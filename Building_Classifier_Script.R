#Original code from Christopher Saunders
#Additional code and methods from Alex Soupir
# April 26, 2020
#
#
#
# I wouldn't run some of the models with validation
# Logistic regression LOOCV takes an extremely long time using the multinom function from nnet
#
# This is a "skunk work" project - determining whether there is something there to pursue further
#
#
#
#
#
#
#
#
#
#

#Import Data############################################################################################################ 
#importing data
lab.dat = read.csv("labeled.csv", stringsAsFactors = F)
lab.dat = lab.dat[,-1]
unlab.dat = read.csv("unlab.example.trial.csv", stringsAsFactors = F)
unlab.dat = unlab.dat[,-1]

# unlab samples are just the first 2 from labeled

#Libraries
#MASS
#nnet
#MNLpred


#consistency
set.seed(333)

#calculate means############################################################################################################
#saunders code
trn.dat.means=NULL
inde.vars=NULL

index.var=apply(lab.dat[,1:4], 1, paste, collapse=":")
group.subject = apply(lab.dat[,1:2], 1, paste, collapse=":")

uni.vars = unique(index.var)
ind.gro.sub = unique(group.subject)

for(i in uni.vars){
  trn.dat.i=lab.dat[i==index.var, ]
  trn.mean.i=colMeans(trn.dat.i[,-(1:5)])
  inde.vars=rbind(inde.vars, trn.dat.i[1,(1:4)])
  trn.dat.means=rbind(trn.dat.means, trn.mean.i)
}

#setting up test variables to be used for predictions
tst.dat.means = NULL
test.inde.vars = NULL
test.index.var = unlab.dat$Trial
test.indexes = unique(test.index.var)
for(i in test.indexes){
  tst.dat.i = unlab.dat[i==test.index.var, ]
  tst.mean.i = colMeans(tst.dat.i[,-(1:2)])
  test.inde.vars = rbind(test.inde.vars, tst.dat.i[1,1])
  tst.dat.means=rbind(tst.dat.means, tst.mean.i)
}

library(MASS)
summary(trn.dat.means)
cbind(colnames(trn.dat.means))
#remove 0 columns############################################################################################################
trn.dat.means2=trn.dat.means[, -c(13, 14)]
tst.dat.means2=tst.dat.means[, -c(13,14)]

boxplot.dat.group=data.frame(inde.vars[,1],trn.dat.means2)
colnames(boxplot.dat.group)
par(mfrow=c(6,4))
for(i in 2:length(boxplot.dat.group)){
  boxplot(boxplot.dat.group[,i]~boxplot.dat.group[,1], main=paste(colnames(boxplot.dat.group)[i]))
}

boxplot.dat.cond=data.frame(inde.vars[,3],trn.dat.means2)
colnames(boxplot.dat.cond)
par(mfrow=c(6,4))
for(i in 2:length(boxplot.dat.cond)){
  boxplot(boxplot.dat.cond[,i]~boxplot.dat.cond[,1], main=paste(colnames(boxplot.dat.cond)[i]))
}

#remove non-separation columns############################################################################################################
##removing those with little separation in the boxplots between the groups
trn.dat.means3=trn.dat.means2[, -c(4,6,18,19,21,22,23)]

prin.comp.mod=princomp(trn.dat.means3, cor = T)
plot(prin.comp.mod)

my.cols=c("red", "blue")
pairs(prin.comp.mod$scores[, 1:10], pch=16, cex=.5,
      col=my.cols[(inde.vars[,1]=="CUR")+1])


#lda and qda on no-sep data############################################################################################################
#Linear Discriminant Analysis
#Almost the same as the code from the playing with data video
# additional predictors removed 
lda.mod.group.prin=lda(x=prin.comp.mod$scores[, 1:10],
                       grouping = inde.vars[,1], CV=T)

lda.prin.group = mean(lda.mod.group.prin$class==inde.vars[,1])

lda.mod.sub.prin=lda(x=prin.comp.mod$scores[, 1:10],
                     grouping = inde.vars[,2], CV=T)

lda.prin.sub = mean(lda.mod.sub.prin$class==inde.vars[,2])

lda.mod.con.prin=lda(x=prin.comp.mod$scores[, 1:10],
                     grouping = inde.vars[,3], CV=T)

lda.prin.con = mean(lda.mod.con.prin$class==inde.vars[,3])

con.confus=data.frame(cbind(paste(lda.mod.con.prin$class),
                            paste(inde.vars[,3])))

xtabs(~X1+X2, con.confus)

##############
paste(lda.mod.group.prin$class)[1]
paste(lda.mod.sub.prin$class)[1]
paste(lda.mod.con.prin$class)[1]

accuracies = data.frame()
lda.prin = c(lda.prin.group,
             lda.prin.sub,
             lda.prin.con)
accuracies = rbind(accuracies, lda.prin)
colnames(accuracies) = c("Group", "Subject", "Condition")
row.names(accuracies)[1] = "LDA PCA No-Sep Removed (cps modified)"

classes.joint=
  apply(inde.vars[,1:3], 1, paste, collapse = ":")

lda.mod.joint.prin=lda(x=prin.comp.mod$scores[, 1:10],
                       grouping = classes.joint, CV=T)

lda.mod.joint.prin$class[1:3]

mean(paste(lda.mod.joint.prin$class)==classes.joint)

#Quadratic Discriminant Analysis
qda.mod.group.prin=qda(x=prin.comp.mod$scores[, 1:10],
                       grouping = inde.vars[,1], CV=T)

qda.pca.group = mean(qda.mod.group.prin$class==inde.vars[,1])

qda.mod.sub.prin=qda(x=prin.comp.mod$scores[, 1:10],
                     grouping = inde.vars[,2], CV=T)

#mean(qda.mod.sub.prin$class==inde.vars[,2])

test2=as.character(qda.mod.sub.prin$class)==inde.vars[,2]
qda.pca.sub = table(test2)["TRUE"]/length(test2)

