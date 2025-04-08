/* * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 Projeto DATAPREV-desafios2024, TEMPLATE DE BENCHMARK.
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

 DO $benchmark$
 DECLARE
  n_rows bigint;
  tstart TIMESTAMP;
  tend TIMESTAMP;
  total_s float;
  rows_per_sec float;
 BEGIN
 -----------------------------------------------------------

 p_user := '!AQUI github_user_FULANO!';

 p_desafio_id := !AQUI O ID DO DESAFIO CONFORME README!;
 p_framework_rotulo := '!AQUI O RÓTULO DO DESAFIO CONFORME README!';
-----------------------------------------------------------

!AQUI O SQL SCRIPT DO DESAFIO/FRAMWORK!

 -----------------------------------------------------------
 get diagnostics n_rows := row_count;
 tend := clock_timestamp();
 total_s := extract(epoch from tend) - extract(epoch from tstart);
 rows_per_sec :=  round( n_rows::float/total_s::float );

 INSERT INTO dpvd24.performance_hist
   VALUES (p_desafio_id, p_framework_rotulo, p_user, n_rows, total_s, rows_per_sec, now())
 ;
 RAISE NOTICE
   '======= % rows of %/% % in % seconds;  rows_per_sec=%  =======',
   n_rows, p_desafio_id, p_framework_rotulo, total_s, rows_per_sec
 ;
 END;
 $benchmark$ language PLpgSQL;
