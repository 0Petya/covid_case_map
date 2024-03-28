library(dplyr)
library(htmlwidgets)
library(leaflet)
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

popup <- paste0(counties_and_cases$NAMELSAD, ", ", case_increases$Province_State, "<br>", "Cases: ", counties_and_cases$`X10.7.20`)
pal <- colorNumeric(palette = "YlGnBu", domain = c(0, max(st_drop_geometry(counties_and_cases[,11:ncol(counties_and_cases)]))))

map <- leaflet(counties_and_cases) %>%
  addProviderTiles("CartoDB.PositronNoLabels") %>%
  addPolygons(fillColor = ~pal(`X10.7.20`), color = "#b2aeae", fillOpacity = 0.7, weight = 1, smoothFactor = 0.2, popup = popup, group = "10/7/20") %>%
  addPolygons(fillColor = ~pal(`X10.14.20`), color = "#b2aeae", fillOpacity = 0.7, weight = 1, smoothFactor = 0.2, popup = popup, group = "10/14/20") %>%
  addPolygons(fillColor = ~pal(`X10.21.20`), color = "#b2aeae", fillOpacity = 0.7, weight = 1, smoothFactor = 0.2, popup = popup, group = "10/21/20") %>%
  addLegend(pal = pal, values = as.vector(as.matrix(st_drop_geometry(counties_and_cases[,11:ncol(counties_and_cases)]))), position = "bottomright", title = "Cases") %>%
  addLayersControl(baseGroups = c("10/7/20", "10/14/20", "10/21/20"), options = layersControlOptions(collapsed = FALSE))

# for (col in colnames(st_drop_geometry(counties_and_cases[,11:ncol(counties_and_cases)]))) {
#   map <- addPolygons(map, fillColor = ~pal(counties_and_cases[[col]]), color = "#b2aeae", fillOpacity = 0.7, weight = 1, smoothFactor = 0.2, popup = popup, group = col)
# }
# 
# map <- addLayersControl(map, baseGroups = colnames(st_drop_geometry(counties_and_cases[,11:ncol(counties_and_cases)])), options = layersControlOptions(collapsed = F))

# map
# saveWidget(map, file = "map.html", selfcontained = F)
