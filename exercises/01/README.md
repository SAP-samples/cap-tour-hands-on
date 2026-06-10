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

---

## Footnotes

1. The [base project](../../baseproj/) is a simple CAP project definition with
   a drastically reduced version of the classic Northwind dataset, consisting
   of just three entities Products, Suppliers and Categories, and with just the
   bare minimum number of elements in each. The project has some corresponding
   initial data for each of these entities. The name of the service is
   "Northwisper", a further step in the evolution towards minimalism
   ("Northwind" -> "Northbreeze" -> "Northwhisper").
