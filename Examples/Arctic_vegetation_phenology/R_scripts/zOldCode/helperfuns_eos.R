#*****************************************************************************************#
#*****************************************************************************************#
#*****************************************************************************************#
extend <- function(gccTS, greenup, browndown, expBEG, expEND, extBEG, extEND,
                   snowOFF, snowON, gccMIN)
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
  if (greenup == "yes" & browndown == "yes")
  {
    ### extend data at the front
    # determine reference gcc values that will be used for extending time series data
    refGCC <- mean(gccTS[1:3], na.rm = TRUE)
    #gccADD <- rnorm(expBEG-extBEG, mean(refGCC), 0.001)
    gccADD <- rnorm(seq(extBEG,expBEG-1,by="day"), refGCC, 0.001)
    #doyADD <- seq(extBEG+1, expBEG-1, by = "day")
    doyADD <- seq(extBEG, expBEG-1, by = "day")
    #begADD <- structure(gccADD, index = as.POSIXct(doyADD), class = "zoo")
    begADD <- structure(gccADD, index = as.Date(doyADD), class = "zoo")
    # combine data to extend with original gcc time series
    gccTS.EXT <- rbind(begADD, gccTS)
    ### extend data at the end
    # determine reference gcc values that will be used for extending time series data
    refGCC <- mean(gccTS[(length(gccTS)-3):length(gccTS)], na.rm = TRUE)
    #gccADD <- rnorm(extEND-expEND, mean(refGCC), 0.001)
    gccADD <- rnorm(seq(expEND,extEND,by="day"), mean(refGCC), 0.001)
    #doyADD <- seq(expEND+1, extEND-1, by = "day")
    doyADD <- seq(expEND, extEND, by = "day")
    #endADD <- structure(gccADD, index = as.POSIXct(doyADD), class = "zoo")
    endADD <- structure(gccADD, index = as.Date(doyADD), class = "zoo")
    # combine data to extend with orginal gcc time series
    gccTS.EXT <- rbind(gccTS.EXT, endADD)
  }
  if (greenup == "yes" & browndown == "no")
  {
    ### extend data at the front
    # determine reference gcc values that will be used for extending time series data
    refGCC <- mean(gccTS[1:3], na.rm = TRUE)
    #gccADD <- rnorm(expBEG-extBEG, refGCC, 0.001)
    gccADD <- rnorm(seq(extBEG,expBEG-1,by="day"), refGCC, 0.001)
    #doyADD <- seq(extBEG+1, expBEG-1, by = "day")
    doyADD <- seq(extBEG, expBEG-1, by = "day")
    #begADD <- structure(gccADD, index = as.POSIXct(doyADD), class = "zoo")
    begADD <- structure(gccADD, index = as.Date(doyADD), class = "zoo")
    gccTS.EXT <- rbind(begADD, gccTS)
    ### extend data at the end by finding the range of added that gives the minimum
    ### prediction error on the gcc time series
    refGCC <- gccMIN
    doyTEST <- seq(expEND+1, snowON-1, by = "day")
    mseTEST <- c()
    for(i in 1:length(doyTEST))
    {
      # extract the current doy for testing
      doy <- doyTEST[i]
      cat(paste(doy), '...')
      # create an empty matrix to store prediction mse for current doy
      mseDOY <- c()
      for (j in 1:20)
      {
        gccADD <- rnorm(extEND-doy, mean(refGCC), 0.0005)
        doyADD <- seq(doy, extEND-1, by = "day")
        endADD <- structure(gccADD, index = as.POSIXct(doyADD), class = "zoo")
        # combine data to extend with orginal gcc time series
        gccTS.TEST <- rbind(gccTS.EXT, endADD)
        # fit a Gu fit on the time series data
        gccTS.TEST <- na.omit(gccTS.TEST)
        phenoFIT <- try(FitDoubleLogGu(gccTS.TEST), silent=FALSE)
        if(class(phenoFIT) %in% 'try-error')
        {
          mse <- NA
        } else
        {
          mse <- mean((as.numeric(gccTS.TEST) - as.numeric(phenoFIT$predicted))^2)
        }
        # calculate mean square error of prediction
        print(mse)
        mseDOY <- c(mseDOY, mse)
      }
      mseTEST <- cbind(mseTEST, mseDOY)
    }
    ### determine the best start of date to extend data
    doyBEST <- doyTEST[which(colMeans(mseTEST, na.rm = TRUE) == 
                               min(colMeans(mseTEST, na.rm = TRUE)))]
    
    ### create final data to add at the end of the time sereis
    gccADD <- rnorm(extEND-doyBEST, refGCC, 0.0005)
    doyADD <- seq(doyBEST, extEND-1, by = "day")
    endADD <- structure(gccADD, index = as.POSIXct(doyADD), class = "zoo")
    gccTS.EXT <- rbind(gccTS.EXT, endADD)
  }
  return(gccTS.EXT)
}


