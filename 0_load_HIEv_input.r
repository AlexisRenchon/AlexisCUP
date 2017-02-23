setwd("L:/PROFILE DATA/metdata")
#test
rm(list=ls())

#Write start date
sD<-"2016-08-01"
#Write end date
eD<-"2016-08-16"

#Address where you want the data to be stored
#just save it in the same folder as the program
#dataTo<-function(){setwd("./pri/")

library("plyr", lib.loc="C:/Program Files/R/R-3.2.2/library")
library(HIEv)
setToken('o9nBpV1mFytgJSxcoXPD')
library("doBy", lib.loc="C:/Program Files/R/R-3.2.2/library")

#for setting up dates in HIEv? don?t worry about it
eD2<-gsub("-","",eD)
when<-paste0(eD2,".dat")
when2<-paste0(eD2,".pdf")

#dataTo()

#Download data
met<- downloadTOA5(filename="FACELawn_FACE_diffPAR_",endDate=eD,startDate=sD,topath="L:/PROFILE DATA/metdata")
met <- met [with(met, order(DateTime)), ]


#met$DateTime3 <- nearestTimeStep(met$DateTime, 30, "ceiling")
#methalfhour2 <- summaryBy(. ~ DateTime3, data = met, FUN = mean, na.rm = TRUE)
#write.table(methalfhour2, file="FACELawn_FACE_diffPAR.csv")


