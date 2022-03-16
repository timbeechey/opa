# opa: An Implementation of Ordinal Pattern Analysis.
# Copyright (C) 2022 Timothy Beechey (tim.beechey@protonmail.com)
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


row_pcc <- function(xs, h, pairing_type, diff_threshold) {

  # if there are NAs in the data row, skip corresponding
  # values in the hypothesis
  if (any(is.na(xs))) {
    hypothesis_no_nas <- conform(xs, h)
  } else {
    hypothesis_no_nas <- h
  }

  # get ordinal relations in hypothesis and data row
  hypothesis_ordering <- c_ordering(hypothesis_no_nas, pairing_type, 0)
  row_ordering <- c_ordering(stats::na.omit(xs), pairing_type, diff_threshold)

  # compare ordinal relations in hypothesis and data row
  match <- row_ordering == hypothesis_ordering

  # get match vector that is same length regardless of NAs to construct matrix of matches
  match_with_nas <- c_ordering(h, "pairwise", 0) == c_ordering(xs, "pairwise", diff_threshold)

  n_pairs <- length(match)
  correct_pairs <- sum(match)
  pcc <- mean(match) * 100

  list(match = match_with_nas,
       pcc = pcc,
       n_pairs = n_pairs,
       correct_pairs = correct_pairs)
}

pcc <- function(dat, h, pairing_type, diff_threshold) {

  individual_pccs <- numeric(dim(dat)[1])
  total_pairs <- 0
  correct_pairs <- 0

  match_mat <- matrix(numeric(0), nrow = dim(dat)[1], ncol = length(c_ordering(h, "pairwise", 0)))

  for (r in 1:dim(dat)[1]) {
    result <- row_pcc(dat[r,], h, pairing_type, diff_threshold)
    match_mat[r,] <- result$match
    individual_pccs[r] <- result$pcc
    total_pairs <- total_pairs + result$n_pairs
    correct_pairs <- correct_pairs + result$correct_pairs
  }

  group_pcc <- (correct_pairs / total_pairs) * 100

  list(group_pcc = group_pcc,
       individual_pccs = individual_pccs,
       matches = match_mat,
       total_pairs = total_pairs,
       correct_pairs = correct_pairs,
       data = dat,
       hypothesis = h,
       pairing_type = pairing_type,
       diff_threshold = diff_threshold)
}

condition_pair_pccs <- function(pcc_out) {
  # create an upper triangle matrix of PCCs for pairs of conditions
  mat <- matrix(numeric(0), nrow = dim(pcc_out$data)[2], ncol = dim(pcc_out$data)[2]) # pre-size matrix
  # calculate PCCs and assign to lower triangle
  pccs <- (apply(pcc_out$matches, 2, mean, na.rm = TRUE) * 100)
  mat[lower.tri(mat)] <- pccs
  # transpose to upper triangle such that rows are from cond and cols are to cond
  mat <- t(mat)
  # drop the first column and last row which are all NAs
  mat <- mat[-nrow(mat),]
  mat <- mat[,-1]
  # assign meaningful row and column names
  colnames(mat) <- 2:(ncol(mat) + 1)
  rownames(mat) <- 1:nrow(mat)
  list(pccs=pccs, mat=mat)
}
