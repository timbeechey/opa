<!-- badges: start -->
![](https://www.r-pkg.org/badges/version-ago/opa?color=orange)
[![R-CMD-check](https://github.com/timbeechey/opa/workflows/R-CMD-check/badge.svg)](https://github.com/timbeechey/opa/actions)
![](https://cranlogs.r-pkg.org/badges/grand-total/opa) [![](https://cranlogs.r-pkg.org/badges/opa)](https://cran.r-project.org/package=opa)
<!-- badges: end -->

# opa

An R package for ordinal pattern analysis.

## Introduction

The `opa` package implements ordinal pattern analysis, as described by [Grice et al., (2015)](https://doi.org/10.1177/2158244015604192) and [Thorngate (1987)](https://doi.org/10.1016/S0166-4115(08)60083-7). Ordinal pattern analysis is a non-parametric statistical method suitable for analyzing time series and repeated measures data. It is a suitable replacement for many applications of repeated measures ANOVA. Further details can be found in [Beechey (2022)](https://doi.org/10.17605/OSF.IO/W32DK).

## Installation

`opa` can be installed from CRAN using:

```r
install.packages("opa")
```

The latest development version can be installed with:

```r
devtools::install_github("timbeechey/opa")
```

## How ordinal pattern analysis works

Ordinal pattern analysis is similar to Kendall's Tau. Whereas Kendall's tau is a measure of similarity between two data sets in terms of rank ordering, ordinal pattern analysis is intended to quantify the match between an hypothesis and patterns of individual-level data across conditions or mesaurement instances.

Ordinal pattern analysis works by comparing the relative ordering of pairs of observations and computing whether these pairwise relations are matched by an hypothesis. Each pairwise ordered relation is classified as an increases, a decrease, or as no change. These classifications are encoded as 1, -1 and 0, respectively. An hypothesis of a monotonic increase in the response variable across four experimental conditions can be specified as:

```r
h <- c(1, 2, 3, 4)
```

The hypothesis `h` encodes six pairwise relations, all increases: `1 1 1 1 1 1`.

A row of individual data representing measurements across four conditions, such as:

```r
dat <- c(65.3, 68.8, 67.0, 73.1)
```

encodes the ordered pairwise relations `1 1 1 -1 1 1`. The percentage of orderings which are correctly classified by the hypothesis (PCC) is the main quantity of iterest in ordinal pattern analysis. Comparing `h` and `dat`, the PCC is `5/6 = 0.833` or 83.3%. An hypothesis which generates a greater PCC is preferred over an hypothesis which generates a lower PCC for given data.

It is also possible to calculate a chance-value for a PCC which is equal to the chance that a PCC at least as great as the PCC of the observed data could occur as a result of a random ordering of the data. Chance values can be computed using either a permutation test or a randomization test.

## Using `opa`

A hypothesized relative ordering of the response variable across conditions is specified with a numeric vector:

```r
h <- c(1, 2, 4, 3)
```

The hypothesis can be visualized with the `plot_hypothesis()` function:

```r
plot_hypothesis(h)
```

Data should be in _wide_ format with one column per measurement condition and one row per individual:

```r
set.seed(123)

dat <- data.frame(t1 = rnorm(20, mean = 12, sd = 2),
                  t2 = rnorm(20, mean = 15, sd = 2),
                  t3 = rnorm(20, mean = 20, sd = 2),
                  t4 = rnorm(20, mean = 17, sd = 2))
                  
round(dat, 2)
```

```
      t1    t2    t3    t4
1  15.20 16.70 24.00 16.30
2  11.82 14.11 20.13 18.41
3  14.16 15.35 23.73 16.79
4  13.26 15.15 17.30 14.48
5  11.77 15.86 20.04 20.37
6   8.93 15.05 22.50 18.82
7  10.96 11.67 18.57 17.47
8  11.02 16.47 18.49 19.44
9  12.09 15.77 18.12 14.32
10 14.60 14.47 17.89 18.32
11 16.59 15.24 19.13 15.95
12 15.10 15.27 20.66 18.37
13 11.73 15.44 15.97 16.88
14  8.49 18.28 20.42 18.27
15 11.22 14.56 22.47 19.67
16 12.18 15.34 24.08 17.01
17 13.69 17.34 22.60 19.04
18 13.93 17.11 21.51 14.62
19 13.37 17.29 16.55 15.56
20  9.21 13.85 18.80 20.04
```

An ordinal pattern analysis model to consider how the hypothesis `h` matches each individual pattern of results in `dat` can be fitted using:

```r
opamod <- opa(dat, h, cval_method = "exact")
```

A summary of the model output can be viewed using:

```r
summary(opamod)
```

```
Ordinal Pattern Analysis of 4 observations for 20 individuals in 1 group 

Group-level results:
        PCC cval
pooled 87.5 0.15

Individual-level results:
      PCC cval
1   83.33 0.17
2  100.00 0.04
3  100.00 0.04
4   83.33 0.17
5   83.33 0.17
6  100.00 0.04
7  100.00 0.04
8   83.33 0.17
9   83.33 0.17
10  66.67 0.38
11  66.67 0.38
12 100.00 0.04
13  83.33 0.17
14  83.33 0.17
15 100.00 0.04
16 100.00 0.04
17 100.00 0.04
18  83.33 0.17
19  66.67 0.38
20  83.33 0.17

PCCs were calculated for pairwise ordinal relationships using a difference threshold of 0.
Chance-values were calculated using the exact method.
```

Individual-level model output can be visualized using:

```r
plot(opamod)
```

![Rplot01](https://user-images.githubusercontent.com/66388815/156462419-2497aba2-f8df-42ae-a04e-7667f22b817b.jpeg)



### Multiple groups 

If the data consist of multiple groups:

```r
dat$group <- rep(c("A", "B", "C", "D"), 5)
dat$group <- factor(dat$group, levels = c("A", "B", "C", "D"))
```

a categorical grouping variable can be passed with the `group` keyword to produce results for each group within the data, in addition to individual results.

```r
opamod2 <- opa(dat[, 1:4], h, group = dat$group, cval_method = "exact")
```

The summary output displays results organised by group.

```r
summary(opamod2)
```

```
Ordinal Pattern Analysis of 4 observations for 20 individuals in 4 groups 

Group-level results:
    PCC cval
A 90.00 0.13
B 80.00 0.21
C 93.33 0.09
D 93.33 0.09

Individual-level results:
  Individual    PCC cval
A          1 100.00 0.04
A          5  83.33 0.17
A          9 100.00 0.04
A         13 100.00 0.04
A         17  66.67 0.38
B          2  83.33 0.17
B          6  66.67 0.38
B         10  83.33 0.17
B         14  83.33 0.17
B         18  83.33 0.17
C          3  83.33 0.17
C          7 100.00 0.04
C         11 100.00 0.04
C         15  83.33 0.17
C         19 100.00 0.04
D          4 100.00 0.04
D          8  83.33 0.17
D         12  83.33 0.17
D         16 100.00 0.04
D         20 100.00 0.04

PCCs were calculated for pairwise ordinal relationships using a difference threshold of 0.
Chance-values were calculated using the exact method.
```

Similarly, plotting the output shows individual PCCs and c-values by group.

```r
plot(opamod2)
```

![Rplot03](https://user-images.githubusercontent.com/66388815/156462646-187a8fc0-4621-4c96-81f6-3d9dcc52727d.jpeg)


