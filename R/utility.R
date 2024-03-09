# opa: An Implementation of Ordinal Pattern Analysis.
# Copyright (C) 2024 Timothy Beechey (tim.beechey@proton.me)
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


#' Create a hypothesis object
#' @param xs a numeric vector
#' @param type a string
#' @return a list containing the following elements
#' @examples
#' h1 <- hypothesis(c(2, 1, 3, 4), type = "pairwise")
#' h2 <- hypothesis(c(2, 1, 3, 4), type = "adjacent")
#' @export
hypothesis <- function(xs, type = "pairwise") {
    stopifnot("A vector or numeric values in required"=is.numeric(xs))
    stopifnot("A vector containing at least two elements is required"=length(xs) > 1)
    stopifnot("type must be either 'pairwise' or 'adjacent'"=type %in% c("pairwise", "adjacent"))

    xs_length <- length(xs)

    if (type == "pairwise") {
        n_pairs <- ((xs_length - 1) * xs_length) / 2
    } else if (type == "adjacent") {
        n_pairs <- xs_length - 1
    }

    ordinal_relations <- ordering(xs, type, 0)
    n_increases <- length(ordinal_relations[ordinal_relations == 1])
    n_decreases <- length(ordinal_relations[ordinal_relations == -1])
    n_equalities <- length(ordinal_relations[ordinal_relations == 0])

    structure(
        list(raw = xs,
             type = type,
             n_pairs = n_pairs,
             ordinal_relations = ordinal_relations,
             n_increases = n_increases,
             n_decreases = n_decreases,
             n_equalities = n_equalities),
        class = "opahypothesis")
}


#' Print details of a hypothesis
#' @param x an object of type "opaHypothesis"
#' @param ... ignored
#' @return No return value, called for side-effects.
#' @examples
#' h1 <- hypothesis(c(2, 1, 3, 4), type = "pairwise")
#' print(h1)
#' h2 <- hypothesis(c(2, 1, 3, 4), type = "adjacent")
#' print(h2)
#' @export
print.opahypothesis <- function(x, ...) {
    cat("********** Ordinal Hypothesis **********\n")
    cat("Hypothesis type:", x$type, "\n")
    cat("Raw hypothesis:\n", x$raw, "\n")
    cat("Ordinal relations:\n", x$ordinal_relations, "\n")
    cat("N conditions:", length(x$raw), "\n")
    cat("N hypothesised ordinal relations:", x$n_pairs, "\n")
    cat("N hypothesised increases:", x$n_increases, "\n")
    cat("N hypothesised decreases:", x$n_decreases, "\n")
    cat("N hypothesised equalities:", x$n_equalities, "\n")
}


#' Prints a summary of results from a fitted ordinal pattern analysis model.
#' @param object an object of class "opafit".
#' @param digits an integer used for rounding values in the output.
#' @param ... ignored
#' @return No return value, called for side effects.
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11))
#' h <- hypothesis(1:3)
#' opamod <- opa(dat, h)
#' summary(opamod)
#' summary(opamod, digits = 3)
#' @export
summary.opafit <- function(object, ..., digits = 2L) {
    if (is.null(object$groups)) {
        cat("Ordinal Pattern Analysis of", dim(object$data)[2], "observations for",
            dim(object$data)[1], "individuals in 1 group \n\n")
    } else {
        cat("Ordinal Pattern Analysis of", dim(object$data)[2], "observations for",
            dim(object$data)[1], "individuals in", nlevels(object$groups), "groups \n\n")
    }

    cat("Between subjects results:\n")
    print(group_results(object, digits))
    cat("\nWithin subjects results:\n")
    print(individual_results(object, digits))
    cat("\nPCCs were calculated for ", object$pairing_type,
        " ordinal relationships using a difference threshold of ", object$diff_threshold,
        ".\n", sep = "")
    cat("Chance-values were calculated from", object$nreps, "random orderings.\n")
}


