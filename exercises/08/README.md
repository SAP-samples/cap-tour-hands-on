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

<details>
<summary>Windows (PowerShell)</summary>

```powershell
Remove-Item -Recurse -Force proj-08 -ErrorAction SilentlyContinue
New-Item -ItemType Directory proj-08 | Out-Null
Set-Location proj-08
```

</details>

<details>
<summary>Windows (cmd)</summary>

```cmd
rmdir /s /q proj-08 2>nul & mkdir proj-08 & cd proj-08
```

</details>

We're going to create an API client package, then use it in another project.
Normally the package would be published to an NPM registry and then `npm
add`-ed from there to the consuming project. But to stay local, we'll use the
NPM workspaces concept again like we did in an earlier exercise.

👉 Create a `package.json` file with the following content:

```json
{
  "workspaces": [
    "*",
    "*/apis/*"
  ]
}
```

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

<details>
<summary>Windows (PowerShell / cmd)</summary>

PowerShell:

```powershell
Copy-Item -Recurse ../baseproj northwhisper
```

cmd:

```cmd
xcopy ..\baseproj northwhisper /e /i /q
```

</details>

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

@hcql  @odata
service ProductSummary {

  @readonly
  entity ProductData as
    projection on northwhisper.Products {
      ProductID                      as ID,
      ProductName                    as name,
      toupper(Category.CategoryName) as category : String,
      Supplier.CompanyName           as supplier
    }

}
```

👉 Take note of the following details in this definition:

- the service content is read-only, not untypical for API client packages that
  serve to provide base data[<sup>1</sup>](#footnotes)
- As well as via OData, this service is to be exposed via HCQL, a "CAP-native"
  protocol especially suited for CAP-to-CAP integration scenarios
- The associations from `Products` to `Categories` and `Suppliers` have been
  denormalised ("flattened") by means of path expressions
- Each element has a simpler alias name
- Just for fun and some exposure to function expressions (see [Further
  info](#further-info)) the category is to be expressed in all-caps, via the
  portable function `toupper`

> [!NOTE]
> Taking a step back, "one level up", as it were, observe also what we're doing
> here, which is to define a completely separate service for this. Services are
> cheap, and it is actually an anti-pattern to combine definitions into a
> single or just a few services. The separation between schema (`db/`) and
> service (`srv/`) layers is there for a reason, think of a decent layer of
> lubrication between these layers, and of space between services.
>
> See the [Further info](#further-info) section for more on service best practices.

### Check the new product summary service

Let's see the effect of this service definition by looking at the corresponding
entity set.

👉 Make sure the CAP server has restarted after this addition, and take a brief
look at the entityset in this new service:

```bash
curl \
  --silent \
  --url 'localhost:4004/odata/v4/product-summary/ProductData?$top=3' \
  | jq .
```

<details>
<summary>Windows (PowerShell / cmd)</summary>

Apply the usual Windows `curl` adjustments (they apply to every `curl` in this
exercise):

1. Replace the bash line-continuation `\` with a backtick `` ` `` (PowerShell)
   or caret `^` (cmd), or put it on one line.
2. In PowerShell call `curl.exe` (plain `curl` is an alias for
   `Invoke-WebRequest`); in cmd plain `curl` is fine.
3. Quote the URL so the `$` in `$top` is passed through literally: use **single**
   quotes in PowerShell (inside double quotes, `$top` would be read as a
   variable and the URL would break), and **double** quotes in cmd.

PowerShell (single quotes):

```powershell
curl.exe --silent --url 'localhost:4004/odata/v4/product-summary/ProductData?$top=3' | jq .
```

cmd:

```cmd
curl --silent --url "localhost:4004/odata/v4/product-summary/ProductData?$top=3" | jq .
```

</details>

It should show something like this, where the product, category and supplier
information are in "flat" records:

```json
{
  "@odata.context": "$metadata#ProductData",
  "value": [
    {
      "ID": 1,
      "name": "Chai",
      "category": "BEVERAGES",
      "supplier": "Exotic Liquids"
    },
    {
      "ID": 2,
      "name": "Chang",
      "category": "BEVERAGES",
      "supplier": "Exotic Liquids"
    },
    {
      "ID": 3,
      "name": "Aniseed Syrup",
      "category": "CONDIMENTS",
      "supplier": "Exotic Liquids"
    }
  ]
}
```

