
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
#> 1  12.72 13.80 17.88 17.93
#> 2  10.97 12.34 17.52 18.38
#> 3  11.53 14.59 19.70 20.06
#> 4   9.90 18.83 20.70 16.07
#> 5  10.27 16.91 21.77 19.31
#> 6  12.71 18.50 20.17 15.97
#> 7  10.69 16.31 17.39 16.50
#> 8  10.45 14.40 21.61 16.07
#> 9  13.37 14.29 22.10 18.65
#> 10 10.25 14.52 19.95 18.49
#> 11  8.59 13.50 21.84 13.20
#> 12 11.51 15.47 20.50 16.23
#> 13 13.20 14.69 26.71 19.17
#> 14 14.24 16.18 21.24 15.95
#> 15 13.33 16.46 20.02 16.43
#> 16 16.60 13.72 19.51 16.69
#> 17 10.95 14.77 18.51 13.50
#> 18  9.90 15.62 22.11 15.11
#> 19  9.10 13.00 21.44 15.63
#> 20 12.32 13.53 18.62 21.06
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
#> pooled  90 0.12
#> 
#> Within subjects results:
#>       PCC cval
#> 1   83.33 0.17
#> 2   83.33 0.17
#> 3   83.33 0.17
#> 4   83.33 0.17
#> 5  100.00 0.04
#> 6   83.33 0.17
#> 7  100.00 0.04
#> 8  100.00 0.04
#> 9  100.00 0.04
#> 10 100.00 0.04
#> 11  83.33 0.17
#> 12 100.00 0.04
#> 13 100.00 0.04
#> 14  83.33 0.17
#> 15  83.33 0.17
#> 16  83.33 0.17
#> 17  83.33 0.17
#> 18  83.33 0.17
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

### Pairwise comparison of measurement conditions

Pairwise comparisons of measurement conditions can be calculated by
applying the `compare_conditions()` function to an `opafit` object
produced by a call to `opa()`:

``` r
condition_comparisons <- compare_conditions(opamod)

condition_comparisons$pccs
#>     1   2  3 4
#> 1   -   -  - -
#> 2  95   -  - -
#> 3 100 100  - -
#> 4 100  65 80 -
condition_comparisons$cvals
#>       1     2   3 4
#> 1     -     -   - -
#> 2 0.525     -   - -
#> 3   0.5   0.5   - -
#> 4   0.5 0.675 0.6 -
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
#> B 86.67 0.14
#> C 90.00 0.12
#> D 90.00 0.12
#> 
#> Within subjects results:
#>   Individual    PCC cval
#> A          1  83.33 0.17
#> A          5 100.00 0.04
#> A          9 100.00 0.04
#> A         13 100.00 0.04
#> A         17  83.33 0.17
#> B          2  83.33 0.17
#> B          6  83.33 0.17
#> B         10 100.00 0.04
#> B         14  83.33 0.17
#> B         18  83.33 0.17
#> C          3  83.33 0.17
#> C          7 100.00 0.04
#> C         11  83.33 0.17
#> C         15  83.33 0.17
#> C         19 100.00 0.04
#> D          4  83.33 0.17
#> D          8 100.00 0.04
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

## Acknowledgements

Development of `opa` was supported by a [Medical Research
Foundation](https://www.medicalresearchfoundation.org.uk/) Fellowship
(MRF-049-0004-F-BEEC-C0899).
