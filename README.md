# Digital Inequality: Panel Data and Random Forest Analysis

This repository contains the reconstruction and validation of the empirical analysis developed for my Master's dissertation on digital inequality, internet use, and social media participation across European countries.

The project combines panel-data econometrics using Fixed Effects (FE) models with Random Forest (RF) predictive modeling and descriptive analysis of digital-use trends before and during the COVID-19 period.

The analysis is based on publicly available data from Eurostat and the OECD and focuses on the relationship between digital behavior, socioeconomic conditions, internet access, education, inequality, and digital skills.

---

## Key Findings

- Daily internet use is positively associated with household income and digital skills and strongly negatively associated with internet non-use.
- The main Fixed Effects model for daily internet use explains approximately **94.7% of the within-country variation**.
- The main Fixed Effects model for social media participation explains approximately **76.9% of the within-country variation**.
- The main Random Forest model reaches a predictive R² of approximately **0.917** on the held-out test sample.
- Internet non-use and household internet access are the two most important predictors in the main Random Forest model.
- Digital-use indicators were already increasing before 2020, while the 2020–2022 period continued or intensified this broader trend rather than showing a clearly isolated structural break.
- Full-period robustness checks using 2017–2022 observations support several of the main relationships and preserve strong Random Forest predictive performance.

---

## Research Objective

The project investigates differences in digital participation across European countries and examines how socioeconomic and digital-access factors are associated with:

- daily internet use;
- social media participation.

The analysis also examines the evolution of digital-use indicators before and during the COVID-19 period.

The project combines two complementary analytical approaches:

1. **Fixed Effects panel models**, used to estimate within-country relationships over time;
2. **Random Forest models**, used to explore predictive performance, variable importance, and potential nonlinear relationships.

---

## Data Sources

The dataset was reconstructed using publicly available indicators from **Eurostat** and the **OECD Income Distribution Database (IDD)**.

### Eurostat Indicators

The main digital and education variables include:

- **Daily internet use**  
  Individuals using the internet daily or almost every day  
  Eurostat indicator: `tin00092`

- **Social media participation**  
  Individuals participating in social networks  
  Eurostat indicator: `tin00127`

- **Household internet access**  
  Households with internet access  
  Eurostat indicator: `tin00134`

- **Internet non-use**  
  Individuals who have never used the internet  
  Eurostat indicator: `tin00093`

- **Tertiary education**  
  Percentage of the population aged 25–64 with tertiary education, ISCED 5–8  
  Eurostat dataset: `edat_lfse_03`

- **Digital skills**  
  Digital-skills indicators were reconstructed using the relevant Eurostat datasets:
  - `isoc_sk_dskl_i`
  - `isoc_sk_dskl_i21`

A methodological revision of the digital-skills indicator occurred during the analyzed period. The earlier and newer indicators are therefore not fully comparable across all years.

### OECD Indicators

The socioeconomic variables were obtained from the **OECD Income Distribution Database**:

- **Mean equivalised household disposable income**
- **Gini coefficient of disposable income**

Household income was converted using OECD Purchasing Power Parities for private consumption to improve cross-country comparability.

---

## Time Coverage

The reconstructed master panel covers:

**2017–2022**

However, the availability and methodological comparability of the digital-skills indicator limit the main multivariate models to:

**2017, 2019, and 2021**

For this reason, the project uses different analytical samples depending on the objective.

---

## Final Analytical Samples

### Main Multivariate Sample

The complete-case dataset used for the main multivariate analysis contains:

- **82 country-year observations**
- **30 countries**
- years **2017, 2019, and 2021**

This dataset is stored in:

```text
data/panel_complete_final.csv
```

### Fixed Effects Sample

Countries with only one usable observation were excluded because they do not contribute within-country variation to a Fixed Effects estimator.

The final FE sample contains:

- **80 observations**
- **28 countries**
- years **2017, 2019, and 2021**
- an unbalanced panel

This dataset is stored in:

```text
data/panel_fe_final.csv
```

### Reconstructed Full-Period Panel

The broader reconstructed dataset preserves all available observations across:

**2017–2022**

It contains:

- **272 country-year rows**
- **50 countries**
- missing values where individual indicators are unavailable

This dataset is stored in:

```text
data/panel_reconstruit_final.csv
```

---

## Digital Trends Before and During the COVID-19 Period

A separate descriptive analysis was conducted to preserve the full annual structure of the 2017–2022 period.

For this analysis:

- **2017–2019** are treated as the pre-pandemic period;
- **2020–2022** are treated as the pandemic period.

The descriptive trend analysis uses a balanced sample of **30 countries with observations in all six years** for daily internet use and social media participation.

