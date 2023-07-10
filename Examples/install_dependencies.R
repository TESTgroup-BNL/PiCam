####################################################################################################
# Install dependencies
#
# Note: to run source the script file
#
# last updated: 2023-06-30 by Shawn P. Serbin <sserbin@bnl.gov>
####################################################################################################


#--------------------------------------------------------------------------------------------------#
req.packages <- c("devtools","dplyr","reshape2","here","ggplot2","gridExtra",
                  "phenopix","zoo","matrixStats","outliers","osfr")
new.packages <- req.packages[!(req.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages, dependencies=TRUE)
#--------------------------------------------------------------------------------------------------#

# Restart R session to load new packages
.rs.restartR()       # Restart R session