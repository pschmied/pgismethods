SET search_path = gis, public, topology;

-- Create a table of 200 randomly sampled vertices; table is fully
-- realized for comparison in ArcGIS.
DROP TABLE IF EXISTS random_200;
CREATE TABLE random_200 AS
SELECT * FROM ways_vertices_pgr
ORDER BY RANDOM()
LIMIT 200;

-- Create the buffers around our points
DROP TABLE IF EXISTS sb_1000m;
CREATE TABLE sb_1000m AS
select * from gis.sausagebufferloop(
'random_200', 'id', 'geom_2926',
'',
'ways', 'geom_2926',
'ways_vertices_pgr',
'geom_2926',
1000,
100);
