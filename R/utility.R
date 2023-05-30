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

#' create a hypothesis object
#' @param xs a numeric vector
#' @param type a string
#' @return a list containing the following elements
#' @export
hypothesis <- function(xs, type = "pairwise") {
  xs_length <- length(xs)

  if (type == "pairwise") {
    n_pairs <- ((xs_length - 1) * xs_length) / 2
  } else {
    n_pairs <- xs_length - 1
  }

  ordinal_relations <- ordering(xs, type, 0)
  n_increases <- length(ordinal_relations[ordinal_relations == 1])
  n_decreases <- length(ordinal_relations[ordinal_relations == -1])
  n_equalities <- length(ordinal_relations[ordinal_relations == 0])

  structure(
    list(
      raw = xs,
      type = type,
      n_pairs = n_pairs,
      ordinal_relations = ordinal_relations,
      n_increases = n_increases,
      n_decreases = n_decreases,
      n_equalities = n_equalities
    ),
    class = "opa_hypothesis"
  )
}

#' Print details of a hypothesis
#' @param x an object of type "opa_hypothesis"
#' @param ... ignored
#' @return No return value, called for side-effects.
#' @export 
print.opa_hypothesis <- function(x, ...) {
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
#' opamod <- opa(dat, 1:3)
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
      ".\n", sep="")
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
#' opamod <- opa(dat, 1:3)
#' pw <- compare_conditions(opamod)
#' print(pw)
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
  disp_cval_mat[disp_cval_mat == "0"] <- paste0("<", toString(1/x$nreps))
  # convert matrices to data.frames for pretty printing
  pcc_df <- as.data.frame(disp_pcc_mat)
  cval_df <- as.data.frame(disp_cval_mat)
  # set column names to condition numbers
  colnames(pcc_df) <- 1:ncol(pcc_df)
  colnames(cval_df) <- 1:ncol(cval_df)
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
#' opamod <- opa(dat, 1:3)
#' print(opamod)
#' @export
print.opafit <- function(x, ...) {
  print(x$call)
}


#' Plot individual PCCs.
#' @param m an object of class "opafit"
#' @param threshold a boolean indicating whether to plot a threshold abline
#' @param title a boolean indicating whether to include a plot title
#' @param legend a boolean indicating whether to include a legend
#' @return No return value, called for side effects.
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11))
#' opamod <- opa(dat, 1:3)
#' pcc_plot(opamod)
#' pcc_plot(opamod, threshold = 85)
#' @export
pcc_plot <- function(m, threshold = NULL, title = TRUE, legend = TRUE) {
  UseMethod("pcc_plot")
}


#' @export
pcc_plot.default <- function(m, threshold = NULL, title = TRUE, legend = TRUE) .NotYetImplemented()


#' @export
pcc_plot.opafit <- function(m, threshold = NULL, title = TRUE, legend = TRUE) {
  old_par <- par()
  if (is.null(m$groups)) {
    par(mar = c(4, 4, 2, 1)) # no legend for single group
    plot_dat <- data.frame(group = rep(1, length(m$individual_pccs)),
                           idx=1:length(m$individual_pccs),
                           pcc = m$individual_pccs)
  } else {
    if (legend == TRUE) {
      par(mar = c(4, 4, 2, 6)) # make space for legend on the right
    } else {
      par(mar = c(4, 4, 2, 1))
    }
    plot_dat <- data.frame(group = m$groups[m$individual_idx],
                           idx = m$individual_idx,
                           pcc = m$individual_pccs)
  }
  plot(x=NULL, y=NULL,
       yaxt = "n",
       xlim = c(0, 100), ylim = rev(c(1, nrow(plot_dat))),
       ylab = "Individual", xlab = "PCC",
       las = 1, frame.plot = FALSE,
       main = ifelse(title == TRUE, "Individual PCCs", ""))
  grid(ny = NA)
  if (is.null(threshold)) {
    segments(x0 = 0,
             y0 = seq(nrow(plot_dat)),
             x1 = plot_dat$pcc,
             y1 = seq(nrow(plot_dat)),
             yaxt = "n",
             lty=1)
  } else {
    segments(x0 = 0,
             y0 = seq(nrow(plot_dat)),
             x1 = plot_dat$pcc,
             y1 = seq(nrow(plot_dat)),
             yaxt = "n",
             lty=ifelse(plot_dat$pcc >= threshold, 1, 3))
  }
  if (!is.null(threshold))
    abline(v=threshold, col="red", lty = 2)
  points(plot_dat$pcc,
         seq(nrow(plot_dat)),
         pch=21,
         cex=1.2,
         bg=plot_dat$group)
  axis(2, at=seq(nrow(plot_dat)),
       labels = plot_dat$idx, las=1)
  if (!is.null(m$groups)) {
    if (legend == TRUE) {
      legend("right", legend = levels(m$groups), title = "Group",
             pch=21, pt.bg = m$groups, cex=1,
             xpd = TRUE, inset = c(-0.3, 0))
    }
  }
  par(mar = old_par$mar)
}


