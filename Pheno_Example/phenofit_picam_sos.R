###########################################################################################
#
#  this script perform 
#
#    --- Last updated:  2021.06.22 By Daryl Yang <dediyang@bnl.gov>
###########################################################################################

#******************** close all devices and delete all variables *************************#
rm(list=ls(all=TRUE))   # clear workspace
graphics.off()          # close any open graphics
closeAllConnections()   # close any open connections to files
dlm <- .Platform$file.sep # <--- What is the platform specific delimiter?
#*****************************************************************************************#

#****************************** load required libraries **********************************#
### install and load required R packages
list.of.packages <- c("ggplot2", "phenopix", "zoo", "matrixStats")  
# check for dependencies and install if needed
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
# load libraries
invisible(lapply(list.of.packages, library, character.only = TRUE))

# load helper functions
helperfunDIR <- file.path("/Volumes/data2/dyang/projects/ngee_arctic/barrow/zpw/script/phenocam_processing/helperfuns.R")
source(helperfunDIR)
#*****************************************************************************************#

#************************************ user parameters ************************************#
# define an output directory to store outputs
outDIR <- file.path("/Volumes/data2/dyang/projects/ngee_arctic/seward/analysis/phenology/council/picam/pheno")
# create output directory if not exist
if (! file.exists(outDIR)) dir.create(outDIR,recursive=TRUE)
# creat an temporary to store files temporarily generated during the course of processing
tempDIR <- file.path(paste0(outDIR, "/", 'spring'))
if (! file.exists(tempDIR)) dir.create(tempDIR,recursive=TRUE)

# define the first date that experiment started (when the first useful data was collected)
expBEG <- as.Date("2022/05/21") #2022/05/21
# define the last date that experiment ended (when the last useful data was collected)
expEND <- as.Date("2022/07/18") #"2022/07/24"

### if the experiment started after vegetation green up or ended before vegetation fully 
### brown down, fit the time series by adding data before and after snow
# experiment started before greenup?
greenup = 'yes'
if (greenup == 'no')
{
  # define the last date that snow disappear
  snowOFF <- as.Date("2021/05/20")
}
# experiment ended after browndown?
browndown = 'yes'
if (browndown == "no")
{
  # define the first date that snow appears
  snowON <- as.Date("2021/10/01")
  # define minimum gcc for extanding
  gccMIN <- 0.25
}

# define the first date that the data to be extended to
extBEG = as.Date("2022/04/01")
# define the last date that the data to be extended to
extEND = as.Date("2022/08/31")

# select a fitting method for extract phenophases
method <- "Gu" # potential methods: Beck, Elmore, Klosterman, Gu

# define the columns to use
vars <- c("date", "time", "red", "green", "blue", "gcc")
#*****************************************************************************************#

#*************************************** load data ***************************************#
# define the directory to time-series phenocam data csv files, please extract the
# time-series data using ENVI_IDL code "get_roi_stats_from_phenocam'
phenoDIR <- file.path("/Volumes/data2/dyang/projects/ngee_arctic/seward/analysis/phenology/council/picam/gcc_ts")
# search all hdf files stored in the directory
phenoFILE <- list.files(phenoDIR, pattern = "PiCam_025_20210817_20220722_roi1",
                        full.names = TRUE, recursive = FALSE)
# load in phenocam time series as dataframe
dataORIG <- read.csv(phenoFILE, header = TRUE)
# extract date, time, and gcc time series
gccTS <- dataORIG[, vars]

# clean images that are not collected during day time
gccHH <- as.numeric(substr(gccTS$time, 1,2))
goodHH <- which(gccHH > 14 & gccHH < 16)
gccTS <- gccTS[goodHH,]
#*****************************************************************************************#

#*********************************** preprocessing ***************************************#
# merge date and time columns, and convert them to posix format
posixTIME <- as.POSIXct(apply(gccTS[,1:2],1, paste, collapse =" "))
# replace the date and time columns in gccTS with posixTIME
gccTS <- gccTS[,-1]
gccTS$time <- posixTIME

# clean data at the beginning and end of the time-series that the camera are not observing 
# intended targets
goodDAY <- which(gccTS$time > as.POSIXct(expBEG) & gccTS$time < as.POSIXct(expEND))
gccTS <- gccTS[goodDAY,]

# filter out noisy data in data and create a time series with daily gcc observation
autofilterR <- try(autoFilter(gccTS, dn=c(2,3,4), na.fill=TRUE, 
                              filter=c("night", "spline", "max", 'blue', 'mad'), 
                              filter.options=NULL, raw.dn=TRUE), silent=FALSE)
if(class(autofilterR) %in% 'try-error') {next} else {print("fitlering successful")}
# extract filtered time series from autofilter result, while the this scripe uses result
# from max fileter, users can choose results from other filter
gccTS.CLN <- autofilterR$max.filtered

#temp <- hampel(gccTS.clean, k = 7, t0 = 1)
#gccTS.clean <- temp$y

# extend data to desired extBEG and extEND 
gccTS.EXT <- extend(gccTS.CLN, greenup, browndown, expBEG, expEND, extBEG, extEND,
                    snowOFF, snowON, gccMIN)
#*****************************************************************************************#

#************************************* main function *************************************#
# perform a single double logistic fitting on the extended data
phenoR <- pheno(gccTS.EXT, method)
# extracted phenology variables and fitted gcc time series from double logistic fitting
# result
phenoVAR <- phenoR$phenoPAR
gccFITTED <- phenoR$gccFITTED

### write out phenoDATE parameters
file.basename <- gsub(".csv", ".csv", basename(phenoFILE))
csvNAME <- paste0(tempDIR, "/", "phenoPARs_", file.basename)
write.csv(phenoVAR, csvNAME)

