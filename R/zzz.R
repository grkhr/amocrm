.onAttach <- function(lib, pkg,...){
  packageStartupMessage(welcomeMessage())
}

welcomeMessage <- function(){
  # library(utils)

  paste0(
         "You are using AmoCRM API client version ", utils::packageDescription("amocrm")$Version, "\n",
         "\n",
         "Please READ the following manual on github: https://github.com/grkhr/amocrm\n",
         "Type ?amocrm for the key features.\n",
         "\n",
         "To suppress this message use:  ", "suppressPackageStartupMessages(library(amocrm))"
  )
}
