# 02 - Mocking messaging

In the blog post "Five reasons to use CAP" we see that everything is an event.
Whether synchronous, such as via HTTP requests and responses for OData
operations, or asynchronous, where messages are emitted and received for
decoupled service-to-service communications.

The Messaging topic in Capire has a great overview and an explanation of all
the different message brokers that can be used. And there's one that is well
suited for local-first development: file based messaging, which we'll explore
in this exercise.

## Create a containing project directory with NPM workspaces enabled

NPM's [workspaces](https://docs.npmjs.com/cli/v11/using-npm/workspaces/)
concept is very useful for organising interdependent packages, especially for a
local-first development scenario. Let's start by setting up what we need
to use the workspaces concept.

👉 In a new shell session, or at least in the root of this repo, create a new
project directory:

```bash
rm -rf proj-02 \
  && mkdir proj-02 \
  && cd $_
```

<details>
<summary>Windows (PowerShell)</summary>

```powershell
Remove-Item -Recurse -Force proj-02 -ErrorAction SilentlyContinue
New-Item -ItemType Directory proj-02 | Out-Null
Set-Location proj-02
```

</details>

<details>
<summary>Windows (cmd)</summary>

```cmd
rmdir /s /q proj-02 2>nul & mkdir proj-02 & cd proj-02
```

</details>

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

In simple terms, messaging generally have two participating components -
one that emits, and one that receives. Let's first create the emitter.

👉 Create a new `emitter` service in its own project subdirectory within the
`proj-02/` directory, specifying two facets `nodejs` and
`file-based-messaging`:

```bash
cds init emitter --add nodejs,file-based-messaging
```

Here's what those two facets do:

