# =========================================================
# 03_portfolio_figures.R
# Portfolio figures for GitHub / recruitment
# All visible text in figures is in English.
# Run this script from the repository root.
# =========================================================

library(dplyr)
library(ggplot2)
library(plm)
library(lmtest)
library(sandwich)

# Create output folder
dir.create(
  "portfolio_figures",
  showWarnings = FALSE,
  recursive = TRUE
)

# =========================================================
# REQUIRED INPUT FILES
# =========================================================

required_files <- c(
  "data/panel_fe_final.csv",
  "data/panel_reconstruit_final.csv",
  "results/importanta_random_forest_final.csv",
  "results/pdp_nefolosire_internet_final.csv",
  "results/predictii_random_forest_final.csv"
)

missing_files <- required_files[!file.exists(required_files)]

if (length(missing_files) > 0) {
  stop(
    paste0(
      "Missing required file(s):\n",
      paste(missing_files, collapse = "\n"),
      "\n\nRun the script from the repository root and verify the repository structure."
    )
  )
}

# =========================================================
# LOAD DATA
# =========================================================

panel_fe <- read.csv(
  "data/panel_fe_final.csv",
  stringsAsFactors = FALSE
)

panel_trends <- read.csv(
  "data/panel_reconstruit_final.csv",
  stringsAsFactors = FALSE
)

rf_importance <- read.csv(
  "results/importanta_random_forest_final.csv",
  stringsAsFactors = FALSE
)

rf_pdp <- read.csv(
  "results/pdp_nefolosire_internet_final.csv",
  stringsAsFactors = FALSE
)

rf_predictions <- read.csv(
  "results/predictii_random_forest_final.csv",
  stringsAsFactors = FALSE
)

# =========================================================
# 1. RANDOM FOREST VARIABLE IMPORTANCE
# =========================================================

rf_importance_en <- rf_importance %>%
  mutate(
    Variable = case_when(
      Variabila == "nefolosire_internet" ~ "Internet non-use",
      Variabila == "nivel_acces_internet" ~ "Household internet access",
      Variabila == "participare_social_media" ~ "Social media participation",
      Variabila == "venit_mediu_gospodarie" ~ "Household income",
      Variabila == "abilitati_digitale" ~ "Digital skills",
      Variabila == "educatie_superioara" ~ "Tertiary education",
      Variabila == "gini" ~ "Gini coefficient",
      TRUE ~ Variabila
    )
  )

g_importance_en <- ggplot(
  rf_importance_en,
  aes(
    x = reorder(Variable, IncMSE),
    y = IncMSE
  )
) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Random Forest Variable Importance",
    subtitle = "Permutation importance based on increase in mean squared error",
    x = NULL,
    y = "Permutation importance (%IncMSE)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold")
  )

ggsave(
  "portfolio_figures/random_forest_variable_importance.png",
  plot = g_importance_en,
  width = 9,
  height = 6,
  dpi = 300
)

# =========================================================
# 2. PARTIAL DEPENDENCE PLOT
# =========================================================

g_pdp_en <- ggplot(
  rf_pdp,
  aes(
    x = nefolosire_internet,
    y = yhat
  )
) +
  geom_line(linewidth = 1) +
  labs(
    title = "Partial Dependence of Internet Non-Use",
    subtitle = "Random Forest predictions for daily internet use",
    x = "Individuals who have never used the internet (%)",
    y = "Predicted daily internet use (%)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold")
  )

ggsave(
  "portfolio_figures/partial_dependence_internet_nonuse.png",
  plot = g_pdp_en,
  width = 9,
  height = 6,
  dpi = 300
)

# =========================================================
# 3. OBSERVED VS PREDICTED
# =========================================================

g_observed_predicted_en <- ggplot(
  rf_predictions,
  aes(
    x = Observat,
    y = Prezis
  )
) +
  geom_point(size = 2.5, alpha = 0.75) +
  geom_abline(
    intercept = 0,
    slope = 1,
    linetype = "dashed",
    linewidth = 0.8
  ) +
  labs(
    title = "Observed vs Predicted Daily Internet Use",
    subtitle = "Random Forest held-out test sample (n = 24)",
    x = "Observed daily internet use (%)",
    y = "Predicted daily internet use (%)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold")
  )

