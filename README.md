# DATAPREV-desafios2024

Exemplos de desafios de Geoprocessamento realizados sobre dados públicos de 2024 pela DATAPREV.
Esses desafios servem de *benchmark* para comparação de SIG **convencional** (senso [ISO&nbsp;19125-2](https://en.wikipedia.org/wiki/Simple_Features)) com SIG baseado em **sistema de grades** &mdash; padrão [DGGS](https://www.iso.org/standard/32588.html) (ISO&nbsp;19170-1) ou similar ([**DNGS**](https://inde.gov.br/simposio-16-anos/docs/AnaiSBIDE4_v5_241017_093910J.pdf)), baseado em grades hierárquicas [igual-área](https://en.wikipedia.org/wiki/Equal-area_projection) e respectivos identificadores de célula indexáveis.

Ambos tipos de SIG podem ser implementados como "*framework* SQL", em ambiente PostgreSQL/[PostGIS](https://en.wikipedia.org/wiki/PostGIS), adotado pelo presente projeto.

## Arquivos, tabelas e _views_
Os dados que alimentam o projeto chegam na forma de arquivos comprimidos. Para garantir sua integridade adotou-se *checksum* [SHA256](https://en.wikipedia.org/wiki/SHA-2).

Como projeto orientado a SQL, foi adotado um SCHEMA como *namespace* (`dpv24`), e podendo ser "dropado em cascata" e reconstruído a partir dos scripts deste *git*.
Para as tabels adotou-se a seguinte convenção de nomes: prefixo par para tabelas brutas "as is", `t00raw_`, `t02raw_`, `t04raw_` etc. e prefixo impar para demais dados, `t01x_`, `t03y_`, `t05z_` etc. VIEWs com prefixo `v` seguindo de numeração impar quando dependente de uma só tabela (que aparece como sufixo), e numeração par nos demais casos. 

## Dados de entrada
As diversas operações do Desafio2024 fazem uso de três grandes conjuntos de dados, todos com características de *Big Data*.
Algumas das tabelas entrada são *"as is"*, com projeção original. Em seguida, como fontes no geoprocessaento de origem e no *SIG convencional*, são expressas em **WGS84** (SRID 4326).

### CNEFE
&nbsp; _Dados brutos_ na tabela `dpvd24.t01filt_ibge_cnefe2022_point` (7.6 Gib data + 5.4 Gib index). <!--3922081398 bytes zip-->
<br/> &nbsp; _Fonte_: [www.ibge.gov.br/estatisticas/downloads](https://www.ibge.gov.br/estatisticas/downloads-estatisticas.html) no menu "Censo_Demografico_2022/Arquivos_CNEFE". CSVs expandidos totalizam \~17 GiB.
<br/> &nbsp; _Fonte única_:  `dl.digital-guard.org`   (zip com \~3.65 GiB). 
<br/> &nbsp;  &nbsp; _SHA256_: [`daff5251f48d295d27621d0bfbd6c9b3a78a8827e31fd0bd7acb4bc7ad079d27`](https://dl.digital-guard.org/daff5251f48d)

Na fonte os *datasets* "por UF" são arquivos CSV zipados. A AddressForAll (através da [Digital Guard](https://git.digital-guard.org)) reuniu todos como fonte única, num só&nbsp;zip. O Censo de 2022, segundo [blog do próprio IBGE](https://agenciadenoticias.ibge.gov.br/agencia-noticias/2012-agencia-de-noticias/noticias/40393-noticia-cnefe), "tem 106,8 milhões de endereços". No presente projeto estamos interessados no que o IBGE denominou *endereços únicos*, que representam 96% desse total, mas geograficamente podem ser pontos duplicados. <!-- que são endereços horizontais de porta de casa, **sem complemento**.-->

Esta [página IBGE dá acesso ao Excel de descrição, "Dicionário"](https://www.ibge.gov.br/estatisticas/sociais/populacao/38734-cadastro-nacional-de-enderecos-para-fins-estatisticos.html?edicao=40122&t=resultados), e descreve a coluna `COD_UNICO_ENDERECO` como chave primária. <!-- Dá a entender que são endereços de imóveis, ou seja,  duplicando pontos de "endereço horizontal" no caso de edifícios demais tipos de imóvel distinguíveis apenas pelo complemento do endereço.-->

Na [seção abaixo](#instalação) de instalação indicamos, depois do "passo 3", a melhor forma de trazer os dados para o PostgreSQL, através de ETL ao invés de cópia direta dos CSVs, armazenando apenas o essencial: seu ponto, seu ID e o ID do seu município. O custo final é da ordem de `10 GiB`, de modo que a tabela foi particionada em 3 grandes regiões (exemplificando um procedimento típico de Big Data).

Para conferir o número de linhas do zip expandido é o mesmo que nos arquivos originais, usar `wc -l *.csv | awk '{a=a+ $1-1;} END {print a;}'` que resulta em 222205776 (222 milhões). Os CSVs e o zip podem ser todos apagados depois da instalação.

### Mancha
&nbsp; _Dados brutos_ na tabela `dpvd24.t02raw_mancha_inund` (61 MB).
<br/> &nbsp; _Fonte_:  https://mup.rs.gov.br/   (`ADA_SPGG_03092024.zip` com 48.5 MB). 
<br/> &nbsp; _SHA256_: [`0e4ce549a2572bd736ab7e441fb3054107c1793b58cea0603d163d2d7bcfa691`](https://dl.digital-guard.org/0e4ce549a257)

As [enchentes no Rio Grande do Sul em 2024](https://pt.wikipedia.org/wiki/Enchentes_no_Rio_Grande_do_Sul_em_2024) ficaram caracterizadas por seu "mapa de mancha de inundação", contendo as áreas geográficas atingidas.

Os dados foram disponibilizados na infraestrutura do Mapa Único do Plano Rio Grande (**MUP RS**), em https://mup.rs.gov.br/ (é uma aplicação MS-PowerBI com ícone "i" para navegar nos dados). Os dados MKL foram convertidos para *shapefile*. Exemplo de processo em ambiente Linux, dentro do "passo 4" descrito na [seção abaixo](#instalação) de instalação:

```sh
ogr2ogr -f "ESRI Shapefile" /tmp/mancha_inund/ADA_SPGG_03092024.kml
shp2pgsql -I -s 4674 /tmp/mancha_inund/ada_03092024.shp dpvd24.t02raw_mancha_inund | psql postgres://postgres@localhost/dbtest
```
Após a carga do *shapefile* teremos o seguinte perfil:
```sql
SELECT gid, tipo_ada, round(st_area(geom,true)/1000^2) km2, st_geometrytype(geom) as geomtype, ST_NumGeometries(geom) as n_geoms
FROM dpvd24.t02raw_mancha_inund;
```
```
 gid |   tipo_ada    |  km2  |    geomtype     | n_geoms
-----+---------------+-------+-----------------+---------
   1 | Autodeclarada |  1076 | ST_MultiPolygon |    7191
   2 | SPGG          | 15210 | ST_MultiPolygon |   21814
```
São dois grandes multi-polígonos compostos, cada um por milhares de polígonos. Para que o PostGIS processe com mais eficiência a verificação dos pontos contidos no multipolígono, é recomendado que se exploda a geometria nos seus diversos polígonos, elimimando se necessário os insignificantes, com menos de 2 m². No _script_ [`src/step01-ini.sql`](src/step01-ini.sql) foram implementadas as funções de tratamento e a tabela que recebe o material tratado.

### SICAR
&nbsp; _Dados brutos_ na tabela `dpvd24.t04raw_imoveis_rs` (370 Mib).
<br/> &nbsp; _Fonte_: https://consultapublica.car.gov.br/publico/estados/downloads  (`AREA_IMOVEL.zip` com 216 MB).
<br/> &nbsp; _SHA256_: [`ea1f5678e59f6117b0bae07f6287544ed61299434a040e72de67ef8ca489fe7f`](https://dl.digital-guard.org/ea1f5678e59f)

O Sistema de Cadastro Ambiental Rural (SICAR) contém polígonos representando lotes de propriedade da terra. São  mantidos pelo https://www.car.gov.br  e com *downloads* disponíveis em https://consultapublica.car.gov.br

Por ser um conjunto de dados mais pesado, restringimos o universo ao Estado do Rio Grande do Sul, RS. Para download de polígonos de uma UF específica, selecionar o nome da UF nos downloads, e realizar download de "Perímetro dos Imóveis".

Foi definido em [SRID&nbsp;4674](https://epsg.io/4674), que pode ser considerado equivalente ao WGS84. A trasformação foi feita no tratamento de simplificação dos polígonos, disponível na tabela `dpvd24.t03dump_mancha_inund`.

--------------

## Desafios

São "desafios computacionais" de SIG, correspondendo a operações típicas de Geoprocessamento.  Foram escolhidas operações corriqueiras que, devido ao volume de dados, se tornam operações demoradas para um SIG tradicional. Num computador pessoal, mesmo com dados bem preparados, não instantâneas, podem levar algumas horas para serem efetuadas.

O [*benchmark* de *software*](https://en.wikipedia.org/wiki/Benchmark_(computing)) requer ambiente controlado, sem outras aplicações rodando simultaneamente. Convenções:
* computador com *hardware* popular (ex. Notebook com disco SSD e CPU Intel Core i7),
* sistema operacional Linux (Ubunto LTS 20),
* [PostgreSQL v16](https://en.wikipedia.org/wiki/PostgreSQL#Release_history), [`psql` v17](https://github.com/postgres/postgres/tree/master/src/bin/psql), [PostGIS v3.5](https://en.wikipedia.org/wiki/PostGIS#History).

Os desafios são executados por uma testemunha (usuário Github) em seu ambiente, e resultados registrados no [arquivo `benckmark_info.csv`](data/benckmark_info.csv) pela testemunha. A instalação e execussão dos *benchmarks* é realizada em `psql`. A mesma temporização pode ser obtida de diversas formas: pelo comando psql `\timing` ;  incluindo cláusula [`EXPLAIN ANALYSE`](https://www.postgresql.org/docs/current/sql-explain.html) (*Execution Time*); ou usando `clock_timestamp`. Optamos pela última para poder inserir valores na tabela de controle  `dpvd24.performance_hist`, que alimenta no formato correto o `benckmark_info.csv`.

### Desafio 1 - Pontos dentro da Mancha
<!-- Endereços na Mancha de Inundação de RS -->
Encontrar os pontos de endereço CNEFE que estão dentro da Mancha de Inundação do RS. Scripts [`step04-desafio01p1-GISpoints.sql`](src/step04-desafio01p1-GISpoints.sql) e do fornecedor DNGS, `desafio01p2`.

A operação de verificação de quais pontos estão dentro da Mancha é simples em SIG convencional, mas devido ao volume de dados, mesmo com dados bem preparados, pode levar algumas horas num computador pessoal. A hipótese é que o tempo de verificação em _framework_ DNGS seja dezenas ou centenas de vezes menor.  

### Desafio 2 - Lotes com maior parte sob a Mancha
Lotes do SICAR com 60% ou mais de sua área sob a Mancha de Inundação. Scripts [`step04-desafio02p1-GISpoints.sql`](src/step04-desafio01p1-GISpoints.sql) e do fornecedor DNGS, `desafio02p2`.

### Desafio 3 - Lotes com sobreposição relevante entre si
A sobreposição de lotes pode ser insignificante se for apenas um ponto ou pequena porção sobreposta. Isso é esperado devido à imprecisão das medições e ausência de padronização metodológica na coleta dos dados. Podemos imaginar, por outro lado, a situação onde a sobreposição se torna relevante, para por exemplo eliminar da base de dados.

Para fins de _benchmark_ foram considerados: lotes SICAR com 40% ou mais de sua área sobreposta a outro lote.  Scripts [`step04-desafio03p1-GISpoints.sql`](src/step04-desafio01p1-GISpoints.sql) e do fornecedor DNGS, `desafio03p2`.

### Desafio 4 - Determinação do município do ponto
<!-- Associar pontos aos respectivos municípios, conhecendo apenas as suas geometrias -->
Desafio análogo ao 1, porém usando polígonos que formam uma cobertura completa (sem lacunas ou sobreposições) sobre o território nacional. No caso do SIG convencional a performance esperada é a mesma. Na da representação em grade surge a necessidade de uma operação a mais no preparo. conhecida como [*snap rounding*](https://en.wikipedia.org/wiki/Snap_rounding) poligonal.

O _benchmark_ aqui é mais delicado: buscamos avaliar convergência em função da resolução. A técnica de *snap rounding*, para que seja a mesma para qualquer que seja o *_framework_ de grade, será usando o SIG convencional: depois de obtidas coberturas municipais com certa resolução, as lacunas dentre municípios são preenchidas pelo município com maior área sob a lacuna.

Outra diferença para o Desafio 1 é que todos os pontos serão selecionados, e podem ser um a uma validados, e essa validação também faz parte do _benchmark_.

--------------

## Instalação

A tabela `dpvd24.f01_ibge_cnefe2022_get` definida em [`src/step01-ini.sql`](src/step01-ini.sql) faz a leitura do CSV, mas precisa do *path* local dos arquivos CSV do `IBGE_Enderecos.zip` descritos acima>

Depois disso basta seguir o passo-a-passo, supondo ambiente Linux:

1. `cd DATAPREV-desafios2024/src`
2. `psql postgres://postgres@localhost/dbtest < step01-ini.sql`  (rápido)
3. Preparar dados brutos CSV do CNEFE, como descrito na [seção acima](#CNEFE).
5. Preparar e fazer carga do *shapefile* da mancha de inundação, em `dpvd24.mancha_inund`.
6. `psql postgres://postgres@localhost/dbtest < step02-ingest.sql &>> log_step02.txt &` (demorado)
7. (opcional) se log_step02 sem erros, apagar dados do CNEFE.
8. Rodar o benchmark desejado e gravar resultado no CSV, usando `COPY dpvd24.performance_hist TO '/tmp/dpvd24_performance_hist.csv' CSV HEAD` para obter dados corretos.

Rodando os **desafios com SIG convencional**:

* Rodar _script_ deste _git_, por exemplo Desafio-01<br/>`psql postgres://postgres@localhost/dbtest < step04-desafio01p1-GISpoints.sql &>> log_step04.txt &`

Rodando os **desafios com DGGS ou DNGS**: ver git passo-a-passo dos fornecedores, e resultados no CSV.


Alternativamente ao `psql` pode-se usar [`raster2dggs`](https://github.com/manaakiwhenua/raster2dggs) para _frameworks_ H3 Uber e rHEALPix.

## Fornecedores testados

Fornecedores de *framework-DGGS* (ex. [S2 Geometry](http://s2geometry.io/)) ou *framework-DNGS* (ex. AFA Codes) devem incluir os respectivos benchmarks sob seguinte rotulação em [`benckmark_info.csv`](data/benckmark_info.csv):

## Licença

Este repositório GIT, com todos os seus dados e _scripts_, é distribuído sob [**licença CC0**](https://creativecommons.org/publicdomain/zero/1.0/deed.en).
