
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
#> 1  15.03 16.16 20.13 16.87
#> 2   9.79 15.85 21.00 20.76
#> 3  11.43 15.12 20.41 15.42
#> 4  11.02 16.03 22.30 14.49
#> 5  11.95 18.35 18.37 19.08
#> 6  15.10 15.62 18.88 17.68
#> 7  10.68 17.91 18.23 18.29
#> 8  12.03 15.15 19.81 19.40
#> 9  12.46 15.15 19.37 16.55
#> 10  9.39 13.41 19.97 17.12
#> 11  8.14 17.32 18.26 13.96
#> 12 13.56 15.01 25.51 14.91
#> 13 10.95 11.16 22.56 15.54
#> 14 14.08 13.87 21.67 17.84
#> 15 13.34 14.10 18.52 14.65
#> 16 11.50 14.41 19.78 16.12
#> 17  8.49 13.84 16.40 18.13
#> 18 12.13 15.63 19.84 18.06
#> 19 10.48 16.85 19.96 14.96
#> 20 11.96 12.81 18.21 19.21
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
#>         PCC cval
#> pooled 92.5  0.1
#> 
#> Within subjects results:
#>       PCC cval
#> 1  100.00 0.04
#> 2  100.00 0.04
#> 3  100.00 0.04
#> 4   83.33 0.17
#> 5   83.33 0.17
#> 6  100.00 0.04
#> 7   83.33 0.17
#> 8  100.00 0.04
#> 9  100.00 0.04
#> 10 100.00 0.04
#> 11  83.33 0.17
#> 12  83.33 0.17
#> 13 100.00 0.04
#> 14  83.33 0.17
#> 15 100.00 0.04
#> 16 100.00 0.04
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
#>      2  3   4
#> 1 0.95  1 1.0
#> 2   NA  1 0.8
#> 3   NA NA 0.8
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
#> B 96.67 0.07
#> C 90.00 0.12
#> D 90.00 0.12
#> 
#> Within subjects results:
#>   Individual    PCC cval
#> A          1 100.00 0.04
#> A          5  83.33 0.17
#> A          9 100.00 0.04
#> A         13 100.00 0.04
#> A         17  83.33 0.17
#> B          2 100.00 0.04
#> B          6 100.00 0.04
#> B         10 100.00 0.04
#> B         14  83.33 0.17
#> B         18 100.00 0.04
#> C          3 100.00 0.04
#> C          7  83.33 0.17
#> C         11  83.33 0.17
#> C         15 100.00 0.04
#> C         19  83.33 0.17
#> D          4  83.33 0.17
#> D          8 100.00 0.04
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

Pairwise comparisons of conditions within each group are returned as a
list and can be accessed with the `condition_pccs` method:

``` r
opamod2$condition_pccs
#> [[1]]
#>    2  3   4
#> 1  1  1 1.0
#> 2 NA  1 1.0
#> 3 NA NA 0.6
#> 
#> [[2]]
#>     2  3 4
#> 1 0.8  1 1
#> 2  NA  1 1
#> 3  NA NA 1
#> 
#> [[3]]
#>    2  3   4
#> 1  1  1 1.0
#> 2 NA  1 0.6
#> 3 NA NA 0.8
#> 
#> [[4]]
#>    2  3   4
#> 1  1  1 1.0
#> 2 NA  1 0.6
#> 3 NA NA 0.8
```
