
#******************** close all devices and delete all variables *************************#
rm(list=ls(all=TRUE))   # clear workspace
graphics.off()          # close any open graphics
closeAllConnections()   # close any open connections to files
#*****************************************************************************************#

#****************************** load required libraries **********************************#
### install and load required R packages
list.of.packages <- c("here","phenopix")  
# check for dependencies and install if needed
new.packages <- list.of.packages[!(list.of.packages %in% 
                                     installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
# load libraries
invisible(lapply(list.of.packages, library, character.only = TRUE))

# load helper functions
#code_dir <- file.path(here::here(),"Examples/Arctic_vegetation_phenology/code")
#helperfuns <- file.path(code_dir,"helperfuns_sos.R")
#source(helperfuns)
#*****************************************************************************************#

#*****************************************************************************************#
# define location of example image timeseries data
image_path <- file.path(here::here(),"Examples/Arctic_vegetation_phenology/example_data/images")

# set a reference image for drawing ROIs, e.g. 
reference_image <- "img_014_A77D7C5263D0_2021-08-17_150008.jpg" 

# set a primary ROI path to save the ROI objects
roi_path <- file.path(here::here(),"Examples/Arctic_vegetation_phenology/pheno_results/roi/")
if (! file.exists(roi_path)) dir.create(roi_path,recursive=TRUE)
#*****************************************************************************************#            

#*****************************************************************************************# 
# example, draw an ROI the includes a tall alder shrub and save to the 
# roi folder
roi_name <- "alder_roi1"
roi_path2 <- file.path(roi_path,roi_name)
if (! file.exists(roi_path2)) dir.create(roi_path2,recursive=TRUE)
phenopix::DrawMULTIROI(path_img_ref=file.path(image_path,reference_image), 
                       path_ROIs=file.path(roi_path2,"/"), nroi = 1, 
                       roi.names=as.vector(roi_name), 
                       file.type='.jpg')
# above temporary bug fix for path issues in the phenopix::DrawMULTIROI 
# function that doesnt properly create the full path and roi name unless
# you add a trailing / to the path_ROIs
# needs to be fixed in the DrawMULTIROI function on line 43
# https://github.com/cran/phenopix/blob/6aeac44999513eafacad31850e826c177903896e/R/DrawMULTIROI.R#L43
#*****************************************************************************************#

#*****************************************************************************************#
# load ROI data - a little clunky since the output doesnt go into
# the correct path_ROIs folder for some reason when using the
# phenopix::DrawMULTIROI function
load(file.path(roi_path2,"roi.data.Rdata"))
#*****************************************************************************************# 

#*****************************************************************************************#
# extract timeseries data from ROI
# ?extractVIs
temp <- phenopix::extractVIs(img.path=image_path, 
                             roi.path=file.path(roi_path2,"/"), 
                             roi.name=roi_name,
                             vi.path=file.path(roi_path2,"/"),
                   date.code = "yyyy-mm-dd_HHMMSS")
# !!! above temporary bug fix for path issues in the phenopix::extractVIs
# function that doesnt properly create the full path and roi name unless
# you add a trailing / to the path_ROIs 
# PhenoPix code needs to be fixed to provide correct combination of path
# and roi name so that the results end up in the desired sub-directory !!!
head(temp)

names(temp$alder_roi1)
head(temp$alder_roi1$date)
head(temp$alder_roi1$r.av)


plot(temp$alder_roi1$date[which(lubridate::hour(temp$alder_roi1$date)==15)],
     temp$alder_roi1$r.av[which(lubridate::hour(temp$alder_roi1$date)==15)])

# TODO - keep only daytime, sunny midday data
# change to match time with local time on camera
# 
#




#save(list = temp, file = file.path(roi_path,"example_extract.Rdata"))
#*****************************************************************************************#
#*
#*

#*
#*
#*
#*