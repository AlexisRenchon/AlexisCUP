require(HIEv)

sourcedir<-"L:/FastDataSplit"
destdir<-"L:/FastDataSplitFilled"

setwd(sourcedir)
filelist<-list.files(sourcedir)

for (filename in filelist){
  
#fillmissing<-function(filename=file.choose(),sourcedir=sourcedir,destdir=destdir){
  cat("working on ",filename,"\n")
  setwd(sourcedir)
  to.read = file(filename, "rb")
  #read in header lines these are in ASCII so need to get them out if the way
  #head<-readLines(to.read,n=5)
  #compute starttime from filename endtime
  date<-as.POSIXlt(substring(filename,10,19),tz="UTC")
  hour<-as.numeric(substring(filename,21,22)) #hour 0-23
  halfh<-as.numeric(substring(filename,24,25)) #half hour 0 or 30
  starttime<-date+hour*60*60+halfh*60-30*60
  endtime<-starttime+30*60-0.1
  #read all data into a matrix
  pointDataRecordLength<-44
  numberPointRecords<-19000
  #grab all data into memory
  rawbytes<-readBin(to.read, "raw", n = pointDataRecordLength * numberPointRecords, size = 1, endian = "little")
  close(to.read)
  
  pointDataRecordLength<-44  #11 variables of 4 bytes each
  numberPointRecords<-length(rawbytes)/44  #work out how many records there were 
  #convert to a matrix
  allbytes <- matrix(rawbytes,ncol= pointDataRecordLength, nrow = numberPointRecords, byrow = TRUE)    
  
  
  #parse matrix
  #read in sets/lines of data and append to dataframe
  #first 12 bytes are 3x4byte integers
  ints<-matrix(readBin(t(allbytes[,1:12]), "integer", size = 4, n = 3 * numberPointRecords, endian = "little"), ncol = 3, byrow = TRUE)
  #remaining 8x4 bytes are floating point numbers
  num<-matrix(readBin(t(allbytes[,13:44]), "numeric", size = 4, n = 8 * numberPointRecords, endian = "little"), ncol = 8, byrow = TRUE)
  #convert first two integers to datetime and milliseconds
  DateTime<- as.POSIXlt(ints[,1],origin="1990-01-01",tz="UTC")+(ints[,2])/1e9 
  #build all the data into a dataframe
  dat<-data.frame(DateTime,ints[,3],num[,])
  
  names(dat)<-c("DateTime","record","Ux_CSAT","Uy_CSAT","Uz_CSAT","Cc_7500","Ah_7500","Tv_CSAT","Diag_CSAT","Diag_7500")
  
  #strftime(dat[1,1],'%Y-%m-%d %H:%M:%OS2')
  #dat$t30 <-nearestTimeStep(dat$DateTime,nminutes=1)
  #table(dat$t30)
  dt<-round(diff(dat$DateTime),1) #look for gaps between successive records
  table(dt) #show freq of gap sizes should be 30*60*10=18000 values of 0.1
  
  
  #run through data and fill missing 10hz time slots with binary equivalent of -9999

  setwd(destdir)
  to.write=file(filename,"wb") #open file in append mode
  zz <- file("missinglines", "a")#opena file to log missing lines
  cat(file=zz,filename,"\n") #write current filename to log file 
  
  testtime<-starttime
  
  times<-seq(starttime,endtime,by=0.1)
  i<-1
  j<-1
  while(testtime<endtime){
    while(!isTRUE(all.equal(DateTime[i],times[j],0.0001))){ #times rarely exact so test using tolerance of 0.0001 sec
      t1<-as.integer(times[j]) #split timestamp into secs and 0.1 secs
      t2<-round(as.numeric(as.POSIXlt(times[j])-t1),1)*1e9 #same format as original binary file
      writeBin(t1,to.write,endian="little",size=4,useBytes = TRUE) #write seconds
      writeBin(as.integer(t2),to.write,endian="little",size=4,useBytes = TRUE) #write 0.1 secs x 1e9
      writeBin(as.integer(-9999),to.write,endian="little",size=4,useBytes = TRUE) #record number as -9999
      writeBin(rep(-9999,8),to.write,endian="little",size=4,useBytes = TRUE)#write other 8 missing values in line
      write(paste(strftime(times[j],'%Y-%m-%d %H:%M:%OS2')," ",i),file=zz) #write missing line to logfile
      j<-j+1
      if(j>18000){break}
     }
    if(j>18000){break}
    writeBin(allbytes[i,], to.write,  endian="little", useBytes = TRUE) #copy orignal line to new file
    i<-i+1
    j<-j+1
  }
  close(to.write)
  close(zz)
  
} #end function fillmissing