![Digital Use Trends Before and During the COVID-19 Period](portfolio_figures/pandemic_digital_trends_2017_2022.png)

The figure suggests that both digital-use indicators were already increasing before 2020.

The pandemic period therefore appears to have continued or intensified an existing upward trajectory rather than producing an entirely new trend.

This analysis is descriptive and should not be interpreted as evidence of a causal COVID-19 effect.

---

## Fixed Effects Analysis

### Why Fixed Effects?

Fixed Effects models were used because the analysis focuses on how changes within the same country over time are associated with changes in digital behavior.

Country Fixed Effects control for unobserved country characteristics that remain constant over time.

Robust HC1 standard errors clustered at the country level were used for statistical inference.

Hausman tests were also estimated to compare Fixed Effects and Random Effects specifications.

---

### Main Fixed Effects Results

#### Social Media Participation

Dependent variable:

```text
participare_social_media
```

| Predictor | Coefficient | Robust SE | Significance |
|---|---:|---:|---:|
| Daily internet use | 0.697 | 0.243 | *** |
| Household income | 0.000592 | 0.000273 | ** |
| Gini coefficient | 2.388 | 41.451 | |
| Tertiary education | -0.743 | 0.366 | ** |
| Digital skills | 0.124 | 0.071 | * |
| Internet access | 0.462 | 0.206 | ** |
| Internet non-use | 0.632 | 0.337 | * |

Significance convention used in the reconstructed dissertation tables:

- `*` p < 0.10
- `**` p < 0.05
- `***` p < 0.01

Model statistics:

- N = **80**
- countries = **28**
- within R² = **0.769**
- adjusted R² = **0.594**

Hausman test:

- χ² ≈ **12.52**
- df = **7**
- p ≈ **0.0847**

The Hausman result does not reject Random Effects at the 5% level, although it provides marginal evidence at the 10% level.

---

#### Daily Internet Use

Dependent variable:

```text
daily_internet_use
```

| Predictor | Coefficient | Robust SE | Significance |
|---|---:|---:|---:|
| Household income | 0.000335 | 0.000088 | *** |
| Gini coefficient | -4.566 | 27.778 | |
| Tertiary education | 0.183 | 0.177 | |
| Digital skills | 0.138 | 0.045 | *** |
| Internet access | 0.064 | 0.113 | |
| Internet non-use | -1.060 | 0.113 | *** |

Model statistics:

- N = **80**
- countries = **28**
- within R² = **0.947**
- adjusted R² = **0.910**

Hausman test:

- χ² ≈ **28.21**
- df = **6**
- p < **0.001**

The Hausman test provides strong support for the Fixed Effects specification in the daily-internet-use model.

---

### Fixed Effects Coefficient Visualization

For presentation purposes, selected predictors were rescaled in the coefficient plot:

- percentage variables: effect of a **10 percentage-point increase**;
- household income: effect of a **$10,000 PPP increase**;
- Gini: effect of a **0.1-point increase**.

The dependent variables remain expressed in percentage points.

![Fixed Effects Coefficient Plot](portfolio_figures/fixed_effects_coefficients.png)

The plotted confidence intervals are based on country-clustered robust standard errors.

---

## Random Forest Analysis

A Random Forest regression model was estimated with:

```text
daily_internet_use
```

as the dependent variable.

The predictors included:

- social media participation;
- household income;
- Gini coefficient;
- tertiary education;
- digital skills;
- internet access;
- internet non-use.

Country and year were not used as Random Forest predictors.

The model used:

- **500 trees**
- `mtry = 2`
- a **70/30 row-level train/test split**
- random seed `123`

The Random Forest analysis is predictive and exploratory rather than causal.

---

### Main Random Forest Performance

Main analytical sample:

- total N = **82**
- training N = **58**
- test N = **24**

| Metric | Value |
|---|---:|
| RMSE | 3.353 |
| MAE | 2.616 |
| Predictive R² | 0.917 |
| Squared correlation | 0.934 |
| OOB MSE | 11.082 |
| OOB variance explained | approximately 91.9% |

The standard predictive R² is calculated as:

```text
1 - SSE / SST
```

The squared correlation is retained separately because this approach was used in the original dissertation workflow.

---

### Random Forest Variable Importance

Variable importance was evaluated using the percentage increase in Mean Squared Error (`%IncMSE`) when each predictor was permuted.

The main ranking was:

1. Internet non-use
2. Internet access
3. Social media participation
4. Household income
5. Digital skills
6. Tertiary education
7. Gini coefficient

![Random Forest Variable Importance](portfolio_figures/random_forest_variable_importance.png)

