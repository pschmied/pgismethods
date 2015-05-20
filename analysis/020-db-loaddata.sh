#!/usr/bin/env bash

DB=pgismethods

# Use osm2pgrouting to build the table
osm2pgrouting -file "data/net/washington-latest.osm" \
              -conf "analysis/020-mapconfig.xml" \
              -dbname $DB \
              -user `whoami` \
              -clean


# Convert / project the network data to a WA-North NAD83 HARN ft
echo "SELECT addgeometrycolumn('ways', 'geom_2926',
      2926, 'LINESTRING', 2);
      UPDATE ways SET geom_2926 = st_transform(the_geom, 2926);
      CREATE INDEX ways_geom_2926_gidx ON ways
      USING gist(geom_2926);" |
    psql $DB

# Ditto the vertices
echo "SELECT addgeometrycolumn('ways_vertices_pgr',
      'geom_2926',2926,'POINT',2);
      UPDATE ways_vertices_pgr set geom_2926 = st_transform(the_geom, 2926);
      CREATE INDEX ways_vertices_pgr_geom_2926_gidx ON ways
      USING gist(geom_2926);" |
    psql $DB
