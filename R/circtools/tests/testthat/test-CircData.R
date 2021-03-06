context("Create and plot CircData")

library("EnsDb.Hsapiens.v86")
db <- EnsDb.Hsapiens.v86

createCirc <- function(geneName, db){
  txs <- select(db, keys=geneName, keytype="GENENAME",columns="TXNAME")
  ex1 <- exonsBy(db, filter=TxidFilter(txs$TXNAME[1]))[[1]]
  ex2 <- exonsBy(db, filter=TxidFilter(txs$TXNAME[2]))[[1]]
  circCoords <- c(range(ex1[1:2]), range(ex2[1:2]))
  mcols(circCoords)$sjId <- paste0(seqnames(circCoords), ":",
                                     start(circCoords), "-", end(circCoords))
  circCoords
}

test_that("No error when create a CircData object", {
  geneName <- c("BCL6", "BCL2")
  suppressWarnings(
    circCoords <- do.call(c, lapply(geneName, createCirc, db = db)))
  sjId <- mcols(circCoords)$sjId[1]
  expect_silent(CircData(db, circCoords))
})

test_that("No error while plot CircData object", {
  geneName <- c("BCL6" )
  suppressWarnings(
    circCoords <- do.call(c, lapply(geneName, createCirc, db = db)))
  sjId <- mcols(circCoords)$sjId[1]
  circData <- CircData(db, circCoords)
  expect_silent(plotCirc(sjId, circData = circData))
})

test_that("Error if wrong input to  plot CircData", {
  geneName <- c("BCL6", "BCL2")
  suppressWarnings(
    circCoords <- do.call(c, lapply(geneName, createCirc, db = db)))
  circData <- CircData(db, circCoords)
  # correct and  wrong gene or circ
  sjId <- mcols(circCoords)$sjId[1:2] # chr 3
  geneId <- circData$sjGeneIds[3] #chr 3
  expect_silent(plotCirc(sjId, circGenes = geneId, circData = circData))
  sjId <- mcols(circCoords)$sjId[1] # chr 3
  geneId <- circData$sjGeneIds[1] #chr 18
  expect_error(plotCirc(sjId, circGenes = geneId, circData = circData))
  # several genes
  sjId <- mcols(circCoords)$sjId[3] # chr 18
  geneId <- circData$sjGeneIds[1:2] # chr 18
  expect_warning(plotCirc(sjId, circGenes = geneId, circData = circData))
})

test_that("retrieve sequencies for circs", {
  library("EnsDb.Hsapiens.v86")
  db <- EnsDb.Hsapiens.v86
  geneName <- c("BCL6")
  suppressWarnings(
    circCoords <- do.call(c, lapply(geneName, createCirc, db = db)))
  sjId <- mcols(circCoords)$sjId[1]
  circData <- CircData(db, circCoords)
  library(BSgenome.Hsapiens.NCBI.GRCh38)
  bsg <- BSgenome.Hsapiens.NCBI.GRCh38
  expect_silent({
    exSeq <- getExonSeqs(circData = circData, bsg = bsg, type = "sho")
    exSeq <- getExonSeqs(circData = circData, bsg = bsg, type = "long")
  }
  )
  exSeq <- getExonSeqs(circData = circData, bsg = bsg)
  # starts and ends are as in circs
  lapply(circCoords, function(circ) {
    ex <- exSeq[[mcols(circ)$sjId]]
    expect_true(all(end(ex[mcols(ex)$side == "leftSide"]) == end(circ)))
    expect_true(all(start(ex[mcols(ex)$side == "rightSide"]) == start(circ)))
  })
})
