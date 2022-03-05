
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
#> 1  14.13 13.92 22.06 18.31
#> 2  14.70 16.45 24.32 20.44
#> 3   9.82 14.76 19.56 20.56
#> 4  12.45 11.56 17.23 17.21
#> 5  12.19 16.84 18.56 17.29
#> 6  12.63 15.58 23.22 13.34
#> 7  10.32 15.56 19.16 15.83
#> 8  14.42 13.64 19.91 17.18
#> 9  10.12 13.31 15.49 16.98
#> 10 13.23 17.15 20.54 19.11
#> 11 12.04 15.12 18.43 18.05
#> 12 14.78 16.27 19.07 16.06
#> 13 10.01 12.27 23.63 15.94
#> 14 10.11 12.59 18.51 17.77
#> 15 10.79 15.94 22.91 18.23
#> 16 11.70 14.01 17.82 18.04
#> 17  9.24 15.10 18.40 17.52
#> 18  9.33 17.77 20.40 16.03
#> 19 10.42 16.42 21.21 18.77
#> 20 13.95 15.85 20.50 17.76
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
#> Group-level results:
#>         PCC cval
#> pooled 92.5  0.1
#> 
#> Individual-level results:
#>       PCC cval
#> 1   83.33 0.17
#> 2  100.00 0.04
#> 3   83.33 0.17
#> 4   83.33 0.17
#> 5  100.00 0.04
#> 6   83.33 0.17
#> 7  100.00 0.04
#> 8   83.33 0.17
#> 9   83.33 0.17
#> 10 100.00 0.04
#> 11 100.00 0.04
#> 12  83.33 0.17
#> 13 100.00 0.04
#> 14 100.00 0.04
#> 15 100.00 0.04
#> 16  83.33 0.17
#> 17 100.00 0.04
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
#> Group-level results:
#>     PCC cval
#> A 93.33 0.09
#> B 93.33 0.09
#> C 96.67 0.07
#> D 86.67 0.14
#> 
#> Individual-level results:
#>   Individual    PCC cval
#> A          1  83.33 0.17
#> A          5 100.00 0.04
#> A          9  83.33 0.17
#> A         13 100.00 0.04
#> A         17 100.00 0.04
#> B          2 100.00 0.04
#> B          6  83.33 0.17
#> B         10 100.00 0.04
#> B         14 100.00 0.04
#> B         18  83.33 0.17
#> C          3  83.33 0.17
#> C          7 100.00 0.04
#> C         11 100.00 0.04
#> C         15 100.00 0.04
#> C         19 100.00 0.04
#> D          4  83.33 0.17
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
