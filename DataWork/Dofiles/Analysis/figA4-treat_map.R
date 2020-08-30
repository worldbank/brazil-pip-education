  # --------------------------------------------------------------------------- #
  #                                                                             #
  #                                     PIP                                     #                                     
  #                                 Mapping script                              #                           
  #                                                                             #
  # --------------------------------------------------------------------------- #
  
  # PURPOSE: Produce map in Figure A1 
  
  # NOTES: This can only by run by the authors as it employs identified data
  #        on schools who participate to the experiment.
  #        The script is provided just for informative purpose.
  
  # WRITTEN BY: Matteo Ruzzante [mruzzante@worldbank.org]
  
  #                                                  Last modified in August 2020
  

  # PART 0: Clear boiler plate --------------------------------------------------
  
  rm(list=ls())
  
  
  # PART 1: Load packages   -----------------------------------------------------
  
  # Before running this you need to have installed at least Rtools 3.3 from here https://cran.r-project.org/bin/windows/Rtools/
  
  # List packages used
  packages  <- c("dplyr"        ,
                 "foreign"      ,
                 "geosphere"    ,
                 "ggmap"        ,
                 "ggplot2"      ,
                 "RColorBrewer" ,
                 "rgdal"        ,
                 "rgeos"        ,
                 "sp"
  )
  
  # Install packages that are not yet installed
  sapply(packages, function(x) {
    if (!(x %in% installed.packages())) {
      install.packages(x, dependencies = TRUE) 
    }
  }
  )
  
  # Load all packages -- this is equivalent to using library(package) for each 
  # package listed before
  invisible(sapply(packages, library, character.only = TRUE))
  
  
  # PART 2: Set folder folder paths --------------------------------------------
  
  #-------------#
  # Root folder #
  #-------------#
  
  # Add your username and folder path here (for Windows computers)
  # To find out what your username is, type Sys.getenv("USERNAME")
  if (Sys.getenv("USERNAME") == "ruzza") {
    dataFolder <- ""
    github     <- "C:/Users/ruzza/OneDrive/Documenti/GitHub/brazil-pip-education"
  }
  
  if (Sys.getenv("USERNAME") == "") {
    dropbox <- ""
    github  <- ""
  }
  
  #--------------------#
  # Project subfolders #
  #--------------------#
  
  identified_data <- file.path(dataFolder, "Identified data")
  out_fig         <- file.path(githubRepo, "DataWork", "Output", "Figures")
  
  
  # PART 3: Create map ---------------------------------------------------------
  
  # Load CSV data
  GPS_coordinates_all_schools <- read.csv(file.path(identified_data,"GPS_schools.csv"),
                                          header = T)
  # Input Google API key
  register_google(key = "")
  
  # Set a range to zoom on
  lat <- c(-39.25, -34.25)                
  lon <- c(-7.25, -4.25)   
  
  # Get a basemap
  baseMap <- get_map(c(-38.5, -7.05, -34.5, -4.75))
  
  # Overlay schoolGPS coodinates and other figure options
  treatMap <-
    ggmap(baseMap,
          extent = "panel",
          darken = 0.05) + 
    geom_point(data = GPS_coordinates_all_schools,
               size = 1.25,
               aes(x     = longitude,
                   y     = latitude,
                   group = treated_school,
                   shape = factor(treated_school),
                   color = factor(treated_school)))  +
    xlab("Longitude") + 
    ylab("Latitude" ) +
    scale_color_manual(name = "Group", # or name = element_blank()
                       labels = c("Control", "Treatment"),
                       values = c((rgb(26,  71, 111, maxColorValue = 255)),
                                  (rgb( 0, 139, 188, maxColorValue = 255)))) +
    scale_shape_manual(name   = "Group",
                       labels = c("Control", "Treatment"),
                       values = c(16, 17)) +
    theme(text = element_text(size = 7.5))
  
  # Plot map in R
  treatMap
  
  # Save figure in PNG format
  ggsave(file.path(out_fig,"treat_map.png"))
  