qda.mod.con.prin=qda(x=prin.comp.mod$scores[, 1:10],
                     grouping = inde.vars[,3], CV=T)

qda.pca.con = mean(qda.mod.con.prin$class==inde.vars[,3])

con.confus=data.frame(cbind(paste(qda.mod.con.prin$class),
                            paste(inde.vars[,3])))

xtabs(~X1+X2, con.confus)

##############
paste(qda.mod.group.prin$class)[1]
paste(qda.mod.sub.prin$class)[1]
paste(qda.mod.con.prin$class)[1]

qda.prin = c(qda.pca.group,
             qda.pca.sub,
             qda.pca.con)
accuracies = rbind(accuracies, qda.prin)
row.names(accuracies)[2] = "QDA PDA No-Sep Removed (cps modified)"
### grouping all of them gives an error as some don't have enough samples?
#qda.mod.joint.prin=qda(x=prin.comp.mod$scores[, 1:10],
#                       grouping = classes.joint, CV=T)

#qda.mod.joint.prin$class[1:3]

#mean(paste(qda.mod.joint.prin$class)==classes.joint)

#QDA decreases the accuracy of the group and condition, while increasing the accuracy of subjects by more
# than 10% (0.290 -> 0.399). Group accuracy decrased by 3% (0.896 -> 0.869) 
# and condition by a 5% (0.327 -> 0.274)

#lda and qda on raw means############################################################################################################
#fitting on mean data rather than pc's
lda.mod.group.mean=lda(x=trn.dat.means3,
                       grouping = inde.vars[,1], CV=T)

lda.mean.group = mean(lda.mod.group.mean$class==inde.vars[,1])

lda.mod.sub.mean=lda(x=trn.dat.means3,
                     grouping = inde.vars[,2], CV=T)

lda.mean.sub = mean(lda.mod.sub.mean$class==inde.vars[,2])

lda.mod.con.mean=lda(x=trn.dat.means3,
                     grouping = inde.vars[,3], CV=T)

lda.mean.con = mean(lda.mod.con.mean$class==inde.vars[,3])

lda.mean.unscl = c(lda.mean.group,
                   lda.mean.sub,
                   lda.mean.con)
accuracies = rbind(accuracies, lda.mean.unscl)
row.names(accuracies)[3] = "LDA on Means No Scale (cps modified)"

#Fitting an LDA on the 'raw' means rather than pc's improves the accuracy for all of the response varialbes
# group pc acc 0.896 -> means acc 0.917
# subject pc acc 0.290 -> means acc 0.398
# condition pc acc 0.327 -> means acc 0.372

qda.mod.group.mean=qda(x=trn.dat.means3,
                       grouping = inde.vars[,1], CV=T)
test2=as.character(qda.mod.group.mean$class)==inde.vars[,1]
qda.mean.group = table(test2)["TRUE"]/length(test2)
#qda.mean.group = mean(qda.mod.group.mean$class==inde.vars[,1])

qda.mod.sub.mean=qda(x=trn.dat.means3,
                     grouping = inde.vars[,2], CV=T)
#mean(qda.mod.sub.prin$class==inde.vars[,2])
test2=as.character(qda.mod.sub.mean$class)==inde.vars[,2]
qda.mean.sub = table(test2)["TRUE"]/length(test2)

qda.mod.con.mean=qda(x=trn.dat.means3,
                     grouping = inde.vars[,3], CV=T)
test2=as.character(qda.mod.con.mean$class)==inde.vars[,3]
qda.mean.con = table(test2)["TRUE"]/length(test2)
#qda.mean.con = mean(qda.mod.con.mean$class==inde.vars[,3])

qda.mean.unscl = c(qda.mean.group,
                   qda.mean.sub,
                   qda.mean.con)
accuracies = rbind(accuracies, qda.mean.unscl)
row.names(accuracies)[4] = "QDA on Means No Scale (cps modified)"

#fitting the qda on the mean data rather than pc's decreased the accuracy of the 
# Group response (0.869 -> 0.698), but increased the Subject (0.399 -> 0.474) and 
# Condition (0.274 -> 0.285)

#############################################################################################################
#Trying to go back to the whole data set means rather than down-selecting
#for those that show separation between the groups since it didn't show much
#improvement over the values in the video
lda.mod.group.mean=lda(x=trn.dat.means2,
                       grouping = inde.vars[,1], CV=T)

lda.mean.group = mean(lda.mod.group.mean$class==inde.vars[,1])

lda.mod.sub.mean=lda(x=trn.dat.means2,
                     grouping = inde.vars[,2], CV=T)

lda.mean.sub = mean(lda.mod.sub.mean$class==inde.vars[,2])

lda.mod.con.mean=lda(x=trn.dat.means2,
                     grouping = inde.vars[,3], CV=T)

lda.mean.con = mean(lda.mod.con.mean$class==inde.vars[,3])

lda.mean.unscl = c(lda.mean.group,
                   lda.mean.sub,
                   lda.mean.con)
accuracies = rbind(accuracies, lda.mean.unscl)
row.names(accuracies)[5] = "LDA on Means No Scale (cps means)"

#Fitting an LDA on the 'raw' means rather than pc's improves the accuracy for all of the response varialbes
# group pc acc 0.896 -> means acc 0.924
# subject pc acc 0.290 -> means acc 0.700
# condition pc acc 0.327 -> means acc 0.406

qda.mod.group.mean=qda(x=trn.dat.means2,
                       grouping = inde.vars[,1], CV=T)
test2=as.character(qda.mod.group.mean$class)==inde.vars[,1]
qda.mean.group = table(test2)["TRUE"]/length(test2)
#qda.mean.group = mean(qda.mod.group.mean$class==inde.vars[,1])

qda.mod.sub.mean=qda(x=trn.dat.means2,
                     grouping = inde.vars[,2], CV=T)
