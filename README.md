# lemo - Luajit Console Memo Program

## Intro

* Quick note and search (ignorecase, multi keyword)
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

* Usage
```console
Usage: lemo "strings"

  -a|add "strings"             -- add memo
  -d|delete id[s]              -- delete id[s]
  -e|edit id[s]                -- edit id[s]
  -x|export id[s]              -- same as -v, but pure output
  -l|list [d|w|m|y|a]          -- list
           d:today w:week m:month y:year a:all
  -s|search keyword[s]         -- keyword[s] search: and-search
  -v|view id[s]                -- view id[s]

 lemo_0.1.2  help ﰲ Console Memo Powered by LuaJit
```

* Add memo
```console
$ lemo
foo
bar
^d(Control + d)

$ lemo -a "foo
bar"

$ lemo -a foo bar hello world
```

* list memo
```console
$ lemo -l         # default: in 3 days
$ lemo -l d(ay)   # in today
$ lemo -l w(eek)  # in this week
$ lemo -l m(onth) # in this month
$ lemo -l y(ear)  # in this year
$ lemo -l 5       # in a five days
```

* search memo
```console
$ lemo -s foo      # single keyword
$ lemo -s foo bar  # search 'foo' and 'bar'
```

* edit memo
```console
$ lemo -e 1  # edit id (vim is default editor)
```

## TODO

* Add mode: readlines support
* Security: memo file encryption support
* [x] 2022.10.07: List mode: d(ay), w(eek), m(onth), y(ear), a(ll) options added
* [x] 2022.10.07:search mode: `ignorecase`, `and` search support
