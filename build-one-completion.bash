#/bin/env bash

_completion()
{
  COMPREPLY=($(compgen -W "-f --force $(git branch --list 'clang-*' 'gcc-*' --format='%(refname:short)' | sed ':a;N;$!ba;s/\n/ /g')" -- "${COMP_WORDS[1]}"))
}

complete -F _completion build-one
