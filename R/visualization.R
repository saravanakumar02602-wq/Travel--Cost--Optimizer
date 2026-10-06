
# ============================================================
# TRAVEL COST OPTIMIZER
# R VISUALIZATION LAYER
# ============================================================

BASE_DIR <- "D:/Travel-Cost-Optimizer"

DATA_DIR <- file.path(
  BASE_DIR,
  "data",
  "processed"
)

OUTPUT_DIR <- file.path(
  BASE_DIR,
  "reports"
)

if (!dir.exists(OUTPUT_DIR)) {
  dir.create(
    OUTPUT_DIR,
    recursive = TRUE
  )
}


# ============================================================
# LOAD DATA
# ============================================================

flights <- read.csv(
  file.path(DATA_DIR, "flights.csv"),
  stringsAsFactors = FALSE
)

hotels <- read.csv(
  file.path(DATA_DIR, "hotels.csv"),
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
# DISPLAY FUEL COLUMNS
# ============================================================

cat("\nFuel dataset columns:\n")
print(names(fuel))


# ============================================================
# FIND PETROL COLUMN
# ============================================================

petrol_column <- names(fuel)[
  grepl(
    "petrol",
    names(fuel),
    ignore.case = TRUE
  )
]

diesel_column <- names(fuel)[
  grepl(
    "diesel",
    names(fuel),
    ignore.case = TRUE
  )
]

date_column <- names(fuel)[
  grepl(
    "^date$|date",
    names(fuel),
    ignore.case = TRUE
  )
]

if (length(petrol_column) == 0) {
  stop(
    "Petrol price column was not found in fuel_prices.csv"
  )
}

if (length(diesel_column) == 0) {
  stop(
    "Diesel price column was not found in fuel_prices.csv"
  )
}

if (length(date_column) == 0) {
  stop(
    "Date column was not found in fuel_prices.csv"
  )
}

petrol_column <- petrol_column[1]
diesel_column <- diesel_column[1]
date_column <- date_column[1]

cat("\nDetected petrol column :", petrol_column)
cat("\nDetected diesel column :", diesel_column)
cat("\nDetected date column   :", date_column)
cat("\n")


# ============================================================
# 1. FLIGHT PRICE DISTRIBUTION
# ============================================================

png(
  file.path(
    OUTPUT_DIR,
    "flight_price_distribution.png"
  ),
  width = 1200,
  height = 800
)

hist(
  flights$price,
  main = "Flight Price Distribution",
  xlab = "Flight Price (₹)",
  ylab = "Number of Flights",
  breaks = 30
)

dev.off()


# ============================================================
# 2. AVERAGE FLIGHT PRICE BY AIRLINE
# ============================================================

airline_summary <- aggregate(
  price ~ airline,
  data = flights,
  FUN = mean,
  na.rm = TRUE
)

airline_summary <- airline_summary[
  order(
    airline_summary$price,
    decreasing = TRUE
  ),
]

png(
  file.path(
    OUTPUT_DIR,
    "airline_average_price.png"
  ),
  width = 1400,
  height = 900
)

barplot(
  airline_summary$price,
  names.arg = airline_summary$airline,
  main = "Average Flight Price by Airline",
  xlab = "Airline",
  ylab = "Average Price (₹)",
  las = 2,
  cex.names = 0.7
)

dev.off()


# ============================================================
# 3. HOTEL PRICE BY CITY
# ============================================================

hotel_city <- aggregate(
  price ~ city,
  data = hotels,
  FUN = mean,
  na.rm = TRUE
)

hotel_city <- hotel_city[
  order(
    hotel_city$price,
    decreasing = TRUE
  ),
]

png(
  file.path(
    OUTPUT_DIR,
    "hotel_price_by_city.png"
  ),
  width = 1200,
  height = 800
)

barplot(
  hotel_city$price,
  names.arg = hotel_city$city,
  main = "Average Hotel Price by City",
  xlab = "City",
  ylab = "Average Hotel Price (₹)",
  las = 2
)

dev.off()


# ============================================================
# 4. FOOD PRICE DISTRIBUTION
# ============================================================

png(
  file.path(
    OUTPUT_DIR,
    "food_price_distribution.png"
  ),
  width = 1200,
  height = 800
)

hist(
  food$prices,
  main = "Food Item Price Distribution",
  xlab = "Food Price (₹)",
  ylab = "Number of Items",
  breaks = 40
)

dev.off()


# ============================================================
# 5. PETROL PRICE TREND
# ============================================================

fuel[[date_column]] <- as.Date(
  fuel[[date_column]]
)

fuel[[petrol_column]] <- as.numeric(
  fuel[[petrol_column]]
)

fuel_daily <- aggregate(
  fuel[[petrol_column]],
  by = list(
    date = fuel[[date_column]]
  ),
  FUN = mean,
  na.rm = TRUE
)

names(fuel_daily)[2] <- "petrol_price"

fuel_daily <- fuel_daily[
  order(fuel_daily$date),
]

png(
  file.path(
    OUTPUT_DIR,
    "petrol_price_trend.png"
  ),
  width = 1400,
  height = 800
)

plot(
  fuel_daily$date,
  fuel_daily$petrol_price,
  type = "l",
  main = "Petrol Price Trend",
  xlab = "Date",
  ylab = "Average Petrol Price (₹/L)"
)

dev.off()


# ============================================================
# 6. HOTEL PRICE DISTRIBUTION
# ============================================================

png(
  file.path(
    OUTPUT_DIR,
    "hotel_price_distribution.png"
  ),
  width = 1200,
  height = 800
)

hist(
  hotels$price,
  main = "Hotel Price Distribution",
  xlab = "Hotel Price (₹)",
  ylab = "Number of Hotels",
  breaks = 30
)

dev.off()


# ============================================================
# COMPLETED
# ============================================================

cat("\n")
cat("======================================================================\n")
cat("R VISUALIZATION COMPLETED SUCCESSFULLY\n")
cat("======================================================================\n")

cat("\nGenerated files:\n")

cat("1. flight_price_distribution.png\n")
cat("2. airline_average_price.png\n")
cat("3. hotel_price_by_city.png\n")
cat("4. food_price_distribution.png\n")
cat("5. petrol_price_trend.png\n")
cat("6. hotel_price_distribution.png\n")

cat("\nSaved in:\n")
cat(OUTPUT_DIR, "\n")

cat("\n")
cat("======================================================================\n")

