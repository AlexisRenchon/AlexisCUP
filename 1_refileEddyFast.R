require(HIEv)
inputdir<-"//ad.uws.edu.au/dfshare/HomesHWK$/90929058/My Documents/GitHub/AlexisCUP/Input TOB1 fast raw"
outputdir<-"//ad.uws.edu.au/dfshare/HomesHWK$/90929058/My Documents/GitHub/AlexisCUP/Output 1 30min files with gaps in timestamp"
filelist<-list.files(inputdir) #get list of all files in the folder

#step through the files and break them into 30min files NB files need to be in chronological order.
for(i in 1 : length(filelist)){
  to.read = file(paste(inputdir,filelist[i],sep="/"), "rb")
  cat("opening file-",filelist[i],"\n")
  #read in header lines these are in ASCII so need to get them out if the way
  head<-readLines(to.read,n=5)
  #read all data into a matrix
  
  pointDataRecordLength<-44  #11 variables of 4 bytes each
  numberPointRecords<-8460000 #make this big to account for oversized inputfiles
  #grab all data into memory
  rawbytes<-readBin(to.read, "raw", n = pointDataRecordLength * numberPointRecords, size = 1, endian = "little")
  close(to.read)
  
  pointDataRecordLength<-44  #11 variables of 4 bytes each
  numberPointRecords<-length(rawbytes)/44  #work out how many records there were in inputfile 
  #convert to a matrix
  allbytes <- matrix(rawbytes,ncol= pointDataRecordLength, nrow = numberPointRecords, byrow = TRUE)    
  
  #parse matrix
  #read in sets/lines of data and append to dataframe
  #first 12 bytes are 3x4byte integers
  ints<-matrix(readBin(t(allbytes[,1:12]), "integer", size = 4, n = 3 * numberPointRecords, endian = "little"), ncol = 3, byrow = TRUE)
  DateTime<- as.POSIXct(ints[,1],origin="1990-01-01",tz="UTC")+ints[,2]/1e9
  #create variable that assigns each record to correct 30 min interval
  Datebreaks <-nearestTimeStep(DateTime,nminutes=30) 
  table(Datebreaks)
  
  setwd("//ad.uws.edu.au/dfshare/HomesHWK$/90929058/My Documents/GitHub/AlexisCUP/Output 1 30min files with gaps in timestamp")
  filename<-paste(outputdir,"/eddyfast_",format(Datebreaks[1]+30*60,"%Y-%m-%d_%H-%M"),".dat",sep="")
  lastDB<-Datebreaks[1]
  to.write=file(filename,"ab") #open file in append mode
  
  for(i in 1:length(Datebreaks)){
    if(Datebreaks[i]!=lastDB){
      close(to.write)
      lastDB<-Datebreaks[i]
      filename<-paste(outputdir,"/eddyfast_",format(Datebreaks[i]+30*60,"%Y-%m-%d_%H-%M"),".dat",sep="")
      to.write=file(filename,"ab") #open file in append mode
      cat("writing-",filename,"\n")
    }
    writeBin(allbytes[i,], to.write,  endian="little", useBytes = TRUE)
  }
  close(to.write)
} #next inputfile
