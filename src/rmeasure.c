// dear emacs, please treat this as -*- C++ -*-

#include <R.h>
#include <Rmath.h>
#include <Rdefines.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>

#include "pomp_internal.h"

SEXP do_rmeasure (SEXP object, SEXP x, SEXP times, SEXP params, SEXP gnsi)
{
  int nprotect = 0;
  pompfunmode mode = undef;
  int ntimes, nvars, npars, ncovars, nreps, nrepsx, nrepsp;
  int nobs = 0;
  SEXP Snames, Pnames, Cnames, Onames = R_NilValue;
  SEXP cvec, tvec = R_NilValue, xvec = R_NilValue, pvec = R_NilValue;
  SEXP fn, fcall, rho = R_NilValue;
  SEXP pompfun;
  SEXP Y = R_NilValue;
  int *dim;
  int *sidx = 0, *pidx = 0, *cidx = 0, *oidx = 0;
  lookup_table_t covariate_table;
  pomp_measure_model_simulator *ff = NULL;

  PROTECT(times = AS_NUMERIC(times)); nprotect++;
  ntimes = length(times);
  if (ntimes < 1)
    errorcall(R_NilValue,"length('times') = 0, no work to do.");

  PROTECT(x = as_state_array(x)); nprotect++;
  dim = INTEGER(GET_DIM(x));
  nvars = dim[0]; nrepsx = dim[1];

  if (ntimes != dim[2])
    errorcall(R_NilValue,"length of 'times' and 3rd dimension of 'x' do not agree.");

  PROTECT(params = as_matrix(params)); nprotect++;
  dim = INTEGER(GET_DIM(params));
  npars = dim[0]; nrepsp = dim[1];

  nreps = (nrepsp > nrepsx) ? nrepsp : nrepsx;

  if ((nreps % nrepsp != 0) || (nreps % nrepsx != 0))
    errorcall(R_NilValue,"larger number of replicates is not a multiple of smaller.");

  PROTECT(Snames = GET_ROWNAMES(GET_DIMNAMES(x))); nprotect++;
  PROTECT(Pnames = GET_ROWNAMES(GET_DIMNAMES(params))); nprotect++;
  PROTECT(Cnames = get_covariate_names(GET_SLOT(object,install("covar")))); nprotect++;

  // set up the covariate table
  covariate_table = make_covariate_table(GET_SLOT(object,install("covar")),&ncovars);

  // vector for interpolated covariates
  PROTECT(cvec = NEW_NUMERIC(ncovars)); nprotect++;
  SET_NAMES(cvec,Cnames);

  // extract the user-defined function
  PROTECT(pompfun = GET_SLOT(object,install("rmeasure"))); nprotect++;
  PROTECT(fn = pomp_fun_handler(pompfun,gnsi,&mode)); nprotect++;

  // extract 'userdata' as pairlist
  PROTECT(fcall = VectorToPairList(GET_SLOT(object,install("userdata")))); nprotect++;

  // first do setup
  switch (mode) {
  case Rfun:			// use R function

    PROTECT(tvec = NEW_NUMERIC(1)); nprotect++;
    PROTECT(xvec = NEW_NUMERIC(nvars)); nprotect++;
    PROTECT(pvec = NEW_NUMERIC(npars)); nprotect++;
    SET_NAMES(xvec,Snames);
    SET_NAMES(pvec,Pnames);

    // set up the function call
    PROTECT(fcall = LCONS(cvec,fcall)); nprotect++;
    SET_TAG(fcall,install("covars"));
    PROTECT(fcall = LCONS(pvec,fcall)); nprotect++;
    SET_TAG(fcall,install("params"));
    PROTECT(fcall = LCONS(tvec,fcall)); nprotect++;
    SET_TAG(fcall,install("t"));
    PROTECT(fcall = LCONS(xvec,fcall)); nprotect++;
    SET_TAG(fcall,install("x"));
    PROTECT(fcall = LCONS(fn,fcall)); nprotect++;

    // get the function's environment
    PROTECT(rho = (CLOENV(fn))); nprotect++;

    break;

  case native:				// use native routine

    // construct state, parameter, covariate, observable indices
    PROTECT(Onames = GET_SLOT(pompfun,install("obsnames"))); nprotect++;
    sidx = INTEGER(PROTECT(name_index(Snames,pompfun,"statenames","state variables"))); nprotect++;
    pidx = INTEGER(PROTECT(name_index(Pnames,pompfun,"paramnames","parameters"))); nprotect++;
    cidx = INTEGER(PROTECT(name_index(Cnames,pompfun,"covarnames","covariates"))); nprotect++;
    oidx = INTEGER(PROTECT(name_index(Onames,pompfun,"obsnames","observables"))); nprotect++;
    nobs = LENGTH(Onames);

    // address of native routine
    *((void **) (&ff)) = R_ExternalPtrAddr(fn);

    break;

  default:

    errorcall(R_NilValue,"unrecognized 'mode'."); // # nocov

  break;

  }

  // now do computations
  switch (mode) {

  case Rfun:			// R function

  {
    int first = 1;
    double *yt = 0;
    double *time = REAL(times);
    double *tp = REAL(tvec);
    double *cp = REAL(cvec);
    double *xp = REAL(xvec);
    double *pp = REAL(pvec);
    double *xs = REAL(x);
    double *ps = REAL(params);
    double *ys;
    SEXP ans, ans1;
    int i, j, k;

    for (k = 0; k < ntimes; k++, time++) { // loop over times

      R_CheckUserInterrupt();	// check for user interrupt

      *tp = *time;		// copy the time
      table_lookup(&covariate_table,*tp,cp); // interpolate the covariates

      for (j = 0; j < nreps; j++) { // loop over replicates

        // copy the states and parameters into place
        for (i = 0; i < nvars; i++) xp[i] = xs[i+nvars*((j%nrepsx)+nrepsx*k)];
        for (i = 0; i < npars; i++) pp[i] = ps[i+npars*(j%nrepsp)];

        if (first) {

          // evaluate the call
          PROTECT(ans1 = eval(fcall,rho)); nprotect++;

          nobs = LENGTH(ans1);
          if (nobs < 1) {
            errorcall(R_NilValue,"zero-length result.");
          }
          PROTECT(Onames = GET_NAMES(ans1)); nprotect++;
          if (isNull(Onames)) {
            errorcall(R_NilValue,"'rmeasure' must return a named numeric vector.");
          }
          ys = REAL(AS_NUMERIC(ans1));

          // create array Y to hold the results
          {
            int dim[3] = {nobs, nreps, ntimes};
            const char *dimnm[3] = {"variable","rep","time"};
            PROTECT(Y = makearray(3,dim)); nprotect++;
            setrownames(Y,Onames,3);
            fixdimnames(Y,dimnm,3);
          }
          yt = REAL(Y);

          first = 0;

        } else {

          PROTECT(ans=eval(fcall,rho));
          if (LENGTH(ans) != nobs)
            errorcall(R_NilValue,"'rmeasure' returns variable-length results.");
          ys = REAL(AS_NUMERIC(ans));
          UNPROTECT(1);

        }

        for (i = 0; i < nobs; i++) yt[i] = ys[i];
        yt += nobs;

      }
    }
  }

    break;

  case native: 			// native routine

  {
    int dim[3] = {nobs, nreps, ntimes};
    const char *dimnm[3] = {"variable","rep","time"};

    PROTECT(Y = makearray(3,dim)); nprotect++;
    setrownames(Y,Onames,3);
    fixdimnames(Y,dimnm,3);

    double *yt = REAL(Y);
    double *time = REAL(times);
    double *xs = REAL(x);
    double *ps = REAL(params);
    double *cp = REAL(cvec);
    double *xp, *pp;
    int j, k;

    set_pomp_userdata(fcall);
    GetRNGstate();

    for (k = 0; k < ntimes; k++, time++) { // loop over times

      R_CheckUserInterrupt();	// check for user interrupt

      // interpolate the covar functions for the covariates
      table_lookup(&covariate_table,*time,cp);

      for (j = 0; j < nreps; j++, yt += nobs) { // loop over replicates

        xp = &xs[nvars*((j%nrepsx)+nrepsx*k)];
        pp = &ps[npars*(j%nrepsp)];

        (*ff)(yt,xp,pp,oidx,sidx,pidx,cidx,ncovars,cp,*time);

      }
    }

    PutRNGstate();
    unset_pomp_userdata();
  }

    break;

  default:

    errorcall(R_NilValue,"unrecognized 'mode'"); // # nocov

  break;

  }

  UNPROTECT(nprotect);
  return Y;
}
