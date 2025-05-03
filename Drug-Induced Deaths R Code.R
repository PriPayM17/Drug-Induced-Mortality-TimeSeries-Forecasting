setwd("/Users/priscabongupayanzomaba/Downloads")  # Replace with your actual folder path

install.packages(c("tidyverse", "lubridate", "forecast", "tseries", "ggplot2"))
install.packages(c("caret", "randomForest", "xgboost", "dplyr"))


library(tidyverse)
library(lubridate)
library(forecast)
library(tseries)
library(ggplot2)
library(caret)
library(randomForest)
library(xgboost)
library(dplyr)

#READING THE DATA
# Load the data
deaths <- read.csv("Deaths_Cleaned_Full_1999_2023.csv")

# Make sure 'year' and 'deaths' are numeric
deaths$Year <- as.numeric(deaths$Year)
deaths$Deaths <- as.numeric(deaths$Deaths)

# Aggregate total deaths by year
nationwide <- deaths %>%
  group_by(Year) %>%
  summarise(Total_Deaths = sum(Deaths, na.rm = TRUE))

# Plot
ggplot(nationwide, aes(x = Year, y = Total_Deaths)) +
  geom_line(color = "steelblue", size = 1.2) +
  ggtitle("Nationwide Deaths (1999–2023)") +
  xlab("Year") + ylab("Total Deaths") +
  theme_minimal()


# Group by year and sex
by_gender <- deaths %>%
  group_by(Year, Sex) %>%
  summarise(Deaths = sum(Deaths, na.rm = TRUE))

# Plot
ggplot(by_gender, aes(x = Year, y = Deaths, color = Sex)) +
  geom_line(size = 1.1) +
  ggtitle("Deaths by Gender (1999–2023)") +
  theme_minimal()


# Get top 5 states by total deaths
top_states <- deaths %>%
  group_by(State) %>%
  summarise(Total_Deaths = sum(Deaths, na.rm = TRUE)) %>%
  arrange(desc(Total_Deaths)) %>%
  slice_head(n = 5)

# Filter and group by year/state
by_state <- deaths %>%
  filter(State %in% top_states$State) %>%
  group_by(Year, State) %>%
  summarise(Deaths = sum(Deaths, na.rm = TRUE))

# Plot
ggplot(by_state, aes(x = Year, y = Deaths, color = State)) +
  geom_line(size = 1) +
  ggtitle("Top 5 States by Deaths (1999–2023)") +
  theme_minimal()


# Top 5 age groups by total deaths
top_ages <- deaths %>%
  group_by(`Five.Year.Age.Groups`) %>%
  summarise(Total_Deaths = sum(Deaths, na.rm = TRUE)) %>%
  arrange(desc(Total_Deaths)) %>%
  slice_head(n = 5)

# Filter and group
by_age <- deaths %>%
  filter(`Five.Year.Age.Groups` %in% top_ages$`Five.Year.Age.Groups`) %>%
  group_by(Year, `Five.Year.Age.Groups`) %>%
  summarise(Deaths = sum(Deaths, na.rm = TRUE))

# Plot
ggplot(by_age, aes(x = Year, y = Deaths, color = `Five.Year.Age.Groups`)) +
  geom_line(size = 1) +
  ggtitle("Top 5 Age Groups by Deaths (1999–2023)") +
  theme_minimal()


# Convert total nationwide deaths to time series
nationwide_ts <- ts(nationwide$Total_Deaths, start = 1999, frequency = 1)  # annual data
plot(nationwide_ts, main = "Nationwide Deaths Time Series", ylab = "Deaths", xlab = "Year")


#Checking for Stationarity
autoplot(nationwide_ts) +
  ggtitle("Nationwide Deaths (Raw)") +
  xlab("Year") + ylab("Deaths")

#ADF
adf.test(nationwide_ts)  # H0: non-stationary

#Differencing because ADF non-stationary
# First difference
nationwide_diff <- diff(nationwide_ts)

# Plot differenced data
autoplot(nationwide_diff) +
  ggtitle("Differenced Nationwide Deaths (1st order)") +
  xlab("Year") + ylab("Differenced Deaths")

# Check again with ADF test
adf.test(nationwide_diff)

#ACF & PACF Plots (to suggest AR(p)/MA(q))
acf(nationwide_diff, main = "ACF of Differenced Data")
pacf(nationwide_diff, main = "PACF of Differenced Data")


#Fit ARIMA Model
# Use auto.arima to find best (p,d,q)
fit <- auto.arima(nationwide_ts)
summary(fit)


#Check Residuals (White Noise?)
checkresiduals(fit)

# Ljung-Box Test
Box.test(residuals(fit), lag = 10, type = "Ljung-Box")  # p > 0.05 means residuals ~ white noise


forecast_national <- forecast(fit, h = 4)

# Plot the forecast
autoplot(forecast_national) +
  ggtitle("Forecast: Nationwide Deaths (2024–2027)") +
  xlab("Year") + ylab("Deaths")

# Show forecasted values
forecast_national


# Filter Minnesota data and aggregate
mn_ts <- deaths %>%
  filter(State == "Minnesota") %>%
  group_by(Year) %>%
  summarise(Total_Deaths = sum(Deaths, na.rm = TRUE)) %>%
  pull(Total_Deaths) %>%
  ts(start = 1999, frequency = 1)

# Fit and forecast
fit_mn <- auto.arima(mn_ts)
forecast_mn <- forecast(fit_mn, h = 4)

# Plot
autoplot(forecast_mn) + ggtitle("Forecasted Deaths in Minnesota (2024–2027)")
forecast_mn


# Summarize national data
nationwide_df <- deaths %>%
  group_by(Year) %>%
  summarise(Deaths = sum(Deaths), Population = sum(Population)) %>%
  arrange(Year)

# Add lag features if needed
nationwide_df$Lag1 <- dplyr::lag(nationwide_df$Deaths, 1)

# Drop first NA lag row
nationwide_df <- nationwide_df %>% filter(!is.na(Lag1))

# Split data
train_df <- nationwide_df %>% filter(Year <= 2019)
test_df <- nationwide_df %>% filter(Year > 2019)


#Random Forest Model
rf_model <- randomForest(Deaths ~ Year + Population + Lag1, data = train_df)
rf_preds <- predict(rf_model, newdata = test_df)

# Accuracy
postResample(rf_preds, test_df$Deaths)


#XGBOOST Model
# Convert to matrix
train_x <- model.matrix(Deaths ~ Year + Population + Lag1, data = train_df)[, -1]
test_x <- model.matrix(Deaths ~ Year + Population + Lag1, data = test_df)[, -1]

train_y <- train_df$Deaths
test_y <- test_df$Deaths

dtrain <- xgb.DMatrix(data = train_x, label = train_y)
dtest <- xgb.DMatrix(data = test_x)

# Fit model
xgb_model <- xgboost(data = dtrain, nrounds = 100, objective = "reg:squarederror", verbose = 0)

# Predict
xgb_preds <- predict(xgb_model, dtest)

# Accuracy
postResample(xgb_preds, test_y)


#Check Variable Importance For Random Forest:
importance(rf_model)
varImpPlot(rf_model)



