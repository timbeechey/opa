#' Childhood growth data
#'
#' Distance from the the pituitary to the pteryo-maxillary fissure.
#'
#' @format ## `pituitary`
#' A data frame with 108 rows and 4 columns:
#' \describe{
#'  \item{distance}{distance in mm from the pituitary to the pteryo-maxillary fissure}
#'  \item{age}{age in years}
#'  \item{individual}{identifier for each individual}
#'  \item{sex}{sex of each individual}
#' }
#' @source Potthoff, R. F., & Roy, S. N. (1964). A Generalized Multivariate Analysis of Variance Model Useful Especially for Growth Curve Problems. Biometrika, 51(3/4), 313–326. https://doi.org/10.2307/2334137
"pituitary"


#' Bee data
#' 
#' Time between visits to a mechanical flower by bees in two experimental conditions.
#' 
#' @format ## `bees`
#' A data frame with 20 rows and 14 columns:
#' \describe{
#'  \item{bee}{Unique identifier for each individual bee.}
#'  \item{condition}{Factor identifying the two experimental conditions. In the frustrated condition bees were temporarily restricted from returning to the hive after collecting nectar, in the free condition bees were able to return to the hive without delay.}
#'  \item{t1-t12}{Time between visits to the mechanical flower (in seconds) in each of 12 consecutive trials.}
#' }
#' @source Grice, J. W., Craig, D. P. A., & Abramson, C. I. (2015). A Simple and Transparent Alternative to Repeated Measures ANOVA. SAGE Open, 5(3), 215824401560419. https://doi.org/10.1177/2158244015604192
"bees"