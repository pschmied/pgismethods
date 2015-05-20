--
-- 
-- GIS functions for creating sausage buffers
--
--

-- First, create a gis schema to contain said functions
CREATE SCHEMA IF NOT EXISTS gis;

-- Set our search path to include the new schema
set search_path TO "$user", gis, public, topology;


--
-- Create sausage buffer around ONE point
-- 
drop function if exists gis.sausagebuffer (
pointsource_tablename text, 
pointsource_id_columnname text, 
pointsource_id text,
pointsource_geom_columnname text,
edge_tablename text, 
edge_geom_columnname text, 
vertex_tablename text, 
vertex_geom_columnname text, 
networkbufferdistance_m integer, 
linebufferdistance_m integer);

create function gis.sausagebuffer(
pointsource_tablename text, 
pointsource_id_columnname text, 
pointsource_id text,
pointsource_geom_columnname text,
edge_tablename text, 
edge_geom_columnname text, 
vertex_tablename text, 
vertex_geom_columnname text, 
networkbufferdistance_m integer, 
linebufferdistance_m integer) RETURNS 
TABLE(id text, geom_poly geometry, geom_line geometry)
AS
$BODY$
DECLARE
    source_vertex_id bigint;
    dest_vertex_ids text;
    result record;
    helper text;
BEGIN

-- set the search path
-- set search_path TO twins, gis, public, pmh, topology;


-- a query to get the closest vertex to home location -- generates a variable 'id'
        -- DECLARE cnt INTEGER;
        -- SELECT INTO cnt count(*) FROM t;
            -- or 
        -- cnt := COUNT(*) FROM t;
