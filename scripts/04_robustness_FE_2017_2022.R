# =========================================================
# 04_robustness_FE_2017_2022.R
# Robustness check: Fixed Effects models using 2017-2022
# Digital skills are excluded because a consistent and
# methodologically comparable annual series is not available
# for the full period.
# =========================================================

library(dplyr)
library(tidyr)
library(plm)
library(lmtest)
library(sandwich)

# =========================================================
# 1. LOAD RECONSTRUCTED PANEL
# =========================================================

panel_all <- read.csv(
  "data/panel_reconstruit_final.csv",
  stringsAsFactors = FALSE
)

# =========================================================
# 2. KEEP FULL 2017-2022 PERIOD
# =========================================================

panel_2017_2022 <- panel_all %>%
  filter(year %in% 2017:2022)

# =========================================================
# 3. BUILD COMPLETE-CASE SAMPLE
# =========================================================
# Digital skills are intentionally excluded.

panel_robust <- panel_2017_2022 %>%
  select(
    country,
    year,
    participare_social_media,
    daily_internet_use,
    venit_mediu_gospodarie,
    gini,
    educatie_superioara,
    nivel_acces_internet,
    nefolosire_internet
  ) %>%
  drop_na()

# =========================================================
# 4. KEEP COUNTRIES WITH AT LEAST 2 OBSERVATIONS
# =========================================================

panel_robust_fe <- panel_robust %>%
  group_by(country) %>%
  filter(n() >= 2) %>%
  ungroup()

# =========================================================
# 5. SAMPLE DIAGNOSTICS
# =========================================================

cat("Complete robustness sample:\n")
cat("Observations:", nrow(panel_robust), "\n")
cat("Countries:", n_distinct(panel_robust$country), "\n\n")

cat("Final FE robustness sample:\n")
cat("Observations:", nrow(panel_robust_fe), "\n")
cat("Countries:", n_distinct(panel_robust_fe$country), "\n\n")

cat("Observations by year:\n")
print(table(panel_robust_fe$year))

cat("\nYears included:\n")
print(sort(unique(panel_robust_fe$year)))

cat("\nNumber of observations per country:\n")
print(table(table(panel_robust_fe$country)))


# =========================================================
# 6. CONVERT TO PANEL-DATA FORMAT
# =========================================================

pdata_robust <- pdata.frame(
  panel_robust_fe,
  index = c("country", "year")
)

# Check panel structure
pdim(pdata_robust)


# =========================================================
# 7. FIXED EFFECTS MODEL:
# SOCIAL MEDIA PARTICIPATION
# =========================================================

fe_social_robust <- plm(
  participare_social_media ~
    daily_internet_use +
    venit_mediu_gospodarie +
    gini +
    educatie_superioara +
    nivel_acces_internet +
    nefolosire_internet,
  data = pdata_robust,
  model = "within",
  effect = "individual"
)

summary(fe_social_robust)


# Robust HC1 standard errors clustered by country
vcov_social_robust <- vcovHC(
  fe_social_robust,
  method = "arellano",
  type = "HC1",
  cluster = "group"
)

social_robust_test <- coeftest(
  fe_social_robust,
  vcov = vcov_social_robust
)

cat("\nROBUST FE MODEL: SOCIAL MEDIA PARTICIPATION\n")
print(social_robust_test)


# =========================================================
# 8. FIXED EFFECTS MODEL:
# DAILY INTERNET USE
# =========================================================

fe_daily_robust <- plm(
  daily_internet_use ~
    venit_mediu_gospodarie +
    gini +
    educatie_superioara +
    nivel_acces_internet +
    nefolosire_internet,
  data = pdata_robust,
  model = "within",
  effect = "individual"
)

summary(fe_daily_robust)


# Robust HC1 standard errors clustered by country
vcov_daily_robust <- vcovHC(
  fe_daily_robust,
  method = "arellano",
  type = "HC1",
  cluster = "group"
)

daily_robust_test <- coeftest(
  fe_daily_robust,
  vcov = vcov_daily_robust
)

cat("\nROBUST FE MODEL: DAILY INTERNET USE\n")
print(daily_robust_test)


# =========================================================
# 9. RANDOM EFFECTS MODELS FOR HAUSMAN TEST
# =========================================================

re_social_robust <- plm(
  participare_social_media ~
    daily_internet_use +
    venit_mediu_gospodarie +
    gini +
    educatie_superioara +
    nivel_acces_internet +
    nefolosire_internet,
  data = pdata_robust,
  model = "random",
  effect = "individual"
)

re_daily_robust <- plm(
  daily_internet_use ~
    venit_mediu_gospodarie +
    gini +
    educatie_superioara +
    nivel_acces_internet +
    nefolosire_internet,
  data = pdata_robust,
  model = "random",
  effect = "individual"
)


# =========================================================
# 10. HAUSMAN TESTS
# =========================================================

hausman_social_robust <- phtest(
  fe_social_robust,
  re_social_robust
)

hausman_daily_robust <- phtest(
  fe_daily_robust,
  re_daily_robust
)

cat("\nHAUSMAN TEST: SOCIAL MEDIA PARTICIPATION\n")
print(hausman_social_robust)

cat("\nHAUSMAN TEST: DAILY INTERNET USE\n")
print(hausman_daily_robust)


# =========================================================
# 11. MODEL FIT
# =========================================================

cat("\nMODEL FIT: SOCIAL MEDIA\n")
print(summary(fe_social_robust)$r.squared)

cat("\nMODEL FIT: DAILY INTERNET USE\n")
print(summary(fe_daily_robust)$r.squared)


# =========================================================
# 12. SAVE ROBUSTNESS FE RESULTS
# =========================================================

social_results <- data.frame(
  variable = rownames(social_robust_test),
  estimate = social_robust_test[, "Estimate"],
  std_error = social_robust_test[, "Std. Error"],
  t_value = social_robust_test[, "t value"],
  p_value = social_robust_test[, "Pr(>|t|)"],
  row.names = NULL
)

daily_results <- data.frame(
  variable = rownames(daily_robust_test),
  estimate = daily_robust_test[, "Estimate"],
  std_error = daily_robust_test[, "Std. Error"],
  t_value = daily_robust_test[, "t value"],
  p_value = daily_robust_test[, "Pr(>|t|)"],
  row.names = NULL
)

fit_results <- data.frame(
  model = c("Social media participation", "Daily internet use"),
  N = c(nobs(fe_social_robust), nobs(fe_daily_robust)),
  countries = c(
    n_distinct(panel_robust_fe$country),
    n_distinct(panel_robust_fe$country)
  ),
  within_R2 = c(
    summary(fe_social_robust)$r.squared["rsq"],
    summary(fe_daily_robust)$r.squared["rsq"]
  ),
  adjusted_R2 = c(
    summary(fe_social_robust)$r.squared["adjrsq"],
    summary(fe_daily_robust)$r.squared["adjrsq"]
  ),
  hausman_chisq = c(
    as.numeric(hausman_social_robust$statistic),
    as.numeric(hausman_daily_robust$statistic)
  ),
  hausman_p = c(
    hausman_social_robust$p.value,
    hausman_daily_robust$p.value
  )
)

write.csv(
  social_results,
  "results/robustness_fe_social_2017_2022.csv",
  row.names = FALSE
)

write.csv(
  daily_results,
  "results/robustness_fe_daily_2017_2022.csv",
  row.names = FALSE
)

write.csv(
  fit_results,
  "results/robustness_fe_model_fit_2017_2022.csv",
  row.names = FALSE
)

cat("\nRobustness FE results saved successfully.\n")
