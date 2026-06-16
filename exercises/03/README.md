# 03 - Creating a plugin

The plugin concept is fundamental to the CAP framework. Not only as a clean and
simple extension mechanism, but also a core building block in the framework
itself. Various basic components in CAP are implemented as plugins, as well as
[many additional features](https://cap.cloud.sap/docs/plugins/).

In this exercise we'll implement a simple plugin so that we understand how
they're put together and how they work.

## Start a new CAP project

Like we did in an earlier exercise, we'll start with the "base project" to save
a bit of time.

👉 Create a new project directory for this exercise using the base project:

```bash
rm -rf proj-03 \
  && cp -a baseproj proj-03 \
  && cd $_
  && tree
```

## Install the runtime

Normally this point in a project would be too early to think about installing
the `@sap/cds` runtime and the rest of the project dependencies. But we'll do
it here because it makes things simpler in terms of paths (relative and
absolute) when we come to looking at some `@sap/cds` runtime components. It's
easier to refer to and view them relative to (within) our `proj-03/` project
directory, than in a global install location elsewhere.

👉 Install the package dependencies for the project:

```bash
npm install
```

## Explore plugins as core building blocks

Let's see if we can find evidence of the plugin concept being used in the core
framework. We can turn on debugging for the plugins module and have a look.

👉 Start up the server with the `DEBUG` environment variable set to `plugins`:

```bash
DEBUG=plugins cds watch
```

Some interesting output appears in the server log, like this:

```log
[cds.plugins] - fetched plugins in: 1.401ms
[cds.plugins] - loading @sap/cds-fiori: { impl: 'node_modules/@sap/cds-fiori/cds-plugin.js' }
[cds.plugins] - loading @cap-js/sqlite: { impl: 'node_modules/@cap-js/sqlite/cds-plugin.js' }
[cds.plugins] - loaded plugins in: 1.346ms
[cds] - loaded model from 2 file(s):

  srv/main.cds
  db/schema.cds

...
[cds] - server listening on { url: 'http://localhost:4004' }
[cds] - server v9.9.1 launched in 286 ms
```

We can see there are two plugins being fetched and loaded:

- `@sap/cds-fiori`
- `@cap-js/sqlite`

So let's investigate where these plugins (mentioned at the start of the CAP
server log output) are coming from and why they're being loaded.

### Look at the dependent packages