#mean(qda.mod.sub.prin$class==inde.vars[,2])
test2=as.character(qda.mod.sub.mean$class)==inde.vars[,2]
qda.mean.sub = table(test2)["TRUE"]/length(test2)

qda.mod.con.mean=qda(x=trn.dat.means2,
                     grouping = inde.vars[,3], CV=T)
test2=as.character(qda.mod.con.mean$class)==inde.vars[,3]
qda.mean.con = table(test2)["TRUE"]/length(test2)
#qda.mean.con = mean(qda.mod.con.mean$class==inde.vars[,3])

qda.mean.unscl = c(qda.mean.group,
                   qda.mean.sub,
                   qda.mean.con)
accuracies = rbind(accuracies, qda.mean.unscl)
row.names(accuracies)[6] = "QDA on Means No Scale (cps means)"

#QDA on the main means tables from cps with the 2 variables removed resulted again in a decrease from the
# Group accuracy (0.869 -> 0.688) but large increase in the Subject (0.291 -> 0.658) and 
# Condition (0.326 -> 0.382) accuracies

#scale to mean = 0, sd = 1
trn.dat.means2.scl = scale(trn.dat.means2)

lda.mod.group.mean=lda(x=trn.dat.means2.scl,
                       grouping = inde.vars[,1], CV=T)

lda.mean.group = mean(lda.mod.group.mean$class==inde.vars[,1])

lda.mod.sub.mean=lda(x=trn.dat.means2.scl,
                     grouping = inde.vars[,2], CV=T)

lda.mean.sub = mean(lda.mod.sub.mean$class==inde.vars[,2])

lda.mod.con.mean=lda(x=trn.dat.means2.scl,
                     grouping = inde.vars[,3], CV=T)

lda.mean.con = mean(lda.mod.con.mean$class==inde.vars[,3])

lda.mean.unscl = c(lda.mean.group,
                   lda.mean.sub,
                   lda.mean.con)
accuracies = rbind(accuracies, lda.mean.unscl)
row.names(accuracies)[7] = "LDA on Means Scaled (cps means)"

#Fitting an LDA on the 'raw' means rather than pc's improves the accuracy for all of the response varialbes
# group pc acc 0.896 -> means acc 0.922
# subject pc acc 0.290 -> means acc 0.700
# condition pc acc 0.327 -> means acc 0.407
# This caused a decrease in Group when compared to the unscaled means (only by 0.002) and increased 
# Condition by 0.001, 

qda.mod.group.mean=qda(x=trn.dat.means2.scl,
                       grouping = inde.vars[,1], CV=T)
test2=as.character(qda.mod.group.mean$class)==inde.vars[,1]
qda.mean.group = table(test2)["TRUE"]/length(test2)
#qda.mean.group = mean(qda.mod.group.mean$class==inde.vars[,1])

qda.mod.sub.mean=qda(x=trn.dat.means2.scl,
                     grouping = inde.vars[,2], CV=T)
#mean(qda.mod.sub.prin$class==inde.vars[,2])
test2=as.character(qda.mod.sub.mean$class)==inde.vars[,2]
qda.mean.sub = table(test2)["TRUE"]/length(test2)

qda.mod.con.mean=qda(x=trn.dat.means2.scl,
                     grouping = inde.vars[,3], CV=T)
test2=as.character(qda.mod.con.mean$class)==inde.vars[,3]
qda.mean.con = table(test2)["TRUE"]/length(test2)
#qda.mean.con = mean(qda.mod.con.mean$class==inde.vars[,3])

qda.mean.unscl = c(qda.mean.group,
                   qda.mean.sub,
                   qda.mean.con)
accuracies = rbind(accuracies, qda.mean.unscl)
row.names(accuracies)[8] = "QDA on Means Scaled (cps means)"

#QDA on the main means tables from cps with the 2 variables removed resulted again in a decrease from the
# Group accuracy (0.869 -> 0.688) but large increase in the Subject (0.291 -> 0.658) and 
# Condition (0.326 -> 0.382) accuracies
# These accuracies are the same as the ones from the unscaled means.

#Making predictions on the unlabeled data provided
trn.dat.means2.scl_mean = attr(trn.dat.means2.scl, 'scaled:center')
trn.dat.means2.scl_sd = attr(trn.dat.means2.scl, 'scaled:scale')
test_data_scaled = scale(tst.dat.means2, center = trn.dat.means2.scl_mean, scale = trn.dat.means2.scl_sd)

#models
#lda.mod.group.mean
#lda.mod.sub.mean
#lda.mod.con.mean

lda.mod.group.mean=lda(x=trn.dat.means2.scl,
                       grouping = inde.vars[,1])

lda.mod.sub.mean=lda(x=trn.dat.means2.scl,
                     grouping = inde.vars[,2])

lda.mod.con.mean=lda(x=trn.dat.means2.scl,
                     grouping = inde.vars[,3])

lda.group.prds = predict(lda.mod.group.mean, test_data_scaled)$class
lda.sub.prds = predict(lda.mod.sub.mean, test_data_scaled)$class
lda.con.prds = predict(lda.mod.con.mean, test_data_scaled)$class

lda.group.prds
lda.sub.prds
lda.con.prds

#Predicting that the 2 samples come from cursive writings from subjects 00Q and 0, writing the first line.

#Logistic Regression - with multiple predictors, algorithm does not converge
#converting from matrix to data frame makes all values in the matrix a factor?
#convert from factor out to numeric allows logistic regression fitting.
#only works with group since there are 2 different
set.seed(333)
group.scaled = as.data.frame(cbind(inde.vars$Group, trn.dat.means2.scl))
subject.scaled = as.data.frame(cbind(inde.vars$Subject, trn.dat.means2.scl))
cond.scaled = as.data.frame(cbind(inde.vars$Condition, trn.dat.means2.scl))