#' Displays the results of a pairwise ordinal pattern analysis.
#' @param x an object of class "pairwiseopafit".
#' @param ... ignored
#' @return No return value, called for side effects.
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11))
#' h <- hypothesis(1:3)
#' opamod <- opa(dat, h)
#' pw <- compare_conditions(opamod)
#' print(pw, digits = 2)
#' @export
print.pairwiseopafit <- function(x, ...) {
    disp_pcc_mat <- matrix(numeric(0), nrow = dim(x$pccs_mat)[1], ncol = dim(x$pccs_mat)[2])
    disp_cval_mat <- matrix(numeric(0), nrow = dim(x$cvals_mat)[1], ncol = dim(x$cvals_mat)[2])
    disp_pcc_mat[lower.tri(disp_pcc_mat)] <- round(x$pccs, 3)
    disp_cval_mat[lower.tri(disp_cval_mat)] <- round(x$cvals, 3)
    # put "-" in empty cells in the upper triangle
    disp_pcc_mat[upper.tri(disp_pcc_mat, diag = TRUE)] <- "-"
    disp_cval_mat[upper.tri(disp_cval_mat, diag = TRUE)] <- "-"
    # display 0s as < 1/nreps. e.g. if nreps=1000, display 0 as <0.001
    disp_cval_mat[disp_cval_mat == "0"] <- paste0("<", toString(1 / x$nreps))
    # convert matrices to data.frames for pretty printing
    pcc_df <- as.data.frame(disp_pcc_mat)
    cval_df <- as.data.frame(disp_cval_mat)
    # set column names to condition numbers
    colnames(pcc_df) <- seq_len(dim(pcc_df)[2])
    colnames(cval_df) <- seq_len(dim(cval_df)[2])
    cat("Pairwise PCCs:\n")
    print(pcc_df)
    cat("\nPairwise chance values:\n")
    print(cval_df)
}


#' Displays the call used to fit an ordinal pattern analysis model.
#' @param x an object of class "opafit".
#' @param ... ignored
#' @return No return value, called for side effects.
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11))
#' h <- hypothesis(1:3)
#' opamod <- opa(dat, h)
#' print(opamod)
#' @export
print.opafit <- function(x, ...) {
    print(x$call)
}


#' Plot individual PCCs.
#' @param m an object of class "opafit"
#' @return No return value, called for side effects.
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11))
#' h <- hypothesis(1:3)
#' opamod <- opa(dat, h)
#' pcc_plot(opamod)
#' @export
pcc_plot <- function(m) {
    UseMethod("pcc_plot")
}


#' @export
pcc_plot.default <- function(m) {
    .NotYetImplemented()
}


#' @export
pcc_plot.opafit <- function(m) {
    dat <- data.frame(y = seq_along(m$individual_pccs),
                      x = m$individual_pccs)
    plot_symbols <- c(3, 8, 4, 1, 0, 5, 2, 7, 6, 9, 10:14)
    dotplot(y ~ x, dat, group = m$groups,
            pch = if (!is.null(m$groups)) plot_symbols else 3,
            lty = 3,
            col = if (!is.null(m$groups)) palette()[1:nlevels(m$groups)] else palette()[1], 
            col.line = "grey", cex = 1,
            xlab = "PCC", ylab = "Individual",
            key = if (!is.null(m$groups)) {
                      list(space = "top", columns = nlevels(m$groups),
                           text = list(levels(m$groups)),
                           points = list(pch = plot_symbols[1:nlevels(m$groups)],
                           col = palette()[1:nlevels(m$groups)]))})
}


#' Plot individual chance values
#' @param m an object of class "opafit"
#' @return No return value, called for side effects.
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11))
#' h <- hypothesis(1:3)
#' opamod <- opa(dat, h)
#' cval_plot(opamod)
#' @export
cval_plot <- function(m) {
    UseMethod("cval_plot")
}


#' @export
cval_plot.default <- function(m) {
    .NotYetImplemented()
}


#' @export
cval_plot.opafit <- function(m) {
    dat <- data.frame(y = seq_along(m$individual_cvals), 
                      x = m$individual_cvals)
    plot_symbols <- c(3, 8, 4, 1, 0, 5, 2, 7, 6, 9, 10:14)
    dotplot(y ~ x, dat, group = m$groups, lty = 3, col.line = "grey", cex = 1,
            pch = if (!is.null(m$groups)) plot_symbols else 3,
            col = if (!is.null(m$groups)) palette()[1:nlevels(m$groups)] else palette()[1],
            xlab = "Chance-Value", ylab = "Individual",
            key = if (!is.null(m$groups)) {
                      list(space = "top", columns = nlevels(m$groups),
                           text = list(levels(m$groups)),
                           points = list(pch = plot_symbols[1:nlevels(m$groups)],
                           col = palette()[1:nlevels(m$groups)]))})
}


#' Plots individual-level PCCs and chance-values.
#' @param x an object of class "opafit" produced by \code{opa()}
#' @param ... ignored
#' @return No return value, called for side effects.
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11))
#' h <- hypothesis(1:3)
#' opamod <- opa(dat, h)
#' plot(opamod)
#' @export
plot.opafit <- function(x, ...) {
    plot_symbols <- c(3, 8, 4, 1, 0, 5, 2, 7, 6, 9, 10:14)
    n <- length(x$individual_pccs)
    dat <- data.frame(stat = c(rep("PCC", n), rep("Chance-Value", n)),
                      y = rep(1:n, 2),
                      x = c(x$individual_pccs, x$individual_cvals))
    dat$stat <- factor(dat$stat, levels = c("PCC", "Chance-Value"))
    if (!is.null(x$groups)) {
        dat$groups <- rep(x$groups, 2)
        dat$groups <- factor(dat$groups)
    }
    dotplot(y ~ x | stat, dat, group = dat$groups,
            pch = if (!is.null(x$groups)) plot_symbols else 3,
            lty = 3, col.line = "grey",
            col = if (!is.null(x$groups)) palette()[1:nlevels(x$groups)] else palette()[1],
            xlab = NULL, ylab = "Individual",
            scales = list(relation = "free"),
            key = if (!is.null(x$groups)) {
                list(space = "bottom", columns = nlevels(x$groups),
                     text = list(levels(x$groups)),
                     points = list(pch = plot_symbols[1:nlevels(x$groups)],
                                   col = palette()[1:nlevels(x$groups)]))})
}


