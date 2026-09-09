# =========================================================
# DISERTATIE - RANDOM FOREST
#
# Script 02
#
# Scop:
# Reconstruirea analizei Random Forest folosind baza
# finala rezultata dupa auditarea si reconstruirea datelor.
# =========================================================



# =========================================================
# STRUCTURA PORTABILA A REPOSITORY-ULUI
# =========================================================
# Toate caile sunt relative la radacina proiectului GitHub.
dir.create("data", showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

# =========================================================
# 1. INCARCAREA BAZEI DE DATE
# =========================================================

panel_complete <- read.csv(
  "data/panel_complete_final.csv",
  stringsAsFactors = FALSE
)


# Verificari
dim(panel_complete)

names(panel_complete)

summary(panel_complete)



# =========================================================
# 2. PACHETE NECESARE PENTRU RANDOM FOREST
# =========================================================

# Instalarea se face doar daca pachetele nu exista deja
if (!requireNamespace("randomForest", quietly = TRUE)) {
  install.packages("randomForest")
}

if (!requireNamespace("caret", quietly = TRUE)) {
  install.packages("caret")
}


# Incarcarea pachetelor
library(randomForest)
library(caret)
library(dplyr)


# =========================================================
# 3. CONSTRUIREA DATASETULUI PENTRU RANDOM FOREST
#
# Random Forest este utilizat pe date pooled.
#
# Variabila dependenta:
# daily_internet_use
#
# Predictori:
# participare_social_media
# venit_mediu_gospodarie
# gini
# educatie_superioara
# abilitati_digitale
# nivel_acces_internet
# nefolosire_internet
# =========================================================

rf_data <- panel_complete %>%
  
  select(
    daily_internet_use,
    participare_social_media,
    venit_mediu_gospodarie,
    gini,
    educatie_superioara,
    abilitati_digitale,
    nivel_acces_internet,
    nefolosire_internet
  ) %>%
  
  na.omit()


# Verificari
dim(rf_data)

names(rf_data)

colSums(is.na(rf_data))


# =========================================================
# 4. IMPARTIREA DATASETULUI IN TRAIN / TEST
#
# Scop:
# Reproducem metodologia utilizata initial:
# - 70% din observatii pentru antrenare
# - 30% pentru testare
# - seed = 123 pentru reproducibilitate
#
# createDataPartition() incearca sa pastreze distributia
# variabilei dependente relativ similara intre train si test.
# =========================================================

set.seed(123)

train_index <- createDataPartition(
  rf_data$daily_internet_use,
  p = 0.7,
  list = FALSE
)


# Setul pentru antrenarea modelului
train_data <- rf_data[
  train_index,
]


# Setul pentru evaluarea modelului
test_data <- rf_data[
  -train_index,
]


# =========================================================
# VERIFICARI
# =========================================================

dim(train_data)

dim(test_data)

# Verificam daca toate cele 82 de observatii
# se regasesc in train + test
nrow(train_data) + nrow(test_data)


# =========================================================
# 5. ESTIMAREA MODELULUI RANDOM FOREST
#
# Scop:
# Estimam modelul predictiv pentru utilizarea zilnica
# a internetului.
#
# Reproducem specificatia originala:
# - 500 arbori
# - toate cele 7 variabile drept predictori
# - importance = TRUE
# =========================================================

rf_model <- randomForest(
  
  daily_internet_use ~ .,
  
  data = train_data,
  
  ntree = 500,
  
  importance = TRUE
)


# Afisam sumarul modelului
rf_model



# =========================================================
# 6. PREDICTII PE SETUL DE TEST
#
# Scop:
# Evaluam modelul pe observatii care NU au fost utilizate
# pentru antrenarea Random Forest.
# =========================================================


# Generam predictiile pentru setul de test
pred_rf <- predict(
  rf_model,
  newdata = test_data
)


# Valorile reale
y_test <- test_data$daily_internet_use


# Valorile prezise
y_pred <- as.numeric(pred_rf)


# Verificari
length(y_test)

length(y_pred)

head(
  data.frame(
    Observat = y_test,
    Prezis = y_pred
  )
)



# =========================================================
# 7. METRICILE DE PERFORMANTA RANDOM FOREST
#
# Scop:
# Evaluam performanta predictiva pe setul de test.
# =========================================================


# RMSE
rmse_val <- sqrt(
  mean(
    (y_test - y_pred)^2
  )
)


# MAE
mae_val <- mean(
  abs(
    y_test - y_pred
  )
)


# R2 calculat ca in analiza initiala
r2_cor <- cor(
  y_test,
  y_pred
)^2


# R2 predictiv standard
r2_predictiv <- 1 -
  sum(
    (y_test - y_pred)^2
  ) /
  sum(
    (y_test - mean(y_test))^2
  )


# Tabel cu metricile
metrici_rf <- data.frame(
  
  Metrica = c(
    "RMSE",
    "MAE",
    "R2_cor_original",
    "R2_predictiv"
  ),
  
  Valoare = c(
    rmse_val,
    mae_val,
    r2_cor,
    r2_predictiv
  )
)


metrici_rf %>%
  tibble::as_tibble() %>%
  print()


# =========================================================
# 8. IMPORTANTA VARIABILELOR IN RANDOM FOREST
#
# Scop:
# Verificam ce predictori contribuie cel mai mult
# la acuratetea predictiva a modelului.
#
# %IncMSE:
# arata cat creste eroarea modelului atunci cand valorile
# unei variabile sunt permutate.
#
# O valoare mai mare = variabila mai importanta predictiv.
# =========================================================


# Extragem scorurile de importanta
imp <- importance(rf_model)


# Transformam rezultatul intr-un tabel
imp_df <- data.frame(
  
  Variabila = rownames(imp),
  
  IncMSE = imp[, "%IncMSE"],
  
  IncNodePurity = imp[, "IncNodePurity"],
  
  row.names = NULL
)


# Ordonam variabilele dupa %IncMSE
imp_df <- imp_df %>%
  
  arrange(
    desc(IncMSE)
  )


# Afisam clasamentul complet
imp_df %>%
  tibble::as_tibble() %>%
  print(n = Inf)


# =========================================================
# 9. SALVAREA IMPORTANTEI VARIABILELOR
# =========================================================

write.csv(
  imp_df,
  "results/importanta_random_forest_final.csv",
  row.names = FALSE
)


# =========================================================
# 10. GRAFICUL IMPORTANTEI VARIABILELOR
#
# Scop:
# Reprezentam grafic importanta predictiva a variabilelor
# pe baza indicatorului %IncMSE.
#
# Valoare mai mare = importanta predictiva mai mare.
# =========================================================

library(ggplot2)


# Denumiri mai clare pentru prezentarea in disertatie
imp_plot <- imp_df %>%
  
  mutate(
    
    Variabila = recode(
      Variabila,
      
      nefolosire_internet = "Nefolosire internet",
      nivel_acces_internet = "Nivel acces internet",
      participare_social_media = "Participare social media",
      venit_mediu_gospodarie = "Venit mediu gospodarie",
      abilitati_digitale = "Abilitati digitale",
      educatie_superioara = "Educatie superioara",
      gini = "Coeficient Gini"
    )
  )


# Grafic
g_importanta_rf <- ggplot(
  imp_plot,
  aes(
    x = reorder(Variabila, IncMSE),
    y = IncMSE
  )
) +
  
  geom_col() +
  
  coord_flip() +
  
  labs(
    title = "Importanta variabilelor in modelul Random Forest",
    x = NULL,
    y = "Importanta predictiva (% crestere MSE)"
  ) +
  
  theme_minimal(
    base_size = 13
  )


g_importanta_rf


# =========================================================
# 11. SALVAREA GRAFICULUI DE IMPORTANTA RF
# =========================================================

ggsave(
  filename = "figures/importanta_random_forest_final.png",
  plot = g_importanta_rf,
  width = 9,
  height = 6,
  dpi = 300
)


# =========================================================
# 12. PARTIAL DEPENDENCE PLOT
#     NEFOLOSIRE INTERNET
#
# Scop:
# Analizam cum se modifica predictia utilizarii zilnice
# a internetului atunci cand variaza nefolosirea
# internetului, tinand cont de ceilalti predictori.
#
# Interpretarea este predictiva, nu cauzala.
# =========================================================


# Instalam pachetul doar daca nu exista
if (!requireNamespace("pdp", quietly = TRUE)) {
  install.packages("pdp")
}

library(pdp)


# Calculam dependenta partiala
pdp_nefolosire <- partial(
  rf_model,
  pred.var = "nefolosire_internet",
  train = train_data
)


# Verificam valorile calculate
head(pdp_nefolosire)

summary(pdp_nefolosire)





# =========================================================
# 13. GRAFIC PDP - NEFOLOSIRE INTERNET
# =========================================================

g_pdp_nefolosire <- ggplot(
  pdp_nefolosire,
  aes(
    x = nefolosire_internet,
    y = yhat
  )
) +
  
  geom_line(
    linewidth = 1
  ) +
  
  labs(
    title = "Relatia predictiva dintre nefolosirea internetului si utilizarea zilnica",
    x = "Nefolosirea internetului (%)",
    y = "Utilizarea zilnica a internetului prezisa (%)"
  ) +
  
  theme_minimal(
    base_size = 13
  )


g_pdp_nefolosire


# =========================================================
# 14. SALVAREA GRAFICULUI PDP
# =========================================================

ggsave(
  filename = "figures/pdp_nefolosire_internet_final.png",
  plot = g_pdp_nefolosire,
  width = 9,
  height = 6,
  dpi = 300
)


# =========================================================
# 15. GRAFIC OBSERVAT VS PREZIS
#
# Scop:
# Comparam valorile reale ale utilizarii zilnice
# a internetului cu valorile prezise de Random Forest.
#
# Cu cat punctele sunt mai apropiate de diagonala,
# cu atat predictiile sunt mai precise.
# =========================================================


df_observat_prezis <- data.frame(
  
  Observat = y_test,
  
  Prezis = y_pred
)


g_observat_prezis <- ggplot(
  df_observat_prezis,
  aes(
    x = Observat,
    y = Prezis
  )
) +
  
  geom_point(
    size = 2.5,
    alpha = 0.8
  ) +
  
  geom_abline(
    intercept = 0,
    slope = 1,
    linetype = "dashed",
    linewidth = 0.8
  ) +
  
  labs(
    title = "Valori observate vs. valori prezise - Random Forest",
    x = "Utilizarea zilnica a internetului observata (%)",
    y = "Utilizarea zilnica a internetului prezisa (%)"
  ) +
  
  theme_minimal(
    base_size = 13
  )


g_observat_prezis



# =========================================================
# 16. SALVAREA GRAFICULUI OBSERVAT VS. PREZIS
# =========================================================

ggsave(
  filename = "figures/observat_vs_prezis_rf_final.png",
  plot = g_observat_prezis,
  width = 8,
  height = 6,
  dpi = 300
)



# =========================================================
# 17. SALVAREA MODELULUI SI A PREDICTIILOR RF
# =========================================================

# Salvam modelul Random Forest
saveRDS(
  rf_model,
  "results/random_forest_final.rds"
)


# Salvam valorile observate si prezise
write.csv(
  df_observat_prezis,
  "results/predictii_random_forest_final.csv",
  row.names = FALSE
)


# Salvam obiectul PDP
write.csv(
  pdp_nefolosire,
  "results/pdp_nefolosire_internet_final.csv",
  row.names = FALSE
)


# =========================================================
# 18. REZUMAT FINAL RANDOM FOREST
# =========================================================

cat("\n===== RANDOM FOREST FINAL =====\n")

cat("\nObservatii totale:", nrow(rf_data))
cat("\nTrain:", nrow(train_data))
cat("\nTest:", nrow(test_data))

cat("\n\nRMSE:", round(rmse_val, 3))
cat("\nMAE:", round(mae_val, 3))
cat("\nR2 original (cor^2):", round(r2_cor, 3))
cat("\nR2 predictiv:", round(r2_predictiv, 3))

cat("\n\nTop variabile dupa %IncMSE:\n")

print(
  imp_df %>%
    select(Variabila, IncMSE) %>%
    arrange(desc(IncMSE))
)

cat("\n===============================\n")


# =========================================================
# 19. TABEL FINAL - PERFORMANTA RANDOM FOREST
#
# Scop:
# Centralizam indicatorii care vor fi utilizati
# in versiunea finala a disertatiei.
# =========================================================

tabel_rf_final <- data.frame(
  
  Indicator = c(
    "Observatii totale",
    "Train",
    "Test",
    "Numar arbori",
    "Varianta explicata OOB (%)",
    "RMSE",
    "MAE",
    "R2 predictiv",
    "cor(observat, prezis)^2"
  ),
  
  Valoare = c(
    nrow(rf_data),
    nrow(train_data),
    nrow(test_data),
    500,
    tail(rf_model$rsq, 1) * 100,
    rmse_val,
    mae_val,
    r2_predictiv,
    r2_cor
  )
)


tabel_rf_final %>%
  tibble::as_tibble() %>%
  print()


# Salvare
write.csv(
  tabel_rf_final,
  "results/tabel_random_forest_final.csv",
  row.names = FALSE
)


# =========================================================
# 20. VERIFICARE FINALA A FISIERELOR RANDOM FOREST
# =========================================================

c(
  list.files(
    "results",
    pattern = "random_forest|rf|pdp|observat",
    full.names = FALSE
  ),
  list.files(
    "figures",
    pattern = "random_forest|rf|pdp|observat",
    full.names = FALSE
  )
)

# Optional - salvam si tabelul brut al metricilor
write.csv(
  metrici_rf,
  "results/metrici_random_forest_final.csv",
  row.names = FALSE
)