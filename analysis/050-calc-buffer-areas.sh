DB=pgismethods

echo "COPY (SELECT ST_Area(sb_1000m.geom_poly) AS postgis,
              ST_Area(esri_1000m_round.geom) AS esri,
              sb_1000m.id as id
              FROM gis.sb_1000m
              LEFT JOIN public.esri_1000m_round
              ON gis.sb_1000m.id = public.esri_1000m_round.id_t)
      TO STDOUT WITH CSV HEADER;" |
    psql $DB > ./results/buffer_areas.csv

echo "COPY (SELECT ST_Area(ST_SymDifference(sb_1000m.geom_poly, esri_1000m_round.geom)) AS pg_esr,
              sb_1000m.id as id
              FROM gis.sb_1000m
              LEFT JOIN public.esri_1000m_round
              ON gis.sb_1000m.id = public.esri_1000m_round.id_t)
      TO STDOUT WITH CSV HEADER;" |
    psql $DB > ./results/buffer_symdiffs.csv
