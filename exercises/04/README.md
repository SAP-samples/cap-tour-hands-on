# 04 - Using the REPL

In any language or development environment, having a REPL is a superpower, and
it pays to embrace it and be at least a little familiar with it. CAP as a whole
is built on solid foundations and practices that have matured over the decades,
and the REPL is part of that, first appearing in the 1960's and initially
popularised in the LISP and LISP-derivative language communities.

Node.js has a REPL, and it is upon this REPL that the cds REPL is based. In this
exercise, we'll explore the cds REPL.

## Start a new CAP project

Like we did in an earlier exercise, we'll start with the "base project" to save
a bit of time.

👉 Create a new project directory for this exercise using the base project:

```bash
rm -rf proj-04 \
  && cp -a baseproj proj-04 \
  && cd $_
```

<details>
<summary>Windows (PowerShell)</summary>

```powershell
Remove-Item -Recurse -Force proj-04 -ErrorAction SilentlyContinue
Copy-Item -Recurse baseproj proj-04
Set-Location proj-04
```

</details>

<details>
<summary>Windows (cmd)</summary>

```cmd
rmdir /s /q proj-04 2>nul & xcopy baseproj proj-04 /e /i /q & cd proj-04
```

</details>

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
Welcome to cds repl v10.0.3
>
```

whereupon, to honour one of the pivotal moments in the birth of personal
computing[<sup>1</sup>](#footnotes), there's only one thing we should type in
at this point, and that's `2 + 2`:

```javascript
> 2 + 2
4
```

> In subsequent suggested cds REPL commands for you to enter, the prompt (`>`)
> won't be shown, unless it's part of an illustration that includes output from
> that command.

Yes, this Node.js based REPL expects and interprets JavaScript, unsurprisingly.

## Explore the commands

The cds REPL adds a few extra commands to the standard Node.js REPL.

👉 Look at what commands are available:

```javascript
.help
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

### Try out .inspect

The `.inspect` command is a configurable structure viewer, effectively. It
gives us a comfortable way of looking at structures, either as part of the CAP
runtime, or as part of a model.

