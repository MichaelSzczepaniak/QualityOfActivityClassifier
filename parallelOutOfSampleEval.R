itr <- vector(mode = "integer")
build_time <- vector(mode = "numeric")
is_correct <- vector(mode = "integer")
is_incorrect <- vector(mode = "integer")
is_error <- vector(mode = "numeric")
os_correct <- vector(mode = "integer")
os_incorrect <- vector(mode = "integer")
os_error <- vector(mode = "numeric")

#install.packages("doParallel")
library(foreach); library(doParallel);
cl <- makeCluster(2, type='PSOCK')
registerDoParallel(cl)
set.seed(149)
for(i in 1:100)
{
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
    if(i %/% 2 == 0) {
        # write out a file every 5 iterations
        results.df <- data.frame(itr, build_time, is_correct,
                                 is_incorrect, is_error,
                                 os_correct, os_incorrect, os_error)
        write.csv(results.df, paste0("results.", model, "_", i, ".csv"))
    }
}