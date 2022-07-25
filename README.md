
<!-- README.md is generated from README.Rmd. Please edit that file -->

``` r
palette("Set 2")
palette(adjustcolor(palette(), alpha.f = 0.7))
```

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
#> 1  11.54 15.05 22.12 13.97
#> 2  14.61 14.54 21.87 15.77
#> 3  11.65 18.11 20.79 16.74
#> 4  10.70 15.28 21.19 16.47
#> 5  10.78 17.14 23.81 16.86
#> 6   9.19 14.09 17.10 14.16
#> 7   9.88 15.02 20.02 15.11
#> 8  13.72 13.34 20.47 17.42
#> 9  15.99 15.15 20.17 15.82
#> 10 13.59 13.73 17.32 16.84
#> 11 12.30 14.82 22.07 17.09
#> 12 12.60 16.29 19.50 19.58
#> 13 11.93 15.27 18.59 13.73
#> 14 12.83 17.27 19.76 18.11
#> 15  6.19 12.83 20.72 16.97
#> 16 12.01 13.19 19.61 16.43
#> 17 11.55 13.76 24.66 15.25
#> 18 13.89 17.24 23.04 17.14
#> 19 13.70 14.85 20.33 14.18
#> 20  7.19 17.87 20.21 19.64
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
#> pooled 90.83 0.11
#> 
#> Within subjects results:
#>       PCC cval
#> 1   83.33 0.17
#> 2   83.33 0.17
#> 3   83.33 0.17
#> 4  100.00 0.04
#> 5   83.33 0.17
#> 6  100.00 0.04
#> 7  100.00 0.04
#> 8   83.33 0.17
#> 9   66.67 0.38
#> 10 100.00 0.04
#> 11 100.00 0.04
#> 12  83.33 0.17
#> 13  83.33 0.17
#> 14 100.00 0.04
#> 15 100.00 0.04
#> 16 100.00 0.04
#> 17 100.00 0.04
#> 18  83.33 0.17
#> 19  83.33 0.17
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

### Pairwise comparison of measurement conditions

Pairwise comparisons of measurement conditions can be calculated by
applying the `compare_conditions()` function to an `opafit` object
produced by a call to `opa()`:

``` r
condition_comparisons <- compare_conditions(opamod)

condition_comparisons$pccs
#>     1   2  3 4
#> 1   -   -  - -
#> 2  85   -  - -
#> 3 100 100  - -
#> 4  95  70 95 -
condition_comparisons$cvals
#>       1    2     3 4
#> 1     -    -     - -
#> 2 0.575    -     - -
#> 3   0.5  0.5     - -
#> 4 0.525 0.65 0.525 -
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
#> B 93.33 0.09
#> C 93.33 0.09
#> D 93.33 0.09
#> 
#> Within subjects results:
#>   Individual    PCC cval
#> A          1  83.33 0.17
#> A          5  83.33 0.17
#> A          9  66.67 0.38
#> A         13  83.33 0.17
#> A         17 100.00 0.04
#> B          2  83.33 0.17
#> B          6 100.00 0.04
#> B         10 100.00 0.04
#> B         14 100.00 0.04
#> B         18  83.33 0.17
#> C          3  83.33 0.17
#> C          7 100.00 0.04
#> C         11 100.00 0.04
#> C         15 100.00 0.04
#> C         19  83.33 0.17
#> D          4 100.00 0.04
#> D          8  83.33 0.17
#> D         12  83.33 0.17
#> D         16 100.00 0.04
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

## Acknowledgements

Development of `opa` was supported by a [Medical Research
Foundation](https://www.medicalresearchfoundation.org.uk/) Fellowship
(MRF-049-0004-F-BEEC-C0899).
