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
   p_user text;
   p_desafio_id int;
   p_framework_rotulo text;
  BEGIN
  -----------------------------------------------------------

  p_user := 'fulano'; -- Github username

  p_desafio_id := 1;  -- número do desafio conforme README
  p_framework_rotulo := 'SIG convencional';  -- rótulo conforme README

  tstart := clock_timestamp();
 -----------------------------------------------------------

 !AQUI O SQL SCRIPT DO DESAFIO/FRAMWORK!

 -----------------------------------------------------------
  get diagnostics n_rows := row_count;
  tend := clock_timestamp();
  total_s := extract(epoch from tend) - extract(epoch from tstart);
  rows_per_sec :=  round( n_rows::float/total_s::float,1 );

  INSERT INTO dpvd24.performance_hist
    VALUES (p_desafio_id, p_framework_rotulo, p_user, n_rows, total_s, rows_per_sec, now())
  ;
  RAISE NOTICE
    '======= % linhas do desafio % (%) em % segundos; rows_per_sec=%  =======',
    n_rows, p_desafio_id, p_framework_rotulo, total_s, rows_per_sec
  ;
  END;
$benchmark$ language PLpgSQL;