Take the CDS facade as an example - the entrypoint to the surface area of CAP
facilities (See [Further info](#further-info)). In the cds REPL, it's available
by default, injected into the context.

👉 Take a look:

```javascript
cds
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
Object.keys(cds)
```

This is a little cumbersome, and also is a bit too far the other way (not
enough information):

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

This is where `.inspect` comes in, the [dialectical
third](https://en.wikipedia.org/wiki/Goldilocks_and_the_Three_Bears#:~:text=this%20as%20the%20%22-,dialectical%20three,-%22%20where%20%22the%20first)
option - just right.

👉 Give it a go:

```javascript
.inspect cds
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
default (`.inspect .depth=2`). It goes all the way to
11[<sup>2</sup>](#footnotes).

### Try out .run

In the output from `.inspect cds` just now, there were fewer than 20 properties
shown. Some of these, such as `model`, `db` and `services` were also either
undefined or empty. That's because we're not currently running any CAP server
in the context of this cds REPL session (and thus there's no model, no database
connection, and no services).

With the `.run` command we can change that, and start up a server.

👉 Try that now, specifying `.` as the location for the project definitions,
i.e. the `proj-04/` directory we're in:

```javascript
.run .
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
[cds] - server v10.0.3 launched in 872550 ms
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
as `Products`, `db` and `Main`, by typing them into the cds REPL prompt. Try to
notice not only the different object types:

- `Products`: `entity`
- `db`: `SQLiteService`
- `Main`: `ApplicationService`

but also each object's component parts. For example we can see the element
details in the `Products` entity:

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
`LinkedDefinitions` (see [Further info](#further-info)), we can sometimes
struggle to enumerate members in a way we would normally expect. For example:

```javascript
Main.entities
```

will just emit:

```javascript
[object Function]
```

> [!NOTE]
> On cds 10 and higher this situation is improved — the cds REPL expands
> `LinkedDefinitions` for you, so typing `Main.entities` there will already show
> the entities (much like the `.inspect` output below) rather than the terse
> `[object Function]`. So if you're on cds 10+, your output here may not match
> what's shown — that's expected, and a welcome improvement.

Instead, we can use `.inspect`.

👉 Try it:

```javascript
.inspect Main.entities
```

which produces:

```javascript
Main.entities: [Function (anonymous)] LinkedDefinitions {
  Products: [entity],
  Categories: [entity],
  Suppliers: [entity]
}
```

> Of course, we can use other techniques to access this information, such as
> with the spread syntax (`[...Main.entities]`)[<sup>3</sup>](#footnotes) or
> using destructuring (`{ Products } = Main.entities`). Exploration of these
> approaches is left as an exercise for you, dear reader.

### Revisit the inspection of the CDS facade

Now that we have a running server in the cds REPL, let's revisit the CDS facade.

👉 Re-inspect it now:

```javascript
.inspect cds
```

This time, we see lots more top-level properties:

```javascript
cds: cds {
  _events: [Object: null prototype],
  _eventsCount: 6,
  _maxListeners: undefined,
  model: [LinkedCSN],
  db: [SQLiteService],
  cli: [Object],
  root: '/work/gh/github.com/SAP-samples/cap-tour-hands-on/proj-04',
  services: [Object],
  extend: [Function (anonymous)],
  home: '/home/dj/.npm-packages/lib/node_modules/@sap/cds-dk/node_modules/@sap/cds',
  version: '9.9.1',
  parse: [Function],
  utils: [Object],
  options: [Object],
  env: [Config],
  plugins: [Promise],
  server: [AsyncFunction],
  log: [Function],
  builtin: [Object],
  service: [Function],
  requires: {},
  app: [Function],
  debug: [Function: cds_debug],
  resolve: [Function],
  load: [Function],
  compile: [Function],
  deploy: [Function],
  edmxs: null,
  minify: [Function],
  type: [class type extends any],
  linked: [Function],
  entity: [class entity extends struct],
  connect: [AsyncFunction],
  Service: [Function]
  infer: [Function],
  ql: [Function],
  compiler: [Object],
  EventContext: [Function],
  User: [Function],
  serve: [Function (anonymous)],
  i18n: [I18nFacade],
  ApplicationService: [Function],
  middlewares: [Object],
  Request: [Function: Request],
  shutdown: [AsyncFunction: _shutdown],
  Symbol(shapeMode): false,
  Symbol(kCapture): false
}
```

All of the empty properties mentioned earlier now have values.

👉 Take a moment to explore these, with, for example:

- `cds.model` (effectively the compiled model, in an internal CSN
  representation)
- `cds.db === db` (yes, the database property points to the `db` service)
- `[...cds.services].map(x => [x.name, x.kind])` (a look at each service and
  their kinds)

### Try out query construction and .ql

While this section fits in naturally with the flow (we've tried out the other
cds REPL specific commands `.run` and `.inspect` so far), we need to take a
step back a little first.

The `.ql` command switches us into a different cds REPL mode where we can
enter query constructs directly. But before we do that, it's worth taking
a moment to explore queries in more general terms. So let's do that
first.

In CAP, query objects are first class citizens and essential to our
understanding of the fundamentals. There are many ways of constructing and
executing queries (see [Further info](#further-info)) - let's start with the
REST-style API.

#### Explore the REST-style API

Let's read the details of the "Chai" product, using the `db` variable that's been
made available to us.

👉 First, let's remind ourselves of what `db` represents:

```javascript
db
```

It's a `SQLiteService` object representing the database connection, effectively:

```javascript
SQLiteService {
  name: 'db',
  options: [Object],
  kind: 'sqlite',
  model: [LinkedCSN],
  handlers: [EventHandlers],
  definition: undefined,
  pools: [Object],
  class: [Function],
  _source: '/home/dj/.npm-packages/lib/node_modules/@sap/cds-dk/node_modules/@cap-js/sqlite/index.js',
  onDELETE: [AsyncFunction: deep_delete]
}
```

We can call HTTP style methods on this object, passing objects that represent
the entities, objects that have also been made available in the cds REPL
context.

👉 Try that now, with a `get` method:

```javascript
db.get(Products).where({ProductName:'Chai'})
```

What we get from this is a little unexpected, but very enlightening:

```javascript
cds.ql {
  SELECT: {
    from: { ref: [ 'northwhisper.Products' ] },
    where: [ { ref: [ 'ProductName' ] }, '=', { val: 'Chai' } ]
  }
}
```

It's a representation (in CQN) of the first class query object we've just constructed.

> For the deepest dive you could ever wish for on queries and expressions,
> covering CDL, CSN, CQL, CQN, CXL and CXN, have a look at the [CDS expressions
> in
> CAP](https://qmacro.org/blog/posts/2025/12/09/a-new-hands-on-sap-dev-mini-series-on-the-core-expression-language-in-cds/)
> series of videos and accompanying detailed blog posts.

OK, so we have a query object. What should we do with it? Well, we can send it
to the database to be executed, via the `run` method of the `db` object.

👉 But first, for convenience, and to meditate for a second on the nature of
queries as first class objects, let's re-create the query and assign the
resulting query object to a variable:

```javascript
chai = db.get(Products).where({ProductName:'Chai'})
```

👉 Now let's send it to be executedL

```javascript
db.run(chai)
```

Oh:

```javascript
Promise {
  <pending>,
  Symbol(async_id_symbol): 223,
  Symbol(trigger_async_id_symbol): 2
}
```

More [gratification delay](https://en.wikipedia.org/wiki/Delayed_gratification)!

👉 As with most things in Node.js, execution is asynchronous. So we need to
`await` the call:

```javascript
await db.run(chai)
```

Success!

```javascript
[
  {
    ProductID: 1,
    ProductName: 'Chai',
    UnitPrice: 18,
    Category_CategoryID: 1,
    Supplier_SupplierID: 1,
    UnitsInStock: 39,
    Discontinued: false
  }
]
```

Actually, we can await the query directly, and the default behaviour for such
query objects is to be executed via `db.run`:

👉 Let's try that:

```javascript
await chai
```

This, therefore, gives us the same effect. Nice!

#### Explore the CRUD-style API

Let's spend a brief moment on the CRUD-style API (see also [Further
info](#further-info)), which is an alternative set of convenience methods to
contruct queries.

👉 Let's have a look at a luxury product, using `read` (the "R" in "CRUD")
instead of the more HTTP-like `get`):

```javascript
await db.read(Products).where({ProductName:{'like':'%Kaviar%'}})
```

which shows us:

```javascript
[
  {
    ProductID: 73,
    ProductName: 'Röd Kaviar',
    UnitPrice: 15,
    Category_CategoryID: 8,
    Supplier_SupplierID: 17,
    UnitsInStock: 101,
    Discontinued: false
  }
]
```

👉 Let's try another CRUD-style method to update the price:

```javascript
await db.update(Products).set({UnitPrice: 20}).where({ProductID:73})
```

The number of rows affected is returned:

```javascript
1
```

So this was a little taste of an alternative API.

Both styles of API we've seen so far are essentially convenience methods that
build query objects that can also be constructed more "natively" with the
`cds.ql` method. Let's explore that now.

#### Explore cds.ql and its fluent API helper functions

Querying in CAP Node.js revolves around `cds.ql` which also sports useful
helper functions (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) which makes for a
fluent-style API approach to query construction. [The world is our
oyster](https://nosweatshakespeare.com/quotes/famous/the-worlds-your-oyster/)!

👉 Try constructing a query using one of these helper functions.

```javascript
q = SELECT.from(Products).where({UnitPrice:20}).orderBy({ProductName:'desc'})
```

This will produce an object that, represented in CQN, looks like this:

```javascript
cds.ql {
  SELECT: {
    from: { ref: [ 'northwhisper.Products' ] },
    where: [ { ref: [ 'UnitPrice' ] }, '=', { val: 20 } ],
    orderBy: [ { ref: [ 'ProductName' ], sort: 'desc' } ]
  }
}
```

Note that the "class" is `cds.ql`, indicating that the `SELECT` indeed helped
us construct a query object.

And of course, `await`ing the query object will cause it to be executed:

```javascript
> await q
[
  {
    ProductID: 73,
    ProductName: 'Röd Kaviar',
    UnitPrice: 20,
    Category_CategoryID: 8,
    Supplier_SupplierID: 17,
    UnitsInStock: 101,
    Discontinued: false
  },
  {
    ProductID: 49,
    ProductName: 'Maxilaku',
    UnitPrice: 20,
    Category_CategoryID: 3,
    Supplier_SupplierID: 23,
    UnitsInStock: 10,
    Discontinued: false
  }
]
```

What if we were to not use the `SELECT` helper function, and instead pass some
CQL directly to `cds.ql`? What would that look like?

Let's try it:

```javascript
cds.ql `select from Products where UnitPrice = 20 order by ProductName desc`
```

What's produced is a query object that's pretty much the same as before:

```javascript
cds.ql {
  SELECT: {
    from: { ref: [ 'Products' ] },
    where: [ { ref: [ 'UnitPrice' ] }, '=', { val: 20 } ],
    orderBy: [ { ref: [ 'ProductName' ], sort: 'desc' } ]
  }
}
```

Now we're getting to the heart of queries, the facilities that revolve around
and are supported by `cds.ql`. You'll find that the flexibility and power of
CQL means that you'll likely want to use `cds.ql` more often than you think.

And for that, there's a special mode in the cds REPL.

#### Invoke the .ql command

That mode is "cql" mode, and is what we get to with the third of the three cds
REPL specific commands.

👉 Enter the "cql" mode by using the `.ql` command, whereupon the prompt will
change from the standard "JavaScript" mode prompt (`>`) to the "cql" prompt:

```javascript
> .ql
cql>
```

Here we can enter CQL comfortably and directly, and it gets passed to `cds.ql`,
turned into a query object, and executed.

Re-try that CQL but in "direct" fashion here in "cql" mode:

```sql
select from Products where UnitPrice = 20 order by ProductName desc
```

The query result is provided without fanfare, exactly what we want:

```javascript
[
  {
    ProductID: 73,
    ProductName: 'Röd Kaviar',
    UnitPrice: 20,
    Category_CategoryID: 8,
    Supplier_SupplierID: 17,
    UnitsInStock: 101,
    Discontinued: false
  },
  {
    ProductID: 49,
    ProductName: 'Maxilaku',
    UnitPrice: 20,
    Category_CategoryID: 3,
    Supplier_SupplierID: 23,
    UnitsInStock: 10,
    Discontinued: false
  }
]
```

There's so much more to explore here (and not enough space!), so please refer
to the "Querying in JavaScript" link in the [Further info](#further-info)
section.

If we were to ask for `.help` at this point in "cql" mode, we'd see the command
that takes us back to the "JavaScript" prompt is `.js`.

👉 Switch back now:

```javascript
.js
```

## Explore CAP building blocks by creating a new service

With access to the entire CDS facade and an executable CAP "interpreter" at our
fingertips, we can do pretty much anything we want. Let's finish off this
exercise by creating a service from scratch and sending a message to it. Why?
So we understand the fundamentals and get a better understanding of what
services and messages really are.

### Explore the Main handlers

👉 First, revisit the `Main` service object and have a look at its handlers:

```javascript
Main.handlers
```

This shows us that there are many built-in handlers (remember, one of the key
reasons to use CAP is that [the code is in the
framework](https://qmacro.org/blog/posts/2024/11/07/five-reasons-to-use-cap/#1-the-code-is-in-the-framework-not-outside-of-it)):

```javascript
EventHandlers {
  _initial: [
    {
      before: '*',
      handler: [Function: check_service_level_restrictions]
    },
    { before: '*', handler: [Function: check_auth_privileges] },
    { before: '*', handler: [Function: check_readonly] },
    { before: '*', handler: [Function: check_insertonly] },
    { before: '*', handler: [Function: check_odata_constraints] },
    { before: '*', handler: [Function: check_autoexposed] },
    { before: '*', handler: [AsyncFunction: enforce_auth] },
    { before: 'READ', handler: [Function: restrict_expand] },
    { before: 'CREATE', handler: [AsyncFunction: validate_input] },
    { before: 'UPDATE', handler: [AsyncFunction: validate_input] },
    { before: 'NEW', handler: [AsyncFunction: validate_input] },
    { before: 'READ', handler: [Function: handle_paging] },
    { before: 'READ', handler: [Function: handle_sorting] }
  ],
  before: [],
  on: [
    { on: 'CREATE', handler: [AsyncFunction: handle_crud_requests] },
    { on: 'READ', handler: [AsyncFunction: handle_crud_requests] },
    { on: 'UPDATE', handler: [AsyncFunction: handle_crud_requests] },
    { on: 'UPSERT', handler: [AsyncFunction: handle_crud_requests] },
    { on: 'DELETE', handler: [AsyncFunction: handle_crud_requests] }
  ],
  after: [
    { after: 'CREATE', handler: [AsyncFunction (anonymous)] },
    { after: 'UPSERT', handler: [AsyncFunction (anonymous)] },
    { after: 'UPDATE', handler: [AsyncFunction (anonymous)] }
  ],
  _error: []
}
```

We're looking at a basic building block in CAP here; after all, [everything is
a
service](https://qmacro.org/blog/posts/2024/12/10/tasc-notes-part-4/#everything-is-a-service)!
What's more, [services are
cheap](https://github.com/qmacro/capref/blob/main/axioms/AXI004.md)!

### Create a new basic service

We saw earlier that `Main` has the type `ApplicationService`, effectively an
instance of the `cds.ApplicationService` class.

Capire's "Core Services" topic
(see [Further info](#further-info)) tells us that `cds.ApplicationService` is
built upon the base class `cds.Service` which has everything we need for the
behaviour of reacting to messages through execution of registered event handlers.

👉 So let's create a new instance of `cds.Service`, as that's all we should need:

```javascript
srv = new cds.Service
```

This should emit something like this:

```javascript
Service {
  name: 'Service',
  options: {},
  handlers: [EventHandlers],
  definition: undefined
}
```

If we were to look at the handlers, we'd see that -- in contrast to `Main`'s
handlers -- there are none yet:

```javascript
> srv.handlers
EventHandlers {
  _initial: [],
  before: [],
  on: [],
  after: [],
  _error: []
}
```

### Send a message

That means that there will be nothing to handle anything.

👉 Try one anyway:

```javascript
await srv.send('codejam', { location: 'Rot' })
```

The message is sent, but there's no reaction.

### Define a handler

What's [the simplest thing that could possibly
work](https://creators.spotify.com/tech-aloud/episodes/SAP-BTP-runtimes--my-personal-considerations-and-preferences-on-Cloud-Foundry--Kyma--ABAP-runtimes---Mauricio-Lauffer---18-Jun-2025-e34tadv)
here as a handler? How about just `console.log`[<sup>4</sup>](#footnotes):

```javascript
srv.on('codejam', console.log)
```

This is now visible in the list of handlers:

```javascript
> srv.handlers
EventHandlers {
  _initial: [],
  before: [],
  on: [ { on: 'codejam', handler: [Function: log] } ],
  after: [],
  _error: []
}
```

but more importantly, what will happen now?

👉 Try sending another message:

```javascript
await srv.send('codejam', { before: 'reCAP' })
```

We see this:

```log
Request { method: 'codejam', data: { before: 'reCAP' } } [AsyncFunction: next]
```

What we see here are two arguments that the handler received:

- a `Request` object with the message payload
- a `next` function to enable the calling of any further handlers in the
  interceptor stack

> For more on further handlers, the interceptor stack, and - crucially - the
> difference between synchronous request/response style messages and
> asynchronous events (reflected in the difference between `srv.send` and
> `srv.emit`), see the [Creating a service from
> scratch](https://qmacro.org/blog/posts/2025/07/21/a-recap-intro-to-the-cds-repl/#creating-a-service-from-scratch)
> section of [A reCAP intro to the cds
> REPL](https://qmacro.org/blog/posts/2025/07/21/a-recap-intro-to-the-cds-repl/).

There's so much more to explore in the cds REPL, but we'll finish here. Well
done!

## Further info

- The [Wikipedia article on the
  REPL](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop) has
  some great background and history.
- The [cds Façade Object](https://cap.cloud.sap/docs/node.js/cds-facade) topic
  in Capire has a great overview.
- [LinkedDefinitions](https://cap.cloud.sap/docs/node.js/cds-reflect#iterable)
  is an iterable which is used to store all objects of a linked model.
- The [Core Services](https://cap.cloud.sap/docs/node.js/core-services) topic
  in Capire provides comprehensive coverage of the various query contexts and
  construction mechanisms (including
  [REST-style](https://cap.cloud.sap/docs/node.js/core-services#rest-style-api)
  and
  [CRUD-style](https://cap.cloud.sap/docs/node.js/core-services#crud-style-api)
  APIs). It also covers `cds.Service` and `cds.ApplicationService`.
- Capire's [Querying in JavaScript](https://cap.cloud.sap/docs/node.js/cds-ql)
  topic has a wealth of information that goes far beyond what we've covered in
  this exercise.

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
1. MDN is a great resource, and has a section on JavaScript's [Spread syntax
   (...)](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Spread_syntax).
1. The beauty of JavaScript is in evidence here - handlers are provided as
   functions (as `srv.on` is a [higher order
   function](https://en.wikipedia.org/wiki/Higher-order_function) which takes a
   handler function as one of its arguments, and `console.log` is a function, and
   thus perfectly valid to provide here.
