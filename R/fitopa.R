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
#' Any \emph{independent} variable must be passed separately as a vector with the
#' \code{group} keyword. The grouping vector must be a \emph{factor}.
#'
#' The length of the \code{hypothesis} must be equal to the number of columns in
#' the dependent variable data.frame \code{dat}.
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
                diff_threshold = 0, cval_method = "stochastic", nreps = 1000) {
  # verify the arguments
  assertthat::assert_that(assertthat::are_equal(ncol(dat), length(hypothesis)))
  assertthat::assert_that(pairing_type %in% c("pairwise", "adjacent"))
  assertthat::assert_that(cval_method %in% c("exact", "stochastic"))
  assertthat::assert_that(class(diff_threshold) %in% c("integer", "numeric"))
  assertthat::assert_that(assertthat::is.count(nreps))

  if (is.null(group)) { # single groups
    # convert the data.frame input to a matrix for speed
    mat <- as.matrix(dat)

    pccs <- pcc(mat, hypothesis, pairing_type, diff_threshold)
    if (cval_method == "exact") {
      cvalues <- cval_exact(pccs)
    } else if (cval_method == "stochastic") {
      cvalues <- cval_stochastic(pccs, nreps)
    }

    return(
      structure(
        list(group_pcc = pccs$group_pcc,
             individual_pccs = pccs$individual_pccs,
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

    for (i in 1:nlevels(group)) {
      idx <- which(group == groups[i])
      subgroup_dat <- dat[idx,]
      subgroup_mat <- as.matrix(subgroup_dat)
      subgroup_pccs <- pcc(subgroup_mat, hypothesis, pairing_type, diff_threshold)
      cat("Fitting group", i, "of", nlevels(group), "\n")
      if (cval_method == "exact") {
        subgroup_cvalues <- cval_exact(subgroup_pccs)
      } else if (cval_method == "stochastic") {
        subgroup_cvalues <- cval_stochastic(subgroup_pccs, nreps)
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

    return(
      structure(
        list(group_pcc = group_pccs,
             individual_pccs = individual_pccs,
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
