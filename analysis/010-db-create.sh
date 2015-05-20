#!/usr/bin/env bash

# Assumption here is that PostGIS is running locally, that the
# current user has administrative rights to the DB, and that the
# postgres user binaries are all in the current user's PATH.
#
# WARNING: If you happen to have a db named pgismethods, well, you'll
# have a different one after running this script.

DB=pgismethods

# Drop the DB
dropdb $DB

# Create the DB
createdb $DB

# Enable PostGIS extensions
echo "CREATE EXTENSION postgis; CREATE EXTENSION postgis_topology;" |
    psql $DB

# Enable PgRouting extension
echo "CREATE EXTENSION pgrouting;" |
    psql $DB
