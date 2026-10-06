# ============================================================
# TRAVEL COST OPTIMIZER
# R STATISTICAL ANALYSIS
# ============================================================

# ------------------------------------------------------------
# PROJECT PATH
# ------------------------------------------------------------

BASE_DIR <- "D:/Travel-Cost-Optimizer"

DATA_DIR <- file.path(
  BASE_DIR,
  "data",
  "processed"
)


# ------------------------------------------------------------
# LOAD DATASETS
# ------------------------------------------------------------

flights <- read.csv(
  file.path(DATA_DIR, "flights.csv"),
  stringsAsFactors = FALSE
)

hotels <- read.csv(
  file.path(DATA_DIR, "hotels.csv"),
  stringsAsFactors = FALSE
)

tourism <- read.csv(
  file.path(DATA_DIR, "tourism.csv"),
  stringsAsFactors = FALSE
)

food <- read.csv(
  file.path(DATA_DIR, "food.csv"),
  stringsAsFactors = FALSE
)

fuel <- read.csv(
  file.path(DATA_DIR, "fuel_prices.csv"),
  stringsAsFactors = FALSE
)


# ============================================================
# BASIC DATASET ANALYSIS
# ============================================================

cat("\n")
cat("======================================================================\n")
cat("TRAVEL COST OPTIMIZER - R STATISTICAL ANALYSIS\n")
cat("======================================================================\n")


# ------------------------------------------------------------
# DATASET SUMMARY
# ------------------------------------------------------------

cat("\nDATASET SUMMARY\n")
cat("----------------------------------------------------------------------\n")

cat(
  "Flights Records       :", nrow(flights), "\n"
)

cat(
  "Hotels Records        :", nrow(hotels), "\n"
)

cat(
  "Tourism Records       :", nrow(tourism), "\n"
)

cat(
  "Food Records          :", nrow(food), "\n"
)

cat(
  "Fuel Records          :", nrow(fuel), "\n"
)


# ============================================================
# FLIGHT ANALYSIS
# ============================================================

cat("\n")
cat("======================================================================\n")
cat("FLIGHT COST ANALYSIS\n")
cat("======================================================================\n")

flight_prices <- flights$price

cat(
  "Average Flight Price  : ₹",
  round(mean(flight_prices, na.rm = TRUE), 2),
  "\n",
  sep = ""
)

cat(
  "Minimum Flight Price  : ₹",
  round(min(flight_prices, na.rm = TRUE), 2),
  "\n",
  sep = ""
)

cat(
  "Maximum Flight Price  : ₹",
  round(max(flight_prices, na.rm = TRUE), 2),
  "\n",
  sep = ""
)

cat(
  "Median Flight Price   : ₹",
  round(median(flight_prices, na.rm = TRUE), 2),
  "\n",
  sep = ""
)


# ------------------------------------------------------------
# AIRLINE ANALYSIS
# ------------------------------------------------------------

airline_summary <- aggregate(
  price ~ airline,
  data = flights,
  FUN = mean,
  na.rm = TRUE
)

airline_summary <- airline_summary[
  order(airline_summary$price),
]

cat("\nAIRLINE AVERAGE PRICES\n")
cat("----------------------------------------------------------------------\n")

print(
  head(
    airline_summary,
    10
  )
)


# ============================================================
# HOTEL ANALYSIS
# ============================================================

cat("\n")
cat("======================================================================\n")
cat("HOTEL COST ANALYSIS\n")
cat("======================================================================\n")

cat(
  "Average Hotel Price   : ₹",
  round(mean(hotels$price, na.rm = TRUE), 2),
  "\n",
  sep = ""
)

cat(
  "Minimum Hotel Price   : ₹",
  round(min(hotels$price, na.rm = TRUE), 2),
  "\n",
  sep = ""
)

cat(
  "Maximum Hotel Price   : ₹",
  round(max(hotels$price, na.rm = TRUE), 2),
  "\n",
  sep = ""
)

cat(
  "Median Hotel Price    : ₹",
  round(median(hotels$price, na.rm = TRUE), 2),
  "\n",
  sep = ""
)


# ------------------------------------------------------------
# HOTEL CITY ANALYSIS
# ------------------------------------------------------------

hotel_city_summary <- aggregate(
  price ~ city,
  data = hotels,
  FUN = mean,
  na.rm = TRUE
)

hotel_city_summary <- hotel_city_summary[
  order(hotel_city_summary$price),
]

cat("\nAVERAGE HOTEL PRICE BY CITY\n")
cat("----------------------------------------------------------------------\n")

print(hotel_city_summary)


# ============================================================
# FOOD ANALYSIS
# ============================================================

cat("\n")
cat("======================================================================\n")
cat("FOOD COST ANALYSIS\n")
cat("======================================================================\n")

cat(
  "Average Food Item    : ₹",
  round(mean(food$prices, na.rm = TRUE), 2),
  "\n",
  sep = ""
)

cat(
  "Minimum Food Item    : ₹",
  round(min(food$prices, na.rm = TRUE), 2),
  "\n",
  sep = ""
)

cat(
  "Maximum Food Item    : ₹",
  round(max(food$prices, na.rm = TRUE), 2),
  "\n",
  sep = ""
)

cat(
  "Median Food Item     : ₹",
  round(median(food$prices, na.rm = TRUE), 2),
  "\n",
  sep = ""
)


# ============================================================
# FUEL ANALYSIS
# ============================================================

cat("\n")
cat("======================================================================\n")
cat("FUEL PRICE ANALYSIS\n")
cat("======================================================================\n")

cat(
  "Average Petrol Price : ₹",
  round(mean(fuel$petrol_price, na.rm = TRUE), 2),
  "\n",
  sep = ""
)

cat(
  "Average Diesel Price : ₹",
  round(mean(fuel$diesel_price, na.rm = TRUE), 2),
  "\n",
  sep = ""
)

cat(
  "Minimum Petrol Price : ₹",
  round(min(fuel$petrol_price, na.rm = TRUE), 2),
  "\n",
  sep = ""
)

cat(
  "Maximum Petrol Price : ₹",
  round(max(fuel$petrol_price, na.rm = TRUE), 2),
  "\n",
  sep = ""
)


# ============================================================
# TOURISM ANALYSIS
# ============================================================

cat("\n")
cat("======================================================================\n")
cat("TOURISM DESTINATION ANALYSIS\n")
cat("======================================================================\n")

cat(
  "Number of Destinations:",
  nrow(tourism),
  "\n"
)

if ("popularity_score" %in% names(tourism)) {

  cat(
    "Average Popularity   :",
    round(
      mean(
        tourism$popularity_score,
        na.rm = TRUE
      ),
      2
    ),
    "\n"
  )
}


# ============================================================
# COST INSIGHT
# ============================================================

cat("\n")
cat("======================================================================\n")
cat("COST INSIGHTS\n")
cat("======================================================================\n")

cat(
  "The R analysis provides statistical information about\n"
)

cat(
  "transportation, accommodation, food, fuel and destinations.\n"
)

cat(
  "These statistics will be used by the dashboard for\n"
)

cat(
  "visualization and travel decision support.\n"
)


# ============================================================
# COMPLETED
# ============================================================

cat("\n")
cat("======================================================================\n")
cat("R STATISTICAL ANALYSIS COMPLETED\n")
cat("======================================================================\n")