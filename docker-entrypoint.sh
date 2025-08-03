#!/bin/sh

if [ "$1" = 'migrate_and_release' ]; then
    exec /app/rinha start
elif [ "$1" = 'release' ]; then
    exec /app/rinha start
fi
