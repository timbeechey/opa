# opa

An R package for ordinal pattern analysis.

## Introduction

The opa package implements ordinal pattern analysis, as described by [Grice et al., (2015)](https://doi.org/10.1177/2158244015604192) and [Thorngate (1987)](https://doi.org/10.1016/S0166-4115(08)60083-7). Ordinal pattern analysis is a non-parametric statistical method suitable for analyzing timeseries and repeated measures data. It is a suitable replacement for many applications of repeated measures ANOVA.

## Installation

opa is not available on cran yet. The package can be installed from github using the devtools package.

```r
install.packages("devtools")

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

## Using opa

Considering four individuals who provide ratings in each of three experimental conditions on a scale from 0 to 12:

```r
dat <- data.frame(individual = c(1, 2, 3, 4),
                  t1 = c(9, 4, 10, 8),
                  t2 = c(8, 8, 12, 10),
                  t3 = c(8, 5, 10, 11))
```

