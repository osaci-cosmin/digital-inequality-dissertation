install.packages("eurostat")

library(eurostat)
library(dplyr)


# =========================================================
# STRUCTURA PORTABILA A REPOSITORY-ULUI
# =========================================================
# Toate caile sunt relative la radacina proiectului GitHub.
# Astfel, scriptul poate fi rulat si pe alte calculatoare.
dir.create("data", showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)


daily <- eurostat::get_eurostat("tin00092", time_format = "num")

access <- eurostat::get_eurostat("tin00134", time_format = "num")

education <- eurostat::get_eurostat("edat_lfse_03", time_format = "num")

names(daily)
names(access)
names(education)

head(daily)
head(access)
head(education)

# Verificăm categoriile existente în fiecare dataset

sort(unique(daily$indic_is))
sort(unique(daily$unit))
sort(unique(daily$ind_type))

sort(unique(access$unit))
sort(unique(access$hhtyp))

sort(unique(education$sex))
sort(unique(education$age))
sort(unique(education$unit))
sort(unique(education$isced11))

# =========================================================
# VERIFICARE VARIABILA EDUCATIE SUPERIOARA
# Scop:
# Vrem sa vedem cum arata valorile Eurostat pentru educatia
# tertiara (ISCED 5-8) in functie de grupa de varsta.
# Nu modificam datasetul original, doar facem un rezumat.
# =========================================================

