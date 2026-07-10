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

This last observation is worth thinking about.

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

> [!INFO]
> At this point the API client package is all ready to go, and we might
> normally at this point publish the package to an NPM registry with e.g. `npm
> publish ./apis/productsummary`. But we'll omit this to avoid having to find,
> authenticate with and use such a registry, and instead use the NPM workspaces
> setup we have to stay local.

## Further info

- The [June 2026 release notes](https://cap.cloud.sap/docs/releases/2026/jun26)
  have information on the [new HCQL protocol
  adapter](https://cap.cloud.sap/docs/releases/2026/jun26#new-hcql-protocol-adapter)

---

## Footnotes

1. See the [xflights](https://github.com/capire/xflights) and
   [xtravels](https://github.com/capire/xtravels) projects for an example of
   how the former provides a read-only API client package for use by the
   latter.
