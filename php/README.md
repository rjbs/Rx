# Shaggy8871\Rx

[![Author](https://img.shields.io/badge/author-@shaggy8871-blue.svg?style=flat-square)](https://twitter.com/johnginsberg)
[![Software License](https://img.shields.io/badge/license-GPL-brightgreen.svg?style=flat-square)](https://github.com/shaggy8871/Rx/blob/master/LICENSE)

Based on https://github.com/rjbs/Rx with ideas from https://blog.picnic.nl/how-to-use-yaml-schema-to-validate-your-yaml-files-c82c049c2097

## What is Rx?

When adding an API to your web service, you have to choose how to encode the
data you send across the line. XML is one common choice for this, but it can
grow arcane and cumbersome pretty quickly. Lots of webservice authors want to
avoid thinking about XML, and instead choose formats that provide a few simple
data types that correspond to common data structures in modern programming
languages. In other words, JSON and YAML.

Unfortunately, while these formats make it easy to pass around complex data
structures, they lack a system for validation. XML has XML Schemas and RELAX
NG, but these are complicated and sometimes confusing standards. They're not
very portable to the kind of data structure provided by JSON, and if you wanted
to avoid XML as a data encoding, writing more XML to validate the first XML is
probably even less appealing.

Rx is meant to provide a system for data validation that matches up with
JSON-style data structures and is as easy to work with as JSON itself.

## Installation

```
composer require shaggy8871/rx
```

## Documentation

[Check out the documentation](http://rx.codesimply.com/)

## Usage

* Create a schema file
* Run `./vendor/bin/rx <yaml/json> <schema> ["<glob of custom types>"]`
* Be sure to quote custom type glob!

For example, `./vendor/bin/rx test.yml schema.yml "types/*.yml"`