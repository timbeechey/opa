
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
#> 1  13.29 16.12 18.78 16.85
#> 2  13.38 15.88 19.87 15.40
#> 3  15.84 16.34 21.12 18.36
#> 4  12.72 13.58 17.09 18.46
#> 5  13.76 16.55 17.45 15.54
#> 6  10.67  9.30 22.78 13.61
#> 7  12.55  9.70 18.14 15.25
#> 8  14.15 13.66 17.68 19.41
#> 9  11.40 14.67 25.38 15.23
#> 10 11.73 15.33 19.01 17.71
#> 11 12.81 13.42 21.95 18.32
#> 12  9.95 15.25 17.19 21.52
#> 13 12.92 12.96 20.97 17.56
#> 14  8.35 15.86 20.53 15.03
#> 15 12.04 17.98 21.50 16.18
#> 16 13.05 14.01 19.71 14.14
#> 17  9.98 16.86 22.30 16.78
#> 18  8.12 16.81 24.03 18.07
#> 19 11.89 14.96 21.71 14.58
#> 20 12.53 17.08 20.96 19.66
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
#> 1  100.00 0.04
#> 2   83.33 0.17
#> 3  100.00 0.04
#> 4   83.33 0.17
#> 5   83.33 0.17
#> 6   83.33 0.17
#> 7   83.33 0.17
#> 8   66.67 0.38
#> 9  100.00 0.04
#> 10 100.00 0.04
#> 11 100.00 0.04
#> 12  83.33 0.17
#> 13 100.00 0.04
#> 14  83.33 0.17
#> 15  83.33 0.17
#> 16 100.00 0.04
#> 17  83.33 0.17
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
#>     1   2  3 4
#> 1   -   -  - -
#> 2  85   -  - -
#> 3 100 100  - -
#> 4 100  70 85 -
condition_comparisons$cvals
#>       1    2     3 4
#> 1     -    -     - -
#> 2 0.575    -     - -
#> 3   0.5  0.5     - -
#> 4   0.5 0.65 0.575 -
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
#> B 90.00 0.12
#> C 90.00 0.12
#> D 86.67 0.16
#> 
#> Within subjects results:
#>   Individual    PCC cval
#> A          1 100.00 0.04
#> A          5  83.33 0.17
#> A          9 100.00 0.04
#> A         13 100.00 0.04
#> A         17  83.33 0.17
#> B          2  83.33 0.17
#> B          6  83.33 0.17
#> B         10 100.00 0.04
#> B         14  83.33 0.17
#> B         18 100.00 0.04
#> C          3 100.00 0.04
#> C          7  83.33 0.17
#> C         11 100.00 0.04
#> C         15  83.33 0.17
#> C         19  83.33 0.17
#> D          4  83.33 0.17
#> D          8  66.67 0.38
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
