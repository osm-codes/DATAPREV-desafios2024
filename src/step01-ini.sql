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

CREATE or replace FUNCTION iIF(
    condition boolean,       -- IF condition
    true_result anyelement,  -- THEN
    false_result anyelement  -- ELSE
    -- See https://stackoverflow.com/a/53750984/287948
) RETURNS anyelement AS $f$
  SELECT CASE WHEN condition THEN true_result ELSE false_result END
$f$  LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION iif
  IS 'Immediate IF. Sintax sugar for the most frequent CASE-WHEN. Avoid with text, need explicit cast.'
;

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
 geom geometry(Point, 4326)
);

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
) SERVER import OPTIONS ( filename '/tmp/pg_io/file.csv', format 'csv'); -- header e ";"


INSERT INTO dpvd24.t01_ibge_cnefe2022_point
  SELECT COD_UNICO_ENDERECO,
         MAX( ST_Point(LONGITUDE::float,LATITUDE::float,4326) )
  FROM ibge_cnefe2022_onlyend
  GROUP BY 1
  ORDER BY 1
ON CONFLICT DO NOTHING
;
INSERT INTO tablename (x, y, z)
  SELECT f1(fieldname1), f2(fieldname2), f3(fieldname3) -- the transforms 
  FROM tmp_tablename_fdw
  -- WHERE condictions
;
