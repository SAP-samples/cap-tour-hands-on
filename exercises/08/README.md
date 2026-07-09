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
authentication, authorizations and setup that would involve).

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
what we'll be doing in this exercise.

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

### Define a new data service

The main (and only) service right now in the northwhisper CDS model is defined
in `srv/main.cds` and exposes all three entities.

We'll now create a second service definition to be the heart of our API client
package that we'll eventually export and make available.

👉 In `northwhisper/srv/` create a new file `data.cds` with the following
contents:

```cds
using northwhisper from '../db/schema';

@readonly  @hcql  @odata
service Data {

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
