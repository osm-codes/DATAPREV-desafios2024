/* * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 Projeto DATAPREV-desafios2024, passo 4, Operação em SIG.
  Obtêm os pontos de interseção da maneira convencional.
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

 DO $benchmark$
 DECLARE
  p_desafio_id        bigint;
  p_user              text;
  p_framework_rotulo  text;
  n_rows bigint;
  tstart TIMESTAMP;
  tend TIMESTAMP;
  total_s float;
  rows_per_sec float;
 BEGIN
 -----------------------------------------------------------

 p_user := 'github_user_FULANO';

 p_desafio_id := 1;
 p_framework_rotulo := 'SIG convencional';
-----------------------------------------------------------
  -- Início da medição de tempo
  tstart := clock_timestamp();

 CREATE TABLE dpvd24.t04res_point_bysig AS
  SELECT c.cod_unico_endereco, m.gid, m.i
  FROM dpvd24.t01_ibge_cnefe2022_point c
  INNER JOIN dataprev.t02dump_mancha_inund m
     ON c.geom && m.geom AND ST_Intersects(c.geom,m.geom)
 ; -- são esperados ~550 mil pontos.

 -----------------------------------------------------------
 get diagnostics n_rows := row_count;
 tend := clock_timestamp();
 total_s := extract(epoch from tend) - extract(epoch from tstart);
 rows_per_sec :=  round( n_rows::float/total_s::float );

 INSERT INTO dpvd24.performance_hist
   VALUES (p_desafio_id, p_framework_rotulo, p_user, n_rows, total_s, rows_per_sec, now())
 ;
 RAISE NOTICE
   '======= % rows of %/% in % seconds;  rows_per_sec=%  =======',
   n_rows, p_desafio_id, p_framework_rotulo, total_s, rows_per_sec
 ;
 END;
 $benchmark$ language PLpgSQL;
