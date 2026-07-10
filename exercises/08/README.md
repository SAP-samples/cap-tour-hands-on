# 08 - Discovering API client package export and reuse

CAP-level service integration (Calesi) is a powerful and flexible concept and
exists in various forms. One of these is the idea of API client packages which
can be created from CDS service definitions, exported, and then used in
consumer projects.

In this exercise we'll explore what that is, and how it works.

## Create a new project directory

👉 As usual, create a new directory for this project:

```bash
rm -rf proj-08 \
  && mkdir proj-08 \
  && cd $_
```

We're going to create an API client package, then use it in another project.
Normally the package would be published to an NPM registry and then `npm
add`-ed from there to the consuming project. But to stay local, we'll use the
NPM workspaces concept again like we did in an earlier exercise.

👉 Create a `package.json` file with following
content:

```json
{
  "workspaces": [
    "*",
    "*/apis/*"
  ]
}
```

TODO - question about the "*/apis/*" entry here

This will allow us to export the API client package from one project, and
consume it in another, without a round-trip to any NPM registry (and all the
authentication, authorisations and setup that would involve).

## Set up the provider project

In this section we'll set up a provider project, the one from which we'll
create the API client package. In the section after this, we'll then consume
it.

### Use the base project for the source

We'll start with the Northwind-based "base project" and create an API client
package in that. So let's get that set up as one ("provider") project within
our main project directory.

👉 Make a copy of the base project contents here and call it "northwhisper":

```bash
cp -a ../baseproj northwhisper
```

The value of the `name` property in the project's `package.json` file becomes
significant when we create an API client package, so let's change it from the
current value of `baseproj` to something better.

👉 In `northwhisper/package.json`, change the value of the `name` property from
`baseproj` to `northwhisper`:

```json
{
  "name": "northwhisper",
  "version": "1.0.0",
  "dependencies": {
    ...
  },
  ...
}
```

### Examine the entities and their relationships

A regular service will typically make various entities available, and
implicitly the relationships between them too. In an API client package it
might be more appropriate to expose a flattened subset of the model. That's
what we'll be doing here.

👉 Before we do, let's remind ourselves of the relationships between the
entities, by looking at `northwhisper/db/schema.cds`, which shows that each
product is associated with a supplier and with a category:

```cds
namespace northwhisper;

entity Products {
  key ProductID    : Integer;
      ProductName  : String;
      UnitPrice    : Decimal;
      Category     : Association to Categories;
      Supplier     : Association to Suppliers;
      UnitsInStock : Integer;
      Discontinued : Boolean;
}

entity Suppliers {
  key SupplierID  : Integer;
      CompanyName : String;
      City        : String;
      Country     : String;
      Products    : Association to many Products
                      on Products.Supplier = $self;
}

entity Categories {
  key CategoryID   : Integer;
      CategoryName : String;
      Description  : String;
      Products     : Association to many Products
                       on Products.Category = $self;
}
```

👉 Start a CAP server with `cds watch northwhisper` and then check out these
relationships with an OData query operation like this:
<http://localhost:4004/northwhisper/Products?$select=ProductName&$expand=Supplier($select=CompanyName),Category($select=CategoryName)>.

### Define a new product summary service

The main (and only) service right now in the northwhisper CDS model is defined
in `srv/main.cds` and exposes all three entities.

We'll now create a second service definition to be the heart of our API client
package that we'll eventually export and make available.

👉 In `northwhisper/srv/` create a new file `productsummary.cds` with the
following contents:

```cds
using northwhisper from '../db/schema';

@readonly  @hcql  @odata
service ProductSummary {

  entity ProductData as
    projection on northwhisper.Products {
      ProductID             as ID,
      ProductName           as name,
      Category.CategoryName as category,
      Supplier.CompanyName  as supplier
    }

}
```

👉 Take note of the following details in this definition:

