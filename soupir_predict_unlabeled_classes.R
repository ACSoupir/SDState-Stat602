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
unlab.dat = read.csv(choose.files(caption = "Select Testing File...", ), stringsAsFactors = F)
#remove first indexed column
unlab.dat = unlab.dat[,-1]

#set seed because paranoia
set.seed(333)

#create empty variables
tst.dat.means = NULL
test.inde.vars = NULL
tst.dat.summarys = NULL

#separate variables based on unique trials
test.index.var = unlab.dat$Trial
test.indexes = unique(test.index.var)

#calculate descriptive statistics
for(i in test.indexes){
  temp2 = double()
  nam2 = double()
  tst.dat.i = unlab.dat[i==test.index.var, ]
  tst.mean.i = colMeans(tst.dat.i[,-(1:2)])
  tst.median.i = colMedians(as.matrix(tst.dat.i[,-(1:2)]))
  tst.var.i = colVars(as.matrix(tst.dat.i[,-(1:2)]))
  tst.sd.i = colSds(as.matrix(tst.dat.i[,-(1:2)]))
  tst.iqr.i = colIQRs(as.matrix(trn.dat.i[,-(1:5)]))
  tst.range.i = colRanges(as.matrix(tst.dat.i[,-(1:2)]))
  tst.mins.i = colMins(as.matrix(tst.dat.i[,-(1:2)]))
  tst.max.i = colMaxs(as.matrix(tst.dat.i[,-(1:2)]))
  test.inde.vars = rbind(test.inde.vars, tst.dat.i[1,1])
  for(j in 1:length(tst.mean.i)){
    temp2 = c(temp2, tst.mean.i[j], tst.median.i[j], tst.var.i[j], tst.sd.i[j], tst.iqr.i[j], tst.range.i[j], tst.mins.i[j], tst.max.i[j])
    nam2 = c(nam2, 
             paste(names(tst.mean.i[j]),"mean", sep="."), 
             paste(names(tst.mean.i[j]),"median", sep="."), 
             paste(names(tst.mean.i[j]),"var", sep="."), 
             paste(names(tst.mean.i[j]),"sd", sep="."), 
             paste(names(tst.mean.i[j]),"iqr", sep="."), 
             paste(names(tst.mean.i[j]),"range", sep="."), 
             paste(names(tst.mean.i[j]),"mins", sep="."), 
             paste(names(tst.mean.i[j]),"max", sep=".")
             )
    names(temp2) = nam2
  }
  tst.dat.summarys=rbind(tst.dat.summarys, temp2)
  row.names(tst.dat.summarys)[nrow(tst.dat.summarys)] = i
}

#identify which variables were kept for the training data and then remove all others for testing data
tst.dat.summarys.1 = as.data.frame(tst.dat.summarys[,colnames(tst.dat.summarys) %in% colnames(trn.dat.summarys.1)])

#predict principal components 
tst.comps = predict(prin.com.sum.mod, newdata = tst.dat.summarys.1)

#check princomp predcition of training data
#trn.comps = predict(prin.com.sum.mod, newdata = trn.dat.summarys.1)

#testing data predictions
tst.group.preds = predict(lda.sum.group.prin, newdata=tst.comps[,1:112])$class
tst.subject.preds = predict(lda.sum.sub.prin, newdata=tst.comps[,1:145])$class
tst.condition.preds = predict(lda.sum.cond.prin, newdata=tst.comps[,1:133])$class
tst.joint.preds = predict(lda.sum.joint.prin, newdata=tst.comps[,1:120])$class

#check predictions of the training data
#trn.group.preds = predict(lda.sum.group.prin, newdata=trn.comps[,1:112])$class
#trn.subject.preds = predict(lda.sum.sub.prin, newdata=trn.comps[,1:145])$class
#trn.condition.preds = predict(lda.sum.cond.prin, newdata=trn.comps[,1:133])$class
#trn.joint.preds = predict(lda.sum.joint.prin, newdata=trn.comps[,1:120])$class
