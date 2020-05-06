#Construction of classifier - Alex soupir - May 4, 2020
#with the 'labeled.csv

#attach libraries
library(MASS)

#import data
#
#
#
#if it appears to hang, it is just prompting to select a file in the background
#
#
#
lab.dat = read.csv(choose.files(caption = "Select Training File...", ), stringsAsFactors = F)
#remove first indexed column
lab.dat = lab.dat[,-1]

#set seed because paranoia
set.seed(333)

#create empty variables for the new data table and new variable table
trn.dat.summarys=NULL
inde.vars=NULL

#
index.var=apply(lab.dat[,1:4], 1, paste, collapse=":")

uni.vars = unique(index.var)
#ind.gro.sub = unique(group.subject)

#using the MatrixStats package to add the descriptive statistics
for(i in uni.vars){
  temp = double()
  nam = double()
  trn.dat.i=lab.dat[i==index.var, ]
  trn.mean.i=colMeans(trn.dat.i[,-(1:5)])
  trn.median.i = colMedians(as.matrix(trn.dat.i[,-(1:5)]))
  trn.var.i = colVars(as.matrix(trn.dat.i[,-(1:5)]))
  trn.sd.i = colSds(as.matrix(trn.dat.i[,-(1:5)]))
  trn.iqr.i = colIQRs(as.matrix(trn.dat.i[,-(1:5)]))
  trn.range.i = colRanges(as.matrix(trn.dat.i[,-(1:5)]))
  trn.mins.i = colMins(as.matrix(trn.dat.i[,-(1:5)]))
  trn.max.i = colMaxs(as.matrix(trn.dat.i[,-(1:5)]))
  inde.vars=rbind(inde.vars, trn.dat.i[1,(1:4)])
  for(j in 1:length(trn.mean.i)){
    temp = c(temp, trn.mean.i[j], trn.median.i[j], trn.var.i[j], trn.sd.i[j], trn.iqr.i[j], trn.range.i[j], trn.mins.i[j], trn.max.i[j])
    nam = c(nam, 
            paste(names(trn.mean.i[j]),"mean", sep="."), 
            paste(names(trn.mean.i[j]),"median", sep="."), 
            paste(names(trn.mean.i[j]),"var", sep="."), 
            paste(names(trn.mean.i[j]),"sd", sep="."), 
            paste(names(trn.mean.i[j]),"iqr", sep="."), 
            paste(names(trn.mean.i[j]),"range", sep="."), 
            paste(names(trn.mean.i[j]),"mins", sep="."), 
            paste(names(trn.mean.i[j]),"max", sep=".")
    )
    names(temp) = nam
  }
  trn.dat.summarys=rbind(trn.dat.summarys, temp)
  row.names(trn.dat.summarys)[nrow(trn.dat.summarys)] = i
  
}

classes.joint = apply(inde.vars[,1:3], 1, paste, collapse = ":")

#remove the columns that have zero variance (constant)
trn.dat.summarys.1 = as.data.frame(trn.dat.summarys[,apply(trn.dat.summarys, 2, var, na.rm=TRUE) != 0])
#(dim(trn.dat.summarys)-dim(trn.dat.summarys.1))[2]

#PCA on new data
set.seed(333)
prin.com.sum.mod = princomp(trn.dat.summarys.1, cor=T)


#creating the lda models
#The accuracies of running them in this way, even using the same PCs in training the model, result in slightly different accuracies.
#my guess is that this is because when selecting pcs through the foreach function, there were other processes causing shifts in random numbers
#by the time it go to training the model itself (handing out runs to different threads). I've read before this can be an issue in 
#gpu parallel proccessing so maybe the same is happening here?
#either way accuracies are still pretty close to what they were when selecting the model.
#For predictions, you cannot set CV=T because then it apparently doens't retain the model :
# https://stackoverflow.com/questions/60302223/lda-no-applicable-method-for-predict-applied-to-an-object-of-class-list
set.seed(333)
lda.sum.group.prin = MASS::lda(x=prin.com.sum.mod$scores[,1:112],grouping=inde.vars[,1])
#mean(lda.sum.group.prin$class == inde.vars[,1])
set.seed(333)
lda.sum.sub.prin = MASS::lda(x=prin.com.sum.mod$scores[,1:145], grouping=inde.vars[,2])
#mean(lda.sum.sub.prin$class == inde.vars[,2])
set.seed(333)
lda.sum.cond.prin = MASS::lda(x=prin.com.sum.mod$scores[,1:133], grouping=inde.vars[,3])
#mean(lda.sum.cond.prin$class == inde.vars[,3])
set.seed(333)
lda.sum.joint.prin = MASS::lda(x=prin.com.sum.mod$scores[,1:120], grouping=classes.joint)
#mean(lda.sum.joint.prin$class == classes.joint)

#accuracies when selecting the model
#0.9597222  0.8694444  0.7201389  0.7076389 