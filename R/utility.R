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

#' Plots individual PCCs relative to a user-supplied PCC threshold value.
#' @param m an object of class "opafit"
#' @param pcc_threshold a numeric scalar
#' @return an object of class "ggplot"
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11))
#' opamod <- opa(dat, 1:3)
#' pcc_threshold_plot(opamod)
#' pcc_threshold_plot(opamod, pcc_threshold = 85)
#' @export
pcc_threshold_plot <- function(m, pcc_threshold = 75) {
  Individual <- group <- PCC <- NULL # bind variables to function
  if (is.null(m$groups)) { # single group
    df <- data.frame(Individual = 1:dim(m$data)[1],
                     PCC = m$individual_pccs)
    ggplot2::ggplot(df, ggplot2::aes(x = Individual, y = PCC)) +
      ggplot2::scale_x_continuous(breaks = 1:length(m$individual_pccs)) +
      ggplot2::geom_hline(yintercept = pcc_threshold, linetype = 2, colour = "red") +
      ggplot2::geom_segment(ggplot2::aes(x=Individual, xend=Individual, y=0, yend=PCC), colour="black", size=0.3) +
      ggplot2::geom_point(size=2, shape=21, fill="royalblue") +
      ggplot2::guides(fill="none") +
      ggplot2::coord_flip() +
      ggplot2::theme(panel.grid.major.y = ggplot2::element_blank(),
                     panel.grid.minor.y = ggplot2::element_blank())
  } else { # multiple groups
    df <- data.frame(Individual = 1:length(m$individual_pccs),
                     group = factor(m$group_labels),
                     PCC = m$individual_pccs)
    ggplot2::ggplot(df, ggplot2::aes(x = Individual, y = PCC)) +
      ggplot2::scale_x_continuous(breaks = 1:length(m$individual_idx), labels=m$individual_idx) +
      ggplot2::geom_hline(yintercept = pcc_threshold, linetype = 2, colour = "red") +
      ggplot2::geom_segment(ggplot2::aes(x=Individual, xend=Individual, y=0, yend=PCC), colour="black", size=0.3) +
      ggplot2::geom_point(size=2, shape=21, ggplot2::aes(fill=group)) +
      ggplot2::coord_flip() +
      ggplot2::theme(panel.grid.major.y = ggplot2::element_blank(),
                     panel.grid.minor.y = ggplot2::element_blank(),
                     legend.position = "bottom")
  }
}

#' Plots individual-level PCCs and chance-values.
#' @param x an object of class "opafit" produced by \code{opa()}
#' @param ... ignored
#' @return an object of class "ggplot"
#' @examples
#' dat <- data.frame(t1 = c(9, 4, 8, 10),
#'                   t2 = c(8, 8, 12, 10),
#'                   t3 = c(8, 5, 10, 11))
#' opamod <- opa(dat, 1:3)
#' plot(opamod)
#' @export
plot.opafit <- function(x, ...) {
  Individual <- stat <- group <- value <- NULL
  if (is.null(x$groups)) { # single group
    df <- data.frame(Individual = rep(1:dim(x$data)[1], 2),
                     stat = c(rep("PCCs", dim(x$data)[1]), rep("c-values", dim(x$data)[1])),
                     value = c(x$individual_pccs, x$individual_cvals))
    df$stat <- factor(df$stat, levels = c("PCCs", "c-values"))
    ggplot2::ggplot(df, ggplot2::aes(x = Individual, y = value)) +
      ggplot2::scale_x_reverse(breaks = 1:length(x$individual_pccs)) +
      ggplot2::geom_segment(ggplot2::aes(x=Individual, xend=Individual, y=0, yend=value), colour="black", size=0.3) +
      ggplot2::geom_point(size=2, shape=21, ggplot2::aes(fill=stat)) +
      ggplot2::facet_wrap(~ stat, nrow=1, scale="free") +
      ggplot2::ylab(NULL) +
      ggplot2::guides(fill="none") +
      ggplot2::coord_flip() +
      ggplot2::theme(panel.grid.major.y = ggplot2::element_blank(),
                     panel.grid.minor.y = ggplot2::element_blank())
  } else { # multiple groups
    df <- data.frame(Individual = rep(1:length(x$individual_pccs), 2),
                     group = rep(factor(x$group_labels), 2),
                     stat = c(rep("PCCs", nrow(x$data)), rep("c-values", dim(x$data)[1])),
                     value = c(x$individual_pccs, x$individual_cvals))
    df$stat <- factor(df$stat, levels = c("PCCs", "c-values"))
    ggplot2::ggplot(df, ggplot2::aes(x = Individual, y = value)) +
      ggplot2::scale_x_reverse(breaks = 1:length(x$individual_idx), labels=x$individual_idx) +
      ggplot2::geom_segment(ggplot2::aes(x=Individual, xend=Individual, y=0, yend=value), colour="black", size=0.3) +
      ggplot2::geom_point(size=2, shape=21, ggplot2::aes(fill=group)) +
      ggplot2::facet_wrap(~ stat, nrow=1, scale="free") +
      ggplot2::ylab(NULL) +
      ggplot2::coord_flip() +
      ggplot2::theme(panel.grid.major.y = ggplot2::element_blank(),
                     panel.grid.minor.y = ggplot2::element_blank(),
                     legend.position = "bottom")
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

#' @rdname group_results
#' @export
group_results.default <- function(m, digits) .NotYetImplemented()

#' @rdname group_results
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

#' @rdname individual_results
#' @export
individual_results.default <- function(m, digits) .NotYetImplemented()

#' @rdname individual_results
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
#' @param xlabels a character or numeric vector
#' @param point_size a number
#' @param fill_color a string containing a hex value or recognised colour name
#' @return no return value, called for side-effects only
#' @examples
#' h <- c(1,2,3,3,3)
#' plot_hypothesis(h)
#' plot_hypothesis(h, xlabels = c("A", "B", "C", "D", "E"))
#' plot_hypothesis(h, point_size = 1)
#' plot_hypothesis(h, fill_color = "royalblue")
#' @export
plot_hypothesis <- function(h, xlabels = 1:length(h), point_size = 2, fill_color = "#CCCCCC") {

  stopifnot("hypothesis must be a numeric vector"= (class(h) == "numeric") || (class(h) == "integer"))
  stopifnot("xlabels must be same length as the hypothesis"= length(h) == length(xlabels))
  stopifnot("point size must be a number"= typeof(point_size) == "double" || typeof(point_size) == "integer")
  stopifnot("point_size must be a single number"= length(point_size) == 1)
  stopifnot("fill_color must be a single- or double-quoted string"= class(fill_color) == "character")

  graphics::par(mar = c(4, 4, 0.5, 0.5))
  plot(1:length(h), h, pch = 21, cex = point_size, bg = fill_color,
       xlab = "", ylab = "Relative Value",
       xlim = c(0.7,length(h) + 0.3), ylim = c(min(h) - 0.3, max(h) + 0.3),
       xaxt = "n", yaxt = "n")
  graphics::axis(1, at = 1:length(xlabels), labels = c(xlabels))
  graphics::axis(2, at=c(min(h), max(h)), labels = c("Lower", "Higher"), las=1)
}

# Clean up C++ when package is unloaded.
.onUnload <- function(libpath) {
  library.dynam.unload("opa", libpath)
}
