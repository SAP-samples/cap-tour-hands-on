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


/*
  annotate Controls with @flow.status: position;

  annotate Controls actions {
    engageForward  @from: #Neutral  @to: #Forward;
    engageNeutral  @from: [
      #Forward,
      #Reverse
    ]                               @to: #Neutral;
    engageReverse  @from: #Neutral  @to: #Reverse;

  };
*/

}

/*
annotate Switches with @flow.status: status actions {
  flipUp               @from       : #Down  @to: #Up;
  flipDown             @from       : #Up    @to: #Down;
};
*/
```

Here's what we have:

- a `Status` type which, via the `enum` definition, has two possible values
  `Up` and `Down` (think of a light switch)
- a `Switches` entity definition, where each entity has an ID and a switch
  "status", which by default (e.g. when a switch is created) is
  `Down`[<sup>2</sup>](#footnotes)
- a service exposing the `Switches` entity, and giving it a couple of bound
  action definitions `flipUp()` and `flipDown()`

This more or less models a simple switch mechanism for us, like those
shown here:

![switches](https://qmacro.org/images/2025/12/double-toggle-switch.jpg)
([Image courtesy of Wikimedia Commons](https://commons.wikimedia.org/wiki/File:A_double_toggle_light_switch.jpg)).

## Try things out

Is the model here enough? Let's see.

👉 In one terminal window, start a CAP server with `cds watch`.

👉 In a separate terminal window, experiment with the service as follows:

- create a new switch:

    ```bash
    curl \
      --header 'Content-Type: application/json'  \
      --data '{"ID":1}'  \
      --silent  \
      --url 'localhost:4004/odata/v4/switch/Switches'
    ```

  this should give us something like this:

  ```json
  {"@odata.context":"$metadata#Switches/$entity","ID":1,"status":"Down"}
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