### Create the API client package

We now have all we need to create the API client package, which is essentially
an exposed and reusable version of what we've just created.

👉 First, move into the provider project directory:

```bash
cd northwhisper/
```

👉 Create the package, using the `--data` option to request not only the API
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
  a simple `package.json` file generated with some basic information, including
  the package name which is made up from the "provider" package name (which we
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

<details>
<summary>Windows (PowerShell / cmd)</summary>

There's no `head` command; show the first few lines like this.

PowerShell:

```powershell
Get-Content apis/productsummary/data/ProductSummary.ProductData.csv -TotalCount 5
```

cmd (prints all lines, prefixed with line numbers — read the first five):

```cmd
type apis\productsummary\data\ProductSummary.ProductData.csv | more
```

</details>

We see that it's exactly that flattened summary we defined:

```csv
ID,name,category,supplier
1,Chai,BEVERAGES,Exotic Liquids
2,Chang,BEVERAGES,Exotic Liquids
3,Aniseed Syrup,CONDIMENTS,Exotic Liquids
4,Chef Anton's Cajun Seasoning,CONDIMENTS,New Orleans Cajun Delights
```

In other words, it's not just lifted from the `data/` directory of CSV files in
the provider project, it really is a pure and narrow reflection as defined by
the projection.

> [!NOTE]
> At this point the API client package is all ready to go, and we might
> normally at this point publish the package to an NPM registry with e.g. `npm
> publish ./apis/productsummary`. But we'll omit this to avoid having to find,
> authenticate with and use such a registry, and instead use the NPM workspaces
> setup we have to [(stay cool and) stay
> local](https://github.com/SAP-samples/cap-local-development-workshop/tree/main#description).

👉 Before continuing, make sure any CAP server for the provider project is
stopped (mostly because we don't need it running, and we don't want to have any
port clashes when running a CAP server at the consumer end).

## Set up the consumer

Let's channel the great Ward Cunningham here and start with the simplest thing
that could possibly work[<sup>2</sup>](#footnotes). Amongst other things, it
will help us focus on what's needed (clue: not much) to consume such an API
client package.

We'll start by creating a barebones consumer project.

### Create a bare bones project

The [cdsnano](https://github.com/qmacro/dotfiles/blob/main/scripts/cdsnano) script
in my dotfiles, along with a corresponding [template directory](https://github.com/qmacro/dotfiles/tree/main/scripts/cdsnano-template)
represents an even tinier `tiny-sample` based starter project.

Going smaller still to a bare bones project, let's just start with a `package.json`
file and an empty `services.cds` file.

👉 Within the `proj-08/` containing directory, create a directory for the
consumer and move into it:

```bash
mkdir consumer/ \
  && cd $_
```

<details>
<summary>Windows (PowerShell / cmd)</summary>

PowerShell:

```powershell
New-Item -ItemType Directory consumer | Out-Null
Set-Location consumer
```

cmd:

```cmd
mkdir consumer & cd consumer
```

</details>

👉 Within this new `consumer/` directory, create a `package.json` file with the
following content (basically a cds 10 CAP Node.js starter `package.json` file
as reflected in the [cdsnano
template](https://github.com/qmacro/dotfiles/blob/main/scripts/cdsnano-template/package.json)):

```json
{
  "name": "consumer",
  "version": "1.0.0",
  "type": "module",
  "description": "A simple consumer example project",
  "dependencies": {
    "@sap/cds": "^10"
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

### Add the API client package as a dependency

All we need to do to be able to enjoy the model and contents of the API client
package is to use the standard approach of adding it as a dependency via NPM.

👉 First, let's double-check our API client package name:

```bash
jq .name ../northwhisper/apis/productsummary/package.json
```

This should emit:

```json
"northwhisper-productsummary"
```

and is indeed what we expect, remembering what we observed after creating the
package.

👉 Add the package as a dependency to the project:

```bash
npm add northwhisper-productsummary
```

The output looks familiar:

```log
added 112 packages, and audited 114 packages in 5s

found 0 vulnerabilities
```

👉 Look in the current project directory (e.g. with the Explorer or with `ls`).

There is neither a `node_modules/` directory nor a `package-lock.json` file -
just the `package.json`.

That's because of the NPM workspaces context - the package directory and lock
file are at the containing directory's level (i.e. where the `package.json`
with the `workspaces` definition lives).

What has changed, however, is the important part - the consumer project's
dependencies now also include the API client package
`northwhisper-productsummary`.

👉 Examine that now in the consumer's `package.json` file, in which the
`dependencies` property should look like this:

```json
{
  "dependencies": {
    "@sap/cds": "^10",
    "northwhisper-productsummary": "^1.0.0"
  }
}
```

### Take stock of what we have so far

So at this point we have a NPM project file `package.json` in our consumer project.

👉 Double check the dependencies in a similar way to how we did it in exercise
[03 - Creating a plugin](../03/README.md):

```bash
jq '.dependencies + .devDependencies' package.json
```

<details>
<summary>Windows (cmd)</summary>

Works as-is in PowerShell. In cmd, use double quotes around the `jq` filter:

```cmd
jq ".dependencies + .devDependencies" package.json
```

</details>

This should show us that the project needs the `@sap/cds` runtime, the SQLite
driver provided by `@cap-js/sqlite` ... and our API client package
`northwhisper-productsummary`:

```json
{
  "@sap/cds": "^10",
  "northwhisper-productsummary": "^1.0.0",
  "@cap-js/sqlite": "^3"
}
```

### Create the basis for a consumption view

Let's now continue with the "simplest thing that could possibly work" theme.

👉 Create a `services.cds`[<sup>3</sup>](#footnotes) file (next to the
`package.json` file) with this single line:

```cds
using from 'northwhisper-productsummary';
```

To get started, that's all we need!

> [!NOTE]
> It's worth pausing at this point to note that what we have not had to do is
> define a `package.json#cds.requires.<srv>.model` stanza to bring this external
> model to the project's attention. Such a stanza might have looked like this:
>
> ```javascript
> {
>   "cds": {
>     "requires": {
>       "northwhisper-productsummary": {
>         "kind": "hcql",
>         "model": "northwhisper-productsummary"
>       }
>     }
>   }
> }
> ```
>
> This sort of thing was really only for where imported models weren't used in
> mashups, i.e. not included with a `using` directive, but instead accessed
> only via programmatic calls in implementation handlers.

### Compile what we have

Sometimes, a convenient way for us to check and confirm what we're dealing with
is to simply ask the CDS compiler.

> If you're working in some incarnation of VS Code[<sup>4</sup>](#footnotes)
> where the CDS Language Support extension is installed, then you can do this
> easily with the "show as YAML/CSN ..." facility.

👉 Let's do that now:

```bash
cds compile .
```

Bootstrapped from the simple, single `using` line, we get this:

```javascript
{
  definitions: {
    ProductSummary: {
      kind: 'service',
      '@source': 'srv/productsummary.cds',
      '@hcql': true,
      '@odata': true,
      '@cds.external': 2
    },
    'ProductSummary.ProductData': {
      kind: 'entity',
      '@readonly': true,
      elements: {
        ID: {
          key: true,
          type: 'cds.Integer'
        },
        name: {
          type: 'cds.String'
        },
        category: {
          '@Core.Computed': true,
          type: 'cds.String'
        },
        supplier: {
          type: 'cds.String'
        }
      }
    }
  },
  meta: {
    creator: 'CDS Compiler v7.0.1',
    compilerCsnFlavor: 'inferred',
    flavor: 'inferred'
  },
  '$version': '2.0'
}
```

That's a great sign. But we can investigate further in the cds REPL.

### Start a cds REPL for the consumer project

So let's dive in.

👉 Start a cds REPL session (still in the `consumer/` directory), specifying
the `--run` option to have a CAP server started for the current (minimal!)
project:

```bash
cds repl --run .
```

#### Examine the server output

Goodness, what beautiful output!

```log
[cds] - using bindings from: { registry: '~/.cds-services.json' }
[cds] - loaded model from 3 file(s):

  services.cds
  ../northwhisper/apis/productsummary/index.cds
  ../northwhisper/apis/productsummary/services.csn

[cds] - connect to db > sqlite { url: ':memory:' }
  > init from ../northwhisper/apis/productsummary/data/ProductSummary.ProductData.csv
/> successfully deployed to in-memory database.

[cds] - using auth strategy { kind: 'mocked' }
[cds] - mocking ProductSummary {
  at: [ '/odata/v4/product-summary', '/hcql/product-summary' ],
  decl: '../northwhisper/apis/productsummary/services.csn:3'
}
[cds] - server listening on { url: 'http://localhost:42335' }
[cds] - server v10.0.3 launched in 3774 ms
[cds] - [ terminate with ^C ]


------------------------------------------------------------------------
Following variables are made available in your repl's global context:

from cds.entities: {
}

from cds.services: {
  db,
  scheduling,
  ProductSummary,
}

Simply type e.g. ProductSummary in the prompt to use the respective objects.
```

👉 Let's take a moment to learn from what we observe here.

- The `using` directive does its job perfectly, bringing in the definitions
  from our API client package, as we can see from the 3 files listed in the
  "loaded models from 3 file(s)" message
- The sample data from within the API client package is also loaded and
  deployed to the in-memory SQLite database
- The CAP server recognises the `northwhisper-productsummary` as a "non-local"
  service (which has no external bindings, nothing in `~/.cds-services.json`)
  and mocks it for us
- In doing so, the protocol annotations in the imported package definition
  (`@hcql` and `@odata`) are honoured

and

- We have access directly to the `ProductSummary` service in one of the cds
  REPL run-based convenience variables

so let's make good use of it!

#### Explore what is on offer

👉 At the cds REPL prompt, start with:

```javascript
ProductSummary
```

We see everything that is part of the `cds export`-ed API client package, laid
out bare for us in all its glory (and gory detail):

```javascript
ApplicationService {
  handlers: [EventHandlers],
  name: 'ProductSummary',
  options: [Object],
  kind: 'app-service',
  model: [LinkedCSN],
  definition: [service],
  namespace: 'ProductSummary',
  actions: LinkedDefinitions {},
  entities: [LinkedDefinitions],
  _source: '/work/gh/github.com/SAP-samples/cap-tour-hands-on/proj-08/node_modules/@sap/cds/srv/app-service.js',
  handle_authorization: [AsyncFunction: handle_authorization],
  handle_etags: [AsyncFunction: handle_etags],
  handle_validations: [Function: handle_validations],
  handle_media_type: [Function (anonymous)],
  handle_temporal_data: undefined,
  handle_paging: [Function: handle_paging],
  handle_sorting: [Function: handle_sorting],
  mocked: true,
  endpoints: [Array],
  _adapters: [Object],
  path: '/odata/v4/product-summary',
  '$linkProviders': [Array]
}
```

👉 Examine the content of the entities property:

```javascript
ProductSummary.entities
```

whereupon we're presented with:

```javascript
LinkedDefinitions {
  ProductData: entity {
    kind: 'entity',
    '@readonly': true,
    elements: LinkedDefinitions {
      ID: Integer { key: true, type: 'cds.Integer' },
      name: String { type: 'cds.String' },
      category: String { '@Core.Computed': true, type: 'cds.String' },
      supplier: String { type: 'cds.String' }
    },
    '@Capabilities.DeleteRestrictions.Deletable': false,
    '@Capabilities.InsertRestrictions.Insertable': false,
    '@Capabilities.UpdateRestrictions.Updatable': false
  }
}
```

This is exactly what we'd expect, but it's nice to see the details in the
flesh, so to speak.

#### Check the sample data

Let's use our new understanding of the cds REPL (from [04 - Using the REPL](../04/README.md) to jump into CQL mode and check that the data is also available.

👉 Jump into CQL mode:

```javascript
.ql
```

👉 At the `cql>` prompt that appears, have a look at the data:

```sql
select * from ProductSummary.ProductData;
```

and enjoy the output, which starts like this:

```javascript
[
  {
    ID: 1,
    name: 'Chai',
    category: 'BEVERAGES',
    supplier: 'Exotic Liquids'
  },
  {
    ID: 2,
    name: 'Chang',
    category: 'BEVERAGES',
    supplier: 'Exotic Liquids'
  },
  {
    ID: 3,
    name: 'Aniseed Syrup',
    category: 'CONDIMENTS',
    supplier: 'Exotic Liquids'
  }
]
```

### Going beyond exploration and wrapping up

Of course, this is just the start of what we might do with an imported API
client package. But it's important to understand how we embrace it, how we
can explore it, and to know what we have at our fingertips.

See the questions section below for one on how we might proceed from where we
have got to.

## Further info

- The [June 2026 release notes](https://cap.cloud.sap/docs/releases/2026/jun26)
  have information on the [new HCQL protocol
  adapter](https://cap.cloud.sap/docs/releases/2026/jun26#new-hcql-protocol-adapter)
- For more on `toupper` and the use of functions in CDS model definitions, see
  the sections [Exploring function
  expressions](https://qmacro.org/blog/posts/2026/03/23/cds-expressions-in-cap-notes-on-part-3/#exploring-function-expressions)
  and [Portable
  functions](https://qmacro.org/blog/posts/2026/03/23/cds-expressions-in-cap-notes-on-part-3/#portable-functions)
  in the [notes to part 3 of the CDS expressions in CAP
  series](https://qmacro.org/blog/posts/2026/03/23/cds-expressions-in-cap-notes-on-part-3/).
- [Services are
  cheap](https://github.com/qmacro/capref/blob/main/axioms/AXI004.md), so
  there's no reason to bunch everything together into a one-size-fits-all
  service. Right at the very start, Capire leads us towards the best practice
  of [using case-specific
  services](https://cap.cloud.sap/docs/get-started/bookshop#use-case-specific-services),
  which is expanded upon in the [case-oriented
  services](https://cap.cloud.sap/docs/guides/services/providing-services#use-case-oriented-services)
  section of the [Define Provided
  Services](https://cap.cloud.sap/docs/guides/services/providing-services)
  topic.
- Find out more about the facilities of the [CDS Language
  Support](https://marketplace.visualstudio.com/items?itemName=SAPSE.vscode-cds)
  extension for VS Code.

---

## Questions

1. How we might have gone about conveying the provided model to consumers?
   Think about how we use `cds import` and what formats that reads and writes.
   How do the two approaches compare? Can you identify the "lossy" vs
   "lossless" ideas here?
1. When we added the `using from 'northwhisper-productsummary';` line in
   `services.cds`, how does the compiler know that this is a package that it
   should look inside, and not a file or directory?
1. How might we continue with our consumer project now that we have
   successfully added it as a dependency and included it in our (otherwise
   empty) CDS model with the `using` directive? In other words, what sort of
   consumption views might we imagine?

---

## Footnotes

1. See the [xflights](https://github.com/capire/xflights) and
   [xtravels](https://github.com/capire/xtravels) projects for an example of
   how the former provides a read-only API client package for use by the
   latter.
1. [Ward Cunningham](https://en.wikipedia.org/wiki/Ward_Cunningham) invented
   the wiki, co-authored the Manifesto For Agile Software Development and is an
   all-round nice guy. For more info on this "simplest thing that could
   possibly work" idea, you might enjoy [a reading of an interview with him on
   this
   topic](https://creators.spotify.com/pod/profile/tech-aloud/episodes/The-Simplest-Thing-that-Could-Possibly-Work--A-conversation-with-Ward-Cunningham--Part-V---Bill-Venners-e5dpts).
1. See [Why I use services.cds in simple CDS model
   examples](https://qmacro.org/blog/posts/2026/01/02/why-i-use-services-cds-in-simple-cds-model-examples/).
1. The phrase "some incarnation of" encompasses VS Code running on your
   own machine, or an SAP Business Application Studio dev space, or a GitHub
   Codespace session.