- `nodejs`: specifies that a CAP Node.js project is desired, which will (amongst
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
  "type": "module",
  "dependencies": {
    "@sap/cds": "^10"
  },
  "devDependencies": {
    "@cap-js/sqlite": "^3"
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

> See note on [cds 10 and ESM](../../cds10esm.md).

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

While normally we want all the content created by `cds init`, it's mostly
superfluous here, so for neatness and clarity, let's remove what we don't need.

👉 Remove the unwanted content[<sup>5</sup>](#footnotes):

```bash
rm -rf emitter/{.gitignore,.vscode/,app/,db/,readme.md}
```

<details>
<summary>Windows (PowerShell / cmd)</summary>

The `{...}` brace expansion is a bash feature; list the paths explicitly
instead.

PowerShell:

```powershell
Remove-Item -Recurse -Force emitter/.gitignore, emitter/.vscode, emitter/app, emitter/db, emitter/readme.md -ErrorAction SilentlyContinue
```

cmd:

```cmd
del /q emitter\.gitignore emitter\readme.md 2>nul & rmdir /s /q emitter\.vscode emitter\app emitter\db 2>nul
```

</details>

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

<details>
<summary>Windows (PowerShell / cmd)</summary>

Windows shells don't support the inline `VAR=value command` syntax; set the
environment variable first.

PowerShell:

```powershell
$env:PORT=4006; cds watch emitter
```

cmd:

```cmd
set PORT=4006 && cds watch emitter
```

</details>

> If you see an error on startup like this:
>
> ```log
> ReferenceError: require is not defined in ES module scope, you can use import instead
> ```
>
> then as a workaround (this is due to the move to ESM in cds 10) while the
> issue is addressed (should be resolved with 10.0.5), remove the
> `"type":"module"` property in the emitter's `package.json` file. You may
> have to do the same for the receiver later (look out for a note similar to
> this).

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
[cds] - server v10.0.3 launched in 279 ms
[cds] - [ terminate with ^C ]
```

Note the line that shows us that the `file-based-messaging` is active.

So far so good.

#### Send a greeting request to the emitter

👉 Now, in a separate terminal, make a "greeting" call:

```bash
curl \
  --header 'Content-Type: application/json' \
  --data '{"greeting": "Mock all the things!"}' \
  --url 'localhost:4006/rest/emitter/greet'
```

<details>
<summary>Windows (PowerShell / cmd)</summary>

On Windows, put the whole command on one line (or use the line-continuation
character for your shell — a backtick `` ` `` in PowerShell, a caret `^` in
cmd), and mind the quoting of the JSON payload. In PowerShell also call
`curl.exe`, because `curl` is an alias for `Invoke-WebRequest`.

PowerShell 7+ (single-quoted JSON, no escaping):

```powershell
curl.exe --header "Content-Type: application/json" --data '{"greeting": "Mock all the things!"}' --url "localhost:4006/rest/emitter/greet"
```

cmd (inner double quotes doubled as `""`):

```cmd
curl --header "Content-Type: application/json" --data "{""greeting"": ""Mock all the things!""}" --url "localhost:4006/rest/emitter/greet"
```

> Windows PowerShell 5.1 (the version bundled with Windows) mangles inline
> double quotes passed to native programs, so the PowerShell line above needs
> PowerShell 7+. On 5.1, put the JSON in a file and use `--data '@greeting.json'`.

</details>

In the log output of the emitter server, we see:

```log
[rest] - POST /rest/emitter/greet
[emitter] - emitting Greeting.Received (Mock all the things!)
```

OK, fine, but let's go deeper.

#### Examine the message queue

This is file-based messaging after all, so let's have a peek into the queue. By
default, the `file-based-messaging` mechanism uses a file called `.cds-msg-box`
in the user's home directory, which, like `.cds-services.json` which also lives
there, tells us this is design-time only, and not for production.

👉 Have a look:

```bash
cat ~/.cds-msg-box
```

<details>
<summary>Windows (PowerShell / cmd)</summary>

`~` and the `.cds-msg-box` filename resolve the same way, but the command to
print a file differs. This applies to both places in this exercise where the
message box is inspected.

PowerShell:

```powershell
Get-Content ~/.cds-msg-box
```

cmd:

```cmd
type "%USERPROFILE%\.cds-msg-box"
```

</details>

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

OK, now let's turn our attention to the recipient of this event.

## Create a receiver service

We can start off with the same approach, creating a basic receiver service in
its own project subdirectory.

👉 Do that now, from the `proj-02/` directory:

```bash
cds init receiver --add nodejs,file-based-messaging
```

The log output and `package.json` created will be pretty much the same as before.

### Clean up unused files again

As before, we only really need the `package.json` file.

👉 Remove what we don't need:

```bash
rm -rf receiver/{.gitignore,.vscode/,app/,db/,srv/,readme.md}
```

<details>
<summary>Windows (PowerShell / cmd)</summary>

PowerShell:

```powershell
Remove-Item -Recurse -Force receiver/.gitignore, receiver/.vscode, receiver/app, receiver/db, receiver/srv, receiver/readme.md -ErrorAction SilentlyContinue
```

cmd:

```cmd
del /q receiver\.gitignore receiver\readme.md 2>nul & rmdir /s /q receiver\.vscode receiver\app receiver\db receiver\srv 2>nul
```

</details>

### Add a custom server implementation

All we really want to do here is have this receiver consume the events when it
starts up. So we can use a [custom
server](https://cap.cloud.sap/docs/node.js/cds-server#custom-server-js).

Create `receiver/server.js` with the following content:

```javascript
const cds = require('@sap/cds')
const log = cds.log('receiver')
const eventID = 'Greeting.Received'

cds.once('served', async () => {
  log(`Setting up listener for ${eventID}`)
  const EmitterService = await cds.connect.to('EmitterService')
  EmitterService.on(eventID, (msg) => {
    log('received:', msg.event, msg.data)
  })
})
```

We can view this as the flip side of `emitter/srv/main.js`, as it:

- loads the CDS facade
- creates a 'receiver' logging instance

and then, in the one-time
[served](https://cap.cloud.sap/docs/node.js/cds-server#served) event:

- connects to the emitter service
- defines a handler for `Greeting.Received` events, which simply logs them out

### Define the requirement for the emitter service

We also need to define a requirement for the emitter service.

In `receiver/package.json`, add a section to the `cds.requires` so that it
looks like this:

```json
{
  "...": "...",
  "cds": {
    "requires": {
      "EmitterService": {
        "service": "codejam.emitter.EmitterService",
        "model": "emitter"
      },
      "messaging": {
        "kind": "file-based-messaging"
      }
    }
  }
}
```

### Wire things up at the workspace level

Now we're all set; all that's left for us to do is wire things up at the
"containing" level, i.e. from the NPM workspaces perspective. If we were to
examine the entire contents of our `proj-02/` directory, for example with
`tree`, we'd see this:

```log
.
├── emitter
│   ├── index.cds
│   ├── package.json
│   └── srv
│       ├── main.cds
│       └── main.js
├── package.json
└── receiver
    ├── package.json
    └── server.js

7 directories, 8 files
```

👉 At the `proj-02/` level (where the `package.json` is), run:

```bash
npm install
```

What has this done for us? Well, apart from install the dependencies described
in the `emitter` and `receiver` projects, it has also wired up those packages.

👉 Have a look, either with your IDE's file & directory explorer, or simply
with `tree`, like this (with `-L` to limit directory descent, and `-l` to show
symbolic links):

```bash
tree -L 2 -l
```

<details>
<summary>Windows (PowerShell / cmd)</summary>

The built-in Windows `tree` command has no equivalent of `-L` (depth limit) or
`-l` (follow/show symbolic links), so the output won't match exactly. `tree /F`
will still show the `emitter` and `receiver` entries under `node_modules`, but
renders them as ordinary directories rather than annotating them as links. To
confirm they really are links (junctions) to the local packages, use:

PowerShell:

```powershell
Get-ChildItem node_modules -Force | Where-Object LinkType | Select-Object Name, LinkType, Target
```

cmd (junctions show as `<JUNCTION>` with their target):

```cmd
dir /a:l node_modules
```

</details>

Here's what you should see (with much of the output removed, for brevity):

```log
.
├── emitter
│   ├── index.cds
│   ├── package.json
│   └── srv
├── node_modules
│   ├── @cap-js
│   ├── @eslint
│   ├── @sap
│   ├── ...
│   ├── ee-first
│   ├── emitter -> ../emitter
│   ├── encodeurl
│   ├── ...
│   ├── readable-stream
│   ├── receiver -> ../receiver
│   ├── router
│   ├── ...
│   └── yaml
├── package-lock.json
├── package.json
└── receiver
    ├── package.json
    └── server.js
```

The `emitter` and `receiver` packages are local, but NPM has created symbolic
links to them so that they're available as if they had been retrieved and
installed as normal.

### Start the receiver

It's now time to fire up the receiver.

👉 Do that now:

```bash
cds watch receiver
```

> As earlier, you may see an error like this at startup:
>
> ```log
> ReferenceError: require is not defined in ES module scope, you can use import instead
> ```
>
> Use the same temporary workaround as before, by removing the
> `"type":"module"` property in the receiver's `package.json` file.

You should see log output like this:

```log
[cds] - bootstrapping from { file: 'receiver/server.js' }
[cds] - loaded model from 2 file(s):

  emitter/index.cds
  emitter/srv/main.cds

...

[cds] - connect to messaging > file-based-messaging
...
[receiver] - Setting up listener for Greeting.Received
...
```

And pretty much immediately after that, you should see this:

```log
[receiver] - received: Greeting.Received { info: 'Mock all the things!' }
```

Excellent!

The event made its way to the receiver.

### Check the message queue

What is in `~/.cds-msg-box` now?

👉 Let's have a look:

```bash
cat ~/.cds-msg-box
```

<details>
<summary>Windows (PowerShell / cmd)</summary>

```powershell
Get-Content ~/.cds-msg-box
```

```cmd
type "%USERPROFILE%\.cds-msg-box"
```

</details>

Nothing! The event record has gone. As we'd hoped and expected.

## Further info

- The blog post [Five reasons to use
  CAP](https://qmacro.org/blog/posts/2024/11/07/five-reasons-to-use-cap/)
  includes some thoughts on how [everything is an
  event](https://qmacro.org/blog/posts/2024/11/07/five-reasons-to-use-cap/#:~:text=%22Everything%20is%20an%20event%22).
- See the [Messaging](https://cap.cloud.sap/docs/node.js/messaging) topic in
  Capire for all the details, including a list of all brokers.

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
   section of the Reuse and Compose topic in Capire.

1. The `{ ... }` part of this invocation is called [Brace
   expansion](https://www.gnu.org/software/bash/manual/html_node/Brace-Expansion.html),
   in case you're wondering[<sup>6</sup>](#footnotes).

1. Bash FTW[<sup>7</sup>](#footnotes)

1. Yo dawg, I heard you like footnotes, so I put some footnotes in your footnotes.