for(i in 2:length(group.scaled)){
  group.scaled[,i] = as.numeric(as.character(group.scaled[,i]))
  subject.scaled[,i] = as.numeric(as.character(subject.scaled[,i]))
  cond.scaled[,i] = as.numeric(as.character(cond.scaled[,i]))
}
#pairs(group.scaled, pch=16, cex=.5,
#      col=my.cols[(inde.vars[,1]=="CUR")+1])
colnames(group.scaled)
#https://www.r-bloggers.com/how-to-multinomial-regression-models-in-r/
#since the logistic regression with many response factors (more than 2) was confusing
# I went looking for another option and found the multinom function in nnet which seemed to do the trick
library(MNLpred)
library(nnet)
logreg.group = multinom(V1~., data=group.scaled, Hess=TRUE)
group.preds.log = predict(logreg.group, group.scaled, "class")
group.preds.matrix = table(group.preds.log, group.scaled$V1)
group.preds.matrix
group.log.acc = sum(diag(group.preds.matrix))/sum(group.preds.matrix)
group.log.acc
#0.933
logreg.subject = multinom(V1~., data=subject.scaled)
subject.preds.log = predict(logreg.subject, subject.scaled, "class")
subject.preds.matrix = table(subject.preds.log, subject.scaled$V1)
subject.preds.matrix
subject.log.acc = sum(diag(subject.preds.matrix))/sum(subject.preds.matrix)
subject.log.acc
#0.943
logreg.cond = multinom(V1~., data=cond.scaled, Hess=TRUE)
cond.preds.log = predict(logreg.cond, cond.scaled, "class")
cond.preds.matrix = table(cond.preds.log, cond.scaled$V1)
cond.preds.matrix
cond.log.acc = sum(diag(cond.preds.matrix))/sum(cond.preds.matrix)
cond.log.acc
#0.456
log.reg.accs = c(group.log.acc,
                 subject.log.acc,
                 cond.log.acc)
accuracies = rbind(accuracies,
                   log.reg.accs)
row.names(accuracies)[9] = "Logistic Regression (No-CV/Just Test)"

#Running LOOCV on Logist Regression
#Testing individual response variables
group.error = double()
group.correct=double()
subject.error = double()
subject.correct=double()
cond.error = double()
cond.correct = double()
#due to the amount of computational power needed for the `multinom` function, I am running every 50th row as LOOCV
runs = seq(1, nrow(group.scaled), 1)
for(i in runs){
  group.model = glm(V1~., data=group.scaled[-i,], family=binomial())
  group.preds = predict(group.model, group.scaled[i,], type="response")
  group.preds2 = ifelse(0.5>group.preds, "CUR","PRI")
  group.error = append(group.error, group.preds2 != group.scaled[i,]$V1)
  group.correct = append(group.correct, group.preds2==group.scaled[i,]$V1)
  
  invisible(capture.output(subject.model <- multinom(V1~., data=subject.scaled[-i,])))
  subject.preds = predict(subject.model, subject.scaled[i,], "probs")
  subject.error = append(subject.error, names(which.max(subject.preds)) != subject.scaled[i,]$V1)
  subject.correct = append(subject.correct, names(which.max(subject.preds)) == subject.scaled[i,]$V1)
  
  invisible(capture.output(cond.model <- multinom(V1~., data=cond.scaled[-i,], Hess=TRUE)))
  cond.preds = predict(cond.model, cond.scaled[i,], "probs")
  cond.error = append(cond.error, names(which.max(cond.preds)) != cond.scaled[i,]$V1)
  cond.correct = append(cond.correct, names(which.max(cond.preds)) == cond.scaled[i,]$V1)
  
  print(i)
}
group.scaled.error.logistic = mean(group.error)
group.scaled.error.logistic
group.scaled.acc.logistic = mean(group.correct)
group.scaled.acc.logistic

subject.scaled.error.logistic = mean(subject.error)
subject.scaled.error.logistic
subject.scaled.acc.logistic = mean(subject.correct)
subject.scaled.acc.logistic

cond.scaled.error.logistic = mean(cond.error)
cond.scaled.error.logistic
cond.scaled.acc.logistic = mean(cond.correct)
cond.scaled.acc.logistic

log.reg.loocv.accs = c(group.scaled.acc.logistic,
                       subject.scaled.acc.logistic,
                       cond.scaled.acc.logistic)
accuracies = rbind(accuracies,
                   log.reg.loocv.accs)
row.names(accuracies)[10] = "Logistic Regression (LOOCV)"
#LOO cross-validation slightly decreases accuracy but not by much

#comps  = as.data.frame(cbind(inde.vars[,1],prin.comp.mod$scores))
#logreg.group = glm(V1~., data=comps,family='binomial')

#Neural Networks? Basic first - NeuralNet Package
library(neuralnet)
#one person on stackexchange suggested a hidden layer with 2/3 input + output, just between input and output, or not more than twice input
#https://stats.stackexchange.com/questions/181/how-to-choose-the-number-of-hidden-layers-and-nodes-in-a-feedforward-neural-netw
groups = c("CUR","PRI")
subjects = names(subject.preds)
conditions = names(cond.preds)

group.error = double()
group.correct=double()
subject.error = double()
subject.correct=double()
cond.error = double()
cond.correct = double()

