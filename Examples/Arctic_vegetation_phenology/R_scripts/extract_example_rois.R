###########################################################################################
#
#  This R script will walk the user through an example showing how to 
#  use the R PhenoPix package to extract a timeseries of phenocamera data
#  from an example PiCAM dataset.  The extracted data is provided for each 
#  user-specified image ROI(s), also created using the R PhenoPix package
#
#  Note: This script assumes you have already downloaded the example
#  PiCAM dataset(s) from the OSF.io archive to be used with these 
#  example scripts
#
#
# @AUTHORS: Shawn P. Serbin, Daryl Yang
#
#    --- Last updated:  2023.07.09 By Shawn P. Serbin <sserbin@bnl.gov>
###########################################################################################

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
#*****************************************************************************************#

#*****************************************************************************************#
# set picam camera ID for output
cam_id <- "alaska_picam_14"

# define location of example image timeseries data - for now assumes we are
# using the Alaska PiCAM 14 example dataset which has already been downloaded
# from the repo on OSF.io
image_path <- file.path(here::here(),"Examples/Arctic_vegetation_phenology/example_data/",cam_id,"/images")

# set a reference image for drawing ROIs, e.g. 
#reference_image <- "img_014_A77D7C5263D0_2021-08-17_150008.jpg" 
fall_reference_image <- "img_014_A77D7C5263D0_2021-08-22_150004.jpg"
spring_reference_image <- "img_014_A77D7C5263D0_2022-06-10_150009.jpg"

# set a primary ROI path to save the ROI objects
roi_path <- file.path(here::here(),"Examples/Arctic_vegetation_phenology/pheno_results/roi/")
if (! file.exists(roi_path)) dir.create(roi_path,recursive=TRUE)
#*****************************************************************************************#            

#*****************************************************************************************#
# Pre-filter the raw images to remove low-light images. This is a basic
# approach that just selects the midday images. Could instead use the 
# PhenoPix filter function, however selecting midday images appears to provide
# a similarly effective filtering that is faster then the PhenoPix
# approach

image_files <- list.files(path = file.path(image_path), pattern = "*.*jpg")
head(image_files)

# Extract out date-time from image filenames in order to select only the
# midday (e.g. 1500 hrs) images and create a new directory with only those 
# images
image_files <- gsub(pattern = ".jpg", replacement = "", x = image_files)
split_strings <- strsplit(x = image_files, "_") 
split_strings <- as.data.frame(do.call(rbind, split_strings))
head(split_strings)

# get the image hour info
image_hour <- gsub("(..)(..)(..)", "\\1:\\2:\\3", as.character(split_strings$V5))
image_hour <- lubridate::hour(lubridate::hms(as.character(image_hour)))
head(image_hour)

# select only 15H images
keep <- which(image_hour %in% 15)
out_file_list <- image_files[keep]
head(out_file_list)

# Update the image path to point to the time subset directory
image_path2 <- file.path(image_path,"subset")
if (! file.exists(image_path2)) dir.create(image_path2, recursive=TRUE)

# copy only the subset images to the new subset folder
cp_task <- file.copy(file.path(image_path,paste0(out_file_list,".jpg")), 
                     file.path(image_path2))

# swap the original image path for the new subset path
image_path <- image_path2
rm(image_path2)
#*****************************************************************************************#

#*****************************************************************************************#
#*****************************************************************************************#
#*. FALL PERIOD
#*****************************************************************************************# 
# Extract the first timeseries data for the fall 2021 period
# example, draw an ROI the includes a tall alder shrub and save to the 
# roi folder

# fall or spring phenology?
pheno_period <- "fall" # fall, spring