If we dig in (see the [Further info](#further-info) section), we'll see that
the core plugin mechanism looks for package dependencies for two key locations:

- [cds.home](https://cap.cloud.sap/docs/node.js/cds-facade#cds-home): the
  location of the in-use `@sap/cds` runtime (which we've just installed and
  therefore is within the project's `node_modules/` directory)
- [cds.root](https://cap.cloud.sap/docs/node.js/cds-facade#cds-root): the
  project root directory

#### Determine the home and root values

Use the cds REPL to confirm what the values are for your setup.

👉 Start the cds REPL:

```bash
cds repl
```

👉 And at the prompt, ask for the values of both `cds.home` and `cds.root`.

You should see something like this:

```log
node ➜ /workspaces/cap-tour-hands-on (main) $ cds repl
Welcome to cds repl v9.9.1
> cds.home
/workspaces/cap-tour-hands-on/proj-03/node_modules/@sap/cds
> cds.root
/workspaces/cap-tour-hands-on/proj-03
>
```

Depending on your setup, the values, especially the first parts of the paths,
may be different. But the key thing is that they're both, (literally)
relatively speaking, easily accessible from where you are right now in
`proj-03/` - `cds.home` is `./node_modules/@sap/cds` and `cds.root` is `.`.

#### Look at the dependencies

Now we know the actual locations, let's take a look at the dependencies - these
will be listed in `dependencies` and `devDependencies` sections within the
`package.json` files in each of these two locations.

👉 List the dependencies of both these locations:

```bash
jq '.name, .dependencies + .devDependencies' \
  ./node_modules/@sap/cds/package.json \
  ./package.json
```

This should produce something like this:

```json
"@sap/cds"
{
  "@sap/cds-compiler": "^6.4",
  "@sap/cds-fiori": "^2",
  "express": "^4.22.1 || ^5",
  "yaml": "^2"
}
"baseproj"
{
  "@sap/cds": "^9",
  "@cap-js/sqlite": "^2.4"
}
```

### Look for signs of plugins

We know from Capire (see the [Further info](#further-info) section) that the
key file that makes your package a plugin, like the "index" file in other
contexts, is `cds-plugin.js`. So let's see whether we can find any instance of
such a file.

👉 Look for `cds-plugin.js` files in `cds.home` and `cds.root`:

```bash
find . -name cds-plugin.js 
```

and bingo - we have two, both in `cds.home` (in the `@sap/cds` runtime):

```log
./node_modules/@sap/cds-fiori/cds-plugin.js
./node_modules/@cap-js/sqlite/cds-plugin.js
```

And yes, these are `cds-plugin.js` files in packages that exactly match those
we saw in the CAP server log output. And, also yes, the SQLite module is
implemented ... as a plugin.

## Build the skeleton of our own plugin

Now we know what we need - a package with a `cds-plugin.js` file - let's create
one. Even here we can embrace the local-first development mode that CAP
celebrates by using NPM's "Workspaces" concept (see [Further
info](#further-info)), which will allow us to create the plugin locally but
still "require" it via the normal `package.json#dependencies` route.

What will the plugin do? Well, let's keep it super simple so we can focus on
the plugin mechanics. It should replace country values with the corresponding
flag emojis. An essential enterprise feature, I'm sure you'll agree!

### Create the plugin package directory

👉 Create a new package for the plugin by initialising a new package in the
context of a new workspace called "flags":

```bash
npm init \
  --yes \
  --workspace flags
```

This should emit something like this:

```log
Wrote to [...]/proj-03/flags/package.json:

{
  "name": "flags",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "devDependencies": {},
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "type": "commonjs"
}

added 1 package in 312ms
```

Perhaps more interestingly, it's also caused the addition of a new `workspaces`
section in `proj-03`'s `package.json`: 

```json
{
  "name": "baseproj",
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
  "workspaces": [
    "flags"
  ]
}
```

### Add some startup logging

For this skeleton step, all we want to do is get the plugin to announce itself.

👉 Create a new file in the plugin directory (`flags/`) called `cds-plugin.js`
with this content:

```javascript
const cds = require('@sap/cds')
const log = cds.log('flags')
log('Starting up ...')
```

That should be all we need, right?

### Start up the main project

👉 Now start up the main service in `proj-03` like we did before:

```bash
DEBUG=plugins cds watch
```

We see this:

```log
[cds.plugins] - fetched plugins in: 22.209ms
[cds.plugins] - loading @sap/cds-fiori: { impl: 'node_modules/@sap/cds-fiori/cds-plugin.js' }
[cds.plugins] - loading @cap-js/sqlite: { impl: 'node_modules/@cap-js/sqlite/cds-plugin.js' }
[cds.plugins] - loaded plugins in: 3.791ms
```

It's essentially the same output as before.

Where's our plugin?

Well, we should know now that it's only loaded when defined as a dependency.

👉 So let's do that now (in a separate terminal):

```bash
npm add flags
```

Assuming your CAP server is still running, the restart should now emit this:

```log
[cds.plugins] - fetched plugins in: 3.949ms
[cds.plugins] - loading @sap/cds-fiori: { impl: 'node_modules/@sap/cds-fiori/cds-plugin.js' }
[cds.plugins] - loading flags: { impl: 'flags/cds-plugin.js' }
[flags] - Starting up ...
[cds.plugins] - loading @cap-js/sqlite: { impl: 'node_modules/@cap-js/sqlite/cds-plugin.js' }
[cds.plugins] - loaded plugins in: 5.452ms
```

Success!

## Further info

- A deep dive into what causes plugins to be loaded, and from where, is
  available in the blog post [CAP Node.js plugins - part 1 - how things
  work](https://qmacro.org/blog/posts/2024/10/05/cap-node-js-plugins-part-1-how-things-work/).
- The [CDS Plugin Packages](https://cap.cloud.sap/docs/node.js/cds-plugins)
  topic has a section on `cds-plugin.js`.
- Learn more about [NPM
  Workspaces](https://docs.npmjs.com/cli/v11/using-npm/workspaces).