pheno <- function(gccTS, method)
# this function performs double logistic fitting on a gcc time sereis using defined
# fitting method
# input:
#      gccTS: a zoo structured gcc time series
#      method: method for phenology extraction
{
  gccTS <- na.omit(gccTS)
  
  # extract the dates for producing fitted gcc time series
  doyOLD <- strftime(index(gccTS), format = "%j")
  doyNEW <- seq(as.numeric(min(doyOLD)), as.numeric(max(doyOLD)), 1)
  
  # fit gcc time series and extract phenolpgical dates
  if (method == 'Gu')
  {
    #### fit Gu double logistic model
    # double logistic equation:
    # gcc <- y0 + (a1/(1 + exp(-(t - t01)/b1))^c1) -  (a2/(1 + exp(-(t - t02)/b2))^c2)
    
    phenoFIT <- try(FitDoubleLogGu(gccTS, t = index(gccTS), tout = doyNEW, hessian = TRUE,
                                   na.rm = TRUE), silent=FALSE)
    # extract pheno parameters
    phenoPARs <- try(PhenoGu(phenoFIT$params, phenoFIT, sf=phenoFIT$sf, uncert = TRUE),
                     silent=TRUE)

    # create smooth curve from extBEG to extEND
    # generate fitted gcc data across the entire time span of interest
    y0 <- phenoFIT$params[1]
    a1 <- phenoFIT$params[2]
    a2 <- phenoFIT$params[3]
    t01 <- phenoFIT$params[4]
    t02 <- phenoFIT$params[5]
    b1 <- phenoFIT$params[6]
    b2 <- phenoFIT$params[7]
    c1 <- phenoFIT$params[8]
    c2 <- phenoFIT$params[9]
    gccMIN <- phenoFIT$sf[1]
    gccMAX <- phenoFIT$sf[2]
    
    # generate simulated gcc
    phenoFITTED <- y0 + (a1/(1 + exp(-(doyNEW - t01)/b1))^c1) -
      (a2/(1 + exp(-(doyNEW - t02)/b2))^c2)
    gccFITTED <- phenoFITTED*(gccMAX-gccMIN) + gccMIN
    names(gccFITTED) <- doyNEW
    
    # extract phenophase dates
    UD <- phenoPARs[1] 
    SD <- phenoPARs[2] 
    DD <- phenoPARs[3] 
    RD <- phenoPARs[4]
    gccUD <- gccFITTED[which(names(gccFITTED) == round(UD))]
    if(length(gccUD) == 0){gccUD <- NA}
    gccSD <- gccFITTED[which(names(gccFITTED) == round(SD))]
    if(length(gccSD) == 0){gccSD <- NA}
    gccDD <- gccFITTED[which(names(gccFITTED) == round(DD))]
    if(length(gccDD) == 0){gccDD <- NA}
    gccRD <- gccFITTED[which(names(gccFITTED) == round(RD))]
    if(length(gccRD) == 0){gccRD <- NA}
    
    phenoDATE <- c(UD, SD, DD, RD, gccUD, gccSD, gccDD, gccRD, gccMIN, gccMAX)
    names(phenoDATE) <- c('UD', 'SD', 'DD', 'RD', 'gccUD', 'gccSD', 'gccDD', 'gccRD',
                          'gccMIN', 'gccMAX')
  }
  
  if (method == "Klosterman")
  {
    ### fit Klosterman double logistic model
    # double logistic equation:
    # gcc = (a1 * t + b1) + (a2 * t^2 + b2 * t + c) * (1/(1 + q1 * exp(-B1 * 
    # (t - m1)))^v1 - 1/(1 + q2 * exp(-B2 * (t - m2)))^v2)
    phenoFIT <- try(FitDoubleLogKlLight(gccTS, t = index(gccTS), tout = doyNEW, hessian = TRUE,
                                        na.rm = TRUE), silent=FALSE)
    # extract pheno parameters
    phenoPARs <- try(PhenoKl(x = phenoFIT$params, fit = phenoFIT, uncert = TRUE), silent=F)

    # create smooth curve from extBEG to extEND
    # generate fitted gcc data across the entire time span of interest
    a1 <- phenoFIT$params[1]
    a2 <- phenoFIT$params[2]
    b1 <- phenoFIT$params[3]
    b2 <- phenoFIT$params[4]
    c <- phenoFIT$params[5]
    B1 <- phenoFIT$params[6]
    B2 <- phenoFIT$params[7]
    m1 <- phenoFIT$params[8]
    m2 <- phenoFIT$params[9]
    q1 <- phenoFIT$params[10]
    q2 <- phenoFIT$params[11]
    v1 <- phenoFIT$params[12]
    v2 <- phenoFIT$params[13]
    gccMIN <- phenoFIT$sf[1]
    gccMAX <- phenoFIT$sf[2]
    
    # generate simulated gcc
    phenoFITTED <- (a1 * doyNEW + b1) + (a2 * doyNEW^2 + b2 * doyNEW + c) * 
      (1/(1 + q1 * exp(-B1 *  (doyNEW - m1)))^v1 - 1/(1 + q2 * exp(-B2 * (doyNEW - m2)))^v2)
    gccFITTED <- phenoFITTED*(gccMAX-gccMIN) + gccMIN
    names(gccFITTED) <- doyNEW
    
    # extract phenophase dates
    UD <- phenoPARs[1] 
    SD <- phenoPARs[2] 
    DD <- phenoPARs[3] 
    RD <- phenoPARs[4]
    gccUD <- gccFITTED[which(names(gccFITTED) == round(UD))]
    if(length(gccUD) == 0){gccUD <- NA}
    gccSD <- gccFITTED[which(names(gccFITTED) == round(SD))]
    if(length(gccSD) == 0){gccSD <- NA}
    gccDD <- gccFITTED[which(names(gccFITTED) == round(DD))]
    if(length(gccDD) == 0){gccDD <- NA}
    gccRD <- gccFITTED[which(names(gccFITTED) == round(RD))]
    if(length(gccRD) == 0){gccRD <- NA}
    
    phenoDATE <- c(UD, SD, DD, RD, gccUD, gccSD, gccDD, gccRD, gccMIN, gccMAX)
    names(phenoDATE) <- c('UD', 'SD', 'DD', 'RD', 'gccUD', 'gccSD', 'gccDD', 'gccRD',
                          'gccMIN', 'gccMAX')
  }
  
  if (method == 'Beck')
  {
    ### fit Beck double logistic model
    # double logistic equation:
    # gcc <- mn + (mx - mn) * (1/(1 + exp(-rsp * (t - sos))) + 1/(1 + exp(rau * (t - eos))))
    phenoFIT <- try(FitDoubleLogBeck(gccTS, t = index(gccTS), tout = doyNEW, hessian = TRUE,
                                     na.rm = TRUE), silent=FALSE)

    # create smooth curve from extBEG to extEND
    # generate fitted gcc data across the entire time span of interest
    mn <- phenoFIT$params[1]
    mx <- phenoFIT$params[2]
    sos <- phenoFIT$params[3]
    rsp <- phenoFIT$params[4]
    eos <- phenoFIT$params[5]
    rau <- phenoFIT$params[6]
    gccMIN <- phenoFIT$sf[1]
    gccMAX <- phenoFIT$sf[2]
    
    # generate simulated gcc
    phenoFITTED <- mn + (mx - mn) * (1/(1 + exp(-rsp * (doyNEW - sos))) +
                                       1/(1 + exp(rau * (doyNEW - eos))))
    gccFITTED <- phenoFITTED*(gccMAX-gccMIN) + gccMIN
    names(gccFITTED) <- doyNEW
    
    # extract phenophase dates
    UD <- phenoFIT$params[3]
    SD <- NA
    DD <- NA
    RD <- phenoFIT$params[4]
    gccUD <- gccFITTED[which(names(gccFITTED) == round(UD))]
    if(length(gccUD) == 0){gccUD <- NA}
    gccSD <- gccFITTED[which(names(gccFITTED) == round(SD))]
    if(length(gccSD) == 0){gccSD <- NA}
    gccDD <- gccFITTED[which(names(gccFITTED) == round(DD))]
    if(length(gccDD) == 0){gccDD <- NA}
    gccRD <- gccFITTED[which(names(gccFITTED) == round(RD))]
    if(length(gccRD) == 0){gccRD <- NA}
    
    phenoDATE <- c(UD, SD, DD, RD, gccUD, gccSD, gccDD, gccRD, gccMIN, gccMAX)
    names(phenoDATE) <- c('UD', 'SD', 'DD', 'RD', 'gccUD', 'gccSD', 'gccDD', 'gccRD',
                          'gccMIN', 'gccMAX')
  }
  
  if (method == 'Elmore')
  {
    # fit Elmore double logistic model
    phenoFIT <- try(FitDoubleLogElmore(gccTS, t = index(gccTS), tout = doyNEW, hessian = TRUE,
                                       na.rm = TRUE), silent=FALSE)
    # extract pheno parameters
    phenoPARs <- PhenoDeriv(phenoFIT$predicted)

    m1 <- phenoFIT$params[1]
    m2 <- phenoFIT$params[2]
    m3 <- phenoFIT$params[3]
    m4 <- phenoFIT$params[4]
    m5 <- phenoFIT$params[5]
    m6 <- phenoFIT$params[6]
    m7 <- phenoFIT$params[7]
    gccMIN <- phenoFIT$sf[1]
    gccMAX <- phenoFIT$sf[2]
    
    # create smooth curve from extBEG to extEND
    # generate fitted gcc data across the entire time span of interest
    phenoFITTED <- m1 + (m2 - m7 * doyNEW) * ((1/(1 + exp(((m3/m4) - doyNEW)/(1/m4)))) - 
                                                (1/(1 + exp(((m5/m6) - doyNEW)/(1/m6)))))
    gccFITTED <- phenoFITTED*(gccMAX-gccMIN) + gccMIN
    names(gccFITTED) <- doyNEW
    
    # extract phenophase dates
    UD <- phenoPARs[1]
    SD <- NA
    DD <- NA
    RD <- phenoPARs[2]
    gccUD <- gccFITTED[which(names(gccFITTED) == round(UD))]
    if(length(gccUD) == 0){gccUD <- NA}
    gccSD <- gccFITTED[which(names(gccFITTED) == round(SD))]
    if(length(gccSD) == 0){gccSD <- NA}
    gccDD <- gccFITTED[which(names(gccFITTED) == round(DD))]
    if(length(gccDD) == 0){gccDD <- NA}
    gccRD <- gccFITTED[which(names(gccFITTED) == round(RD))]
    if(length(gccRD) == 0){gccRD <- NA}
    
    phenoDATE <- c(UD, SD, DD, RD, gccUD, gccSD, gccDD, gccRD, gccMIN, gccMAX)
    names(phenoDATE) <- c('UD', 'SD', 'DD', 'RD', 'gccUD', 'gccSD', 'gccDD', 'gccRD',
                          'gccMIN', 'gccMAX')
  }
  phenoRES <- list("phenoPAR" = phenoDATE, "gccFITTED" =  gccFITTED)
  return(phenoRES)
}


