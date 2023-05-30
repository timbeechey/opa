# opa: An Implementation of Ordinal Pattern Analysis.
# Copyright (C) 2023 Timothy Beechey (tim.beechey@proton.me)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


#' Calculates PCCs and c-values based on pairwise comparison of conditions.
#' @param result an object of class "opafit" produced by a call to opa().
#' @param nreps an integer
#' @return \code{compare_conditions} returns a list with the following elements
#'
#' \describe{
#'   \item{pcc_mat}{A lower triangle matrix containing PCCs calculated from each
#'   pairing of data columns.}
#'   \item{cval_mat}{A lower triangle matrix containing c-values calculated from
#'   each pairing of data columns.}
#'   \item{pccs}{A vector containing PCCs calculated from each pairing of data.}
#'   \item{cvals}{A vector containing c-values calculated from each pairing of data.}
#'   \item{nreps}{The number of permutations used to calculate the c-values.}
#'   }
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11),
#'                   t4 = c(10, 5, 11, 12))
#' opamod <- opa(dat, 1:4)
#' compare_conditions(opamod)
#' @export
compare_conditions <- function(result, nreps = 1000L) {
  UseMethod("compare_conditions")
}


#' @export
compare_conditions.default <- function(result, nreps = 1000L) .NotYetImplemented()


#' @export
compare_conditions.opafit <- function(result, nreps = 1000L) {
  
  stopifnot("The object passed to compare_conditions() must be of class opafit"= class(result) == "opafit")

  dat <- result$data
  n_condition_pairs <- ((ncol(dat) - 1) * ncol(dat)) / 2
  pccs <- numeric(n_condition_pairs)
  cvals <- numeric(n_condition_pairs)

  n <- 1 # vector index
  # iterate through pairs of columns

  for (i in 1:(ncol(dat)-1)) {
    for (j in (i+1):ncol(dat)) {
      # get a pair of elements from the hypothesis
      h_subset <- result$hypothesis[c(i,j)]
      # get a pair of columns from the data
      dat_subset <- na.omit(dat[,c(i,j)])
      pairwise_result <- opa(dat_subset, h_subset,
                             diff_threshold = result$diff_threshold,
                             nreps = nreps)
      pccs[n] <- pairwise_result$group_pcc
      cvals[n] <- pairwise_result$group_cval
      n <- n + 1 # iterate vector index
    }
  }


  # create upper triangle matrices for PCCs and cvalues for pairs of conditions
  pcc_mat <- matrix(numeric(0), nrow = dim(result$data)[2], ncol = dim(result$data)[2])
  cval_mat <- matrix(numeric(0), nrow = dim(result$data)[2], ncol = dim(result$data)[2])
  # assign PCCs and c-values to matrix lower triangles
  pcc_mat[lower.tri(pcc_mat)] <- pccs
  cval_mat[lower.tri(cval_mat)] <- cvals
  structure(
    list(pccs_mat = pcc_mat,
         cvals_mat = cval_mat,
         pccs = pccs,
         cvals = cvals,
         nreps = nreps), 
    class = "pairwiseopafit")
}
