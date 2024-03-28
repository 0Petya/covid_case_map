library(dplyr)
library(readr)
library(tigris)

options(tigris_use_cache = T)

dir.create("./data/", showWarnings = F)
download.file("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv", "./data/time_Series_covid19_confirmed_US.csv")

cases <- read_csv("./data/time_Series_covid19_confirmed_US.csv") %>%
  filter(!(Province_State %in% c("Hawaii", "Alaska", "Puerto Rico")))

counties <- counties(cb = T, resolution = "500k")
counties$FIPS <- as.numeric(paste0(counties$STATEFP, counties$COUNTYFP))

counties_with_data <- counties[counties$FIPS %in% cases$FIPS,]
cases_with_shape <- cases[cases$FIPS %in% counties$FIPS,]
counties_with_data <- counties_with_data %>% arrange(factor(FIPS, levels = cases_with_shape$FIPS))

case_increases <- cases_with_shape[,1:11]
for (i in seq(12, ncol(cases_with_shape) - 7, 7)) {
  case_increases[colnames(cases_with_shape)[i]] <- cases_with_shape[i+6]-cases_with_shape[i]
}

counties_and_cases <- cbind(counties_with_data, case_increases[,12:ncol(case_increases)])
colnames(counties_and_cases)[11:(ncol(counties_and_cases)-1)] <- gsub("X", "", gsub("\\.", "/", colnames(counties_and_cases)[11:(ncol(counties_and_cases)-1)]))

file.remove("./data/counties_and_cases.geojson")
st_write(counties_and_cases, "./data/counties_and_cases.geojson")

dates <- colnames(counties_and_cases)[11:(ncol(counties_and_cases)-1)]
dates_js <- paste("dates = [", paste(paste("'", dates, "'", sep = ""), collapse = ", "), "];", sep = "")
writeLines(dates_js, "./data/map_data.js")