execute 'SELECT id
FROM 
' || vertex_tablename || '  as v
ORDER BY v.' || vertex_geom_columnname || '<-> 
(select 
' || pointsource_geom_columnname || ' from
' || pointsource_tablename || ' as r where 
' || pointsource_id_columnname || ' = 
'
|| quote_literal(pointsource_id) ||
') 
LIMIT 1' into source_vertex_id;

--RAISE NOTICE 'ID: %', source_vertex_id;

-- a query to get the array of vertices within X distance of home location of ID n -- generates a string variable 'sarray'
EXECUTE '
select array(
select v.id from 
' || vertex_tablename || ' as v, 
(
SELECT id, v. ' || vertex_geom_columnname || ' 
FROM 
' || vertex_tablename || ' as v
ORDER BY 
v. ' || vertex_geom_columnname || ' <-> 
(select 
' || pointsource_geom_columnname || ' from 
' || pointsource_tablename || ' where ' || pointsource_id_columnname || ' = '
|| quote_literal(pointsource_id) ||'
)
LIMIT 1
) as s
where st_dwithin(
v.' || vertex_geom_columnname || ',
s.' || pointsource_geom_columnname || ', '|| networkbufferdistance_m || ' * 3.2808 )
and s.id <> v.id
)::text'
INTO dest_vertex_ids;

dest_vertex_ids:= trim(dest_vertex_ids, '{}');

--RAISE NOTICE 'dest ID: %', dest_vertex_ids;


-- helper query for dijkstra
helper :=  'SELECT gid as id, source, target, length as cost FROM ' || edge_tablename;

RAISE NOTICE '%', helper;

-- a query to generate a sausage buffer -- outputs a record
return query execute 'select ' || quote_literal(pointsource_id) || '::text as id,
st_collect(geom_poly) as geom_poly,
geom_line
from
(select
    st_makepolygon(
        st_exteriorring(
            (st_dump(
                st_union(
                    st_buffer(st_linesubstring(the_geom, 0, prop), ' || linebufferdistance_m || ' * 3.2808, 40)
                )
            )).geom
        )
    ) as geom_poly
--st_makepolygon(st_exteriorring(st_union(st_buffer(st_linesubstring(the_geom, 0, prop), ' || linebufferdistance_m || ' * 3.2808, 40)))) as the_geom
--((st_union(st_buffer(st_linesubstring(the_geom, 0, prop), ' || linebufferdistance_m || ' * 3.2808, 40)))) as the_geom
, st_collect(st_linesubstring(the_geom, 0, prop)) as geom_line
from
(SELECT path
    , CASE 
        WHEN px = lx0
            AND py = ly0
            THEN the_geom
        ELSE st_reverse(the_geom)
        END AS the_geom
    , length as length_ft
    , length / 3.2808 as length_m
    , case
        when ' || networkbufferdistance_m || ' / (length / 3.2808) < 1 -- v networkbufferdistance_m
            then ' || networkbufferdistance_m || ' / (length / 3.2808) -- v networkbufferdistance_m
        else 1
     end as prop
FROM (
    SELECT p.*
        , st_x(st_pointn(the_geom, 1)) AS lx0
        , st_y(st_pointn(the_geom, 1)) AS ly0
        , st_x(st_pointn(the_geom, st_numpoints(the_geom))) AS lx1
        , st_y(st_pointn(the_geom, st_numpoints(the_geom))) AS ly1
        , l.*
    FROM (
        SELECT *
--             , st_asewkt(the_geom)
--             , st_length(the_geom)
        FROM (
            SELECT id1 AS path
                , st_linemerge(st_union(b.' || edge_geom_columnname || ' )) AS the_geom
                , st_length(st_union(b.' || edge_geom_columnname || ' )) AS length
            FROM pgr_kdijkstrapath(' || quote_literal(helper) || ',
-- this is a variable
' || source_vertex_id || '
, array 
                    [
-- this is a variable
' || dest_vertex_ids || '
]   -- vertexdestinationids
                    , false, false) AS a
                , ' || edge_tablename || '  AS b
            WHERE a.id3 = b.gid
            GROUP BY id1
            ORDER BY id1
            ) AS a
        ) AS l
        , (
            SELECT st_x(' || vertex_geom_columnname || ' ) AS px
                , st_y(' || vertex_geom_columnname || ') AS py
            FROM ' || vertex_tablename || '
            WHERE id = ' || source_vertex_id || '
            ) AS p
    ) AS foo) as foo) as foo
	group by geom_line';
    END
$BODY$
LANGUAGE 'plpgsql' ;






--
-- Multiple sausage buffers
-- 
-- set search_path = twins, gis, public, topology;

drop function if exists gis.sausagebufferloop (
pointsource_tablename text, 
pointsource_id_columnname text, 
pointsource_geom_columnname text,
pointsource_subquery text,
edge_tablename text, 
edge_geom_columnname text, 
vertex_tablename text, 
vertex_geom_columnname text, 
networkbufferdistance_m integer, 
linebufferdistance_m integer);

create function gis.sausagebufferloop(
pointsource_tablename text, 
pointsource_id_columnname text, 
pointsource_geom_columnname text,
pointsource_subquery text,
edge_tablename text, 
edge_geom_columnname text, 
vertex_tablename text, 
vertex_geom_columnname text, 
networkbufferdistance_m integer, 
linebufferdistance_m integer)

RETURNS 
TABLE(id text, geom_poly geometry, geom_line geometry)
AS
$BODY$
DECLARE
    studyid text; 
    rec integer;
    use_sql text;
    search_sql text := '';
BEGIN
    search_sql := 'SELECT ' || pointsource_id_columnname || ' FROM ' || pointsource_tablename || ' ' || pointsource_subquery || ' ORDER BY ' || pointsource_id_columnname;
    for studyid in execute(search_sql) LOOP
        -- can do some processing here
    raise notice 'STUDY ID: %', studyid;
        use_sql := 
            'select * from sausagebuffer(
            ' || quote_literal(pointsource_tablename) || ',
            ' || quote_literal(pointsource_id_columnname) || ',
            ' || quote_literal(studyid) || ',
            ' || quote_literal(pointsource_geom_columnname) || ',
            ' || quote_literal(edge_tablename) || ',
            ' || quote_literal(edge_geom_columnname) || ',
            ' || quote_literal(vertex_tablename) || ',
            ' || quote_literal(vertex_geom_columnname) || ',
            ' || networkbufferdistance_m || ',
            ' || linebufferdistance_m || ')' ;
        RETURN QUERY EXECUTE use_sql;
    END LOOP;
END
$BODY$
LANGUAGE 'plpgsql' ;
