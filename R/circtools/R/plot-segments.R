
# get height of a text line in inches
inches_per_line <- function(){
  graphics::par("csi") 
}

# calculate text width in lines
maxLabelWidth <- function(x){
  textLength <- max(graphics::strwidth(x, units = "inches", cex = 1))
  textLength / graphics::par()$csi
}

# set plot outer margins
margins <- function(left = 0,
                    right = 0,
                    top = 0,
                    bottom = 0,
                    x = c(left, right),
                    y = c(bottom, top)) {
  op <- graphics::par()
  graphics::par(mar = c(y[1], x[1], y[2], x[2]))
  op
}

xy_per_in <- function() graphics::par("cxy") / graphics::par("cin")

# set which axis to plot
which_axis <- function(x = FALSE, y = FALSE) {
  op <- graphics::par(xaxt = ifelse(x, "s", "n"),
            yaxt = ifelse(y, "s", "n"))
  op
}

# drop axes
no_axis <- function(){
  which_axis() 
}

# no outer box around a plot
no_box <- function(){
  op <- graphics::par(bty = "n")
  op
}

getPanelHeight <- function(laneNumber){
  graphics::par("csi") * laneNumber 
}

# get vertical limits in user coordinates 
getYLim <- function() graphics::par()$usr[3:4]

#' Plots isoforms structure, primer position and isoform counts if provided
#'
#' @param exons an interval data.frame
#' @param circs a counts data.frame
#' @param counts an interval data.frame
#' @param primers an interval data.frame
#' @param opts an option list
#' @param minAspectRatio a minimal ratio of a segment height to its width
#' 
#' @details all interval data.frames must have start and end fields.
#' `exons` is assumed to have `strand` (character) and `tx_id` fields.
#' `primers` must have `id` to distinguish forward, reverse primers for 
#' different circular transcripts.
#' `cirsc` must contain sjId field. 
#'  `counts` has id and count fields.
#' 
#' @return Used for its side effects. Plots intervals for exons,
#' primers and transcript counts if provided.
#' @export
#'
plotTranscripts <- function(exons,
                            counts = NULL,
                            primers = NULL,
                            circs = NULL,
                            minAspectRatio = .2,
                            opts = list()) {
  .opts <- list(
    normalise = TRUE,
    net = TRUE,
    primerColor = "firebrick3",
    exonColor = "black", 
    netColor = "grey"
  )
  .opts[names(opts)] <- opts
  if (.opts$normalise) {
    n <- normaliseData(
      exons = exons,
      circs = circs,
      primers = primers
    )
    cols <- c('start', 'end')
    if (!is.null(exons))
      exons[, cols] <- n$exons
    if (!is.null(circs))
      circs[, cols] <- n$circs
    if (!is.null(primers))
      primers[, cols] <- n$primers
  }
  addNet <- function() {
    if (.opts$net && .opts$normalise) {
      cols <- c('start', 'end')
      positions <- rbind(exons[, cols], circs[, cols], primers[, cols])
      graphics::abline(v = unique(unlist(positions)), col = .opts$netColor)
    }
  }
  # pre-defined
  numMarginLines <- 3
  widths <- c(2, 1)
  if (is.null(counts)) 
    widths[2] <- .1
  # calculate sizes of panels and segments
  segmentSize <- .75
  primersNum <- ifelse(missing(primers), 0, length(unique(primers$id)))
  upperPanelHeight <- getPanelHeight(primersNum)
  lowerPanelHeight <- getPanelHeight(numMarginLines +
                                       length(unique(exons$tx_id)))
  # in relative units
  heights <- c(upperPanelHeight, lowerPanelHeight) / lowerPanelHeight + .1
  graphics::layout(
    matrix(c(2, 1, 4, 3), ncol = 2),
    widths  = widths,
    heights = heights
  )
  # plot exons -- bottom left
  # leave 0.5 + 0.5 = 1 margin lines around the labels
  labWidth <- maxLabelWidth(c(as.character(exons$tx_id),
                              as.character(primers$id))) + 1 
  op <- margins(left = labWidth, bottom = numMarginLines)
  # plot segments
  if (is.null(exons$tx_id))
    stop("No transcript id field named 'tx_id' in the `exons` argument")
  plotRanges(
    ids         = exons$tx_id,
    starts      = exons$start,
    ends        = exons$end,
    segmentSize = segmentSize,
    col = .opts$exonColor,
    minWidth    = minAspectRatio,
    opts = .opts
  )
  addNet()
  if ( !is.null(exons$strand)) {
    graphics::par(xpd = TRUE)
    xy <- graphics::par()$usr
    direction <- switch(as.character(unique(exons$strand)),
                        "-" = 1,
                        "+" = 2,
                        0)
    graphics::arrows(y0 = xy[3], y1 = xy[3], x0 = xy[1], x1 = xy[2], 
           length = getPanelHeight(1),
           angle = 15,
           code = direction,
           lwd = 2,
           col = .opts$exonColor)
    graphics::par(xpd = FALSE)
  }
  # add circ rectangles if defined
  isoformsYLim <- getYLim()
  if (!is.null(circs))
    annotateCircs(
      ids    = circs$sjId,
      starts = circs$start,
      ends   = circs$end,
      alpha  = .1
    )
  exonsXLim <- range(exons$start, exons$end)
  exonsXLim <- graphics::par()$usr[1:2]
  # plot primers -- upper left
  if (!is.null(primers)) {
    op <- margins(left   = labWidth,
                  top    = 0,
                  bottom = .1)
    plotRanges(
      ids    = primers$id,
      starts = primers$start,
      ends   = primers$end,
      segmentSize = segmentSize,
      minWidth    = .1, 
      col = .opts$primerColor,
      xlim = exonsXLim,
      ylim = c(.5, length(primers$id) - .5), 
      opts = .opts 
    )
    addNet()
    graphics::box()
  } else {
    margins()
    graphics::plot.new()
  }
  # plot counts -- lower right
  if (!is.null(counts)) {
    graphics::par(bty = "u")
    margins(left   = 1,
            bottom = numMarginLines,
            right  = 0.2)
    counts <- counts[counts$id %in% levels(factor(exons$tx_id)),]
    counts$id <- match(counts$id, levels(factor(exons$tx_id)))
    plotCounts(id    = counts$id,
               count = counts$count,
               ylim  = isoformsYLim)
  }
}