roi_name <- "birch_roi3"
roi_path2 <- file.path(roi_path,roi_name,pheno_period)
if (! file.exists(roi_path2)) dir.create(roi_path2,recursive=TRUE)
phenopix::DrawMULTIROI(path_img_ref=file.path(image_path,fall_reference_image), 
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
# extract timeseries data from ROI - start with fall 2021
# we are using two different ROIs for the same alder shrub given the camera
# FOV moved over the winter. Despite the camera moving the same alder is visible
# in the full timeseries allowing us to explore the fall and spring phenology
# periods, however we will treat these as two separate fits
# 
# Future modifications of this example could merge the datasets together by the 
# date when the camera moved to make a single timeseries but this would not alter
# the fitted phenological parameters


# load ROI data - a little clunky since the output doesnt go into
# the correct path_ROIs folder for some reason when using the
# phenopix::DrawMULTIROI function
load(file.path(roi_path2,"roi.data.Rdata"))

# run the extraction function - for this example we are using the 
# version of the function that averages all of the pixels into a single value
# for each RGB channle by date and image time
fall_vi_extract <- phenopix::extractVIs(img.path=image_path, 
                                        roi.path=file.path(roi_path2,"/"), 
                                        roi.name=roi_name,
                                        vi.path=file.path(roi_path2,"/"),
                                        date.code = "yyyy-mm-dd_HHMMSS",
                                        log.file = NULL)
#                                        log.file = file.path(roi_path2))
# Turning off writing to the log file because the constant open/close makes this
# step much slower.  would be better to use the R progress bar on the screen 
# instead - the default is to append to the file which means a lot of open/close
# !!! above temporary bug fix for path issues in the phenopix::extractVIs
# function that doesnt properly create the full path and roi name unless
# you add a trailing / to the path_ROIs 
# PhenoPix code needs to be fixed to provide correct combination of path
# and roi name so that the results end up in the desired sub-directory !!!
head(fall_vi_extract)

# Create the GCC timeseries for this first ROI
fall_vi_extract[[roi_name]]$gcc <- (fall_vi_extract[[roi_name]]$g.av) / 
  (fall_vi_extract[[roi_name]]$r.av + fall_vi_extract[[roi_name]]$g.av + 
     fall_vi_extract[[roi_name]]$b.av)

# show the fall timeseries plot and write to the ROI folder
par(mfrow=c(1,1), mar=c(4,4.6,0.3,0.4), oma=c(0, 0, 0, 0))
plot(lubridate::yday(fall_vi_extract[[roi_name]]$date),
     fall_vi_extract[[roi_name]]$gcc,
     ylim=c(0.25,0.42), xlim=c(228,300), pch=21, bg="black", cex=2,
     ylab="GCC", xlab="DOY 2021", cex.axis=2, cex.lab=1.7)
box(lwd=2.2)
dev.copy(png, filename=file.path(roi_path2,"fall_gcc.png"),
         height=800,width=1100, res=100)
dev.off()

# Subset extracted results to just the fall period
fall_vi_extract_output2 <- list(fall_vi_extract[[roi_name]][
  lubridate::year(fall_vi_extract[[roi_name]]$date)==2021,])
#assign(paste(roi_name),fall_vi_extract_output2)
names(fall_vi_extract_output2) <- roi_name
head(fall_vi_extract_output2)

# Save the VI data in the default VI.data.Rdata data file
VI.data.Rdata <- fall_vi_extract_output2
save(VI.data.Rdata, file = file.path(roi_path2,"VI.data.Rdata"))
rm(fall_vi_extract_output2,VI.data.Rdata)
#*****************************************************************************************#

#*****************************************************************************************#
#*****************************************************************************************#
#*. SPRING PERIOD
#*****************************************************************************************# 
# Extract the first timeseries data for the fall 2021 period
# example, draw an ROI the includes a tall alder shrub and save to the 
# roi folder

# fall or spring phenology?
pheno_period <- "spring" # fall, spring

roi_name <- "birch_roi3"
roi_path2 <- file.path(roi_path,roi_name,pheno_period)
if (! file.exists(roi_path2)) dir.create(roi_path2,recursive=TRUE)
phenopix::DrawMULTIROI(path_img_ref=file.path(image_path,spring_reference_image), 
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
# extract timeseries data from ROI - spring 2022
# we are using two different ROIs for the same alder shrub given the camera
# FOV moved over the winter. Despite the camera moving the same alder is visible
# in the full timeseries allowing us to explore the fall and spring phenology
# periods, however we will treat these as two separate fits
# 
# Future modifications of this example could merge the datasets together by the 
# date when the camera moved to make a single timeseries but this would not alter
# the fitted phenological parameters


# load ROI data - a little clunky since the output doesnt go into
# the correct path_ROIs folder for some reason when using the
# phenopix::DrawMULTIROI function
load(file.path(roi_path2,"roi.data.Rdata"))

# run the extraction function - for this example we are using the 
# version of the function that averages all of the pixels into a single value
# for each RGB channle by date and image time
spring_vi_extract <- phenopix::extractVIs(img.path=image_path, 
                                        roi.path=file.path(roi_path2,"/"), 
                                        roi.name=roi_name,
                                        vi.path=file.path(roi_path2,"/"),
                                        date.code = "yyyy-mm-dd_HHMMSS",
                                        log.file = NULL)
#                                        log.file = file.path(roi_path2))
# Turning off writing to the log file because the constant open/close makes this
# step much slower.  would be better to use the R progress bar on the screen 
# instead - the default is to append to the file which means a lot of open/close
# !!! above temporary bug fix for path issues in the phenopix::extractVIs
# function that doesnt properly create the full path and roi name unless
# you add a trailing / to the path_ROIs 
# PhenoPix code needs to be fixed to provide correct combination of path
# and roi name so that the results end up in the desired sub-directory !!!
head(spring_vi_extract)

# Create the GCC timeseries for this first ROI
spring_vi_extract[[roi_name]]$gcc <- (spring_vi_extract[[roi_name]]$g.av) / 
  (spring_vi_extract[[roi_name]]$r.av + spring_vi_extract[[roi_name]]$g.av + 
     spring_vi_extract[[roi_name]]$b.av)

# show the fall timeseries plot and write to the ROI folder
par(mfrow=c(1,1), mar=c(4,4.6,0.3,0.4), oma=c(0, 0, 0, 0))
plot(lubridate::yday(spring_vi_extract[[roi_name]]$date),
     spring_vi_extract[[roi_name]]$gcc,
     ylim=c(0.25,0.42), xlim=c(130,180), pch=21, bg="black", cex=2,
     ylab="GCC", xlab="DOY 2021", cex.axis=2, cex.lab=1.7)
box(lwd=2.2)
dev.copy(png, filename=file.path(roi_path2,"spring_gcc.png"),
         height=800,width=1100, res=100)
dev.off()

# Subset extracted results to just the fall period
spring_vi_extract_output2 <- list(spring_vi_extract[[roi_name]][
  lubridate::year(spring_vi_extract[[roi_name]]$date)==2022,])
names(spring_vi_extract_output2) <- roi_name
head(spring_vi_extract_output2)

# Save the VI data in the default VI.data.Rdata data file
VI.data.Rdata <- spring_vi_extract_output2
save(VI.data.Rdata, file = file.path(roi_path2,"VI.data.Rdata"))
rm(spring_vi_extract_output2,VI.data.Rdata)
#*****************************************************************************************#
#*****************************************************************************************#
