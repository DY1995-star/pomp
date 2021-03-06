% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/bsmc2.R
\docType{methods}
\name{bsmc2}
\alias{bsmc2}
\alias{bsmc2,missing-method}
\alias{bsmc2,ANY-method}
\alias{bsmc2-data.frame}
\alias{bsmc2,data.frame-method}
\alias{bsmc2-pomp}
\alias{bsmc2,pomp-method}
\title{The Liu and West Bayesian particle filter}
\usage{
\S4method{bsmc2}{data.frame}(
  data,
  Np,
  smooth = 0.1,
  params,
  rprior,
  rinit,
  rprocess,
  dmeasure,
  partrans,
  ...,
  verbose = getOption("verbose", FALSE)
)

\S4method{bsmc2}{pomp}(data, Np, smooth = 0.1, ..., verbose = getOption("verbose", FALSE))
}
\arguments{
\item{data}{either a data frame holding the time series data,
or an object of class \sQuote{pomp},
i.e., the output of another \pkg{pomp} calculation.}

\item{Np}{the number of particles to use.
This may be specified as a single positive integer, in which case the same number of particles will be used at each timestep.
Alternatively, if one wishes the number of particles to vary across timesteps, one may specify \code{Np} either as a vector of positive integers of length \preformatted{length(time(object,t0=TRUE))} or as a function taking a positive integer argument.
In the latter case, \code{Np(k)} must be a single positive integer, representing the number of particles to be used at the \code{k}-th timestep:
\code{Np(0)} is the number of particles to use going from \code{timezero(object)} to \code{time(object)[1]},
\code{Np(1)}, from \code{timezero(object)} to \code{time(object)[1]},
and so on,
while when \code{T=length(time(object))}, \code{Np(T)} is the number of particles to sample at the end of the time-series.}

\item{smooth}{Kernel density smoothing parameter.
The compensating shrinkage factor will be \code{sqrt(1-smooth^2)}.
Thus, \code{smooth=0} means that no noise will be added to parameters.
The general recommendation is that the value of \code{smooth} should be chosen close to 0 (e.g., \code{shrink} ~ 0.1).}

\item{params}{optional; named numeric vector of parameters.
This will be coerced internally to storage mode \code{double}.}

\item{rprior}{optional; prior distribution sampler, specified either as a C snippet, an \R function, or the name of a pre-compiled native routine available in a dynamically loaded library.
For more information, see \link[=prior_spec]{?prior_spec}.
Setting \code{rprior=NULL} removes the prior distribution sampler.}

\item{rinit}{simulator of the initial-state distribution.
This can be furnished either as a C snippet, an \R function, or the name of a pre-compiled native routine available in a dynamically loaded library.
Setting \code{rinit=NULL} sets the initial-state simulator to its default.
For more information, see \link[=rinit_spec]{?rinit_spec}.}

\item{rprocess}{simulator of the latent state process, specified using one of the \link[=rprocess_spec]{rprocess plugins}.
Setting \code{rprocess=NULL} removes the latent-state simulator.
For more information, \link[=rprocess_spec]{see ?rprocess_spec for the documentation on these plugins}.}

\item{dmeasure}{evaluator of the measurement model density, specified either as a C snippet, an \R function, or the name of a pre-compiled native routine available in a dynamically loaded library.
Setting \code{dmeasure=NULL} removes the measurement density evaluator.
For more information, see \link[=dmeasure_spec]{?dmeasure_spec}.}

\item{partrans}{optional parameter transformations, constructed using \code{\link{parameter_trans}}.

Many algorithms for parameter estimation search an unconstrained space of parameters.
When working with such an algorithm and a model for which the parameters are constrained, it can be useful to transform parameters.
One should supply the \code{partrans} argument via a call to \code{\link{parameter_trans}}.
For more information, see \link[=parameter_trans]{?parameter_trans}.
Setting \code{partrans=NULL} removes the parameter transformations, i.e., sets them to the identity transformation.}

\item{...}{additional arguments supply new or modify existing model characteristics or components.
See \code{\link{pomp}} for a full list of recognized arguments.

When named arguments not recognized by \code{\link{pomp}} are provided, these are made available to all basic components via the so-called \dfn{userdata} facility.
This allows the user to pass information to the basic components outside of the usual routes of covariates (\code{covar}) and model parameters (\code{params}).
See \link[=userdata]{?userdata} for information on how to use this facility.}

\item{verbose}{logical; if \code{TRUE}, diagnostic messages will be printed to the console.}
}
\value{
An object of class \sQuote{bsmcd_pomp}.
The following methods are avaiable:
\describe{
\item{\code{\link[=plot,bsmcd_pomp-method]{plot}}}{produces diagnostic plots}
\item{\code{\link{as.data.frame}}}{puts the prior and posterior samples into a data frame}
}
}
\description{
Modified version of the Liu and West (2001) algorithm.
}
\details{
\code{bsmc2} uses a version of the original algorithm (Liu \& West 2001), but discards the auxiliary particle filter.
The modification appears to give superior performance for the same amount of effort.

Samples from the prior distribution are drawn using the \code{rprior} component.
This is allowed to depend on elements of \code{params}, i.e., some of the elements of \code{params} can be treated as \dQuote{hyperparameters}.
\code{Np} draws are made from the prior distribution.
}
\section{Note for Windows users}{


Some Windows users report problems when using C snippets in parallel computations.
These appear to arise when the temporary files created during the C snippet compilation process are not handled properly by the operating system.
To circumvent this problem, use the \code{cdir} and \code{cfile} options \link[=pomp]{(described here)} to cause the C snippets to be written to a file of your choice, thus avoiding the use of temporary files altogether.
}

\references{
Liu, J. and M. West.
Combining Parameter and State Estimation in Simulation-Based Filtering.
In A. Doucet, N. de Freitas, and N. J. Gordon, editors,
Sequential Monte Carlo Methods in Practice, pages 197-224.
Springer, New York, 2001.
}
\seealso{
More on particle-filter based methods in \pkg{pomp}: 
\code{\link{cond.logLik}()},
\code{\link{eff.sample.size}()},
\code{\link{filter.mean}()},
\code{\link{filter.traj}()},
\code{\link{kalman}},
\code{\link{mif2}()},
\code{\link{pfilter}()},
\code{\link{pmcmc}()},
\code{\link{pred.mean}()},
\code{\link{pred.var}()},
\code{\link{saved.states}()},
\code{\link{wpfilter}()}

More on \pkg{pomp} estimation algorithms:
\code{\link{abc}()},
\code{\link{estimation_algorithms}},
\code{\link{kalman}},
\code{\link{mif2}()},
\code{\link{nlf}},
\code{\link{pmcmc}()},
\code{\link{pomp-package}},
\code{\link{probe.match}},
\code{\link{spect.match}}
}
\author{
Michael Lavine, Matthew Ferrari, Aaron A. King, Edward L. Ionides
}
\concept{estimation_methods}
\concept{particle_filter_methods}
