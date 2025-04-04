/* * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 Projeto DATAPREV-desafios2024, passo 2, ingestão (ETL).
 Editar com as suas configurações locais!
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

-- -- -- -- -- -- -- -- -- -- --
--- INGEST CNEFE:
DO $do$
DECLARE
 i text;
 ibge_files text DEFAULT '/mnt/dados/IBGE/'; -- please CHANGE HERE to your path!!
BEGIN
   FOREACH i IN ARRAY '{11_RO,12_AC,13_AM,14_RR,15_PA,16_AP,17_TO,21_MA,22_PI,23_CE,24_RN,25_PB,26_PE,27_AL,28_SE,29_BA,31_MG,32_ES,33_RJ,35_SP,41_PR,42_SC,43_RS,50_MS,51_MT,52_GO,53_DF}'::text[] LOOP
      CALL dpvd24.ins_on_t01_ibge_cnefe2022_point(ibge_files|| i ||'.csv');
      COMMIT;
   END LOOP;
END
$do$;

-- -- -- -- -- -- -- -- -- -- --
--- INGEST MANCHA INUNDAÇÃO RS:

