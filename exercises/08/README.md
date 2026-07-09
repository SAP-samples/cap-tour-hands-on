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

## Use the base project as the source

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

