# lemo - Luajit Memo Console Program for quick note and search

## Intro

* Quick note and search
* Small luajit script program
* Linux base command line memo program
* File based memo database system: `PREFIX/data/<time>`
* Fancy Nerd font icons and colored terminal display
* No dependency except `luajit` and `vim`
* Portable

## Requirement

* on `Linux` or `unix` base system
* `luajit-2.1`
* `Nerd Font` on Terminal
* `vim` for edit mode

## Install

```console
$ git clone https://github.com/neosolaris/lemo.git
$ cd lemo/
$ ./setup.sh --help
$ ./setup.sh install # create shellscript command to 'bin/lemo'
$ export PATH=$PATH:<your_lemo_path>/bin
$ lemo -h
```

## Usage

```console
Usage: lemo v0.1

-a|add "strings"             -- add memo
-d|delete id[s]              -- delete id[s]
-e|edit id[s]                -- edit id[s]
-l|list [d|dd|ddd|w|m|y|a]   -- list
   d:today dd:yesterday ddd:day before yesterday
   w:week m:month y:year a:all
-s|search keyword[s]         -- keyword[s] search: and-search
-v|view id[s]                -- view id[s]
-h|help                      -- this help
```

## TODO

* Add mode: readlines support
* List mode: d, dd, etc options support
* search mode: ignorecase support
* Security: memo file encryption support
