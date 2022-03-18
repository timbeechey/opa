
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
#> 1  13.01 13.86 17.39 18.08
#> 2  11.92 14.74 21.75 15.45
#> 3  12.67 15.72 22.08 18.13
#> 4  12.41 11.83 18.93 17.52
#> 5  13.70 16.35 21.68 18.97
#> 6  13.37 13.65 15.54 18.56
#> 7  11.83 12.35 18.35 15.82
#> 8  11.17 13.61 17.05 16.79
#> 9  11.17 14.39 19.98 15.64
#> 10  9.37 15.24 23.44 17.97
#> 11  8.32 13.83 20.07 15.19
#> 12 12.27 14.28 16.57 17.24
#> 13 11.64 14.33 18.31 13.09
#> 14  8.07 13.89 23.13 17.33
#> 15 12.15 17.41 18.20 18.66
#> 16 13.98 12.79 18.36 17.47
#> 17 11.87 18.90 19.11 17.72
#> 18 13.33 17.64 18.47 17.71
#> 19 10.53 13.65 15.66 18.43
#> 20 11.19 13.66 16.35 21.01
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
#> pooled 91.67  0.1
#> 
#> Within subjects results:
#>       PCC cval
#> 1   83.33 0.17
#> 2  100.00 0.04
#> 3  100.00 0.04
#> 4   83.33 0.17
#> 5  100.00 0.04
#> 6   83.33 0.17
#> 7  100.00 0.04
#> 8  100.00 0.04
#> 9  100.00 0.04
#> 10 100.00 0.04
#> 11 100.00 0.04
#> 12  83.33 0.17
#> 13  83.33 0.17
#> 14 100.00 0.04
#> 15  83.33 0.17
#> 16  83.33 0.17
#> 17  83.33 0.17
#> 18 100.00 0.04
#> 19  83.33 0.17
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
#>    2   3   4
#> 1 90 100 100
#> 2 NA 100  90
#> 3 NA  NA  70
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
#> A 90.00 0.12
#> B 96.67 0.07
#> C 93.33 0.09
#> D 86.67 0.14
#> 
#> Within subjects results:
#>   Individual    PCC cval
#> A          1  83.33 0.17
#> A          5 100.00 0.04
#> A          9 100.00 0.04
#> A         13  83.33 0.17
#> A         17  83.33 0.17
#> B          2 100.00 0.04
#> B          6  83.33 0.17
#> B         10 100.00 0.04
#> B         14 100.00 0.04
#> B         18 100.00 0.04
#> C          3 100.00 0.04
#> C          7 100.00 0.04
#> C         11 100.00 0.04
#> C         15  83.33 0.17
#> C         19  83.33 0.17
#> D          4  83.33 0.17
#> D          8 100.00 0.04
#> D         12  83.33 0.17
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
#>     2   3   4
#> 1 100 100 100
#> 2  NA 100  60
#> 3  NA  NA  80
#> 
#> $B
#>     2   3   4
#> 1 100 100 100
#> 2  NA 100 100
#> 3  NA  NA  80
#> 
#> $C
#>     2   3   4
#> 1 100 100 100
#> 2  NA 100 100
#> 3  NA  NA  60
#> 
#> $D
#>    2   3   4
#> 1 60 100 100
#> 2 NA 100 100
#> 3 NA  NA  60
```

## Acknowledgements

Development of `opa` was supported by a [Medical Research
Foundation](https://www.medicalresearchfoundation.org.uk/) Fellowship
(MRF-049-0004-F-BEEC-C0899).
