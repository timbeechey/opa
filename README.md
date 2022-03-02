<!-- badges: start -->
![](https://www.r-pkg.org/badges/version-ago/opa?color=orange) ![](https://cranlogs.r-pkg.org/badges/grand-total/opa) [![](https://cranlogs.r-pkg.org/badges/opa)](https://cran.r-project.org/package=opa)
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

A hypothesis of a monotonic increase in the dependent variable across a series of three measurements can be specified as:

```r
h <- c(1, 2, 3)
```

Data should be in _wide_ format with one column per measurement condition and one row per individual:

```r
set.seed(123)

dat <- data.frame(t1 = rnorm(10, mean = 10, sd = 2),
                  t2 = rnorm(10, mean = 12, sd = 2),
                  t3 = rnorm(10, mean = 15, sd = 2))
```

```
          t1        t2       t3
1  14.397621 12.238490 13.85205
2  12.624826 12.487375 16.23597
3   9.469710 14.464952 17.21970
4  11.086388 10.967872 16.41518
5   9.171320 10.014986 14.27269
6   9.047506 15.351394 15.11950
7   8.422794 11.117674 13.59081
8   8.810765 10.553868 13.56556
9  13.301815  9.527454 16.76930
10  9.891944  9.430569 12.96881
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
Ordinal Pattern Analysis of 3 observations for 10 individuals in 1 group 

Group-level results:
         PCC cval
pooled 76.67  0.4

Individual-level results:
      PCC cval
1   33.33 0.83
2   66.67 0.50
3  100.00 0.17
4   66.67 0.50
5  100.00 0.17
6   66.67 0.50
7  100.00 0.17
8  100.00 0.17
9   66.67 0.50
10  66.67 0.50

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
dat$group <- c(rep("A", 3), rep("B", 3), rep("C", 4))
dat$group <- factor(dat$group, levels = c("A", "B", "C"))
```

```
          t1        t2       t3 group
1  14.397621 12.238490 13.85205     A
2  12.624826 12.487375 16.23597     A
3   9.469710 14.464952 17.21970     A
4  11.086388 10.967872 16.41518     B
5   9.171320 10.014986 14.27269     B
6   9.047506 15.351394 15.11950     B
7   8.422794 11.117674 13.59081     C
8   8.810765 10.553868 13.56556     C
9  13.301815  9.527454 16.76930     C
10  9.891944  9.430569 12.96881     C
```

a categorical grouping variable can be passed with the `group` keyword to produce results for each group within the data, in addition to individual results.

```r
opamod2 <- opa(dat[, 1:3], h, group = dat$group, cval_method = "exact")
```

The summary output displays results organised by group.

```r
summary(opamod2)
```

```
Ordinal Pattern Analysis of 3 observations for 10 individuals in 3 groups 

Group-level results:
    PCC cval
A 66.67 0.50
B 77.78 0.39
C 83.33 0.33

Individual-level results:
  Individual    PCC cval
A          1  33.33 0.83
A          2  66.67 0.50
A          3 100.00 0.17
B          4  66.67 0.50
B          5 100.00 0.17
B          6  66.67 0.50
C          7 100.00 0.17
C          8 100.00 0.17
C          9  66.67 0.50
C         10  66.67 0.50

PCCs were calculated for pairwise ordinal relationships using a difference threshold of 0.
Chance-values were calculated using the exact method.
```

Similarly, plotting the output shows individual PCCs and c-values by group.

```r
plot(opamod2)
```

![Rplot03](https://user-images.githubusercontent.com/66388815/156462646-187a8fc0-4621-4c96-81f6-3d9dcc52727d.jpeg)