#' Plot a hypothesis.
#' @param x an object of class "opaHypothesis"
#' @param title a boolean indicating whether to include a plot title
#' @param ... ignored
#' @return No return value, called for side effects.
#' @examples
#' h <- hypothesis(c(1,2,3,3,3))
#' plot(h)
#' @export
plot.opahypothesis <- function(x, title = TRUE, ...) {
    xyplot(x$raw ~ seq_along(x$raw), xlab = "x", ylab = "h(x)",
           main = if (title) "Hypothesis" else NULL,
           cex = 2, pch = 21, col = "black", fill = palette()[1],
           scales = list(x = list(at = seq_along(x$raw)),
                         y = if (min(x$raw) != max(x$raw)) {
                                 list(at = c(min(x$raw), max(x$raw)), labels = c("Lower", "Higher"))
                             } else {
                                list(at = NULL, labels = NULL)
                             }))
}


#' Group-level PCC and chance values.
#'
#' @details
#' If the model was fitted with no grouping variable, a single PCC and c-value
#' are returned. If a grouping variable was specified in the call to \code{opa}
#' then PCCs and c-values are returned for each factor level of the grouping
#' variable.
#' @param m an object of class "opafit" produced by \code{opa()}.
#' @param digits a positive integer.
#' @return a matrix with 1 row per group.
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11))
#' h <- hypothesis(1:3)
#' opamod <- opa(dat, h)
#' group_results(opamod)
#' @export
group_results <- function(m, digits) {
    UseMethod("group_results")
}


#' @export
group_results.default <- function(m, digits) {
    .NotYetImplemented()
}


#' @export
group_results.opafit <- function(m, digits = 2) {
    if (is.null(m$groups)) {
        out <- matrix(c(round(m$group_pcc, digits), m$group_cval), nrow = 1)
        colnames(out) <- c("PCC", "cval")
        rownames(out) <- "pooled"
        out_df <- as.data.frame(out)
        out_df$cval[out_df$cval < 1 / m$nreps] <- paste0("<", 1 / m$nreps)
        return(out_df)
    } else {
        out <- cbind(round(m$group_pcc, digits), m$group_cval)
        colnames(out) <- c("PCC", "cval")
        rownames(out) <- levels(m$groups)
        out_df <- as.data.frame(out)
        out_df$cval[out_df$cval < 1 / m$nreps] <- paste0("<", 1 / m$nreps)
        return(out_df)
    }
}


#' Individual-level PCC and chance values.
#'
#' @details
#' If the \code{opa} model was fitted with no grouping variable, a matrix of PCCs
#' and c-values are returned corresponding to the order of rows in the data. If
#' the \code{opa} model was fitted with a grouping variable specified, a table of
#' PCCs and c-values is returned ordered by factor level of the grouping
#' variable.
#' @param m an object of class "opafit" produced by \code{opa()}
#' @param digits an integer
#' @return a matrix containing a column of PCC values and a column of c-values
#' with 1 row per row of data.
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11))
#' h <- hypothesis(1:3)
#' opamod <- opa(dat, h)
#' individual_results(opamod)
#' @export
individual_results <- function(m, digits) {
    UseMethod("individual_results")
}


#' @export
individual_results.default <- function(m, digits) {
    .NotYetImplemented()
}


#' @export
individual_results.opafit <- function(m, digits = 2) {
    if (is.null(m$groups)) {
        out <- round(cbind(m$individual_pccs, m$individual_cvals), digits)
        colnames(out) <- c("PCC", "cval")
        rownames(out) <- 1:(length(m$individual_pccs))
        return(out)
    } else {
        out <- round(cbind(m$individual_idx, m$individual_pccs, m$individual_cvals), digits)
        colnames(out) <- c("Individual", "PCC", "cval")
        rownames(out) <- m$group_labels
        out_df <- as.data.frame(out)
        out_df$cval[out_df$cval < 1 / m$nreps] <- paste0("<", 1 / m$nreps)
        return(out_df)
    }
}