runs = seq(1, nrow(group.scaled), 100)
set.seed(333)
for(i in runs){
  group.net = neuralnet(V1~.,
                        data=group.scaled[-i,],
                        hidden = 15,
                        err.fct = 'sse',
                        linear.output = FALSE)
  group.ouput = compute(group.net, group.scaled[i,])
  #head(group.ouput$net.result)
  colnames(group.ouput$net.result) = groups
  group.error = append(group.error, groups[which.max(group.ouput$net.result)] != group.scaled[i,]$V1)
  group.correct = append(group.correct, groups[which.max(group.ouput$net.result)] == group.scaled[i,]$V1)
  
  subject.net = neuralnet(V1~.,
                          data=subject.scaled[-i,],
                          hidden = 15,
                          err.fct = 'sse',
                          linear.output = FALSE)
  subject.ouput = compute(subject.net, subject.scaled[i,])
  #head(subject.ouput$net.result)
  colnames(subject.ouput$net.result) = subjects
  subject.error = append(subject.error, subjects[which.max(subject.ouput$net.result)] != subject.scaled[i,]$V1)
  subject.correct = append(subject.correct, subjects[which.max(subject.ouput$net.result)] == subject.scaled[i,]$V1)
  
  #cond.net = neuralnet(V1~.,
  #                     data=cond.scaled[-i,],
  #                     hidden = 5,
  #                     err.fct = 'sse',
  #                     linear.output = FALSE,
  #                    stepmax = 1e+5)
  #cond.ouput = compute(cond.net, cond.scaled[i,])
  #head(cond.ouput$net.result)
  #colnames(cond.ouput$net.result) = conditions
  #cond.error = append(cond.error, conditions[which.max(cond.ouput$net.result)] != cond.scaled[i,]$V1)
  #cond.correct = append(cond.correct, conditions[which.max(cond.ouput$net.result)] == cond.scaled[i,]$V1)
  
  print(i)
}

nn.group.error = mean(group.error)
nn.group.error
nn.group.correct = mean(group.correct)
nn.group.correct

nn.subject.error = mean(subject.error)
nn.subject.error
nn.subject.correct = mean(subject.correct)
nn.subject.correct

nn.accs = c(nn.group.correct,
            nn.subject.correct,
            "Did Not Converge")
accuracies = rbind(accuracies,
                   nn.accs)
row.names(accuracies)[11] = "Neural-Net (normalized 23 factor)"

#                                                   Group           Subject         Condition
# LDA PCA No-Sep Removed (cps modified) 0.895138888888889 0.289583333333333 0.326388888888889 #removed 7 more predictors that didn't appear to offer separation
# QDA PDA No-Sep Removed (cps modified)           0.86875 0.398611111111111 0.274305555555556 #removed 7 more predictors that didn't appear to offer separation
# LDA on Means No Scale (cps modified)  0.914583333333333 0.397916666666667 0.372916666666667 #removed 7 more predictors that didn't appear to offer separation
# QDA on Means No Scale (cps modified)  0.697916666666667 0.473611111111111 0.284722222222222 #removed 7 more predictors that didn't appear to offer separation
# LDA on Means No Scale (cps means)     0.920833333333333               0.7           0.40625 #only 2 removed as per lecture
# QDA on Means No Scale (cps means)     0.688194444444444 0.658333333333333 0.381944444444444 #only 2 removed as per lecture
# LDA on Means Scaled (cps means)       0.922222222222222               0.7 0.406944444444444 #only 2 removed as per lecture and scaled
# QDA on Means Scaled (cps means)       0.688194444444444 0.658333333333333 0.381944444444444 #only 2 removed as per lecture and scaled
# Logistic Regression (No-CV/Just Test) 0.932638888888889 0.943055555555556 0.455555555555556 #Single run logistic regression (scaled only 2 removed)
# Logistic Regression (LOOCV - 50th)     0.96551724137931 0.758620689655172 0.517241379310345 #LOOCV (every 50th) logistic (scaled only 2 removed)
# Neural-Net (normalized 23 factor)                     1 0.733333333333333  Did Not Converge #15 hidden perceptrons (scaled only 2 removed)

#idea - time series with multiple response
#idea - take each predictor column and scale it, then take row means as a predictor for hte bigtime package
#       This could work because each row will be up to 75 obervations for a particular run

#############################################################################################################
library(class)
set.seed(333)
classes.joint=apply(inde.vars[,c(2,3)], 1, paste, collapse = ":")
knn.correct = double()
for(i in seq(classes.joint)){
  knn.prin.matrix = as.matrix(trn.dat.means2[-i,])
  knn.labs = classes.joint[-i]
  knn.prin.test = t(as.matrix(trn.dat.means2[i,]))
  knn.prin.joint = knn(knn.prin.matrix, knn.prin.test, knn.labs, k=2)
  knn.correct = append(knn.correct, knn.prin.joint == classes.joint[i])
}
knn.acc = mean(knn.correct)
knn.acc
##absolutely trash for the KNN of 1 or even 2 for the joined predictors
#k=1 is 0.1104167
#k=2 is 0.0847222

classes.joint=apply(inde.vars[,c(2,3)], 1, paste, collapse = ":")
set.seed(333)
knn.correct = double()
for(i in seq(classes.joint)){
  knn.prin.matrix = as.matrix(trn.dat.means2.scl[-i,])
  knn.labs = classes.joint[-i]
  knn.prin.test = t(as.matrix(trn.dat.means2.scl[i,]))
  knn.prin.joint = knn(knn.prin.matrix, knn.prin.test, knn.labs, k=1)
  knn.correct = append(knn.correct, knn.prin.joint == classes.joint[i])
}
knn.acc = mean(knn.correct)
knn.acc

#columns are group, subject, condition
#k=1                        unscaled      scaled
#group:subject:condition =  0.1104167     0.3423611
#group:subject =            0.3034722     0.6090278
#group:condition =          0.3034722     0.4645833
#subject:condition =        0.1159722     
#k=2                                      
#group:subject:condition =  0.08472222    0.2756944
#group:subject =            0.2631944     0.5729167
#group:condition =          0.1736111     0.3895833
#subject:condition =        0.09722222    0.2715278


#############################################################################################################




#https://github.com/magnusfurugard/featuretoolsR
##TRASH PACKAGE - Should only be used in python because reticulate 

