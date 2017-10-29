#!/bin/bash
this="${BASH_SOURCE-$0}"
bin=$(cd -P -- "$(dirname -- "$this")" && pwd -P)
if [ -f "${bin}/../conf/env.sh" ]; then
    set -a
    . "${bin}/../conf/env.sh"
    set +a
fi

echo $NUM_OF_POINTS