#' Return the group PCCs of the specified model
#' @param m an object of class "opafit"
#' @return a numeric vector
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11))
#' h <- hypothesis(1:3)
#' opamod <- opa(dat, h)
#' group_pccs(opamod)
#' @export
group_pccs <- function(m) {
    UseMethod("group_pccs")
}


#' @export
group_pccs.default <- function(m) {
    .NotYetImplemented()
}


#' @export
group_pccs.opafit <- function(m) {
    m$group_pcc
}


#' @export
group_pccs.pairwiseopafit <- function(m) {
    m$pccs
}


#' Return the group chance values of the specified model
#' @param m an object of class "opafit"
#' @return a numeric vector
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11))
#' h <- hypothesis(1:3)
#' opamod <- opa(dat, h)
#' group_cvals(opamod)
#' @export
group_cvals <- function(m) {
    UseMethod("group_cvals")
}


#' @export
group_cvals.default <- function(m) {
    .NotYetImplemented()
}


#' @export
group_cvals.opafit <- function(m) {
    m$group_cval
}


#' @export
group_cvals.pairwiseopafit <- function(m) {
    m$cvals
}


#' Return the individual PCCs of the specified model
#' @param m an object of class "opafit"
#' @return a numeric vector
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11))
#' h <- hypothesis(1:3)
#' opamod <- opa(dat, h)
#' individual_pccs(opamod)
#' @export
individual_pccs <- function(m) {
    UseMethod("individual_pccs")
}


#' @export
individual_pccs.default <- function(m) {
    .NotYetImplemented()
}


#' @export
individual_pccs.opafit <- function(m) {
    c(m$individual_pccs)
}


#' Return the individual chance values of the specified model
#' @param m an object of class "opafit"
#' @return a numeric vector
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11))
#' h <- hypothesis(1:3)
#' opamod <- opa(dat, h)
#' individual_cvals(opamod)
#' @export
individual_cvals <- function(m) {
    UseMethod("individual_cvals")
}


#' @export
individual_cvals.default <- function(m) {
    .NotYetImplemented()
}


#' @export
individual_cvals.opafit <- function(m) {
    c(m$individual_cvals)
}


#' Return the random order generated PCCs used to calculate the group chance value
#' @param m an object of class "opafit"
#' @return a numeric vector
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11))
#' h <- hypothesis(1:3)
#' opamod <- opa(dat, h)
#' random_pccs(opamod)
#' @export
random_pccs <- function(m) {
    UseMethod("random_pccs")
}


#' @export
random_pccs.default <- function(m) {
    .NotYetImplemented()
}


#' @export
random_pccs.opafit <- function(m) {
    z <- m$rand_pccs
    attr(z, "observed_pcc") <- m$group_pcc
    class(z) <- "oparandpccs"
    z
}


#' Plot PCC replicates.
#'
#' @details
#' Plot a histogram of PCCs computed from randomly reordered data
#' used to calculate the chance-value.
#' @param x an object of class "oparandpccs" produced by \code{random_pccs()}
#' @param ... ignored
#' @return no return value, called for side effects only.
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11))
#' h <- hypothesis(1:3)
#' opamod <- opa(dat, h)
#' plot(random_pccs(opamod))
#' @export
plot.oparandpccs <- function(x, ...) {
    densityplot(unclass(x), pch = 4, cex = 0.5, col = palette()[1], xlab = "PCC",
                xlim = c(NA, min(max(max(x), attr(x, "observed_pcc")) + 5, 105)), ylab = "",
                panel = function(...) {
                    panel.densityplot(...)
                    panel.abline(v = attr(x, "observed_pcc"), col = "red", lty = 2)})
}


#' Return the number of pairs of observations matched by the hypothesis
#' @param m an object of class "opafit"
#' @return a non-negative integer
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11))
#' h <- hypothesis(1:3)
#' opamod <- opa(dat, h)
#' correct_pairs(opamod)
#' @export
correct_pairs <- function(m) {
    UseMethod("correct_pairs")
}


#' @export
correct_pairs.default <- function(m) {
    .NotYetImplemented()
}


#' @export
correct_pairs.opafit <- function(m) {
    m$correct_pairs
}


#' Return the number of pairs of observations not matched by the hypothesis
#' @param m an object of class "opafit"
#' @return a non-negative integer
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11))
#' h <- hypothesis(1:3)
#' opamod <- opa(dat, h)
#' incorrect_pairs(opamod)
#' @export
incorrect_pairs <- function(m) {
    UseMethod("incorrect_pairs")
}


#' @export
incorrect_pairs.default <- function(m) {
    .NotYetImplemented()
}


#' @export
incorrect_pairs.opafit <- function(m) {
    m$total_pairs - m$correct_pairs
}


# Clean up C++ when package is unloaded.
.onUnload <- function(libpath) {
    library.dynam.unload("opa", libpath)
}