# library(featuretoolsR)
# library(magrittr)
# set_1 <- data.frame(key = 1:100, value = sample(letters, 100, T), a = rep(Sys.Date(), 100))
# set_2 <- data.frame(key = 1:100, value = sample(LETTERS, 100, T), b = rep(Sys.time(), 100))
# 
# es <- as_entityset(
#   featuretool.dat[,c(1,2)],
#   index = "key", 
#   entity_id = "set_1", 
#   id = "demo",
# )
# es <- es %>%
#   add_entity(
#     df = featuretool.dat[,c(1,4)], 
#     entity_id = "set_3", 
#     index = "key"
#   )
# es <- es %>%
#   add_relationship(
#     parent_set = "connections", 
#     child_set = "related", 
#     parent_idx = "key1", 
#     child_idx = "key1"
#   )
# ft_matrix <- test.dat %>%
#   dfs(
#     target_entity = "Direction",
#     agg_primitives = c("sum", "std", "max", "skew", "min", "mean", "count", "percent_true", "num_unique", "mode"),
#     trans_primitives = c("and", "cum_sum"),
#     max_depth = 20, features_only=F, verbose=T
#   )
# tidy <- tidy_feature_matrix(ft_matrix, remove_nzv = T, nan_is_na = T, clean_names = T)
# View(tidy)
# 
# classes_joint=
#   apply(inde.vars[,1:4], 1, paste, collapse = ":")
# featuretool.dat = as.data.frame(cbind(key1 = 1:1440, trn.dat.means2))
# featuretool.cols = colnames(featuretool.dat)
# 
# #creating the entityset
# Direction.dat = as_entityset(
#   featuretool.dat[,c(1,2,3,4,7)],
#   index = "key1",
#   entity_id = "connections",
#   id = "not_normalized"
# )
# Direction.dat <- Direction.dat %>%
#   add_entity(
#     df = featuretool.dat[,c(1,3:24)], 
#     entity_id = "related", 
#     index = "key1"
#   )
# 
# #addint all variables as entities
# for(i in 3:length(featuretool.dat)){
#   Direction.dat = Direction.dat %>%
#     add_entity(
#       df = featuretool.dat[,c(1,i)],
#       index = "key1",
#       entity_id = colnames(featuretool.dat)[i]
#     )
#   test.dat = test.dat %>%
#     add_relationship(
#       parent_set = "Direction",
#       child_set = featuretool.cols[i],
#       parent_idx = "key1",
#       child_idx = "key1"
#     )
# }
# 
# for(i in 4:length(featuretool.cols)){
#   test.dat = test.dat %>%
#     add_entity(
#       df = featuretool.dat[,c(1,i)],
#       index = "key2",
#       entity_id = featuretool.cols[i]
#     )
#   test.dat = test.dat %>%
#     add_relationship(
#       parent_set = "Duration",
#       child_set = featuretool.cols[i],
#       parent_idx = "key2",
#       child_idx = "key2"
#     )
# }
# 
# #defining relationships
# #parent and  child set is the column headings
# #idx is the index, or "key"
# 
# relationships = data.frame("parent"=c(rep(2, 22), 
#                                       rep(3, 21), 
#                                       rep(4, 18),
#                                       rep(7,16)),
#                            "child"=c(rep(3:24,1),
#                                      rep(4:24,1),
#                                      rep(c(5:6, 9:24),1),
#                                      rep(c(8:11, 13:24),1)))
# 
# for(i in seq(nrow(relationships)))
# 
# #This package does not work. Issue with python implementation in reticulate and featuretoolsR
# #
# # for(i in 1:nrow(relationships)){
# #   test.dat = test.dat %>%
# #     add_relationship(
# #       parent_set = featuretool.cols[relationships[i,1]],
# #       child_set = featuretool.cols[relationships[i,2]],
# #       parent_idx = "key",
# #       child_idx = "key"
# #     )
# # }
# # 
# direction_matrix =
#   dfs(
#     entityset = test.dat,
#     target_entity = "Direction",
# 
#     #agg_primitives = c("sum", "std", "max", "skew", "min", "mean", "count", "percent_true", "num_unique", "mode"),
#     trans_primitives = list("and"),
#     max_depth = 20, features_only=F, verbose=T
#   )
# 
# directions_table = tidy_feature_matrix(direction_matrix, remove_nzv = T, nan_is_na = T, clean_names = T)


#############################################################################################################
#Just getting as many descriptors as possible for the data
#looked for hours of how to do a sort of analysis of many time points for replications of 'something' and couldn't figure it out, so gave up.
#
#hallelujah - something that finally seems to work (well)
#
#for this, I built on the in class example 
#

#setting seed because paranoia is real
#this setup is basically the same as before with the addition of loading the matrixStats library
#and adding more descriptive statistics about each variable
set.seed(333)
library(MASS)
library(matrixStats)
library(e1071)
library(foreach)
library(doParallel)
registerDoParallel(8)
trn.dat.summarys=NULL
inde.vars=NULL

index.var=apply(lab.dat[,1:4], 1, paste, collapse=":")
group.subject = apply(lab.dat[,1:2], 1, paste, collapse=":")


uni.vars = unique(index.var)
ind.gro.sub = unique(group.subject)

#using the MatrixStats package to add the descriptive statistics
for(i in uni.vars){
  temp = double()
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
  }
  trn.dat.summarys=rbind(trn.dat.summarys, temp)
}

classes.joint = apply(inde.vars[,1:3], 1, paste, collapse = ":")

#setting up test variables to be used for predictions
tst.dat.means = NULL
test.inde.vars = NULL
test.index.var = unlab.dat$Trial
test.indexes = unique(test.index.var)
for(i in test.indexes){
  tst.dat.i = unlab.dat[i==test.index.var, ]
  tst.mean.i = colMeans(tst.dat.i[,-(1:2)])
  test.inde.vars = rbind(test.inde.vars, tst.dat.i[1,1])
  tst.dat.means=rbind(tst.dat.means, tst.mean.i)
}

#remove the columns that have zero variance (constant)
trn.dat.summarys.1 = as.data.frame(trn.dat.summarys[,apply(trn.dat.summarys, 2, var, na.rm=TRUE) != 0])
dim(trn.dat.summarys)-dim(trn.dat.summarys.1)
#removing those columns leaves us with 22 less

#PCA on new data
set.seed(333)
prin.com.sum.mod = princomp(trn.dat.summarys.1, cor=T)
plot(prin.com.sum.mod)

