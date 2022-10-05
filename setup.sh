#!/usr/bin/bash

PREFIX=${PWD}
PROGRAM=$(basename ${PWD})
PROG_ENV="${PROGRAM^^}"
BASENAME=$(basename $0)

show_help() {
  cat<<EOF

  [ Usage ]

  ./$(basename $0) install --- create shellscript for luajit
  
  [ Requirement ]

  * 'shell' mode : lua5.1 or luajit

  [ Exec EveryWhere ]
  * program will be ${PREFIX}/bin/${PROGRAM}
  * Add this path environment below:
  \$ echo "export PATH=\$PATH:${PREFIX}/bin/${PROGRAM}" >> ~/.bashrc"

EOF
}

check_luajit() {
  luajit -e 'print(_VERSION)'  | grep 'Lua 5.1' >/dev/null 2>&1
  [ $? != 0 ] && echo "Install Luajit 2.1.x please." && return 1
}

shell_luajit() {
  check_luajit
  mkdir -p ${PREFIX}/bin
  cat<<EOF  > ${PREFIX}/bin/${PROGRAM}
#!/bin/sh
export LUA_PATH="${PREFIX}/lib/?.lua"
export ${PROG_ENV}=${PREFIX}
exec "${PREFIX}/lib/main.lua" "\$@"
EOF

  chmod u+x ${PREFIX}/bin/${PROGRAM}
  echo "--> ${PREFIX}/bin/${PROGRAM} is created!"
}

# ## Main
[ $# -ne 1 ] && show_help && exit
[ $1 == 'install' ]  && shell_luajit && exit

show_help
