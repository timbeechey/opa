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


# Removes elements of a hypothesis vector that correspond to the position of
# NAs in a numeric vector of data (a data row).
# param: xs a numeric vector
# param: h a numeric vector
# return: a numeric vector
conform <- function(xs, h) {
  h[-which(is.na(xs))]
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
  cat("Chance-values were calculated using the", object$cval_method, "method.\n")
}

#' @export
print.opafit <- function(x, ...) {
  print(x$call)
}

#' Plot individual PCCs.
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
#' pcc_plot(opamod)
#' pcc_plot(opamod, threshold = 85)
#' @export
pcc_plot <- function(m, threshold = NULL, title = TRUE, legend = TRUE) {
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
  if (! is.null(threshold))
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
  if (is.null(m$groups)) {
    par(mar = c(4, 4, 2, 1))
    plot_dat <- data.frame(group = rep(1, length(m$individual_cvals)), idx=1:length(m$individual_cvals), cval = m$individual_cvals)
  } else {
    if (legend == TRUE) {
      par(mar = c(4, 4, 2, 6)) # make space for legend on the right
    } else {
      par(mar = c(4, 4, 2, 1))
    }
    plot_dat <- data.frame(group = m$groups[m$individual_idx], idx = m$individual_idx, cval = m$individual_cvals)
  }

  plot(x=NULL, y=NULL,
       yaxt = "n",
       xlim = c(0, min(c(1, max(m$individual_cvals + 0.1)))), ylim = rev(c(1, nrow(plot_dat))),
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
}

#' Plots individual PCCs relative to a user-supplied PCC threshold value.
#' @param m an object of class "opafit"
#' @param pcc_threshold a numeric scalar
#' @return No return value, called for side effects.
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11))
#' opamod <- opa(dat, 1:3)
#' pcc_threshold_plot(opamod)
#' pcc_threshold_plot(opamod, pcc_threshold = 85)
#' @export
pcc_threshold_plot <- function(m, pcc_threshold = 75) {
  warning("pcc_threshold_plot() is deprecated. Use pcc_plot(x, threshold = n) instead")
  pcc_plot(m, threshold = pcc_threshold)
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
  if (is.null(x$groups)) {
    par(mfrow = c(1, 2))
    pcc_plot(x, threshold = pcc_threshold)
    cval_plot(x, threshold = cval_threshold)
    par(mfrow = c(1, 1))
  } else {
    layout(matrix(c(1, 2, 3, 3), ncol = 2, byrow = TRUE), heights=c(4, 1))
    par(mai = rep(0.5, 4))
    pcc_plot(x, threshold = pcc_threshold, legend = FALSE)
    cval_plot(x, threshold = cval_threshold, legend = FALSE)
    par(mai = c(0, 0, 0, 0))
    plot.new()
    legend(x="center", horiz = TRUE, legend = levels(x$groups), title = "Group",
           pch=21, pt.bg = x$groups, cex=1)
    par(mfrow = c(1, 1))
  }
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
    out <- matrix(c(round(m$group_pcc, digits), round(m$group_cval, digits)),
                  nrow = 1)
    colnames(out) <- c("PCC", "cval")
    rownames(out) <- "pooled"
    return(out)
  }
  else {
    out <- cbind(round(m$group_pcc, digits), round(m$group_cval, digits))
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

#' Plot a hypothesis.
#' @param h a numeric vector
#' @param title a boolean indicating whether to include a plot title
#' @return No return value, called for side effects.
#' @examples
#' h <- c(1,2,3,3,3)
#' plot_hypothesis(h)
#' @export
plot_hypothesis <- function(h, title = TRUE) {
  par(mar = c(4, 4, 2, 0.5))
  plot(x = NULL, y = NULL, xlim = c(min(h) - 0.5, max(h) + 0.5),
       ylim = c(min(h) - 0.5, max(h) + 0.5),
       xlab = "x", ylab = "h(x)",
       yaxt = "n", xaxt="n",
       main = ifelse(title == TRUE, "Hypothesis", ""),
       frame.plot = FALSE)
  points(seq(length(h)), h, pch=21, cex=2, bg = palette()[1])
  axis(1, at=h, labels=h)
  axis(2, at=c(min(h), max(h)), labels = c("Lower", "Higher"), las = 1)
}

# TODO: function to plot pairwise condition comparisons
# condition_comparison_plot(m) {}

# Clean up C++ when package is unloaded.
.onUnload <- function(libpath) {
  library.dynam.unload("opa", libpath)
}