#' Plot individual chance values
#' @param m an object of class "opafit"
#' @param threshold a boolean indicating whether to plot a threshold abline
#' @param title a boolean indicating whether to include a plot title
#' @param legend a boolean indicating whether to include a legend when n groups > 1
#' @return No return value, called for side effects.
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11))
#' opamod <- opa(dat, 1:3)
#' cval_plot(opamod)
#' cval_plot(opamod, threshold = 0.1)
#' @export
cval_plot <- function(m, threshold = NULL, title = TRUE, legend = TRUE) {
  UseMethod("cval_plot")
}


#' @export
cval_plot.default <- function(m, threshold = NULL, title = TRUE, legend = TRUE) .NotYetImplemented()


#' @export
cval_plot.opafit <- function(m, threshold = NULL, title = TRUE, legend = TRUE) {
  old_par <- par()
  if (is.null(m$groups)) {
    par(mar = c(4, 4, 2, 1))
    plot_dat <- data.frame(group = rep(1, length(m$individual_cvals)),
                           idx=1:length(m$individual_cvals),
                           cval = m$individual_cvals)
  } else {
    if (legend == TRUE) {
      par(mar = c(4, 4, 2, 6)) # make space for legend on the right
    } else {
      par(mar = c(4, 4, 2, 1))
    }
    plot_dat <- data.frame(group = m$groups[m$individual_idx],
                           idx = m$individual_idx,
                           cval = m$individual_cvals)
  }

  plot(x=NULL, y=NULL,
       yaxt = "n",
       xlim = c(0, min(c(1, max(m$individual_cvals + 0.1)))),
       ylim = rev(c(1, nrow(plot_dat))),
       ylab = "Individual", xlab = "c-value",
       las = 1, frame.plot = FALSE,
       main = ifelse(title == TRUE, "Individual c-values", ""))
  grid(ny = NA)
  if (is.null(threshold)) {
    segments(x0 = 0,
             y0 = seq(nrow(plot_dat)),
             x1 = plot_dat$cval,
             y1 = seq(nrow(plot_dat)),
             yaxt = "n",
             lty=1)
  } else {
    segments(x0 = 0,
             y0 = seq(nrow(plot_dat)),
             x1 = plot_dat$cval,
             y1 = seq(nrow(plot_dat)),
             yaxt = "n",
             lty=ifelse(plot_dat$cval >= threshold, 3, 1))
  }
  if (!is.null(threshold))
    abline(v=threshold, col = "red", lty = 2)
  points(plot_dat$cval,
         seq(nrow(plot_dat)),
         pch=21, cex=1.2,
         bg=plot_dat$group)
  axis(2, at=seq(nrow(plot_dat)),
       labels = plot_dat$idx, las = 1)
  if (!is.null(m$groups)) {
    if (legend == TRUE) {
      legend("right", legend = levels(m$groups), title = "Group",
             pch=21, pt.bg = m$groups, cex=1,
             xpd = TRUE, inset = c(-0.3, 0))
    }
  }
  par(mar = old_par$mar)
}


#' Plots individual-level PCCs and chance-values.
#' @param x an object of class "opafit" produced by \code{opa()}
#' @param pcc_threshold a number used as the x-intercept to plot a PCC threshold abline
#' @param cval_threshold a number used as the x-intercept to plot a c-value threshold abline
#' @param ... ignored
#' @return No return value, called for side effects.
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11))
#' opamod <- opa(dat, 1:3)
#' plot(opamod)
#' @export
plot.opafit <- function(x, pcc_threshold = NULL, cval_threshold = NULL, ...) {
  old_par <- par()
  if (is.null(x$groups)) {
    par(mfrow = c(1, 2))
    pcc_plot(x, threshold = pcc_threshold)
    cval_plot(x, threshold = cval_threshold)
    par(mfrow = c(1, 1))
  } else {
    layout(matrix(c(1, 2, 3, 3), ncol = 2, byrow = TRUE), heights=c(4, 1))
    par(mai = rep(0.5, 4))
    pcc_plot(x, threshold = pcc_threshold)
    cval_plot(x, threshold = cval_threshold)
    par(mai = c(0, 0, 0, 0))
    plot.new()
    legend(x="center", horiz = TRUE, legend = levels(x$groups), title = "Group",
           pch=21, pt.bg = x$groups, cex=1)
    par(mfrow = c(1, 1))
  }
  par(mar = old_par$mar)
}


