/* * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 Projeto DATAPREV-desafios2024, passo 3, Preparo da Mancha.
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * */


CREATE TABLE dpvd24.mancha_inund2 AS
 SELECT gid, tipo_ada::text,
  ST_Collect(
    ARRAY( --SELECT ST_MakeValid( ST_MakePolygon(
           SELECT ST_MakePolygon(
              ST_ExteriorRing(geom),
              ARRAY( SELECT ST_ExteriorRing( rings.geom )
                      FROM ST_DumpRings(geom) AS rings
                      WHERE rings.path[1] > 0 AND ST_Area(rings.geom,true) >= 256  -- L16.0
              ) -- /array
        )  -- /makes
        FROM ST_Dump(geom) AS poly where st_area(geom,true) >= 4  -- ponto 4m2 vai se tornar 256m2, se menor é desprezado.
    ) -- /array
  ) AS geom
 FROM dpvd24.mancha_inund
;

CREATE TABLE dpvd24.mancha_inund3albers AS
 SELECT gid, tipo_ada, ST_MakeValid( ST_SimplifyVW(st_transform(geom,952019),2) ) as geom
 FROM dpvd24.mancha_inund2
;
