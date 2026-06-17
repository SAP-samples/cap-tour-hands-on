# 04 - Using the REPL

In any language or development environment, having a REPL is a superpower, and
it pays to embrace it and be at least a little familiar with it. CAP as a whole
is built on solid foundations and practices that have matured over the decades,
and the REPL is part of that, first appearing in the 1960's and initially
popularised in the LISP and LISP-derivative communities.

Node.js has a REPL, and it is upon this REPL that the cds REPL is based.

## Start a new CAP project

Like we did in an earlier exercise, we'll start with the "base project" to save
a bit of time.

👉 Create a new project directory for this exercise using the base project:

```bash
rm -rf proj-04 \
  && cp -a baseproj proj-04 \
  && cd $_
```

We should by now be familiar with the contents of this project, a very reduced
version of Northwind, with just products, suppliers and categories (each of
which have just a few fields) exposed in a single service.

## Fire up the cds REPL

Let's dive right in.

Start the REPL:

```bash
cds repl
```

and you'll be presented with a simple prompt:

```text
Welcome to cds repl v9.9.1
>
```

whereupon, to honour one of the pivotal moments of the birth of personal
computing[<sup>1</sup>](#footnotes), there's only one thing we should type in
at this point, and that's `2 + 2`:

```javascript
> 2 + 2
4
```

Yes, this REPL expects and interprets JavaScript.

## Further info

- The [Wikipedia article on the
  REPL](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop) has
  some great background and history.

## Footnotes

1. The co-founder of Microsoft, Paul Allen, on arriving at MITS in Albuquerque
   NM in March 1975 to demonstrate the BASIC interpreter that he and Bill Gates
   had worked on and were hoping to license, loads the code from the paper tape
   into the ALTAIR 8800 and at the BASIC prompt that appears, types `PRINT 2 +
   2`. This also appears subsequently as an example in the Introduction section
   of the [MITS ALTAIR
   BASIC](https://deramp.com/downloads/mfe_archive/010-S100%20Computers%20and%20Boards/00-MITS/40-Software/BASIC/Altair%20BASIC%203.0/Documentation/Altair_8800_BASIC_Reference_Manual_1975.pdf)
   manual. See the article [MITS licenses Altair BASIC from Bill Gates and Paul
   Allen](https://www.computinghistory.org.uk/det/5946/Bill-Gates-and-Paul-Allen-sign-a-licensing-agreement-with-MITS/)
   from the Centre for Computing History.

