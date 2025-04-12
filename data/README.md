
## Dados de testemunhos
A tabela CSV [`benckmark_info.csv`](benckmark_info.csv) tem cada linha acrescentada por um usuário Github que rodou e testemunhou a performance de um ou mais desafios.

## Benchmarks
Para o preparo do ambinte de teste e dos scripts, ver [README principal](../README.md).

Cada vez que rodamos um "script de desafio" conforme o [template geral](../src/step04-desafioX.tpl.sql), ele grava na tabela xxx e apresenta uma mensagem com "NOTICE" com os mesmos dados.
Por exemplo [desafio01p1](../src/step04-desafio01p1-GISpoints.sql) resulta em algo como:

```NOTICE:  table "br_scientific" does not exist, skipping
NOTICE:  ======= 9000 linhas do desafio 1 (SIG convencional) em 0.668204 segundos; rows_per_sec=13468.9  =======
```
Esses valores permitem avaliar o tempo de resolução do desafio no framework indicado, em diferentes CPUs.

Pelo comando `lscpu | grep "CPU(s):\|Model name"` são fornecidas as informações das colunas `CPUs` e `CPU_model_name`. O resultado será algo como 
"CPU(s): 8"; "Model name: Intel(R) Core(TM) i7-6700 CPU @ 3.40GHz". Essas informações também precisam constar na tabela [`benckmark_info.csv`](benckmark_info.csv), colunas `CPUs` e `CPU_model_name` respectivamente.