extendDATE_ref = function(data, expBEG, expEND, dayBEG, dayEND)
{
  # pre-extend the data to a certain date.
  # Inputs:
  #       GccFilterred: the filterred Gcc data.
  #       firstDay: the first day of the date range that you want to extent.
  #       dateUse: the date range that the Gcc data is useful.
  #Outputs:
  #       ExtendDate: the pre-extend gcc data.
  
  # extract dates of data collection
  collDATEs <- index(data)
  # pull out gcc time series
  gcc <- data$mad.filtered
  gcc <- na.omit(gcc)
  # extend data to the desired begin date if the first day of data collection is after the 
  # the defined first date
  if(as.POSIXct(dayBEG) <= min(collDATEs))
  {
    if(as.POSIXct(dayBEG) < as.POSIXct(expBEG))
    {
      # extract gcc from the first week to be used as reference for data extension
      refGCC <- gcc[1:5]
      # determine the number of dates to add
      numDAY <- expBEG-dayBEG
      gccADD <- rnorm(numDAY, mean(refGCC), sd(refGCC))
      dayADD <- seq(dayBEG+1, expBEG-1, by = "day")
      begADD <- structure(gccADD, index = as.POSIXct(dayADD), class = "zoo")
      # remove and data before snow date and add the extend data to the original data
      snowDAY <- which(index(gcc) < expBEG)
      if(length(snowDAY) > 0)
      {
        gcc <- rbind(begADD, gcc[-snowDAY])
      }else
      {
        gcc <- rbind(begADD, gcc)
      }
    }
  }
  # extend data to the desired end date if the first day of data collection is before the 
  # the defined last date
  if(as.POSIXct(dayEND) >= max(collDATEs))
  {
    if(as.POSIXct(dayEND) > as.POSIXct(expEND))
    {
      refGCC <- gcc[(length(gcc)-5):length(gcc)]
      numDAY <- dayEND-expEND
      gccADD <- rnorm(numDAY, mean(refGCC), sd(refGCC))
      dayADD <- seq(expEND+1, dayEND-1, by = "day")
      endADD <- structure(gccADD, index = as.POSIXct(dayADD), class = "zoo")
      # remove and data before snow date and add the extend data to the original data
      snowDAY <- which(index(gcc) > expEND)
      if(length(snowDAY) > 0)
      {
        gcc <- rbind(gcc[-snowDAY], endADD)
      }else
      {
        gcc <- rbind(gcc, endADD)
      }
    }
  }
  # return extended gcc time series
  return(gcc)
}


RSquareCal = function(dataORI, dataFit)
{
  SSR = sum((dataFit - mean(dataORI))^2)
  SST = sum((dataORI - mean(dataORI))^2)
  R2 = SSR/SST
  return(R2)
}
#*****************************************************************************************#
#*****************************************************************************************#
#*****************************************************************************************#