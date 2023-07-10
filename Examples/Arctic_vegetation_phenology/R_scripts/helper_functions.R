#*****************************************************************************************#
#*****************************************************************************************#
#*****************************************************************************************#
extend <- function(gccTS, expBEG, expEND, extBEG, extEND)
# this function extend gcc time series to include non-growing season to enable the fitting
# of double logistic models
# input:
#       gccTS: a zoo structured gcc time series
#       greenup: a logical variable that defines if experiment starts before vegetation
#               greenup
#       browndown: a logical variable that defines if experiment ends after vegetation
#               fully browns down
#       expBEG: a date that defines when experiment started (the date when the first good
#               data was collected)  
#       expEND: a date that defines when experiment ends (the date when the last good data
#               was collected)
#       extBEG: the first date that users want the data to be extended to
#       extEND: the last date that users want the data to be extended to
#       snowOFF: the date when snow fully disappeared in spring
#       snowON: the date when snow first appears in fall
{
  ### extend data to the desired beginning and end data based on parameters defined above
  ### extend data at the front
  # determine reference gcc values that will be used for extending time series data
  refGCC <- mean(gccTS[1:3], na.rm = TRUE)
  gccADD <- rnorm(seq(extBEG,expBEG-1,by="day"), refGCC, 0.003)
  doyADD <- seq(extBEG, expBEG-1, by = "day")
  begADD <- structure(gccADD, index = as.Date(doyADD), class = "zoo")
  # combine data to extend with original gcc time series
  gccTS.EXT <- rbind(begADD, gccTS)
  ### extend data at the end
  # determine reference gcc values that will be used for extending time series data
  refGCC <- mean(gccTS[(length(gccTS)-3):length(gccTS)], na.rm = TRUE)
  gccADD <- rnorm(seq(expEND,extEND,by="day"), mean(refGCC), 0.003)
  doyADD <- seq(expEND, extEND, by = "day")
  endADD <- structure(gccADD, index = as.Date(doyADD), class = "zoo")
  # combine data to extend with orginal gcc time series
  gccTS.EXT <- rbind(gccTS.EXT, endADD)
  
  # return the dataset
  return(gccTS.EXT)
}
#*****************************************************************************************#