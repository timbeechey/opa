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


#' Calculate the c-value of the difference in PCCs produced by two hypotheses
#' @param m1 an object of class "opafit" produced by a call to opa().
#' @param m2 an object of class "opafit" produced by a call to opa().
#' @param two_tailed a boolean indicating whether the comparison is two-tailed.
#' @return an object of class "opaHypothesisComparison".
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11),
#'                   t4 = c(10, 5, 11, 12))
#' h1 <- hypothesis(c(1, 2, 3, 4))
#' h2 <- hypothesis(c(1, 4, 2, 3))
#' opamod1 <- opa(dat, h1)
#' opamod2 <- opa(dat, h2)
#' compare_hypotheses(opamod1, opamod2, two_tailed = TRUE)
#' @export
compare_hypotheses <- function(m1, m2, two_tailed) {
    UseMethod("compare_hypotheses")
}


#' @export
compare_hypotheses.default <- function(m1, m2, two_tailed) {
    .NotYetImplemented()
}


#' @export
compare_hypotheses.opafit <- function(m1, m2, two_tailed = TRUE) {
    stopifnot("Multigroup fits cannot be compared using compare_hypotheses()"= is.null(m1$group) && is.null(m2$group))
    stopifnot("Models have different numbers of random orderings"= m1$nreps == m2$nreps)
    pcc_diff <- abs(m1$group_pcc - m2$group_pcc)
    rand_pccs_diff <- m1$rand_pccs - m2$rand_pccs
    if (two_tailed) {
        type <- "two-tailed"
        cval <- length(rand_pccs_diff[abs(rand_pccs_diff) >= pcc_diff]) / m1$nreps
    } else {
        type <- "one-tailed"
        cval <- length(rand_pccs_diff[rand_pccs_diff >= pcc_diff]) / m1$nreps
    }
    return(
        structure(
            list(h1 = m1$hypothesis,
                 h2 = m2$hypothesis,
                 h1_pcc = m1$group_pcc,
                 h2_pcc = m2$group_pcc,
                 pcc_diff = pcc_diff,
                 cval = cval,
                 nreps = m1$nreps,
                 type = type,
                 pcc_diff_dist = unlist(rand_pccs_diff)),
            class = "opaHypothesisComparison"
        )
    )
}


#' Plot hypothesis comparison PCC replicates.
#'
#' @details
#' Plot a histogram of PCCs computed from randomly reordered data
#' used to calculate the chance-value for a hypothesis comparison.
#' @param x an object of class "oparandpccs" produced by \code{random_pccs()}
#' @param nbins number of histogram bins
#' @param ... ignored
#' @return no return value, called for side effects only.
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11),
#'                   t4 = c(10, 5, 11, 12))
#' h1 <- hypothesis(c(1, 2, 3, 4))
#' h2 <- hypothesis(c(1, 4, 2, 3))
#' opamod1 <- opa(dat, h1)
#' opamod2 <- opa(dat, h2)
#' z <- compare_hypotheses(opamod1, opamod2)
#' plot(z)
#' @export
plot.opaHypothesisComparison <- function(x, nbins = 10, ...) {
  histogram(x$pcc_diff_dist, type = "count", xlab = "PCC",
    xlim = c(NA, min(max(max(x$pcc_diff_dist), x$pcc_diff) + 5, 105)),
    ylab = "Count", col = "#56B4E9", breaks = nbins,
    panel = function(...) {
        panel.histogram(...)
        if (x$type == "two_tailed") {
            panel.abline(v = c(x$pcc_diff, -x$pcc_diff), col = "red", lty = 2)
        } else {
            panel.abline(v = x$pcc_diff, col = "red", lty = 2)
        }
    }
  )
}


#' Prints a summary of results from hypothesis comparison.
#' @param object an object of class "opaHypothesisComparison".
#' @param ... ignored
#' @return No return value, called for side effects.
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11),
#'                   t4 = c(10, 5, 11, 12))
#' h1 <- hypothesis(c(1, 2, 3, 4))
#' h2 <- hypothesis(c(1, 4, 2, 3))
#' opamod1 <- opa(dat, h1)
#' opamod2 <- opa(dat, h2)
#' z <- compare_hypotheses(opamod1, opamod2)
#' summary(z)
#' @export
summary.opaHypothesisComparison <- function(object, ...) {
    if (object$cval == 0) {
        object$cval <- paste0("<", toString(1/object$nreps))
    }
    cat("********* Hypothesis Comparison **********\n")
    cat("H1:", object$h1, "\n")
    cat("H2:", object$h2, "\n")
    cat("H1 PCC:", object$h1_pcc, "\n")
    cat("H2 PCC:", object$h2_pcc, "\n")
    cat("PCC difference:", object$pcc_diff, "\n")
    cat("cval:", object$cval, "\n")
    cat("Comparison type:", object$type)
}


#' Prints a summary of results from hypothesis comparison.
#' @param x an object of class "opaHypothesisComparison".
#' @param ... ignored
#' @return No return value, called for side effects.
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11),
#'                   t4 = c(10, 5, 11, 12))
#' h1 <- hypothesis(c(1, 2, 3, 4))
#' h2 <- hypothesis(c(1, 4, 2, 3))
#' opamod1 <- opa(dat, h1)
#' opamod2 <- opa(dat, h2)
#' z <- compare_hypotheses(opamod1, opamod2)
#' print(z)
#' @export
print.opaHypothesisComparison <- function(x, ...) {
    summary(x)
}


