#!/usr/bin/env bash
DB=pgismethods

mkdir -p data/random_200_2926
pgsql2shp -f data/random_200_2926/random_200_2926 -g geom_2926 \
          pgismethods "gis.random_200"

mkdir -p data/net_shp_2926
pgsql2shp -f data/net_shp_2926/net_shp_2926 -g geom_2926 \
          pgismethods "public.ways"

mkdir -p data/random_200_wgs84
pgsql2shp -f data/random_200_wgs84/random_200_wgs84 \
          pgismethods "gis.random_200"

mkdir -p data/net_shp_wgs84
pgsql2shp -f data/net_shp_wgs84/net_shp_wgs84 \
          pgismethods "public.ways"
