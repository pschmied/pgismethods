#!/usr/bin/env bash

DB=pgismethods

shp2pgsql -d -s2926 \
          ./data/esri_sausage_1000m/sausage_1000m_buffer_round_end.shp \
          public.esri_1000m_round |
    psql $DB

shp2pgsql -d -s2926 \
          ./data/esri_sausage_1000m/sausage_1000m_dissolve_flat_end.shp \
          public.esri_1000m_flat |
   psql $DB