ggsave(
  "portfolio_figures/random_forest_observed_vs_predicted.png",
  plot = g_observed_predicted_en,
  width = 8,
  height = 6,
  dpi = 300
)

# =========================================================
# 4. FIXED EFFECTS COEFFICIENT PLOT
# =========================================================
# Predictors are rescaled only for presentation:
# - percentage variables: +10 percentage points
# - household income: +$10,000 PPP
# - Gini coefficient: +0.1
#
# Dependent variables remain expressed in percentage points.
# =========================================================

panel_fe_plot <- panel_fe %>%
  mutate(
    daily_internet_10 = daily_internet_use / 10,
    income_10k = venit_mediu_gospodarie / 10000,
    gini_01 = gini / 0.1,
    education_10 = educatie_superioara / 10,
    digital_skills_10 = abilitati_digitale / 10,
    internet_access_10 = nivel_acces_internet / 10,
    internet_nonuse_10 = nefolosire_internet / 10
  )

panel_fe_plot <- pdata.frame(
  panel_fe_plot,
  index = c("country", "year")
)

# Social media participation model
fe_social_plot <- plm(
  participare_social_media ~
    daily_internet_10 +
    income_10k +
    gini_01 +
    education_10 +
    digital_skills_10 +
    internet_access_10 +
    internet_nonuse_10,
  data = panel_fe_plot,
  model = "within",
  effect = "individual"
)

# Daily internet use model
fe_daily_plot <- plm(
  daily_internet_use ~
    income_10k +
    gini_01 +
    education_10 +
    digital_skills_10 +
    internet_access_10 +
    internet_nonuse_10,
  data = panel_fe_plot,
  model = "within",
  effect = "individual"
)

# Robust standard errors clustered by country
rob_social_plot <- coeftest(
  fe_social_plot,
  vcov = vcovHC(
    fe_social_plot,
    type = "HC1",
    cluster = "group"
  )
)

rob_daily_plot <- coeftest(
  fe_daily_plot,
  vcov = vcovHC(
    fe_daily_plot,
    type = "HC1",
    cluster = "group"
  )
)

prepare_coefficients <- function(robust_results, model_name) {
  data.frame(
    term = rownames(robust_results),
    estimate = robust_results[, "Estimate"],
    std_error = robust_results[, "Std. Error"],
    row.names = NULL
  ) %>%
    mutate(
      conf_low = estimate - 1.96 * std_error,
      conf_high = estimate + 1.96 * std_error,
      Model = model_name
    )
}

coef_social <- prepare_coefficients(
  rob_social_plot,
  "Social media participation"
)

coef_daily <- prepare_coefficients(
  rob_daily_plot,
  "Daily internet use"
)

coef_plot_data <- bind_rows(
  coef_social,
  coef_daily
) %>%
  mutate(
    Variable = case_when(
      term == "daily_internet_10" ~ "Daily internet use (+10 pp)",
      term == "income_10k" ~ "Household income (+$10k PPP)",
      term == "gini_01" ~ "Gini coefficient (+0.1)",
      term == "education_10" ~ "Tertiary education (+10 pp)",
      term == "digital_skills_10" ~ "Digital skills (+10 pp)",
      term == "internet_access_10" ~ "Household internet access (+10 pp)",
      term == "internet_nonuse_10" ~ "Internet non-use (+10 pp)",
      TRUE ~ term
    )
  )

g_fe_en <- ggplot(
  coef_plot_data,
  aes(
    x = estimate,
    y = reorder(Variable, estimate)
  )
) +
  geom_vline(
    xintercept = 0,
    linetype = "dashed"
  ) +
  geom_errorbar(
    aes(
      xmin = conf_low,
      xmax = conf_high
    ),
    width = 0.15
  ) +
  geom_point(size = 2.8) +
  facet_wrap(
    ~ Model,
    scales = "free_y",
    ncol = 1
  ) +
  labs(
    title = "Fixed Effects Estimates",
    subtitle = "Country fixed effects with robust standard errors clustered by country",
    x = "Estimated change in the dependent variable (percentage points)",
    y = NULL,
    caption = "Points show coefficient estimates; lines show 95% confidence intervals."
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold")
  )

