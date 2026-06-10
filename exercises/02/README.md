# 01 - Mocking messaging

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
  "name": "@demo/messaging",
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

---

## Footnotes

1. Yes, this is the same approach as we use for local development of CDS
   plugins - see [Creating our own plugin
   package](https://qmacro.org/blog/posts/2024/10/05/cap-node-js-plugins-part-1-how-things-work/#creating-our-own-plugin-package)
   within part 1 of the series on [CAP Node.js
   plugins](https://qmacro.org/blog/posts/2024/12/30/cap-node-js-plugins/).