#group.acc = double()
#for(i in 2:150){
#  set.seed(333)
#  lda.sum.group.prin = lda(x=prin.com.sum.mod$scores[,1:i],grouping=inde.vars[,1], CV=T)
#  lda.sum.group = mean(lda.sum.group.prin$class == inde.vars[,1])
#  group.acc = c(group.acc, lda.sum.group)
#  print(i)
#}

#subject.acc = double()
#for(i in 2:150){
#  set.seed(333)
#  lda.sum.sub.prin = lda(x=prin.com.sum.mod$scores[,1:i], grouping=inde.vars[,2], CV=T)
#  lda.sum.sub = mean(lda.sum.sub.prin$class == inde.vars[,2])
#  subject.acc = c(subject.acc, lda.sum.sub)
#  print(i)
#}

#cond.acc = double()
#for(i in 2:150){
#  set.seed(333)
#  lda.sum.cond.prin = lda(x=prin.com.sum.mod$scores[,1:i], grouping=inde.vars[,3], CV=T)
#  lda.sum.cond = mean(lda.sum.cond.prin$class == inde.vars[,3])
#  cond.acc = c(cond.acc, lda.sum.cond)
#  print(i)
#}

#joint.acc = double()
#for(i in 2:150){
#  set.seed(333)
#  lda.sum.joint.prin = lda(x=prin.com.sum.mod$scores[,1:i], grouping=classes.joint, CV=T)
#  lda.sum.joint = mean(lda.sum.joint.prin$class == classes.joint)
#  joint.acc = c(joint.acc, lda.sum.joint)
#  print(i)
#}

#One loop to run all of the lda models for all of the different principal components with cv
#in order to find the optimal number of pcs for the highest accuracy
group.acc = double()
subject.acc = double()
cond.acc = double()
joint.acc = double()
all.accs = double()
#for(i in 2:150){
all.accs = foreach(i = 2:150, .combine = rbind) %dopar%{
  set.seed(333)
  lda.sum.group.prin = MASS::lda(x=prin.com.sum.mod$scores[,1:i],grouping=inde.vars[,1], CV=T)
  lda.sum.group = mean(lda.sum.group.prin$class == inde.vars[,1])
  #group.acc = c(group.acc, lda.sum.group)
  
  set.seed(333)
  lda.sum.sub.prin = MASS::lda(x=prin.com.sum.mod$scores[,1:i], grouping=inde.vars[,2], CV=T)
  lda.sum.sub = mean(lda.sum.sub.prin$class == inde.vars[,2])
  #subject.acc = c(subject.acc, lda.sum.sub)
  
  set.seed(333)
  lda.sum.cond.prin = MASS::lda(x=prin.com.sum.mod$scores[,1:i], grouping=inde.vars[,3], CV=T)
  lda.sum.cond = mean(lda.sum.cond.prin$class == inde.vars[,3])
  #cond.acc = c(cond.acc, lda.sum.cond)
  
  set.seed(333)
  lda.sum.joint.prin = MASS::lda(x=prin.com.sum.mod$scores[,1:i], grouping=classes.joint, CV=T)
  lda.sum.joint = mean(lda.sum.joint.prin$class == classes.joint)
  #joint.acc = c(joint.acc, lda.sum.joint)
  
  c(lda.sum.group, lda.sum.sub, lda.sum.cond, lda.sum.joint)
  #print(i)
}

#the accuracy of the different response vairables 
#which.max(group.acc)
all.accs[,1][which.max(all.accs[,1])]
#which.max(subject.acc1)
all.accs[,2][which.max(all.accs[,2])]
#which.max(cond.acc1)
all.accs[,3][which.max(all.accs[,3])]
#which.max(joint.acc1)
all.accs[,4][which.max(all.accs[,4])]

#plot(2:150, group.acc, ylim = c(0,1))
#plot(2:150, subject.acc, ylim = c(0,1))
#plot(2:150, cond.acc, ylim = c(0,1))
#plot(2:150, all.accs[,4], ylim = c(0,1))














########################################################################################################################################################################################################################################

set.seed(333)
trn.dat.summarys=NULL
inde.vars=NULL

index.var=apply(lab.dat[,1:4], 1, paste, collapse=":")
group.subject = apply(lab.dat[,1:2], 1, paste, collapse=":")

uni.vars = unique(index.var)
ind.gro.sub = unique(group.subject)

#using the MatrixStats package to 
for(i in uni.vars){
  temp = double()
  trn.dat.i=lab.dat[i==index.var, ]
  trn.mean.i=colMeans(trn.dat.i[,-(1:5)])
  trn.median.i = colMedians(as.matrix(trn.dat.i[,-(1:5)]))
  trn.var.i = colVars(as.matrix(trn.dat.i[,-(1:5)]))
  trn.sd.i = colSds(as.matrix(trn.dat.i[,-(1:5)]))
  trn.iqr.i = colIQRs(as.matrix(trn.dat.i[,-(1:5)]))
  trn.range.i = colRanges(as.matrix(trn.dat.i[,-(1:5)]))
  trn.mins.i = colMins(as.matrix(trn.dat.i[,-(1:5)]))
  trn.max.i = colMaxs(as.matrix(trn.dat.i[,-(1:5)]))
  trn.skewness.i = apply(as.matrix(trn.dat.i[,-(1:5)]), 2, skewness, na.rm=TRUE)
  trn.kurtosis.i = apply(as.matrix(trn.dat.i[,-(1:5)]), 2, kurtosis, na.rm=TRUE)
  trn.mad.i = colMads(as.matrix(trn.dat.i[,-(1:5)]))
  inde.vars=rbind(inde.vars, trn.dat.i[1,(1:4)])
  for(j in 1:length(trn.mean.i)){
    temp = c(temp, trn.mean.i[j], trn.median.i[j], trn.var.i[j], trn.sd.i[j], trn.iqr.i[j], trn.range.i[j], trn.mins.i[j], trn.max.i[j], trn.skewness.i[j], trn.kurtosis.i[j], trn.mad.i[j])
  }
  temp = c(temp, nrow(as.matrix(trn.dat.i[,-(1:5)])))
  trn.dat.summarys=rbind(trn.dat.summarys, temp)
}

