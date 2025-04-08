/* * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 Projeto DATAPREV-desafios2024, passo 2, ingestão (ETL).
 Editar com as suas configurações locais!
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

-- -- -- -- -- -- -- -- -- -- --
--- INGEST CNEFE:
DO $do$
DECLARE
 i text;
 ibge_files text DEFAULT '/tmp/IBGE/'; -- please CHANGE HERE to your path!!
BEGIN
   FOREACH i IN ARRAY '{11_RO,12_AC,13_AM,14_RR,15_PA,16_AP,17_TO,21_MA,22_PI,23_CE,24_RN,25_PB,26_PE,27_AL,28_SE,29_BA,31_MG,32_ES,33_RJ,35_SP,41_PR,42_SC,43_RS,50_MS,51_MT,52_GO,53_DF}'::text[] LOOP
      CALL dpvd24.ins_on_t01_ibge_cnefe2022_point(ibge_files|| i ||'.csv');
      COMMIT;
   END LOOP;
END
$do$;

-- -- -- -- -- -- -- -- -- -- --
--- INGEST MANCHA INUNDAÇÃO RS:

-- ogr2ogr -f "ESRI Shapefile" /tmp/mancha_inund/ADA_SPGG_03092024.kml
-- shp2pgsql -I -s 4674 /tmp/mancha_inund/ada_03092024.shp dataprev.test_ingest | psql postgres://postgres@localhost/dbtest

CREATE TABLE dpvd24.t03dump_mancha_inund AS
SELECT t0.gid, t1.i, t0.tipo_ada, ST_MakeValid( ST_SimplifyVW(t1.g,2) ) as geom
 FROM (
  SELECT gid, tipo_ada::text,
    ARRAY(
           SELECT ST_MakePolygon(
              ST_ExteriorRing(geom),
              ARRAY( SELECT ST_ExteriorRing( rings.geom )
                      FROM ST_DumpRings(geom) AS rings
                      WHERE rings.path[1] > 0 AND ST_Area(rings.geom,true) >= 4
              ) -- /array
        )  -- /makes
        FROM ST_Dump(geom) AS poly where st_area(geom,true) >= 4 -- remove menor que 4m2
    ) AS geoms
  FROM dpvd24.t02_mancha_inund
 ) t0,
 UNNEST(t0.geoms) WITH ORDINALITY t1(g,i)
; -- 27986 rows
