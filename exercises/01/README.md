# 01 - Mocking auth

With the mocked authentication strategy, we can embrace and work on the
important aspect of securing our app or service right from the very start. CAP
makes it easy to do the right things here.

In this exercise we'll look at how we can do that, based on a simple service.

## Start a new CAP project

👉 Use the "base project"[<sup>1</sup>](#footnotes) as a starting point and create
a new CAP project:

```bash
rm -rf proj-01 \
  && cp -a baseproj proj-01 \
  && cd $_ \
  && tree
```

<details>
<summary>Windows (PowerShell)</summary>

```powershell
Remove-Item -Recurse -Force proj-01 -ErrorAction SilentlyContinue
Copy-Item -Recurse baseproj proj-01
Set-Location proj-01
tree /F
```

</details>

<details>
<summary>Windows (cmd)</summary>

```cmd
rmdir /s /q proj-01 2>nul & xcopy baseproj proj-01 /e /i /q & cd proj-01 & tree /f
```

</details>

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

> On Windows, the built-in `tree /F` command produces box-drawing output in a
> different style and does not print a trailing "N directories, M files" summary
> line. The structure (the same 4 directories and 6 files) will match, even
> though the exact rendering differs from the Unix `tree` output shown above.

## Explore the service

As it's our first time using the base project, take a minute to explore the
service which is a very cut down version of Northwind.

👉 Start the CAP server, using `cds serve` for a change, to remind ourselves
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
> 👉 Open up a new terminal window, which should place you in the root of this
> CodeJam content, and run:
>
> ```bash
> ./utils/showurls
> ```
>
> specifying the exercise number (1) as the only argument.
>
> On Windows, use the equivalent utility for your shell instead — both take the
> exercise number the same way:
>
> ```powershell
> .\utils\showurls.ps1 1
> ```
>
> ```cmd
> utils\showurls.cmd 1
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
> environment that has had a large influence on important software designs and
> architectures, including CAP[<sup>2</sup>](#footnotes).

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

<details>
<summary>Windows (PowerShell)</summary>

PowerShell doesn't support the inline `VAR=value command` syntax; set the
environment variable first, then run the command:

```powershell
$env:DEBUG='basic'; cds watch
```

</details>

<details>
<summary>Windows (cmd)</summary>

```cmd
set DEBUG=basic && cds watch
```

</details>

With non-productive auth strategies, automatic authentication of all endpoints
is disabled[<sup>3</sup>](#footnotes). This is why we can access resources
served by the CAP server without any authentication information in the request.

👉 Try it:

```bash
curl -i 'localhost:4004/northwhisper/Categories?$top=1'
```

<details>
<summary>Windows (PowerShell / cmd)</summary>

The `curl` commands throughout this exercise need some adjustments on Windows —
apply the same pattern to every `curl` command that follows. The tricky part is
quoting the `$` in `$top` (and other `$...` query options), and the correct
approach differs by shell:

- **PowerShell** treats `$top` inside double quotes as a variable, so double
  quotes would turn `?$top=1` into `?=1` (a `400` "Parsing URL failed" error).
  Use **single quotes** around the URL instead. Also call `curl.exe`, because
  plain `curl` is an alias for `Invoke-WebRequest`, which takes different
  options.
- **cmd** doesn't support single-quoted arguments, but it also doesn't treat
  `$` specially — so use **double quotes**. Plain `curl` is fine in cmd.

PowerShell (single quotes, `curl.exe`):

```powershell
curl.exe -i 'localhost:4004/northwhisper/Categories?$top=1'
```

cmd (double quotes):

```cmd
curl -i "localhost:4004/northwhisper/Categories?$top=1"
```

A Windows equivalent is given under each `curl` command in this exercise. Where
a command spans multiple lines, replace the bash line-continuation `\` with a
backtick `` ` `` in PowerShell or a caret `^` in cmd (or put it on one line).

Where a command sends a JSON `--data` payload, the quoting differs by shell:

- **PowerShell 7+**: wrap the JSON in single quotes with no escaping, e.g.
  `--data '{"UnitPrice":100}'`.
- **cmd**: wrap in double quotes and double the inner quotes, e.g.
  `--data "{""UnitPrice"":100}"`.
- **Windows PowerShell 5.1** (the version bundled with Windows) mangles inline
  double quotes passed to native programs, so neither reliably works there. If
  you're on 5.1, either upgrade to PowerShell 7+, or put the JSON in a file and
  use curl's `--data '@payload.json'` form.

</details>

This should return data successfully, with something like:

```log
HTTP/1.1 200 OK

{
  "@odata.context": "$metadata#Categories",
  "value": [
    {
      "CategoryID": 1,
      "CategoryName": "Beverages",
      "Description": "Soft drinks, coffees, teas, beers, and ales"
    }
  ]
}
```

> Here the JSON is presented in a pretty-printed way, for easier reading. The
> actual mechanism to do this is left off the invocation that produced this
> output, again, to keep things clean and legible. This approach is used
> throughout all the exercises in this CodeJam. If you want to have the JSON
> formatted like this, you'll need to do two things:
>
> - in circumstances where non-JSON output is also produced, like the status
>   code line in this example, you'll have to suppress it; here, you'd need to
>   omit the `-i` option that was used in the `curl` invocation to include the
>   HTTP response status code and headers
> - then you'd need to send the remaining JSON output to something like `jq`
>   invoked with the identity function `.` (and if you don't supply any filter
>   then the identity filter will be assumed), like this:
>
>    ```bash
>    curl 'localhost:4004/northwhisper/Categories?$top=1' | jq .
>    ```
>
>   Working out the Windows equivalent is left as an exercise for you, dear
>   reader.

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

<details>
<summary>Windows (PowerShell / cmd)</summary>

```powershell
curl.exe -i 'localhost:4004/northwhisper/Categories?$top=1'
```

```cmd
curl -i "localhost:4004/northwhisper/Categories?$top=1"
```

</details>

This time, we get an appropriate HTTP response:

```log
HTTP/1.1 401 Unauthorized

Unauthorized
```

> Also note that (despite the status text):
>
> - an HTTP 401 response is related to authentication
> - an HTTP 403 response (which we'll see shortly) is related to authorization

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
one[<sup>4</sup>](#footnotes).

👉 Try that now:

```bash
curl -u alan: -i 'localhost:4004/northwhisper/Categories?$top=1'
```

<details>
<summary>Windows (PowerShell / cmd)</summary>

```powershell
curl.exe -u alan: -i 'localhost:4004/northwhisper/Categories?$top=1'
```

```cmd
curl -u alan: -i "localhost:4004/northwhisper/Categories?$top=1"
```

</details>

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

<details>
<summary>Windows (PowerShell / cmd)</summary>

```powershell
curl.exe -u alan: -i 'localhost:4004/northwhisper/Products?$top=1'
```

```cmd
curl -u alan: -i "localhost:4004/northwhisper/Products?$top=1"
```

</details>

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

<details>
<summary>Windows (PowerShell / cmd)</summary>

```powershell
curl.exe -u alan: -i 'localhost:4004/northwhisper/Products?$top=1'
```

```cmd
curl -u alan: -i "localhost:4004/northwhisper/Products?$top=1"
```

</details>

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
   --header 'Content-Type: application/json' \
   --data '{"UnitPrice":100}' \
   --include \
   --url 'localhost:4004/northwhisper/Products/1'
```

<details>
<summary>Windows (PowerShell / cmd)</summary>

PowerShell (single-quoted JSON, no escaping — needs PowerShell 7+):

```powershell
curl.exe -u alan: --request PATCH --header "Content-Type: application/json" --data '{"UnitPrice":100}' --include --url "localhost:4004/northwhisper/Products/1"
```

cmd (JSON inner quotes doubled as `""`):

```cmd
curl -u alan: --request PATCH --header "Content-Type: application/json" --data "{""UnitPrice"":100}" --include --url "localhost:4004/northwhisper/Products/1"
```

</details>

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
   --header 'Content-Type: application/json' \
   --data '{"UnitPrice":100}' \
   --include \
   --url 'localhost:4004/northwhisper/Products/1'
```

<details>
<summary>Windows (PowerShell / cmd)</summary>

PowerShell (single-quoted JSON, no escaping — needs PowerShell 7+):

```powershell
curl.exe -u alan: --request PATCH --header "Content-Type: application/json" --data '{"UnitPrice":100}' --include --url "localhost:4004/northwhisper/Products/1"
```

cmd (JSON inner quotes doubled as `""`):

```cmd
curl -u alan: --request PATCH --header "Content-Type: application/json" --data "{""UnitPrice"":100}" --include --url "localhost:4004/northwhisper/Products/1"
```

</details>

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

- Did you know that `@requires: '<some-role>'` is just shorthand for
  `@restrict: [{grant:'*',to:'<some-role>'}]`?
- Did you also know that `@readonly` is just shorthand for `@restrict:
  [{grant:'READ'}]`?
- The [CAP-level
  Authorization](https://cap.cloud.sap/docs/guides/security/authorization)
  topic in Capire is definitely worth a visit.
- The blog post [CAP service authentication at design time and in
  production](https://qmacro.org/blog/posts/2026/06/19/cap-service-authentication-at-design-time-and-in-production/)
  explains how the "failsafe" production auth mechanism is designed for
  resources served in a CAP context, and includes mention of the
  `restrict_all_services` property.

---

## Footnotes

1. The [base project](../../baseproj/) is a simple CAP project definition with
   a drastically reduced version of the classic Northwind dataset, consisting
   of just three entities Products, Suppliers and Categories, and with just the
   bare minimum number of elements in each. The project has some corresponding
   initial data for each of these entities. The name of the service is
   "Northwhisper", a further step in the evolution towards minimalism
   ("Northwind" -> "Northbreeze" -> "Northwhisper").

1. See the [Remote services, proxies and
   abstraction](https://qmacro.org/blog/posts/2024/12/13/tasc-notes-part-5/#remote-services-proxies-and-abstraction)
   section of the notes to Part 5 of The Art and Science of CAP.

1. See the `restrict_all_services` flag within `requires.auth` for further
   details and the blog post [CAP service authentication at design time and in production](https://qmacro.org/blog/posts/2026/06/19/cap-service-authentication-at-design-time-and-in-production/)

1. If we don't use the `:` then `curl` will prompt for a password, like this:

    ```text
    ; curl -u alan -i 'localhost:4004/northwhisper/Products?$top=1'
    Enter host password for user 'alan':
    ```
