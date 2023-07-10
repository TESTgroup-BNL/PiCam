###########################################################################################
#
#  This R script will download and extract an example Alaska PiCAM dataset 
#  to the local computer to demonstrate the phenology fitting and 
#  extraction of phenology metrics 
#
# @AUTHORS: Shawn P. Serbin, Daryl Yang
#
#    --- Last updated:  2023.07.06 By Shawn P. Serbin <sserbin@bnl.gov>
###########################################################################################


#****************************** load required libraries **********************************#
### install and load required R packages
list.of.packages <- c("here","dplyr","osfr")  
# check for dependencies and install if needed
new.packages <- list.of.packages[!(list.of.packages %in% 
                                     installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
# load libraries
invisible(lapply(list.of.packages, library, character.only = TRUE))
#*****************************************************************************************#

#*****************************************************************************************#
# Define directory or location to store example PiCAM 14 data
# Default is to place example data in:
# "../PiCam/Examples/Arctic_vegetation_phenology/example_data/alaska_[picam_num]
#
# For PiCAM 14 data:
#outDIR <- file.path(here::here(),"Examples/Arctic_vegetation_phenology/example_data/alaska_picam_14")
#

# camera ID: 14
cameraID <- "Alaska_PiCAM_14"
out_cam_id <- "alaska_picam_14"

# Primary output folder
outDIR <- file.path(here::here(),"Examples/Arctic_vegetation_phenology/example_data/")
# create output directory if not exist
if (! file.exists(outDIR)) dir.create(outDIR,recursive=TRUE)
#*****************************************************************************************#


#*****************************************************************************************#
# Connect to the PiCAM project on OSF.io
# https://osf.io/k9xb3/
# OSF.io project ID: k9xb3

picam_project <- osf_retrieve_node("k9xb3")
picam_project
#*****************************************************************************************#

#*****************************************************************************************#
# Download the data
osf_ls_nodes(picam_project)
osf_ls_files(picam_project)

osf_ls_files(picam_project, type = "folder")
osf_ls_files(picam_project, path = "example_data/Alaska_PiCAM_14")
osf_ls_files(picam_project, 
             path = "example_data/Alaska_PiCAM_14/picam_images",
             pattern = "jpg")

zip_file_ids <- osf_ls_files(picam_project, 
                            path = paste0("example_data/",cameraID,"/picam_images"),
                            pattern = "zip")

# Download the zip file containing the example PiCAM 14 dataset
osf_retrieve_file(zip_file_id$id) %>%
  osf_download(path = file.path(outDIR,out_cam_id), conflicts = "overwrite",
               verbose = TRUE, progress = TRUE)
#*****************************************************************************************#

#*****************************************************************************************#
# Extract/unpack example data to the same folder
#unzip(zipfile = file.path(outDIR,cam_id,"images.zip"), 
#      exdir = file.path(outDIR,cam_id))

unzip(zipfile = file.path(outDIR,out_cam_id,"images.1.zip"), 
      exdir = file.path(outDIR,out_cam_id))
unzip(zipfile = file.path(outDIR,out_cam_id,"images.2.zip"), 
      exdir = file.path(outDIR,out_cam_id))

# create new images/ directory and combine example data 
imagesdir <- file.path(outDIR,out_cam_id,"images")
# create output directory if not exist
if (! file.exists(imagesdir)) dir.create(imagesdir,recursive=TRUE)

# move the images to the images directory
file_list <- list.files(file.path(outDIR,out_cam_id,"images.1"))
cp_task <- file.copy(from = file.path(outDIR,out_cam_id,"images.1",file_list), 
          to = file.path(imagesdir,file_list), 
          overwrite = TRUE)
file_list <- list.files(file.path(outDIR,out_cam_id,"images.2"))
cp_task <- file.copy(from = file.path(outDIR,out_cam_id,"images.2",file_list), 
                     to = file.path(imagesdir,file_list), 
                     overwrite = TRUE)
rm(file_list,cp_task)
unlink(file.path(outDIR,out_cam_id,"images.1"), recursive = TRUE)
unlink(file.path(outDIR,out_cam_id,"images.2"), recursive = TRUE)
# remove scratch folder if exists
if(file.exists(file.path(outDIR,out_cam_id,"__MACOSX"))) {
  unlink(file.path(outDIR,out_cam_id,"__MACOSX"), recursive = TRUE)
}
#*****************************************************************************************#
#*
#*TODO: Cleanup and generalize
