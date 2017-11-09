# [R SDK] Create a Bioconductor/R SDK

This repo is for work by @BenjaminHCCarr and any collaborators for work on the ticket: https://dev.arvados.org/issues/11876

---

## Description

Overview:

As an R programmer I'd like to have the ability to query the Arvados APIs directly from R using a package which integrates well with and is published with the rest of the Bioconductor packages. The SDK should ideally allow me to do everything a Python programmer can do using the Python SDK.

As a first step, the R SDK should allow me to allow to find collections and files in Keep using filtering on metadata, load the files into R, process them and then write the results back to a collection.

As an optional second stage, it'd be useful to be able to submit CWL jobs and monitor their progress.

The SDK should work on Windows, OS X, and Linux, which implies that depending on arv-mount for file reading and writing is not an acceptable option. Instead, we will use the webdav support in keep-web. Read-only support is already available (completed in issue [#12216](https://dev.arvados.org/issues/12216)). Write support is forthcoming, see issue [#12483](https://dev.arvados.org/issues/12483).

A potential supporting component might be googleAuthR http://code.markedmondson.me/googleAuthR/ which could be used in a similar way to googleComputeEngineR https://cloudyr.github.io/googleComputeEngineR/ and other packages which are layered on it. googleAuthR can be used for API generation and response parsing, but needs to be reworked to not assume Google authentication or endpoints. Instead of the OAuth2 dance, it needs to be able to use an API token.

This code snippet will generate an entire R stub package using googleAuthR:
```
library('googleAuthR')
url="https://qr1hi.arvadosapi.com/discovery/v1/apis/arvados/v1/rest"
req <- httr::RETRY("GET", url)
httr::stop_for_status(req)
content <- httr::content(req,as="text")
api_description <- jsonlite::fromJSON(content)
paste("Loaded API description ", api_description$name, api_description$version)

"Generating API skeleton"
gar_create_api_objects(filename = "arvados_objects.R",api_json = api_description)
gar_create_api_skeleton('arvados_functions.R', api_description, format=TRUE)
"API Generation complete"

# Make sure we can load our newly generated code
source('arvados_functions.R')
source('arvados_objects.R')

# Generate the whole package at once
gar_create_package(api_description, '/tmp/aRv', rstudio = TRUE, check = TRUE, github = FALSE)
```

There `gar_create_package` call does the whole thing including man pages, README, etc, but the `gar_create_api_objects` and `gar_create_api_skeleton`, can be used to just do a part of the process.

The generator assumes the context of a Google API, so has a bunch of built-in assumptions that need to be cleaned up. Below is a non-exhaustive list:
- authentication - switch from Google auth to Arvados token based authentication, remove/fix all references to googleAuthR::gar_auth() and Google API scopes
- fixed base URL - in the above example qr1hi.arvadosapi.com is hardwired into the API. This needs to be configurable by the caller.
man page generation - there's a bunch of warnings due formatting in the docs
- Bioconductor packaging, types, conventions,tests - the core generator targets CRAN tests. This may need to be extended for Bioconductor
- LICENSE & AUTHOR - these are wrong need to figure out where their contents come from
Arvados specific things to pay attention to:
- URL encoding of JSON in query string
- Arvados objects - Collections - manifest parsing, updating, etc.
- WebDAV client to Arvados WebDAV server (depends
- Remove unused / disabled APIs e.g. Crunch1
- Add Jenkins CI job

It is desirable that changes to the code generator be done in such as way that they can be adopted by the upstream project as parameterizable options, but it's not mandatory.

There are also additional things which need to be added:
- tests
- vignettes/examples

---

Some hints on testing and other advanced API topics are here:
- http://code.markedmondson.me/googleAuthR/articles/advanced-building.html

There are two relevant packages, SevenBridges "`sevenbridges`" and Illumina's "`BaseSpaceR`", which could be used to compare against or as sources for code (they are both Apache licensed).

- http://bioconductor.org/packages/release/bioc/html/sevenbridges.html
- https://github.com/sbg/sevenbridges-r
- http://bioconductor.org/packages/release/bioc/html/BaseSpaceR.html
- https://developer.basespace.illumina.com/docs/content/documentation/sdk-samples/r-sdk-overview