The results indicate that variables directly related to digital exclusion and access are particularly useful for predicting daily internet use.

Variable importance should not be interpreted as a causal effect.

---

### Partial Dependence

A Partial Dependence Plot was generated for internet non-use.

![Partial Dependence Plot](portfolio_figures/partial_dependence_internet_nonuse.png)

The plot shows the average Random Forest prediction for daily internet use as internet non-use changes while averaging over the observed distribution of the remaining predictors.

The relationship is clearly negative and nonlinear.

Higher levels of internet non-use are associated with substantially lower predicted daily internet use.

Partial dependence describes the behavior of the predictive model and should not be interpreted causally.

---

### Observed vs Predicted

The held-out test predictions were compared with the observed values.

![Observed vs Predicted](portfolio_figures/random_forest_observed_vs_predicted.png)

The predictions follow the observed values closely, although some regression toward the mean is visible for more extreme observations.

Because the test sample contains only 24 observations, the predictive metrics should be interpreted with appropriate caution.

---

## Full-Period Robustness Check (2017–2022)

To test whether the main conclusions remain broadly stable when the full temporal period is retained, supplementary Fixed Effects and Random Forest models were estimated using observations from **2017 through 2022**.

The digital-skills variable was excluded from these supplementary specifications because a consistent and methodologically comparable annual series is not available for the entire period.

The robustness analysis therefore prioritizes temporal coverage over inclusion of the complete predictor set used in the main models.

These supplementary models do not replace the main specification.

---

### Fixed Effects Robustness Check

After complete-case filtering, the full-period sample contained:

- **160 observations**
- **30 countries**

For FE estimation, one country with only one usable observation was excluded.

The final FE robustness sample therefore contains:

- **159 observations**
- **29 countries**
- years **2017–2022**
- an unbalanced panel with T = 2–6

#### Social Media Participation

Country-clustered robust results:

| Predictor | Coefficient | Robust SE | p-value |
|---|---:|---:|---:|
| Daily internet use | 0.408 | 0.171 | 0.0188 |
| Household income | 0.000268 | 0.000131 | 0.0433 |
| Gini coefficient | 10.955 | 39.062 | 0.7796 |
| Tertiary education | -0.476 | 0.341 | 0.1662 |
| Internet access | 0.342 | 0.178 | 0.0570 |
| Internet non-use | -0.008 | 0.267 | 0.9757 |

Model fit:

- within R² = **0.633**
- adjusted R² = **0.532**

Hausman test:

- χ² = **19.54**
- df = **6**
- p = **0.0033**

The Hausman test provides clear support for Fixed Effects in the full-period specification.

Daily internet use and household income remain positively associated with social media participation.

Internet access also remains positively associated with social media participation, although the result is marginal at the 10% level.

The tertiary-education and internet-non-use effects observed in the main specification are not statistically robust in this alternative specification.

---

#### Daily Internet Use

Country-clustered robust results:

| Predictor | Coefficient | Robust SE | p-value |
|---|---:|---:|---:|
| Household income | 0.000158 | 0.000071 | 0.0285 |
| Gini coefficient | -28.357 | 28.591 | 0.3232 |
| Tertiary education | 0.193 | 0.165 | 0.2434 |
| Internet access | 0.222 | 0.105 | 0.0363 |
| Internet non-use | -1.081 | 0.081 | <0.001 |

Model fit:

- within R² = **0.923**
- adjusted R² = **0.902**

Hausman test:

- χ² = **15.18**
- df = **5**
- p = **0.0096**

The daily-internet-use results are particularly stable.

Internet non-use remains a strong negative predictor:

```text
Main model:       -1.060
2017–2022 model:  -1.081
```

Household income also remains positively associated with daily internet use.

Internet access becomes statistically significant in the full-period specification.

Gini and tertiary education remain statistically non-significant.

---

### Random Forest Robustness Check

The supplementary Random Forest model uses the full 2017–2022 complete-case sample without digital skills.

Sample:

- total N = **160**
- countries = **30**
- training N = **112**
- test N = **48**

The same modeling procedure was retained:

- 70/30 row-level train/test split;
- seed = `123`;
- 500 trees;
- `mtry = 2`

#### Performance

| Metric | Main RF | 2017–2022 Robustness RF |
|---|---:|---:|
| Total N | 82 | 160 |
| Training N | 58 | 112 |
| Test N | 24 | 48 |
| RMSE | 3.353 | 2.652 |
| MAE | 2.616 | 2.066 |
| Predictive R² | 0.917 | 0.946 |
| Squared correlation | 0.934 | 0.954 |
| OOB MSE | 11.082 | 8.528 |
| OOB R² / variance explained | ~0.919 | 0.927 |

