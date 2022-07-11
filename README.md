
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
#> 1  10.61 14.15 19.37 16.50
#> 2  10.02 16.42 21.04 15.17
#> 3  14.44 11.43 20.49 13.62
#> 4  10.52 12.05 23.08 20.58
#> 5   7.77 14.22 17.57 15.51
#> 6   9.19 16.51 17.88 15.69
#> 7  12.32 11.95 19.01 16.16
#> 8  10.09 19.56 15.57 18.09
#> 9  11.88 15.02 21.99 14.59
#> 10 13.30 14.80 23.54 16.11
#> 11  9.56 11.03 19.50 16.09
#> 12 14.13 17.04 18.67 15.26
#> 13 12.94 15.76 17.74 14.49
#> 14 11.62 14.64 19.88 16.23
#> 15 14.38 15.40 19.57 18.63
#> 16 12.96 13.55 20.48 13.99
#> 17 11.77 13.49 23.36 16.79
#> 18 11.97 15.43 20.49 15.79
#> 19 13.43 12.78 18.93 17.13
#> 20 12.13 15.91 22.82 18.20
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
#>        PCC cval
#> pooled  90 0.13
#> 
#> Within subjects results:
#>       PCC cval
#> 1  100.00 0.04
#> 2   83.33 0.17
#> 3   66.67 0.38
#> 4  100.00 0.04
#> 5  100.00 0.04
#> 6   83.33 0.17
#> 7   83.33 0.17
#> 8   50.00 0.62
#> 9   83.33 0.17
#> 10 100.00 0.04
#> 11 100.00 0.04
#> 12  83.33 0.17
#> 13  83.33 0.17
#> 14 100.00 0.04
#> 15 100.00 0.04
#> 16 100.00 0.04
#> 17 100.00 0.04
#> 18 100.00 0.04
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
#>     1  2  3 4
#> 1   -  -  - -
#> 2  85  -  - -
#> 3 100 95  - -
#> 4  95 70 95 -
condition_comparisons$cvals
#>       1     2     3 4
#> 1     -     -     - -
#> 2 0.575     -     - -
#> 3   0.5 0.525     - -
#> 4 0.525  0.65 0.525 -
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
#> B 93.33 0.09
#> C 86.67 0.16
#> D 86.67 0.18
#> 
#> Within subjects results:
#>   Individual    PCC cval
#> A          1 100.00 0.04
#> A          5 100.00 0.04
#> A          9  83.33 0.17
#> A         13  83.33 0.17
#> A         17 100.00 0.04
#> B          2  83.33 0.17
#> B          6  83.33 0.17
#> B         10 100.00 0.04
#> B         14 100.00 0.04
#> B         18 100.00 0.04
#> C          3  66.67 0.38
#> C          7  83.33 0.17
#> C         11 100.00 0.04
#> C         15 100.00 0.04
#> C         19  83.33 0.17
#> D          4 100.00 0.04
#> D          8  50.00 0.62
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