- the service is read-only, not untypical for API client packages that serve to
  provide base data[<sup>1</sup>](#footnotes)
- As well as via OData, this service is to be exposed via HCQL, a "CAP-native"
  protocol especially suited for CAP-to-CAP integration scenarios
- The associations from `Products` to `Categories` and `Suppliers` have been
  denormalised ("flattened") by means of path expressions
- Each element has a simpler alias name

### Check the new product summary service

Let's see the effect of this service definition by starting a CAP server and
looking at the corresponding entity set.

👉 Make sure the CAP server has restarted after this addition, and take a brief
look at the entityset in this new service:

```bash
curl \
  --silent \
  --url 'localhost:4004/odata/v4/product-summary/ProductData?$top=3' \
  | jq .
```

It should show something like this, where the product, category and supplier
information are in "flat" records:

```json
{
  "@odata.context": "$metadata#ProductData",
  "value": [
    {
      "ID": 1,
      "name": "Chai",
      "category": "Beverages",
      "supplier": "Exotic Liquids"
    },
    {
      "ID": 2,
      "name": "Chang",
      "category": "Beverages",
      "supplier": "Exotic Liquids"
    },
    {
      "ID": 3,
      "name": "Aniseed Syrup",
      "category": "Condiments",
      "supplier": "Exotic Liquids"
    }
  ]
}
```

### Create the API client package

We now have all we need to create the API client package, which is essentially
an exposed and reusable version of what we've just created.

👉 Do that now, using the `--data` option to request not only the API
definition but also sample data:

```bash
cds export --data srv/productsummary.cds
```

This should emit something like this:

```log
Exporting APIs to apis/productsummary ...

  > apis/productsummary/index.cds
  > apis/productsummary/services.csn
  > apis/productsummary/package.json
  > apis/productsummary/data/ProductSummary.ProductData.csv

```

👉 Take a moment to examine what is produced:

- there's an `index.cds` file thats serves a similar "bootstrapping" purpose to
  what we saw in the exercise where we were mocking messaging
- given that this is a package that we should be able to add with NPM, there's
  a basic `package.json` file generated with some basic information, including
  the package name, which is made up from the "provider" package name (which we
  changed earlier from `baseproj` to `northwhisper`) and the name of the
  service upon which this API client package export was based
- there's a `services.csn` file, which is the machine readable (CSN) version of
  the service defined in `srv/producsummary.cds`
- there's also a `data/` directory with a single CSV file representing the
  dataset defined by the `ProductData` projection

It's worth digging in a little to this last observation.

👉 Look at what the CSV file contains:

```bash
head -5 apis/productsummary/data/ProductSummary.ProductData.csv
```

We see that it's exactly that flattened summary we defined:

```csv
ID,name,category,supplier
1,Chai,BEVERAGES,Exotic Liquids
2,Chang,BEVERAGES,Exotic Liquids
3,Aniseed Syrup,CONDIMENTS,Exotic Liquids
4,Chef Anton's Cajun Seasoning,CONDIMENTS,New Orleans Cajun Delights
```

> [!NOTE]
> At this point the API client package is all ready to go, and we might
> normally at this point publish the package to an NPM registry with e.g. `npm
> publish ./apis/productsummary`. But we'll omit this to avoid having to find,
> authenticate with and use such a registry, and instead use the NPM workspaces
> setup we have to [(stay cool and) stay
> local](https://github.com/SAP-samples/cap-local-development-workshop/tree/main#description).

## Set up the consumer project

To achieve the simplest end-to-end scenario here, we should consume this API
client package in another project. So let's set one up here, keeping things as
simple as possible.

### Create a tiny-sample based project

👉 First, move back out from the `northwhisper/` directory and up one level
into the `proj-08/` directory:

```bash
cd ..
```

Remember that this `proj-08/` directory is the "container" for both provider
and consumer projects and has a simple `package.json` file enabling the NPM
workspaces mechanism.

👉 Create a consumer project based on the `tiny-sample` facet, specifying also
the `nodejs` facet, so that we get a `package.json` file which we'll need to
capture and store the dependency on the API client package we'll be adding
shortly:

```bash
cds init --add nodejs,tiny-sample consumer
```

The `tiny-sample` facet adds a super simple CDS model which is just a catalog
service containing a single entity `Books` which has a handful of records.

> It doesn't matter too much here about how realistic it might be to use a
> "products" package in this context; the important thing is to keep things
> simple so we can focus on what matters.

### Add the API client package as a dependency

Now within the consumer project directory (`consumer/`) we are ready to
"consume" the API client package. There's really only one main step, and that's
to add it as a dependency.

Whether we're working locally (as here) with NPM workspaces, or using an actual
NPM registry, the approach and command is the same.

👉 First, let's double-check our API client package name:

```bash
jq .name northwhisper/apis/productsummary/package.json
```

This should emit:

```json
"northwhisper-productsummary"
```

and is indeed what we expect, remembering back to what we observed after
creating the package.

👉 Add the package as a dependency to the project:

```bash
cd consumer/ \
  && npm add northwhisper-productsummary
```

The output looks familiar:

```log
added 112 packages, and audited 114 packages in 5s

found 0 vulnerabilities
```

but if we look (with, say, `tree`) at the project contents, we don't see any
`node_modules/` directory or a `package-lock.json` file:

```log
.
├── app
├── db
│   └── data
│       └── CatalogService.Books.csv
├── package.json
├── readme.md
└── srv
    └── cat-service.cds
```

That's because of the NPM workspaces context - the package directory and lock
file are at the containing directory's level (i.e. where the `package.json`
with the `workspaces` definition lives).

What has changed, however, is the important part - the consumer project's
dependencies now also include the API client package
`northwhisper-productsummary`.

👉 Examine that now in the consumer's `package.json` file, which should look
like this:

```json
{
  "name": "consumer",
  "version": "1.0.0",
  "type": "module",
  "dependencies": {
    "@sap/cds": "^10",
    "northwhisper-productsummary": "^1.0.0"
  },
  "devDependencies": {
    "@cap-js/sqlite": "^3"
  },
  "scripts": {
    "start": "cds-serve"
  },
  "private": true
}
```

### Wire up the package references

If we had been using a real NPM registry, then the `npm add` command would have
retrieved the package, and installed it (along with the rest of the
dependencies) i a `consumer/`-local `node_modules/` directory, and we'd be all
set.

But because we're going with the NPM workspaces powered local-first approach,
there's one more step here, and that's to wire up the package references.

👉 First, move back up from the `consumer/` project directory into the
`proj-08/` containing directory:

```bash
cd ..
```

Now run an `npm install`:

```bash
npm install
```

### Add in a requirement for the package

All that's left for us to do is to define a requirement for this API client
package in the configuration for our consumer project. We can do this simply by
adding a `package.json#cds.requires` stanza.

Do that now, so the `consumer/package.json` contents look like this:

```json
{
  "name": "consumer",
  "version": "1.0.0",
  "type": "module",
  "dependencies": {
    "@sap/cds": "^10",
    "northwhisper-productsummary": "^1.0.0"
  },
  "devDependencies": {
    "@cap-js/sqlite": "^3"
  },
  "scripts": {
    "start": "cds-serve"
  },
  "private": true,
  "cds": {
    "requires": {
      "northwhisper-productsummary": {
        "kind": "hcql",
        "model": "northwhisper-productsummary"
      }
    }
  }
}
```

> The `"kind": "hcql"` property in there is deliberate, to start making us
> think about what can arguably be seen as the wire equivalent of the lossless
> API client package CSN definition - CQL over HTTP (see [Further
> info](#furtherinfo)). We may include an exercise on HCQL in future.

### Start up the consumer project

At this point, we can start a CAP server for the consumer project, and see what
happens.

👉 Run `cds watch` for the consumer project:

```bash
cds watch consumer
```

At this point we should see something like this:

```log
[cds] - loaded model from 3 file(s):

  northwhisper/apis/productsummary/index.cds
  consumer/srv/cat-service.cds
  northwhisper/apis/productsummary/services.csn

[cds] - using bindings from: { registry: '~/.cds-services.json' }
[cds] - connect to db > sqlite { url: ':memory:' }
  > init from consumer/db/data/CatalogService.Books.csv
  > init from northwhisper/apis/productsummary/data/ProductSummary.ProductData.csv
/> successfully deployed to in-memory database.

[cds] - using auth strategy { kind: 'mocked' }
[cds] - mocking ProductSummary {
  at: [ '/odata/v4/product-summary', '/hcql/product-summary' ],
  decl: 'northwhisper/apis/productsummary/services.csn:3'
}
[cds] - serving CatalogService {
  at: [ '/odata/v4/catalog' ],
  decl: 'consumer/srv/cat-service.cds:1'
}
[cds] - server listening on { url: 'http://localhost:4004' }
[cds] - server v10.0.3 launched in 3586 ms
[cds] - [ terminate with ^C ]
```

👉 Take a moment to peruse these log records, and notice:

- Not only are the consumer project's own definitions (in
  `consumer/srv/cat-service.cds`) in the model, but also the definitions from
  the API client package, "front-doored" by
  `northwhisper/apis/productsummary/index.cds` which in turn points to
  `northwhisper/apis/productsummary/services.csn`
- Correspondingly, the sample data that was also part of the API client package
  created (with `cds export --data ...`) is available and loaded (from
  `northwhisper/apis/productsummary/data/ProductSummary.ProductData.csv`)
- As usual with `cds watch` (or more accurately with `cds serve all
  --with-mocks ...`) the required `ProductSummary` is mocked, because there is
  no external bindinginformation that exists for it:

    ```log
    [cds] - mocking ProductSummary {
      at: [ '/odata/v4/product-summary', '/hcql/product-summary' ],
      decl: 'northwhisper/apis/productsummary/services.csn:3'
    }
    ```

👉 Take a brief look in the local binding registry (file
`~/.cds-services.json`), which should contain something like this:

```json
{
  "cds": {
    "provides": {
      "ProductSummary": {
        "endpoints": {
          "odata": "/odata/v4/product-summary",
          "hcql": "/hcql/product-summary"
        },
        "server": 25581
      },
      "CatalogService": {
        "endpoints": {
          "odata": "/odata/v4/catalog"
        },
        "server": 25581
      }
    },
    "servers": {
      "25581": {
        "root": "file:///work/gh/github.com/SAP-samples/cap-tour-hands-on/proj-08/consumer",
        "url": "http://localhost:4004"
      }
    }
  }
}
```

We can see that the API client package definitions are being served as defined,
via OData and HCQL.

### Request the product summary data

At this point we've dovetailed into the service integration CodeJam and
everything is effectively downstream from here. Let's round this exercise off
by looking at the CAP server landing page and confirming that the package is
available and being mocked appropriately.

👉 Visit the landing page at <http://localhost:4004/> and select the
<http://localhost:4004/odata/v4/product-summary/ProductData> resource,
whereupon we should see the flattened product data from before.

Well done!

## Further info

- The [June 2026 release notes](https://cap.cloud.sap/docs/releases/2026/jun26)
  have information on the [new HCQL protocol
  adapter](https://cap.cloud.sap/docs/releases/2026/jun26#new-hcql-protocol-adapter)

---

## Questions

1. How we might have gone about conveying the provided model to consumers?
   Think about how we use `cds import` and what formats that reads and writes.
   How do the two approaches compare? Can you identify the "lossy" vs
   "lossless" ideas here?

---

## Footnotes

1. See the [xflights](https://github.com/capire/xflights) and
   [xtravels](https://github.com/capire/xtravels) projects for an example of
   how the former provides a read-only API client package for use by the
   latter.
