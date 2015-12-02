# Quality of Activity Classifier
Michael Szczepaniak  
November 2015  

## Background

People that are into tracking their personal data with a Jawbone Up, Nike FuelBand, Fitbit or whatever activity tracker they use regularly quantify how much of a particular activity they do.  However, they rarely quantify the quality of how they conduct these activities. In this project, the goal was to use data from accelerometers on the belt, forearm, arm, and dumbell of 6 participants. They were asked to perform barbell lifts correctly and incorrectly in 5 different ways. More information is available from the website here: <a src=http://groupware.les.inf.puc-rio.br/har>http://groupware.les.inf.puc-rio.br/har</a> (see the section on the Weight Lifting Exercise Dataset).

## Synopsis

A Random Forrest (RF) model with 31 predictors was selected for use to predict 20 final validation test cases. While the RF model accurately predicted all 20 test cases, a Boosted Tree model (GBM) was able to predict 90% of the validation cases correctly. Two other model types were evaluated as part of the investigation: Linear Discriminant Analysis (LDA) and Recursive Partitioning and Regression Tree (RPART). The LDA and RPART models were eliminated due to high in-sample error rates (44.5% and 56.3% respectively). The RF model had a better in-sample error rate compared to GBM (0% vs. 6% for GBM), but the RF model took over 178 minutes to train using default caret setting while the GBM only took about 10 minutes using 5 repeats of 5-fold cross-validation. The out-of-sample error rates estimated from the testing hold-outs for the GBM and RF models were 8% and 1.6% respectively.

## Files

<ul>
  <li>README.md - This is the file that you are reading now.</li>
  <li>pml-training.csv - This file was used to train the classifiers being investigated and was generously provide by the folks at <a href=http://groupware.les.inf.puc-rio.br/har>groupware</a>.</li>
  <li>pml-testing.csv - This file was used for determining out-of-sample (OOS) error for the investigated models.  This data was also provide by <a href=http://groupware.les.inf.puc-rio.br/har>groupware</a>.</li>
  <li>qualityOfActivity.Rmd - This is the R Mardown which included the write up and the R code that does the classification</li>
  <li>qualityOfActivity.html - This the html that the Rmd version of this file was compiled into.  This is the readable version of the report which is hosted <a href=http://michaelszczepaniak.github.io/QualityOfActivityClassifier/>here</a></li>
  <li>Appendices.Rmd - This is the R Markdown used to build Appendix A and B.</li>
  <li>Appendices.html - This the html that the Rmd version of this file was compiled into.  This file is hosted <a href=http://michaelszczepaniak.github.io/QualityOfActivityClassifier/Appendices.html>here</a>.</li>
  <li>qualityOfActivity_cache - directory holding cached models used during development</li>
  <li>pmlProject.RData - This is the R session data for the last successful model build. It is tracked because of the length of time it took to build the project (especially the gbm and random forest models).</li>
</ul>

## Future Work

Due to the length of time it took to train the gbm and random forest models, parallel processing will be incorporated into this project in the near future.