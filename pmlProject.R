##
##
##
library(caret); library(dplyr)
file <- "pml-training.csv"
rawActitivity <- read.csv(file)
varsDf <- getFractionMissing()
# get column/var names with > 80% of values not empty or NA
varsWithData <- filter(varsDf, FractionMissing < 0.20)$columnName
# varsWithLittleData <- filter(varsDf, FractionMissing > 0.90)$columnName
# http://stackoverflow.com/questions/10086494#10086494
trimmedActivity <- subset(rawActitivity, select=varsWithData)
# This eliminated 100 out of the 160 vars. Turns out that these same
# 100 var's aren't populated at all in test set which makes it a
# no-brainer to pitch them.
offset = 6; classDesignatorCol <- ncol(trimmedActivity) # last col is class
# convert new_window from factor to int
trimmedActivity$new_window <- as.integer(trimmedActivity$new_window)
correlationMatrix <- cor(trimmedActivity[, (offset+1):classDesignatorCol-1])
print(correlationMatrix)
# find attributes that are highly corrected (ideally > 0.75)
highlyCorrelated <- sort(findCorrelation(correlationMatrix, cutoff=0.75))
highlyCorrelated <- highlyCorrelated + offset # get cols relative to trimmed df
trimmedActivity2 <- trimmedActivity[,-highlyCorrelated] # remove highly cor vars
trimmedActivity2 <- trimmedActivity2[,-1] # 1st col is just an index
trimmedActivity3 <- trimmedActivity2[,-4:-2] # remove time stamp info
# remove user_name and new_window after looking at importance plot (see below)
trimmedActivity3 <- trimmedActivity3[,-1] # remove user_name
trimmedActivity3 <- trimmedActivity3[,-1] # remove new_window

# 1) Start with something simple: LDA, split data but no CV
set.seed(1447)
inTrain <- createDataPartition(trimmedActivity3$classe, p=0.60, list=FALSE)
training <- trimmedActivity3[inTrain,]
testing <- trimmedActivity3[-inTrain,]
startTime <- Sys.time()
cat(format(startTime, "%T"), "building LDA model started...\n")
mod01.lda <- train(classe ~ ., method='lda', data=training) # about 6 sec's
endTime <- Sys.time()
cat(format(endTime, "%T"), "building LDA model FINISHED!\n")
cat(endTime - startTime)
# calc in-sample error
pred01.lda <- predict(mod01.lda, newdata = testing)
acc01.lda <- sum(pred01.lda == testing$classe) / length(testing$classe) # in-sample accuracy rather poor: 64%
test.cases <- read.csv("pml-testing.csv")
pred01.lda.test.cases <- predict(mod01.lda, newdata = test.cases)
# > pred01.lda.test.cases
# [1] B A A A C C D D A A D A B A E B A B A B

# 2) Try a classification tree, still no CV
cat(format(Sys.time(), "%T"), "building CART model started...\n")
mod02.cart <- train(classe ~ ., method='rpart', data=training) # about 9 sec's
cat(format(Sys.time(), "%T"), "building CART model FINISHED!\n")
# calc in-sample error
pred02.cart <- predict(mod02.cart, newdata = testing)
acc02.cart <- sum(pred02.cart == testing$classe) / length(testing$classe)

# in-sample accuracy worse than LDA: 55%
pred02.cart.test.cases <- predict(mod02.cart, newdata = test.cases)

# 3) Try a random forrest classifier, still no CV
cat(format(Sys.time(), "%T"), "building RF model started...\n")
mod03.rf <- train(classe ~ ., method='rf', prox=TRUE, data=training)
# above line took ~190 min's on my Xeon 16Gb workstation to complete
# and gave an in-sample error of < 0.3% so it probably overfitted like crazy...
cat(format(Sys.time(), "%T"), "building RF model FINISHED!\n")
# calc in-sample error
pred03.rf <- predict(mod03.rf, newdata = testing)
acc03.rf <- sum(pred03.rf == testing$classe) / length(testing$classe) # 

# read the test cases and predict them
test.cases <- read.csv("pml-testing.csv")
pred03.rf.test.cases <- predict(mod03.rf, newdata = test.cases)
# > pred03.rf.test.cases
# [1] B A B A A E D B A A B C B A E E A B B B

# 4) Try a gbm classifier,
cat(format(Sys.time(), "%T"), "building GBM model started...\n")
# use 5 repeats of 5-fold cross-validation
ctrl <- trainControl(method = "repeatedcv", repeats = 5, number = 5)
mod04.gbm <- train(classe ~ ., data=training,
                   method='gbm',
                   verbose=FALSE,
                   trControl = ctrl) # ~x min's
cat(format(Sys.time(), "%T"), "building GBM model FINISHED!\n")
# calc in-sample error
pred04.gbm <- predict(mod04.gbm, newdata = testing)
acc04.gbm <- sum(pred04.gbm == testing$classe) / length(testing$classe)
pred04.gbm.test.cases <- predict(mod03.rf, newdata = test.cases)
# > pred04.gbm.test.cases
# [1] B A B A A E D B A A B C B A E E A B B B
# [1] B A B A A E D B A A B C B A E E A B B B

pred1 <- predict(mod01.lda, training)
pred2 <- predict(mod03.rf, training)
pred3 <- predict(mod04.gbm, training)
# create new df with predictions from each model
pred.combined.data <- data.frame(lda=pred1, rf=pred2, gbm=pred3,
                                 classe=training$classe)
