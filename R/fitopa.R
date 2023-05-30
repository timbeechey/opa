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
#' considers the ordering of adjacent pairs only. If unspecified, the default
#' is "pairwise".
#'
#' \code{diff_threshold} may be a positive integer or double. If unspecified
#' a default zero threshold is used. The \code{diff_threshold} is never applied
#' to the hypothesis.
#'
#' \code{nreps} specifies the number of random reorderigs to use in the
#' calculation of chance-values.
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
#' @param nreps an integer, ignored if \code{cval_method = "exact"}
#' @return \code{opa} returns an object of class "opafit".
#'
#' An object of class "opafit" is a list containing the folllowing components:
#' \describe{
#'   \item{group_pcc}{the percentage of pairwise orderings from all pooled data
#'   rows which were correctly classified by the hypothesis.}
#'   \item{individual_pccs}{a vector containing the percentage of pairwise
#'   orderings that were correctly classified by the hypothesis for each data
#'   row.}
#'   \item{correct_pairs}{an integer representing the number of pairwise
#'   orderings pooled across all data rows that were correctly classified by the
#'   hypothesis.}
#'   \item{total_pairs}{an integer, the number of pair orderings contained in
#'   the data.}
#'   \item{group_cval}{the group-level chance value.}
#'   \item{individual_cvals}{a vector containing chance values for each data
#'   row}
#'   \item{rand_pccs}{A vector of PCCS calculated from each random ordering
#'   with length equal to nreps, a list of vectors if a \code{group} vector
#'   was passed to \code{opa()}.}
#'   \item{call}{The matched call}
#'   \item{hypothesis}{The hypothesis vector passed to \code{opa()}}
#'   \item{pairing_type}{A string indicating the method of pairing passed
#'   to \code{opa()}.}
#'   \item{diff_threshold}{The numeric difference threshold used to calculate
#'   PCCs. If no value was passed in the \code{diff_threshold}, the default of
#'   0 is used.}
#'   \item{data}{The data.frame passed to \code{opa()}.}
#'   \item{groups}{The vector of groups passed to \code{opa}. If no group vector
#'   was passed to \code{opa()} the default of NULL is used.}
#'   \item{nreps}{an integer, the number of random re-orderings of the data
#'   used to compute chance values.}
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
#' opa(dat[,2:4], 1:3, pairing_type = "adjacent")
#' opa(dat[,2:4], 1:3, diff_threshold = 1)
#' opa(dat[,2:4], 1:3, group = dat$group)
#' @export
opa <- function(dat, hypothesis, group = NULL, pairing_type = "pairwise",
                diff_threshold = 0, nreps = 1000L) {

  if (class(hypothesis) == "opahypothesis") {
    hypothesis <- hypothesis$raw
  }

  # verify the arguments
  if (!is.null(group)) {
    stopifnot("There must be at least 2 groups"= length(group) >= 2)
    stopifnot("The groups vector must contain 1 item per data row"= length(group) == dim(dat)[1])
  }
  stopifnot("Data must be passed to opa() in a data.frame"= is.data.frame(dat))
  stopifnot("Hypothesis and data rows are not the same length"= dim(dat)[2] == length(hypothesis))
  stopifnot("pairing_type must be 'pairwise' or 'adjacent'"= pairing_type %in% c("pairwise", "adjacent"))
  stopifnot("diff_threshold must be a number"= class(diff_threshold) %in% c("integer", "numeric"))
  stopifnot("diff_threshold must be a non-negative number"= diff_threshold >= 0)
  stopifnot("nreps must be a whole number"= nreps == as.integer(nreps))
  stopifnot("nreps must be a positive number"= nreps >= 1)
  stopifnot("nreps must be a single number"= length(nreps) == 1)
  stopifnot("diff_threshold must be a single number"= length(diff_threshold) == 1)

  if (is.null(group)) { # single groups
    mat <- as.matrix(dat) # data must be a matrix

    pccs <- pcc(mat, hypothesis, pairing_type, diff_threshold)
    cvalues <- calc_cvalues(pccs, nreps)

    return(
      structure(
        list(group_pcc = pccs$group_pcc,
             individual_pccs = pccs$individual_pccs,
             correct_pairs = pccs$correct_pairs,
             total_pairs = pccs$total_pairs,
             group_cval = cvalues$group_cval,
             individual_cvals = cvalues$individual_cvals,
             rand_pccs = cvalues$rand_pccs,
             call = match.call(),
             hypothesis = hypothesis,
             pairing_type = pairing_type,
             diff_threshold = diff_threshold,
             data = dat,
             groups = group,
             nreps = nreps),
        class = "opafit"))

  } else { # multiple groups
    stopifnot("The grouping vector must be a factor"=is.factor(group))
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

    group_rand_pccs <- data.frame(n = 1:nreps)

    for (i in 1:nlevels(group)) {
      idx <- which(group == groups[i])
      subgroup_dat <- dat[idx,]
      subgroup_mat <- as.matrix(subgroup_dat)
      subgroup_pccs <- pcc(subgroup_mat, hypothesis, pairing_type, diff_threshold)
      subgroup_cvalues <- calc_cvalues(subgroup_pccs, nreps)

      group_rand_pccs[groups[i]] <- subgroup_cvalues$rand_pccs

      group_pccs[i] <- subgroup_pccs$group_pcc
      correct_pairs <- correct_pairs + subgroup_pccs$correct_pairs
      total_pairs <- total_pairs + subgroup_pccs$total_pairs
      group_cvals[i] <- subgroup_cvalues$group_cval
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
             correct_pairs = correct_pairs,
             total_pairs = total_pairs,
             group_cval = group_cvals,
             individual_cvals = individual_cvals,
             group_rand_pccs = group_rand_pccs,
             individual_idx = individual_idx,
             group_labels = group_labels_vec,
             call = match.call(),
             hypothesis = hypothesis,
             pairing_type = pairing_type,
             diff_threshold = diff_threshold,
             data = dat,
             groups = group,
             nreps = nreps),
        class = "opafit"))
  }
}
