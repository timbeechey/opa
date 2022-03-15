
<!-- README.md is generated from README.Rmd. Please edit that file -->

# opa

<!-- badges: start -->

![](https://www.r-pkg.org/badges/version-ago/opa?color=orange)
![](https://cranlogs.r-pkg.org/badges/grand-total/opa)
<!-- badges: end -->

An R package for ordinal pattern analysis.

## Installation

opa can be installed from CRAN with:

``` r
install.packages("opa")
```

You can install the development version of opa from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("timbeechey/opa")
```

## Citation

To cite opa in your work you can use the output of:

``` r
citation(package = "opa")
```

## How ordinal pattern analysis works

Ordinal pattern analysis is similar to Kendall’s Tau. Whereas Kendall’s
tau is a measure of similarity between two data sets in terms of rank
ordering, ordinal pattern analysis is intended to quantify the match
between an hypothesis and patterns of individual-level data across
conditions or mesaurement instances.

Ordinal pattern analysis works by comparing the relative ordering of
pairs of observations and computing whether these pairwise relations are
matched by an hypothesis. Each pairwise ordered relation is classified
as an increases, a decrease, or as no change. These classifications are
encoded as 1, -1 and 0, respectively. An hypothesis of a monotonic
increase in the response variable across four experimental conditions
can be specified as:

``` r
h <- c(1, 2, 3, 4)
```

The hypothesis `h` encodes six pairwise relations, all increases:
`1 1 1 1 1 1`.

A row of individual data representing measurements across four
conditions, such as:

``` r
dat <- c(65.3, 68.8, 67.0, 73.1)
```

encodes the ordered pairwise relations `1 1 1 -1 1 1`. The percentage of
orderings which are correctly classified by the hypothesis (PCC) is the
main quantity of iterest in ordinal pattern analysis. Comparing `h` and
`dat`, the PCC is `5/6 = 0.833` or 83.3%. An hypothesis which generates
a greater PCC is preferred over an hypothesis which generates a lower
PCC for given data.

It is also possible to calculate a chance-value for a PCC which is equal
to the chance that a PCC at least as great as the PCC of the observed
data could occur as a result of a random ordering of the data. Chance
values can be computed using either a permutation test or a
randomization test.

## Using `opa`

``` r
library(opa)
```

A hypothesized relative ordering of the response variable across
conditions is specified with a numeric vector:

``` r
h <- c(1, 2, 4, 3)
```

The hypothesis can be visualized with the `plot_hypothesis()` function:

``` r
plot_hypothesis(h)
```

<img src="man/figures/README-plot_hypothesis-1.png" style="display: block; margin: auto;" />

Data should be in *wide* format with one column per measurement
condition and one row per individual:

``` r
dat <- data.frame(t1 = rnorm(20, mean = 12, sd = 2),
                  t2 = rnorm(20, mean = 15, sd = 2),
                  t3 = rnorm(20, mean = 20, sd = 2),
                  t4 = rnorm(20, mean = 17, sd = 2))
                  
round(dat, 2)
#>       t1    t2    t3    t4
#> 1  11.66 18.95 22.11 16.33
#> 2  11.85 14.23 20.20 15.34
#> 3  11.86 17.00 23.51 17.97
#> 4  13.56 14.73 20.68 17.45
#> 5  14.67 15.34 20.56 13.33
#> 6  12.18 17.77 21.94 16.11
#> 7  12.15 20.80 19.75 15.58
#> 8  10.90 16.06 19.82 15.74
#> 9  14.30 18.92 19.48 16.62
#> 10 12.27 12.98 22.06 18.41
#> 11  8.77 18.49 19.35 17.10
#> 12  9.85 14.07 17.97 19.28
#> 13 11.15 11.87 21.41 14.09
#> 14 13.86 13.52 23.71 17.31
#> 15 14.75 12.75 21.92 19.35
#> 16 11.53 17.25 21.35 17.10
#> 17 13.71 15.46 16.88 18.13
#> 18 11.76  9.66 21.17 16.39
#> 19 12.28 15.61 19.65 17.85
#> 20 10.25 12.09 21.09 16.69
```

An ordinal pattern analysis model to consider how the hypothesis `h`
matches each individual pattern of results in `dat` can be fitted using:

``` r
opamod <- opa(dat, h, cval_method = "exact")
```

A summary of the model output can be viewed using:

``` r
summary(opamod)
#> Ordinal Pattern Analysis of 4 observations for 20 individuals in 1 group 
#> 
#> Between subjects results:
#>         PCC cval
#> pooled 87.5 0.14
#> 
#> Within subjects results:
#>       PCC cval
#> 1   83.33 0.17
#> 2  100.00 0.04
#> 3  100.00 0.04
#> 4  100.00 0.04
#> 5   66.67 0.38
#> 6   83.33 0.17
#> 7   66.67 0.38
#> 8   83.33 0.17
#> 9   83.33 0.17
#> 10 100.00 0.04
#> 11  83.33 0.17
#> 12  83.33 0.17
#> 13 100.00 0.04
#> 14  83.33 0.17
#> 15  83.33 0.17
#> 16  83.33 0.17
#> 17  83.33 0.17
#> 18  83.33 0.17
#> 19 100.00 0.04
#> 20 100.00 0.04
#> 
#> PCCs were calculated for pairwise ordinal relationships using a difference threshold of 0.
#> Chance-values were calculated using the exact method.
```

Individual-level model output can be visualized using:

``` r
plot(opamod)
```

<img src="man/figures/README-plot_opamod1-1.png" style="display: block; margin: auto;" />

Pairwise comparisons of conditions are returned by `opa()` and can be
accessed with the `condition_pccs` method:

``` r
opamod$condition_pccs
#>    2   3  4
#> 1 85 100 95
#> 2 NA  95 60
#> 3 NA  NA 90
```

### Multiple groups

If the data consist of multiple groups a categorical grouping variable
can be passed with the `group` keyword to produce results for each group
within the data, in addition to individual results.

``` r
dat$group <- rep(c("A", "B", "C", "D"), 5)
dat$group <- factor(dat$group, levels = c("A", "B", "C", "D"))

opamod2 <- opa(dat[, 1:4], h, group = dat$group, cval_method = "exact")
```

The summary output displays results organised by group.

``` r
summary(opamod2)
#> Ordinal Pattern Analysis of 4 observations for 20 individuals in 4 groups 
#> 
#> Between subjects results:
#>     PCC cval
#> A 83.33 0.18
#> B 90.00 0.12
#> C 86.67 0.16
#> D 90.00 0.12
#> 
#> Within subjects results:
#>   Individual    PCC cval
#> A          1  83.33 0.17
#> A          5  66.67 0.38
#> A          9  83.33 0.17
#> A         13 100.00 0.04
#> A         17  83.33 0.17
#> B          2 100.00 0.04
#> B          6  83.33 0.17
#> B         10 100.00 0.04
#> B         14  83.33 0.17
#> B         18  83.33 0.17
#> C          3 100.00 0.04
#> C          7  66.67 0.38
#> C         11  83.33 0.17
#> C         15  83.33 0.17
#> C         19 100.00 0.04
#> D          4 100.00 0.04
#> D          8  83.33 0.17
#> D         12  83.33 0.17
#> D         16  83.33 0.17
#> D         20 100.00 0.04
#> 
#> PCCs were calculated for pairwise ordinal relationships using a difference threshold of 0.
#> Chance-values were calculated using the exact method.
```

Similarly, plotting the output shows individual PCCs and c-values by
group.

``` r
plot(opamod2)
```

<img src="man/figures/README-plot_opamod2-1.png" style="display: block; margin: auto;" />

Pairwise comparisons of conditions within each group are returned as a
list and can be accessed with the `condition_pccs` method:

``` r
opamod2$condition_pccs
#> [[1]]
#>     2   3  4
#> 1 100 100 80
#> 2  NA 100 40
#> 3  NA  NA 80
#> 
#> [[2]]
#>    2   3   4
#> 1 60 100 100
#> 2 NA 100  80
#> 3 NA  NA 100
#> 
#> [[3]]
#>    2   3   4
#> 1 80 100 100
#> 2 NA  80  60
#> 3 NA  NA 100
#> 
#> [[4]]
#>     2   3   4
#> 1 100 100 100
#> 2  NA 100  60
#> 3  NA  NA  80
```
