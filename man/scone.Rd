% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/scone_main.R
\name{scone}
\alias{scone}
\title{SCONE Main: Normalize Expression Data and Evaluate Normalization Performance}
\usage{
scone(expr, imputation = list(none = impute_null), impute_args = NULL,
  rezero = FALSE, scaling, k_ruv = 5, k_qc = 5, ruv_negcon = NULL,
  qc = NULL, adjust_bio = c("no", "yes", "force"), adjust_batch = c("no",
  "yes", "force"), bio = NULL, batch = NULL, run = TRUE,
  evaluate = TRUE, eval_pcs = 3, eval_proj = NULL,
  eval_proj_args = NULL, eval_kclust = 2:10, eval_negcon = ruv_negcon,
  eval_poscon = NULL, params = NULL, verbose = FALSE,
  stratified_pam = FALSE, return_norm = c("no", "in_memory", "hdf5"),
  hdf5file, ...)
}
\arguments{
\item{expr}{matrix. The expression data matrix (genes in rows, cells in columns).}

\item{imputation}{list or function. (A list of) function(s) to be used for
imputation. By default only scone::impute_null is included.}

\item{impute_args}{arguments passed to all imputation functions.}

\item{rezero}{Restore zeroes following scaling step? Default FALSE.}

\item{scaling}{list or function. (A list of) function(s) to be used for
scaling normalization.}

\item{k_ruv}{numeric. The maximum number of factors of unwanted variation
(the function will adjust for 1 to k_ruv factors of unwanted variation). If
0, RUV will not be performed.}

\item{k_qc}{numeric. The maximum number of quality metric PCs (the function
will adjust for 1 to k_qc PCs). If 0, QC adjustment will not be performed.}

\item{ruv_negcon}{character. The genes to be used as negative controls for
RUV. Ignored if k_ruv=0.}

\item{qc}{matrix. The QC metrics to be used for QC adjustment. Ignored if
k_qc=0.}

\item{adjust_bio}{character. If 'no' it will not be included in the model; if
'yes', both models with and without 'bio' will be run; if 'force', only
models with 'bio' will be run.}

\item{adjust_batch}{character. If 'no' it will not be included in the model;
if 'yes', both models with and without 'batch' will be run; if 'force',
only models with 'batch' will be run.}

\item{bio}{factor. The biological condition to be included in the adjustment
model (variation to be preserved). If adjust_bio="no", it will not be used
for normalization, but only for evaluation.}

\item{batch}{factor. The known batch variable to be included in the
adjustment model (variation to be removed). If adjust_batch="no", it will
not be used for normalization, but only for evaluation.}

\item{run}{logical. If FALSE the normalization and evaluation are not run,
but the function returns a data.frame of parameters that will be run for
inspection by the user.}

\item{evaluate}{logical. If FALSE the normalization methods will not be
evaluated (faster).}

\item{eval_pcs}{numeric. The number of principal components to use for
evaluation. Ignored if evaluation=FALSE.}

\item{eval_proj}{function. Projection function for evaluation  (see
\code{\link{score_matrix}} for details). If NULL, PCA is used for
projection.}

\item{eval_proj_args}{list. List of args passed to projection function as
eval_proj_args.}

\item{eval_kclust}{numeric. The number of clusters (> 1) to be used for pam
tightness evaluation. If an array of integers, largest average silhouette
width (tightness) will be reported. If NULL, tightness will be returned NA.}

\item{eval_negcon}{character. The genes to be used as negative controls for
evaluation. These genes should be expected not to change according to the
biological phenomenon of interest. Ignored if evaluation=FALSE. Default is
ruv_negcon argument. If NULL, correlations with negative controls will be
returned NA.}

\item{eval_poscon}{character. The genes to be used as positive controls for
evaluation. These genes should be expected to change according to the
biological phenomenon of interest. Ignored if evaluation=FALSE. If NULL,
correlations with positive controls will be returned NA.}

\item{params}{matrix or data.frame. If given, the algorithm will bypass
creating the matrix of possible parameters, and will use the given matrix.
There are basically no checks as to whether this matrix is in the right
format, and is only intended to be used to feed the results of setting
run=FALSE back into the algorithm (see example).}

\item{verbose}{logical. If TRUE some messagges are printed.}

\item{stratified_pam}{logical. If TRUE then maximum ASW for PAM_SIL is
separately computed for each biological-cross-batch stratum (accepting
NAs), and a weighted average is returned as PAM_SIL.}

\item{return_norm}{character. If "no" the normalized values will not be
returned. This will create a much smaller object and may be useful for
large datasets and/or when many combinations are compared. If "in_memory"
the normalized values will be returned as part of the output. If "hdf5"
they will be written on file using the \code{rhdf5} package.}

\item{hdf5file}{character. If \code{return_norm="hdf5"}, the name of the file
onto which to save the normalized matrices.}

\item{...}{Arguments to be passed to methods.}
}
\value{
A list with the following elements: \itemize{ \item{normalized_data}{
  A list containing the normalized data matrix, log-scaled. NULL when
  \code{return_norm} is not "in_memory".} \item{metrics}{ A matrix containing
  raw evaluation metrics for each normalization method (see
  \code{\link{score_matrix}} for details). Rows are sorted in the same order
  as in the scores output matrix. NULL when evaluate = FALSE.} \item{scores}{
  A matrix containing scores for each normalization, including average score rank.
  Rows are sorted by decreasing mean score rank. NULL when evaluate = FALSE.}
  \item{params}{ A data.frame with each row corresponding to a set of
  normalization parameters.} }

If \code{run=FALSE} a \code{data.frame} with each row corresponding
  to a set of normalization parameters.
}
\description{
This function is a high-level wrapper function for applying and evaluating
a variety of normalization schemes to a specified expression matrix.
}
\details{
Each normalization consists of three main steps:
\itemize{
 \item{Impute:}{ Replace observations of zeroes with expected expression values. }
 \item{Scale:}{ Match sample-specific expression scales or quantiles. }
 \item{Adjust:}{ Adjust for sample-level batch factors / unwanted variation. }
}
Following completion of each step, the normalized expression matrix is scored
based on SCONE's data-driven evaluation criteria.

Evaluation metrics are defined in \code{\link{score_matrix}}.
  Each metric is assigned a signature for conversion to scores:
  Positive-signature metrics increase with improving performance, including
  BIO_SIL, PAM_SIL, and EXP_WV_COR. Negative-signature metrics decrease with
  improving performance, including BATCH_SIL, EXP_QC_COR, EXP_UV_COR,
  RLE_MED, and RLE_IQR. Scores are computed so that higer-performing methods
  are assigned higher scores.
  

Note that if one wants to include the unnormalized data in the final
  comparison of normalized matrices, the identity function must be included 
  in the scaling list argument. Analogously, if one wants to include non-
  imputed data in the comparison, the scone::impute_null function must be 
  included.


If \code{run=FALSE} the normalization and evaluation are not run,
  but the function returns a matrix of parameters that will be run for
  inspection by the user.


If \code{return_norm="hdf5"}, the normalized matrices will be
  written to the \code{hdf5file} file. This must be a string specifying (a
  path to) a new file. If the file already exists, it will return error.
}

