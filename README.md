# DATAPREV-desafios2024

Exemplos de desafios de Geoprocessamento realizados sobre dados públicos de 2024 pela DATAPREV.
Esses desafios servem de *benchmark* para comparação de SIG **convencional** (senso [ISO&nbsp;19125-2](https://en.wikipedia.org/wiki/Simple_Features)) com SIG do tipo [DGGS](https://www.iso.org/standard/32588.html) (ISO&nbsp;19170-1) ou similar ([**DNGS**](https://inde.gov.br/simposio-16-anos/docs/AnaiSBIDE4_v5_241017_093910J.pdf)), baseado em grades hierárquicas [igual-área](https://en.wikipedia.org/wiki/Equal-area_projection) e respectivos identificadores de célula indexáveis.

Ambos tipos de SIG podem ser implementados como "*framework* SQL", em ambiente PostgreSQL/[PostGIS](https://en.wikipedia.org/wiki/PostGIS), adotado pelo presente projeto.

## Dados de entrada
As diversas operações do Desafio2024 fazem uso de três grandes conjuntos de dados, válidos como **exemplo *Big Data***.

### CNEFE

O Censo de 2022, segundo [blog do próprio IBGE](https://agenciadenoticias.ibge.gov.br/agencia-noticias/2012-agencia-de-noticias/noticias/40393-noticia-cnefe), "tem 106,8 milhões de endereços". No presente projeto estamos interessados no que o IBGE denominou *endereços únicos*, que são endereços horizontais de porta de casa, **sem complemento**.

Os *datasets* "por UF" são arquivos CSV zipados, oferecidos em  https://www.ibge.gov.br/estatisticas/downloads-estatisticas.html  no caminho "Censo_Demografico_2022/Arquivos_CNEFE". Os pontos LatLong foram expressos em WGS84 (SRID 4326). A AddressForAll reuniu todos num só zip:<br>&nbsp; `IBGE_Enderecos.zip`	com 3922081398 bytes (\~3.65 GiB) e <br>&nbsp; SHA256=`daff5251f48d295d27621d0bfbd6c9b3a78a8827e31fd0bd7acb4bc7ad079d27`.<br>O *download* é pelo próprio *hash* ou seu prefixo:  https://dl.digital-guard.org/daff5251f  (cuidado só clicar se for mesmo baixar)(Passo 3).

Esta [página IBGE dá acesso ao Excel de descrição, "Dicionário"](https://www.ibge.gov.br/estatisticas/sociais/populacao/38734-cadastro-nacional-de-enderecos-para-fins-estatisticos.html?edicao=40122&t=resultados), e conforma a coluna `COD_UNICO_ENDERECO` como chave primária. Dá a entender que são endereços de imóveis, ou seja,  duplicando pontos de "endereço horizontal" no caso de edifícios e demais tipos de imóveis distinguíveis apenas pelo complemento do endereço.

Na [seção abaixo](#instalação) de instalação indicamos, depois do "passo 3", a melhor forma de trazer os dados para o PostgreSQL, através de ETL ao invés de cópia direta (dos \~17 GiB de CSV expandidos), armazenando apenas o essencial, ponto, seu ID e o ID do seu município. O custo final é de \~2500 bytes/linha (\~1800 dados e \~690 indexação PK), de modo que, multiplicando por \~107 milhões, temos `107000000.0*2500.0/1024^3 = 250 GiB`. A tabela `dpvd24.f01_ibge_cnefe2022_get` , portanto, foi particionada em grandes regiões.

Para conferir o número de linhas do zip expandido é o mesmo que nos arquivos originais, usar `wc -l *.csv | awk '{a=a+ $1-1;} END {print a;}'` que resulta em 222205776 (222 milhões). Os CSVs e o zip podem ser todos apagados depois da instalação.

### Mancha

Os dados foram disponibilizados na infraestrutura do Mapa Único do Plano Rio Grande (**MUP RS**), em https://mup.rs.gov.br/ (é uma aplicação MS-PowerBI com ícone "i" para navegar nos dados). Os dados MKL foram convertidos para *shapefile*. Exemplo de processo em ambiente Linux, dentro do "passo 6" descrito na [seção abaixo](#instalação) de instalação:

```sh
ogr2ogr -f "ESRI Shapefile" /tmp/mancha_inund/ADA_SPGG_03092024.kml
shp2pgsql -I -s 4674 /tmp/mancha_inund/ada_03092024.shp dpvd24.t02_mancha_inund | psql postgres://postgres@localhost/dbtest
```
Após a carga do *shapefile* teremos o seguinte perfil:
```sql
SELECT gid, tipo_ada, round(st_area(geom,true)/1000^2) km2, st_geometrytype(geom) as geomtype, ST_NumGeometries(geom) as n_geoms
FROM dpvd24.t02_mancha_inund;
```
```
 gid |   tipo_ada    |  km2  |    geomtype     | n_geoms
-----+---------------+-------+-----------------+---------
   1 | Autodeclarada |  1076 | ST_MultiPolygon |    7191
   2 | SPGG          | 15210 | ST_MultiPolygon |   21814
```
São dois grandes multi-polígonos compostos, cada um por milhares de polígonos. Para que o PostGIS processe com mais eficiência a verificação dos pontos contidos no multipolígono, é recomendado que se exploda a geometria nos seus diversos polígonos, elimimando se necessário os insignificantes, com menos de 2 m². No _script_ [`src/step01-ini.sql`](src/step01-ini.sql) foram implementadas as funções de tratamento e a tabela que recebe o material tratado.

### SICAR

O Sistema de Cadastro Ambiental Rural (SICAR) contém polígonos representando lotes de propriedade da terra. São  mantidos pelo https://www.car.gov.br  e com *downloads* disponíveis em https://consultapublica.car.gov.br

Por ser um conjunto de dados mais pesado, restringimos o universo ao Estado do Rio Grande do Sul, RS.

--------------

## Desafios
São "desafios computacionais" de SIG, correspondendo a operações típicas de Geoprocessamento.  Foram escolhidas operações corriqueiras que, devido ao volume de dados, se tornam operações demoradas para um SIG tradicional. Num computador pessoal, mesmo com dados bem preparados, não instantâneas, podem levar algumas horas para serem efetuadas.

O [*benchmark* de *software*](https://en.wikipedia.org/wiki/Benchmark_(computing)) requer ambiente controlado, sem outras aplicações rodando simultaneamente. Convenções:
* computador com *hardware* popular (ex. Notebook com disco SSD e CPU Intel Core i7),
* sistema operacional Linux (Ubuntu LTS 20),
* [PostgreSQL v16](https://en.wikipedia.org/wiki/PostgreSQL#Release_history), [`psql` v17](https://github.com/postgres/postgres/tree/master/src/bin/psql), [PostGIS v3.5](https://en.wikipedia.org/wiki/PostGIS#History).

Os desafios são executados por uma testemunha (usuário Github) em seu ambiente, e resultados registrados no [arquivo `benckmark_info.csv`](data/benckmark_info.csv) pela testemunha. A instalação e execussão dos *benchmarks* é realizada em `psql`. A mesma temporização pode ser obtida de diversas formas: pelo comando psql `\timing` ;  incluindo cláusula [`EXPLAIN ANALYSE`](https://www.postgresql.org/docs/current/sql-explain.html) (*Execution Time*); ou usando `clock_timestamp`. Optamos pela última para poder inserir valores na tabela de controle  `dpvd24.performance_hist`, que alimenta no formato correto o `benckmark_info.csv`.

### Desafio 1 - Pontos dentro da Mancha
A operação de verificação de quais pontos do CNEFE estão dentro da Mancha de Inundação é bastante simples e corriqueira em SIG, mas devido ao volume de dados, num computador pessoal, mesmo com dados bem preparados, pode levar algumas horas (ex. Notebook com processador Intel i7).

### Desafio 2 - ...
A revisar com comunidade.

--------------

## Instalação

A tabela `dpvd24.f01_ibge_cnefe2022_get` definida em [`src/step01-ini.sql`](src/step01-ini.sql) faz a leitura do CSV, mas precisa do *path* local dos arquivos CSV do `IBGE_Enderecos.zip` descritos acima. O usuário também precisa de privilégio para a execussão de stored procedures. Recomenda-se também criar uma base exclusíva para o presente projeto, por exemplo base `dbtest`.

Depois disso basta seguir o passo-a-passo, supondo ambiente Linux:

1. `cd DATAPREV-desafios2024/src`
2. `psql postgres://postgres@localhost/dbtest < step01-ini.sql`  (rápido)
3. Preparar dados brutos CSV do CNEFE, como descrito no tópico "CNEFE" acima.
4. Preparar e fazer carga do *shapefile* da mancha de inundação, em `dpvd24.mancha_inund`.
5. `psql postgres://postgres@localhost/dbtest < step02-ingest.sql &>> log_step02.txt &` (demorado)
6. (opcional) se log_step02 sem erros, apagar dados do CNEFE.
7. Rodar o benchmark desejado e gravar resultado no CSV, usando `COPY dpvd24.performance_hist TO '/tmp/dpvd24_performance_hist.csv' CSV HEAD` para obter dados corretos.

Rodando os **desafios com SIG convencional**:

* Rodar _script_ deste _git_, por exemplo Desafio-01<br/>`psql postgres://postgres@localhost/dbtest < step04-desafio01p1-GISpoints.sql &>> log_step04.txt &`

Rodando os **desafios com DGGS ou DNGS**: ver git passo-a-passo dos fornecedores, e resultados no CSV.


Alternativamente ao `psql` pode-se usar [`raster2dggs`](https://github.com/manaakiwhenua/raster2dggs) para _frameworks_ H3 Uber e rHEALPix.

## Fornecedores testados

Fornecedores de *framework-DGGS* (ex. [S2 Geometry](http://s2geometry.io/)) ou *framework-DNGS* (ex. AFA Codes) devem incluir os respectivos benchmarks sob seguinte rotulação em [`benckmark_info.csv`](data/benckmark_info.csv):

## Licença

Este repositório GIT, com todos os seus dados e _scripts_, é distribuído sob [**licença CC0**](https://creativecommons.org/publicdomain/zero/1.0/deed.en).
