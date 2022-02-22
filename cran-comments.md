## Changes in this revised submission

* I have reworded the description so that it does not begin with the title.

* I have added missing \value{} information for exported functions.

* I have documented the structure of the opafit class including details of the
components of the returned list.

* I have removed the \dontrun{} wrappers from the examples and verified that
they run using R CMD check.

## R CMD check results
There were no ERRORs or WARNINGs. 

There was 1 NOTE:

* Possibly mis-spelled words in DESCRIPTION:
    Grice (10:5)
    Thorngate (9:5)
    al (10:14)
    et (10:11)
    
    "Grice" and "Thorngate" are proper names. 
    "al" and "et" are used in APA-style citation text.
    
* Found the following (possibly) invalid URLs:
  URL: https://doi.org/10.1177/2158244015604192
    From: README.md
    Status: 503
    Message: Service Unavailable

* Found the following (possibly) invalid DOIs:
    DOI: 10.1177/2158244015604192
    From: DESCRIPTION
    Status: Service Unavailable
    Message: 503
    
    I have manually checked that this DOI is correct and that 
    https://doi.org/10.1177/2158244015604192 resolves to the valid URL
    https://journals.sagepub.com/doi/10.1177/2158244015604192
