% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sconeReport.R
\name{sconeReport}
\alias{sconeReport}
\title{SCONE Report Browser: Browse Evaluation of Normalization Performance}
\usage{
sconeReport(scone_res, qc, bio = NULL, batch = NULL, poscon = character(),
  negcon = character())
}
\arguments{
\item{scone_res}{list. SCONE output list from a scone(return_norm = "in_memory") call. Required.}

\item{qc}{matrix. The QC metrics to be used for QC evaluation. Required.}

\item{bio}{factor. The biological condition (variation to be preserved). Default NULL.}

\item{batch}{factor. The known batch variable (variation to be removed). Default NULL.}

\item{poscon}{character. The genes to be used as positive controls for
evaluation. These genes should be expected to change according to the
biological phenomenon of interest. Default empty character.}

\item{negcon}{character. The genes to be used as negative controls for
evaluation. These genes should be expected not to change according to the
biological phenomenon of interest. Default empty character.}
}
\description{
This function opens a shiny application session for visualizing performance
of a variety of normalization schemes.
}

