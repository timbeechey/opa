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



#' Fit an ordinal pattern analysis model
#'
#' \code{opa} is used to fit ordinal pattern analysis models by computing the
#' percentage of pair orderings in each row of data which are matched by
#' corresponding pair orderings in an hypothesis, in addition the chance of a
#' permutation of the data producing a percentage match as great.
#'
#' @details
#' Data is expected in \strong{wide} format with 1 row per individual and 1
#' column per measurement condition. Data must contain only columns consisting
#' of numerical values of the \emph{dependent} variable.
#'
#' The length of the \code{hypothesis} must be equal to the number of columns in
#' the dependent variable data.frame \code{dat}.
#'
#' Any \emph{independent} variable must be passed separately as a vector with the
#' \code{group} keyword. The grouping vector must be a \emph{factor}.
#'
#' \code{pairing_type} must be either "pairwise" or "adjacent". The "pairwise"
#' option considered the relative ordering of every pair of observations in
#' the data and every pair of elements of the hypothesis. The "adjacent" option
#' considered the ordering of adjacent pairs only. If unspecified, the default
#' is "pairwise".
#'
#' \code{diff_threshold} may be a positive integer or double. If unspecified
#' a default zero threshold is used. The \code{diff_threshold} is never applied
#' to the hypothesis.
#'
#' \code{cval_method} is either "stochastic" or "exact". The "stochastic" option
#' generates random reorderings of each data row. The "exact" method generates
#' every possible permutation of each data row. Care must be taken using the
#' "exact" method since the number of permutations is the factorial of the
#' number of columns in the data. For large numbers of data columns it is best
#' to use the default "stochastic" method to sample orderings.
#'
#' \code{nreps} specifies the number of random reorderigs to generate when
#' using the "stochastic" method for computing chance values. The default
#' value of \code{nreps} is 1000. If the \code{cval_method = "exact"} option
#' is specified, \code{nreps} is ignored.
#'
#' @references
#' Grice, J. W., Craig, D. P. A., & Abramson, C. I. (2015). A Simple and
#' Transparent Alternative to Repeated Measures ANOVA. SAGE Open, 5(3),
#' 215824401560419. <https://doi.org/10.1177/2158244015604192>
#'
#' Thorngate, W. (1987). Ordinal Pattern Analysis: A Method for Assessing
#' Theory-Data Fit. Advances in Psychology, 40, 345–364.
#' <https://doi.org/10.1016/S0166-4115(08)60083-7>
#'
#' @param dat a data frame
#' @param hypothesis a numeric vector
#' @param group an optional factor vector
#' @param pairing_type a string
#' @param diff_threshold a positive integer or floating point number
#' @param cval_method a string, either "exact" or "stochastic
#' @param nreps an integer, ignored if \code{cval_method = "exact"}
#' @param progress a boolean indicating whether to display a progress bar
#' @return \code{opa} returns an object of class "opafit".
#'
#' An object of class "opafit" is a list containing the folllowing components:
#' \describe{
#'   \item{group_pcc}{the percentage of pairwise orderings from all pooled data
#'   rows which were correctly classified by the hypothesis.}
#'   \item{individual_pccs}{a vector containing the percentage of pairwise
#'   orderings that were correctly classified by the hypothesis for each data
#'   row.}
#'   \item{condition_pccs}{a matrix containing PCCs for each pair of
#'   conditions, or a list containing such a matrix for each group level if a
#'   grouping variable is passed to \code{opa}}
#'   \item{correct_pairs}{an integer representing the number of pairwise
#'   orderings pooled across all data rows that were correctly classified by the
#'   hypothesis.}
#'   \item{total_pairs}{an integer, the number of pair orderings contained in
#'   the data.}
#'   \item{group_cval}{the group-level chance value.}
#'   \item{individual_cvals}{a vector containing chance values for each data
#'   row}
#'   \item{n_permutations}{an integer, the number of permutations of the data
#'   used to compute chance values.}
#'   \item{pccs_geq_observed}{an integer, the number of permutations which
#'   generated PCC values at least as great as the PCC of the observed data.}
#'   \item{pcc_replicates}{a matrix containing PCC values, one column per data
#'   row, computed from all permutations used to compute chance values. }
#'   \item{call}{the matched call}
#'   }
#' @examples
#' dat <- data.frame(group = c("a", "b", "a", "b"),
#'                   t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11))
#' dat$group <- factor(dat$group, levels = c("a", "b"))
#' opamod <- opa(dat[,2:4], 1:3)
#' opa(dat[,2:4], 1:3)
#' opa(dat[,2:4], 1:3, nreps = 500)
#' opa(dat[,2:4], 1:3, cval_method = "exact")
#' opa(dat[,2:4], 1:3, pairing_type = "adjacent")
#' opa(dat[,2:4], 1:3, diff_threshold = 1)
#' opa(dat[,2:4], 1:3, group = dat$group)
#' @export
opa <- function(dat, hypothesis, group = NULL, pairing_type = "pairwise",
                diff_threshold = 0, cval_method = "stochastic", nreps = 1000L,
                progress = FALSE) {
  # verify the arguments
  assertthat::assert_that(assertthat::are_equal(dim(dat)[2], length(hypothesis)))
  assertthat::assert_that(pairing_type %in% c("pairwise", "adjacent"))
  assertthat::assert_that(cval_method %in% c("exact", "stochastic"))
  assertthat::assert_that(class(diff_threshold) %in% c("integer", "numeric"))
  assertthat::assert_that(assertthat::is.count(nreps))
  assertthat::assert_that(assertthat::is.scalar(diff_threshold))
  assertthat::assert_that(assertthat::is.count(nreps))
  assertthat::assert_that(assertthat::are_equal(diff_threshold >= 0, TRUE))

  if (is.null(group)) { # single groups
    # convert the data.frame input to a matrix for speed
    mat <- as.matrix(dat)

    pccs <- pcc(mat, hypothesis, pairing_type, diff_threshold)
    if (cval_method == "exact") {
      cvalues <- cval_exact(pccs, progress)
    } else if (cval_method == "stochastic") {
      cvalues <- cval_stochastic(pccs, nreps, progress)
    }

    # create an upper triangle matrix of PCCs for pairs of conditions
    cond_pccs <- condition_pair_pccs(pccs)

    return(
      structure(
        list(group_pcc = pccs$group_pcc,
             individual_pccs = pccs$individual_pccs,
             condition_pccs = cond_pccs$mat,
             correct_pairs = pccs$correct_pairs,
             total_pairs = pccs$total_pairs,
             group_cval = cvalues$group_cval,
             individual_cvals = cvalues$individual_cvals,
             n_permutations = cvalues$total_perms,
             pccs_geq_observed = cvalues$perm_pccs_geq_obs_pcc,
             pcc_replicates = cvalues$pcc_replicates,
             call = match.call(),
             hypothesis = hypothesis,
             pairing_type = pairing_type,
             diff_threshold = diff_threshold,
             cval_method = cval_method,
             data = dat,
             groups = group),
        class = "opafit"))

  } else { # multiple groups
    assertthat::assert_that(is.factor(group) == TRUE, msg = "The grouping vector must be a factor.")
    groups <- levels(group)
    group_pccs <- numeric(nlevels(group))
    group_cvals <- numeric(nlevels(group))
    individual_pccs <- numeric(0)
    individual_cvals <- numeric(0)
    individual_idx <- numeric(0)
    group_labels_vec <- character(0)
    correct_pairs <- 0
    total_pairs <- 0
    n_permutations <- 0
    pccs_geq_observed <- 0
    pcc_replicates <- vector(nlevels(group), mode="list")
    cond_pccs <- vector(nlevels(group), mode="list")

    for (i in 1:nlevels(group)) {
      idx <- which(group == groups[i])
      subgroup_dat <- dat[idx,]
      subgroup_mat <- as.matrix(subgroup_dat)
      subgroup_pccs <- pcc(subgroup_mat, hypothesis, pairing_type, diff_threshold)

      # create an upper triangle matrix of PCCs for pairs of conditions
      cond_pccs[[i]] <- condition_pair_pccs(subgroup_pccs)$mat

      if (progress == TRUE)
        cat("Fitting group", i, "of", nlevels(group), "\n")
      if (cval_method == "exact") {
        subgroup_cvalues <- cval_exact(subgroup_pccs, progress)
      } else if (cval_method == "stochastic") {
        subgroup_cvalues <- cval_stochastic(subgroup_pccs, nreps, progress)
      }
      group_pccs[i] <- subgroup_pccs$group_pcc
      correct_pairs <- correct_pairs + subgroup_pccs$correct_pairs
      total_pairs <- total_pairs + subgroup_pccs$total_pairs
      group_cvals[i] <- subgroup_cvalues$group_cval
      pcc_replicates[[i]] <- subgroup_cvalues$pcc_replicates
      n_permutations <- n_permutations + subgroup_cvalues$total_perms
      pccs_geq_observed <- pccs_geq_observed + subgroup_cvalues$perm_pccs_geq_obs_pcc
      individual_idx <- append(individual_idx, idx)
      group_labels_vec <- append(group_labels_vec, rep(groups[i], length(idx)))
      individual_pccs <- append(individual_pccs, subgroup_pccs$individual_pccs)
      individual_cvals <- append(individual_cvals, subgroup_cvalues$individual_cvals)
    }
    names(group_pccs) <- levels(group)
    names(group_cvals) <- levels(group)
    names(cond_pccs) <- levels(group)

    return(
      structure(
        list(group_pcc = group_pccs,
             individual_pccs = individual_pccs,
             condition_pccs = cond_pccs,
             correct_pairs = correct_pairs,
             total_pairs = total_pairs,
             group_cval = group_cvals,
             individual_cvals = individual_cvals,
             individual_idx = individual_idx,
             group_labels = group_labels_vec,
             n_permutations = n_permutations,
             pccs_geq_observed = pccs_geq_observed,
             pcc_replicates = pcc_replicates,
             call = match.call(),
             hypothesis = hypothesis,
             pairing_type = pairing_type,
             diff_threshold = diff_threshold,
             cval_method = cval_method,
             data = dat,
             groups = group),
        class = "opafit"))
  }
}