ggsave(
  "portfolio_figures/fixed_effects_coefficients.png",
  plot = g_fe_en,
  width = 10,
  height = 8,
  dpi = 300
)

# =========================================================
# 5. DIGITAL USE TRENDS BEFORE AND DURING THE COVID-19 PERIOD
# =========================================================
# This descriptive figure uses annual data for daily internet
# use and social media participation from 2017 to 2022.
#
# A balanced set of countries is used so that changes over
# time are not driven by changes in country composition.
# =========================================================

trend_balanced <- panel_trends %>%
  filter(year %in% 2017:2022) %>%
  select(
    country,
    year,
    daily_internet_use,
    participare_social_media
  ) %>%
  filter(
    !is.na(daily_internet_use),
    !is.na(participare_social_media)
  ) %>%
  group_by(country) %>%
  filter(n_distinct(year) == 6) %>%
  ungroup()

trend_long <- trend_balanced %>%
  tidyr::pivot_longer(
    cols = c(
      daily_internet_use,
      participare_social_media
    ),
    names_to = "indicator",
    values_to = "value"
  ) %>%
  mutate(
    Indicator = case_when(
      indicator == "daily_internet_use" ~ "Daily internet use",
      indicator == "participare_social_media" ~ "Social media participation"
    )
  )

trend_summary <- trend_long %>%
  group_by(year, Indicator) %>%
  summarise(
    n = sum(!is.na(value)),
    mean = mean(value, na.rm = TRUE),
    sd = sd(value, na.rm = TRUE),
    se = sd / sqrt(n),
    ci_low = mean - 1.96 * se,
    ci_high = mean + 1.96 * se,
    .groups = "drop"
  )

n_countries_trend <- n_distinct(trend_balanced$country)

g_pandemic_en <- ggplot(
  trend_summary,
  aes(
    x = year,
    y = mean,
    group = Indicator
  )
) +
  geom_ribbon(
    aes(
      ymin = ci_low,
      ymax = ci_high
    ),
    alpha = 0.15
  ) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.5) +
  geom_vline(
    xintercept = 2020,
    linetype = "dashed"
  ) +
  facet_wrap(
    ~ Indicator,
    ncol = 1,
    scales = "free_y"
  ) +
  scale_x_continuous(
    breaks = 2017:2022
  ) +
  labs(
    title = "Digital Use Trends Before and During the COVID-19 Period",
    subtitle = paste0(
      "Annual country means, 2017–2022 | Balanced sample: ",
      n_countries_trend,
      " countries | Dashed line marks 2020"
    ),
    x = "Year",
    y = "Mean share of individuals (%)",
    caption = "Descriptive trends based on Eurostat indicators. Shaded areas show 95% confidence intervals."
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold")
  )

ggsave(
  "portfolio_figures/pandemic_digital_trends_2017_2022.png",
  plot = g_pandemic_en,
  width = 10,
  height = 7,
  dpi = 300
)

# =========================================================
# FINAL OUTPUT CHECK
# =========================================================

expected_outputs <- c(
  "portfolio_figures/random_forest_variable_importance.png",
  "portfolio_figures/partial_dependence_internet_nonuse.png",
  "portfolio_figures/random_forest_observed_vs_predicted.png",
  "portfolio_figures/fixed_effects_coefficients.png",
  "portfolio_figures/pandemic_digital_trends_2017_2022.png"
)

output_check <- data.frame(
  file = expected_outputs,
  exists = file.exists(expected_outputs)
)

print(output_check)

if (!all(output_check$exists)) {
  stop("One or more portfolio figures were not generated successfully.")
}

message("All portfolio figures were generated successfully.")




