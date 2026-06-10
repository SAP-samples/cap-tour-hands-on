# 01 - Mocking auth

With the mocked authentication strategy, we can embrace and work on the
important aspect of securing our app or service right from the very start. CAP
makes it easy to do the right things here.

## Start a new CAP project

👉 Use the "base project"[<sup>1</sup>](#footnotes) as a starting point and create
a new CAP project:

```bash
rm -rf proj-01 \
  && cp -a baseproj proj-01 \
  && cd $_ \
  && tree
```

This should emit something like this:

```log
.
├── db
│   ├── data
│   │   ├── northwhisper-Categories.csv
│   │   ├── northwhisper-Products.csv
│   │   └── northwhisper-Suppliers.csv
│   └── schema.cds
├── package.json
└── srv
    └── main.cds

4 directories, 6 files
```

## Explore the service

As it's our first time using the base project, take a minute to explore the
service which is a very cut down version of Northwind.

👉 Start the CAP server (let's use `cds serve` for a change, to remind ourselves
of the difference between `serve` and `watch`, and think about the options and what
they do (such as `--in-memory`):

```bash
cds serve --in-memory
```

Make a few OData query operations to get a feel for the Northwind data that is
there (while the model itself is cut down, there's a full complement of records
for each of the three entities):

- <http://localhost:4004/northwhisper/Categories?$expand=Products($select=ProductName)>
- <http://localhost:4004/northwhisper/Suppliers?$orderby=Country>
- <http://localhost:4004/northwhisper/Products?$apply=aggregate(UnitsInStock%20with%20sum%20as%20TotalStock)>

> For those of you running these exercises in a Codespace, where
> `localhost:<port>` addresses are auto exposed with custom random domain
> names, use the `showurls` utility for this exercise, which will simply emit
> the above URLs to the shell, where they'll become clickable and auto
> translated into the appropriate domain name equivalent:
>
> ```bash
> ../utils/showurls
> ```

👉 Once you've done exploring, stop the CAP server (with `Ctrl-C`).

## Find out about auth strategies

In the log output from the CAP server, we saw:

```log
[cds] - using auth strategy { kind: 'mocked' }
```

👉 Head over to the [Authentication
Strategies](https://cap.cloud.sap/docs/node.js/authentication#strategies) of
the Security topic in Capire to find out what this mocked strategy is. Briefly:

- it uses [Basic Authentication](https://datatracker.ietf.org/doc/html/rfc7617)
- it comes with some pre-defined mock users to develop with

### Examine the pre-defined mock users

👉 Take a look at the pre-defined mock users:

```bash
cds env requires.auth.users
```

This should show something like this:

```javascript
{
  alice: { tenant: 't1', roles: [ 'admin' ] },
  bob: { tenant: 't1', roles: [ 'cds.ExtensionDeveloper' ] },
  carol: { tenant: 't1', roles: [ 'admin', 'cds.ExtensionDeveloper' ] },
  dave: { tenant: 't1', roles: [ 'admin' ], features: [] },
  erin: { tenant: 't2', roles: [ 'admin', 'cds.ExtensionDeveloper' ] },
  fred: { tenant: 't2', features: [ 'isbn' ] },
  me: { tenant: 't1', features: [ '*' ] },
  yves: { roles: [ 'internal-user' ] },
  '*': true
}
```

None of the users have passwords (there wouldn't be much point), but what they
do have are roles assigned to them.

### Consider the basic auth strategy

There's also the 'basic' strategy which is the one that determines the use of
Basic Authentication. The 'mocked' strategy builds on the 'basic' strategy by
adding the pre-defined users.

The easiest thing for us to do would be to use the 'mocked' strategy and one of
the pre-defined users, but instead, for the purposes of exploration and
learning, let's use the 'basic' strategy and add our own user.

## Switch to the basic auth strategy and add a user

Let's practise using CAP's "effective configuration" mechanism and specify
that we want to use the 'basic' auth strategy, and also define our own user.

There are [plenty of places we could make these configuration
definitions](https://cap.cloud.sap/docs/node.js/cds-env#sources-for-cds-env),
let's choose a `.env` file.

👉 Create a `.env` file in the `proj-01/` project's root with the following content:

```env
cds.requires.auth.kind=basic
cds.requires.auth.users.alan.roles=["admin"]
```

> Alan Kay led the Xerox PARC research team that produced
> [Smalltalk](https://en.wikipedia.org/wiki/Smalltalk), a language, system and
> environment that has had a large influence on software design and
> architecture, including CAP[<sup>2</sup>](#footnotes).

👉 Check the effect of this configuration:

```bash
cds env requires.auth
```

This should emit something like this:

```javascript
{
  kind: 'basic',
  users: { alan: { roles: [ 'admin' ] } },
  tenants: {}
}
```

## Restart the CAP server

👉 Now let's restart the CAP server, but this time in watch mode, plus we want
to see some extra output relating to the 'basic' strategy we're using:

```bash
DEBUG=basic cds watch
```

With non-productive auth strategies, automatic authentication of all endpoints
is disabled[<sup>3</sup>](#footnotes). This is why we can access resources
served by the CAP server without any authentication information in the request.

👉 Try it:

```bash
curl -i 'localhost:4004/northwhisper/Categories?$top=1'
```

This should return data successfully, with something like[<sup>4</sup>](#footnotes):

```log
HTTP/1.1 200 OK

{
  "@odata.context": "$metadata#Categories",
  "value": [
    {
      "CategoryID": 1,
      "CategoryName": "Beverages",
      "...": "..."
    }
  ]
}
```

## Restrict access to the service

Let's start to explore some of the ways we can restrict access. First, we'll just
add an annotation to the service itself which will require users to authenticate.

> Remember:
>
> - authentication is about the verification of a user's identity
> - authorization is about checking what level of access a given user has

👉 Add a `@requires` annotation to the service in `srv/main.cds` as shown:

```cds
using northwhisper from '../db/schema';

@path: '/northwhisper'
@requires: 'authenticated-user'
service Main {

  entity Products   as projection on northwhisper.Products;
  entity Suppliers  as projection on northwhisper.Suppliers;
  entity Categories as projection on northwhisper.Categories;

}
```

### Retry access to one of the entities

Now that we've specified that service resources are only available to users who
have identified themselves (in this case just via Basic Authentication, as
we're using the 'basic' strategy here), we should retry access to the
`Categories` entity.

👉 Do that now:

```bash
curl -i 'localhost:4004/northwhisper/Categories?$top=1'
```

This time, we get an appropriate HTTP response:

```log
HTTP/1.1 401 Unauthorized

Unauthorized
```

> Also note (that despite the status text):
>
> - An HTTP 401 response is related to authentication
> - An HTTP 403 response (which we'll see shortly) is related to authorization

Note also that we see this in the CAP server log, too:

```log
[basic] - 401 > login required
```

### Retry access as an authenticated user

So let's authenticate, as our user `alan`. We can use the `--user` (short:
`-u`) option with `curl` where we would normally specify a username and
password like this:

```text
-u user:pass
```

If we keep the joining colon (`:`) but leave off any password, we can
effectively specify no password and not have `curl` prompt us for
one[<sup>5</sup>](#footnotes).

👉 Try that now:

```bash
curl -u alan: -i 'localhost:4004/northwhisper/Categories?$top=1'
```

Authenticating as `alan` does the trick:

```log
HTTP/1.1 200 OK

{
  "@odata.context": "$metadata#Categories",
  "value": [
    {
      "CategoryID": 1,
      "CategoryName": "Beverages",
      "...": "..."
    }
  ]
}
```

Note also the CAP server log shows this:

```log
[basic] - authenticated: { user: 'alan', tenant: undefined, features: undefined }
```

## Limit access to an entity

We've added an authentication restriction to the service (and thus everything
within it). But let's now try something more fine-grained, and require a
specific role for a certain type of access to one of the entities within.

👉 Add this `@restrict` annotation to the `Products` entity with a privilege
block (`{ ... }`) as follows:

```cds
using northwhisper from '../db/schema';

@path    : '/northwhisper'
@requires: 'authenticated-user'
service Main {

  @restrict: [{
    grant: 'WRITE',
    to   : 'finance'
  }]
  entity Products   as projection on northwhisper.Products;

  entity Suppliers  as projection on northwhisper.Suppliers;
  entity Categories as projection on northwhisper.Categories;

}
```

This says that in order to perform write operations on the `Products` entity, a
user (needs to be authenticated, from the auth requirement at the service
level, and) must have the `finance` role.

### Try to access the newly restricted entity

Write access to the `Products` entity is now further locked down.

👉 So let's try read access first:

```bash
curl -u alan: -i 'localhost:4004/northwhisper/Products?$top=1'
```

Oh!

```log
HTTP/1.1 403 Forbidden

{
  "error": {
    "message": "Forbidden",
    "code": "403",
    "@Common.numericSeverity": 4
  }
}
```

That's because a request is only allowed through "if at least one of the
privileges is met" - and there are no privileges that allow for read operations
(see the Capire section on
[@restrict](https://cap.cloud.sap/docs/guides/security/authorization#restrict-annotation)).

👉 So let's remedy that by adding a second privilege that grants read access to
any user (who has authenticated):

```cds
using northwhisper from '../db/schema';

@path    : '/northwhisper'
@requires: 'authenticated-user'
service Main {

  @restrict: [
    {
      grant: 'READ',
      to   : 'any'
    },
    {
      grant: 'WRITE',
      to   : 'finance'
    }
  ]
  entity Products   as projection on northwhisper.Products;

  entity Suppliers  as projection on northwhisper.Suppliers;
  entity Categories as projection on northwhisper.Categories;

}
```

Let's have another go at reading products as `alan`:

```bash
curl -u alan: -i 'localhost:4004/northwhisper/Products?$top=1'
```

Success!

```log
HTTP/1.1 200 OK

{
  "@odata.context": "$metadata#Products",
  "value": [
    {
      "ProductID": 1,
      "ProductName": "Chai",
      "...": "..."
    }
  ]
}
```

### Check that we have write access

Now let's check write access, given that privilege on `Products`.

👉 Try with our user `alan`:

```bash
 curl -u alan: \
   --request PATCH \
   --data '{"UnitPrice":100}' \
   --include \
   --url 'localhost:4004/northwhisper/Products/1'
```

Uh-oh!

```log
HTTP/1.1 403 Forbidden

{
  "error": {
    "message": "Forbidden",
    "code": "403",
    "@Common.numericSeverity": 4
  }
}
```

### Extend the role assignment

Of course, `alan` has the `admin` role but not the `finance` role.

Include the `finance` role by adding it to the configuration in `.env`:

```env
cds.requires.auth.kind=basic
cds.requires.auth.users.alan.roles=["admin","finance"]
```

### Retry the write access

👉 Let's now try again, as `alan`, who [now has finance access](https://www.youtube.com/watch?v=SoAk7zBTrvo):

```bash
 curl -u alan: \
   --request PATCH \
   --data '{"UnitPrice":100}' \
   --include \
   --url 'localhost:4004/northwhisper/Products/1'
```

This time, we are successful!

```log
HTTP/1.1 200 OK

{
  "@odata.context": "$metadata#Products/$entity",
  "ProductID": 1,
  "ProductName": "Chai",
  "UnitPrice": 100,
  "...": "..."
}
```

## Further info

- Did you know that `@requires: '<some-role>'` is just shorthand for `@restrict: [{grant:'*',to:'<some-role>'}]`?
- Did you also know that `@readonly` is just shorthand for `@restrict: [{grant:'READ'}]`?
- The [CAP-level Authorization](https://cap.cloud.sap/docs/guides/security/authorization) topic in Capire is definitely worth a visit.

---

## Footnotes

1. The [base project](../../baseproj/) is a simple CAP project definition with
   a drastically reduced version of the classic Northwind dataset, consisting
   of just three entities Products, Suppliers and Categories, and with just the
   bare minimum number of elements in each. The project has some corresponding
   initial data for each of these entities. The name of the service is
   "Northwisper", a further step in the evolution towards minimalism
   ("Northwind" -> "Northbreeze" -> "Northwhisper").

1. See the [Remote services, proxies and
   abstraction](https://qmacro.org/blog/posts/2024/12/13/tasc-notes-part-5/#remote-services-proxies-and-abstraction)
   section of the notes to Part 5 of The Art and Science of CAP.

1. See the `restrict_all_services` flag within `requires.auth` for further
   details.

1. Any JSON structures in responses are formatted for easier reading.

1. If we don't use the `:` then `curl` will prompt for a password, like this:

    ```shell
    ; curl -u alan -i 'localhost:4004/northwhisper/Products?$top=1'
    Enter host password for user 'alan':
    ```
