#' Likelihood function of the logistic model
#' @param Z data matrix
#' @param X sample-level values
#' @param Beta gene-level values
#' 
likfn = function(Z,X,Beta){
  return((1-Z) + (2*Z - 1)/(1+exp(-X %*% Beta)))
}

#' Posterior probability of detection
#' @param Y detection matrix.
#' @param W sample-level drop-out coefficients.
#' @param Alpha gene-level drop-out features.
#' @param X sample-level expression features.
#' @param Beta gene-level sample coefficients.
#'
pzfn = function(Y,W,Alpha,X,Beta){
  matA = likfn(1,X,Beta)
  matB = matA*likfn(Y,W,Alpha)
  return(matB/(matB + (Y == 0)*(1-matA)))
}

#' Parameter estimation of zero-inflated bernoulli model
#' 
#' This function implements an EM algorithm to estimate the parameters of a zero-inflated bernoulli model
#' 
#' This function implements an expectation-maximization algorithm for a zero-inflated
#' bernoulli model of transcript detection, modeling gene expression state (off of on) 
#' as a bernoulli draw on a gene-specific expression rate (Z in {0,1}). Detection conditioned
#' on expression is a logistic function of gene-level features. The bernoulli model is modeled 
#' numerically by a logistic model with an intercept.
#'  
#' @param x matrix. An expression data matrix (genes in rows, cells in columns)
#' @param fp_tresh numeric. Threshold for calling a positive detection (D = 1). Default 0.
#' @param gfeatM matrix. Numeric gene level determinants of drop-out (genes in rows, features in columns)
#' @param bulk_model logical. Use median log-expression of gene in detected fraction as sole gene-level feature. Default FALSE.
#' Ignored if gfeatM is specified.
#' @param pos_controls logical. TRUE for all genes that are known to be expressed in all cells. 
#' @param em_tol numeric. Convergence treshold on log-likelihood.
#' @param maxiter numeric. The maximum number of iterations. Default 100.
#' @param verbose logical. Whether or not to print the value of the likelihood at each iteration.
#' 
#' @export
#' 
#' @return a list with the following elements:
#' \itemize{
#' \item{W}{ coefficients of sample-specific logistic drop-out model }
#' \item{Alpha}{ intercept and gene-level parameter matrix }
#' \item{X}{ intercept }
#' \item{Beta}{ coefficient of gene-specific logistic expression model }
#' \item{fnr_character}{ the probability, per gene, of P(D=0|E=1)}
#' \item{p_nodrop}{ 1 - the probability P(drop|Y), useful as weights in weighted principal components analysis}
#' \item{expected_state}{ the expected value E[Z] (1 = "on")}
#' \item{loglik}{ the log-likelihood}
#' \item{convergence}{ 0 if the algorithm converged and 1 if maxiter was reached}
#' }

estimate_ziber = function(x, fp_tresh = 0, 
                          gfeatM = NULL, bulk_model = FALSE, 
                          pos_controls = NULL,
                          em_tol = 0.01, maxiter = 100,
                          verbose = FALSE){
  
  Y = t(matrix(as.numeric( x > fp_tresh ),nrow = dim(x)[1]))
  
  if(is.null(gfeatM) & bulk_model){
    x2 = x
    x2[x2 <= fp_tresh] = NA
    Alpha = t(matrix(log(rowMedians(x2, na.rm=TRUE))))
  }else{
    if(is.null(gfeatM)){
      stop("No gene-level features specified")
    }
    Alpha = t(gfeatM)
  }
  
  # Prepare Gene-Intrinsic Intercept
  X = matrix(1,dim(x)[2],1)
  Beta = matrix(0,1,dim(x)[1])
  
  # Prepare Unwanted Variation and Sample-Intrinsic Intercept
  Alpha = rbind(Alpha,rep(1,dim(x)[1]))
  K = dim(Alpha)[1]
  W = matrix(0,dim(x)[2],K)
  
  # Initialize Z
  Z = pzfn(Y,W,Alpha,X,Beta)
  
  if(is.null(pos_controls)){
    stop("Must supply positive controls genes to fit FNR characteristic")
  }
    
  # Fit W once using control genes
  
  cY = Y[,pos_controls]
  cAlpha = Alpha[,pos_controls]
  for (i in 1:dim(Z)[1]){
    W[i,] = glm(cbind(cY[i,],1-cY[i,]) ~ 0 + t(cAlpha),quasibinomial)$coefficients
  } 
  Beta[,pos_controls] = NA
  Z[,pos_controls] = 1
  
  matA = likfn(1,X,Beta)
  EL2 = sum(Z*log(likfn(Y,W,Alpha)),na.rm = TRUE) + sum(Z*log( matA ),na.rm = TRUE) + sum((1-Z)*log(1- matA ),na.rm = TRUE)
  
  if(verbose){print(EL2)}
  
  EL1 = 2*EL2
  
  niter = 1
  while( is.infinite(EL1) | (EL2 - EL1) > em_tol ) {   
    
    EL1 = EL2
    
    # Update Beta
    cmz = colMeans(Z[,!pos_controls])
    Beta[,!pos_controls] = t(matrix(log(cmz) - log(1-cmz)))
    # Update Z
    Z[,!pos_controls] = pzfn(Y[,!pos_controls],W,Alpha[,!pos_controls],X,Beta[,!pos_controls])
    
    matA = likfn(1,X,Beta)
    EL2 = sum(Z*log(likfn(Y,W,Alpha)),na.rm = TRUE) + sum(Z*log( matA ),na.rm = TRUE) + sum((1-Z)*log(1- matA ),na.rm = TRUE)
    if(verbose){print(EL2)}
    niter = niter + 1
    if(niter >= maxiter){
      return(list(W = W, X = X, Alpha = Alpha, Beta = Beta,
                  fnr_character = t(likfn(1,W,Alpha)), p_nodrop = 1 - t((Y <= fp_tresh)*Z), 
                  expected_state = t(Z), loglik = EL2, convergence = 1))    }
  }

  return(list(W = W, X = X, Alpha = Alpha, Beta = Beta,
              fnr_character = t(likfn(1,W,Alpha)), p_nodrop = 1 - t((Y <= fp_tresh)*Z), 
              expected_state = t(Z), loglik = EL2, convergence = 0))
}

#' Imputation of zero abundance based on general zero-inflated model
#' 
#' This function is used to impute the data, weighted by probability of 
#' data coming from the zero-inflation part of the distribution.
#'
#' @details The imputation is carried out with the following formula:
#' y_{ij}* =  y_{ij} * Pr( No Drop | y_{ij}) + mu_{i} * Pr( Drop | y_{ij}).
#' 
#' impute_args must contain two elements: 
#' 1) p_nodrop  = posterior probability of data not having resulted from drop-out  (genes in rows, cells in columns)
#' 2) mu  = expected expression of dropped data (genes in rows, cells in columns)
#'  
#' @export
#' 
#' @param expression the data matrix (genes in rows, cells in columns)
#' @param impute_args arguments for imputation (see details)
#' 
#' @return the imputed expression matrix.
#' 

impute_expectation <- function(expression,impute_args) {
  imputed <- expression * impute_args$p_nodrop + impute_args$mu * (1 - impute_args$p_nodrop)
  return(imputed)
}

#' Null or no-op imputation
#' @export
#' 
#' @param expression the data matrix (genes in rows, cells in columns)
#' @param impute_args arguments for imputation (not used)
#' 
#' @return the imputed expression matrix.
#' 

impute_null <- function(expression,impute_args) {
  return(expression)
}
