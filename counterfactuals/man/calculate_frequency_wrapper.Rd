% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Counterfactuals.R
\name{calculate_frequency_wrapper}
\alias{calculate_frequency_wrapper}
\title{Calculate frequency of altered features in final solution set}
\usage{
calculate_frequency_wrapper(
  counterfactual,
  target = NULL,
  obs = NULL,
  row.ids = NULL,
  plot = FALSE
)
}
\description{
Identify leverages that alter prediction to desired target
 over multiple datapoints. Leverages are identified by calculating
 the frequency a feature was altered within the set of the
 final calculated counterfactuals.
}
\section{Arguments}{

\describe{
\item{counterfactual: }{(Counterfactuals)\cr Instance of class
Counterfactual to extract
dataset and target, if not needed, as well as all the parameters}
\item{target: }{(numeric(1)|numeric(2))\cr Desired outcome either a
single numeric or
a vector of two numerics, to define a desired interval of outcome.}
\item{obs: }{(data.frame) Data frame to use to identify leverages
by calculating counterfactuals for them}
\item{row.ids }{(integer) Rows with the specific row.ids are extracted
from the input data defined in the predictor field of the
Counterfactuals class. The subset is used to identify leverages.}
\item{plot: }{(logical(1)) Whether to plot the frequency over all
observations}
}
}

