
<!-- README.md is generated from README.Rmd. Please edit that file -->

# opa <a href="https://timbeechey.github.io/opa/"></a>

<!-- badges: start -->

![](https://www.r-pkg.org/badges/version-ago/opa?color=orange)
![](https://cranlogs.r-pkg.org/badges/grand-total/opa)
[![R-CMD-check](https://github.com/timbeechey/opa/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/timbeechey/opa/actions/workflows/R-CMD-check.yaml)
[![codecov](https://codecov.io/gh/timbeechey/opa/graph/badge.svg?token=Q3ZI7BBMIK)](https://codecov.io/gh/timbeechey/opa)
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
# install.packages("remotes")
remotes::install_github("timbeechey/opa")
```

## Using `opa`

``` r
library(opa)
```

A hypothesized relative ordering of a response variable across
conditions is specified with a numeric vector:

``` r
(h <- hypothesis(c(1, 2, 4, 3), type = "pairwise"))
#> ********** Ordinal Hypothesis **********
#> Hypothesis type: pairwise 
#> Raw hypothesis:
#>  1 2 4 3 
#> Ordinal relations:
#>  1 1 1 1 1 -1 
#> N conditions: 4 
#> N hypothesised ordinal relations: 6 
#> N hypothesised increases: 5 
#> N hypothesised decreases: 1 
#> N hypothesised equalities: 0
```

The hypothesis can be visualised with the `plot()` function:

``` r
plot(h)
```

<img src="man/figures/README-plot_hypothesis-1.png" style="display: block; margin: auto;" />

Data should be in *wide* format with one column per measurement
condition and one row per individual:

``` r
set.seed(123)

dat <- data.frame(t1 = rnorm(20, mean = 12, sd = 2),
                  t2 = rnorm(20, mean = 15, sd = 2),
                  t3 = rnorm(20, mean = 20, sd = 2),
                  t4 = rnorm(20, mean = 17, sd = 2))
                  
round(dat, 2)
#>       t1    t2    t3    t4
#> 1  10.88 12.86 18.61 17.76
#> 2  11.54 14.56 19.58 16.00
#> 3  15.12 12.95 17.47 16.33
#> 4  12.14 13.54 24.34 14.96
#> 5  12.26 13.75 22.42 14.86
#> 6  15.43 11.63 17.75 17.61
#> 7  12.92 16.68 19.19 17.90
#> 8   9.47 15.31 19.07 17.11
#> 9  10.63 12.72 21.56 18.84
#> 10 11.11 17.51 19.83 21.10
#> 11 14.45 15.85 20.51 16.02
#> 12 12.72 14.41 19.94 12.38
#> 13 12.80 16.79 19.91 19.01
#> 14 12.22 16.76 22.74 15.58
#> 15 10.89 16.64 19.55 15.62
#> 16 15.57 16.38 23.03 19.05
#> 17 13.00 16.11 16.90 16.43
#> 18  8.07 14.88 21.17 14.56
#> 19 13.40 14.39 20.25 17.36
#> 20 11.05 14.24 20.43 16.72
```

An ordinal pattern analysis model of how the hypothesis `h` matches each
individual pattern of results in `dat` can be fitted using:

``` r
opamod <- opa(dat, h)
```

A summary of the model output can be viewed using:

``` r
summary(opamod)
#> Ordinal Pattern Analysis of 4 observations for 20 individuals in 1 group 
#> 
#> Between subjects results:
#>          PCC   cval
#> pooled 93.33 <0.001
#> 
#> Within subjects results:
#>       PCC cval
#> 1  100.00 0.04
#> 2  100.00 0.04
#> 3   83.33 0.17
#> 4  100.00 0.05
#> 5  100.00 0.04
#> 6   83.33 0.18
#> 7  100.00 0.04
#> 8  100.00 0.04
#> 9  100.00 0.04
#> 10  83.33 0.15
#> 11 100.00 0.04
#> 12  66.67 0.38
#> 13 100.00 0.04
#> 14  83.33 0.16
#> 15  83.33 0.18
#> 16 100.00 0.04
#> 17 100.00 0.05
#> 18  83.33 0.17
#> 19 100.00 0.04
#> 20 100.00 0.04
#> 
#> PCCs were calculated for pairwise ordinal relationships using a difference threshold of 0.
#> Chance-values were calculated from 1000 random orderings.
```

Individual-level model output can be plotted using:

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

print(condition_comparisons)
#> Pairwise PCCs:
#>     1   2  3 4
#> 1   -   -  - -
#> 2  90   -  - -
#> 3 100 100  - -
#> 4  95  80 95 -
#> 
#> Pairwise chance values:
#>        1      2      3 4
#> 1      -      -      - -
#> 2 <0.001      -      - -
#> 3 <0.001 <0.001      - -
#> 4 <0.001  0.002 <0.001 -
```

### Multiple groups

If the data consist of multiple groups a categorical grouping variable
can be passed with the `group` keyword to produce results for each group
within the data, in addition to individual results.

``` r
dat$group <- rep(c("A", "B", "C", "D"), each = 5)
dat$group <- factor(dat$group, levels = c("A", "B", "C", "D"))

opamod2 <- opa(dat[, 1:4], h, group = dat$group)
```

The summary output displays results organised by group.

``` r
summary(opamod2, digits = 3)
#> Ordinal Pattern Analysis of 4 observations for 20 individuals in 4 groups 
#> 
#> Between subjects results:
#>      PCC   cval
#> A 96.667 <0.001
#> B 93.333 <0.001
#> C 86.667  0.002
#> D 96.667 <0.001
#> 
#> Within subjects results:
#>     Individual     PCC  cval
#> A            1 100.000 0.034
#> A.1          2 100.000 0.035
#> A.2          3  83.333 0.178
#> A.3          4 100.000 0.044
#> A.4          5 100.000 0.047
#> B            6  83.333  0.18
#> B.1          7 100.000 0.037
#> B.2          8 100.000 0.048
#> B.3          9 100.000 0.043
#> B.4         10  83.333 0.158
#> C           11 100.000 0.049
#> C.1         12  66.667 0.392
#> C.2         13 100.000 0.043
#> C.3         14  83.333 0.158
#> C.4         15  83.333 0.156
#> D           16 100.000 0.055
#> D.1         17 100.000 0.047
#> D.2         18  83.333 0.158
#> D.3         19 100.000  0.05
#> D.4         20 100.000 0.044
#> 
#> PCCs were calculated for pairwise ordinal relationships using a difference threshold of 0.
#> Chance-values were calculated from 1000 random orderings.
```

Similarly, plotting the output shows individual PCCs and c-values by
group.

``` r
plot(opamod2)
```

<img src="man/figures/README-plot_opamod2-1.png" style="display: block; margin: auto;" />

### Comparing fit by group

The chance-value of the difference in group-level PCCs between any two
groups can be calculated using the `compare_groups()` function.

``` r
group_comp <- compare_groups(opamod2, "A", "B")
```

The difference in group-level PCCs along with the c-value of the
difference can then be checked:

``` r
summary(group_comp)
#> ********* Group Comparison **********
#> Group 1: A 
#> Group 2: B 
#> Group 1 PCC: 96.66667 
#> Group 2 PCC: 93.33333 
#> PCC difference: 3.333333 
#> cval: 0.776 
#> Comparison type: two-tailed
```

## Acknowledgements

Development of `opa` was supported by a [Medical Research
Foundation](https://www.medicalresearchfoundation.org.uk/) Fellowship
(MRF-049-0004-F-BEEC-C0899).