#setting up test variables to be used for predictions
tst.dat.means = NULL
test.inde.vars = NULL
test.index.var = unlab.dat$Trial
test.indexes = unique(test.index.var)
for(i in test.indexes){
  tst.dat.i = unlab.dat[i==test.index.var, ]
  tst.mean.i = colMeans(tst.dat.i[,-(1:2)])
  test.inde.vars = rbind(test.inde.vars, tst.dat.i[1,1])
  tst.dat.means=rbind(tst.dat.means, tst.mean.i)
}

#remove the columns that have zero variance (constant)
trn.dat.summarys.1 = as.data.frame(trn.dat.summarys[,apply(trn.dat.summarys, 2, var, na.rm=TRUE) != 0])
trn.dat.summarys.1 = trn.dat.summarys.1[,is.finite(colSums(trn.dat.summarys.1))]
dim(trn.dat.summarys)-dim(trn.dat.summarys.1)
#removing those columns leaves us with 22 less

#PCA on new data
set.seed(333)
prin.com.sum.mod = princomp(trn.dat.summarys.1, cor=T)
plot(prin.com.sum.mod)

group.acc1 = double()
system.time({
for(i in 2:213){
  set.seed(333)
  lda.sum.group.prin = lda(x=prin.com.sum.mod$scores[,1:i],grouping=inde.vars[,1], CV=T)
  lda.sum.group = mean(lda.sum.group.prin$class == inde.vars[,1])
  group.acc1 = c(group.acc1, lda.sum.group)
  #print(i)
}
})

group.acc1 = double()
system.time({
group.acc1 = foreach(i=2:213, .combine=c) %dopar% {
  set.seed(333)
  lda.sum.group.prin = MASS::lda(x=prin.com.sum.mod$scores[,1:i],grouping=inde.vars[,1], CV=T)
  mean(lda.sum.group.prin$class == inde.vars[,1])
}
})

#subject.acc1 = double()
#for(i in 2:213){
#  set.seed(333)
#  lda.sum.sub.prin = lda(x=prin.com.sum.mod$scores[,1:i], grouping=inde.vars[,2], CV=T)
#  lda.sum.sub = mean(lda.sum.sub.prin$class == inde.vars[,2])
#  subject.acc1 = c(subject.acc1, lda.sum.sub)
#  print(i)
#}

#cond.acc1 = double()
#for(i in 2:213){
#  set.seed(333)
# lda.sum.cond.prin = lda(x=prin.com.sum.mod$scores[,1:i], grouping=inde.vars[,3], CV=T)
# lda.sum.cond = mean(lda.sum.cond.prin$class == inde.vars[,3])
#  cond.acc1 = c(cond.acc1, lda.sum.cond)
#  print(i)
#}

#joint.acc1 = double()
#classes.joint = apply(inde.vars[,1:3], 1, paste, collapse = ":")
#for(i in 2:213){
#  set.seed(333)
#  lda.sum.joint.prin = lda(x=prin.com.sum.mod$scores[,1:i], grouping=classes.joint, CV=T)
#  lda.sum.joint = mean(lda.sum.joint.prin$class == classes.joint)
#  joint.acc1 = c(joint.acc1, lda.sum.joint)
#  print(i)
#}

group.acc1 = double()
subject.acc1 = double()
cond.acc1 = double()
joint.acc1 = double()
all.accs1 = double()
system.time({
#for(i in 2:213){
all.accs1 = foreach(i=2:213, .combine = rbind) %dopar%{
  #set.seed(333)
  #lda.sum.group.prin = MASS::lda(x=prin.com.sum.mod$scores[,1:i],grouping=inde.vars[,1], CV=T)
  #lda.sum.group = mean(lda.sum.group.prin$class == inde.vars[,1])
  
  #set.seed(333)
  #lda.sum.sub.prin = MASS::lda(x=prin.com.sum.mod$scores[,1:i], grouping=inde.vars[,2], CV=T)
  #lda.sum.sub = mean(lda.sum.sub.prin$class == inde.vars[,2])
  
  #set.seed(333)
  #lda.sum.cond.prin = MASS::lda(x=prin.com.sum.mod$scores[,1:i], grouping=inde.vars[,3], CV=T)
  #lda.sum.cond = mean(lda.sum.cond.prin$class == inde.vars[,3])
  
  set.seed(333)
  lda.sum.joint.prin = MASS::lda(x=prin.com.sum.mod$scores[,1:i], grouping=classes.joint, CV=T)
  lda.sum.joint = mean(lda.sum.joint.prin$class == classes.joint)
  
  #c(lda.sum.group, lda.sum.sub, lda.sum.cond, lda.sum.joint)
  c(0, 0, 0, lda.sum.joint)
  #group.acc1 = c(group.acc1, lda.sum.group); subject.acc1 = c(subject.acc1, lda.sum.sub); cond.acc1 = c(cond.acc1, lda.sum.cond); joint.acc1 = c(joint.acc1, lda.sum.joint)#; print(i)
}
})

#which.max(group.acc1)
all.accs1[,1][which.max(all.accs1[,1])]
#which.max(subject.acc1)
all.accs1[,2][which.max(all.accs1[,2])]
#which.max(cond.acc1)
all.accs1[,3][which.max(all.accs1[,3])]
#which.max(joint.acc1)
all.accs1[,4][which.max(all.accs1[,4])]

plot(2:213, all.accs1[,1], ylim = c(0,1))
plot(2:213, all.accs1[,2], ylim = c(0,1))
plot(2:213, all.accs1[,3], ylim = c(0,1))
plot(2:213, all.accs1[,4], ylim = c(0,1))



















































