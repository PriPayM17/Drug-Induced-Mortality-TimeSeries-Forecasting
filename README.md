# U.S. Mortality Forecasting (1999–2023)

This project explores and forecasts mortality trends across the U.S. using CDC WONDER data. Models include ARIMA (time series), Random Forest, and XGBoost.

## Objective
To model and predict mortality counts nationwide and by subgroup (gender, age, state) using statistical and machine learning techniques.

## Methods
- ARIMA (AutoRegressive Integrated Moving Average)
- Random Forest Regression
- XGBoost Regression
- Model validation: RMSE, MAE, R², MAPE

## Data
CDC WONDER mortality dataset (1999–2023)  
🔗 [https://wonder.cdc.gov/](https://wonder.cdc.gov/)

## Key Results
- **ARIMA** overfit the training data (MAPE = 14%, but 41% on test)
- **Random Forest** performed best (MAE = 15,209, R² ≈ 0.999)
- **XGBoost** slightly underperformed Random Forest
- Most important predictor: `Year`

## Visualizations
See `/images` folder for:
- Stationarity check
- ACF/PACF plots
- Forecast charts

## Limitations
- No external covariates (e.g., healthcare, economic shocks)
- Mortality counts were highly autocorrelated
- Generalization outside of time range not guaranteed

## Final Report
See `Forecasting Nationwide Mortality Trends in the United States (1999–2023).docx`

---

### Appendix
All R code is provided in this repository.
