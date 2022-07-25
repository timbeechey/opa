
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
#> 1  11.04 13.78 15.93 13.12
#> 2  12.03 12.04 17.83 14.08
#> 3  10.03 13.32 21.68 17.34
#> 4  12.06 14.47 22.88 20.01
#> 5  11.37 16.38 22.98 18.17
#> 6   7.19 16.88 22.42 15.44
#> 7  11.80 11.94 18.77 20.44
#> 8   8.87 16.93 19.14 18.49
#> 9  13.31 15.42 22.00 16.03
#> 10 14.21 15.56 18.84 14.62
#> 11 10.69 12.78 19.66 14.94
#> 12 12.68 20.89 18.54 20.24
#> 13  9.47 15.98 17.26 17.13
#> 14 12.23 12.28 20.97 18.91
#> 15 12.68 14.02 20.16 16.83
#> 16  6.93 11.13 20.00 17.67
#> 17 12.15 14.44 16.17 18.34
#> 18 16.26 11.37 19.93 15.72
#> 19 10.30 13.57 21.65 18.03
#> 20 10.90 15.63 22.88 19.20
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
#> pooled 91.67 0.12
#> 
#> Within subjects results:
#>       PCC cval
#> 1   83.33 0.17
#> 2  100.00 0.04
#> 3  100.00 0.04
#> 4  100.00 0.04
#> 5  100.00 0.04
#> 6   83.33 0.17
#> 7   83.33 0.17
#> 8  100.00 0.04
#> 9  100.00 0.04
#> 10  83.33 0.17
#> 11 100.00 0.04
#> 12  50.00 0.62
#> 13 100.00 0.04
#> 14 100.00 0.04
#> 15 100.00 0.04
#> 16 100.00 0.04
#> 17  83.33 0.17
#> 18  66.67 0.38
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

### Pairwise comparison of measurement conditions

Pairwise comparisons of measurement conditions can be calculated by
applying the `compare_conditions()` function to an `opafit` object
produced by a call to `opa()`:

``` r
condition_comparisons <- compare_conditions(opamod)

condition_comparisons$pccs
#>     1  2  3 4
#> 1   -  -  - -
#> 2  95  -  - -
#> 3 100 95  - -
#> 4  95 80 85 -
condition_comparisons$cvals
#>       1     2     3 4
#> 1     -     -     - -
#> 2 0.525     -     - -
#> 3   0.5 0.525     - -
#> 4 0.525   0.6 0.575 -
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
#> A 93.33 0.09
#> B 86.67 0.16
#> C 96.67 0.07
#> D 90.00 0.16
#> 
#> Within subjects results:
#>   Individual    PCC cval
#> A          1  83.33 0.17
#> A          5 100.00 0.04
#> A          9 100.00 0.04
#> A         13 100.00 0.04
#> A         17  83.33 0.17
#> B          2 100.00 0.04
#> B          6  83.33 0.17
#> B         10  83.33 0.17
#> B         14 100.00 0.04
#> B         18  66.67 0.38
#> C          3 100.00 0.04
#> C          7  83.33 0.17
#> C         11 100.00 0.04
#> C         15 100.00 0.04
#> C         19 100.00 0.04
#> D          4 100.00 0.04
#> D          8 100.00 0.04
#> D         12  50.00 0.62
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