#' Plot a hypothesis.
#' @param x an object of class "opa_hypothesis"
#' @param title a boolean indicating whether to include a plot title
#' @param ... ignored
#' @return No return value, called for side effects.
#' @examples
#' h <- hypothesis(c(1,2,3,3,3))
#' plot(h)
#' @export
plot.opa_hypothesis <- function(x, title = TRUE, ...) {
  par(mar = c(4, 4, 2, 0.5))
  plot(x = NULL, y = NULL, xlim = c(0.5, length(x$raw) + 0.5),
       ylim = c(min(x$raw) - 0.5, max(x$raw) + 0.5),
       xlab = "x", ylab = "h(x)",
       yaxt = "n", xaxt="n",
       main = ifelse(title == TRUE, "Hypothesis", ""))
  points(seq(length(x$raw)), x$raw, pch=21, cex=2, bg = palette()[1])
  axis(1, at=x$raw, labels=x$raw)
  axis(2, at=c(min(x$raw), max(x$raw)), labels = c("Lower", "Higher"), las = 1)
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
#' opamod <- opa(dat, 1:3)
#' group_results(opamod)
#' @export
group_results <- function(m, digits) {
  UseMethod("group_results")
}


#' @export
group_results.default <- function(m, digits) .NotYetImplemented()


#' @export
group_results.opafit <- function(m, digits = 2) {
  if (is.null(m$groups)) {
    out <- matrix(c(round(m$group_pcc, digits), m$group_cval),
                  nrow = 1)
    colnames(out) <- c("PCC", "cval")
    rownames(out) <- "pooled"
    return(out)
  }
  else {
    out <- cbind(round(m$group_pcc, digits), m$group_cval)
    colnames(out) <- c("PCC", "cval")
    rownames(out) <- levels(m$groups)
    return(out)
  }
}


#' Individual-level PCC and chance values.
#'
#' @details
#' If the model was fitted with no grouping variable, a matrix of PCCs and
#' c-values are returned corresponding to the order of rows in the data. If the
#' \code{opa} model was fitted with a grouping variable specified, a table of
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
#' opamod <- opa(dat, 1:3)
#' individual_results(opamod)
#' @export
individual_results <- function(m, digits) {
  UseMethod("individual_results")
}


#' @export
individual_results.default <- function(m, digits) .NotYetImplemented()


#' @export
individual_results.opafit <- function(m, digits = 2) {
  if (is.null(m$groups)) {
    out <- round(cbind(m$individual_pccs, m$individual_cvals), digits)
    colnames(out) <- c("PCC", "cval")
    rownames(out) <- seq(length(m$individual_pccs))
    return(out)
  } else {
    out <- round(cbind(m$individual_idx, m$individual_pccs, m$individual_cvals), digits)
    colnames(out) <- c("Individual", "PCC", "cval")
    rownames(out) <- m$group_labels
    return(out)
  }
}

#' Return the group PCCs of the specified model
#' @param m an object of class "opafit"
#' @return a numeric vector
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11))
#' opamod <- opa(dat, 1:3)
#' group_pccs(opamod)
#' @export
group_pccs <- function(m) {
  UseMethod("group_pccs")
}


#' @export
group_pccs.default <- function(m) .NotYetImplemented()


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
#' opamod <- opa(dat, 1:3)
#' group_cvals(opamod)
#' @export
group_cvals <- function(m) {
  UseMethod("group_cvals")
}


#' @export
group_cvals.default <- function(m) .NotYetImplemented()


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
#' opamod <- opa(dat, 1:3)
#' individual_pccs(opamod)
#' @export
individual_pccs <- function(m) {
  UseMethod("individual_pccs")
}


#' @export
individual_pccs.default <- function(m) .NotYetImplemented()


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
#' opamod <- opa(dat, 1:3)
#' individual_cvals(opamod)
#' @export
individual_cvals <- function(m) {
  UseMethod("individual_cvals")
}


#' @export
individual_cvals.default <- function(m) .NotYetImplemented()


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
#' opamod <- opa(dat, 1:3)
#' random_pccs(opamod)
#' @export
random_pccs <- function(m) {
  UseMethod("random_pccs")
}


#' @export
random_pccs.default <- function(m) .NotYetImplemented()


#' @export
random_pccs.opafit <- function(m) {
  m$rand_pccs
}


#' Return the number of pairs of observations matched by the hypothesis
#' @param m an object of class "opafit"
#' @return a non-negative integer
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11))
#' opamod <- opa(dat, 1:3)
#' correct_pairs(opamod)
#' @export
correct_pairs <- function(m) {
  UseMethod("correct_pairs")
}


#' @export
correct_pairs.default <- function(m) .NotYetImplemented()


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
#' opamod <- opa(dat, 1:3)
#' incorrect_pairs(opamod)
#' @export
incorrect_pairs <- function(m) {
  UseMethod("incorrect_pairs")
}


#' @export
incorrect_pairs.default <- function(m) .NotYetImplemented()


#' @export
incorrect_pairs.opafit <- function(m) {
  m$total_pairs - m$correct_pairs
}


# Clean up C++ when package is unloaded.
.onUnload <- function(libpath) {
  library.dynam.unload("opa", libpath)
}
