[![REUSE status](https://api.reuse.software/badge/github.com/SAP-samples/cap-tour-hands-on)](https://api.reuse.software/info/github.com/SAP-samples/cap-tour-hands-on)

# A hands-on tour of CAP

Explore some of CAP's facets, features & facilities in this series of hands-on
exercises.

## Introduction

In this hands-on workshop you'll explore various developer and design-time
focused features of CAP, the domain expert and developer centric framework for
modern SAP development.

## Prerequisites

In order to work through the exercises, you'll need a development environment
for CAP Node.js. See the [prerequisites info](prerequisites/README.md) page for
details and options.

## Exercises

To get started, clone this repository and open it in your favourite editor or
IDE. Alternatively, launch a GitHub Codespace directly from this repository -
see the [prerequisites](prerequisites/README.md) for more info.

- [01 - Mocking auth](exercises/01/README.md)

    With the mocked authentication strategy, we can embrace and work on the
    important aspect of securing our app or service right from the very start. CAP
    makes it easy to do the right things here.

    In this exercise we'll look at how we can do that, based on a simple service.

- [02 - Mocking messaging](exercises/02/README.md)

    In the blog post "Five reasons to use CAP" we see that everything is an event.
    Whether synchronous, such as via HTTP requests and responses for OData
    operations, or asynchronous, where messages are emitted and received for
    decoupled service-to-service communications.

    The Messaging topic in Capire has a great overview and an explanation of all
    the different message brokers that can be used. And there's one that is well
    suited for local-first development: file based messaging, which we'll explore
    in this exercise.

- [03 - Creating a plugin](exercises/03/README.md)

    The plugin concept is fundamental to the CAP framework. Not only as a clean
    and simple extension mechanism, but also a core building block in the
    framework itself. Various basic components in CAP are implemented as
    plugins, as well as many additional features.

    In this exercise we'll implement a simple plugin so that we understand how
    they're put together and how they work.

- [04 - Using the REPL](exercises/04/README.md)

    In any language or development environment, having a REPL is a superpower, and
    it pays to embrace it and be at least a little familiar with it. CAP as a whole
    is built on solid foundations and practices that have matured over the decades,
    and the REPL is part of that, first appearing in the 1960's and initially
    popularised in the LISP and LISP-derivative language communities.

    Node.js has a REPL, and it is upon this REPL that the cds REPL is based. In
    this exercise, we'll explore the cds REPL.

- [05 - Exploring status-transition flows](exercises/05/README.md)

    Released towards the end of 2025, status-transition flows moves us one step
    closer to declarative nirvana, and in the right direction with regards to
    LLM-based learning about CAP powered solutions, a smaller code surface area,
    and a shift left of logic and definitions.

    In this exercise we'll get a feel for status-transition flows by exploring a
    simple implementation.

- [06 - Testing your services](exercises/06/README.md)

    In the previous exercise we checked the behaviour of our service
    definition by starting the CAP server and then manually sending HTTP requests
    to it. This is a great way to interact, but no the only one.

    In this exercise we'll add tests which will put our service through its paces.
    We'll do that first by exploring in the cds REPL and then formalising our
    explorations in a file that we can drive with a test runner.

- [07 - Defining constraints declaratively](exercises/07/README.md)

    CDS modelling doesn't stop at entities, relationships and service exposure.
    Domain design also includes constraints, and these can be included in the
    overall model declaratively, meaning a cleaner and smaller surface area (less
    chance of bugs), a shared understanding of intent between the domain expert and
    developer and less code to write and maintain.

    In this exercise, we'll explore declarative constraints by adding some to our
    Northwind-based base project.

- [08 - Discovering API client package export and reuse](exercises/08/README.md)

    CAP-level service integration (Calesi) is a powerful and flexible concept and
    exists in various forms. One of these is the idea of API client packages which
    can be created from CDS service definitions, exported, and then used in
    consumer projects.

    In this exercise we'll explore what that is, and how it works.

## Utilities

The [utils/](utils/) directory contains a small `showurls` helper that emits
the `http://localhost:4004...` URLs found in a given exercise's README, which
is handy in GitHub Codespaces where `localhost` addresses are auto-exposed with
custom domain names. Use the variant that matches your shell, passing the
exercise number as the argument:

- macOS / Linux / Codespaces: `./utils/showurls 1`
- Windows (PowerShell): `.\utils\showurls.ps1 1`
- Windows (cmd): `utils\showurls.cmd 1`

All three produce identical output.

## Support

Support for the content in this repository is available during the actual time
of the workshop event for which this content has been designed.

## License

Copyright (c) 2026 SAP SE or an SAP affiliate company. All rights reserved.
This project is licensed under the Apache Software License, version 2.0 except
as noted otherwise in the [LICENSE](LICENSE) file.
