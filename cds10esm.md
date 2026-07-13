# cds 10 and ESM

On cds 10 and higher, `cds init` generates a `package.json` that pins the newer
major versions and, crucially, sets `"type": "module"` — which is what makes
Node.js treat `.js` files as ES modules (see the note about `main.cjs` further
down). It looks like this:

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

The `"type": "module"` line is the key difference — it's why a CommonJS handler
on cds 10+ has to be named `main.cjs` rather than `main.js`.
