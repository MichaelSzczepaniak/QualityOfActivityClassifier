# Figure one table summarizing results
library(knitr) # has kable function to build RMarkdown tables
activity.sum.table <- data.frame(ModelType=c("LDA", "RPART", "RF", "GBM"),
                                 InSampleError=rep(0, 4))


library(ggplot2)
iterNum <- c(0:3)
variableCount <- c(160, 60, 39, 33)  # var counts after each itr
df.var <- data.frame(itr=iterNum, varCount=variableCount)
pFig2 <- ggplot(df.var, aes(x=itr, y=varCount)) + geom_line()
pFig2 <- pFig2 + ggtitle("Figure 1 - Variable Count vs. Iteration Number")
pFig2 <- pFig2 +labs(x="Iteration #", y="Model Variable count")
pFig2 <- pFig2 + coord_cartesian(xlim=0:3) + scale_x_continuous(breaks=0:3)
pFig2 <- pFig2 + annotate("text", x = 0.5, y = 120, color = "darkgreen", angle = -43,
                          label = "Remove empty & sparsely populated variables")
pFig2 <- pFig2 + annotate("text", x = 1.5, y = 55, color = "darkorange1", angle = -11,
                          label = "Remove highly correlated variables")
pFig2 <- pFig2 + annotate("text", x = 2.5, y = 56, color = "blue", angle = 0,
                          label = "Remove low significance variables and")
pFig2 <- pFig2 + annotate("text", x = 2.5, y = 50, color = "blue", angle = 0,
                          label = "variables that shouldn't be predictors")
pFig2