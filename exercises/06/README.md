# 06 - Testing your services

In the previous exercise we checked the behaviour of our `Morse` service
definition by running `curl` commands to send HTTP requests to the CAP server
which we started with `cds watch`. This is a great way to interact, but no the
only one.

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

[!NOTE]
All commands you'll be entering in the rest of this subsection will be
in the context of the cds REPL, at the `>` prompt.

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

That was a little cumbersome, but there's a convenience method that we can use
instead of that ceremony, in the form of `cds.test()`.

👉 Restart the cds REPL:

```bash
cds repl
```

👉 Let's relaunch a test server, but at the same time, use destructuring to get
access to some of the features that the test mechanism offers:

```javascript
const { GET, POST, defaults, expect } = cds.test()
```

The project directory location can be specified as the first argument, but the
default is the current directory, which is what we want. We get pretty much the
same output as before (just the random port will most likely be different!).

### Set some defaults

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
    'content-type': 'application/json; charset=utf-8',
    'content-length': '50',
    date: 'Tue, 23 Jun 2026 10:03:52 GMT',
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

Specifying the full path each time would get a little tiresome, so we can use
the `defaults` also surfaced to us, and specify a default path.

👉 Do that now:

```javascript
defaults.path = '/odata/v4/morse'
```

👉 Now retry that, in short form:

```javascript
await GET `Controls`
```

Much nicer.











## Further info

- The [Testing with cds.test](https://cap.cloud.sap/docs/node.js/cds-test)
  topic in Capire has some really helpful sections and is definitely worth a
  read.

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
