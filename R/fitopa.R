#' Fit an ordinal pattern analysis model to determine the degree of match
#' between data and a specified hypothesis.
#' @param dat a data.frame
#' @param hypothesis a numeric vector
#' @param pairing_type a string
#' @param diff_threshold a positive integer or floating point number
#' @return an object of class "opafit"
#' @examples
#' \dontrun{opa(dat, c(1,2,3,3))}
#' \dontrun{opa(dat, c(1,2,3,3), pairing_type = "adjacent")}
#' \dontrun{opa(dat, c(1,2,3,3), diff_threshold = 1)}
#' \dontrun{opa(dat, c(1,2,3,3), group = group_vector)}
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
#' @references
#' Grice, J. W., Craig, D. P. A., & Abramson, C. I. (2015). A Simple and Transparent Alternative to Repeated Measures ANOVA. SAGE Open, 5(3), 215824401560419. <https://doi.org/10.1177/2158244015604192>
#' Thorngate, W. (1987). Ordinal Pattern Analysis: A Method for Assessing Theory-Data Fit. Advances in Psychology, 40, 345–364. <https://doi.org/10.1016/S0166-4115(08)60083-7>
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
