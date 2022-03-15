
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
#> 1   9.79 10.76 20.44 16.36
#> 2  10.44 15.91 21.54 17.05
#> 3  13.44 16.14 19.09 12.93
#> 4  10.86 12.70 20.34 18.51
#> 5  14.95 14.88 20.93 15.93
#> 6  12.87 11.89 21.85 15.13
#> 7  13.86 18.51 18.42 16.40
#> 8  11.00 16.59 22.35 16.21
#> 9  10.47 16.52 20.42 17.53
#> 10 13.56 15.15 19.56 17.68
#> 11 13.52 16.35 20.96 19.78
#> 12 12.32 14.15 22.51 17.32
#> 13 10.14 12.15 20.13 13.92
#> 14 12.06 17.82 18.02 20.03
#> 15 13.76 15.90 17.12 16.66
#> 16 11.42 15.73 18.70 15.57
#> 17 13.75 14.24 21.65 15.20
#> 18 11.96 13.76 23.05 17.31
#> 19 12.39 15.36 20.80 16.60
#> 20 12.44 11.31 20.27 14.93
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
#>          PCC cval
#> pooled 91.67 0.11
#> 
#> Within subjects results:
#>       PCC cval
#> 1  100.00 0.04
#> 2  100.00 0.04
#> 3   66.67 0.38
#> 4  100.00 0.04
#> 5   83.33 0.17
#> 6   83.33 0.17
#> 7   66.67 0.38
#> 8   83.33 0.17
#> 9  100.00 0.04
#> 10 100.00 0.04
#> 11 100.00 0.04
#> 12 100.00 0.04
#> 13 100.00 0.04
#> 14  83.33 0.17
#> 15 100.00 0.04
#> 16  83.33 0.17
#> 17 100.00 0.04
#> 18 100.00 0.04
#> 19 100.00 0.04
#> 20  83.33 0.17
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
#> 2 NA  95 80
#> 3 NA  NA 95
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
#> A 96.67 0.07
#> B 93.33 0.09
#> C 86.67 0.17
#> D 90.00 0.12
#> 
#> Within subjects results:
#>   Individual    PCC cval
#> A          1 100.00 0.04
#> A          5  83.33 0.17
#> A          9 100.00 0.04
#> A         13 100.00 0.04
#> A         17 100.00 0.04
#> B          2 100.00 0.04
#> B          6  83.33 0.17
#> B         10 100.00 0.04
#> B         14  83.33 0.17
#> B         18 100.00 0.04
#> C          3  66.67 0.38
#> C          7  66.67 0.38
#> C         11 100.00 0.04
#> C         15 100.00 0.04
#> C         19 100.00 0.04
#> D          4 100.00 0.04
#> D          8  83.33 0.17
#> D         12 100.00 0.04
#> D         16  83.33 0.17
#> D         20  83.33 0.17
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
#> $A
#>    2   3   4
#> 1 80 100 100
#> 2 NA 100 100
#> 3 NA  NA 100
#> 
#> $B
#>    2   3   4
#> 1 80 100 100
#> 2 NA 100 100
#> 3 NA  NA  80
#> 
#> $C
#>     2   3   4
#> 1 100 100  80
#> 2  NA  80  60
#> 3  NA  NA 100
#> 
#> $D
#>    2   3   4
#> 1 80 100 100
#> 2 NA 100  60
#> 3 NA  NA 100
```
