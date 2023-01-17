# opa: An Implementation of Ordinal Pattern Analysis.
# Copyright (C) 2022 Timothy Beechey (tim.beechey@proton.me)
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
#' @param nreps an integer, ignored if \code{cval_method = "exact"}
#' @param digits an integer indicating how many decimal places to round values.
#' @return \code{compare_conditions} returns a list with the following elements
#'
#' \describe{
#'   \item{pccs}{An upper triangle matrix containing PCCs calculated from each
#'   pairing of data columns, indicated by the matrix row and column names.}
#'   \item{cvals}{An upper triangle matrix containing c-values calculated from
#'   each pairing of data columns, indicated by the matrix row and column
#'   names.}
#'   }
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11),
#'                   t4 = c(10, 5, 11, 12))
#' opamod <- opa(dat, 1:4)
#' compare_conditions(opamod)
#' @export
compare_conditions <- function(result, nreps = 1000L, digits=3L) {
  UseMethod("compare_conditions")
}


#' @export
compare_conditions.default <- function(result, nreps = 1000L, digits = 3L) .NotYetImplemented()


#' @export
compare_conditions.opafit <- function(result, nreps = 1000L, digits = 3L) {
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
  pcc_mat[lower.tri(pcc_mat)] <- round(pccs, digits)
  cval_mat[lower.tri(cval_mat)] <- round(cvals, digits)
  # put "-" in empty cells in the upper triangle
  pcc_mat[upper.tri(pcc_mat, diag = TRUE)] <- "-"
  cval_mat[upper.tri(cval_mat, diag = TRUE)] <- "-"
  # display 0s as < 1/nreps. e.g. if nreps=1000, display 0 as <0.001
  cval_mat[cval_mat == "0"] <- paste0("<", toString(1/nreps))
  # convert matrices to data.frames for pretty printing
  pcc_df <- as.data.frame(pcc_mat)
  cval_df <- as.data.frame(cval_mat)
  # set column names to condition numbers
  colnames(pcc_df) <- 1:ncol(pcc_df)
  colnames(cval_df) <- 1:ncol(cval_df)
  list(pccs = pcc_df, cvals = cval_df)
}
