% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/soy.R
\docType{data}
\name{soy}
\alias{soy}
\title{Soybean real data set}
\format{
\subsection{\code{soy}}{

A data frame with 823 rows and 6 columns:
\describe{
\item{environment}{14 evaluated environments}
\item{region}{Regions containing the evaluated environments: 1, 2 and 3}
\item{G}{39 evaluated genotypes}
\item{eBLUE}{435 Adjusted means (phenotypes)}
}
}
}
\source{
\describe{
Using soybean historical field trial data to study genotype by environment
variation and identify mega-environments with the integration of genetic
and non-genetic factors. Matheus D Krause, Kaio O G Dias, Asheesh K Singh,
William D Beavis. bioRxiv 2022.04.11.487885;
doi: https://doi.org/10.1101/2022.04.11.487885
}
}
\usage{
soy
}
\description{
A part of the data set used by Krause et al. (2023) regarding the USDA Northen
Region Uniform Soybean Tests. It contains 435 observations from 39 genotypes
evaluated at 14 environments and 3 breeding regions. Note that these data comprise
only the adjusted means (eBLUEs). The original data, available at the package
\code{SoyURT}, has 4,257 experimental genotypes evaluated at 63 locations and
31 years resulting in 591 location-year combinations (environments) with
39,006 yield values.
}
\keyword{datasets}
