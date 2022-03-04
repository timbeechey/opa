
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
#> 1  12.42 14.91 18.50 17.59
#> 2   9.71 15.10 22.88 19.51
#> 3  10.36 19.06 21.55 16.03
#> 4  10.48 18.37 24.43 20.32
#> 5  12.31 11.19 17.24 16.72
#> 6  12.89 13.51 22.61 17.57
#> 7  14.41  9.85 22.17 15.80
#> 8  13.73 14.29 16.06 18.07
#> 9   9.73 16.42 18.47 14.83
#> 10 14.91 15.58 20.19 18.27
#> 11 11.50 13.11 21.82 18.52
#> 12 13.09 12.92 19.89 17.80
#> 13 11.82 16.56 21.09 18.38
#> 14 10.76 14.91 24.62 15.97
#> 15 18.88 16.47 14.80 18.97
#> 16 13.38 15.22 22.06 17.81
#> 17  7.88 14.23 17.87 15.69
#> 18 12.48 18.05 18.41 17.44
#> 19 12.75 15.27 20.53 15.32
#> 20 14.79 14.12 23.12 18.61
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
#>        PCC cval
#> pooled  90 0.13
#> 
#> Individual-level results:
#>       PCC cval
#> 1  100.00 0.04
#> 2  100.00 0.04
#> 3   83.33 0.17
#> 4  100.00 0.04
#> 5   83.33 0.17
#> 6  100.00 0.04
#> 7   83.33 0.17
#> 8   83.33 0.17
#> 9   83.33 0.17
#> 10 100.00 0.04
#> 11 100.00 0.04
#> 12  83.33 0.17
#> 13 100.00 0.04
#> 14 100.00 0.04
#> 15  33.33 0.83
#> 16 100.00 0.04
#> 17 100.00 0.04
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
#> B 96.67 0.07
#> C 80.00 0.25
#> D 90.00 0.12
#> 
#> Individual-level results:
#>   Individual    PCC cval
#> A          1 100.00 0.04
#> A          5  83.33 0.17
#> A          9  83.33 0.17
#> A         13 100.00 0.04
#> A         17 100.00 0.04
#> B          2 100.00 0.04
#> B          6 100.00 0.04
#> B         10 100.00 0.04
#> B         14 100.00 0.04
#> B         18  83.33 0.17
#> C          3  83.33 0.17
#> C          7  83.33 0.17
#> C         11 100.00 0.04
#> C         15  33.33 0.83
#> C         19 100.00 0.04
#> D          4 100.00 0.04
#> D          8  83.33 0.17
#> D         12  83.33 0.17
#> D         16 100.00 0.04
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