### write out phenoDATE parameters
file.basename <- gsub(".csv", ".csv", basename(phenoFILE))
csvNAME <- paste0(tempDIR, "/", "gccFITTED_", file.basename)
write.csv(gccFITTED, csvNAME)

# make a plot
ggplot() +
  geom_point(aes(x = lubridate::yday(index(gccTS.EXT)), 
                 y = as.numeric(gccTS.EXT)), color = "grey", size = 2) +
  geom_line(aes(x = as.numeric(names(gccFITTED)), y = gccFITTED), 
            color = "black", size = 1) +
  geom_vline(xintercept = phenoVAR[which(names(phenoVAR) == "UD")], 
             color = "green", size = 0.8, alpha = 0.5, linetype = "dashed") +
  annotate(geom="text", x = phenoVAR[which(names(phenoVAR) == "UD")]-21, 
           y = min(gccTS.EXT)+0.012, label="UD", size = 4.5, hjust = 0) +
  xlab("Time (DOY)") + ylab('GCC') + ylim(min(gccTS.EXT)-0.01, max(gccTS.EXT)+0.01) + 
  theme(legend.position = 'none') + xlim(120, 210) +
  theme(axis.text = element_text(size=12, color = 'black'),
        axis.title=element_text(size=12)) +
  theme(panel.border = element_rect(color = "black", fill=NA, size = 1), 
        panel.background = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())

file.basename <- gsub(".csv", ".pdf", basename(phenoFILE))
pdfNAME = paste0(tempDIR, "/", "phenoPLOT_", file.basename)
ggsave(pdfNAME, plot = last_plot(), width = 11, height = 8, units = 'cm')
#*****************************************************************************************#

#******************************* uncertainty analysis ************************************#
# perform a iteration on gcc time series to calculate uncertainty
phenVAR.UNC <- c()
gccFITTED.UNC <- c()
for (itr in 1:10)
{
  cat(paste(itr), '...')
  # extend data to desired extBEG and extEND 
  gccTS.EXT <- extend(gccTS.CLN, greenup, browndown, expBEG, expEND, extBEG, extEND,
                      snowOFF, snowON, gccMIN)
  # perform a single double logistic fitting on the extended data
  phenoR <- pheno(gccTS.EXT, method)
  # extracted phenology variables and fitted gcc time series from double logistic fitting
  # result
  phenoVAR <- phenoR$phenoPAR
  gccFITTED <- phenoR$gccFITTED
  
  phenVAR.UNC <- cbind(phenVAR.UNC, phenoVAR)
  gccFITTED.UNC <- cbind(gccFITTED.UNC, gccFITTED)
}
# calculate mean and standard deviation in phenology variables
phenoVAR.MEAN <- rowMeans(phenVAR.UNC, na.rm = TRUE)
phenoVAR.SD <- rowSds(phenVAR.UNC, na.rm = TRUE)
phenoOUT <- data.frame(cbind(phenoVAR.MEAN, phenoVAR.SD))
names(phenoOUT) <- c('mean', 'sd')

### write out phenoDATE parameters
file.basename <- gsub(".csv", ".csv", basename(phenoFILE))
csvNAME <- paste0(tempDIR, "/", "phenoUNCT_", file.basename)
write.csv(phenoOUT, csvNAME)

# calculate mean and stand deviation in fitted gcc time series
gccFITTED.MEAN <- rowMeans(gccFITTED.UNC, na.rm = TRUE)
gccFITTED.SD <- rowSds(gccFITTED.UNC, na.rm = TRUE)
gccOUT <- data.frame(cbind(gccFITTED.MEAN, gccFITTED.SD))
names(gccOUT) <- c('mean', 'sd')
# make a plot
cols <- c("#66CC99", "seagreen", "brown", "black")
ggplot() +
  geom_point(aes(x = lubridate::yday(index(gccTS.EXT)), 
                 y = as.numeric(gccTS.EXT)), color = "grey20", size = 2, shape = 23,
             fill = cols[1]) +
  geom_line(data = gccOUT, aes(x = as.numeric(rownames(gccOUT)), y = mean), 
            color = "black", size = 1.2) +
  geom_ribbon(data = gccOUT, aes(x = as.numeric(rownames(gccOUT)), 
                                 ymin = mean-sd, ymax = mean+sd), fill = 'black', alpha = 0.3) +
  geom_vline(data = phenoOUT[1,], aes(xintercept = mean), color = 'red', alpha = 1,
             linetype = 'dotted', size = 1.2) +
  geom_rect(data = phenoOUT[1,], aes(xmin = mean-sd, xmax = mean+sd,
                                       ymin = -Inf, ymax = Inf), 
            fill = cols[1], alpha = 0.3) +
  annotate(geom="text", x = phenoOUT[c(1), 1], y = min(gccTS.EXT)+0.02,
           label="sos", size = 6, hjust = 0.5, color = "red") +
  xlab("Time (DOY)") + ylab('GCC') + ylim(min(gccTS.EXT)-0.005, max(gccTS.EXT)+0.005) + 
  theme(legend.position = 'none') + xlim(120, 210) +
  theme(axis.text = element_text(size=13, color = 'black'),
        axis.title=element_text(size=13)) +
  theme(panel.border = element_rect(color = "black", fill=NA, size = 1), 
        panel.background = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())

file.basename <- gsub(".csv", ".pdf", basename(phenoFILE))
pdfNAME = paste0(tempDIR, "/", "phenoUNCT_", file.basename)
ggsave(pdfNAME, plot = last_plot(), width = 10, height = 8, units = 'cm')
#*****************************************************************************************#










