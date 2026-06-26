# 07 - Defining constraints declaratively

CDS modelling doesn't stop at entities, relationships and service exposure.
Domain design also includes constraints, and these can be included in the
overall model declaratively, meaning a cleaner and smaller surface area (less
chance of bugs), a shared understanding of intent between the domain expert and
developer and less code to write and maintain.

In this exercise, we'll explore declarative constraints by adding some to our
Northwind-based base project.

## Start a new CAP project

👉 As we've done in other exercises, let's create a new project for this
exercise, using the "base project" as a starter.

```bash
rm -rf proj-07 \
  && cp -a baseproj proj-07 \
  && cd $_ \
  && tree
```

We should be familiar with this base project, a cut-down version of Northwind, with
products, suppliers and categories.

## Examine the data

As we'll be adding some constraints, which are all about input validation,
effectively, it is worth spending a moment familiarising ourselves with the
data we have.

You can do this by either using your Web browser and exploring the entitysets
from the service via the CAP server start page (at <http://localhost:4004>) or
by using some invocations as shown next.

### Start a CAP server

👉 First, start a CAP server with `cds watch`.

From the log output, we're reminded that the `Main` service is available at
`/northwhisper`:

```log
[cds] - serving Main {
  at: [ '/northwhisper' ],
  decl: 'srv/main.cds:4'
}
```

More pertinently, we're also reminded that there is no custom implementation
file (such as `srv/main.js`), no service-specific JavaScript; everything is
being [handled by the
framework](https://qmacro.org/blog/posts/2024/11/07/five-reasons-to-use-cap/#1-the-code-is-in-the-framework-not-outside-of-it).

### Look at the category names

The names of the categories are simple and follow a sort of pattern.

👉 Take a look at them, either at
<http://localhost:4004/northwhisper/Categories?$select=CategoryName> or as
follows:

```bash
curl -s localhost:4004/northwhisper/Categories \
| jq -r .value[].CategoryName
```

This should show us:

```text
Beverages
Condiments
Confections
Dairy Products
Grains/Cereals
Meat/Poultry
Produce
Seafood
```

Each separate word's initial letter is capitalised. We might want to have a
constraint to ensure that future category names fit this pattern.

## Start exploring constraints

Let's now dive in and spend the rest of this exercise exploring data, validation
and some of the constraint annotations available to us.

### Create a new category with minimal data

Right now, there's no restriction on category name, or on anything else for
that matter.

👉 Create a new category like this:

```bash
curl \
  --include \
  --data '{"CategoryID":9,"CategoryName":"my new category"}' \
  --url localhost:4004/northwhisper/Categories
```

This should work fine:

```log
HTTP/1.1 201 Created
OData-Version: 4.0
location: Categories(9)
Content-Type: application/json; charset=utf-8
Content-Length: 116

{
  "@odata.context": "$metadata#Categories/$entity",
  "CategoryID": 9,
  "CategoryName": "my new category",
  "Description": null
}
```

But from our perspective, there are a couple of issues:

- the category name doesn't really conform to what we have already
- there's no description at all

Let's start by addressing the category description. But first, we need
somewhere to put our constraints.

### Start a new file for annotations

We can address not only the category name format, but also the lack of
description, declaratively, with annotations.

Following best practices (see [Further info](#further-info)) ...:

_**Separation of Concerns** – always put secondary concerns, such as
constraints in this case, into separate files as in the example, instead of
polluting your core service definitions._

... we should do this in a separate file.

👉 In a separate terminal window (so that the CAP server can continue running),
create a file `annotations.cds` in the `srv/` directory, alongside `main.cds`,
with the following initial content:

```cds
using Main from './main';

annotate Main.Categories with {

}
```

### Make the category description mandatory

The `@mandatory` annotation will cause requests to be rejected if there is
missing or empty input for the annotated element.

👉 Add this to the `Description` element as shown:

```cds
using Main from './main';

annotate Main.Categories with {

  Description @mandatory;

}
```

### Retry the category creation

What effect does this have?

👉 Try the same OData create operation again:

```bash
curl \
  --include \
  --data '{"CategoryID":9,"CategoryName":"my new category"}' \
  --url localhost:4004/northwhisper/Categories
```

This time we get:

```log
HTTP/1.1 400 Bad Request
OData-Version: 4.0
Content-Type: application/json; charset=utf-8
Content-Length: 127

{
  "error": {
    "message": "Provide the missing value.",
    "code": "ASSERT_MANDATORY",
    "target": "Description",
    "@Common.numericSeverity": 4
  }
}
```

This rejection also occurs if we merely supply an empty string:

```bash
curl \
  --include \
  --data '{"CategoryID":9,"Description":"","CategoryName":"my new category"}' \
  --url localhost:4004/northwhisper/Categories
```

## Get to know the general @assert constraint

While annotations such as `@readonly`, `@mandatory`, `@assert.range` and so on
have been around for a while, there's a relatively
new[<sup>1</sup>](#footnotes) general `@assert` annotation that provides
greater flexibility while remaining in a declarative mode, thanks to the
support for and from the CDS Expression Language (CXL).

### Improve on the @mandatory annotation with @assert

Let's replace what the `@mandatory` annotation is doing for us, with a `case`
expression.

👉 Do that now, in `srv/annotations.cds`:

```cds
using Main from './main';

annotate Main.Categories with {

  Description @assert: (case
    when Description is null then 'Description must be supplied'
    when length(Description) < 3 then 'Description too short'
  end);

}
```

### See the effect of the new @assert constraint with the case expression

👉 Try out a few of the previous OData create operations, with no description
property, with a description property that is too short, and then with a
description property at least 3 characters long, and observe that the responses
are as expected.

It's easy to see how such an expression with this `@assert` annotation is more
flexible, and can even be expanded upon, depending on domain design requirements.

## Address the category name pattern

Let's go back to earlier in the exercise where we saw the existing category names
and the pattern they follow. Let's assume that we want to ensure that any new
category names follow the same pattern. We can implement such a constraint with
the `@assert.format` annotation.

This annotation allows us to specify a regular expression[<sup>2</sup>](#footnotes)
to describe the pattern required.

### Add an @assert.format annotation to constrain new category names

👉 Within the current `annotate Main.Categories with { ... }` block, add a new
annotation as shown:

```cds
using Main from './main';

annotate Main.Categories with {

  Description  @assert: (case
    when Description is null then 'Description must be supplied'
    when length(Description) < 3 then 'Description too short'
  end);

  CategoryName @assert.format: '^[A-Z][a-z]+(?:\W[A-Z][a-z]+)*$';

}
```

### Try to add a new category

Let's exercise the constraints we have now.

Try to add a new category, with a decent description. There's a JSON payload
for this in the file [pulses-and-seeds.json](assets/pulses-and-seeds.json) (in
the `assets/` directory for this exercise) which looks like this:

```json
{
  "CategoryID": 9,
  "CategoryName": "pulses/seeds",
  "Description": "Lentils, chickpeas, kidney beans, black gram and similar."
}
```

👉 Copy that file to the current project directory:

```bash
cp ../exercises/07/assets/pulses-and-seeds.json .
```

👉 Use the file in an OData create operation on the `Categories` entityset:

```bash
curl \
  --include \
  --data @pulses-and-seeds.json \
  --url localhost:4004/northwhisper/Categories
```

This is what should be emitted:

```log
HTTP/1.1 400 Bad Request
OData-Version: 4.0
Content-Type: application/json; charset=utf-8
Content-Length: 167

{
  "error": {
    "message": "Enter a value matching the pattern ^[A-Z][a-z]+(?:\\W[A-Z][a-z]+)*$.",
    "code": "ASSERT_FORMAT",
    "target": "CategoryName",
    "@Common.numericSeverity": 4
  }
}
```

Clearly `pulses/seeds` doesn't match the pattern followed by the other category
names (both `pulses` and `seeds` should have initial capital letters).

Great! The format constraint caught the issue.

### Provide a custom message for the @assert.format annotation

But we can do better. The generic error message ("Enter a value matching the
pattern ...") is fine, but perhaps a little unfriendly, given that it just
reproduces the pattern verbatim, i.e. shows the regular expression.

We've already seen how we can supply custom error messages naturally in the
context of the more general and flexible`@assert` annotation, but even with the
more traditional `@assert.format` (and friends) annotations, we can use a
`.message` suffix to do something similar.

👉 Add an `@assert.format.message` annotation as shown, next to the annotation
just added, like this:

```cds
using Main from './main';

annotate Main.Categories with {

  Description  @assert: (case
    when Description is null then 'Description must be supplied'
    when length(Description) < 3 then 'Description too short'
  end);

  CategoryName @assert.format: '^[A-Z][a-z]+(?:\W[A-Z][a-z]+)*$'
    @assert.format.message: 'Follow the category naming conventions';

}
```

👉 Retry the create operation, and you should see this friendlier message:

```json
{
  "error": {
    "message": "Follow the category naming conventions",
    "code": "ASSERT_FORMAT",
    "target": "CategoryName",
    "@Common.numericSeverity": 4
  }
}
```

> When writing tests for such outcomes, it's important to [make minimal
> assumptions](https://cap.cloud.sap/docs/node.js/cds-test#minimal-assumptions)
> and check against the error code, not the error message, as the code
> (`ASSERT_FORMAT`) remains consistent.

### Retry adding the new category with a name that conforms

To round this particular annotation adventure off, let's try adding the
category again, but this time using a name that conforms to the convention set.

👉 Modify the value of the `CategoryName` property in the
`pulses-and-seeds.json` file so it looks like this:

```json
{
  "CategoryID": 9,
  "CategoryName": "Pulses/Seeds",
  "Description": "Lentils, chickpeas, kidney beans, black gram and similar."
}
```

👉 Now make that OData create operation one more time:

```bash
curl \
  --include \
  --data @pulses-and-seeds.json \
  --url localhost:4004/northwhisper/Categories
```

And enjoy the glory of success!

```log
HTTP/1.1 201 Created
OData-Version: 4.0
location: Categories(9)
Content-Type: application/json; charset=utf-8
Content-Length: 168

{
  "@odata.context": "$metadata#Categories/$entity",
  "CategoryID": 9,
  "CategoryName": "Pulses/Seeds",
  "Description": "Lentils, chickpeas, kidney beans, black gram and similar."
}
```

## Explore another constraint to check for association existence

TODO ... (supplier should exist fo new products)

## Further info

- The [Declarative
  Constraints](https://cap.cloud.sap/docs/guides/services/constraints) topic in
  Capire has a great overview, including some best practice tips.

- See the blog post [A new Hands-on SAP Dev mini-series on the core expression
  language in
  CDS](https://qmacro.org/blog/posts/2025/12/09/a-new-hands-on-sap-dev-mini-series-on-the-core-expression-language-in-cds/)
  for links to the series videos and accompanying detailed blog posts on CXL.

- See the [Operators (xpr)](https://cap.cloud.sap/docs/cds/cxl#operators-xpr)
  section of the CXL topic in Capire for a list of all operators, including
  `case-when-then`.

---

## Footnotes

- The `@assert` annotation was [introduced in the December 2025
  release](https://cap.cloud.sap/docs/releases/2025/dec25#declarative-constraints).

- Yes, I know I'm fond of rolling out Jamie Zawinski (aka JWZ)'s famous quote
  on regular expressions:

    _Some people, when confronted with a problem, think "I know, I'll use
    regular expressions." ... Now they have two problems._

  Despite that, I'm a strong proponent of the (appropriate) use of regular
  expressions. For more on JWZ's quote, see [this
  post](https://web.archive.org/web/20140424160443/http%3A//regex.info/blog/2006-09-15/247),
  by none other than the great Jeffrey Friedl, author of (in my humble opinion)
  [Mastering Regular
  Expressions](https://www.oreilly.com/library/view/mastering-regular-expressions/0596528124/),
  one of the best books out there on the topic.