#' Calculate the c-value of the difference in PCCs produced by two groups
#' @param m an object of class "opafit" produced by a call to opa().
#' @param group1 a character string which matches a group level passed to opa().
#' @param group2 a character string which matches a group level passed to opa().
#' @param two_tailed a boolean indicating whether the comparison is two-tailed.
#' @return an object of class "opaGroupComparison".
#' @examples
#' dat <- data.frame(group = c("a", "b", "a", "b"),
#'                   t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11))
#' dat$group <- factor(dat$group, levels = c("a", "b"))
#' h <- hypothesis(1:3)
#' opamod <- opa(dat[,2:4], h, group = dat$group)
#' compare_groups(opamod, "a", "b")
#' @export 
compare_groups <- function(m, group1, group2, two_tailed) {
    UseMethod("compare_groups")
}


#' @export 
compare_groups.default <- function(m, group1, group2, two_tailed) {
    .NotYetImplemented()
}


#' @export
compare_groups.opafit <- function(m, group1, group2, two_tailed = TRUE) {
    stopifnot("The opafit object must have been fitted with at least 2 groups"= length(m$groups) >= 2)
    pcc_diff <- unname(abs(m$group_pcc[group1] - m$group_pcc[group2]))
    rand_pccs_diff <- unname(unlist(m$group_rand_pccs[group1]) - unlist(m$group_rand_pccs[group2]))
    if (two_tailed) {
        type <- "two-tailed"
        cval <- length(rand_pccs_diff[abs(rand_pccs_diff) >= pcc_diff]) / m$nreps
    } else {
        type <- "one-tailed"
        cval <- length(rand_pccs_diff[rand_pccs_diff >= pcc_diff]) / m$nreps
    }
    
    return(
        structure(
            list(group1 = group1,
                 group2 = group2,
                 group1_pcc = m$group_pcc[group1],
                 group2_pcc = m$group_pcc[group2],
                 pcc_diff = pcc_diff, 
                 cval = cval,
                 nreps = m$nreps,
                 type = type,
                 pcc_diff_dist = unlist(rand_pccs_diff)),
            class = "opaGroupComparison"
        )
    )
}


#' Plot group comparison PCC replicates.
#'
#' @details
#' Plot a histogram of PCCs computed from randomly reordered data
#' used to calculate the chance-value for a group comparison.
#' @param x an object of class "oparandpccs" produced by \code{random_pccs()}
#' @param nbins number of histogram bins
#' @param ... ignored
#' @return no return value, called for side effects only.
#' @examples
#' dat <- data.frame(group = c("a", "b", "a", "b"),
#'                   t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11))
#' dat$group <- factor(dat$group, levels = c("a", "b"))
#' h <- hypothesis(1:3)
#' opamod <- opa(dat[,2:4], h, group = dat$group)
#' z <- compare_groups(opamod, "a", "b")
#' plot(z)
#' @export
plot.opaGroupComparison <- function(x, nbins = 10, ...) {
  histogram(x$pcc_diff_dist, type = "count", xlab = "PCC",
    xlim = c(NA, min(max(max(x$pcc_diff_dist), x$pcc_diff) + 5, 105)),
    ylab = "Count", col = "#56B4E9", breaks = nbins,
    panel = function(...) {
        panel.histogram(...)
        if (x$type == "two_tailed") {
            panel.abline(v = c(x$pcc_diff, -x$pcc_diff), col = "red", lty = 2)
        } else {
            panel.abline(v = x$pcc_diff, col = "red", lty = 2)
        }
    }
  )
}


#' Prints a summary of results from hypothesis comparison.
#' @param object an object of class "opaHypothesisComparison".
#' @param ... ignored
#' @return No return value, called for side effects.
#' @examples
#' dat <- data.frame(group = c("a", "b", "a", "b"),
#'                   t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11))
#' dat$group <- factor(dat$group, levels = c("a", "b"))
#' h <- hypothesis(1:3)
#' opamod <- opa(dat[,2:4], h, group = dat$group)
#' z <- compare_groups(opamod, "a", "b")
#' summary(z)
#' @export
summary.opaGroupComparison <- function(object, ...) {
    if (object$cval == 0) {
        object$cval <- paste0("<", toString(1/object$nreps))
    }
    cat("********* Group Comparison **********\n")
    cat("Group 1:", object$group1, "\n")
    cat("Group 2:", object$group2, "\n")
    cat("Group 1 PCC:", object$group1_pcc, "\n")
    cat("Group 2 PCC:", object$group2_pcc, "\n")
    cat("PCC difference:", object$pcc_diff, "\n")
    cat("cval:", object$cval, "\n")
    cat("Comparison type:", object$type)
}

#' Prints a summary of results from hypothesis comparison.
#' @param x an object of class "opaHypothesisComparison".
#' @param ... ignored
#' @return No return value, called for side effects.
#' @examples
#' dat <- data.frame(group = c("a", "b", "a", "b"),
#'                   t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11))
#' dat$group <- factor(dat$group, levels = c("a", "b"))
#' h <- hypothesis(1:3)
#' opamod <- opa(dat[,2:4], h, group = dat$group)
#' z <- compare_groups(opamod, "a", "b")
#' print(z)
#' @export
print.opaGroupComparison <- function(x, ...) {
    summary(x)
}