#' Plots segments for a list of intervals
#'
#' @param ids a character vector
#' @param starts a numeric vector
#' @param ends a numerica vector
#' @param segmentSize a segment size (height) in inches, so it can be the same
#' for several subplots
#' @param minWidth a minimal segment width in inches
#' @param xlim a range of interval coordinates on the plot. Used for alignment
#' of features at multiple plots
#' @param ylim a ylim range 
#' @param opts a list of plotting parameters:
#'   - col, the color of the segments (default: "dodgerblue4")
#'   - connect, a logical. If the segments must be connected with lines 
#'   (default: TRUE).
#' @param col the color of the segments
#'
#' @return Used for its side effect. Plots segments corresponding to given 
#' intervals. 
#' @export
#'
plotRanges <- function(ids,
                       starts,
                       ends,
                       segmentSize,
                       minWidth = 0,
                       col = "dodgerblue4",
                       xlim = range(starts, ends),
                       ylim = c(0.0, 1 + length(levels(ids))),
                       opts) {
  options <- list(connect = TRUE)
  options[names(opts)] <- opts
  ids <- as.factor(ids)
  no_axis()
  no_box()
  graphics::plot(
    0,
    type = "n",
    xlim = xlim,
    ylim = ylim,
    yaxs = "i",
    xaxs = "i",
    ylab = "",
    xlab = ""
  )
  y_pos <- as.numeric(ids)
  graphics::mtext(
    as.character(ids),
    side = 2,
    line = .5,
    at   = y_pos,
    las  = 1,
    cex  = graphics::par()$cex
  )
  seg_width_y <- segmentSize 
  x_to_y <- xy_per_in()[1] / xy_per_in()[2]
  min_width_x <- segmentSize * x_to_y * minWidth
  o <- (ends - starts) < min_width_x
  ends[o] <- starts[o] + min_width_x
  graphics::rect(
    xleft   = starts,
    ybottom = y_pos - seg_width_y / 2,
    xright  = ends,
    ytop    = y_pos + seg_width_y / 2,
    col     = col,
    border  = NA
  )
  # add connecting lines
  if (options$connect) {
    linesStarts <- vapply(split(starts, ids), min, double(1)) 
    linesEnds <- vapply(split(starts, ids), max, double(1)) 
    uniq_ids <- unique(ids)
    graphics::segments(linesStarts[uniq_ids], as.numeric(uniq_ids),
             linesEnds[uniq_ids], as.numeric(uniq_ids),
             col = col, lend = 2)
  }
}


annotateCircs <- function(ids, starts, ends, alpha = .2) {
    stopifnot(length(starts) == length(ends))
    stopifnot(alpha > 0 & alpha <= 1)
    colors <- grDevices::adjustcolor("darkseagreen1", alpha=.1)
    colorsLine <- "darkolivegreen4"
    shift <- c(.2, -.5)
    ylim <- graphics::par()$usr[3:4] 
    ylim <- ylim + shift
    space <- 0.5 - shift[1]
    step <- space / length(starts)
    graphics::rect(
      xleft = starts,
      xright = ends,
      ybottom = ylim[1] + step * (seq_along(starts) - 1),
      ytop = ylim[2] + step * (seq_along(starts) - 1), 
      #col = colors,
      border = colorsLine,
      lwd = 2
    )
  }

plotCounts <- function(id, count, ylim = c(.5, length(id) + .5)) {
  which_axis(x = TRUE)
  graphics::plot(
    x = count + .5,
    y = as.numeric(id),
    pch = 16,
    cex = 1.5,
    ylim = ylim,
    xlim = c(0.5, max(count) * 2.5),
    log = 'x',
    xaxs = "i",
    yaxs = "i"
  )
  graphics::segments(.5, y0 = as.numeric(id), count + .5, lwd = 2)
}
