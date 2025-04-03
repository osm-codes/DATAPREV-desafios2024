/* * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 Projeto DATAPREV-desafios2024, passo 1, Inicializações.
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

-- -- -- -- -- -- -- -- -- -- --
--- INI POSTGIS:

CREATE extension IF NOT EXISTS postgis;

INSERT INTO spatial_ref_sys (srid, auth_name, auth_srid, proj4text, srtext) VALUES
(
  952019,
  'BR:IBGE',
  52019,
  '+proj=aea +lat_0=-12 +lon_0=-54 +lat_1=-2 +lat_2=-22 +x_0=5000000 +y_0=10000000 +ellps=WGS84 +units=m +no_defs',
  $$PROJCS[
  "Conica_Equivalente_de_Albers_Brasil",
  GEOGCS[
    "GCS_SIRGAS2000",
    DATUM["D_SIRGAS2000",SPHEROID["Geodetic_Reference_System_of_1980",6378137,298.2572221009113]],
    PRIMEM["Greenwich",0],
    UNIT["Degree",0.017453292519943295]
  ],
  PROJECTION["Albers"],
  PARAMETER["standard_parallel_1",-2],
  PARAMETER["standard_parallel_2",-22],
  PARAMETER["latitude_of_origin",-12],
  PARAMETER["central_meridian",-54],
  PARAMETER["false_easting",5000000],
  PARAMETER["false_northing",10000000],
  UNIT["Meter",1]
 ]$$
) ON CONFLICT DO NOTHING;

-- -- -- -- -- -- -- -- -- -- --
--- Public Helper functions:

CREATE or replace FUNCTION ROUND(float,int) RETURNS NUMERIC AS $wrap$
   SELECT ROUND($1::numeric,$2)
$wrap$ language SQL IMMUTABLE;
COMMENT ON FUNCTION ROUND(float,int)
  IS 'Cast for ROUND(float,x). Useful for SUM, AVG, etc. See also https://stackoverflow.com/a/20934099/287948.'
;

CREATE or replace FUNCTION dynamic_query(text) RETURNS SETOF RECORD AS
$f$
 BEGIN
    RETURN QUERY EXECUTE $1;
 END
$f$ language  PLpgSQL;
COMMENT ON FUNCTION dynamic_query(text)
  IS 'Executes dynamically the text as a SQL-query (DQL command).'
;

CREATE or replace FUNCTION dynamic_execute(text) RETURNS boolean AS
$f$
 BEGIN
    RAISE NOTICE '-- EXECUTing: %',substring(trim($1),1,52)||'...'; -- max 64 columns
    EXECUTE $1 ;  -- INTO ret; revisar para comando devolver ret booleano de sucesso
    RETURN true;
 END
$f$ language  PLpgSQL;
COMMENT ON FUNCTION dynamic_execute(text)
  IS 'Executes dynamically the text as a SQL non-DQL COMMAND, like CREATE TABLE.'
;

-- -- -- -- -- -- -- -- -- -- --
--- INI Project:

DROP SCHEMA IF EXISTS dpvd24 CASCADE;
CREATE SCHEMA dpvd24;

CREATE TABLE dpvd24.t01_ibge_cnefe2022_point (
 COD_UNICO_ENDERECO  bigint NOT NULL PRIMARY KEY,
 COD_MUNICIPIO int NOT NULL,
 COD_UF_part smallint NOT NULL, -- obrigatório no SELECT WHERE 
 geom geometry(Point, 4326) NOT NULL
) PARTITION BY LIST (COD_UF_part)
;
SELECT dynamic_execute( format(
    'CREATE TABLE IF NOT EXISTS dpvd24.partition_t01_p%s PARTITION OF dpvd24.ins_on_t01_ibge_cnefe2022_point FOR VALUES IN (%1$s); ', i
  ) )
FROM unnest('{1,2,3,35,4,5}'::text[]) t(i);

-- FUNCTION for queries WHERE COD_UF_part=dpvd24.get_partition_t01($UF): CASE WHEN $1=35 THEN 35 ELSE $1/10::smallint END 

CREATE EXTENSION file_fdw;
CREATE SERVER import FOREIGN DATA WRAPPER file_fdw;
CREATE FOREIGN TABLE dpvd24.f01_ibge_cnefe2022_get(
 COD_UNICO_ENDERECO text,
 COD_UF text,
 COD_MUNICIPIO text,
 COD_DISTRITO text,
 COD_SUBDISTRITO text,
 COD_SETOR text,
 NUM_QUADRA text,
 NUM_FACE text,
 CEP text,
 DSC_LOCALIDADE text,
 NOM_TIPO_SEGLOGR text,
 NOM_TITULO_SEGLOGR text,
 NOM_SEGLOGR text,
 NUM_ENDERECO text,
 DSC_MODIFICADOR text,
 NOM_COMP_ELEM1 text,
 VAL_COMP_ELEM1 text,
 NOM_COMP_ELEM2 text,
 VAL_COMP_ELEM2 text,
 NOM_COMP_ELEM3 text,
 VAL_COMP_ELEM3 text,
 NOM_COMP_ELEM4 text,
 VAL_COMP_ELEM4 text,
 NOM_COMP_ELEM5 text,
 VAL_COMP_ELEM5 text,
 LATITUDE real,
 LONGITUDE real,
 NV_GEO_COORD text, -- nivel de confiança na coordenada
 COD_ESPECIE text,
 DSC_ESTABELECIMENTO text,
 COD_INDICADOR_ESTAB_ENDERECO text,
 COD_INDICADOR_CONST_ENDERECO text,
 COD_INDICADOR_FINALIDADE_CONST text,
 COD_TIPO_ESPECI text
) SERVER import OPTIONS ( filename '/tmp/test.csv', format 'csv', header 'true', delimiter ';' )
;

CREATE PROCEDURE dpvd24.ins_on_t01_ibge_cnefe2022_point(p_filename text)
LANGUAGE SQL AS $p$
 SELECT dynamic_execute(
   format('ALTER FOREIGN TABLE dpvd24.f01_ibge_cnefe2022_get OPTIONS (SET filename %L)', $1 )
 );
 INSERT INTO dpvd24.t01_ibge_cnefe2022_point
  SELECT COD_UNICO_ENDERECO::bigint,
         MAX( COD_MUNICIPIO::int ), -- or FIRST as https://dba.stackexchange.com/q/63661/90651
         MAX( CASE WHEN substring(COD_MUNICIPIO,1,2)='35' THEN '35' ELSE substring(COD_MUNICIPIO,1,1) END::smallint ),
         MAX( ST_Point(LONGITUDE::float,LATITUDE::float,4326) )
  FROM dpvd24.f01_ibge_cnefe2022_get
  GROUP BY 1
 ON CONFLICT DO NOTHING
 ;
$p$;

-------

CREATE VIEW dpvd24.table_disk_usage AS
SELECT
  relname,
  pg_size_pretty(table_size) AS size,
  table_size as size_bytes
FROM (
       SELECT
         pg_catalog.pg_namespace.nspname           AS schema_name,
         relname,
         pg_relation_size(pg_catalog.pg_class.oid) AS table_size
       FROM pg_catalog.pg_class
         JOIN pg_catalog.pg_namespace ON relnamespace = pg_catalog.pg_namespace.oid
     ) t
WHERE schema_name='dpvd24'
ORDER BY table_size DESC;
-- SELECT * FROM dpvd24.table_disk_usage;

