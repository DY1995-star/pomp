% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/bsflu.R
\name{bsflu}
\alias{bsflu}
\title{Influenza outbreak in a boarding school}
\description{
An outbreak of influenza in an all-boys boarding school.
}
\details{
Data are recorded from a 1978 flu outbreak in a closed population.
The variable \sQuote{B} refers to boys confined to bed on the corresponding day and \sQuote{C} to boys in convalescence,
i.e., not yet allowed back to class.
In total, 763 boys were at risk of infection and, over the course of the outbreak, 512 boys spent between 3 and 7 days away from class (either in bed or convalescent).
The index case was a boy who arrived at school from holiday six days before the next case.
}
\examples{
library(magrittr)
library(tidyr)
library(ggplot2)

bsflu \%>\%
  gather(variable,value,-date,-day) \%>\%
  ggplot(aes(x=date,y=value,color=variable))+
  geom_line()+
  labs(y="number of boys",title="boarding school flu outbreak")+
  theme_bw()
}
\references{
\Anonymous1978
}
\seealso{
\link{sir_models}

More data sets provided with \pkg{pomp}: 
\code{\link{blowflies}},
\code{\link{dacca}()},
\code{\link{ebola}},
\code{\link{measles}},
\code{\link{parus}}

More examples provided with \pkg{pomp}: 
\code{\link{blowflies}},
\code{\link{dacca}()},
\code{\link{ebola}},
\code{\link{gompertz}()},
\code{\link{measles}},
\code{\link{ou2}()},
\code{\link{parus}},
\code{\link{pomp_examples}},
\code{\link{ricker}()},
\code{\link{rw2}()},
\code{\link{sir_models}},
\code{\link{verhulst}()}
}
\concept{pomp_datasets}
\concept{pomp_examples}
