
<!-- README.md is generated from README.Rmd. Please edit that file -->

# wcswatin

<!-- badges: start -->
<!-- badges: end -->

wcswatin (Weather & Climate SWAT input) is an open-source R package
for preparing weather and climate data from different sources for input
in the Soil & Water Assessment Tool ([SWAT](https://swat.tamu.edu/)),
funded by the Critical Ecosystem Partnership Fund
([CEPF](https://www.cepf.net/)). Currently two blocks of processing
routines are implemented, one for the pre-processing of NetCDF and tif
raster files as made available from a increasing number of
data-providing institutions around the globe and a second one for the
upscaling of physical station data by interpolation methods. For
processing all used datasets MUST have geographic coordinates using WGS
84 as datum.

### Conceptual overview of the `wcswatin` package

<img src="man/figures/wcswatin_flowchart150222.png" title="Conceptual overview of the `wcswatin` package" alt="Conceptual overview of the `wcswatin` package" width="100%" />

## Installation

You can install the development version from GitHub with:

``` r
# install.packages("devtools")
devtools::install_github("reginalexavier/wcswatin")
```

``` r
library(wcswatin)
## basic example code
```

# Rotinas para dados NetCDF ou raster(TIF)

As rotinas permitem a extração espacial e temporal de conjuntos de dados
de variáveis climatológicos e meteorológicos de grades globais como
disponibilizados em sites como [Climate Change
Service](https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-land?tab=overview),
[GES
DISC](https://disc.gsfc.nasa.gov/datasets/GPM_3IMERGDF_06/summary?keywords=%22IMERG%20final%22),
[PERSIANN-CCS](https://chrsdata.eng.uci.edu/) entre outros. Esses dados
são disponibilizados em formato de raster(.tif) ou em formato de NetCDF
*(um formato binário muito utilizado para disponibilizar séries
espaço-temporais de dados multiparamétricos)*. Para aumentar a
eficiencia computacional no processamento, os respectivos produtos devem
ser inicialmente baixados e armazenados localmente. As caracteristicas
específicas de cada produto (parametros disponibilizados, resolução
temporal e espacial) são detalhadas nos respectivos portais, mas são
extraídas também pelas rotinas desenvolvidas. Para serem utilizados como
entradas no SWAT, os dados meteorológicos e climatológicos são
transformados em conjuntos de tabelas em formato txt demandados pelo
modelo. Testados para conjuntos de dados de reanalise (ERA5_Land) e as
grades de precipitação PERSIANN e GPM, o pacote `wcswatin`
disponibiliza porém, por meio de funções, rotinas gerais e universais
para extração de grades provenientes de outras instituições.

## Passo a passo:

###### 1. Informar o caminho onde o arquivo se encontra(NetCDF)

``` r
era5land_2017 <- file.path(base_path, "ERA5-Land_data/Y2017.nc")
```

###### 2. Verificar as variaveis presentes no arquivo(NetCDF)

``` r
#verificar as variáveis presentes nos arquivos ncdf baixados

var_names(era5land_2017)
#> [1] "uas"              "vas"              "dpt"              "tas"
#> [5] "rsds_accumulated" "tp"
```

> Este arquivo por exemplo contem 6 variáveis

###### 3. Criar um raster multilayer com o arquivo, escolhendo uma variavel desejada entre as mostradas em `var_name` (NetCDF + TIF)

``` r
# NetCDF: carregando um arquivo NetCDF e transformar em raster

one_brick <- raster::brick(era5land_2018,
                           varname = "uas")[[1:3]]
one_brick
#> class      : RasterStack
#> dimensions : 38, 39, 1482, 3  (nrow, ncol, ncell, nlayers)
#> resolution : 0.1, 0.1  (x, y)
#> extent     : -57.52, -53.62, -18.02, -14.22  (xmin, xmax, ymin, ymax)
#> crs        : +proj=longlat +datum=WGS84 +no_defs
#> names      : X2018.01.01.00.00.00, X2018.01.01.01.00.00, X2018.01.01.02.00.00
```

> Alguns arquivos NetCDF invertem a sequencia entre latitude com
> longitude, causando erros na transformação para raster. Neste caso
> `wcswatin` tem a função `ncdf2raster()` que faz essa transformação.

# TIF

> Os mesmos passos são válidos para dados de entrada como raster(.tif),
> uma vez que a partir deste passo estão sendo manipulados rasters vindo
> da transformação dos NetCDF. Os rasters podem ser importados e
> juntados para arquivos multilayer por meio das funções
> (`raster::brick` ou `raster::stack`).

###### 3.1 Caso forem varios arquivos, pode se criar uma lista raster multilayer (NetCDF)

``` r
# para carregar vários arquivos de ncdf para uma lista
# quando for vários arquivos ao mesmo tempo
list_brick <- lapply(list(era5land_2017, era5land_2018),
                     raster::brick,
                     varname = "uas") |> lapply(\(x) (x[[1:3]]))
list_brick
#> [[1]]
#> class      : RasterStack
#> dimensions : 38, 39, 1482, 3  (nrow, ncol, ncell, nlayers)
#> resolution : 0.1, 0.1  (x, y)
#> extent     : -57.52, -53.62, -18.02, -14.22  (xmin, xmax, ymin, ymax)
#> crs        : +proj=longlat +datum=WGS84 +no_defs
#> names      : X2017.01.01.00.00.00, X2017.01.01.01.00.00, X2017.01.01.02.00.00
#>
#>
#> [[2]]
#> class      : RasterStack
#> dimensions : 38, 39, 1482, 3  (nrow, ncol, ncell, nlayers)
#> resolution : 0.1, 0.1  (x, y)
#> extent     : -57.52, -53.62, -18.02, -14.22  (xmin, xmax, ymin, ymax)
#> crs        : +proj=longlat +datum=WGS84 +no_defs
#> names      : X2018.01.01.00.00.00, X2018.01.01.01.00.00, X2018.01.01.02.00.00
```

###### 4. Criar um arquivo contendo as coordenadas centrais dos pixels da grade dentro de uma área de estudo (necessita de um arquivo SHAPE poligonal) e sua elevação corespondente a partir de um MNT (.tif).

``` r
study_area <- study_area_records(raster = one_brick[[1]], # raster de exemplo, dos mesmos que serão extraídos os dados
                                 watershed = bassin_path, # shapefile poligonal que delimita a área de estudo
                                 DEM = dem_path) # raster do MNT para extrair a elevação de dado ponto central da grade
```

Resultado:

``` r
knitr::kable(study_area[1:10, ])
```

|      x |      y |  ID | row | col | Elevation |
|-------:|-------:|----:|----:|----:|----------:|
| -55.37 | -14.27 |  22 |   1 |  22 |  636.4115 |
| -55.27 | -14.27 |  23 |   1 |  23 |  434.6133 |
| -55.17 | -14.27 |  24 |   1 |  24 |  389.8255 |
| -55.07 | -14.27 |  25 |   1 |  25 |  437.3398 |
| -55.67 | -14.37 |  58 |   2 |  19 |  305.0258 |
| -55.57 | -14.37 |  59 |   2 |  20 |  276.4789 |
| -55.47 | -14.37 |  60 |   2 |  21 |  292.9312 |
| -55.37 | -14.37 |  61 |   2 |  22 |  315.1837 |
| -55.27 | -14.37 |  62 |   2 |  23 |  327.0550 |
| -55.17 | -14.37 |  63 |   2 |  24 |  346.9489 |

###### 5. Com a tabela dos pontos da grade da area de estudo, esta função cria a tabela master para cada variavel contida nos arquivos NetCDF, basta informa o nome da variavel. No caso de arquivos TIF de uma variável (principalmente utilizados para grades de precipitação) essa operação precisa ser realizada somente uma única vez.

``` r
mainFile <- mainInput_var(study_area = study_area,
                          var_name = "uas")
```

Resultado:

``` r
knitr::kable(mainFile[1:10, ])
```

|  ID | NAME  |    LAT |   LONG | ELEVATION |
|----:|:------|-------:|-------:|----------:|
|  22 | uas22 | -14.27 | -55.37 |  636.4115 |
|  23 | uas23 | -14.27 | -55.27 |  434.6133 |
|  24 | uas24 | -14.27 | -55.17 |  389.8255 |
|  25 | uas25 | -14.27 | -55.07 |  437.3398 |
|  58 | uas58 | -14.37 | -55.67 |  305.0258 |
|  59 | uas59 | -14.37 | -55.57 |  276.4789 |
|  60 | uas60 | -14.37 | -55.47 |  292.9312 |
|  61 | uas61 | -14.37 | -55.37 |  315.1837 |
|  62 | uas62 | -14.37 | -55.27 |  327.0550 |
|  63 | uas63 | -14.37 | -55.17 |  346.9489 |

> De acordo com as padronizações das entradas climatológicas no SWAT, é
> preciso ciar uma tabela master para cada uma das variaveis (NetCDF de
> múltiplas variaveis).

###### 6. Extrair os dados do parametro climatológico e guardar em uma tabela

Esta função faz a extração dos dados de um raster multilayer e guarda em
uma tabela. A tabela criada contem duas colunas (values) que guardam os
valores extraídos na mesma ordem dos IDs e (layer_name) guardando o nome
de cada layer extraído (geralmente é a data).

``` r
tbls <- raster2vec(rasterbrick = one_brick,
                   study_area = study_area)
```

Resultado:

``` r
knitr::kable(tbls[1:10, ])
```

|     values | layer_name           |
|-----------:|:---------------------|
|  0.0437098 | X2018.01.01.00.00.00 |
| -0.3524084 | X2018.01.01.00.00.00 |
| -0.7492590 | X2018.01.01.00.00.00 |
| -1.1027136 | X2018.01.01.00.00.00 |
|  0.4351892 | X2018.01.01.00.00.00 |
|  0.3896570 | X2018.01.01.00.00.00 |
|  0.2885218 | X2018.01.01.00.00.00 |
|  0.0457850 | X2018.01.01.00.00.00 |
| -0.3877478 | X2018.01.01.00.00.00 |
| -0.8633947 | X2018.01.01.00.00.00 |

A tabela pode ser salva com essas linhas:

``` {r
# este arquivo pode ser salvo como tabelas individuais como:
data.table::fwrite(tbls,
                   "o_caminho/minha_tabela.csv",
                   row.names = TRUE)
```

###### 6.1 Quando varios NetCDFs constituem uma única série temporal é preciso criar um lista de rasters. A função `raster2vec` precisa ser iterada sobre cada um deles. O resultado é uma lista de tabela, cuja cada uma representa um arquivo.

``` r
tbls1 <- lapply(list_brick, raster2vec, study_area)
```

As tabelas podem ser valvas com essas linhas:

``` {r
# este arquivo pode ser salvo como tabelas individuais como:
data.table::fwrite(do.call(rbind, tbls1),
                   "o_caminho/minha_tabela.csv",
                   row.names = TRUE)
```

###### 7. Tendo uma tabela por arquivo, esta funcão transforma essa tabela em uma lista nomeada de séries por pixel. Ele recebe um vetor com os nomes para cada arquivo. Este vetor deve conter o mesmo tamanho que a quantidade pixel com valor. O nome da coluna deve ser a primeira data da série.

``` r
cell_tables <-  layerValues2pixel(layer_values = tbls,
                                  tb_name = mainFile$NAME,
                                  col_name = "20170101")
#>   |                                                                              |                                                                      |   0%  |                                                                              |                                                                      |   1%  |                                                                              |=                                                                     |   1%  |                                                                              |=                                                                     |   2%  |                                                                              |==                                                                    |   2%  |                                                                              |==                                                                    |   3%  |                                                                              |===                                                                   |   4%  |                                                                              |===                                                                   |   5%  |                                                                              |====                                                                  |   5%  |                                                                              |====                                                                  |   6%  |                                                                              |=====                                                                 |   7%  |                                                                              |=====                                                                 |   8%  |                                                                              |======                                                                |   8%  |                                                                              |======                                                                |   9%  |                                                                              |=======                                                               |   9%  |                                                                              |=======                                                               |  10%  |                                                                              |=======                                                               |  11%  |                                                                              |========                                                              |  11%  |                                                                              |========                                                              |  12%  |                                                                              |=========                                                             |  12%  |                                                                              |=========                                                             |  13%  |                                                                              |=========                                                             |  14%  |                                                                              |==========                                                            |  14%  |                                                                              |==========                                                            |  15%  |                                                                              |===========                                                           |  15%  |                                                                              |===========                                                           |  16%  |                                                                              |============                                                          |  16%  |                                                                              |============                                                          |  17%  |                                                                              |============                                                          |  18%  |                                                                              |=============                                                         |  18%  |                                                                              |=============                                                         |  19%  |                                                                              |==============                                                        |  19%  |                                                                              |==============                                                        |  20%  |                                                                              |==============                                                        |  21%  |                                                                              |===============                                                       |  21%  |                                                                              |===============                                                       |  22%  |                                                                              |================                                                      |  22%  |                                                                              |================                                                      |  23%  |                                                                              |================                                                      |  24%  |                                                                              |=================                                                     |  24%  |                                                                              |=================                                                     |  25%  |                                                                              |==================                                                    |  25%  |                                                                              |==================                                                    |  26%  |                                                                              |===================                                                   |  27%  |                                                                              |===================                                                   |  28%  |                                                                              |====================                                                  |  28%  |                                                                              |====================                                                  |  29%  |                                                                              |=====================                                                 |  29%  |                                                                              |=====================                                                 |  30%  |                                                                              |=====================                                                 |  31%  |                                                                              |======================                                                |  31%  |                                                                              |======================                                                |  32%  |                                                                              |=======================                                               |  32%  |                                                                              |=======================                                               |  33%  |                                                                              |========================                                              |  34%  |                                                                              |========================                                              |  35%  |                                                                              |=========================                                             |  35%  |                                                                              |=========================                                             |  36%  |                                                                              |==========================                                            |  37%  |                                                                              |==========================                                            |  38%  |                                                                              |===========================                                           |  38%  |                                                                              |===========================                                           |  39%  |                                                                              |============================                                          |  39%  |                                                                              |============================                                          |  40%  |                                                                              |============================                                          |  41%  |                                                                              |=============================                                         |  41%  |                                                                              |=============================                                         |  42%  |                                                                              |==============================                                        |  42%  |                                                                              |==============================                                        |  43%  |                                                                              |===============================                                       |  44%  |                                                                              |===============================                                       |  45%  |                                                                              |================================                                      |  45%  |                                                                              |================================                                      |  46%  |                                                                              |=================================                                     |  46%  |                                                                              |=================================                                     |  47%  |                                                                              |=================================                                     |  48%  |                                                                              |==================================                                    |  48%  |                                                                              |==================================                                    |  49%  |                                                                              |===================================                                   |  49%  |                                                                              |===================================                                   |  50%  |                                                                              |===================================                                   |  51%  |                                                                              |====================================                                  |  51%  |                                                                              |====================================                                  |  52%  |                                                                              |=====================================                                 |  52%  |                                                                              |=====================================                                 |  53%  |                                                                              |=====================================                                 |  54%  |                                                                              |======================================                                |  54%  |                                                                              |======================================                                |  55%  |                                                                              |=======================================                               |  55%  |                                                                              |=======================================                               |  56%  |                                                                              |========================================                              |  57%  |                                                                              |========================================                              |  58%  |                                                                              |=========================================                             |  58%  |                                                                              |=========================================                             |  59%  |                                                                              |==========================================                            |  59%  |                                                                              |==========================================                            |  60%  |                                                                              |==========================================                            |  61%  |                                                                              |===========================================                           |  61%  |                                                                              |===========================================                           |  62%  |                                                                              |============================================                          |  62%  |                                                                              |============================================                          |  63%  |                                                                              |=============================================                         |  64%  |                                                                              |=============================================                         |  65%  |                                                                              |==============================================                        |  65%  |                                                                              |==============================================                        |  66%  |                                                                              |===============================================                       |  67%  |                                                                              |===============================================                       |  68%  |                                                                              |================================================                      |  68%  |                                                                              |================================================                      |  69%  |                                                                              |=================================================                     |  69%  |                                                                              |=================================================                     |  70%  |                                                                              |=================================================                     |  71%  |                                                                              |==================================================                    |  71%  |                                                                              |==================================================                    |  72%  |                                                                              |===================================================                   |  72%  |                                                                              |===================================================                   |  73%  |                                                                              |====================================================                  |  74%  |                                                                              |====================================================                  |  75%  |                                                                              |=====================================================                 |  75%  |                                                                              |=====================================================                 |  76%  |                                                                              |======================================================                |  76%  |                                                                              |======================================================                |  77%  |                                                                              |======================================================                |  78%  |                                                                              |=======================================================               |  78%  |                                                                              |=======================================================               |  79%  |                                                                              |========================================================              |  79%  |                                                                              |========================================================              |  80%  |                                                                              |========================================================              |  81%  |                                                                              |=========================================================             |  81%  |                                                                              |=========================================================             |  82%  |                                                                              |==========================================================            |  82%  |                                                                              |==========================================================            |  83%  |                                                                              |==========================================================            |  84%  |                                                                              |===========================================================           |  84%  |                                                                              |===========================================================           |  85%  |                                                                              |============================================================          |  85%  |                                                                              |============================================================          |  86%  |                                                                              |=============================================================         |  86%  |                                                                              |=============================================================         |  87%  |                                                                              |=============================================================         |  88%  |                                                                              |==============================================================        |  88%  |                                                                              |==============================================================        |  89%  |                                                                              |===============================================================       |  89%  |                                                                              |===============================================================       |  90%  |                                                                              |===============================================================       |  91%  |                                                                              |================================================================      |  91%  |                                                                              |================================================================      |  92%  |                                                                              |=================================================================     |  92%  |                                                                              |=================================================================     |  93%  |                                                                              |==================================================================    |  94%  |                                                                              |==================================================================    |  95%  |                                                                              |===================================================================   |  95%  |                                                                              |===================================================================   |  96%  |                                                                              |====================================================================  |  97%  |                                                                              |====================================================================  |  98%  |                                                                              |===================================================================== |  98%  |                                                                              |===================================================================== |  99%  |                                                                              |======================================================================|  99%  |                                                                              |======================================================================| 100%
# cell_tables1 <-  layerValues2pixel(layer_values = do.call(rbind, tbls1),
#                                   tb_name = mainFile$NAME,
#                                   col_name = "20170101")
```

Resultado:

``` r
# uma lista nomeada de tabelas por pixel
names(cell_tables[1:10])
#>  [1] "uas22" "uas23" "uas24" "uas25" "uas58" "uas59" "uas60" "uas61" "uas62"
#> [10] "uas63"
# visualizando as 5 primeiras tabelas
knitr::kable(cell_tables[1:10], format = "html")
```

<table class="kable_wrapper">
<tbody>
<tr>
<td>
<table>
<thead>
<tr>
<th style="text-align:right;">
20170101
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
0.0437098
</td>
</tr>
<tr>
<td style="text-align:right;">
-0.3644886
</td>
</tr>
<tr>
<td style="text-align:right;">
-0.7967319
</td>
</tr>
</tbody>
</table>
</td>
<td>
<table>
<thead>
<tr>
<th style="text-align:right;">
20170101
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
-0.3524084
</td>
</tr>
<tr>
<td style="text-align:right;">
-0.5521717
</td>
</tr>
<tr>
<td style="text-align:right;">
-0.8689976
</td>
</tr>
</tbody>
</table>
</td>
<td>
<table>
<thead>
<tr>
<th style="text-align:right;">
20170101
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
-0.7492590
</td>
</tr>
<tr>
<td style="text-align:right;">
-0.7405262
</td>
</tr>
<tr>
<td style="text-align:right;">
-0.9260349
</td>
</tr>
</tbody>
</table>
</td>
<td>
<table>
<thead>
<tr>
<th style="text-align:right;">
20170101
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
-1.1027136
</td>
</tr>
<tr>
<td style="text-align:right;">
-0.9446888
</td>
</tr>
<tr>
<td style="text-align:right;">
-1.0236912
</td>
</tr>
</tbody>
</table>
</td>
<td>
<table>
<thead>
<tr>
<th style="text-align:right;">
20170101
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
0.4351892
</td>
</tr>
<tr>
<td style="text-align:right;">
-0.1973133
</td>
</tr>
<tr>
<td style="text-align:right;">
-0.5290623
</td>
</tr>
</tbody>
</table>
</td>
<td>
<table>
<thead>
<tr>
<th style="text-align:right;">
20170101
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
0.3896570
</td>
</tr>
<tr>
<td style="text-align:right;">
-0.2233753
</td>
</tr>
<tr>
<td style="text-align:right;">
-0.6202183
</td>
</tr>
</tbody>
</table>
</td>
<td>
<table>
<thead>
<tr>
<th style="text-align:right;">
20170101
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
0.2885218
</td>
</tr>
<tr>
<td style="text-align:right;">
-0.2599964
</td>
</tr>
<tr>
<td style="text-align:right;">
-0.7056065
</td>
</tr>
</tbody>
</table>
</td>
<td>
<table>
<thead>
<tr>
<th style="text-align:right;">
20170101
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
0.0457850
</td>
</tr>
<tr>
<td style="text-align:right;">
-0.3856678
</td>
</tr>
<tr>
<td style="text-align:right;">
-0.8162632
</td>
</tr>
</tbody>
</table>
</td>
<td>
<table>
<thead>
<tr>
<th style="text-align:right;">
20170101
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
-0.3877478
</td>
</tr>
<tr>
<td style="text-align:right;">
-0.5987415
</td>
</tr>
<tr>
<td style="text-align:right;">
-0.9041538
</td>
</tr>
</tbody>
</table>
</td>
<td>
<table>
<thead>
<tr>
<th style="text-align:right;">
20170101
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
-0.8633947
</td>
</tr>
<tr>
<td style="text-align:right;">
-0.8483143
</td>
</tr>
<tr>
<td style="text-align:right;">
-1.0185032
</td>
</tr>
</tbody>
</table>
</td>
</tr>
</tbody>
</table>

## Rotinas para interpolação de dados de estações físicas em uma área especifica

Os arquivos de entrada devem possuir a formatação utilizada pelo SWAT e
se encontrar em uma única pasta:

``` r
list.files(pasta_estacoes)
#>  [1] "p-1553003.txt" "p-1554006.txt" "p-1555005.txt" "p-1556007.txt"
#>  [5] "p-1653002.txt" "p-1653004.txt" "p-1653005.txt" "p-1654000.txt"
#>  [9] "p-1654001.txt" "p-1654004.txt" "p-1654005.txt" "p-1754000.txt"
#> [13] "p-83358.txt"   "p-A907.txt"    "pcp.txt"
```

> Essa amostra de dados comtem observaçoes de dados de chuva de 14
> estações no periodo de 01/03/2017 a 31/03/2017. Os valores -99 são uma
> codificação para dados faltantes(falhas).

Assim, a pasta deve incluir um arquivo dos dados da série para cada
estação e um arquivo master das coordenadas etc. das estações (no
exemplo: pcp.txt):

Numa série temporal é uma tabela txt de coluna única, onde o nome da
coluna é a primeira data, seguidos pelos dados do parametro de acordo
com a resolução temporal (geralmente diária). Exemplo da série
`p-1553003.txt`

    #>    X20170301
    #> 1          0
    #> 2        -99
    #> 3          0
    #> 4          0
    #> 5          0
    #> 6          0
    #> 7        -99
    #> 8          0
    #> 9          8
    #> 10       -99
    #> 11         0
    #> 12         0
    #> 13         0
    #> 14         0
    #> 15         0
    #> 16         0
    #> 17       -99
    #> 18       -99
    #> 19       150
    #> 20         0
    #> 21         0
    #> 22         0
    #> 23         0
    #> 24       -99
    #> 25         0
    #> 26         4
    #> 27        20
    #> 28        10
    #> 29         4
    #> 30        10
    #> 31       -99

Arquivo master contendo IDs sequenciais, os nomes das estações, suas
coordenadas e sua elevação `pcp.txt`

    #>    ID      NAME      LAT     LONG ELEVATION
    #> 1   1 p-1553003 -15.9400 -53.4500    597.00
    #> 2   2 p-1554006 -15.9890 -54.9680    256.00
    #> 3   3 p-1555005 -15.8400 -55.3200    783.00
    #> 4   4 p-1556007 -15.6990 -55.1360    699.00
    #> 5   5 p-1653002 -16.3500 -53.7600    482.00
    #> 6   6 p-1653004 -16.9400 -53.5300    735.00
    #> 7   7 p-1653005 -16.6700 -53.4500    533.00
    #> 8   8 p-1654000 -16.4710 -54.6570    231.00
    #> 9   9 p-1654001 -16.6740 -54.2660    314.00
    #> 10 10 p-1654004 -16.8430 -54.4080    295.00
    #> 11 11 p-1654005 -16.3910 -54.1490    381.00
    #> 12 12 p-1754000 -17.2100 -54.1400    527.00
    #> 13 13   p-83358 -15.8274 -54.3955    374.35
    #> 14 14    p-A907 -16.4625 -54.5802    289.88

## Preenchimento de falhas

Antes de proseguir para as transformações, pode se efetuar uma
verificação dos dados no quesito de dados faltantes. Para isso temos
duas funções:

-   `files_to_table()`: importa todas as series em uma unica tabela;
-   `count_na()`: verifica a quantidade de dados faltantes em cada
    coluna de dados, i. e., para cada estção.
-   `fill_gap()`: permite preencher as falhas de dados presentes.
-   `table_to_files()`: exporta cada coluna da tabela pós-preenchimento
    em um arquivo separado.

Importando os dados:

``` r
unique_table <- files_to_table(files_path = pasta_estacoes,
                              files_pattern = "p-",
                              start_date = "2017-03-01",
                              end_date = "2017-03-31",
                              na_value = -99,
                              neg_to_zero = FALSE
)
```

#### Visão geral de dados das 14 estações:

| p-1553003 | p-1554006 | p-1555005 | p-1556007 | p-1653002 | p-1653004 | p-1653005 | p-1654000 | p-1654001 | p-1654004 | p-1654005 | p-1754000 | p-83358 | p-A907 |
|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|--------:|-------:|
|         0 |       8.4 |       0.0 |       0.0 |       5.2 |       0.3 |      28.5 |       0.0 |        NA |       0.0 |       0.0 |       4.2 |     0.0 |    0.0 |
|        NA |      12.3 |       0.0 |       0.0 |        NA |       3.3 |      23.2 |       0.0 |       0.0 |       0.0 |       3.5 |      16.5 |     0.0 |    3.8 |
|         0 |       0.0 |       0.0 |      30.4 |       0.0 |       0.3 |       0.2 |       3.2 |        NA |       0.0 |      21.7 |      30.3 |     3.0 |    0.8 |
|         0 |       5.1 |       0.0 |      38.6 |      14.1 |       0.0 |      17.5 |      11.8 |      13.7 |       0.0 |       0.0 |       0.0 |      NA |    4.8 |
|         0 |       0.0 |        NA |       0.0 |       0.0 |       0.0 |       0.0 |       8.1 |       0.0 |       0.0 |      23.4 |       0.0 |     0.0 |   14.6 |
|         0 |       0.0 |      37.4 |       0.0 |       4.1 |       5.2 |      49.3 |        NA |      50.6 |        NA |      66.9 |      37.4 |     0.0 |    0.8 |
|        NA |       2.1 |      14.1 |       0.0 |      11.9 |        NA |       5.8 |      30.2 |       0.0 |        NA |      11.6 |       8.5 |    46.0 |    5.4 |
|         0 |       0.0 |       4.2 |       0.0 |       0.0 |        NA |       2.1 |       8.0 |       6.9 |       0.0 |       0.0 |       0.0 |     0.0 |    0.4 |
|         8 |       0.0 |       0.0 |       0.0 |       0.0 |       0.0 |        NA |       0.0 |       0.0 |       0.0 |       0.0 |      12.3 |     0.0 |    0.0 |
|        NA |       0.0 |       0.0 |      40.0 |       0.0 |       0.0 |        NA |       0.0 |        NA |       0.0 |       3.9 |       6.4 |     0.0 |    1.2 |
|         0 |       0.0 |       9.6 |       0.0 |        NA |        NA |        NA |      11.6 |       0.0 |       0.0 |       0.0 |       0.0 |     0.0 |    0.4 |
|         0 |        NA |       6.2 |        NA |       0.0 |       0.0 |       4.1 |       0.0 |       0.0 |       2.0 |       0.0 |      14.3 |     0.0 |     NA |
|         0 |       4.3 |       0.0 |       0.0 |       0.0 |       0.0 |      11.9 |      14.9 |       0.0 |        NA |       0.0 |       8.2 |    17.0 |    3.4 |
|         0 |       1.2 |        NA |       0.0 |       0.0 |       0.0 |        NA |       1.3 |       0.0 |       0.0 |       0.0 |      18.5 |     0.0 |    0.2 |
|         0 |      12.8 |      18.9 |       0.0 |       0.0 |        NA |       0.0 |        NA |       0.0 |       0.0 |       0.0 |       4.2 |     0.0 |    0.0 |
|         0 |        NA |       0.8 |      20.2 |       0.5 |       0.0 |        NA |       0.7 |       0.0 |      27.2 |       0.0 |       0.0 |      NA |    1.6 |
|        NA |       0.0 |      26.4 |      60.4 |       0.0 |       0.0 |       0.0 |      67.0 |       8.7 |        NA |       0.7 |        NA |     0.0 |   40.2 |
|        NA |      10.4 |      51.2 |      50.3 |      10.8 |       0.0 |      22.5 |        NA |       0.0 |      50.1 |      38.7 |      26.4 |    71.0 |    9.2 |
|       150 |      14.2 |      27.8 |       0.0 |       6.3 |        NA |      55.8 |      19.4 |      50.6 |       0.0 |       4.5 |       6.3 |    42.0 |   15.6 |
|         0 |       0.0 |      27.2 |       0.0 |      10.2 |       0.0 |       0.3 |       0.0 |       0.0 |      20.2 |       0.0 |       0.0 |     0.0 |    1.2 |
|         0 |       0.0 |        NA |      10.3 |       7.3 |        NA |        NA |       0.0 |      40.2 |      10.8 |       0.7 |      12.5 |    16.0 |    0.0 |
|         0 |       0.0 |        NA |       0.0 |      11.3 |      12.4 |       7.3 |        NA |      18.4 |       0.0 |      11.9 |       8.6 |     4.6 |     NA |
|         0 |       7.5 |       0.0 |      20.4 |        NA |       0.0 |       1.1 |       0.0 |        NA |       0.0 |       0.0 |        NA |     0.0 |    0.0 |
|        NA |       0.0 |       0.0 |       0.0 |        NA |       0.0 |       0.0 |        NA |       0.0 |        NA |        NA |       0.0 |      NA |    0.0 |
|         0 |       0.0 |       0.6 |       0.0 |       0.0 |       4.2 |      14.0 |       0.0 |       5.2 |       0.0 |      25.5 |      14.2 |     0.0 |     NA |
|         4 |       9.4 |      12.6 |      40.2 |       0.0 |        NA |       0.7 |       0.0 |       0.0 |       0.0 |       0.0 |       6.5 |     0.0 |    0.0 |
|        20 |        NA |       0.0 |       8.4 |       4.3 |       1.1 |      26.6 |       0.0 |       0.0 |        NA |       1.1 |      15.2 |      NA |    0.0 |
|        10 |        NA |       6.7 |        NA |      10.1 |      13.3 |       8.8 |       0.3 |       0.0 |       0.0 |      50.8 |        NA |    28.0 |    0.0 |
|         4 |       0.0 |       0.5 |        NA |       0.0 |       0.3 |       0.0 |       0.0 |       0.0 |       0.0 |       0.0 |       4.3 |      NA |    6.0 |
|        10 |       9.3 |      13.8 |        NA |       2.1 |      21.2 |       0.0 |       0.0 |       0.0 |       0.0 |       3.9 |        NA |     3.4 |   15.0 |
|        NA |       0.0 |       0.4 |        NA |       0.0 |     127.4 |      31.4 |       0.3 |       0.0 |       0.0 |      16.8 |       0.0 |     0.0 |    0.0 |

#### Calculo das porcentagens de NA em cada coluna:

``` r
wcswatin::count_na(unique_table[-1], percent = TRUE)
#>       column   Prop_NA
#> 1  p-1553003 22.580645
#> 2  p-1554006 12.903226
#> 3  p-1555005 12.903226
#> 4  p-1556007 16.129032
#> 5  p-1653002 12.903226
#> 6  p-1653004 22.580645
#> 7  p-1653005 19.354839
#> 8  p-1654000 16.129032
#> 9  p-1654001 12.903226
#> 10 p-1654004 19.354839
#> 11 p-1654005  3.225806
#> 12 p-1754000 12.903226
#> 13   p-83358 16.129032
#> 14    p-A907  9.677419
```

#### Executando o preenchimento das falhas:

``` {r
gap_filled <- wcswatin::fill_gap(dataset = unique_table,
                                    corPeriod = "daily")
```

#### Após o preenchimento de falhas:

| p-1553003 | p-1554006 | p-1555005 | p-1556007 | p-1653002 | p-1653004 | p-1653005 | p-1654000 | p-1654001 | p-1654004 | p-1654005 | p-1754000 | p-83358 | p-A907 |
|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|--------:|-------:|
|     0.000 |     8.400 |     0.000 |     0.000 |     5.200 |     0.300 |    28.500 |     0.000 |     7.790 |     0.000 |       0.0 |     4.200 |   0.000 |  0.000 |
|    38.993 |    12.300 |     0.000 |     0.000 |     5.785 |     3.300 |    23.200 |     0.000 |     0.000 |     0.000 |       3.5 |    16.500 |   0.000 |  3.800 |
|     0.000 |     0.000 |     0.000 |    30.400 |     0.000 |     0.300 |     0.200 |     3.200 |     0.000 |     0.000 |      21.7 |    30.300 |   3.000 |  0.800 |
|     0.000 |     5.100 |     0.000 |    38.600 |    14.100 |     0.000 |    17.500 |    11.800 |    13.700 |     0.000 |       0.0 |     0.000 |   8.238 |  4.800 |
|     0.000 |     0.000 |     0.000 |     0.000 |     0.000 |     0.000 |     0.000 |     8.100 |     0.000 |     0.000 |      23.4 |     0.000 |   0.000 | 14.600 |
|     0.000 |     0.000 |    37.400 |     0.000 |     4.100 |     5.200 |    49.300 |     0.000 |    50.600 |     0.000 |      66.9 |    37.400 |   0.000 |  0.800 |
|     6.657 |     2.100 |    14.100 |     0.000 |    11.900 |     0.973 |     5.800 |    30.200 |     0.000 |     1.147 |      11.6 |     8.500 |  46.000 |  5.400 |
|     0.000 |     0.000 |     4.200 |     0.000 |     0.000 |     0.000 |     2.100 |     8.000 |     6.900 |     0.000 |       0.0 |     0.000 |   0.000 |  0.400 |
|     8.000 |     0.000 |     0.000 |     0.000 |     0.000 |     0.000 |     0.000 |     0.000 |     0.000 |     0.000 |       0.0 |    12.300 |   0.000 |  0.000 |
|     0.000 |     0.000 |     0.000 |    40.000 |     0.000 |     0.000 |     0.000 |     0.000 |     0.000 |     0.000 |       3.9 |     6.400 |   0.000 |  1.200 |
|     0.000 |     0.000 |     9.600 |     0.000 |     0.000 |     0.000 |     0.000 |    11.600 |     0.000 |     0.000 |       0.0 |     0.000 |   0.000 |  0.400 |
|     0.000 |     1.237 |     6.200 |     4.124 |     0.000 |     0.000 |     4.100 |     0.000 |     0.000 |     2.000 |       0.0 |    14.300 |   0.000 |  1.974 |
|     0.000 |     4.300 |     0.000 |     0.000 |     0.000 |     0.000 |    11.900 |    14.900 |     0.000 |     2.348 |       0.0 |     8.200 |  17.000 |  3.400 |
|     0.000 |     1.200 |     1.778 |     0.000 |     0.000 |     0.000 |     2.114 |     1.300 |     0.000 |     0.000 |       0.0 |    18.500 |   0.000 |  0.200 |
|     0.000 |    12.800 |    18.900 |     0.000 |     0.000 |     5.929 |     0.000 |     8.438 |     0.000 |     0.000 |       0.0 |     4.200 |   0.000 |  0.000 |
|     0.000 |     0.160 |     0.800 |    20.200 |     0.500 |     0.000 |     0.526 |     0.700 |     0.000 |    27.200 |       0.0 |     0.000 |   0.621 |  1.600 |
|     0.000 |     0.000 |    26.400 |    60.400 |     0.000 |     0.000 |     0.000 |    67.000 |     8.700 |     0.000 |       0.7 |     0.000 |   0.000 | 40.200 |
|    32.970 |    10.400 |    51.200 |    50.300 |    10.800 |     0.000 |    22.500 |     6.856 |     0.000 |    50.100 |      38.7 |    26.400 |  71.000 |  9.200 |
|   150.000 |    14.200 |    27.800 |     0.000 |     6.300 |     6.578 |    55.800 |    19.400 |    50.600 |     0.000 |       4.5 |     6.300 |  42.000 | 15.600 |
|     0.000 |     0.000 |    27.200 |     0.000 |    10.200 |     0.000 |     0.300 |     0.000 |     0.000 |    20.200 |       0.0 |     0.000 |   0.000 |  1.200 |
|     0.000 |     0.000 |     0.000 |    10.300 |     7.300 |     0.000 |     0.000 |     0.000 |    40.200 |    10.800 |       0.7 |    12.500 |  16.000 |  0.000 |
|     0.000 |     0.000 |     0.000 |     0.000 |    11.300 |    12.400 |     7.300 |     0.000 |    18.400 |     0.000 |      11.9 |     8.600 |   4.600 |  0.000 |
|     0.000 |     7.500 |     0.000 |    20.400 |     3.528 |     0.000 |     1.100 |     0.000 |     6.955 |     0.000 |       0.0 |     7.124 |   0.000 |  0.000 |
|     0.000 |     0.000 |     0.000 |     0.000 |     0.000 |     0.000 |     0.000 |     0.000 |     0.000 |     0.000 |       0.0 |     0.000 |   0.000 |  0.000 |
|     0.000 |     0.000 |     0.600 |     0.000 |     0.000 |     4.200 |    14.000 |     0.000 |     5.200 |     0.000 |      25.5 |    14.200 |   0.000 |  0.000 |
|     4.000 |     9.400 |    12.600 |    40.200 |     0.000 |     4.354 |     0.700 |     0.000 |     0.000 |     0.000 |       0.0 |     6.500 |   0.000 |  0.000 |
|    20.000 |     0.000 |     0.000 |     8.400 |     4.300 |     1.100 |    26.600 |     0.000 |     0.000 |     0.000 |       1.1 |    15.200 |   0.000 |  0.000 |
|    10.000 |     1.337 |     6.700 |     4.456 |    10.100 |    13.300 |     8.800 |     0.300 |     0.000 |     0.000 |      50.8 |     3.462 |  28.000 |  0.000 |
|     4.000 |     0.000 |     0.500 |     0.000 |     0.000 |     0.300 |     0.000 |     0.000 |     0.000 |     0.000 |       0.0 |     4.300 |   0.000 |  6.000 |
|    10.000 |     9.300 |    13.800 |    13.064 |     2.100 |    21.200 |     0.000 |     0.000 |     0.000 |     0.000 |       3.9 |     8.834 |   3.400 | 15.000 |
|     0.000 |     0.000 |     0.400 |     0.000 |     0.000 |   127.400 |    31.400 |     0.300 |     0.000 |     0.000 |      16.8 |     0.000 |   0.000 |  0.000 |

> Após desses passos, é preciso salvar os dados com as falhas corrigidas
> com a função `table_to_files()` em uma pasta local, e passam a ser os
> dados de entrada para o restante do processamento.

Para preparar a interpolação entre as estações com ajuste individual
para cada passo de tempo, a função `point_to_daily` capta as séries de
todos os pontos/estações e cria uma tabela única para cada dia

``` r
dados_diarios <- point_to_daily(my_folder = pasta_estacoes1,
                                var_pattern = "p-",
                                main_pattern = "pcp",
                                start_date = "20170301",
                                end_date = "20170331",
                                interval = "day",
                                na_value = -99,
                                negatif_number = TRUE,
                                prefix = "day_")
#>   |                                                                              |                                                                      |   0%  |                                                                              |==                                                                    |   3%  |                                                                              |=====                                                                 |   6%  |                                                                              |=======                                                               |  10%  |                                                                              |=========                                                             |  13%  |                                                                              |===========                                                           |  16%  |                                                                              |==============                                                        |  19%  |                                                                              |================                                                      |  23%  |                                                                              |==================                                                    |  26%  |                                                                              |====================                                                  |  29%  |                                                                              |=======================                                               |  32%  |                                                                              |=========================                                             |  35%  |                                                                              |===========================                                           |  39%  |                                                                              |=============================                                         |  42%  |                                                                              |================================                                      |  45%  |                                                                              |==================================                                    |  48%  |                                                                              |====================================                                  |  52%  |                                                                              |======================================                                |  55%  |                                                                              |=========================================                             |  58%  |                                                                              |===========================================                           |  61%  |                                                                              |=============================================                         |  65%  |                                                                              |===============================================                       |  68%  |                                                                              |==================================================                    |  71%  |                                                                              |====================================================                  |  74%  |                                                                              |======================================================                |  77%  |                                                                              |========================================================              |  81%  |                                                                              |===========================================================           |  84%  |                                                                              |=============================================================         |  87%  |                                                                              |===============================================================       |  90%  |                                                                              |=================================================================     |  94%  |                                                                              |====================================================================  |  97%  |                                                                              |======================================================================| 100%
dados_diarios[18] # exemplo de uma tabela
#> $`day_2017-03-18`
#>     ID      NAME      LAT     LONG ELEVATION    pcp
#>  1:  1 p-1553003 -15.9400 -53.4500    597.00 32.970
#>  2:  2 p-1554006 -15.9890 -54.9680    256.00 10.400
#>  3:  3 p-1555005 -15.8400 -55.3200    783.00 51.200
#>  4:  4 p-1556007 -15.6990 -55.1360    699.00 50.300
#>  5:  5 p-1653002 -16.3500 -53.7600    482.00 10.800
#>  6:  6 p-1653004 -16.9400 -53.5300    735.00  0.000
#>  7:  7 p-1653005 -16.6700 -53.4500    533.00 22.500
#>  8:  8 p-1654000 -16.4710 -54.6570    231.00  6.856
#>  9:  9 p-1654001 -16.6740 -54.2660    314.00  0.000
#> 10: 10 p-1654004 -16.8430 -54.4080    295.00 50.100
#> 11: 11 p-1654005 -16.3910 -54.1490    381.00 38.700
#> 12: 12 p-1754000 -17.2100 -54.1400    527.00 26.400
#> 13: 13   p-83358 -15.8274 -54.3955    374.35 71.000
#> 14: 14    p-A907 -16.4625 -54.5802    289.88  9.200
```

As tabelas diárias podem ser salvas com a função `save_daily_tbl` do
pacote `wcswatin` (por favor consultar a documentação da função).

Segue a leitura dos centroides das estações utilizadas nas
interpolações:

``` r
sf::read_sf(centroides_path)
#> Simple feature collection with 258 features and 5 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: -55.27486 ymin: -17.14102 xmax: -53.76752 ymax: -15.53671
#> Geodetic CRS:  WGS 84
#> # A tibble: 258 × 6
#>    OBJECTID Subbasin  Elev Lat_dec Lon_dec              geometry
#>       <dbl>    <dbl> <dbl>   <dbl>   <dbl>           <POINT [°]>
#>  1        1        1   556   -15.5   -54.9 (-54.94489 -15.53671)
#>  2        2        2   587   -15.6   -55.1 (-55.08196 -15.55587)
#>  3        3        3   622   -15.6   -54.7 (-54.73782 -15.55762)
#>  4        4        4   511   -15.6   -54.7  (-54.6657 -15.56561)
#>  5        5        5   472   -15.6   -54.9 (-54.92795 -15.60461)
#>  6        6        6   631   -15.6   -54.8 (-54.77498 -15.60364)
#>  7        7        7   424   -15.7   -54.7 (-54.74662 -15.65306)
#>  8        8        8   532   -15.6   -54.6 (-54.62564 -15.63742)
#>  9        9        9   530   -15.6   -54.8 (-54.83962 -15.59748)
#> 10       10       10   432   -15.7   -54.8  (-54.79766 -15.6824)
#> # … with 248 more rows
```

A função `ts_to_point` faz a interpolação, no exemplo, utilizando o
método “Trend surface” com polinómio de segundo grau para os pontos
indicados por meio de um shapefile contendo os pontos desejados. Para
uso dos dados interpolados no SWAT recomenda-se por exemplo um shape dos
centroides de cada subbacia parametrizada. É gerado um arquivo txt com a
série temporal de cada ponto interpolado.

``` r
#list.files(pasta_dados_diarios)
serie_pontos <- ts_to_point(my_folder = pasta_dados_diarios,
                            targeted_points_path = centroides_path,
                            poly_degree = 2)
#>   |                                                                              |                                                                      |   0%  |                                                                              |==                                                                    |   3%  |                                                                              |=====                                                                 |   6%  |                                                                              |=======                                                               |  10%  |                                                                              |=========                                                             |  13%  |                                                                              |===========                                                           |  16%  |                                                                              |==============                                                        |  19%  |                                                                              |================                                                      |  23%  |                                                                              |==================                                                    |  26%  |                                                                              |====================                                                  |  29%  |                                                                              |=======================                                               |  32%  |                                                                              |=========================                                             |  35%  |                                                                              |===========================                                           |  39%  |                                                                              |=============================                                         |  42%  |                                                                              |================================                                      |  45%  |                                                                              |==================================                                    |  48%  |                                                                              |====================================                                  |  52%  |                                                                              |======================================                                |  55%  |                                                                              |=========================================                             |  58%  |                                                                              |===========================================                           |  61%  |                                                                              |=============================================                         |  65%  |                                                                              |===============================================                       |  68%  |                                                                              |==================================================                    |  71%  |                                                                              |====================================================                  |  74%  |                                                                              |======================================================                |  77%  |                                                                              |========================================================              |  81%  |                                                                              |===========================================================           |  84%  |                                                                              |=============================================================         |  87%  |                                                                              |===============================================================       |  90%  |                                                                              |=================================================================     |  94%  |                                                                              |====================================================================  |  97%  |                                                                              |======================================================================| 100%

serie_pontos[[1]]
#> # A tibble: 31 × 3
#>       ID date           value
#>    <int> <chr>          <dbl>
#>  1     1 day_2017-03-01  0
#>  2     1 day_2017-03-02  0
#>  3     1 day_2017-03-03 30.6
#>  4     1 day_2017-03-04 23.7
#>  5     1 day_2017-03-05  0
#>  6     1 day_2017-03-06  2.10
#>  7     1 day_2017-03-07 27.0
#>  8     1 day_2017-03-08  0
#>  9     1 day_2017-03-09  3.00
#> 10     1 day_2017-03-10 28.3
#> # … with 21 more rows
```

A função `varMain_creator` cria uma tabela master para entrada no SWAT
para os dados da grade regular ou irregular interpolada

``` r
varMain_creator(targeted_points_path = centroides_path,
                var_name = "pcp",
                col_elev = "Elev")
#> # A tibble: 258 × 5
#>       ID NAME    LAT  LONG ELEVATION
#>    <dbl> <chr> <dbl> <dbl>     <dbl>
#>  1     1 pcp1  -15.5 -54.9       556
#>  2     2 pcp2  -15.6 -55.1       587
#>  3     3 pcp3  -15.6 -54.7       622
#>  4     4 pcp4  -15.6 -54.7       511
#>  5     5 pcp5  -15.6 -54.9       472
#>  6     6 pcp6  -15.6 -54.8       631
#>  7     7 pcp7  -15.7 -54.7       424
#>  8     8 pcp8  -15.6 -54.6       532
#>  9     9 pcp9  -15.6 -54.8       530
#> 10    10 pcp10 -15.7 -54.8       432
#> # … with 248 more rows
```

A função `ts_to_area` ainda permite interpolar os pontos de entrada para
uma área de estudo inteiro e cria um raster para cada dia em uma
resolução espacial a ser definida (no exemplo 0.01°)

``` r
raster_interpolated <- ts_to_area(my_folder = pasta_dados_diarios,
           bassin_limit_path = bassin_path,
           poly_degree = 2,
           resolution = 0.01)
#>   |                                                                              |                                                                      |   0%  |                                                                              |==                                                                    |   3%  |                                                                              |=====                                                                 |   6%  |                                                                              |=======                                                               |  10%  |                                                                              |=========                                                             |  13%  |                                                                              |===========                                                           |  16%  |                                                                              |==============                                                        |  19%  |                                                                              |================                                                      |  23%  |                                                                              |==================                                                    |  26%  |                                                                              |====================                                                  |  29%  |                                                                              |=======================                                               |  32%  |                                                                              |=========================                                             |  35%  |                                                                              |===========================                                           |  39%  |                                                                              |=============================                                         |  42%  |                                                                              |================================                                      |  45%  |                                                                              |==================================                                    |  48%  |                                                                              |====================================                                  |  52%  |                                                                              |======================================                                |  55%  |                                                                              |=========================================                             |  58%  |                                                                              |===========================================                           |  61%  |                                                                              |=============================================                         |  65%  |                                                                              |===============================================                       |  68%  |                                                                              |==================================================                    |  71%  |                                                                              |====================================================                  |  74%  |                                                                              |======================================================                |  77%  |                                                                              |========================================================              |  81%  |                                                                              |===========================================================           |  84%  |                                                                              |=============================================================         |  87%  |                                                                              |===============================================================       |  90%  |                                                                              |=================================================================     |  94%  |                                                                              |====================================================================  |  97%  |                                                                              |======================================================================| 100%

raster_interpolated[[18]]
#> class      : RasterLayer
#> dimensions : 170, 170, 28900  (nrow, ncol, ncell)
#> resolution : 0.01, 0.01  (x, y)
#> extent     : -55.4081, -53.7081, -17.17936, -15.47936  (xmin, xmax, ymin, ymax)
#> crs        : +proj=longlat +datum=WGS84 +no_defs
#> source     : memory
#> names      : day_2017.03.18
#> values     : 0, 98.62848  (min, max)
```

Para visualização de uma camada interpolada e sua validação é utilizado
o pacote `tmap` que combina o raster interpolado com as estações
utilizadas na interpolação.

``` r
dia <- 18
tmap::tm_shape(raster_interpolated[[dia]]) +
  tmap::tm_raster(title = "Precipitação Estimada \n Trend Surface (mm)",
                  midpoint = NA,
                  n = 15, palette = "-RdBu",
                  style = c("cat", "fixed", "sd", "equal", "pretty", "quantile",
                            "kmeans", "hclust", "bclust", "fisher",
                            "dpih", "headtails")[7]) +
  tmap::tm_shape(sf::read_sf(bassin_path)) +
  tmap::tm_borders(col = "red") +
  tmap::tm_shape(sf::st_as_sf(as.data.frame(dados_diarios[[dia]]), coords = c("LONG", "LAT"),
                              crs = "+proj=longlat +datum=WGS84 +no_defs")) +
  tmap::tm_text(text = "pcp",
                auto.placement = 1,
                size = .8) +
  tmap::tm_dots(shape = 1,
                col = "blue",
                size = "pcp",
                title.size = "Precipitação Observada em Campo") +
  tmap::tm_legend(legend.outside = TRUE) +
  tmap::tm_compass(type = "arrow", position = c(0.08,0.1), size = 2) +
  tmap::tm_scale_bar(text.size = .5,
                     position = c(0.01, 0),
  )
```

<img src="man/figures/README-unnamed-chunk-33-1.png" width="100%" />

<br><br>

# Validação de dados simulados com dados coletados em campo

A validação consiste em criar uma tabela unica contendo os dados de
campo e os dados “simulados” de precipitação. Tendo isso, pode-se
utilizar as funções `ggof()` *(Graphical Goodness of Fit)* ou `gof`
*(Numerical Goodness-of-fit measures)* do pacote `hydroGOF` para
comparar os dados observados e os dados simulados.

Como exemplo, pegamos dados de precipitação coletados de 14 estações da
ANA e INMET para o periodo de 01/03/2017 a 31/03/2017 como dados
observados e dados provenientes do produto [GPM IMERG Final
Precipitation L3](https://gpm.nasa.gov/data/directory) da plataforma
[GES
DISC](https://disc.gsfc.nasa.gov/datasets/GPM_3IMERGDF_06/summary?keywords=%22IMERG%20final%22)
de precipitação para o mesmo periodo.

## Os passos:

-   Criar uma tabela unica com os dados de campo com ajuda da função
    `wcswatin::files_to_table()`;
-   Transformar os arquivos NetCDF para dados em formato Raster com
    ajuda da função `wcswatin::ncdf_to_raster()`;
-   Extrair os dados de precipitação nos dados em formato Raster com
    ajuda da função `wcswatin::tbl_from_references()`;
-   Juntar as duas tabelas em uma unica tabela;
-   Rodar a função `hydroGOF::ggof()`

Dados das estações:

``` r
list.files(pasta_estacoes,
                       full.names = FALSE)
#>  [1] "p-1553003.txt" "p-1554006.txt" "p-1555005.txt" "p-1556007.txt"
#>  [5] "p-1653002.txt" "p-1653004.txt" "p-1653005.txt" "p-1654000.txt"
#>  [9] "p-1654001.txt" "p-1654004.txt" "p-1654005.txt" "p-1754000.txt"
#> [13] "p-83358.txt"   "p-A907.txt"    "pcp.txt"
```

O arquivo `pcp.txt` contem as localizações dos 14 estações:

    #>    ID      NAME      LAT     LONG ELEVATION
    #> 1   1 p-1553003 -15.9400 -53.4500    597.00
    #> 2   2 p-1554006 -15.9890 -54.9680    256.00
    #> 3   3 p-1555005 -15.8400 -55.3200    783.00
    #> 4   4 p-1556007 -15.6990 -55.1360    699.00
    #> 5   5 p-1653002 -16.3500 -53.7600    482.00
    #> 6   6 p-1653004 -16.9400 -53.5300    735.00
    #> 7   7 p-1653005 -16.6700 -53.4500    533.00
    #> 8   8 p-1654000 -16.4710 -54.6570    231.00
    #> 9   9 p-1654001 -16.6740 -54.2660    314.00
    #> 10 10 p-1654004 -16.8430 -54.4080    295.00
    #> 11 11 p-1654005 -16.3910 -54.1490    381.00
    #> 12 12 p-1754000 -17.2100 -54.1400    527.00
    #> 13 13   p-83358 -15.8274 -54.3955    374.35
    #> 14 14    p-A907 -16.4625 -54.5802    289.88

Os arquivos baixados:

``` r
# lista dos arquivos
list.files(ncdf_path,
           pattern = "nc4*",
           full.names = FALSE)
#>  [1] "3B-DAY.MS.MRG.3IMERG.20170301-S000000-E235959.V06.nc4.SUB.nc4"
#>  [2] "3B-DAY.MS.MRG.3IMERG.20170302-S000000-E235959.V06.nc4.SUB.nc4"
#>  [3] "3B-DAY.MS.MRG.3IMERG.20170303-S000000-E235959.V06.nc4.SUB.nc4"
#>  [4] "3B-DAY.MS.MRG.3IMERG.20170304-S000000-E235959.V06.nc4.SUB.nc4"
#>  [5] "3B-DAY.MS.MRG.3IMERG.20170305-S000000-E235959.V06.nc4.SUB.nc4"
#>  [6] "3B-DAY.MS.MRG.3IMERG.20170306-S000000-E235959.V06.nc4.SUB.nc4"
#>  [7] "3B-DAY.MS.MRG.3IMERG.20170307-S000000-E235959.V06.nc4.SUB.nc4"
#>  [8] "3B-DAY.MS.MRG.3IMERG.20170308-S000000-E235959.V06.nc4.SUB.nc4"
#>  [9] "3B-DAY.MS.MRG.3IMERG.20170309-S000000-E235959.V06.nc4.SUB.nc4"
#> [10] "3B-DAY.MS.MRG.3IMERG.20170310-S000000-E235959.V06.nc4.SUB.nc4"
#> [11] "3B-DAY.MS.MRG.3IMERG.20170311-S000000-E235959.V06.nc4.SUB.nc4"
#> [12] "3B-DAY.MS.MRG.3IMERG.20170312-S000000-E235959.V06.nc4.SUB.nc4"
#> [13] "3B-DAY.MS.MRG.3IMERG.20170313-S000000-E235959.V06.nc4.SUB.nc4"
#> [14] "3B-DAY.MS.MRG.3IMERG.20170314-S000000-E235959.V06.nc4.SUB.nc4"
#> [15] "3B-DAY.MS.MRG.3IMERG.20170315-S000000-E235959.V06.nc4.SUB.nc4"
#> [16] "3B-DAY.MS.MRG.3IMERG.20170316-S000000-E235959.V06.nc4.SUB.nc4"
#> [17] "3B-DAY.MS.MRG.3IMERG.20170317-S000000-E235959.V06.nc4.SUB.nc4"
#> [18] "3B-DAY.MS.MRG.3IMERG.20170318-S000000-E235959.V06.nc4.SUB.nc4"
#> [19] "3B-DAY.MS.MRG.3IMERG.20170319-S000000-E235959.V06.nc4.SUB.nc4"
#> [20] "3B-DAY.MS.MRG.3IMERG.20170320-S000000-E235959.V06.nc4.SUB.nc4"
#> [21] "3B-DAY.MS.MRG.3IMERG.20170321-S000000-E235959.V06.nc4.SUB.nc4"
#> [22] "3B-DAY.MS.MRG.3IMERG.20170322-S000000-E235959.V06.nc4.SUB.nc4"
#> [23] "3B-DAY.MS.MRG.3IMERG.20170323-S000000-E235959.V06.nc4.SUB.nc4"
#> [24] "3B-DAY.MS.MRG.3IMERG.20170324-S000000-E235959.V06.nc4.SUB.nc4"
#> [25] "3B-DAY.MS.MRG.3IMERG.20170325-S000000-E235959.V06.nc4.SUB.nc4"
#> [26] "3B-DAY.MS.MRG.3IMERG.20170326-S000000-E235959.V06.nc4.SUB.nc4"
#> [27] "3B-DAY.MS.MRG.3IMERG.20170327-S000000-E235959.V06.nc4.SUB.nc4"
#> [28] "3B-DAY.MS.MRG.3IMERG.20170328-S000000-E235959.V06.nc4.SUB.nc4"
#> [29] "3B-DAY.MS.MRG.3IMERG.20170329-S000000-E235959.V06.nc4.SUB.nc4"
#> [30] "3B-DAY.MS.MRG.3IMERG.20170330-S000000-E235959.V06.nc4.SUB.nc4"
#> [31] "3B-DAY.MS.MRG.3IMERG.20170331-S000000-E235959.V06.nc4.SUB.nc4"
```

Transformar os arquivos NetCDF para raster:

``` r
gpm_raster_list <- lapply(list.files(ncdf_path,
                                     pattern = "nc4*",
                                     full.names = TRUE),
                          ncdf_to_raster,
                          "precipitationCal")


gpm_stack <- raster::stack(gpm_raster_list)
```

Criação das duas tabelas, de referencia e sinulado:

``` r
tbl_ref <- files_to_table(files_path = pasta_estacoes,
                          files_pattern = "p-",
                          start_date = "2017-03-01",
                          end_date = "2017-03-31",
                          na_value = -99,
                          neg_to_zero = FALSE
                          )

tbl_sim <- tbl_from_references(raster_file = gpm_stack,
                               ref_points = file.path(pasta_estacoes, "pcp.txt"),
                               prefix_colname = "sim",
                               buffer = 1,
                               fun = mean)
```

Juntando as duas tabelas:

``` r
all_tabl <- cbind(tbl_ref, tbl_sim)
```

Comparando os dados da primeira estação:

``` r
hydroGOF::gof(sim = all_tabl$`p-1553003`,
               obs = all_tabl$`sim_p-1553003`)
#> Warning: 'rNSE' can not be computed: some elements in 'obs' are zero !
#> Warning: 'rd' can not be computed: some elements in 'obs' are zero !
#>           [,1]
#> ME        0.78
#> MAE      10.52
#> MSE     521.03
#> RMSE     22.83
#> NRMSE % 204.10
#> PBIAS %   9.90
#> RSR       2.04
#> rSD       2.73
#> NSE      -3.35
#> mNSE     -0.26
#> rNSE       NaN
#> d         0.67
#> md        0.50
#> rd         NaN
#> cp       -0.86
#> r         0.75
#> R2        0.57
#> bR2       0.33
#> KGE      -0.75
#> VE       -0.35
```
