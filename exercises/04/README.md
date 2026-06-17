# 04 - Using the REPL

In any language or development environment, having a REPL is a superpower, and
it pays to embrace it and be at least a little familiar with it. CAP as a whole
is built on solid foundations and practices that have matured over the decades,
and the REPL is part of that, first appearing in the 1960's and initially
popularised in the LISP and LISP-derivative communities.

Node.js has a REPL, and it is upon this REPL that the cds REPL is based.

## Start a new CAP project

Like we did in an earlier exercise, we'll start with the "base project" to save
a bit of time.

👉 Create a new project directory for this exercise using the base project:

```bash
rm -rf proj-04 \
  && cp -a baseproj proj-04 \
  && cd $_
```

We should by now be familiar with the contents of this project, a very reduced
version of Northwind, with just products, suppliers and categories (each of
which have just a few fields) exposed in a single service.

## Fire up the cds REPL

Let's dive right in.

👉 Start the REPL:

```bash
cds repl
```

and you'll be presented with a simple prompt:

```text
Welcome to cds repl v9.9.1
>
```

whereupon, to honour one of the pivotal moments in the birth of personal
computing[<sup>1</sup>](#footnotes), there's only one thing we should type in
at this point, and that's `2 + 2`:

```javascript
> 2 + 2
4
```

Yes, this Node.js based REPL expects and interprets JavaScript, unsurprisingly.

## Explore the commands

The cds REPL adds a few extra commands to the standard Node.js REPL.

👉 Look at what commands are available:

```javascript
> .help
```

and you should see a list like this:

```text
.break     Sometimes you get stuck, this gets you out
.clear     Alias for .break
.editor    Enter editor mode
.exit      Exit the REPL
.help      Print this help message
.inspect   Sets options for util.inspect, e.g. `.inspect .depth=1`.
.load      Load JS from a file into the REPL session
.ql        Switch to cql repl mode, evaluating cql queries
.run       Runs a cds server from a given CAP project folder, or module name like @capire/bookshop.
.save      Save all evaluated commands in this REPL session to a file
```

The cds REPL specific commands are `.inspect`, `.ql` and `.run`.

### Try out inspect

The `.inspect` command is a configurable structure viewer, effectively. It
gives us a comfortable way of looking at structures, either as part of the CAP
runtime, or as part of a model.

Take the CDS facade as an example - the entrypoint to the surface area of CAP
facilities (See [Further info](#further-info)). In the cds REPL, it's available
by default, injected into the context.

👉 Take a look:

```javascript
> cds
```

This emits a ton of output:

```javascript
cds {
  _events: {},
  _eventsCount: 0,
  _maxListeners: undefined,
  model: undefined,
  db: undefined,
  cli: { command: 'repl', argv: [], options: { run: undefined } },
  root: '/work/gh/github.com/SAP-samples/cap-tour-hands-on/proj-04',
  services: {},
  extend: [Function (anonymous)],
  home: '/home/dj/.npm-packages/lib/node_modules/@sap/cds-dk/node_modules/@sap/cds',
  version: '9.9.1',
  parse: [Function: exports] {
    cdl: [Function: cdl],
    cql: [Function: cql],
    path: [Function: path],
    expr: [Function: expr],
    xpr: [Function (anonymous)],
    ref: [Function (anonymous)],
    properties: [Function (anonymous)],
    yaml: [Function (anonymous)],
    csv: [Function (anonymous)],
    json: [Function (anonymous)],
    ttl: [Function (anonymous)],
    _select: [Function (anonymous)]
  },
  utils: <ref *3> {
    path: <ref *2> {
      resolve: [Function: resolve],
      normalize: [Function: normalize],
      isAbsolute: [Function: isAbsolute],
      join: [Function: join],
      relative: [Function: relative],
      toNamespacedPath: [Function: toNamespacedPath],

      ... (many many more lines)
```

With regular JavaScript facilities, we can get a better overview.

👉 Try this:

```javascript
> Object.keys(cds)
```

This is a little cumbersome, and also is a bit too far the other way:

```javascript
[
  '_events',       '_eventsCount',
  '_maxListeners', 'model',
  'db',            'cli',
  'root',          'services',
  'extend',        'home',
  'version',       'parse',
  'utils'
]
```

This is where `.inspect` comes in, the [dialectical third](https://en.wikipedia.org/wiki/Goldilocks_and_the_Three_Bears#:~:text=this%20as%20the%20%22-,dialectical%20three,-%22%20where%20%22the%20first) option - just right.

👉 Give it a go:

```javascript
> .inspect cds
```

This emits something like this:

```javascript
cds: cds {
  _events: [Object: null prototype] {},
  _eventsCount: 0,
  _maxListeners: undefined,
  model: undefined,
  db: undefined,
  cli: [Object],
  root: '/work/gh/github.com/SAP-samples/cap-tour-hands-on/proj-04',
  services: {},
  extend: [Function (anonymous)],
  home: '/home/dj/.npm-packages/lib/node_modules/@sap/cds-dk/node_modules/@sap/cds',
  version: '9.9.1',
  parse: [Function],
  utils: [Object],
  Symbol(shapeMode): false,
  Symbol(kCapture): false
}
```

It's also possible to control the "volume" of output, either on an
execution-by-execution basis (`.inspect .depth=3 cds`) or by updating the
default (`.inspect .depth=2`). The "volume" goes all the way to
11[<sup>2</sup>](#footnotes).

### Try out run

In the output from `.inspect cds` just now, there were fewer than 20 properties
shown. Some of these, such as `model`, `db` and `services` were also either
undefined or empty. That's because we're not currently running any CAP server
in the context of this cds REPL session (and thus there's no model, no database
connection, and no services).

With the `.run` command we can change that, and start up a server.

👉 Try that now, specifying `.` as the location for the project definitions,
i.e. the `proj-04/` directory we're in:

```javascript
> .run .
```

We get some usual server output which we're used to from `cds watch` (in fact
the invocation is effectively the same, except that a random port is chosen
instead of the default 4004):

```log
[cds] - using bindings from: { registry: '~/.cds-services.json' }
[cds] - loaded model from 2 file(s):

  srv/main.cds
  db/schema.cds

[cds] - connect to db > sqlite { database: ':memory:' }
  > init from db/data/northwhisper-Suppliers.csv
  > init from db/data/northwhisper-Products.csv
  > init from db/data/northwhisper-Categories.csv
/> successfully deployed to in-memory database.

[cds] - using auth strategy { kind: 'mocked' }
[cds] - serving Main {
  at: [ '/northwhisper' ],
  decl: 'srv/main.cds:4'
}
[cds] - server listening on { url: 'http://localhost:40625' }
[cds] - server v9.9.1 launched in 872550 ms
[cds] - [ terminate with ^C ]
```

But what we also get is something additional:

```log
Following variables are made available in your repl's global context:

from cds.entities: {
  Products,
  Categories,
  Suppliers,
}

from cds.services: {
  db,
  Main,
}

Simply type e.g. Main in the prompt to use the respective objects.
```

What happens is that the `.run` mechanism identifies entities and services
within the project and makes them available in the cds REPL context, globally,
and very conveniently for us!

### Use the run facility as a cds REPL option

This is so convenient and very often what you want when launching a cds REPL,
it's available as an option at invocation time.

👉 First, exit the current cds REPL session (with `Ctrl-D`).

👉 Now restart the cds REPL, but this time specify that you want to have a CAP
server started up automatically for the project in the current directory:

```bash
cds repl --run . # or cds r -r .
```

👉 Once you're at the cds REPL prompt, explore the global variables there, such
as `Products`, `db` and `Main`. Try to notice the different object types:

- `Products`: `entity`
- `db`: `SQLiteService`
- `Main`: `ApplicationService`

as well as their component parts, for example we can see the element details in
the `Products` entity:

```javascript
entity {
  kind: 'entity',
  elements: LinkedDefinitions {
    ProductID: Integer { key: true, type: 'cds.Integer' },
    ProductName: String { type: 'cds.String' },
    UnitPrice: Decimal { type: 'cds.Decimal' },
    Category: Association {
      type: 'cds.Association',
      target: 'northwhisper.Categories',
      keys: [
        {
          ref: [ 'CategoryID' ],
          '$generatedFieldName': 'Category_CategoryID'
        }
      ]
    },
    Category_CategoryID: Integer { type: 'cds.Integer', '@odata.foreignKey4': 'Category' },
    Supplier: Association {
      type: 'cds.Association',
      target: 'northwhisper.Suppliers',
      keys: [
        {
          ref: [ 'SupplierID' ],
          '$generatedFieldName': 'Supplier_SupplierID'
        }
      ]
    },
    Supplier_SupplierID: Integer { type: 'cds.Integer', '@odata.foreignKey4': 'Supplier' },
    UnitsInStock: Integer { type: 'cds.Integer' },
    Discontinued: Boolean { type: 'cds.Boolean' }
  }
}
```

However, due to how some of the detail is structured and stored, as
`LinkedDefintions` (see [Further info](#further-info)), we can sometimes
struggle to enumerate members. For example:

```javascript
> Main.entities
```

will just emit:

```javascript
[object Function]
```

Instead, we can use `.inspect`.

👉 Try it:

```javascript
> .inspect Main.entities
```

which produces:

```javascript
Main.entities: [Function (anonymous)] LinkedDefinitions {
  Products: [entity],
  Categories: [entity],
  Suppliers: [entity]
}
```

## Further info

- The [Wikipedia article on the
  REPL](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop) has
  some great background and history.
- The [cds Façade Object](https://cap.cloud.sap/docs/node.js/cds-facade) topic
  in Capire has a great overview.
- [LinkedDefinitions](https://cap.cloud.sap/docs/node.js/cds-reflect#iterable)
  is an iterable which is used to store all objects of a linked model.

## Footnotes

1. The co-founder of Microsoft, Paul Allen, on arriving at MITS in Albuquerque
   NM in March 1975 to demonstrate the BASIC interpreter that he and Bill Gates
   had worked on and were hoping to license, loads the code from the paper tape
   into the ALTAIR 8800 and at the BASIC prompt that appears, types `PRINT 2 +
   2`. This also appears subsequently as an example in the Introduction section
   of the [MITS ALTAIR
   BASIC](https://deramp.com/downloads/mfe_archive/010-S100%20Computers%20and%20Boards/00-MITS/40-Software/BASIC/Altair%20BASIC%203.0/Documentation/Altair_8800_BASIC_Reference_Manual_1975.pdf)
   manual. See the article [MITS licenses Altair BASIC from Bill Gates and Paul
   Allen](https://www.computinghistory.org.uk/det/5946/Bill-Gates-and-Paul-Allen-sign-a-licensing-agreement-with-MITS/)
   from the Centre for Computing History.
1. This is either a reference to a classic scene in [Spinal
   Tap](https://en.wikipedia.org/wiki/Up_to_eleven), or [yet another
   Schnapszahl](https://www.google.com/search?q=site%3Aqmacro.org+schnapszahl).
