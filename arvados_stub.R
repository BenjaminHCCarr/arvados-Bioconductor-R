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
