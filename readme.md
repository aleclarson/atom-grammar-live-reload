# Language grammars Live Reload for Atom (Async)

[![Atom Package](https://img.shields.io/apm/v/grammar-live-reload.svg)](https://atom.io/packages/grammar-live-reload)
[![Atom Package Downloads](https://img.shields.io/apm/dm/grammar-live-reload.svg)](https://atom.io/packages/grammar-live-reload)
[![Build Status](https://travis-ci.org/ldez/atom-grammar-live-reload.svg?branch=master)](https://travis-ci.org/ldez/atom-grammar-live-reload)
[![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://github.com/ldez/atom-grammar-live-reload/blob/master/LICENSE.md)

Reload automatically editors when grammars files (`.cson`) changes.

The reloading is doing asynchronously.

Only editors that are affected by the selected language are reload.

TODO: screenshots

## Options

- `Enabled live reload`: check if you want to enabled grammars live reload.
- `Name of the package to grammars reload`: define the name of your grammars package. (ex: `language-git`)
  - currently not support for multiple packages language (but support multiple languages in one package)

## Install

Settings/Preferences > Install > Search for `grammar-live-reload`

Or

```bash
apm install grammar-live-reload
```
