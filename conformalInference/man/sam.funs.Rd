% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sam.R
\name{sam.funs}
\alias{sam.funs}
\title{Sparse additive models training and prediction functions.}
\usage{
sam.funs(m = 3, lambda = NULL, nlambda = 30, lambda.min.ratio = 0.005)
}
\arguments{
\item{m}{Number of spline functions to be used in the additive expansion of 
each variable. Default is 3.}

\item{lambda}{Sequence of lambda values over which training is performed.
This must be in decreasing order, and --- this argument should be used with
caution! When used, it is usually best to grab the sequence constructed by
one intial call to SAM (see examples). Default is NULL, which means that
the nlambda, lambda.min.ratio arguments will define the lambda sequence
(see next).}

\item{nlambda}{Number of lambda values over which training is performed. In
particular, the lambda sequence is defined by nlambda log-spaced values
between lambda.max and lambda.min.ratio * lambda.max, where lambda.max is
the smallest value of lambda at which the solution has all zero components,
and lambda.min.ratio is a small fraction (see next). Default is 30.}
}
\value{
A list with three components: train.fun, predict.fun, active.fun.
  The third function is designed to take the output of train.fun, and
  reports which features are active for each fitted model contained in
  this output.
}
\description{
Construct training and prediction functions for sparse additive models,
  based on the \code{\link{SAM}} package, over a sequence of (given or
  internally computed) lambda values.
}
\details{
This function is based on the packages \code{\link{SAM}} and
  \code{\link{plyr}}. If these packages are not installed, then the function
  will abort.
}
\examples{
## Sparse additive models: high-dimensional example

# Use the sim.xy function to get a data set with additive structure
set.seed(11)
n = 200; n0 = 200; p = 500; s = 10
obj = sim.xy(n+n0, p, mean.fun="additive", m=4, s=s, snr=3)
x = obj$x[1:n,]
y = obj$y[1:n]
x0 = obj$x[(n+1):(n+n0),]
y0 = obj$y[(n+1):(n+n0)]

# Grab a fixed lambda sequence from one call to samQL, then define the sparse
# additive models training and prediction functions
if (!require("SAM",quietly=TRUE)) {
  stop("Package SAM not installed (required for this example)!") 
}
out.sam = samQL(x,y,nlambda=50,lambda.min.ratio=1e-5)
lambda = out.sam$lambda
my.sam.funs = sam.funs(m=5,lambda=lambda)

# Random forest training and prediction functions
if (!require("randomForest",quietly=TRUE)) {
  stop("Package randomForest not installed (required for this example)!") 
}
my.rf.funs = rf.funs(ntree=500)

# Split conformal inference with sparse additive models and random forest
out.sam = conformal.pred.split(x, y, x0, alpha=0.1,
  train.fun=my.sam.funs$train, predict.fun=my.sam.funs$predict)

out.rf = conformal.pred.split(x, y, x0, alpha=0.1,
  train.fun=my.rf.funs$train, predict.fun=my.rf.funs$predict)

y0.mat = matrix(rep(y0,ncol(out.sam$lo)),nrow=n0)
cov.sam = colMeans(out.sam$lo <= y0.mat & y0.mat <= out.sam$up)
len.sam = colMeans(out.sam$up - out.sam$lo)
err.sam = colMeans((y0.mat - out.sam$pred)^2)

cov.rf = mean(out.rf$lo <= y0 & y0 <= out.rf$up)
len.rf = mean(out.rf$up - out.rf$lo)
err.rf = mean((y0 - out.rf$pred)^2)

# Plot average coverage 
plot(log(lambda),cov.sam,type="l",ylim=c(0,1),
     xlab="log(lambda)",ylab="Avg coverage",
     main=paste0("Split conformal + Spam, RF:\\nAverage coverage"))
points(log(lambda),cov.sam,pch=20)
abline(h=cov.rf,lty=2,col=4)
legend("bottomright",col=c(1,4),lty=1:2,
       legend=c("Spam","Random forest"))

# Plot average length
plot(log(lambda),len.sam,type="l",
     ylim=range(len.sam,len.rf),
     xlab="log(lambda)",ylab="Avg length",
     main=paste0("Split conformal + Spam, RF:\\nAverage length"))
points(log(lambda),len.sam,pch=20)
abline(h=len.rf,lty=2,col=4)
legend("topleft",col=c(1,4),lty=1:2,
       legend=c("Spam","Random forest"))

# Plot test error
plot(log(lambda),err.sam,type="l",
     ylim=range(err.sam,err.rf),
     xlab="log(lambda)",ylab="Test error",
     main=paste0("Split conformal + Spam, RF:\\nTest error"))
points(log(lambda),err.sam,pch=20)
abline(h=err.rf,lty=2,col=4)
legend("topleft",col=c(1,4),lty=1:2,
       legend=c("Spam","Random forest"))
}
\author{
Ryan Tibshirani
}

