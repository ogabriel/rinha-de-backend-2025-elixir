#!/bin/sh

if [ "$1" = 'migrate_and_release' ]; then
    /app/bin/check_database
    /app/bin/drop_database
    /app/bin/create_database
    /app/bin/migrate

    exec /app/bin/server
elif [ "$1" = 'release' ]; then
    /app/bin/check_database

    exec /app/bin/server
fi
