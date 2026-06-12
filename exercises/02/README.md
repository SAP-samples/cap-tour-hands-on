# 02 - Mocking messaging

In [Five reasons to use
CAP](https://qmacro.org/blog/posts/2024/11/07/five-reasons-to-use-cap/), we see
that [everything is an
event](https://qmacro.org/blog/posts/2024/11/07/five-reasons-to-use-cap/#:~:text=%22Everything%20is%20an%20event%22).
Whether synchronous, such as via HTTP requests and responses for OData
operations, or asynchronous, where messages are emitted and received for
decoupled service-to-service communications.

The [Messaging](https://cap.cloud.sap/docs/node.js/messaging) topic in Capire
has a great overview and an explanation of all the different message brokers
that can be used. And there's one that is well suited for local-first
development: [File based
messaging](https://cap.cloud.sap/docs/node.js/messaging#file-based), which
we'll explore in this exercise.

## Create a containing project directory with NPM workspaces enabled

NPM's [workspaces](https://docs.npmjs.com/cli/v11/using-npm/workspaces/)
concept is very useful for organising interdependent packages, especially for a
local-first development scenario. Let's set up what we need to use the
workspaces concept first.

👉 In a new shell session, or at least in the root of this repo, create a new
project directory:

```bash
rm -rf proj-02/ \
  && mkdir proj-02/ \
  && cd $_
```

👉 Now in this directory, create a `package.json` file containing:

```json
{
  "name": "messaging",
  "workspaces": [
    "*"
  ]
}
```

From a `package.json` point of view, this is [the simplest thing that could
possibly
work](https://creators.spotify.com/pod/profile/tech-aloud/episodes/The-Simplest-Thing-that-Could-Possibly-Work--A-conversation-with-Ward-Cunningham--Part-V---Bill-Venners-e5dpts)
and will allow us to define and use multiple packages that will be available to
one another[<sup>1</sup>](#footnotes).

## Create an emitter service

In simple terms, messaging generally have two components participating, one
that emits, and one that receives. Let's first create the emitter.

👉 Create a new `emitter` service in its own project subdirectory within the
`proj-02/` directory, specifying two facets `nodejs` and
`file-based-messaging`:

```bash
cds init emitter --add nodejs,file-based-messaging
```

Here's what those two facets do:

- `nodejs`: specify that a CAP Node.js project is desired, which will (amongst
  other things) ensure the creation of a `package.json` file in the `emitter/`
  project subdirectory, with the appropriate
  settings[<sup>2</sup>](#footnotes).
- `file-based-messaging`: add messaging configuration to the CDS requirements,
  specifying the local-first friendly file-based approach.

The output from this command will look something like this:

```log
Adding facet: nodejs
Adding facet: file-based-messaging

Successfully initialized CAP project
Continue with: code emitter
```

and the contents of its `package.json` file are what we need:

```json
{
  "name": "emitter",
  "version": "1.0.0",
  "dependencies": {
    "@sap/cds": "^9"
  },
  "devDependencies": {
    "@cap-js/sqlite": "^2.4"
  },
  "scripts": {
    "start": "cds-serve"
  },
  "private": true,
  "cds": {
    "requires": {
      "messaging": {
        "kind": "file-based-messaging"
      }
    }
  }
}
```

### Add an emitter trigger and event

Continuing on the theme of keeping things simple, let's now flesh out this
emitter with a basic service definition.

👉 Create a file `emitter/srv/main.cds` with this content:

```cds
namespace codejam.emitter;

@rest
service EmitterService {
  action greet(greeting: String) returns String;

  event Greeting.Received {
    info : String;
  }
}
```

Here in `EmitterService` we define:

- an `EmitterService` with an RPC style endpoint (to which we can make HTTP
  POST requests with a "greeting" payload)
- an event `Greeting.Received` that carries a simple `info` string

👉 Create a corresponding implementation in `emitter/srv/main.js` with this content:

```javascript
const cds = require('@sap/cds')
const log = cds.log('emitter')

module.exports = cds.service.impl(async function() {
  this.on('greet', async (req) => {
    const emitter = await cds.connect.to('codejam.emitter.EmitterService')
    log(`emitting Greeting.Received (${req.data.greeting})`)
    await emitter.emit('Greeting.Received', { info: req.data.greeting })
    return 'OK'
  })
})
```

Here's a quick summary of what this does:

- loads the CDS facade
- creates an 'emitter' logging instance
- defines a handler for the `greet` request (the `action` in the service
  definition)
- this handler, on receipt of an incoming request,
  emits[<sup>3</sup>](#footnotes) a `Greeting.Received` event, conveying the
  value of the `greeting` that was received
- it then simply returns 'OK' in response to the `greet` request

### Add an entrypoint for the emitter

We're building the emitter like a plugin, so we'll follow convention and create
an entrypoint for the service definition at the emitter project root.

👉 Create the file `emitter/index.cds` with this content:

```cds
using from './srv/main';
```

When the emitter is loaded, e.g. in the context of another CAP service, the
emitter's service definition is bootstrapped via this `index.cds` file which is
automatically read[<sup>4</sup>](#footnotes).

### Clean up unused files

While normally we want all the content created by `cds init`, it's mostly superfluous here, so for neatness and clarity, let's remove what we don't need.

Remove the unwanted content[<sup>5</sup>](#footnotes):

```bash
rm -rf emitter/{.gitignore,.vscode/,app/,db/,readme.md}
```

### Try out the emitter

Great - at this point, we're all set with our emitter. We should try it out,
especially as it will be a good first milestone in this exercise. We'll run the
emitter on a different port than 4004, just so that we can eventually run the
receiver on that port instead.

#### Start the emitter

👉 Start up the emitter:

```cds
PORT=4006 cds watch emitter
```

We see log output like this, as expected:

```log
[cds] - loaded model from 1 file(s):

  emitter/srv/main.cds

[cds] - using bindings from: { registry: '~/.cds-services.json' }
[cds] - connect to db > sqlite { url: ':memory:' }
/> successfully deployed to in-memory database.

[cds] - connect to messaging > file-based-messaging
[cds] - using auth strategy { kind: 'mocked' }
[cds] - serving codejam.emitter.EmitterService {
  at: [ '/rest/emitter' ],
  decl: 'emitter/srv/main.cds:4',
  impl: 'emitter/srv/main.js'
}
[cds] - server listening on { url: 'http://localhost:4006' }
[cds] - server v9.9.1 launched in 279 ms
[cds] - [ terminate with ^C ]
```

Note the line that shows us that the `file-based-messaging` is active.

So far so good.

#### Send a greeting request to the emitter

👉 Now, in a separate terminal, make a "greeting" call:

```bash
curl \
  --data '{"greeting": "Mock all the things!"}' \
  --url 'localhost:4006/rest/emitter/greet'
```

In the log output of the emitter server, we see:

```log
[rest] - POST /rest/emitter/greet
[emitter] - emitting Greeting.Received (Mock all the things!)
```

OK, fine, but we can go deeper.

#### Examine the message queue

This is file-based messaging after all, so let's have a peek into the queue. By
default, the `file-based-messaging` mechanism uses a file called `.cds-msg-box`
in the user's home directory, which, like `.cds-services.json` which also lives
there, tells us this is design-time only, and not for production.

👉 Have a look:

```bash
cat ~/.cds-msg-box
```

There should be a record in there that represents the message that was just
emitted, and looks something like this (formatted for easier reading):

```log
codejam.emitter.EmitterService.Greeting.Received
{
  "data": {
    "info": "Mock all the things!"
  },
  "headers": {
    "x-correlation-id": "dc56be1a-aec3-4858-8b02-7d0e5dafeb56"
  }
}
```

OK, now to turn our attention to the recipient of this event.

## Create a receiver service

...

---

## Footnotes

1. Yes, this is the same approach as we use for local development of CDS
   plugins - see [Creating our own plugin
   package](https://qmacro.org/blog/posts/2024/10/05/cap-node-js-plugins-part-1-how-things-work/#creating-our-own-plugin-package)
   within part 1 of the series on [CAP Node.js
   plugins](https://qmacro.org/blog/posts/2024/12/30/cap-node-js-plugins/).

1. Until recently this was the default behaviour anyway, but in a move that
   drives us ever further towards domain-first thinking, this is no longer the
   case.

1. For a detailed comparison between `emit` and `send`, see the [Creating a
   service from
   scratch](https://qmacro.org/blog/posts/2025/07/21/a-recap-intro-to-the-cds-repl/#creating-a-service-from-scratch)
   section of the blog post [A reCAP intro to the cds
   REPL](https://qmacro.org/blog/posts/2025/07/21/a-recap-intro-to-the-cds-repl/).

1. See the [Using index.cds Entry
   Points](https://cap.cloud.sap/docs/guides/integration/reuse-and-compose#index-cds)
   section of Capires Reuse and Compose topic.

1. The `{ ... }` part of this invocation is called [Brace
   expansion](https://www.gnu.org/software/bash/manual/html_node/Brace-Expansion.html),
   in case you're wondering[<sup>6</sup>](#footnotes).

1. Bash forever![<sup>7</sup>](#footnotes)

1. Yo dawg, I heard you like footnotes, so I put some footnotes in your footnotes.