edu_check <- education %>%
  
  # Pasul 1:
  # pastram doar totalul populatiei, nu separat femei/barbati
  filter(
    sex == "T",
    
    # Pasul 2:
    # pastram doar educatia tertiara = ISCED 5-8
    isced11 == "ED5-8",
    
    # Pasul 3:
    # pastram perioada studiului nostru
    TIME_PERIOD >= 2017,
    TIME_PERIOD <= 2022
  ) %>%
  
  # Pasul 4:
  # grupam rezultatele dupa grupa de varsta
  group_by(age) %>%
  
  # Pasul 5:
  # pentru fiecare grupa de varsta calculam:
  # - cate observatii valide exista
  # - media
  # - minimul
  # - maximul
  summarise(
    N = sum(!is.na(values)),
    Medie = mean(values, na.rm = TRUE),
    Minim = min(values, na.rm = TRUE),
    Maxim = max(values, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  
  # Pasul 6:
  # ordonam tabelul dupa grupa de varsta
  arrange(age)

# Afisam rezultatul final in consola
edu_check


# =========================================================
# COMPARATIE GRUPE DE VARSTA PLAUZIBILE
# Scop:
# Comparam cateva grupe de varsta relevante pentru
# indicatorul de educatie tertiara (ISCED 5-8).
#
# IMPORTANT:
# Nu alegem inca grupa finala.
# Vrem doar sa vedem cum difera valorile intre variante.
# =========================================================

edu_focus <- education %>%
  
  # Pasul 1:
  # pastram totalul populatiei (femei + barbati)
  filter(
    sex == "T",
    
    # Pasul 2:
    # indicatorul este exprimat procentual
    unit == "PC",
    
    # Pasul 3:
    # educatie tertiara = ISCED 5-8
    isced11 == "ED5-8",
    
    # Pasul 4:
    # comparam doar grupele de varsta relevante
    age %in% c(
      "Y25-34",
      "Y25-64",
      "Y25-74",
      "Y30-34"
    ),
    
    # Pasul 5:
    # perioada analizata in disertatie
    TIME_PERIOD >= 2017,
    TIME_PERIOD <= 2022
  ) %>%
  
  # Pasul 6:
  # calculam statisticile separat pentru fiecare grupa
  group_by(age) %>%
  summarise(
    N = sum(!is.na(values)),
    Medie = mean(values, na.rm = TRUE),
    Minim = min(values, na.rm = TRUE),
    Maxim = max(values, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  
  # Pasul 7:
  # ordonam rezultatele dupa grupa de varsta
  arrange(age)

# Afisam tabelul complet
edu_focus


# =========================================================
# CONSTRUIREA VARIABILEI EDUCATIE SUPERIOARA
#
# Scop:
# Construim indicatorul final pentru educatia tertiara.
#
# Definitie aleasa:
# procentul populatiei de 25-64 ani care a absolvit
# educatie tertiara (ISCED 5-8).
#
# Sursa:
# Eurostat - edat_lfse_03
#
# IMPORTANT:
# Pastram valorile in procente.
# Exemplu: 34.5 inseamna 34.5%, NU 0.345.
# =========================================================

educatie_superioara_new <- education %>%
  
  # Pasul 1:
  # alegem totalul populatiei, fara separare femei/barbati
  filter(
    sex == "T",
    
    # Pasul 2:
    # grupa de varsta adulta / populatia de varsta activa
    age == "Y25-64",
    
    # Pasul 3:
    # valorile sunt exprimate procentual
    unit == "PC",
    
    # Pasul 4:
    # educatie tertiara = ISCED nivelurile 5-8
    isced11 == "ED5-8",
    
    # Pasul 5:
    # perioada cercetarii
    TIME_PERIOD >= 2017,
    TIME_PERIOD <= 2022
  ) %>%
  
  # Pasul 6:
  # pastram doar informatia necesara pentru panel
  select(
    country = geo,
    year = TIME_PERIOD,
    educatie_superioara = values
  ) %>%
  
  # Pasul 7:
  # ordonam dupa tara si an pentru verificare
  arrange(country, year)


# =========================================================
# VERIFICARE
# Vedem primele observatii si statisticile descriptive.
# =========================================================

head(educatie_superioara_new)

summary(educatie_superioara_new$educatie_superioara)

nrow(educatie_superioara_new)

length(unique(educatie_superioara_new$country))

# =========================================================
# SALVAREA VARIABILEI EDUCATIE SUPERIOARA
#
# Scop:
# Salvam variabila reconstruita pentru a nu pierde din nou
# datele si pentru a o folosi ulterior la construirea panelului.
# =========================================================

# Cream un folder special pentru datele reconstruite.
# Daca exista deja, R nu da eroare.
dir.create("data", showWarnings = FALSE)

# Salvare in format R
saveRDS(
  educatie_superioara_new,
  "data/educatie_superioara.rds"
)

# Salvare si in CSV pentru a putea vedea usor datele
write.csv(
  educatie_superioara_new,
  "data/educatie_superioara.csv",
  row.names = FALSE
)

# =========================================================
# RECONSTRUCTIE - UTILIZARE ZILNICA A INTERNETULUI
#
# Sursa: Eurostat tin00092
# Indicator: utilizarea zilnica / aproape zilnica a internetului
# Valorile sunt procente.
# =========================================================

daily_internet_new <- daily %>%
  
  # Pastram doar perioada cercetarii
  filter(
    TIME_PERIOD >= 2017,
    TIME_PERIOD <= 2022
  ) %>%
  
  # Pastram doar tara, anul si valoarea indicatorului
  select(
    country = geo,
    year = TIME_PERIOD,
    daily_internet_use = values
  ) %>%
  
  # Ordonam pentru verificare
  arrange(country, year)


# =========================================================
# RECONSTRUCTIE - ACCES INTERNET IN GOSPODARII
#
# Sursa: Eurostat tin00134
# Indicator: gospodarii cu acces la internet
# Valorile sunt procente.
# =========================================================

internet_access_new <- access %>%
  
  # Pastram perioada studiului
  filter(
    TIME_PERIOD >= 2017,
    TIME_PERIOD <= 2022
  ) %>%
  
  # Pastram doar informatia necesara pentru panel
  select(
    country = geo,
    year = TIME_PERIOD,
    nivel_acces_internet = values
  ) %>%
  
  arrange(country, year)


# =========================================================
# VERIFICARE
# =========================================================

summary(daily_internet_new$daily_internet_use)
nrow(daily_internet_new)
length(unique(daily_internet_new$country))

summary(internet_access_new$nivel_acces_internet)
nrow(internet_access_new)
length(unique(internet_access_new$country))

# =========================================================
# SALVAREA VARIABILELOR INTERNET
#
# Scop:
# Salvam cele doua serii reconstruite pentru a putea
# construi ulterior panelul final fara sa le descarcam din nou.
# =========================================================

# Salvare utilizare zilnica internet - format R
saveRDS(
  daily_internet_new,
  "data/daily_internet_use.rds"
)

# Salvare utilizare zilnica internet - CSV
write.csv(
  daily_internet_new,
  "data/daily_internet_use.csv",
  row.names = FALSE
)


# Salvare acces internet - format R
saveRDS(
  internet_access_new,
  "data/nivel_acces_internet.rds"
)

# Salvare acces internet - CSV
write.csv(
  internet_access_new,
  "data/nivel_acces_internet.csv",
  row.names = FALSE
)

# =========================================================
# DESCARCARE - SOCIAL MEDIA SI NEFOLOSIRE INTERNET
#
# Scop:
# Descarcam cele doua variabile Eurostat ramase care
# pot fi reconstruite direct din indicatorii oficiali.
# =========================================================

# Participare la retele sociale
social_raw <- eurostat::get_eurostat(
  "tin00127",
  time_format = "num"
)

# Persoane care nu au folosit niciodata internetul
never_raw <- eurostat::get_eurostat(
  "tin00093",
  time_format = "num"
)


# =========================================================
# VERIFICARE STRUCTURA
#
# Inainte sa filtram, verificam coloanele si primele randuri.
# Astfel nu presupunem ce filtre trebuie aplicate.
# =========================================================

names(social_raw)
head(social_raw)

names(never_raw)
head(never_raw)


# =========================================================
# VERIFICARE + RECONSTRUCTIE
# SOCIAL MEDIA SI NEFOLOSIRE INTERNET
#
# Scop:
# Transformam cele doua tabele Eurostat in forma necesara
# pentru panel:
#
# country | year | variabila
#
# Pastram perioada cercetarii: 2017-2022.
# =========================================================


# ---------------------------------------------------------
# 1. VERIFICARE CATEGORII
#
# Verificam daca fiecare tabel contine o singura categorie
# pentru indicator, unitate si tipul populatiei.
# Nu modificam datele.
# ---------------------------------------------------------

sort(unique(social_raw$indic_is))
sort(unique(social_raw$unit))
sort(unique(social_raw$ind_type))

sort(unique(never_raw$indic_is))
sort(unique(never_raw$unit))
sort(unique(never_raw$ind_type))


# =========================================================
# 2. PARTICIPARE LA SOCIAL MEDIA
# =========================================================

social_media_new <- social_raw %>%
  
  # Pastram doar perioada analizata in disertatie
  filter(
    TIME_PERIOD >= 2017,
    TIME_PERIOD <= 2022
  ) %>%
  
  # Pastram doar coloanele necesare pentru panel
  select(
    country = geo,
    year = TIME_PERIOD,
    participare_social_media = values
  ) %>%
  
  # Ordonam dupa tara si an
  arrange(country, year)


# =========================================================
# 3. NEFOLOSIRE INTERNET
# =========================================================

never_internet_new <- never_raw %>%
  
  # Pastram doar perioada cercetarii
  filter(
    TIME_PERIOD >= 2017,
    TIME_PERIOD <= 2022
  ) %>%
  
  # Pastram doar coloanele necesare pentru panel
  select(
    country = geo,
    year = TIME_PERIOD,
    nefolosire_internet = values
  ) %>%
  
  # Ordonam dupa tara si an
  arrange(country, year)

# =========================================================
# 1. CONSTRUIREA VARIABILELOR
# =========================================================

social_media_new <- social_raw %>%
  filter(
    TIME_PERIOD >= 2017,
    TIME_PERIOD <= 2022
  ) %>%
  select(
    country = geo,
    year = TIME_PERIOD,
    participare_social_media = values
  ) %>%
  arrange(country, year)


never_internet_new <- never_raw %>%
  filter(
    TIME_PERIOD >= 2017,
    TIME_PERIOD <= 2022
  ) %>%
  select(
    country = geo,
    year = TIME_PERIOD,
    nefolosire_internet = values
  ) %>%
  arrange(country, year)


# =========================================================
# 4. VERIFICAREA REZULTATELOR
#
# Scop:
# Verificam daca variabilele reconstruite au valori plauzibile
# si vedem:
# - distributia valorilor
# - numarul de observatii
# - numarul de tari
#
# Nu modificam datele in aceasta etapa.
# =========================================================


# ---------------------------------------------------------
# Participare la social media
# ---------------------------------------------------------

summary(social_media_new$participare_social_media)

# Numar total de observatii tara-an
nrow(social_media_new)

# Numar de tari distincte
length(unique(social_media_new$country))


# ---------------------------------------------------------
# Nefolosire internet
# ---------------------------------------------------------

summary(never_internet_new$nefolosire_internet)

# Numar total de observatii tara-an
nrow(never_internet_new)

# Numar de tari distincte
length(unique(never_internet_new$country))



# =========================================================
# 5. SALVAREA VARIABILELOR
#
# Scop:
# Salvam cele doua variabile reconstruite pentru a nu
# depinde din nou de descarcarea datelor brute.
#
# Salvam:
# - RDS = format optim pentru lucru ulterior in R
# - CSV = format usor de inspectat si arhivat
# =========================================================


# ---------------------------------------------------------
# Participare la social media
# ---------------------------------------------------------

saveRDS(
  social_media_new,
  "data/participare_social_media.rds"
)

write.csv(
  social_media_new,
  "data/participare_social_media.csv",
  row.names = FALSE
)


# ---------------------------------------------------------
# Nefolosire internet
# ---------------------------------------------------------

saveRDS(
  never_internet_new,
  "data/nefolosire_internet.rds"
)

write.csv(
  never_internet_new,
  "data/nefolosire_internet.csv",
  row.names = FALSE
)



# =========================================================
# 6. VERIFICAREA FISIERELOR SALVATE
#
# Scop:
# Confirmam ca fisierele au fost create efectiv in folderul
# data.
# =========================================================

file.exists(
  "data/participare_social_media.rds"
)

file.exists(
  "data/participare_social_media.csv"
)

file.exists(
  "data/nefolosire_internet.rds"
)

file.exists(
  "data/nefolosire_internet.csv"
)

# Afisam toate fisierele salvate pana acum
list.files("data")


# =========================================================
# VERIFICARE STATISTICA - SOCIAL MEDIA SI NEFOLOSIRE INTERNET
#
# Scop:
# Verificam distributia valorilor si dimensiunea datelor
# reconstruite inainte de a trece la urmatoarea variabila.
# =========================================================

summary(social_media_new$participare_social_media)
nrow(social_media_new)
length(unique(social_media_new$country))

summary(never_internet_new$nefolosire_internet)
nrow(never_internet_new)
length(unique(never_internet_new$country))


# =========================================================
# ABILITATI DIGITALE - DESCARCAREA DATELOR BRUTE
#
# Scop:
# Reconstruim variabila "abilitati_digitale".
#
# Disertatia utilizeaza doua serii Eurostat:
#
# 1. isoc_sk_dskl_i
#    - seria veche
#    - folosita pentru 2017 si 2019
#
# 2. isoc_sk_dskl_i21
#    - seria metodologic actualizata
#    - folosita pentru 2021
#
# IMPORTANT:
# Nu filtram si nu combinam datele inca.
# Mai intai verificam structura reala a celor doua tabele.
# =========================================================


# ---------------------------------------------------------
# 1. DESCARCARE SERIE VECHE
# ---------------------------------------------------------

digital_old <- eurostat::get_eurostat(
  "isoc_sk_dskl_i",
  time_format = "num"
)


# ---------------------------------------------------------
# 2. DESCARCARE SERIE NOUA
# ---------------------------------------------------------

digital_new <- eurostat::get_eurostat(
  "isoc_sk_dskl_i21",
  time_format = "num"
)


# =========================================================
# 3. VERIFICAREA STRUCTURII DATELOR
#
# Scop:
# Vedem exact ce coloane exista si cum sunt codificate
# variabilele in fiecare serie.
#
# Nu presupunem filtrele inainte sa inspectam datele.
# =========================================================


# Coloanele disponibile in seria veche
names(digital_old)

# Primele observatii din seria veche
head(digital_old)


# Coloanele disponibile in seria noua
names(digital_new)

# Primele observatii din seria noua
head(digital_new)


#verificare suprapunere cu perioada mentionata in disertatie
# =========================================================
# CONTROL INTERVAL TEMPORAL - 2017-2022
#
# Scop:
# Verificam ca toate variabilele reconstruite pana acum
# contin numai ani din intervalul analizat in disertatie.
#
# Rezultatul asteptat:
# minim = 2017
# maxim = 2022
#
# Unele variabile pot sa nu aiba observatii in fiecare an,
# dar NU trebuie sa existe ani < 2017 sau > 2022.
# =========================================================

range(educatie_superioara_new$year, na.rm = TRUE)

range(daily_internet_new$year, na.rm = TRUE)

range(internet_access_new$year, na.rm = TRUE)

range(social_media_new$year, na.rm = TRUE)

range(never_internet_new$year, na.rm = TRUE)


# =========================================================
# ABILITATI DIGITALE
# 4. LIMITAREA LA INTERVALUL RELEVANT AL LUCRARII
#
# Scop:
# Pastram numai observatiile care pot intra in analiza
# disertatiei (2017-2022).
#
# Seria veche este disponibila pentru:
# - 2017
# - 2019
#
# Seria noua este folosita pentru:
# - 2021
#
# Nu folosim 2015, 2023 sau 2025.
# =========================================================


# ---------------------------------------------------------
# SERIA VECHE - 2017 si 2019
# ---------------------------------------------------------

digital_old_study <- digital_old %>%
  filter(
    TIME_PERIOD %in% c(2017, 2019)
  )


# ---------------------------------------------------------
# SERIA NOUA - 2021
# ---------------------------------------------------------

digital_new_study <- digital_new %>%
  filter(
    TIME_PERIOD == 2021
  )


# =========================================================
# 5. CONTROLUL ANILOR
#
# Verificam ca filtrarea temporala a functionat corect.
#
# Rezultatul asteptat:
# seria veche -> 2017, 2019
# seria noua  -> 2021
# =========================================================

sort(unique(digital_old_study$TIME_PERIOD))

sort(unique(digital_new_study$TIME_PERIOD))


# =========================================================
# 6. IDENTIFICAREA CATEGORIILOR CORECTE
#
# Scop:
# In tabele exista mai multe niveluri de competente digitale.
#
# Pentru disertatie avem nevoie de:
#
# seria veche:
# I_DSK_BAB = basic OR above basic
#
# seria noua:
# I_DSK2_BAB = basic OR above basic
#
# Verificam si:
# - tipurile de populatie
# - unitatea de masura
#
# Nu filtram inca dupa aceste categorii.
# =========================================================


# ---------------------------------------------------------
# SERIA VECHE
# ---------------------------------------------------------

sort(unique(digital_old_study$indic_is))

sort(unique(digital_old_study$ind_type))

sort(unique(digital_old_study$unit))


# ---------------------------------------------------------
# SERIA NOUA
# ---------------------------------------------------------

sort(unique(digital_new_study$indic_is))

sort(unique(digital_new_study$ind_type))

sort(unique(digital_new_study$unit))


# =========================================================
# 7. VERIFICAREA POPULATIEI DE REFERINTA
#
# Scop:
# Verificam ce categorii de populatie exista EFECTIV
# pentru indicatorul "basic or above basic".
#
# Nu presupunem ca IND_TOTAL si Y16_74 exista ambele
# pentru indicatorul selectat.
# =========================================================


# ---------------------------------------------------------
# SERIA VECHE - 2017 si 2019
# ---------------------------------------------------------

digital_old_target <- digital_old_study %>%
  filter(
    indic_is == "I_DSK_BAB",
    unit == "PC_IND"
  )

# Vedem ce categorii de populatie exista efectiv
sort(unique(digital_old_target$ind_type))

# Vedem cate observatii exista pentru fiecare categorie
digital_old_target %>%
  count(ind_type, sort = TRUE)


# ---------------------------------------------------------
# SERIA NOUA - 2021
# ---------------------------------------------------------

digital_new_target <- digital_new_study %>%
  filter(
    indic_is == "I_DSK2_BAB",
    unit == "PC_IND"
  )

# Vedem ce categorii de populatie exista efectiv
sort(unique(digital_new_target$ind_type))

# Vedem cate observatii exista pentru fiecare categorie
digital_new_target %>%
  count(ind_type, sort = TRUE)



# =========================================================
# 9. IDENTIFICAREA POPULATIEI GENERALE
#
# Scop:
# Din multitudinea de subgrupuri disponibile verificam
# explicit daca exista:
#
# IND_TOTAL = totalul persoanelor din populatia de referinta
# Y16_74    = persoanele cu varsta 16-74 ani
#
# Facem verificarea separat pentru seria veche si seria noua.
# =========================================================


# ---------------------------------------------------------
# SERIA VECHE - 2017 si 2019
# ---------------------------------------------------------

digital_old_target %>%
  filter(ind_type %in% c("IND_TOTAL", "Y16_74")) %>%
  count(ind_type)


# Vedem valorile efective pentru aceste categorii
digital_old_target %>%
  filter(ind_type %in% c("IND_TOTAL", "Y16_74")) %>%
  select(
    geo,
    TIME_PERIOD,
    ind_type,
    values
  ) %>%
  arrange(geo, TIME_PERIOD, ind_type) %>%
  print(n = 20)


# ---------------------------------------------------------
# SERIA NOUA - 2021
# ---------------------------------------------------------

digital_new_target %>%
  filter(ind_type %in% c("IND_TOTAL", "Y16_74")) %>%
  count(ind_type)


# Vedem valorile efective pentru aceste categorii
digital_new_target %>%
  filter(ind_type %in% c("IND_TOTAL", "Y16_74")) %>%
  select(
    geo,
    TIME_PERIOD,
    ind_type,
    values
  ) %>%
  arrange(geo, TIME_PERIOD, ind_type) %>%
  print(n = 20)



# =========================================================
# 10. CONTROL GEOGRAFIC AL DATELOR
#
# Scop:
# Unitatea de analiza a disertatiei este TARA.
#
# Eurostat include in unele tabele si agregate geografice,
# de exemplu:
# EA          = zona euro
# EU27_2020   = Uniunea Europeana - agregat
#
# Acestea NU trebuie tratate ca tari in panel.
#
# Mai intai verificam ce coduri geografice exista.
# Nu eliminam nimic pana nu vedem rezultatul.
# =========================================================


# ---------------------------------------------------------
# 1. Adunam codurile geografice din toate variabilele
# reconstruite pana acum
# ---------------------------------------------------------

geo_audit <- bind_rows(
  
  educatie_superioara_new %>%
    distinct(country) %>%
    mutate(sursa = "educatie"),
  
  daily_internet_new %>%
    distinct(country) %>%
    mutate(sursa = "daily_internet"),
  
  internet_access_new %>%
    distinct(country) %>%
    mutate(sursa = "acces_internet"),
  
  social_media_new %>%
    distinct(country) %>%
    mutate(sursa = "social_media"),
  
  never_internet_new %>%
    distinct(country) %>%
    mutate(sursa = "nefolosire_internet"),
  
  digital_old_target %>%
    transmute(country = geo) %>%
    distinct(country) %>%
    mutate(sursa = "digital_old"),
  
  digital_new_target %>%
    transmute(country = geo) %>%
    distinct(country) %>%
    mutate(sursa = "digital_new")
)


# ---------------------------------------------------------
# 2. Afisam toate codurile geografice distincte
# ---------------------------------------------------------

sort(unique(geo_audit$country))


# ---------------------------------------------------------
# 3. Identificam codurile suspecte
#
# Tarile Eurostat au in general coduri de 2 litere.
# Marcăm:
# - codurile mai lungi de 2 caractere
# - EA si EU, care reprezinta agregate, nu tari
#
# Acesta este doar un diagnostic.
# ---------------------------------------------------------

geo_suspecte <- geo_audit %>%
  distinct(country) %>%
  filter(
    !grepl("^[A-Z]{2}$", country) |
      country %in% c("EA", "EU")
  ) %>%
  arrange(country)


# Afisam codurile suspecte
geo_suspecte



# =========================================================
# 11. ELIMINAREA AGREGATELOR GEOGRAFICE
#
# Scop:
# Unitatea de analiza a disertatiei este tara.
#
# Eliminam agregatele geografice identificate anterior:
# EA, EA21, EU15, EU27_2007, EU27_2020, EU28.
#
# Folosim lista obtinuta automat prin geo_suspecte,
# astfel incat codul sa ramana reproductibil.
# =========================================================


# Salvam codurile agregatelor intr-un vector
geo_agregate <- geo_suspecte$country

geo_agregate


# ---------------------------------------------------------
# CURATAM VARIABILELE RECONSTRUITE PANA ACUM
# ---------------------------------------------------------

educatie_superioara_new <- educatie_superioara_new %>%
  filter(!country %in% geo_agregate)

daily_internet_new <- daily_internet_new %>%
  filter(!country %in% geo_agregate)

internet_access_new <- internet_access_new %>%
  filter(!country %in% geo_agregate)

social_media_new <- social_media_new %>%
  filter(!country %in% geo_agregate)

never_internet_new <- never_internet_new %>%
  filter(!country %in% geo_agregate)


# ---------------------------------------------------------
# CURATAM SI DATELE PENTRU ABILITATI DIGITALE
#
# Aici coloana de tara se numeste inca "geo".
# ---------------------------------------------------------

digital_old_target <- digital_old_target %>%
  filter(!geo %in% geo_agregate)

digital_new_target <- digital_new_target %>%
  filter(!geo %in% geo_agregate)


# =========================================================
# 12. VERIFICARE DUPA CURATAREA GEOGRAFICA
#
# Scop:
# Confirmam ca niciun agregat UE / zona euro
# nu mai apare in datele care vor intra in panel.
# =========================================================

intersect(
  unique(educatie_superioara_new$country),
  geo_agregate
)

intersect(
  unique(daily_internet_new$country),
  geo_agregate
)

intersect(
  unique(internet_access_new$country),
  geo_agregate
)

intersect(
  unique(social_media_new$country),
  geo_agregate
)

intersect(
  unique(never_internet_new$country),
  geo_agregate
)

intersect(
  unique(digital_old_target$geo),
  geo_agregate
)

intersect(
  unique(digital_new_target$geo),
  geo_agregate
)


# =========================================================
# 13. CONSTRUIREA VARIABILEI ABILITATI DIGITALE
#
# Scop:
# Construim variabila finala "abilitati_digitale"
# folosita ulterior in panel.
#
# Folosim:
# 2017 si 2019 -> seria veche
#                 I_DSK_BAB
#
# 2021         -> seria noua
#                 I_DSK2_BAB
#
# Pentru ambele:
# ind_type = IND_TOTAL
# unit     = PC_IND
#
# Agregatele geografice au fost deja eliminate.
#
# Valorile raman exprimate procentual.
# =========================================================


# ---------------------------------------------------------
# 1. SERIA VECHE - 2017 si 2019
# ---------------------------------------------------------

abilitati_old_final <- digital_old_target %>%
  
  # Pastram populatia totala de referinta
  filter(
    ind_type == "IND_TOTAL"
  ) %>%
  
  # Pastram doar coloanele necesare pentru panel
  transmute(
    country = geo,
    year = TIME_PERIOD,
    abilitati_digitale = values,
    
    # Pastram si sursa pentru trasabilitate
    serie = "isoc_sk_dskl_i"
  )


# ---------------------------------------------------------
# 2. SERIA NOUA - 2021
# ---------------------------------------------------------

abilitati_new_final <- digital_new_target %>%
  
  filter(
    ind_type == "IND_TOTAL"
  ) %>%
  
  transmute(
    country = geo,
    year = TIME_PERIOD,
    abilitati_digitale = values,
    serie = "isoc_sk_dskl_i21"
  )


# ---------------------------------------------------------
# 3. COMBINAREA CELOR DOUA SERII
#
# Rezultatul va contine:
# country | year | abilitati_digitale | serie
# ---------------------------------------------------------

abilitati_digitale_new <- bind_rows(
  abilitati_old_final,
  abilitati_new_final
) %>%
  
  arrange(country, year)


# =========================================================
# 14. VERIFICAREA VARIABILEI ABILITATI DIGITALE
#
# Scop:
# Verificam daca variabila finala este construita corect.
# =========================================================


# ---------------------------------------------------------
# 1. Verificam anii disponibili
#
# Rezultatul asteptat:
# 2017 2019 2021
# ---------------------------------------------------------

sort(unique(abilitati_digitale_new$year))


# ---------------------------------------------------------
# 2. Verificam eventualele dubluri tara-an
#
# Rezultatul ideal:
# 0 randuri
# ---------------------------------------------------------

abilitati_digitale_new %>%
  count(country, year) %>%
  filter(n > 1)


# ---------------------------------------------------------
# 3. Statistici descriptive
# ---------------------------------------------------------

summary(
  abilitati_digitale_new$abilitati_digitale
)


# ---------------------------------------------------------
# 4. Numar total de observatii
# ---------------------------------------------------------

nrow(abilitati_digitale_new)


# ---------------------------------------------------------
# 5. Numar de tari
# ---------------------------------------------------------

length(
  unique(abilitati_digitale_new$country)
)


# ---------------------------------------------------------
# 6. Vedem cate observatii avem in fiecare an
# ---------------------------------------------------------

abilitati_digitale_new %>%
  count(year)


# ---------------------------------------------------------
# 7. Primele observatii
# ---------------------------------------------------------

head(abilitati_digitale_new, 20)


# =========================================================
# 15. DIAGNOSTIC FINAL - ABILITATI DIGITALE
#
# Scop:
# Verificam unde sunt cele doua valori lipsa si cum arata
# distributia indicatorului separat pentru fiecare an.
#
# Nu imputam valorile lipsa.
# Panelul poate ramane neechilibrat.
# =========================================================


# ---------------------------------------------------------
# 1. Identificam observatiile cu valori lipsa
# ---------------------------------------------------------

abilitati_digitale_new %>%
  filter(is.na(abilitati_digitale))


# ---------------------------------------------------------
# 2. Statistici separate pentru fiecare an
#
# Verificam:
# - numarul total de observatii
# - numarul de valori valide
# - media
# - minimul
# - maximul
# ---------------------------------------------------------

abilitati_digitale_new %>%
  group_by(year) %>%
  summarise(
    N_total = n(),
    N_valid = sum(!is.na(abilitati_digitale)),
    Medie = mean(abilitati_digitale, na.rm = TRUE),
    Minim = min(abilitati_digitale, na.rm = TRUE),
    Maxim = max(abilitati_digitale, na.rm = TRUE),
    .groups = "drop"
  )


# =========================================================
# 16. SALVAREA FINALA A VARIABILELOR EUROSTAT RECONSTRUITE
#
# Scop:
# Salvam versiunile CURATATE ale variabilelor.
#
# Important:
# Celelalte variabile au fost salvate anterior inainte de
# eliminarea agregatelor geografice.
#
# Prin urmare, le salvam din nou acum.
# Fisierele existente vor fi suprascrise cu versiunile corecte.
# =========================================================


# ---------------------------------------------------------
# 1. Pregatim abilitati_digitale pentru panel
#
# Coloana "serie" a fost utila pentru verificare,
# dar panelul final are nevoie doar de:
# country | year | abilitati_digitale
# ---------------------------------------------------------

abilitati_digitale_panel <- abilitati_digitale_new %>%
  select(
    country,
    year,
    abilitati_digitale
  )


# =========================================================
# 2. EDUCATIE SUPERIOARA
# =========================================================

saveRDS(
  educatie_superioara_new,
  "data/educatie_superioara.rds"
)

write.csv(
  educatie_superioara_new,
  "data/educatie_superioara.csv",
  row.names = FALSE
)


# =========================================================
# 3. UTILIZARE ZILNICA INTERNET
# =========================================================

saveRDS(
  daily_internet_new,
  "data/daily_internet_use.rds"
)

write.csv(
  daily_internet_new,
  "data/daily_internet_use.csv",
  row.names = FALSE
)


# =========================================================
# 4. ACCES INTERNET
# =========================================================

saveRDS(
  internet_access_new,
  "data/nivel_acces_internet.rds"
)

write.csv(
  internet_access_new,
  "data/nivel_acces_internet.csv",
  row.names = FALSE
)


# =========================================================
# 5. PARTICIPARE SOCIAL MEDIA
# =========================================================

saveRDS(
  social_media_new,
  "data/participare_social_media.rds"
)

write.csv(
  social_media_new,
  "data/participare_social_media.csv",
  row.names = FALSE
)


# =========================================================
# 6. NEFOLOSIRE INTERNET
# =========================================================

saveRDS(
  never_internet_new,
  "data/nefolosire_internet.rds"
)

write.csv(
  never_internet_new,
  "data/nefolosire_internet.csv",
  row.names = FALSE
)


# =========================================================
# 7. ABILITATI DIGITALE
# =========================================================

saveRDS(
  abilitati_digitale_panel,
  "data/abilitati_digitale.rds"
)

write.csv(
  abilitati_digitale_panel,
  "data/abilitati_digitale.csv",
  row.names = FALSE
)


# =========================================================
# 8. Salvam separat si varianta cu informatia despre serie
#
# Aceasta este utila pentru trasabilitate:
# putem vedea ulterior daca o observatie provine din
# seria veche sau din seria metodologic actualizata.
# =========================================================

saveRDS(
  abilitati_digitale_new,
  "data/abilitati_digitale_cu_serie.rds"
)

write.csv(
  abilitati_digitale_new,
  "data/abilitati_digitale_cu_serie.csv",
  row.names = FALSE
)


# =========================================================
# 17. CONTROLUL FISIERELOR SALVATE
# =========================================================

list.files("data")

file.exists("data/abilitati_digitale.rds")
file.exists("data/abilitati_digitale.csv")


# =========================================================
# 18. OECD IDD - VENIT MEDIU SI COEFICIENT GINI
#
# Scop:
# Reconstruim ultimele doua variabile ale disertatiei:
#
# - gini
# - venit_mediu_gospodarie
#
# Sursa declarata in disertatie:
# OECD Income Distribution Database (IDD)
#
# Perioada cercetarii:
# 2017-2022
#
# IMPORTANT:
# In aceasta etapa doar descarcam si inspectam datele.
# Nu construim inca variabilele finale.
# =========================================================


# =========================================================
# 1. GINI - OECD IDD
#
# Indicator:
# Gini coefficient of disposable income
#
# Caracteristici:
# - frecventa anuala
# - scala 0-1
# - populatie totala
# - metodologia OECD actuala
# - perioada 2017-2022
# =========================================================

url_gini_oecd <- paste0(
  "https://sdmx.oecd.org/public/rest/data/",
  "OECD.WISE.INE,DSD_WISE_IDD@DF_IDD,1.0/",
  ".A.INC_DISP_GINI..0_TO_1._T.METH2012.D_CUR.",
  "?startPeriod=2017&endPeriod=2022",
  "&dimensionAtObservation=AllDimensions",
  "&format=csvfilewithlabels"
)

# Descarcam datele direct din OECD
gini_oecd_raw <- read.csv(
  url_gini_oecd,
  check.names = FALSE
)


# =========================================================
# 2. VENIT MEDIU - OECD IDD
#
# Indicator:
# Disposable income, Arithmetic mean
#
# Pentru venit NU alegem inca unitatea.
# OECD contine mai multe unitati monetare.
#
# Descarcam variantele disponibile pentru populatia totala
# si identificam ulterior exact varianta PPP folosita.
# =========================================================

url_income_oecd <- paste0(
  "https://sdmx.oecd.org/public/rest/data/",
  "OECD.WISE.INE,DSD_WISE_IDD@DF_IDD,1.0/",
  ".A.INC_DISP.MEAN.._T.METH2012.D_CUR.",
  "?startPeriod=2017&endPeriod=2022",
  "&dimensionAtObservation=AllDimensions",
  "&format=csvfilewithlabels"
)

# Descarcam datele OECD
income_oecd_raw <- read.csv(
  url_income_oecd,
  check.names = FALSE
)


# =========================================================
# 3. VERIFICAREA STRUCTURII
#
# Scop:
# Vedem exact cum se numesc coloanele returnate de API
# si cum arata primele observatii.
#
# Nu filtram nimic pana nu vedem structura.
# =========================================================

names(gini_oecd_raw)
head(gini_oecd_raw)

names(income_oecd_raw)
head(income_oecd_raw)




# =========================================================
# 19. IDENTIFICAREA INDICATORULUI PPP IN OECD IDD
#
# Scop:
# Venitul disponibil este furnizat initial in moneda
# nationala per gospodarie echivalata.
#
# Pentru comparatii internationale avem nevoie de
# paritatea puterii de cumparare (PPP).
#
# Identificam mai intai codul exact al indicatorului PPP
# direct din baza OECD IDD.
#
# Folosim Austria doar pentru diagnostic, pentru ca astfel
# descarcam un volum mic de date.
# =========================================================


# ---------------------------------------------------------
# 1. Descarcam toate masurile OECD IDD pentru Austria
# in perioada 2017-2022
# ---------------------------------------------------------

url_oecd_audit <- paste0(
  "https://sdmx.oecd.org/public/rest/data/",
  "OECD.WISE.INE,DSD_WISE_IDD@DF_IDD,1.0/",
  "AUT.A.......",
  "?startPeriod=2017&endPeriod=2022",
  "&dimensionAtObservation=AllDimensions",
  "&format=csvfilewithlabels"
)

oecd_audit <- read.csv(
  url_oecd_audit,
  check.names = FALSE
)


# ---------------------------------------------------------
# 2. Cautam indicatorii care contin referinte la:
# - Purchasing Power
# - PPP
#
# Nu presupunem codul indicatorului.
# ---------------------------------------------------------

ppp_candidates <- oecd_audit %>%
  filter(
    grepl(
      "purchasing power|PPP",
      Measure,
      ignore.case = TRUE
    )
  ) %>%
  distinct(
    MEASURE,
    Measure,
    UNIT_MEASURE,
    `Unit of measure`,
    CURRENCY,
    Currency
  )


# Afisam candidatii
ppp_candidates


# =========================================================
# 20. VERIFICAREA COMPLETA A INDICATORULUI PPP
#
# Scop:
# Am identificat indicatorul corect:
#
# PPP_PRC = Purchasing Power Parities for private consumption
# XDC_USD = moneda nationala per dolar SUA
#
# Verificam acum toate dimensiunile asociate indicatorului,
# pentru a putea construi ulterior filtrul exact.
# =========================================================


# ---------------------------------------------------------
# 1. Vedem structura completa a randurilor PPP
# pentru Austria
# ---------------------------------------------------------

oecd_audit %>%
  filter(
    MEASURE == "PPP_PRC"
  ) %>%
  select(
    REF_AREA,
    `Reference area`,
    FREQ,
    MEASURE,
    `Measure`,
    STATISTICAL_OPERATION,
    `Statistical operation`,
    UNIT_MEASURE,
    `Unit of measure`,
    AGE,
    `Age`,
    METHODOLOGY,
    `Methodology`,
    DEFINITION,
    `Definition`,
    POVERTY_LINE,
    `Poverty line`,
    TIME_PERIOD,
    OBS_VALUE,
    CURRENCY,
    `Currency`
  ) %>%
  arrange(TIME_PERIOD)


# ---------------------------------------------------------
# 2. Verificam daca exista mai mult de un rand PPP
# pentru acelasi an
# ---------------------------------------------------------

oecd_audit %>%
  filter(
    MEASURE == "PPP_PRC"
  ) %>%
  count(TIME_PERIOD) %>%
  filter(n > 1)


# =========================================================
# 21. DESCARCAREA PPP PENTRU TOATE TARILE
#
# Scop:
# Descarcam indicatorul:
#
# PPP_PRC = Purchasing Power Parities for private consumption
#
# Folosim:
# UNIT_MEASURE = XDC_USD
# AGE          = _T (Total)
# METHODOLOGY  = METH2012
# DEFINITION   = D_CUR
#
# Perioada:
# 2017-2022
# =========================================================


url_ppp_oecd <- paste0(
  "https://sdmx.oecd.org/public/rest/data/",
  "OECD.WISE.INE,DSD_WISE_IDD@DF_IDD,1.0/",
  ".A.PPP_PRC._Z.XDC_USD._T.METH2012.D_CUR._Z",
  "?startPeriod=2017&endPeriod=2022",
  "&dimensionAtObservation=AllDimensions",
  "&format=csvfilewithlabels"
)


ppp_oecd_raw <- read.csv(
  url_ppp_oecd,
  check.names = FALSE
)


# =========================================================
# 22. VERIFICAREA PPP
# =========================================================

names(ppp_oecd_raw)

head(ppp_oecd_raw)


# Verificam dimensiunile importante
unique(ppp_oecd_raw$MEASURE)

unique(ppp_oecd_raw$UNIT_MEASURE)

unique(ppp_oecd_raw$AGE)

unique(ppp_oecd_raw$METHODOLOGY)

unique(ppp_oecd_raw$DEFINITION)


# Verificam daca exista dubluri tara-an
ppp_oecd_raw %>%
  count(REF_AREA, TIME_PERIOD) %>%
  filter(n > 1)


# =========================================================
# 23. VERIFICAREA FINALA A SERIEI DE VENIT OECD
#
# Scop:
# Confirmam ca seria de venit descarcata anterior reprezinta:
#
# MEASURE               = INC_DISP
# STATISTICAL_OPERATION = MEAN
# UNIT_MEASURE          = XDC_HH_EQ
# AGE                   = _T
# METHODOLOGY           = METH2012
# DEFINITION            = D_CUR
#
# Abia dupa aceasta verificare facem conversia PPP.
# =========================================================


unique(income_oecd_raw$MEASURE)

unique(income_oecd_raw$STATISTICAL_OPERATION)

unique(income_oecd_raw$UNIT_MEASURE)

unique(income_oecd_raw$AGE)

unique(income_oecd_raw$METHODOLOGY)

unique(income_oecd_raw$DEFINITION)


# ---------------------------------------------------------
# Verificam eventualele dubluri tara-an
# ---------------------------------------------------------

income_oecd_raw %>%
  count(REF_AREA, TIME_PERIOD) %>%
  filter(n > 1)



# =========================================================
# 24. CONSTRUIREA VENITULUI MEDIU IN USD PPP
#
# Formula:
# venit USD PPP =
# venit in moneda nationala / PPP pentru consum privat
# =========================================================


# Pregatim venitul in moneda nationala
income_local <- income_oecd_raw %>%
  transmute(
    country_oecd = REF_AREA,
    country_name = `Reference area`,
    year = TIME_PERIOD,
    venit_moneda_nationala = OBS_VALUE,
    moneda = CURRENCY
  ) %>%
  arrange(country_oecd, year)


# Pregatim PPP
ppp_final <- ppp_oecd_raw %>%
  transmute(
    country_oecd = REF_AREA,
    year = TIME_PERIOD,
    ppp = OBS_VALUE
  ) %>%
  arrange(country_oecd, year)


# Unim venitul cu PPP si calculam venitul comparabil
venit_mediu_gospodarie_new <- income_local %>%
  
  left_join(
    ppp_final,
    by = c("country_oecd", "year")
  ) %>%
  
  mutate(
    venit_mediu_gospodarie =
      venit_moneda_nationala / ppp
  ) %>%
  
  arrange(country_oecd, year)


# =========================================================
# 25. DIAGNOSTIC VENIT MEDIU USD PPP
# =========================================================


# Statistici descriptive
summary(
  venit_mediu_gospodarie_new$venit_mediu_gospodarie
)


# Cazuri unde exista venit, dar lipseste PPP
venit_mediu_gospodarie_new %>%
  filter(
    !is.na(venit_moneda_nationala),
    is.na(ppp)
  )


# Numar valori finale lipsa
sum(
  is.na(
    venit_mediu_gospodarie_new$venit_mediu_gospodarie
  )
)


# Dubluri tara-an
venit_mediu_gospodarie_new %>%
  count(country_oecd, year) %>%
  filter(n > 1)


# Interval temporal
range(
  venit_mediu_gospodarie_new$year,
  na.rm = TRUE
)


# Numar tari
length(
  unique(venit_mediu_gospodarie_new$country_oecd)
)


# Primele observatii
head(
  venit_mediu_gospodarie_new,
  20
)


# =========================================================
# 26. CONSTRUIREA VARIABILEI GINI OECD
#
# Indicator:
# Gini (disposable income)
#
# Scala este deja 0-1.
# Nu facem nicio transformare.
# =========================================================

gini_new <- gini_oecd_raw %>%
  transmute(
    country_oecd = REF_AREA,
    country_name = `Reference area`,
    year = TIME_PERIOD,
    gini = OBS_VALUE
  ) %>%
  arrange(country_oecd, year)


# =========================================================
# 27. DIAGNOSTIC GINI
# =========================================================

# Statistici descriptive
summary(gini_new$gini)

# Dubluri tara-an
gini_new %>%
  count(country_oecd, year) %>%
  filter(n > 1)

# Valori lipsa
sum(is.na(gini_new$gini))

# Perioada
range(gini_new$year, na.rm = TRUE)

# Numar tari
length(unique(gini_new$country_oecd))

# Primele observatii
head(gini_new, 20)



# =========================================================
# 28. ARMONIZAREA CODURILOR DE TARA OECD - EUROSTAT
#
# Scop:
# OECD foloseste in principal coduri ISO cu 3 litere:
#
# ROU = Romania
# DEU = Germany
# FRA = France
#
# Eurostat foloseste in principal coduri cu 2 litere:
#
# RO
# DE
# FR
#
# Pentru Grecia si Regatul Unit Eurostat foloseste:
#
# EL = Greece
# UK = United Kingdom
#
# Construim o conversie reproductibila.
# =========================================================


# ---------------------------------------------------------
# 1. Instalare / incarcare countrycode
# ---------------------------------------------------------

if (!requireNamespace("countrycode", quietly = TRUE)) {
  install.packages("countrycode")
}

library(countrycode)


# ---------------------------------------------------------
# 2. Construim corespondenta OECD -> cod compatibil Eurostat
# ---------------------------------------------------------

oecd_country_map <- bind_rows(
  
  venit_mediu_gospodarie_new %>%
    distinct(
      country_oecd,
      country_name
    ),
  
  gini_new %>%
    distinct(
      country_oecd,
      country_name
    )
  
) %>%
  
  distinct(
    country_oecd,
    country_name
  ) %>%
  
  mutate(
    
    # Convertim ISO3 -> ISO2
    country = countrycode(
      country_oecd,
      origin = "iso3c",
      destination = "iso2c"
    ),
    
    # Corectam exceptiile Eurostat
    country = case_when(
      country == "GR" ~ "EL",
      country == "GB" ~ "UK",
      TRUE ~ country
    )
  ) %>%
  
  arrange(country_oecd)


# Vedem maparea
oecd_country_map


# =========================================================
# 29. CONTROLUL MAPARII TARILOR
#
# Scop:
# Verificam daca:
# - exista tari OECD fara cod Eurostat
# - doua tari OECD au ajuns accidental la acelasi cod
# =========================================================


# Tari fara corespondent
oecd_country_map %>%
  filter(is.na(country))


# Coduri duplicate dupa conversie
oecd_country_map %>%
  count(country) %>%
  filter(n > 1)


# =========================================================
# 30. APLICAREA CODURILOR EUROSTAT LA VARIABILELE OECD
# =========================================================


# ---------------------------------------------------------
# VENIT
# ---------------------------------------------------------

venit_mediu_gospodarie_panel <- venit_mediu_gospodarie_new %>%
  left_join(
    oecd_country_map %>%
      select(country_oecd, country),
    by = "country_oecd"
  ) %>%
  select(
    country,
    year,
    venit_mediu_gospodarie
  ) %>%
  arrange(country, year)


# ---------------------------------------------------------
# GINI
# ---------------------------------------------------------

gini_panel <- gini_new %>%
  left_join(
    oecd_country_map %>%
      select(country_oecd, country),
    by = "country_oecd"
  ) %>%
  select(
    country,
    year,
    gini
  ) %>%
  arrange(country, year)



# =========================================================
# 31. VERIFICAREA SUPRAPUNERII EUROSTAT - OECD
#
# Scop:
# Vedem ce tari apar simultan in cele doua surse.
# =========================================================


# Tari disponibile in Eurostat
tari_eurostat <- sort(
  unique(
    c(
      educatie_superioara_new$country,
      daily_internet_new$country,
      internet_access_new$country,
      social_media_new$country,
      never_internet_new$country,
      abilitati_digitale_panel$country
    )
  )
)


# Tari disponibile in OECD
tari_oecd <- sort(
  unique(
    c(
      venit_mediu_gospodarie_panel$country,
      gini_panel$country
    )
  )
)


# Tari comune
tari_comune <- intersect(
  tari_eurostat,
  tari_oecd
)

tari_comune

length(tari_comune)


# Tari Eurostat care nu apar in OECD
setdiff(
  tari_eurostat,
  tari_oecd
)


# Tari OECD care nu apar in Eurostat
setdiff(
  tari_oecd,
  tari_eurostat
)


# =========================================================
# 32. SALVAREA VARIABILELOR OECD RECONSTRUITE
#
# Scop:
# Salvam cele doua variabile OECD in forma compatibila
# cu variabilele Eurostat:
#
# country | year | variabila
# =========================================================


# ---------------------------------------------------------
# VENIT MEDIU GOSPODARIE - USD PPP
# ---------------------------------------------------------

saveRDS(
  venit_mediu_gospodarie_panel,
  "data/venit_mediu_gospodarie.rds"
)

write.csv(
  venit_mediu_gospodarie_panel,
  "data/venit_mediu_gospodarie.csv",
  row.names = FALSE
)


# ---------------------------------------------------------
# GINI
# ---------------------------------------------------------

saveRDS(
  gini_panel,
  "data/gini.rds"
)

write.csv(
  gini_panel,
  "data/gini.csv",
  row.names = FALSE
)




# =========================================================
# 33. CONSTRUIREA PANELULUI COMPLET
#
# Scop:
# Unim toate cele 8 variabile pe:
#
# country + year
#
# Folosim full_join pentru a NU elimina prematur
# observatiile care lipsesc din anumite surse.
#
# Panelul ramane neechilibrat.
# =========================================================


panel_reconstruit <- list(
  
  social_media_new,
  
  daily_internet_new,
  
  venit_mediu_gospodarie_panel,
  
  gini_panel,
  
  educatie_superioara_new,
  
  abilitati_digitale_panel,
  
  internet_access_new,
  
  never_internet_new
  
) %>%
  
  purrr::reduce(
    full_join,
    by = c("country", "year")
  ) %>%
  
  # Control suplimentar al perioadei cercetarii
  filter(
    year >= 2017,
    year <= 2022
  ) %>%
  
  arrange(country, year)

# =========================================================
# 34. DIAGNOSTICUL PANELULUI RECONSTRUIT
# =========================================================


# Dimensiunea panelului
dim(panel_reconstruit)


# Numar de tari
length(
  unique(panel_reconstruit$country)
)


# Perioada
range(
  panel_reconstruit$year,
  na.rm = TRUE
)


# Verificam dubluri tara-an
panel_reconstruit %>%
  count(country, year) %>%
  filter(n > 1)


# Numar de valori lipsa pentru fiecare variabila
colSums(
  is.na(panel_reconstruit)
)


# =========================================================
# 35. ESANTIONUL COMPLET PENTRU ANALIZA EMPIRICA
#
# Scop:
# Pastram doar observatiile tara-an pentru care sunt
# disponibile TOATE cele 8 variabile principale.
#
# Acest esantion va putea fi comparat cu vechiul N = 68.
# =========================================================


panel_complete <- panel_reconstruit %>%
  
  tidyr::drop_na(
    participare_social_media,
    daily_internet_use,
    venit_mediu_gospodarie,
    gini,
    educatie_superioara,
    abilitati_digitale,
    nivel_acces_internet,
    nefolosire_internet
  )


# Numar observatii complete
nrow(panel_complete)


# Numar tari
length(
  unique(panel_complete$country)
)


# Anii ramasi
sort(
  unique(panel_complete$year)
)


# Cate observatii complete avem pe fiecare an
panel_complete %>%
  count(year)


# Cate observatii complete avem pentru fiecare tara
panel_complete %>%
  count(country) %>%
  arrange(country)



# =========================================================
# 36. STATISTICI DESCRIPTIVE - ESANTION COMPLET
#
# Scop:
# Comparam noul esantion complet (N = 82)
# cu valorile raportate in vechea disertatie (N = 68).
# =========================================================

statistici_reconstructie <- panel_complete %>%
  summarise(
    
    # Abilitati digitale
    abil_N = n(),
    abil_medie = mean(abilitati_digitale),
    abil_sd = sd(abilitati_digitale),
    abil_min = min(abilitati_digitale),
    abil_max = max(abilitati_digitale),
    
    # Utilizare zilnica internet
    daily_medie = mean(daily_internet_use),
    daily_sd = sd(daily_internet_use),
    daily_min = min(daily_internet_use),
    daily_max = max(daily_internet_use),
    
    # Educatie superioara
    edu_medie = mean(educatie_superioara),
    edu_sd = sd(educatie_superioara),
    edu_min = min(educatie_superioara),
    edu_max = max(educatie_superioara),
    
    # Gini
    gini_medie = mean(gini),
    gini_sd = sd(gini),
    gini_min = min(gini),
    gini_max = max(gini),
    
    # Nefolosire internet
    never_medie = mean(nefolosire_internet),
    never_sd = sd(nefolosire_internet),
    never_min = min(nefolosire_internet),
    never_max = max(nefolosire_internet),
    
    # Acces internet
    access_medie = mean(nivel_acces_internet),
    access_sd = sd(nivel_acces_internet),
    access_min = min(nivel_acces_internet),
    access_max = max(nivel_acces_internet),
    
    # Social media
    social_medie = mean(participare_social_media),
    social_sd = sd(participare_social_media),
    social_min = min(participare_social_media),
    social_max = max(participare_social_media),
    
    # Venit
    venit_medie = mean(venit_mediu_gospodarie),
    venit_sd = sd(venit_mediu_gospodarie),
    venit_min = min(venit_mediu_gospodarie),
    venit_max = max(venit_mediu_gospodarie)
  )

statistici_reconstructie

# =========================================================
# 37. AFISAREA COMPLETA A STATISTICILOR RECONSTRUITE
# =========================================================

statistici_reconstructie %>%
  print(width = Inf)



# =========================================================
# 39. IDENTIFICAREA DIFERENTELOR FATA DE ESANTIONUL VECHI
#
# Scop:
# Vedem cate observatii din panelul actual au valori
# care nu puteau exista in vechiul esantion N = 68,
# deoarece depasesc minimul/maximul raportat atunci.
#
# IMPORTANT:
# Este doar un diagnostic.
# Nu eliminam nimic.
# =========================================================

audit_esantion <- panel_complete %>%
  mutate(
    outside_abil =
      abilitati_digitale < 34.11 |
      abilitati_digitale > 85.18,
    
    outside_daily =
      daily_internet_use < 56.85 |
      daily_internet_use > 95.36,
    
    outside_gini =
      gini < 0.217 |
      gini > 0.415,
    
    outside_never =
      nefolosire_internet < 0.07 |
      nefolosire_internet > 33.15,
    
    outside_access =
      nivel_acces_internet < 70.96 |
      nivel_acces_internet > 99.18,
    
    outside_social =
      participare_social_media < 42.30 |
      participare_social_media > 88.28,
    
    outside_venit =
      venit_mediu_gospodarie < 14579 |
      venit_mediu_gospodarie > 43780,
    
    outside_any =
      outside_abil |
      outside_daily |
      outside_gini |
      outside_never |
      outside_access |
      outside_social |
      outside_venit
  )


# Cate observatii ies din fiecare interval vechi?
audit_esantion %>%
  summarise(
    abilitati = sum(outside_abil),
    daily = sum(outside_daily),
    gini = sum(outside_gini),
    nefolosire = sum(outside_never),
    acces = sum(outside_access),
    social = sum(outside_social),
    venit = sum(outside_venit),
    total_randuri_suspecte = sum(outside_any)
  )


# Care sunt observatiile respective?
audit_esantion %>%
  filter(outside_any) %>%
  select(
    country,
    year,
    abilitati_digitale,
    daily_internet_use,
    gini,
    nefolosire_internet,
    nivel_acces_internet,
    participare_social_media,
    venit_mediu_gospodarie,
    outside_abil,
    outside_daily,
    outside_gini,
    outside_never,
    outside_access,
    outside_social,
    outside_venit
  ) %>%
  arrange(country, year) %>%
  print(n = Inf)


# =========================================================
# 40. STRUCTURA ESANTIONULUI COMPLET PE TARI
#
# Scop:
# Verificam cate observatii temporale are fiecare tara.
#
# Pentru Fixed Effects este important ca o tara sa aiba
# cel putin doua observatii pentru a exista variatie
# in timp ("within").
# =========================================================


structura_tari <- panel_complete %>%
  count(
    country,
    name = "n_observatii"
  ) %>%
  arrange(
    n_observatii,
    country
  )


# Afisam toate cele 30 de tari
structura_tari %>%
  print(n = Inf)


# Cate tari au 1, 2 sau 3 observatii?
structura_tari %>%
  count(
    n_observatii,
    name = "numar_tari"
  )


# Tari cu mai putin de doua observatii
structura_tari %>%
  filter(
    n_observatii < 2
  )

# =========================================================
# 41. AUDITUL DIFERENTEI PENTRU VENIT
#
# Scop:
# Vedem CE tari si ani explica valorile care sunt in afara
# intervalului raportat in vechea disertatie.
#
# Nu eliminam aceste observatii.
# =========================================================


audit_esantion %>%
  filter(
    outside_venit
  ) %>%
  select(
    country,
    year,
    venit_mediu_gospodarie
  ) %>%
  arrange(
    venit_mediu_gospodarie
  ) %>%
  print(n = Inf)

# =========================================================
# 42. VERIFICAREA TARILOR CU O SINGURA OBSERVATIE
#
# Scop:
# Vedem exact ce observatii au ramas pentru Franta si
# Ungaria in esantionul complet.
# =========================================================

panel_complete %>%
  filter(
    country %in% c("FR", "HU")
  ) %>%
  arrange(country, year) %>%
  print(width = Inf)


# =========================================================
# 43. TEST DIAGNOSTIC PENTRU VECHIUL ESANTION N = 68
#
# IMPORTANT:
# Acest esantion NU devine automat baza finala.
# Verificam doar daca cele 14 observatii din afara
# intervalului vechi al venitului explica vechiul N = 68.
# =========================================================

panel_68_diagnostic <- audit_esantion %>%
  
  filter(
    outside_venit == FALSE
  ) %>%
  
  select(
    country,
    year,
    participare_social_media,
    daily_internet_use,
    venit_mediu_gospodarie,
    gini,
    educatie_superioara,
    abilitati_digitale,
    nivel_acces_internet,
    nefolosire_internet
  )


# Numar total observatii
nrow(panel_68_diagnostic)


# Numar tari
length(
  unique(panel_68_diagnostic$country)
)


# Observatii pe ani
panel_68_diagnostic %>%
  count(year)


# Structura pe tari
panel_68_diagnostic %>%
  count(
    country,
    name = "n_observatii"
  ) %>%
  arrange(
    n_observatii,
    country
  ) %>%
  print(n = Inf)


# =========================================================
# 44. STATISTICI PE ESANTIONUL DIAGNOSTIC N = 68
#
# Scop:
# Verificam daca acest esantion reproduce statisticile
# descriptive raportate in vechea disertatie.
#
# Educatia nu este comparabila direct deoarece variabila
# actuala a fost reconstruita pe o definitie/scara corectata.
# =========================================================

statistici_68_diagnostic <- panel_68_diagnostic %>%
  summarise(
    
    # Abilitati digitale
    abil_medie = mean(abilitati_digitale),
    abil_sd = sd(abilitati_digitale),
    abil_min = min(abilitati_digitale),
    abil_max = max(abilitati_digitale),
    
    # Utilizare zilnica internet
    daily_medie = mean(daily_internet_use),
    daily_sd = sd(daily_internet_use),
    daily_min = min(daily_internet_use),
    daily_max = max(daily_internet_use),
    
    # Gini
    gini_medie = mean(gini),
    gini_sd = sd(gini),
    gini_min = min(gini),
    gini_max = max(gini),
    
    # Nefolosire internet
    never_medie = mean(nefolosire_internet),
    never_sd = sd(nefolosire_internet),
    never_min = min(nefolosire_internet),
    never_max = max(nefolosire_internet),
    
    # Acces internet
    access_medie = mean(nivel_acces_internet),
    access_sd = sd(nivel_acces_internet),
    access_min = min(nivel_acces_internet),
    access_max = max(nivel_acces_internet),
    
    # Social media
    social_medie = mean(participare_social_media),
    social_sd = sd(participare_social_media),
    social_min = min(participare_social_media),
    social_max = max(participare_social_media),
    
    # Venit
    venit_medie = mean(venit_mediu_gospodarie),
    venit_sd = sd(venit_mediu_gospodarie),
    venit_min = min(venit_mediu_gospodarie),
    venit_max = max(venit_mediu_gospodarie)
  )

statistici_68_diagnostic %>%
  print(width = Inf)


# =========================================================
# 45. ESANTIONUL FINAL PENTRU MODELELE FIXED EFFECTS
#
# Scop:
# Pentru FE pastram doar tarile cu minimum doua
# observatii complete in timp.
#
# Tarile cu o singura observatie nu pot contribui la
# estimarea variatiei "within".
# =========================================================

panel_fe <- panel_complete %>%
  
  group_by(country) %>%
  
  filter(
    n() >= 2
  ) %>%
  
  ungroup() %>%
  
  arrange(country, year)


# Verificari
nrow(panel_fe)

length(
  unique(panel_fe$country)
)

panel_fe %>%
  count(year)

panel_fe %>%
  count(country) %>%
  arrange(country) %>%
  print(n = Inf)

# =========================================================
# 46. SALVAREA BAZELOR RECONSTRUITE
#
# Scop:
# Salvam separat:
# 1. esantionul complet actual - N = 82
# 2. esantionul utilizabil pentru FE - N = 80
# 3. panelul general cu valori lipsa
# =========================================================


# Esantion complet
saveRDS(
  panel_complete,
  "data/panel_complete_final.rds"
)

write.csv(
  panel_complete,
  "data/panel_complete_final.csv",
  row.names = FALSE
)


# Esantion Fixed Effects
saveRDS(
  panel_fe,
  "data/panel_fe_final.rds"
)

write.csv(
  panel_fe,
  "data/panel_fe_final.csv",
  row.names = FALSE
)


# Panel general
saveRDS(
  panel_reconstruit,
  "data/panel_reconstruit_final.rds"
)

write.csv(
  panel_reconstruit,
  "data/panel_reconstruit_final.csv",
  row.names = FALSE
)


# =========================================================
# 47. DEFINIREA STRUCTURII PANEL PENTRU FIXED EFFECTS
#
# Scop:
# Transformam baza intr-un obiect pdata.frame.
# country = unitatea individuala
# year    = dimensiunea temporala
# =========================================================

install.packages("plm")
install.packages(c("lmtest", "sandwich"))

library(plm)
library(lmtest)
library(sandwich)


pdata_fe <- pdata.frame(
  panel_fe,
  index = c("country", "year")
)


# Diagnostic
pdim(pdata_fe)

is.pbalanced(pdata_fe)


# =========================================================
# 48. MODELUL 1 - PARTICIPARE SOCIAL MEDIA
#
# Scop:
# Estimam modelul Fixed Effects pentru participarea
# la retelele de socializare.
#
# Modelul foloseste variatia in timp din interiorul
# fiecarei tari.
# =========================================================


fe_social <- plm(
  
  participare_social_media ~
    daily_internet_use +
    venit_mediu_gospodarie +
    gini +
    educatie_superioara +
    abilitati_digitale +
    nivel_acces_internet +
    nefolosire_internet,
  
  data = pdata_fe,
  
  model = "within",
  
  effect = "individual"
)


# Rezultatele modelului FE
summary(fe_social)


# =========================================================
# 49. RANDOM EFFECTS + TEST HAUSMAN
#     MODEL PARTICIPARE SOCIAL MEDIA
#
# Scop:
# Comparam Fixed Effects cu Random Effects.
#
# H0: Random Effects este consistent.
# H1: Random Effects nu este consistent.
#
# Daca p < 0.05 -> preferam Fixed Effects.
# =========================================================


re_social <- plm(
  
  participare_social_media ~
    daily_internet_use +
    venit_mediu_gospodarie +
    gini +
    educatie_superioara +
    abilitati_digitale +
    nivel_acces_internet +
    nefolosire_internet,
  
  data = pdata_fe,
  
  model = "random",
  
  effect = "individual"
)


# Test Hausman
haus_social <- phtest(
  fe_social,
  re_social
)


haus_social


# =========================================================
# 50. ERORI STANDARD ROBUSTE
#     MODEL PARTICIPARE SOCIAL MEDIA
#
# Scop:
# Calculam erori standard robuste la heteroscedasticitate
# si dependenta observatiilor in interiorul aceleiasi tari.
#
# Aceste p-value-uri vor fi utilizate pentru interpretarea
# finala a modelului FE.
# =========================================================

robust_social <- coeftest(
  
  fe_social,
  
  vcov = vcovHC(
    fe_social,
    method = "arellano",
    type = "HC1",
    cluster = "group"
  )
)

robust_social


# =========================================================
# 51. MODELUL 2 - UTILIZARE ZILNICA INTERNET
#
# Scop:
# Estimam relatia dintre factorii socio-economici/digitali
# si utilizarea zilnica a internetului.
# =========================================================

fe_daily <- plm(
  
  daily_internet_use ~
    venit_mediu_gospodarie +
    gini +
    educatie_superioara +
    abilitati_digitale +
    nivel_acces_internet +
    nefolosire_internet,
  
  data = pdata_fe,
  model = "within",
  effect = "individual"
)

summary(fe_daily)


# =========================================================
# 52. RANDOM EFFECTS + TEST HAUSMAN
#     MODEL UTILIZARE ZILNICA INTERNET
# =========================================================

re_daily <- plm(
  
  daily_internet_use ~
    venit_mediu_gospodarie +
    gini +
    educatie_superioara +
    abilitati_digitale +
    nivel_acces_internet +
    nefolosire_internet,
  
  data = pdata_fe,
  model = "random",
  effect = "individual"
)


haus_daily <- phtest(
  fe_daily,
  re_daily
)

haus_daily


# =========================================================
# 53. ERORI STANDARD ROBUSTE
#     MODEL UTILIZARE ZILNICA INTERNET
# =========================================================

robust_daily <- coeftest(
  
  fe_daily,
  
  vcov = vcovHC(
    fe_daily,
    method = "arellano",
    type = "HC1",
    cluster = "group"
  )
)

robust_daily


# =========================================================
# 54. TABEL COMPARATIV - REZULTATE FE NOI
#
# Scop:
# Centralizam coeficientii si erorile robuste pentru
# cele doua modele reconstruite.
# =========================================================

rezultate_fe_noi <- data.frame(
  
  Variabila = c(
    "Utilizare zilnica internet",
    "Venit mediu gospodarie",
    "Gini",
    "Educatie superioara",
    "Abilitati digitale",
    "Acces internet",
    "Nefolosire internet"
  ),
  
  Social_Coef = c(
    0.69722371,
    0.00059216,
    2.38830868,
    -0.74280846,
    0.12352202,
    0.46236986,
    0.63194888
  ),
  
  Social_SE = c(
    0.24324384,
    0.00027277,
    41.45051575,
    0.36649472,
    0.07082524,
    0.20585227,
    0.33711018
  ),
  
  Daily_Coef = c(
    NA,
    0.00033498,
    -4.56613850,
    0.18333514,
    0.13837194,
    0.06376055,
    -1.06030460
  ),
  
  Daily_SE = c(
    NA,
    0.00008777,
    27.77821612,
    0.17651491,
    0.04490042,
    0.11286695,
    0.11274198
  )
)

rezultate_fe_noi


# =========================================================
# 55. TABEL FINAL FE GENERAT AUTOMAT
#
# Scop:
# Extragem direct din modelele robuste:
# - coeficientul
# - eroarea standard robusta
# - p-value
# - nivelul de semnificatie
#
# Conventia folosita in disertatie:
# *   p < 0.10
# **  p < 0.05
# *** p < 0.01
# =========================================================


# Functie pentru extragerea rezultatelor din coeftest
extrage_rezultate <- function(model_robust, nume_model) {
  
  rezultat <- data.frame(
    
    variabila_cod = rownames(model_robust),
    
    coeficient = model_robust[, 1],
    
    eroare_standard = model_robust[, 2],
    
    p_value = model_robust[, 4],
    
    row.names = NULL
  )
  
  
  # Adaugam stelutele conform conventiei din disertatie
  rezultat <- rezultat %>%
    mutate(
      
      semnificatie = case_when(
        p_value < 0.01 ~ "***",
        p_value < 0.05 ~ "**",
        p_value < 0.10 ~ "*",
        TRUE ~ ""
      ),
      
      model = nume_model
    )
  
  
  return(rezultat)
}




# Model social media
rezultate_social <- extrage_rezultate(
  robust_social,
  "Participare social media"
)


# Model utilizare zilnica internet
rezultate_daily <- extrage_rezultate(
  robust_daily,
  "Utilizare zilnica internet"
)


rezultate_social

rezultate_daily


# =========================================================
# 56. COMBINAREA CELOR DOUA MODELE
#
# Scop:
# Construim un singur tabel care contine pentru fiecare
# variabila:
# - coeficientul
# - eroarea standard robusta
# - p-value
# - nivelul de semnificatie
#
# pentru ambele modele FE.
# =========================================================


tabel_social <- rezultate_social %>%
  
  select(
    variabila_cod,
    Social_Coef = coeficient,
    Social_SE = eroare_standard,
    Social_p = p_value,
    Social_sig = semnificatie
  )


tabel_daily <- rezultate_daily %>%
  
  select(
    variabila_cod,
    Daily_Coef = coeficient,
    Daily_SE = eroare_standard,
    Daily_p = p_value,
    Daily_sig = semnificatie
  )


# Combinam cele doua modele dupa numele variabilei
rezultate_fe_final <- full_join(
  tabel_social,
  tabel_daily,
  by = "variabila_cod"
) %>%
  
  # Transformam denumirile tehnice in denumiri clare
  mutate(
    
    Variabila = recode(
      variabila_cod,
      
      daily_internet_use = "Utilizare zilnica internet",
      venit_mediu_gospodarie = "Venit mediu gospodarie",
      gini = "Gini",
      educatie_superioara = "Educatie superioara",
      abilitati_digitale = "Abilitati digitale",
      nivel_acces_internet = "Acces internet",
      nefolosire_internet = "Nefolosire internet"
    )
  ) %>%
  
  select(
    Variabila,
    
    Social_Coef,
    Social_SE,
    Social_p,
    Social_sig,
    
    Daily_Coef,
    Daily_SE,
    Daily_p,
    Daily_sig
  )


# Afisam tabelul complet
rezultate_fe_final %>%
  tibble::as_tibble() %>%
  print(width = Inf)


# =========================================================
# 57. INDICATORI GENERALI AI MODELELOR FE
#
# Scop:
# Centralizam informatiile generale ale celor doua modele:
# - numarul de observatii
# - R2 within
# - R2 ajustat
# - testul Hausman
# =========================================================

indicatori_modele_fe <- data.frame(
  
  Model = c(
    "Participare social media",
    "Utilizare zilnica internet"
  ),
  
  # Numarul de observatii utilizate
  N = c(
    nobs(fe_social),
    nobs(fe_daily)
  ),
  
  # R2 within
  R2_within = c(
    unname(summary(fe_social)$r.squared["rsq"]),
    unname(summary(fe_daily)$r.squared["rsq"])
  ),
  
  # R2 ajustat
  R2_ajustat = c(
    unname(summary(fe_social)$r.squared["adjrsq"]),
    unname(summary(fe_daily)$r.squared["adjrsq"])
  ),
  
  # Statistica Hausman
  Hausman_chi2 = c(
    unname(haus_social$statistic),
    unname(haus_daily$statistic)
  ),
  
  # Grade de libertate
  Hausman_df = c(
    unname(haus_social$parameter),
    unname(haus_daily$parameter)
  ),
  
  # p-value Hausman
  Hausman_p = c(
    haus_social$p.value,
    haus_daily$p.value
  )
)


indicatori_modele_fe %>%
  tibble::as_tibble() %>%
  print(width = Inf)

# =========================================================
# 58. SALVAREA REZULTATELOR FIXED EFFECTS
#
# Scop:
# Salvam tabelele finale rezultate din analiza FE pentru
# utilizare ulterioara in disertatie si pentru verificari.
# =========================================================


# Rezultatele coeficientilor robusti
saveRDS(
  rezultate_fe_final,
  "results/rezultate_fe_final.rds"
)

write.csv(
  rezultate_fe_final,
  "results/rezultate_fe_final.csv",
  row.names = FALSE
)


# Indicatorii generali ai modelelor
saveRDS(
  indicatori_modele_fe,
  "results/indicatori_modele_fe.rds"
)

write.csv(
  indicatori_modele_fe,
  "results/indicatori_modele_fe.csv",
  row.names = FALSE
)


# =========================================================
# 59. TABEL FE IN FORMAT PENTRU DISERTATIE
#
# Conventie:
# *   p < 0.10
# **  p < 0.05
# *** p < 0.01
# =========================================================


tabel_fe_disertatie <- rezultate_fe_final %>%
  
  mutate(
    
    Social = ifelse(
      is.na(Social_Coef),
      "",
      paste0(
        sprintf("%.3f", Social_Coef),
        Social_sig,
        " (",
        sprintf("%.3f", Social_SE),
        ")"
      )
    ),
    
    Daily = ifelse(
      is.na(Daily_Coef),
      "",
      paste0(
        sprintf("%.3f", Daily_Coef),
        Daily_sig,
        " (",
        sprintf("%.3f", Daily_SE),
        ")"
      )
    )
  ) %>%
  
  select(
    Variabila,
    Social,
    Daily
  )


tabel_fe_disertatie %>%
  tibble::as_tibble() %>%
  print(width = Inf)


# =========================================================
# 60. FORMATAREA FINALA A TABELULUI FE
#
# Scop:
# Construim tabelul in forma potrivita pentru disertatie.
#
# Regula de rotunjire:
# - venitul: 6 zecimale
# - celelalte variabile: 3 zecimale
#
# Conventie semnificatie:
# *   p < 0.10
# **  p < 0.05
# *** p < 0.01
# =========================================================


tabel_fe_final <- rezultate_fe_final %>%
  
  rowwise() %>%
  
  mutate(
    
    # -------------------------
    # MODEL SOCIAL MEDIA
    # -------------------------
    
    Social = if (
      is.na(Social_Coef)
    ) {
      
      ""
      
    } else if (
      Variabila == "Venit mediu gospodarie"
    ) {
      
      paste0(
        sprintf("%.6f", Social_Coef),
        Social_sig,
        " (",
        sprintf("%.6f", Social_SE),
        ")"
      )
      
    } else {
      
      paste0(
        sprintf("%.3f", Social_Coef),
        Social_sig,
        " (",
        sprintf("%.3f", Social_SE),
        ")"
      )
    },
    
    
    # -------------------------
    # MODEL DAILY INTERNET
    # -------------------------
    
    Daily = if (
      is.na(Daily_Coef)
    ) {
      
      ""
      
    } else if (
      Variabila == "Venit mediu gospodarie"
    ) {
      
      paste0(
        sprintf("%.6f", Daily_Coef),
        Daily_sig,
        " (",
        sprintf("%.6f", Daily_SE),
        ")"
      )
      
    } else {
      
      paste0(
        sprintf("%.3f", Daily_Coef),
        Daily_sig,
        " (",
        sprintf("%.3f", Daily_SE),
        ")"
      )
    }
  ) %>%
  
  ungroup() %>%
  
  select(
    Variabila,
    Social,
    Daily
  )


# =========================================================
# 61. ADAUGAREA INDICATORILOR GENERALI IN TABEL
# =========================================================


indicatori_tabel <- data.frame(
  
  Variabila = c(
    "N",
    "R² within",
    "R² ajustat"
  ),
  
  Social = c(
    as.character(nobs(fe_social)),
    sprintf("%.3f", summary(fe_social)$r.squared["rsq"]),
    sprintf("%.3f", summary(fe_social)$r.squared["adjrsq"])
  ),
  
  Daily = c(
    as.character(nobs(fe_daily)),
    sprintf("%.3f", summary(fe_daily)$r.squared["rsq"]),
    sprintf("%.3f", summary(fe_daily)$r.squared["adjrsq"])
  )
)


# Adaugam indicatorii sub coeficienti
tabel_fe_final <- bind_rows(
  tabel_fe_final,
  indicatori_tabel
)


tabel_fe_final %>%
  tibble::as_tibble() %>%
  print(width = Inf)

# =========================================================
# 62. SALVAREA TABELULUI FE FINAL PENTRU DISERTATIE
#
# Scop:
# Salvam tabelul final cu coeficientii, erorile standard
# robuste si indicatorii generali ai celor doua modele.
# =========================================================

write.csv(
  tabel_fe_final,
  "results/tabel_fe_final_disertatie.csv",
  row.names = FALSE
)

saveRDS(
  tabel_fe_final,
  "results/tabel_fe_final_disertatie.rds"
)

# =========================================================
# 63. TABEL FINAL TESTE HAUSMAN
# =========================================================

tabel_hausman_final <- data.frame(
  
  Model = c(
    "Participare social media",
    "Utilizare zilnica internet"
  ),
  
  Chi2 = c(
    unname(haus_social$statistic),
    unname(haus_daily$statistic)
  ),
  
  df = c(
    unname(haus_social$parameter),
    unname(haus_daily$parameter)
  ),
  
  p_value = c(
    haus_social$p.value,
    haus_daily$p.value
  )
)


tabel_hausman_final %>%
  tibble::as_tibble() %>%
  print(width = Inf)


write.csv(
  tabel_hausman_final,
  "results/tabel_hausman_final.csv",
  row.names = FALSE
)