The supplementary model preserves very strong predictive performance over the full 2017–2022 period.

The improvement in individual performance metrics should not be interpreted as evidence that the full-period model is intrinsically superior, because both the analytical sample and predictor set differ from the main specification.

Instead, the result indicates that strong predictive performance remains present under the alternative full-period specification.

---

### Random Forest Robustness: Variable Importance

The full-period `%IncMSE` ranking is:

| Rank | Predictor | %IncMSE |
|---:|---|---:|
| 1 | Internet non-use | 25.954 |
| 2 | Internet access | 22.627 |
| 3 | Social media participation | 15.831 |
| 4 | Household income | 14.471 |
| 5 | Tertiary education | 13.306 |
| 6 | Gini coefficient | 6.147 |

The ordering is broadly consistent with the main Random Forest model.

In both specifications:

- internet non-use ranks first;
- internet access ranks second;
- social media participation and household income remain among the most important predictors;
- Gini remains the least important predictor.

Digital skills do not appear in this ranking because the variable was intentionally excluded from the full-period specification.

---

### Robustness Interpretation

Overall, the full-period analysis provides additional support for several of the main findings.

Particularly stable relationships include:

- the strong negative relationship between internet non-use and daily internet use;
- the positive relationship between household income and daily internet use;
- the positive relationship between daily internet use and social media participation;
- the high predictive importance of internet non-use and internet access;
- the relatively low importance and statistical instability of the Gini coefficient.

Not every coefficient remains statistically significant across specifications.

The robustness results should therefore be interpreted as evidence that several **core relationships are stable**, rather than as evidence that every individual coefficient is invariant.

The main and robustness models are not directly identical because both the temporal coverage and predictor set differ.

---

## Complementarity of Fixed Effects and Random Forest

The two methods answer different questions.

### Fixed Effects

Fixed Effects models estimate how changes in explanatory variables **within the same country over time** are associated with changes in the dependent variable.

They provide:

- coefficient direction;
- magnitude;
- statistical inference;
- control for time-invariant country characteristics.

### Random Forest

Random Forest focuses on predictive relationships.

It provides:

- predictive performance;
- variable importance;
- nonlinear patterns;
- interactions that are not explicitly specified in a linear model.

The methods therefore complement each other rather than compete.

For example, internet non-use is:

- strongly negatively associated with daily internet use in the FE models;
- the most important Random Forest predictor in both the main and robustness specifications.

Internet access also demonstrates an important distinction between the methods: it is highly important predictively in the RF models even when its linear within-country FE effect is not statistically significant in the main specification.

---

## Repository Structure

```text
digital-inequality-dissertation/
│
├── data/
│   ├── panel_complete_final.csv
│   ├── panel_fe_final.csv
│   └── panel_reconstruit_final.csv
│
├── figures/
│   ├── importanta_random_forest_final.png
│   ├── observat_vs_prezis_rf_final.png
│   └── pdp_nefolosire_internet_final.png
│
├── portfolio_figures/
│   ├── fixed_effects_coefficients.png
│   ├── pandemic_digital_trends_2017_2022.png
│   ├── partial_dependence_internet_nonuse.png
│   ├── random_forest_observed_vs_predicted.png
│   └── random_forest_variable_importance.png
│
├── results/
│   ├── importanta_random_forest_final.csv
│   ├── metrici_random_forest_final.csv
│   ├── pdp_nefolosire_internet_final.csv
│   ├── predictii_random_forest_final.csv
│   ├── robustness_fe_daily_2017_2022.csv
│   ├── robustness_fe_model_fit_2017_2022.csv
│   ├── robustness_fe_social_2017_2022.csv
│   ├── robustness_rf_importance_2017_2022.csv
│   ├── robustness_rf_metrics_2017_2022.csv
│   ├── robustness_rf_predictions_2017_2022.csv
│   ├── tabel_fe_final_disertatie.csv
│   ├── tabel_hausman_final.csv
│   └── tabel_random_forest_final.csv
│
├── scripts/
│   ├── 01_data_reconstruction_FE.R
│   ├── 02_random_forest.R
│   ├── 03_portfolio_figures.R
│   ├── 04_robustness_FE_2017_2022.R
│   └── 05_robustness_RF_2017_2022.R
│
├── .gitignore
├── LICENSE
└── README.md
```

The `figures/` directory contains figures generated during the original reconstruction workflow.

The `portfolio_figures/` directory contains presentation-ready English-language figures intended for the GitHub portfolio.

---

## Reproducibility

The workflow is organized into five scripts.

