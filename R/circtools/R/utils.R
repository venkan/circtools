

unifyDiff <- function(x,y) {
    points <- cbind(x,y)
    o <- order(points)
    res <- rle(points[o]) 
    res$values <- seq_along(unique(res$values))
    points[o] <- inverse.rle(res)
    list(points[seq_along(x)],
         points[seq_along(y) + length(x)])
}

normaliseData <- function(...){
    dat <- list(...)
    toProcess <- vapply(dat, Negate(is.null), logical(1))
    columns <- c("start", "end")
    positions <- do.call(rbind,
        lapply(names(dat)[toProcess], function(x){
          cbind(id = x, dat[[x]][, columns])
        })
    )
    result <- as.data.frame(
        do.call(cbind,
                unifyDiff(positions$start, positions$end))
    )
    names(result) <- columns
    dat[toProcess] <- split(result, positions$id)
    dat
}

testData <- function() {
  set.seed(239)
  res <- list()
  # create transcript-exon table
  exonsNum <- 10
  exons <- data.frame(start = 1000 * 1:exonsNum,
                      end = 1000 * 1:exonsNum + 600)
  transNum <- 5
  exons <-  lapply(1:transNum,
                   function(x) {
                     cbind(tx_id = paste0("ENST000000", x),
                           exons[sample(exonsNum, sample(exonsNum, 1) +
                                          1), ])
                   })
  exons <- do.call(rbind, exons)
  res$exons <- exons
  # create expression levels
  res$counts <- data.frame(id = unique(exons$tx_id),
                           count = round(2 ^ stats::runif(
                             transNum, min = -10, max = 20
                           )))
  
  # primers
  t1 <- exons$tx_id[1]
  e1 <- exons[exons$tx_id == t1, ]
  e1 <- e1[order(e1$start), ]
  res$primers <- data.frame(id = paste0("circ", c(1, 1, 2)),
                            rbind(
                              c(e1$end[1] - 10, e1$end[1]),
                              c(e1$start[2], e1$start[2] + 10),
                              c(e1$start[2] + 40, e1$start[2] + 60)
                            ))
  names(res$primers) <- c("id", "start", "end")
  # circ coord
  res$circs <-  data.frame(sjId = "circ1",
                           start = e1$start[4],
                           end = e1$end[6])
  #circ primers
  res$circPrimers <-
    with(res$circs,
         {
           data.frame(id = paste0("circ", c(1, 1, 2)),
                      rbind(
                        c(start[1], start[1] + 10),
                        c(end[1] - 10, end[1]),
                        c(start[1] + 60, start[1] + 80)
                      ))
         })
  names(res$circPrimers) <- names(res$primers)
  res
}
