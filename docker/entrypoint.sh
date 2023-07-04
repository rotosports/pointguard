#!/bin/sh

set -e 

if [ "$1" = 'pointguardd' ]; then
    ./init.sh

    exec "$@" "--"
fi

exec "$@"