### 1. Data Reconstruction and Fixed Effects

```text
scripts/01_data_reconstruction_FE.R
```

This script:

- retrieves and reconstructs the analytical indicators;
- harmonizes country identifiers;
- prepares the panel datasets;
- estimates the main Fixed Effects models;
- estimates the main Hausman tests;
- exports the final FE results.

---

### 2. Main Random Forest Analysis

```text
scripts/02_random_forest.R
```

This script:

- loads the final complete analytical dataset;
- reproduces the train/test split;
- estimates the Random Forest model;
- calculates predictive metrics;
- generates variable importance;
- produces prediction and partial-dependence outputs.

---

### 3. Portfolio Visualizations

```text
scripts/03_portfolio_figures.R
```

This script generates the final English-language visualizations:

- Random Forest variable importance;
- partial dependence for internet non-use;
- observed vs predicted values;
- Fixed Effects coefficient plot;
- digital-use trends before and during the COVID-19 period.

---

### 4. Full-Period Fixed Effects Robustness Check

```text
scripts/04_robustness_FE_2017_2022.R
```

This script:

- constructs the 2017–2022 complete-case sample;
- intentionally excludes digital skills;
- removes countries with insufficient within-country observations;
- estimates supplementary Fixed Effects models;
- calculates country-clustered HC1 robust standard errors;
- performs Hausman tests;
- exports coefficients and model-fit statistics.

---

### 5. Full-Period Random Forest Robustness Check

```text
scripts/05_robustness_RF_2017_2022.R
```

This script:

- constructs the 2017–2022 complete-case sample;
- excludes digital skills;
- retains the same 70/30 split logic and random seed;
- estimates a 500-tree Random Forest;
- calculates test and OOB performance;
- calculates variable importance;
- exports metrics and predictions.

---

## Software and Packages

The analysis was conducted in **R**.

Main packages include:

```text
eurostat
dplyr
tidyr
plm
lmtest
sandwich
randomForest
caret
pdp
ggplot2
```

---

## Methodological Notes

### Fixed Effects Interpretation

The FE coefficients refer to changes **within countries over time**.

They should not be interpreted as simple cross-sectional differences between countries.

The reported FE R² values therefore primarily describe the proportion of within-country variation explained by the models.

### Random Forest Interpretation

The Random Forest analysis is predictive and exploratory.

Variable importance and partial dependence should not be interpreted as causal effects.

### Train/Test Split

The Random Forest train/test split is performed at the **country-year observation level**, not by holding out entire countries.

The reported test performance therefore evaluates prediction on held-out observations rather than generalization to completely unseen countries.

### Digital-Skills Discontinuity

The digital-skills indicator underwent a methodological revision during the period.

Because a fully comparable annual series is not available across 2017–2022, the main specification prioritizes inclusion of digital skills and uses the years where compatible data are available.

The full-period robustness specifications instead prioritize temporal coverage and exclude digital skills.

---

## Limitations

Several limitations should be considered when interpreting the results:

- The main multivariate models are restricted to 2017, 2019, and 2021 because of digital-skills data availability.
- The digital-skills indicator experienced a methodological revision during the period.
- The panel is unbalanced.
- The number of countries and country-year observations is relatively limited.
- The main Random Forest test sample contains only 24 observations.
- The robustness Random Forest test sample contains 48 observations.
- The Random Forest split is performed at the observation level rather than by country.
- Random Forest variable importance is predictive rather than causal.
- Fixed Effects estimates capture within-country relationships and should not be generalized directly to cross-country differences.
- The COVID-period trend analysis is descriptive and does not establish a causal pandemic effect.
- The main and robustness models differ in both time coverage and predictor composition, so changes in estimates cannot be attributed solely to the inclusion of additional years.

---

## Use of Generative AI Tools

Generative AI tools were used as supporting tools during the reconstruction, validation, debugging, and documentation of this project.

Uses included:

- code review and debugging;
- clarification of statistical and programming concepts;
- restructuring and documenting the R workflow;
- consistency checks across datasets, models, and outputs;
- support in preparing portfolio-oriented visualizations;
- language editing and documentation.

Generative AI was not used as a substitute for the underlying statistical analysis or official data sources.

The datasets were obtained from Eurostat and the OECD, while the final methodological choices, model specifications, interpretations, and reported results were reviewed and validated by the author.

---

## License

The code in this repository is released under the **MIT License**.

The underlying Eurostat and OECD datasets remain subject to the terms, licenses, and conditions of their respective data providers.

---

## Author

**Cosmin Osaci**

Master's project focused on applied data analysis, panel-data econometrics, machine learning, and reproducible research using R.

