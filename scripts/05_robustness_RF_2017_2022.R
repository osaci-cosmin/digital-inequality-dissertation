# =========================================================
# 05_robustness_RF_2017_2022.R
# Random Forest robustness check using 2017-2022.
#
# Digital skills are excluded because a consistent and
# methodologically comparable annual series is not available
# for the full 2017-2022 period.
# =========================================================

library(dplyr)
library(tidyr)
library(caret)
library(randomForest)


# =========================================================
# 1. LOAD RECONSTRUCTED PANEL
# =========================================================

panel_all <- read.csv(
  "data/panel_reconstruit_final.csv",
  stringsAsFactors = FALSE
)


# =========================================================
# 2. BUILD COMPLETE 2017-2022 SAMPLE
# =========================================================
# Digital skills are intentionally excluded.
# Country and year are retained here only for diagnostics.

rf_robust_sample <- panel_all %>%
  filter(year %in% 2017:2022) %>%
  select(
    country,
    year,
    daily_internet_use,
    participare_social_media,
    venit_mediu_gospodarie,
    gini,
    educatie_superioara,
    nivel_acces_internet,
    nefolosire_internet
  ) %>%
  drop_na()


# =========================================================
# 3. SAMPLE DIAGNOSTICS
# =========================================================

cat("RANDOM FOREST ROBUSTNESS SAMPLE\n")
cat("Observations:", nrow(rf_robust_sample), "\n")
cat("Countries:", n_distinct(rf_robust_sample$country), "\n\n")

cat("Observations by year:\n")
print(table(rf_robust_sample$year))

cat("\nYears included:\n")
print(sort(unique(rf_robust_sample$year)))


# =========================================================
# 4. PREPARE RANDOM FOREST DATA
# =========================================================
# Country and year are not included as predictors.
#
# The specification follows the main Random Forest model,
# except that digital skills are excluded.

rf_data_robust <- rf_robust_sample %>%
  select(
    daily_internet_use,
    participare_social_media,
    venit_mediu_gospodarie,
    gini,
    educatie_superioara,
    nivel_acces_internet,
    nefolosire_internet
  )


# =========================================================
# 5. TRAIN / TEST SPLIT
# =========================================================

set.seed(123)

train_index <- createDataPartition(
  rf_data_robust$daily_internet_use,
  p = 0.70,
  list = FALSE
)

train_data_robust <- rf_data_robust[train_index, ]
test_data_robust  <- rf_data_robust[-train_index, ]

cat("\nTRAIN / TEST SPLIT\n")
cat("Train observations:", nrow(train_data_robust), "\n")
cat("Test observations:", nrow(test_data_robust), "\n")


# =========================================================
# 6. RANDOM FOREST MODEL
# =========================================================

set.seed(123)

rf_robust <- randomForest(
  daily_internet_use ~ .,
  data = train_data_robust,
  ntree = 500,
  importance = TRUE
)

cat("\nRANDOM FOREST MODEL\n")
print(rf_robust)


# =========================================================
# 7. TEST-SAMPLE PREDICTIONS
# =========================================================

pred_rf_robust <- predict(
  rf_robust,
  newdata = test_data_robust
)

y_test_robust <- test_data_robust$daily_internet_use


# =========================================================
# 8. PERFORMANCE METRICS
# =========================================================

rmse_robust <- sqrt(
  mean((y_test_robust - pred_rf_robust)^2)
)

mae_robust <- mean(
  abs(y_test_robust - pred_rf_robust)
)

# Standard predictive R-squared
r2_predictive_robust <- 1 -
  sum((y_test_robust - pred_rf_robust)^2) /
  sum((y_test_robust - mean(y_test_robust))^2)

# Squared correlation, retained for comparability
# with the original dissertation calculation
r2_cor_robust <- cor(
  y_test_robust,
  pred_rf_robust
)^2

cat("\nROBUSTNESS RANDOM FOREST METRICS\n")
cat("RMSE:", round(rmse_robust, 3), "\n")
cat("MAE:", round(mae_robust, 3), "\n")
cat("Predictive R2:", round(r2_predictive_robust, 3), "\n")
cat("Squared correlation:", round(r2_cor_robust, 3), "\n")


# =========================================================
# 9. OOB PERFORMANCE
# =========================================================

oob_mse_robust <- rf_robust$mse[rf_robust$ntree]
oob_r2_robust  <- rf_robust$rsq[rf_robust$ntree]

cat("\nOUT-OF-BAG PERFORMANCE\n")
cat("OOB MSE:", round(oob_mse_robust, 3), "\n")
cat("OOB R2:", round(oob_r2_robust, 3), "\n")


# =========================================================
# 10. VARIABLE IMPORTANCE
# =========================================================

importance_matrix <- importance(rf_robust)

importance_robust_df <- data.frame(
  variable = rownames(importance_matrix),
  IncMSE = importance_matrix[, "%IncMSE"],
  IncNodePurity = importance_matrix[, "IncNodePurity"],
  row.names = NULL
) %>%
  arrange(desc(IncMSE))

cat("\nVARIABLE IMPORTANCE\n")
print(importance_robust_df)


# =========================================================
# 11. SAVE RESULTS
# =========================================================

metrics_robust_df <- data.frame(
  metric = c(
    "RMSE",
    "MAE",
    "Predictive_R2",
    "Squared_Correlation",
    "OOB_MSE",
    "OOB_R2",
    "Train_N",
    "Test_N",
    "Total_N"
  ),
  value = c(
    rmse_robust,
    mae_robust,
    r2_predictive_robust,
    r2_cor_robust,
    oob_mse_robust,
    oob_r2_robust,
    nrow(train_data_robust),
    nrow(test_data_robust),
    nrow(rf_data_robust)
  )
)

predictions_robust_df <- data.frame(
  observed = y_test_robust,
  predicted = pred_rf_robust
)

write.csv(
  metrics_robust_df,
  "results/robustness_rf_metrics_2017_2022.csv",
  row.names = FALSE
)

write.csv(
  importance_robust_df,
  "results/robustness_rf_importance_2017_2022.csv",
  row.names = FALSE
)

write.csv(
  predictions_robust_df,
  "results/robustness_rf_predictions_2017_2022.csv",
  row.names = FALSE
)

cat("\nRobustness Random Forest results saved successfully.\n")

