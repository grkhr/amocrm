% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/AmoUsers.R
\name{AmoUsers}
\alias{AmoUsers}
\title{Users from account}
\usage{
AmoUsers(email = NULL, apikey = NULL, domain = NULL, auth_list = NULL)
}
\arguments{
\item{email}{Email}

\item{apikey}{Your api key from settings in interface}

\item{domain}{Your domain in AmoCRM (xxx in xxx.amocrm.ru)}

\item{auth_list}{List with auth data, you can build from AmoAuthList}
}
\value{
Dataframe in output.
}
\description{
Function to get users.
}
\examples{
\dontrun{
users <- AmoUsers(auth_list = auth_list)
}
}
\references{
Please \strong{READ} this:
\href{https://github.com/grkhr/amocrm/blob/master/md/AmoUsers.md}{Function documentation in Russian on GitHub}

Also nice to read:
\href{https://www.amocrm.ru/developers/content/api/account}{AmoCRM official documentation}
}
