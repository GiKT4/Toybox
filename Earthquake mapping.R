## Description:  This program aims to visually expore the locations and magnitude of past earthquakes in Canada

## Compiled by:  Kevin Turner

## Date created:  25-March-2019

## References to check out:  https://apps.fishandwhistle.net/archives/1490
##                           https://twitter.com/paleolimbot/status/1031704526036729856
##                           https://gist.github.com/paleolimbot/ee29b6915f77a5ae97426f20f7fc10ba
##                           https://gganimate.com/articles/gganimate.html 
##                           https://www.r-spatial.org/r/2018/10/25/ggplot2-sf.html 

year_interest <- 2018

# You have to install packages that are not provided in R base functionality.
# You can do this manually under the Packages tab to the right too.

#install.packages(c("rgdal", "sp", "sf", "ggspatial", "Tidyverse", "glue", "ggplot2",
#          "RColorBrewer", "gganimate", "gifski", "ggspatial", "transformr"))

library(rgdal)
library(sp)

# set the working directory according to where you want the data
setwd("/Users/Kevin/Documents/Kevin/Brock/Courses/GEOG_3P04/Lectures/2018-19 lectures/Lecture 11 - Mapping Time/R demo")

## option if we want the program to download the data for us, use the following lines
curl::curl_download(
  "http://ftp.maps.canada.ca/pub/nrcan_rncan/Earthquakes_Tremblement-de-terre/canadian-earthquakes_tremblements-de-terre-canadien/eqarchive-en.csv", 
  "eqarchive-en.csv"
)

Can_EarthQs <- read.table("eqarchive-en.csv", header = TRUE, sep = ",")
## data came from:  http://ftp.maps.canada.ca/pub/nrcan_rncan/Earthquakes_Tremblement-de-terre/canadian-earthquakes_tremblements-de-terre-canadien/eqarchive-en.csv

##  We can turn our data into a shapefile for other software if we like...
Can_EarthQs_spatdf <- read.table("eqarchive-en.csv", header = TRUE, sep = ",")
coordinates(Can_EarthQs_spatdf)<-~longitude+latitude # whatever the equivalent is in your table
proj4string(Can_EarthQs_spatdf) <- CRS("+init=epsg:4326")  #  you can get list of spatial reference codes here: http://spatialreference.org/ref/epsg/
writeOGR(Can_EarthQs_spatdf, ".", "Can_EarthQs", driver = "ESRI Shapefile", overwrite_layer = TRUE)

##  Getting back to analysis and data visualization in R:

## Need a few other packages first

library(transformr) # this is required to deal with simple feature (sf) layers in animation 
library(ggplot2)  # this provides some nice plotting capabilities
library(RColorBrewer)  # provides index of colours that can be used in plots
library(gganimate)  # require ImageMagick
library(gifski) # needed for making a gif
library(tidyverse)# works well with ggspatial
library(sf) # needed for running ggspatial
library(glue)

library(ggspatial)  # this package has the animate function

## Get into data to set up timing of animation plot  	
#  Have to work with the date and time format:  1985-01-01T11:01:00+0000
Can_EarthQs$eventDate <- as.POSIXct(strptime(Can_EarthQs$date, format = "%Y-%m-%dT%H:%M:%S+0000", tz = "GMT"))
Can_EarthQs$month <- as.numeric(format(Can_EarthQs$eventDate, "%m"))
Can_EarthQs$year <- as.numeric(format(Can_EarthQs$eventDate, "%Y"))
Can_EarthQs$magnitude <- as.numeric(Can_EarthQs$magnitude)

recent_quakes <-  subset(Can_EarthQs, Can_EarthQs$year >= year_interest) 
recent_quakes <- st_as_sf(recent_quakes, coords = c("longitude", "latitude"), crs = 4326)
recent_quakes <- st_transform(recent_quakes, 3978)

## This line will customize the points to be red and have a size relative to magnitude
#quake_pts <- geom_point(data = recent_quakes, aes(longitude, latitude),colour = 'red', alpha = .5, size = recent_quakes$magnitude * 2)
quake_pts <- layer_spatial(recent_quakes, size= recent_quakes$magnitude * 2, col = "red", alpha = 0.5) # this line makes a ggplot2 layer

########################### Make basemap of Canada
library("rnaturalearth")
library("rnaturalearthdata")

Canada <- ne_countries(scale = "medium", returnclass = "sf", country = "Canada")
Canada <- st_transform(Canada, 3978)

Canada_map <- ggplot(data = Canada) + geom_sf() +      ##quake_pts +  # Can put in quake_pts if just a static map
  annotation_scale(location = "bl", width_hint = 0.5) + 
  annotation_north_arrow(location = "bl", which_north = "true", pad_x = unit(0.2, "in"), pad_y = unit(0.5, "in"), style = north_arrow_fancy_orienteering) # +
                                                                               
  #coord_sf(xlim = c(-150, -32), ylim = c(40, 86))  # these are bounding coordinates for Canada if needed

########################### Make animation
anim <- Canada_map + quake_pts +        
  transition_states(eventDate, transition_length = 1, state_length = 1) +
  labs(
    title = 'Earthquakes in Canada during {closest_state}',    #"Earthquakes in Canada during, # {quake_pts[[1]]$data$magnitude}", # 2018  I want the date to change with the frames
    caption = "Data: Natural Resources Canada",
    x = NULL,
    y = NULL
  ) +
  enter_fade() +
  exit_fade()

animate(anim)
anim_save("Canada_Earthquakes_2018.gif")

