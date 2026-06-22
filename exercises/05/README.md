# 05 - Exploring status-transition flows

Released towards the end of 2025, status-transition flows moved us one step
closer to declarative nirvana, and in the right direction with regards to
LLM-based learning about CAP powered solutions, a smaller code surface area,
and a shift left of logic and definitions.

At the time of writing, this feature is now maturing and is currently in Gamma
status.

Let's get a feel for status-transition flows by exploring a simple
implementation.

## Create a new project

👉 Create a new project directory `proj-05/`:

```bash
rm -rf proj-05 \
  && cd $_
```

We'll keep things simple so as not to distract from the feature we want to
understand.

The idea is to model a classic lever engine control as typically found on
narrowboats. These are known as "Morse" controls and enable gear selection
(foward or reverse) and propeller rotation speed with a single control (see
[Further info](#further-info) for more).

![Morse control on narrowboat FULLY
RESTFUL](assets/morse-control-on-fully-restful.png)
_The Morse control on
narrowboat FULLY RESTFUL, with the lever position in the centre (neutral)._

As with other engines, there's also the neutral position that sits between
forward and reverse gears, and a brief moment in neutral before engaging the
opposite direction is always preferable so as not to put undue strain on the
gearbox.

## Define the CDS model

👉 In a new file `services.cds`[<sup>1</sup>](#footnotes) in the project root,
add this:

```cds
context codejam {

  type Position : String enum {
    Forward;
    Neutral;
    Reverse;
  }

  entity Controls {
    key ID       : Integer;
        position : Position default #Neutral;
  }
}

service MorseService {

  entity Controls as projection on codejam.Controls

    actions {
      action engageForward();
      action engageNeutral();
      action engageReverse();
    };

}
```

Here's what we have:

- a `Status` type which, via the `enum` definition, has three possible values
  `Forward`, `Neutral` and `Reverse`
- a `Controls` entity definition, where each entity has an ID and a lever
  "position", which by default (e.g. when a control is created) is at
  `Neutral`[<sup>2</sup>](#footnotes)
- a service exposing the `Controls` entity and giving it some bound action
  definitions `engageForward()`, `engageNeutral()` and `engageReverse()`

This models the Morse control described earlier, and gives us the chance to
implement a restriction so that we can't go directly from `Forward` to
`Reverse` (or vice versa) without first being in `Neutral`.

## Try things out

Is the model here enough? Let's see.

👉 Start a CAP server with `cds watch`, and then open a second terminal window to carry out the following experiments.

👉 Create a new control:

```bash
curl \
  --silent  \
  --data '{"ID":1}'  \
  --url 'localhost:4004/odata/v4/morse/Controls'
```

This should return something like this (note the default position of `Neutral`):

```json
{
  "@odata.context": "$metadata#Switches/$entity",
  "ID": 1,
  "position": "Neutral"
}
```

👉 Create another new control, this time setting the initial gear selection:

```bash
curl \
  --silent  \
  --data '{"ID":2,"position":"Forward"}'  \
  --url 'localhost:4004/odata/v4/morse/Controls'
```

This also returns something similar:

```json
{
  "@odata.context": "$metadata#Switches/$entity",
  "ID": 2,
  "position": "Forward"
}
```

But - just like starting an engine with a forward gear selected - this is not a
good idea and we probably want to prevent this from happening.

👉 Now try to move the first control from its current position to `Reverse`,
using the appropriate action:

```bash
curl \
  --request POST \
  --include \
  --url 'localhost:4004/odata/v4/morse/Controls/1/engageReverse'
```

Not entirely unexpectedly, we get an error:

```log
HTTP/1.1 501 Not Implemented
OData-Version: 4.0
Content-Type: application/json; charset=utf-8

{
  "error": {
    "message": "Service \"MorseService\" has no handler for \"engageReverse MorseService.Controls\".",
    "code": "501",
    "@Common.numericSeverity": 4
  }
}
```

Of course, we're going to have to implement all these actions.

Or are we?

👉 Let's try just updating the value of the `position` element directly:

```bash
curl \
  --request PATCH \
  --data '{"position":"Reverse"}' \
  --silent \
  --url 'localhost:4004/odata/v4/morse/Controls/1'
```

That worked - we got:

```json
{
  "@odata.context": "$metadata#Controls/$entity",
  "ID": 1,
  "position": "Reverse"
}
```

But is that what we really want? Because we can also slam the engine straight
from `Reverse` into `Forward` without going through `Neutral`.

👉 Try it:

```bash
curl \
  --request PATCH \
  --data '{"position":"Forward"}' \
  --silent \
  --url 'localhost:4004/odata/v4/morse/Controls/1'
```

Yikes!

```json
{
  "@odata.context": "$metadata#Controls/$entity",
  "ID": 1,
  "position": "Forward"
}
```



## Further info

- The Fitout Pontoon's page on [Engine
  Controls](https://www.thefitoutpontoon.co.uk/engines-drive-gear/controls/)
  has an overview of Morse lever controls.
- See [Shift left with
  CAP](https://qmacro.org/blog/posts/2026/02/09/shift-left-with-cap/) for an
  explanation of the "shift left" idea.
- The [Status-Transition
  Flows](https://cap.cloud.sap/docs/guides/services/status-flows) topic in
  Capire has some great info on this feature.
- There are different statuses for features and APIs in CAP. See the [Status
  Badges](https://cap.cloud.sap/docs/releases/index#status-badges) section of
  the Releases topic in Capire for more info.
- For a dive into status-transition flows, see [A simple exploration of status
  transition flows in
  CAP](https://qmacro.org/blog/posts/2025/12/08/a-simple-exploration-of-status-transition-flows-in-cap/)

---

## Footnotes

1. See [Why I use services.cds in simple CDS model
   examples](https://qmacro.org/blog/posts/2026/01/02/why-i-use-services-cds-in-simple-cds-model-examples/).
1. The default value is expressed as the enum symbol, rather than the literal
   value, by using the `#` prefix - see the [Default
   Values](https://cap.cloud.sap/docs/cds/cdl#default-values) section of the
   CDL topic in Capire.
