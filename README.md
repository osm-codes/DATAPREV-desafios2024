# DATAPREV-desafios2024

Exemplos de desafios de Geoprocessamento realizados sobre dados públicos de 2024 pela DATAPREV.
Esses desafios servem de *benchmark* para comparação de SIG convencional (vetorial), como PostGIS,
e SIG do tipo [DGGS](https://www.iso.org/standard/32588.html) ou similar ([**DNGS**](https://inde.gov.br/simposio-16-anos/docs/AnaiSBIDE4_v5_241017_093910J.pdf)), baseado em grades hierárquicas igual-área e identificadores de célula.


## Dados de entrada
As diversas operações do Desafio2024 fazem uso de dois grandes conjuntos de dados, válidos como exemplo *Big Data*.

### CNEFE

O Censo de 2022, segundo [blog do próprio IBGE](https://agenciadenoticias.ibge.gov.br/agencia-noticias/2012-agencia-de-noticias/noticias/40393-noticia-cnefe), "tem 106,8 milhões de endereços". No presente projeto estamos interessados no que o IBGE denominou *endereços únicos*, que são endereços horizontais de porta de casa, **sem complemento**. 

Os *datasets* "por UF" são arquivos CSV zipados, oferecidos em  https://www.ibge.gov.br/estatisticas/downloads-estatisticas.html  no caminho "Censo_Demografico_2022/Arquivos_CNEFE". Os pontos LatLong foram expressos em WGS84 (SRID 4326). A AddressForAll reuniu todos num só zip:<br>&nbsp; `IBGE_Enderecos.zip`	com 3922081398 bytes (\~3.65 GiB) e <br>&nbsp; SHA256=`daff5251f48d295d27621d0bfbd6c9b3a78a8827e31fd0bd7acb4bc7ad079d27`.<br>O *download* é pelo próprio *hash* ou seu prefixo:  https://dl.digital-guard.org/daff5251f  (cuidado só clicar se for mesmo baixar).

Esta [página dá acesso ao Excel de descrição, "Dicionário"](https://www.ibge.gov.br/estatisticas/sociais/populacao/38734-cadastro-nacional-de-enderecos-para-fins-estatisticos.html?edicao=40122&t=resultados).  Na seção de Instalação abaixo indicamos a melhor forma de trazer os dados para o PostgreSQL, através de ETL ao invés de cópia direta (dos \~17 GiB de CSV expandidos), armazendo apenas o essencial, ponto, seu ID e o ID do seu municicípio. O custo final é de \~2500 bytes/linha (\~1800 dados e \~690 indexação PK), de modo que, multiplicando por \~107 milhões, temos `107000000.0*2500.0/1024^3 = 250 GiB`. A tabela `dpvd24.f01_ibge_cnefe2022_get` , portanto, foi particionada em SP e grandes regiões.

### Mancha
...

--------------

## Desafios
...

--------------

## Instalação

A tabela `dpvd24.f01_ibge_cnefe2022_get` definida em [`src/step01-ini.sql`](src/step01-ini.sql) faz a leitura do CSV, mas precisa do *path* local dos arquivos CSV do `IBGE_Enderecos.zip`. O usuário também precisa de privilégio para a execussão de stored procedures. Recomenda-se também criar uma base exclusíva para o presente projeto, por exemplo base `dbtest`.

Depois disso basta seguir o passo-a-passo, supondo ambiente Linux:

1. `cd DATAPREV-desafios2024/src`
2. `psql postgres://postgres@localhost/dbtest < step01-ini.sql`  (rápido)
3. `psql postgres://postgres@localhost/dbtest < step02-ingest.sql` (demorado)

