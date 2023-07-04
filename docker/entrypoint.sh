#!/bin/sh

set -e 

if [ "$1" = 'pointguard' ]; then
    ./init.sh

    exec "$@" "--"
fi

exec "$@"