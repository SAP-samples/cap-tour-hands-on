# 06 - Testing your services

In the previous exercise we checked the behaviour of our service
definition by starting the CAP server and then manually sending HTTP requests
to it. This is a great way to interact, but not the only one.

In this exercise we'll add tests which will put our service through its paces.
We'll do that first by exploring in the cds REPL and then formalising our
explorations in a file that we can drive with a test runner.

## Set things up for testing

Unlike most exercises in this CodeJam, we won't be starting a new project
directory for this exercise. We'll use the previous exercise content.

### Stay in the previous exercise directory

👉 Instead, stay in the project directory from the previous exercise, i.e.
`proj-05/`.

### Add the CAP Node.js test support package

Test support is in the form of a package that we should install for use at
design time. That package is
[@cap-js/cds-test](https://www.npmjs.com/package/@cap-js/cds-test).

In the previous exercise (the directory for which is where we are now, i.e.
`proj-05/`) we only created a `services.cds` file, relying on the globally
installed CDS development kit for everything.

Now, before we install the `@cap-js/cds-test` package, we'll need a
`package.json` file that has the appropriate settings for a CAP Node.js
project[<sup>1</sup>](#footnotes).

👉 Have a `package.json` generated for us (and remove the
directories that are also created but which we don't need):

```bash
cds add nodejs && rmdir app/ srv/ db/
```

<details>
<summary>Windows (PowerShell / cmd)</summary>

`cds add nodejs` is the same; only the directory removal differs.

PowerShell:

```powershell
cds add nodejs; Remove-Item -Recurse -Force app, srv, db
```

cmd:

```cmd
cds add nodejs && rmdir /s /q app srv db
```

</details>

👉 Install the `@cap-js/cds-test` package as a dev dependency:

```bash
npm install --save-dev @cap-js/cds-test
```

The resulting `package.json` should look something like this:

```json
{
  "name": "proj-05",
  "version": "1.0.0",
  "dependencies": {
    "@sap/cds": "^9"
  },
  "devDependencies": {
    "@cap-js/cds-test": "^1.0.1",
    "@cap-js/sqlite": "^2.4"
  },
  "scripts": {
    "start": "cds-serve"
  },
  "private": true
}
```

> [!NOTE]
> On a CDS 10+ project the generated `package.json` differs in a few ways worth
> keeping in mind here:
>
> - `@sap/cds` is pinned to `^10` and `@cap-js/sqlite` to `^3` (the v3 SQLite
>   driver uses Node.js' built-in `node:sqlite`, so there's no native
>   `better-sqlite3` to compile).
> - `cds init` sets `"type": "module"`, which makes Node.js treat `.js` files as
>   ES modules.
>
> That last point affects the **test file** we're about to write. The
> `test/transitions.test.js` shown later uses CommonJS (`const cds =
> require('@sap/cds')`). On a `"type": "module"` project that `require` throws
> `ReferenceError: require is not defined in ES module scope`, so you'd either
> name the file `transitions.test.cjs`, or keep `.js` and write it as an ES
> module — replacing `const cds = require('@sap/cds')` with `import cds from
> '@sap/cds'`. The `describe`/`it`/`expect` calls themselves are unchanged. This
> exercise targets v9, so the CommonJS test file is correct as written.

## Explore testing in the cds REPL

We're now ready to explore.

👉 Launch the cds REPL:

```bash
cds repl
```

whereupon we should only see the simple prompt, as we didn't request
a CAP server to be started (with `--run`):

```log
Welcome to cds repl v9.9.1
>
```

Instead, we'll request one in the context of the test support package.

> [!NOTE]
> All commands you'll be entering in the rest of this subsection will be
> in the context of the cds REPL, at the `>` prompt.

### Meet the Test class

At the core of the test support package is the `Test` class, an instance of
which can be used to start a test server. Let's explore that first.

👉 Create an instance of the `Test` class:

```javascript
const { Test } = cds.test
const mytest = new Test
```

👉 Now use that instance to start a test server:

```javascript
mytest.run().in('.')
```

What is emitted should look something like this:

```log
Test {}
> [cds] - loaded model from 1 file(s):

  services.cds

[cds] - connect to db > sqlite { url: ':memory:' }
/> successfully deployed to in-memory database.

[cds] - using auth strategy { kind: 'mocked' }
[cds] - serving Morse {
  at: [ '/odata/v4/morse' ],
  decl: 'services.cds:15'
}
[cds] - server listening on { url: 'http://localhost:45167' }
[cds] - server v9.9.1 launched in 13275 ms
[cds] - [ terminate with ^C ]
```

Look familiar? Sure, it's a CAP server in the equivalent of `watch` mode,
listening on a random port.

> You may not see a cds REPL prompt (`>`) at this point, that's just because
> the prompt did appear, but then was obscured by the CAP server log output.
> Just hit `<Enter>` to get to a prompt if this is the case.

So far so good.

👉 Exit the cds REPL (with `Ctrl-D`).

### Use the cds.test convenience method

Summoning and invoking that test mechanism was a little cumbersome, but there's
a convenience method that we can use instead of that ceremony, in the form of
`cds.test()`.

👉 Restart the cds REPL:

```bash
cds repl
```

👉 Let's relaunch a test server, but at the same time, use destructuring to get
access to some of the features that the test mechanism offers:

```javascript
const { GET, POST, defaults } = cds.test()
```

The project directory location can be specified as the first argument, but the
default is the current directory, which is what we want. We get pretty much the
same output as before (just the random port will most likely be different!).

### Try a first test request

What we have in the destructured items are conveniences for testing.

We can see from the test server output that our service is being provided via
the default protocol (OData v4) and the path is default too:

```text
/odata/v4/morse
```

We know from the previous exercise that we have the `Controls` entity, so we
can use the `GET` feature to request the entityset.

👉 Do that now:

```javascript
await GET `/odata/v4/morse/Controls`
```

The output we see is from the `GET` mechanism provided from the test mechanism,
and is a `Response` object that looks like this:

```javascript
Response {
  status: 200,
  statusText: 'OK',
  headers: Headers {
    'x-powered-by': 'Express',
    'x-correlation-id': '8d684204-38ad-4e2e-9b93-03b69ac345f2',
    'odata-version': '4.0',
    'content-type': 'application/json; charset=utf-8', 'content-length': '50',
    date: '...',
    connection: 'keep-alive',
    'keep-alive': 'timeout=5'
  },
  body: ReadableStream { locked: true, state: 'closed', supportsBYOB: true },
  bodyUsed: true,
  ok: true,
  redirected: false,
  type: 'basic',
  url: 'http://localhost:41083/odata/v4/morse/Controls'
}
```

### Take advantage of the defaults object

Specifying the full path each time would get a little tiresome, so we can use
`defaults` which we also picked out in the destructuring, and specify a default
path.

👉 Do that now:

```javascript
defaults.path = '/odata/v4/morse'
```

👉 Now retry that, in short form:

```javascript
await GET `Controls`
```

Much nicer!

### Try a POST test request

As well as the `GET` affordance, we picked out `POST` when we invoked
`cds.test()`, so let's try that out too.

👉 Make an HTTP POST request to convey an OData Create operation, specifying
the payload (`{ID:1}`), and capturing a couple of the items that `POST`
returns, i.e. the `status` and `data`:

```javascript
{ status, data } = await POST('Controls', {ID:1})
```

Here's what this emits:

```log
[odata] - POST /odata/v4/morse/Controls
Response {
  status: 201,
  statusText: 'Created',
  headers: Headers {
    'x-powered-by': 'Express',
    'x-correlation-id': '6be73e96-1ba8-4b21-919c-80573f7bbf66',
    'odata-version': '4.0',
    location: 'Controls(1)',
    'content-type': 'application/json; charset=utf-8',
    'content-length': '75',
    date: 'Tue, 23 Jun 2026 12:18:06 GMT',
    connection: 'keep-alive',
    'keep-alive': 'timeout=5'
  },
  body: ReadableStream { locked: true, state: 'closed', supportsBYOB: true },
  bodyUsed: true,
  ok: true,
  redirected: false,
  type: 'basic',
  url: 'http://localhost:38939/odata/v4/morse/Controls'
}
```

👉 Let's have a look what we got:

```javascript
[status, data]
```

Nice - it's the response status and payload (as we'd sort of expect):

```javascript
[
  201,
  {
    '@odata.context': '$metadata#Controls/$entity',
    ID: 1,
    position: 'Neutral'
  }
]
```

At this point, we're done with the cds REPL.

👉 Exit the cds REPL with `Ctrl-D`.

## Build a series of tests

Now that we've got a feel for the support for testing, let's create our first
test. Traditionally these files are like normal language-based files except
they have a `.test` inserted just before the extension.

Also traditionally, the test support package will look for such files in a
`test/` directory.

### Create a test file

👉 Create `transitions.test.js` in a new `test/` directory, with the following
content:

```javascript
const cds = require('@sap/cds')
const { GET, POST, defaults, expect } = cds.test('.')
defaults.path = '/odata/v4/morse'

describe('Initial controls', () => {

})
```

> [!NOTE]
> On a CDS 10+ project (where `"type": "module"` is set), write this as an ES
> module instead — only the first line changes, from `require` to `import`:
>
> ```javascript
> import cds from '@sap/cds'
> const { GET, POST, defaults, expect } = cds.test('.')
> defaults.path = '/odata/v4/morse'
>
> describe('Initial controls', () => {
>
> })
> ```
>
> Everything else in the file — `cds.test('.')`, `defaults.path`, and the
> `describe`/`it`/`expect` calls added throughout the rest of this exercise —
> stays exactly the same. `cds test` discovers and runs `*.test.js` files the
> same way whether they're CommonJS or ES modules. (This exercise targets v9, so
> the CommonJS version above is correct as written.)

This is a simple harness for our tests.

👉 Take a moment to see what differs from our explorations in the cds REPL
earlier:

- we also bring in `expect` in the destructuring, which gives us the common
  test building block from the Chai Assertion Library (see [Further
  info](#further-info))
- the argument to `cds.test()` is `.`, i.e. "this current (project) directory",
  just to be more explicit
- as is traditional, we're using `describe` to create a (named) "group" for
  tests that logically belong together

### Invoke the test runner to check the file

Actually, we should think about this testing context in two parts - the test
definitions themselves, and the test runner that executes the test definitions
and reports on the results.

We have a choice of test runner (see the [Running
Tests](https://cap.cloud.sap/docs/node.js/cds-test#running-tests) section of
the "Testing with cds.test" topic linked in [Further info](#further-info));
we'll use CAP's `cds test` - a thin wrapper around Node.js's built-in test
runner, which makes it easier to fetch tests and provides a cleaner output.

As we've installed the requisite `@cap-js/cds-test` package, we can invoke `cds
test`.

👉 Let's do that now, with the `--list` option to make sure that it can find
our test file:

```bash
cds test --list
```

```log
Found these matching test files:

   test/transitions.test.js

 1 total
```

Yup.

### Execute the (non-existent) tests

It's worth seeing what happens when we request the tests to be run. The `cds
test` command has an `--unmute` option, which will stop the suppression of
output that we would not normally want when running the tests for real (for
example in a Continuous Integration (CI) scenario).

But as we're just starting out, that's what we'll use initially.

👉 Let's try that now:

```bash
cds test --unmute
```

We see something like this:

```log
[cds] - loaded model from 1 file(s):

  services.cds

[cds] - connect to db > sqlite { url: ':memory:' }
/> successfully deployed to in-memory database.

[cds] - using auth strategy { kind: 'mocked' }
[cds] - serving Morse {
  at: [ '/odata/v4/morse' ],
  decl: 'services.cds:15'
}
[cds] - server listening on { url: 'http://localhost:45211' }
[cds] - server v9.9.1 launched in 640 ms

 0.720s

```

Nothing unfamiliar, which is a good sign! In case you're wondering, the
`0.720s` measurement is from the test runner itself, not from the test server
that was automatically started.

We can feel comfortable that this situation is just like we experienced in
the cds REPL.

### Add a first test

Now that we have everything in place, let's add a first test.

👉 Inside the `describe` block in `test/transitions.test.js`, add this:

```javascript
  it('initially returns an empty list', async () => {
    const { data } = await GET('Controls')
    expect(data.value).to.deep.equal([])
  })
```

Here are some notes on this test definition:

- `it` defines a name conveying a brief test description ("initially returns an
  empty list") and a function that holds the expectation(s) that should be
  checked
- the expectation to be checked relates to what's returned from fetching the
  `/odata/v4/morse/Controls` resource; the `GET` mechanism makes this response
  payload available in the `data` object which we grab via destructuring
- the expectation here is that we are going to get an empty list (`[]`)
- we refer to `data.value` in the expectation as - in the resource that's
  returned[<sup>2</sup>](#footnotes) - it's the `value` property that has the
  actual data
- the `deep` part of the expectation relates to the fact that `[]` does not
  equal `[]`, and so we need a special library for such comparisons (see
  [Further info](#further-info) for a link to a the library and also a classic
  talk on the quirks of JavaScript)

### Re-invoke the test runner

👉 Now that we have an actual test, let's re-invoke the test runner:

```bash
cds test --unmute
```

We get output like this:

```log
[cds] - loaded model from 1 file(s):

...

[cds] - serving Morse {
  at: [ '/odata/v4/morse' ],
  decl: 'services.cds:15'
}
[cds] - server listening on { url: 'http://localhost:37143' }
[cds] - server v9.9.1 launched in 4332 ms
[odata] - GET /odata/v4/morse/Controls

  Initial controls
    ✔ initially returns an empty list

 1 passed
 4.631s
```

We can see that a CAP server was started again. We can see evidence of the
GET request for the `Controls` entityset (`[odata] - GET
/odata/v4/morse/Controls`).

We can also see that the test passed; it's shown with its name ("initially
returns an empty list") within its containing group ("Initial controls").

Great!

> From now on, we'll omit the `--unmute` option as we now know what's going on,
> and it will be easier to discern the test results without the extra noise.

### Add more tests to the group

Let's add some more simple tests to the "Initial controls" test group.

Edit the test group (`describe( ... )`) so that it now looks like this:

```javascript
describe('Initial controls', () => {

  it('initially returns an empty list', async () => {
    const { data } = await GET('Controls')
    expect(data.value).to.deep.equal([])
  })

  it('allows the creation of new controls', async () => {
    const { status } = await POST('Controls', { ID: 1 })
    expect(status).to.equal(201)
  })

  it('gives new controls a Neutral default position', async () => {
    const { data } = await POST('Controls', { ID: 2 })
    expect(data.position).to.equal('Neutral')
  })

  it('prevents positions being specified on creation', async () => {
    const { data } = await POST('Controls', { ID: 3, position: "Random" })
    expect(data.position).to.equal('Neutral')
  })

})
```

### Re-invoke the test runner again

If we now invoke the test runner, we should see each of the tests executed.

👉 Let's do that now:

```bash
cds test
```

The output should look something like this:

```log
  Initial controls
    ✔ initially returns an empty list
    ✔ allows the creation of new controls
    ✔ gives new controls a Neutral default position
    ✔ prevents positions being specified on creation

 4 passed
 0.846s
```

Excellent!

### Add one more test group

We can continue to add tests, grouped logically.

Let's add one more group of tests relating to the checking of what the
status-transition flow restrictions bring about.

👉 Add this new test group to the end of the `test/transitions.test.js` file:

```javascript
describe('Transitions', () => {

  it('allows moving from Neutral to Forward', async () => {
    const { status } = await POST('Controls/1/engageForward')
    expect(status).to.equal(204)
  })

  it('tracks the position after engagement', async () => {
    const { data } = await GET('Controls/1')
    expect(data.position).to.equal('Forward')
  })

  it('prevents moving from Forward directly to Reverse', async () => {
    const { data } = await POST(
      'Controls/1/engageReverse',
      null,
      { validateStatus: status => status == 409 }
    )
    expect(data.error.code).to.equal('INVALID_FLOW_TRANSITION_SINGLE')
  })

  it('allows moving from Forward to Neutral', async () => {
    const { status } = await POST('Controls/1/engageNeutral')
    expect(status).to.equal(204)
  })

  it('allows moving from Neutral to Reverse', async () => {
    const { status } = await POST('Controls/1/engageReverse')
    expect(status).to.equal(204)
  })

})
```

> Here's a note on the test "prevents moving from Forward directly to Reverse".
>
> The testing mechanisms in use will abort and cause the test to fail if the HTTP
> response code is unexpected. What's expected is any code that fits in to the
> default condition which is `status >= 200 && status < 300`. But we actually want
> a 409 response code ("Conflict"), so need to pass a custom function for
> `validateStatus` as a third argument to `POST()` (the second argument is to
> convey any payload for the call, but there is no payload for this action
> invocation, hence `null`).

### Invoke the test runner one last time

Let's see where we are with our tests.

👉 Invoke the runner:

```bash
cds test
```

We should see output like this:

```log
  Initial controls
    ✔ initially returns an empty list
    ✔ allows the creation of new controls
    ✔ gives new controls a Neutral default position
    ✔ prevents positions being specified on creation

  Transitions
    ✔ allows moving from Neutral to Forward
    ✔ tracks the position after engagement
    ✔ prevents moving from Forward directly to Reverse
    ✔ allows moving from Forward to Neutral
    ✔ allows moving from Neutral to Reverse

 9 passed
 0.702s
```

If you do, well done!

## Further info

- The [Testing with cds.test](https://cap.cloud.sap/docs/node.js/cds-test)
  topic in Capire has some really helpful sections and is definitely worth a
  read.
- Read more about the [Chai Assertion Library](https://www.chaijs.com/)
  portable across various JavaScript testing frameworks.
- Gary Bernhardt's classic lightning talk
  [Wat](https://www.destroyallsoftware.com/talks/wat) is great, regardless of
  your views on JavaScript (and Ruby[<sup>3</sup>](#footnotes)) :-)
- The [deep-eql](https://github.com/chaijs/deep-eql) library is used by Chai
  for non-trivial and / or reference-laden comparisons

---

## Questions

1. In our [first test request](#try-a-first-test-request) we specified the
   relative path in backticks (`` `...` ``) rather than single or double
   quotes. Why?

1. The CDS command line interface `cds` actually has a facet that helps us with
   setting up tests like this. What is it, and what does it do?

---

## Footnotes

1. Otherwise we would end up with a super-minimal `package.json` created when
   installing `@cap-js/cds-test`, like this:

    ```json
    {
      "devDependencies": {
        "@cap-js/cds-test": "^1.0.1"
      }
    }
    ```

1. The resource requested is an OData v4 entityset, and the default
   representation is in JSON:

    ```bash
    ; curl localhost:4004/odata/v4/morse/Controls
    {
      "@odata.context": "$metadata#Controls",
      "value": []
    }
    ```

1. As you'll see in the talk, Ruby has an lovely `method_missing` construct,
   similar to Smalltalk's `#doesNotUnderstand` which is amongst the many
   wonderful influences for CAP - see the [Everything is a
   service](https://qmacro.org/blog/posts/2024/12/10/tasc-notes-part-4/#everything-is-a-service)
   section of [the notes to The Art and Science of CAP part
   4](https://qmacro.org/blog/posts/2024/12/10/tasc-notes-part-4/).
1. See <https://github.com/axios/axios> and specifically the default
   implementation of `validateStatus`.
