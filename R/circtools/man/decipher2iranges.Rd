% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/design.R
\name{decipher2iranges}
\alias{decipher2iranges}
\title{Creates  IRanges objects}
\usage{
decipher2iranges(primers)
}
\arguments{
\item{primers}{is a list of results from
\code{\link[DECIPHER]{DesignPrimers}}}
}
\value{
a list with an \code{\link[IRanges]{IRanges}}
item for every primer pair
}
\description{
The  metadata include:
\itemize{
\item seqId
\item productSize
\item type: ['forward', 'reverse']
\item seq: the primer sequence.
}

['forward', 'reverse']: R:'forward',%20'reverse'%5C
}