combined.model <- train(classe ~ ., method="rf", data=pred.combined.data)

pred1.test <- predict(mod01.lda, testing)
pred2.test <- predict(mod03.rf, testing)
pred3.test <- predict(mod04.gbm, testing)

combined.test <- data.frame(lda=pred1.test, rf=pred2.test, gbm=pred3.test,
                            classe=testing$classe)

pred.combined <- predict(combined.model, combined.test)

accuracy.lda <- sum((pred1.test == testing$classe) * 1) /
                length(testing$classe)
accuracy.rf <- sum((pred2.test == testing$classe) * 1) /
               length(testing$classe)
accuracy.gbm <- sum((pred3.test == testing$classe) * 1) /
                length(testing$classe)
accuracy.combined <- sum((pred.combined == testing$classe) * 1) /
    length(testing$classe)

# another way to estimate variable importance
importance <- varImp(mod04.gbm, scale=FALSE)
print(importance)
plot(importance)

## Estimate out-of-sample error
itr <- vector(mode = "integer")
build_time <- vector(mode = "numeric")
is_correct <- vector(mode = "integer")
is_incorrect <- vector(mode = "integer")
is_error <- vector(mode = "numeric")
os_correct <- vector(mode = "integer")
os_incorrect <- vector(mode = "integer")
os_error <- vector(mode = "numeric")

#install.packages("doParallel")
# library(foreach); library(doParallel);
# cl <- makeCluster(2, type='PSOCK')
# registerDoParallel(cl)
set.seed(149)
for(i in 1:100) {
    #model <- "LDA"
    #model <- "RPART"
    model <- "GBM"
    inTrain <- createDataPartition(trimmedActivity3$classe, p=0.60, list=FALSE)
    training <- trimmedActivity3[inTrain,]
    testing <- trimmedActivity3[-inTrain,]
    itr <- c(itr, i)
    startTime <- Sys.time()
    cat("itr:",i, ">>>", model, "model build started",
        format(startTime, "%T"), "...")
    
    ####### SWAP OUT MODELS HERE #######
    #model.i <- train(classe ~ ., method='lda', data=training)
    #model.i <- train(classe ~ ., method='rpart', data=training)
    ctrl <- trainControl(method = "repeatedcv", repeats = 5, number = 5)
    model.i <- train(classe ~ ., data=training, method='gbm', verbose=FALSE,
                     trControl = ctrl) # use 5 repeats of 5-fold cv
    
    endTime <- Sys.time()
    bt <- endTime - startTime
    cat(", finished", format(endTime, "%T"), ", build time =", bt,"\n")
    build_time <- c(build_time, bt)
    # calc in-sample error
    trainSize <- length(inTrain)
    pred.train <- predict(model.i, newdata = training)
    value <- sum(pred.train == training$classe)
    is_correct <- c(is_correct, value)
    value <- sum(pred.train != training$classe)
    is_incorrect <- c(is_incorrect, value)
    is_error <- c(is_error, round(value/trainSize, 4))
    cat("training set size = ", trainSize, "\n")
    cat("is_correct = ", is_correct[length(is_correct)],
        ", is_incorrect = ", is_incorrect[length(is_incorrect)],
        ", is_error = ", is_error[length(is_error)])
    cat("\n-------\n")
    # calc out-of-sample error
    testSize <- length(testing$classe)
    pred.test <- predict(model.i, newdata = testing)
    value <- sum(pred.test == testing$classe)
    os_correct <- c(os_correct, value)
    value <- sum(pred.test != testing$classe)
    os_incorrect <- c(os_incorrect, value)
    os_error <- c(os_error, round(value/testSize, 4))
    cat("testing set size = ", testSize, "\n")
    cat("os_correct = ", os_correct[length(os_correct)],
        ", os_incorrect = ", os_incorrect[length(os_incorrect)],
        ", os_error = ", os_error[length(os_error)])
    cat("\n***************\n")
    if(i %% 5 == 0) {
        cat("i =", i, "writing file...")
        # write out a file every 5 iterations
        results.df <- data.frame(itr, build_time, is_correct,
                                 is_incorrect, is_error,
                                 os_correct, os_incorrect, os_error)
        write.csv(results.df, paste0("results.", model, "_", i, ".csv"))
    }
}


## Creates a data frame with three columns: index, ColumnName and
## FractionMissing.
## index is the column index in df corresponding to ColumnName
## ColumnName is as the name implies: the name the column in df
## FractionMissing is the fraction of values that are missing or NA.
## The closer this value is to 1, the less data the column contains
getFractionMissing <- function(df = rawActitivity) {
    colCount <- ncol(df)
    returnDf <- data.frame(index=1:ncol(df),
                           columnName=rep("undefined", colCount),
                           FractionMissing=rep(-1, colCount),
                           stringsAsFactors=FALSE)
    for(i in 1:colCount) {
        colVector <- df[,i]
        missingCount <- length(which(colVector == "") * 1)
        missingCount <- missingCount + sum(is.na(colVector) * 1)
        returnDf$columnName[i] <- as.character(names(df)[i])
        returnDf$FractionMissing[i] <- missingCount / length(colVector)
    }
    
    return(returnDf)
}

## Write the files to submit
pml_write_files = function(x){
    n = length(x)
    for(i in 1:n){
        filename = paste0("problem_id_",i,".txt")
        write.table(x[i],file=filename,quote=FALSE,row.names=FALSE,col.names=FALSE)
    }
}