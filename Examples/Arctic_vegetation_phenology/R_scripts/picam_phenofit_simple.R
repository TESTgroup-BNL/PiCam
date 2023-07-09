###########################################################################################
#
#  INFO HERE
#
#
#
# @AUTHORS: Shawn P. Serbin, Daryl Yang
#
#    --- Last updated:  2023.07.08 By Shawn P. Serbin <sserbin@bnl.gov>
###########################################################################################

#******************** close all devices and delete all variables *************************#
rm(list=ls(all=TRUE))   # clear workspace
graphics.off()          # close any open graphics
closeAllConnections()   # close any open connections to files
#*****************************************************************************************#

#****************************** load required libraries **********************************#
### install and load required R packages
list.of.packages <- c("ggplot2", "phenopix", "zoo", "matrixStats","lubridate")
# check for dependencies and install if needed
new.packages <- list.of.packages[!(list.of.packages %in% 
                                     installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
# load libraries
invisible(lapply(list.of.packages, library, character.only = TRUE))

# load helper functions
code_dir <- file.path(here::here(),"Examples/Arctic_vegetation_phenology/R_scripts")
source(file.path(code_dir,"helper_functions.R"))
#*****************************************************************************************#

#************************************ user parameters ************************************#
# define the base output directory
outDIR <- file.path(here::here(),"Examples/Arctic_vegetation_phenology/pheno_results/roi/")

# set picam camera ID
cam_id <- "alaska_picam_14"

# which ROI to process?
roi_name <- "birch_roi3"

# fitting fall or spring phenology?
pheno_period <- "fall" # fall, spring

# what year?
pheno_year <- "2021" # 2021, 2022

# do you want to extend the data?
extend_data <- TRUE # TRUE/FALSE

# use the filtered timeseries or the raw data?
useFilter <- FALSE # TRUE/FALSE
max_filt <- FALSE # TRUE/FALSE
spline_filt <- TRUE # TRUE/FALSE
mad_filt <- FALSE # TRUE/FALSE
  
# define full results path
outDIR <- file.path(outDIR,roi_name,pheno_period)
# create output directory if not exist
if (! file.exists(outDIR)) dir.create(outDIR,recursive=TRUE)

# define the first date that experiment started (when the first useful data was collected)
expBEG <- 229
expBEG <- as.Date(expBEG, origin = as.Date(paste0(pheno_year,"-01-01")))
# Fall example: 229
# Spring example: 130, 140
# define the last date that experiment ended (when the last useful data was collected)
expEND <- 265
expEND <- as.Date(expEND, origin = as.Date(paste0(pheno_year,"-01-01")))
# Fall example: 303, 280
# Spring example: 180

# define the first date that the data to be extended to
extBEG <- 175
extBEG = as.Date(extBEG, origin = as.Date(paste0(pheno_year,"-01-01")))
# Fall example: 180, 175
# Spring example: 130
# define the last date that the data to be extended to
extEND <- 364
extEND <- as.Date(extEND, origin = as.Date(paste0(pheno_year,"-01-01")))
# Fall example: 364
# Spring example: 190

# select a fitting method for extract phenophases
#method <- "Gu" # potential methods: Beck, Elmore, Klosterman, gu, spline
fit_method <- "beck" # spline, beck, elmore, klosterman, gu
#*****************************************************************************************#

#*****************************************************************************************#
## Load the VI data
# load the extracted dataset
load(file.path(outDIR,"VI.data.Rdata"))
#*****************************************************************************************#

#*********************************** preprocessing ***************************************#
gccTS <- VI.data.Rdata[[roi_name]]

# clean data at the beginning and end of the time-series that the camera are not observing 
# intended targets
goodDAY <- which(as.Date(gccTS$date) >= as.Date(expBEG) & as.Date(gccTS$date) 
                 < as.Date(expEND))
gccTS <- gccTS[goodDAY,]

plot(gccTS$date, gccTS$gcc, pch=21, bg="black")

# filter out noisy data in data and create a time series with daily gcc observation
autofilterR <- try(phenopix::autoFilter(gccTS, na.fill=TRUE, 
                                        filter=c("night", "spline", "max", 
                                                 'blue', 'mad'), 
                              filter.options=NULL, raw.dn=TRUE), silent=FALSE)
if(class(autofilterR) %in% 'try-error') {
  print("Filtering failed")
} else {
    print("fitlering successful")
}

# extract filtered time series from autofilter result, while the this scripts 
# users can select between the different filter results to optimize the pheno 
# fitting
if (useFilter) {
  if (max_filt) {
    print("Max filter")
    gccTS.CLN <- autofilterR$max.filtered
  } else if (spline_filt) {
    print("Spline filter")
    gccTS.CLN <- autofilterR$spline.filtered
  } else if (mad_filt) {
    print("Mad filter")
    gccTS.CLN <- autofilterR$mad.filtered
  }
} else {
  print("No filter")
  gccTS.CLN <- autofilterR$gcc
}

# plot
plot(gccTS.CLN, type="p", pch=21, bg="black")

# extend data to desired extBEG and extEND
if (extend_data) {
  gccTS.EXT <- extend(gccTS.CLN, expBEG, expEND, extBEG, extEND)
  plot(lubridate::yday(index(gccTS.EXT)), gccTS.EXT, type="p", xlab="DOY",
       ylab="GCC", pch=21, bg="black", cex=2)
} else {
  print("Using non-extended timeseries")
  gccTS.EXT <- gccTS.CLN
}
#*****************************************************************************************#

#************************************* main function *************************************#
#?phenopix::greenProcess
pheno_fit <- phenopix::greenProcess(ts = gccTS.EXT, fit = fit_method, 
                               threshold = 'trs', 
                               plot=FALSE)
summary(pheno_fit)

# Get the pheno fit metrics
pheno_fit_metrics <- phenopix::extract(pheno_fit, 'metrics')
if(pheno_period=="fall") {
  pheno_dates <- pheno_fit_metrics[["eos"]]
  pheno_label <- c("EOS")
} else if (pheno_period=="spring") {
  pheno_dates <- pheno_fit_metrics[["sos"]]
  pheno_label <- c("SOS")
}

# Create a basic fit plot
ggplot() +
  geom_point(aes(x = lubridate::yday(index(gccTS.EXT)), 
                 y = as.numeric(gccTS.EXT)), color = "grey", size = 3) +
  geom_line(aes(x = as.numeric(index(pheno_fit$fit$fit$predicted)), 
                y = pheno_fit$fit$fit$predicted), 
            color = "black", size = 1) + 
  labs(title = paste0("Phenology Metric: ",pheno_label), 
       subtitle = paste0("Fit Method: ",fit_method), 
       caption = "PiCAM Example Fit") + 
  geom_vline(xintercept = pheno_dates, color = "green", size = 1, 
             alpha = 0.5, linetype = "dashed") +
  annotate(geom="text", x = pheno_dates, 
           y = min(gccTS.EXT)+0.012, label=as.character(pheno_dates), 
           size = 7, color = "green", hjust = 1) +
  xlab("Time (DOY)") + ylab('GCC') + ylim(min(gccTS.EXT)-0.01, 
                                          max(gccTS.EXT)+0.01) + 
  xlim(min(lubridate::yday(index(gccTS.EXT))), 
       max(lubridate::yday(index(gccTS.EXT)))) + 
  theme(legend.position = 'none', plot.title = element_text(face = "bold"),
        axis.text = element_text(size=14, color = 'black'),
        axis.title=element_text(size=14), 
        panel.border = element_rect(color = "black", fill=NA, size = 1), 
        panel.background = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()) 

# Save the plot to the output folder
ggsave(filename = file.path(outDIR,"pheno_fit_basic.pdf"), 
       plot = last_plot(), width = 16, height = 13, units = 'cm')
#*****************************************************************************************#

#*****************************************************************************************#
## Compare the results across different fitting methods using the built in 
# function in PhenoPix
explored <- phenopix::greenExplore(gccTS.EXT)
plotExplore(explored)

# save plot to the output folder
dev.copy(pdf, file.path(outDIR,"pheno_fit_comparison.pdf"),
         width = 10, height = 8)
dev.off()
#*****************************************************************************************#

#*****************************************************************************************#
## Run the built-in PhenoPix uncertainty analysis
#?phenopix::greenProcess
pheno_fit_uq <- phenopix::greenProcess(ts = gccTS.EXT, fit = fit_method, 
                                    threshold = 'trs', 
                                    plot=FALSE,
                                    uncert = TRUE,
                                    nrep = 200)
print(pheno_fit_uq)

dev.off()
par(mfrow=c(1,1), mar=c(4,4.6,0.3,0.4), oma=c(0, 0, 0, 0))
plot(pheno_fit_uq, type='p', pch=21, bg="black", cex=1.5, ylab="GCC",
     xlab="DOY", cex.axis=2, cex.lab=1.7, main="")
box(lwd=2.2)
dev.copy(pdf, file.path(outDIR,"pheno_fit_uq.pdf"),
         width = 8, height = 6)
dev.off()
#*****************************************************************************************#
