<div align="center">

# 🏥 NHS Locum Data Warehouse & Demand Forecasting

### From Raw Operational Data → Data Warehouse → Predictive Analytics

<p>
<img src="https://img.shields.io/badge/SQL%20Server-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white"/>
<img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white"/>
<img src="https://img.shields.io/badge/Pandas-150458?style=for-the-badge&logo=pandas&logoColor=white"/>
<img src="https://img.shields.io/badge/Jupyter-F37626?style=for-the-badge&logo=jupyter&logoColor=white"/>
<img src="https://img.shields.io/badge/ARIMA-Time%20Series-8B5CF6?style=for-the-badge"/>
</p>

**An end-to-end data engineering and time-series forecasting project for NHS locum demand.**

</div>

---

# 🎯 Project at a Glance

This project builds a complete analytical pipeline around **NHS locum staffing requests**.

The system starts with operational data stored in Microsoft Access, validates and cleans the data in SQL Server, transforms it into a structured Data Warehouse, runs analytical queries against the warehouse, and finally feeds historical locum-request demand into time-series forecasting models.

```text
┌───────────────────────┐
│   Microsoft Access    │
│    Source Database    │
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│   Data Validation &   │
│    Cleaning in SQL    │
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│      SQL Server       │
│   Data Transformation │
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│    Data Warehouse     │
│ Fact + Dimensions     │
└───────────┬───────────┘
            │
       ┌────┴─────┐
       ▼          ▼
   SQL Analysis   Time Series
                    │
             ┌──────┴──────┐
             ▼             ▼
          AutoReg         ARIMA
             │             │
             └──────┬──────┘
                    ▼
          Locum Demand Forecast
```

---

# 🏥 Business Context

The NHS funds local agencies to arrange temporary medical staff when doctors or general practitioners are unavailable.

A surgery can request a temporary doctor, known as a **locum**, for a particular period or session.

The agency must then:

1. Receive the staffing request.
2. Identify the required type of medical cover.
3. Match the request with available locums.
4. Record the session and staffing information.
5. Manage historical demand.

This project uses that operational data to create an analytical foundation and investigate whether historical request patterns can be used to forecast future locum demand.

---

# 🧩 System Objectives

The project was designed around an end-to-end data lifecycle:

| Stage | Objective |
|---|---|
| 📥 Extract | Bring operational data from Access into SQL Server |
| 🧹 Clean | Validate keys, relationships and data quality |
| 🔄 Transform | Convert and derive analytical attributes |
| 🏗️ Warehouse | Build a structured relational Data Warehouse |
| 🔎 Analyze | Answer business questions using SQL |
| 📈 Model | Create locum-request time series |
| 🤖 Forecast | Compare AutoReg and ARIMA approaches |

---

# 🏗️ Data Engineering Architecture

```text
                         SOURCE
                           │
                           ▼
                ┌────────────────────┐
                │ Microsoft Access   │
                └─────────┬──────────┘
                          │
                          ▼
                 EXTRACTION / CLEANING
                          │
                          ▼
                ┌────────────────────┐
                │    SQL Server      │
                │                    │
                │ Validation         │
                │ Cleaning           │
                │ Transformation     │
                └─────────┬──────────┘
                          │
                          ▼
                    DATA WAREHOUSE
                          │
             ┌────────────┼────────────┐
             │            │            │
             ▼            ▼            ▼
          FACT        DIMENSIONS    TIME
         SESSION       LOCUM       CALENDAR
             │         PRACTICE
             │         TYPE COVER
             │         REQUEST
             └────────────┬───────────┘
                          │
                          ▼
                  ANALYTICAL LAYER
                          │
                 ┌────────┴────────┐
                 ▼                 ▼
            SQL Queries       Time Series
                                   │
                           ┌───────┴───────┐
                           ▼               ▼
                         AutoReg         ARIMA
                           │               │
                           └───────┬───────┘
                                   ▼
                           Forecast Output
```

---

# 🧹 Data Quality & Cleaning

Before building the warehouse, the source tables were checked for data-quality and referential-integrity issues.

## 🔑 Primary Key Validation

Duplicate identifiers were checked in tables such as:

- `LOCUMDETAILS`
- `LOCUMREQUEST`
- `Practice Details`
- `Template_Type of Cover`

The checks used `GROUP BY` and `HAVING COUNT(...) > 1` to identify duplicate keys.

---

## 🔗 Referential Integrity

The `SESSION` table was checked against related tables to identify orphaned records.

For example:

```sql
SELECT LocumID
FROM SESSION
WHERE ISNULL(LocumID, 0) NOT IN (
    SELECT LocumID
    FROM LOCUMDETAILS
);
```

Invalid session records whose `LocumID` did not exist in `LOCUMDETAILS` were removed.

The same approach was used to validate:

```text
SESSION
   │
   ├── RequestID → LOCUMREQUEST
   │
   ├── LocumID → LOCUMDETAILS
   │
   └── Type → TYPE OF COVER
```

---

## 🧽 Removing Unnecessary Data

Columns containing only irrelevant/empty information were removed from the source tables.

For example, unused columns were removed from `SESSION`, and several empty fields were removed from `LOCUMREQUEST`.

This reduced unnecessary data before loading the warehouse.

---

# 🏗️ Data Warehouse Design

The warehouse separates operational information into a central session fact table
and supporting dimensions for requests, practices, locums, cover types, and time.

### 🗂️ Data Warehouse Schema

The schema below shows the relationships implemented in SQL Server.

![NHS Locum Data Warehouse Schema](./data_warehouse_schema.png)

### Core warehouse tables

```text
DW_SESSION
DW_SessionTimetable
DW_LOCUMREQUEST
DW_TypeCover
DW_PracticeDetails
DW_LocumDetails
```

Conceptually:

```text
                     ┌─────────────────────┐
                     │ DW_SessionTimetable  │
                     └──────────┬──────────┘
                                │
                                │ Date Key
                                ▼
┌────────────────┐       ┌────────────────┐
│ DW_LocumDetails│       │   DW_SESSION   │
└───────┬────────┘       └───────┬────────┘
        │                        │
        │ LocumID                │ RequestID
        │                        ▼
        │                ┌─────────────────┐
        │                │ DW_LOCUMREQUEST │
        │                └────────┬────────┘
        │                         │
        │                         │ PracticeID
        │                         ▼
        │                ┌────────────────────┐
        │                │DW_PracticeDetails │
        │                └────────────────────┘
        │
        └─────────────── DW_TypeCover
```

---

# 🕒 Time Dimension Engineering

The session date was transformed into analytical time attributes:

```text
SessionDate
     │
     ├── Year
     ├── Month
     ├── Week
     └── Day of Year
```

The session duration was also derived using:

```sql
DATEDIFF(
    MINUTE,
    SessionStart,
    SessionEnd
)
```

This created a reusable analytical representation of session length.

Duplicate timetable records were identified and removed using a CTE with `ROW_NUMBER()`.

```sql
WITH cte AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY SessionDate, S_Dayofyear
               ORDER BY SessionDate, S_Dayofyear
           ) AS row_num
    FROM DW_SessionTimetable
)
DELETE FROM cte
WHERE row_num > 1;
```

The resulting date identifier was then linked back to the fact table.

---

# 🔎 Analytical SQL Layer

The warehouse was designed to answer business questions such as:

### 01 — Sessions by type and month

```text
Month × Type of Cover → Sessions
```

### 02 — Requests by type and week

```text
Week × Type of Cover → Request Count
```

### 03 — Requests by county and month

```text
Month × County → Locum Requests
```

### 04 — Sessions conducted by month

```text
Month → Number of Sessions
```

### 05 — Requests by town and week

```text
Week × Town → Locum Requests
```

This demonstrates how the warehouse can support both **operational reporting and downstream analytics**.

---

# 📈 From Data Warehouse to Time Series

The forecasting layer retrieves daily locum-request counts directly from the warehouse.

```sql
SELECT
    RequestDate,
    COUNT(LocumRequestID) AS RequestCount
FROM DW_LOCUMREQUEST
GROUP BY RequestDate;
```

The result becomes the modelling dataset:

```text
RequestDate
     │
     ▼
RequestCount
     │
     ▼
Time Series
```

The Python notebooks connect to SQL Server using `pyodbc`, query the warehouse and load the results into Pandas.

---

# 📊 Time-Series Preparation

The modelling notebooks perform:

```text
SQL Server
    ↓
Extract Request Counts
    ↓
Pandas DataFrame
    ↓
Visualize Series
    ↓
Stationarity Testing
    ↓
Train/Test Split
    ↓
Model Training
    ↓
Prediction
    ↓
RMSE Evaluation
```

The dataset used in the ARIMA notebook contains **26 observations**.

The ARIMA workflow uses:

```text
21 observations → Training
 5 observations → Testing
```

---

# 🧪 Stationarity Analysis

The Augmented Dickey-Fuller test was used to assess stationarity.

The observed test output was:

```text
ADF Statistic : -2.40096
P-Value       : 0.14146
Lags          : 9
```

Because the p-value was above common significance thresholds, the series did not provide sufficient evidence to reject the null hypothesis of a unit root.

This informed the subsequent ARIMA modelling approach.

---

# 🤖 Model 01 — AutoReg

The autoregressive model was implemented using `statsmodels`.

The notebook:

```python
model = AutoReg(train, lags=7).fit()
```

uses the previous **7 observations** as autoregressive lags.

The model then predicts the held-out observations:

```python
pred = model.predict(
    start=len(train),
    end=len(X)-1,
    dynamic=False
)
```

### Evaluation

The AutoReg model achieved:

```text
RMSE
3.7234
```

The notebook also generated a four-step future prediction:

```text
2.9304
7.1142
6.7009
-2.1110
```

The negative forecast is an important modelling limitation because a request count cannot logically be negative.

This highlights why **domain constraints and post-processing matter in a production forecasting system**.

---

# 🤖 Model 02 — ARIMA

The second forecasting approach uses ARIMA.

`auto_arima` was first used to explore model selection, followed by fitting an ARIMA model.

The resulting model was:

```text
ARIMA(1, 1, 0)
```

Model summary:

```text
Observations : 26
Model        : ARIMA(1,1,0)
AIC          : 119.565
BIC          : 122.552
HQIC         : 120.148
```

The training/testing design was:

```text
26 total observations
│
├── 21 training observations
└── 5 testing observations
```

---

# 📊 Model Evaluation

The ARIMA model was evaluated against the five-observation test set.

### RMSE

```text
ARIMA RMSE
1.7936
```

Compared with the AutoReg model:

| Model | RMSE |
|---|---:|
| AutoReg (7 lags) | **3.7234** |
| ARIMA (1,1,0) | **1.7936** |

### Interpretation

For this particular dataset and train/test split, the ARIMA model produced the lower RMSE.

```text
Lower RMSE
     ↓
ARIMA ─────────────── 1.7936
     │
     │
AutoReg ───────────────────── 3.7234
```

This does **not** mean ARIMA is universally better than AutoReg. It means ARIMA performed better on this specific dataset and evaluation setup.

---

# 🧠 Engineering Perspective

The most important part of this project is not simply the forecasting model.

It demonstrates a complete chain:

```text
                 DATA
                  │
                  ▼
        QUALITY & VALIDATION
                  │
                  ▼
          DATA ENGINEERING
                  │
                  ▼
           DATA WAREHOUSE
                  │
                  ▼
          ANALYTICAL QUERIES
                  │
                  ▼
          FEATURE / SERIES
            PREPARATION
                  │
                  ▼
          MODEL DEVELOPMENT
                  │
                  ▼
             EVALUATION
                  │
                  ▼
             FORECAST
```

The project therefore connects **data engineering with data science**, rather than treating machine learning as an isolated notebook exercise.

---

# 🧰 Technology Stack

<div align="center">

### Database & Data Engineering

`Microsoft Access`  
`Microsoft SQL Server`  
`SQL`  
`Data Warehousing`  
`ETL / Data Cleaning`

### Data Science

`Python`  
`Pandas`  
`Statsmodels`  
`Scikit-learn`  
`Jupyter Notebook`

### Forecasting

`AutoReg`  
`ARIMA`  
`Auto-ARIMA`  
`ADF Test`  
`RMSE`

</div>

---

# 📁 Repository Structure

```text
data-warehouse-project/
│
├── README.md
│
├── DW_AUTOREG_MODEL.ipynb
│
├── DW_ARIMA.ipynb
│
└── SQL / Data Warehouse scripts
```

The two notebooks contain the forecasting experiments:

```text
DW_AUTOREG_MODEL.ipynb
        │
        └── AutoReg forecasting

DW_ARIMA.ipynb
        │
        ├── Stationarity testing
        ├── Auto-ARIMA
        ├── ARIMA modelling
        └── Forecast evaluation
```

---

# ⚠️ Current Limitations

This project is a strong demonstration of the end-to-end workflow, but there are several areas that would need improvement before treating it as a production forecasting system.

### 1. Small modelling dataset

The ARIMA experiment uses only 26 observations.

A production forecasting solution would require substantially more historical data.

### 2. Sparse / irregular dates

The extracted request dates are not necessarily evenly spaced.

A production time-series pipeline should explicitly define the time frequency and handle missing periods.

### 3. Forecast constraints

The AutoReg model produced a negative future request prediction.

A production system should enforce appropriate non-negative constraints or use a forecasting approach suitable for count data.

### 4. Model comparison

Only a small number of models were evaluated.

Future work should compare additional approaches using consistent time-series cross-validation.

### 5. Legacy API usage

The original notebook uses the older `statsmodels.tsa.arima_model.ARIMA` interface.

A modern implementation should migrate to the current `statsmodels` API.

---

# 🚀 Future Engineering Improvements

The next evolution of this project could transform the coursework pipeline into a production-style forecasting system.

```text
CURRENT
│
├── SQL Server
├── Data Warehouse
├── Jupyter
├── AutoReg
└── ARIMA
        │
        ▼
FUTURE
│
├── Automated ETL Pipeline
├── Data Quality Checks
├── Incremental Warehouse Loads
├── Time-Series Feature Pipeline
├── Model Registry
├── Automated Evaluation
├── Forecast Monitoring
├── API / Dashboard
└── Scheduled Forecast Generation
```

Potential improvements:

- Automate ingestion from the source database.
- Introduce reusable ETL/ELT pipelines.
- Add automated data-quality validation.
- Create a proper calendar dimension.
- Handle missing dates explicitly.
- Add rolling/expanding time-series validation.
- Compare ARIMA, AutoReg and additional forecasting approaches.
- Add forecast confidence intervals.
- Enforce non-negative demand forecasts.
- Track model performance over time.
- Expose forecasts through an API or dashboard.
- Schedule automatic model retraining.

---

# 🏆 Key Takeaways

### Data Engineering

✔ Source extraction  
✔ Data cleaning  
✔ Referential integrity  
✔ Relational schema design  
✔ Data Warehouse construction  
✔ Analytical SQL  

### Data Science

✔ Time-series preparation  
✔ Stationarity testing  
✔ AutoReg modelling  
✔ ARIMA modelling  
✔ Train/test evaluation  
✔ RMSE comparison  

### System Thinking

✔ Data quality before modelling  
✔ Warehouse as a reusable analytical layer  
✔ Separation of data engineering and modelling  
✔ Model evaluation rather than relying on visual output  
✔ Recognition of real-world modelling constraints  

---

# 💡 What This Project Demonstrates

> **Machine learning is only one layer of a reliable data product.**

A forecasting model is only as useful as the data pipeline feeding it.

This project demonstrates the progression from:

```text
RAW OPERATIONAL DATA
        ↓
CLEAN DATA
        ↓
STRUCTURED DATA WAREHOUSE
        ↓
BUSINESS QUESTIONS
        ↓
TIME-SERIES DATA
        ↓
MACHINE LEARNING
        ↓
EVALUATION
        ↓
FORECASTING
```

---

<div align="center">

## 🏥 Data → Engineering → Intelligence

### Building reliable foundations for data-driven decisions.

<br>

<a href="https://github.com/delfydavis/data-warehouse-project">
<img src="https://img.shields.io/badge/VIEW_REPOSITORY-181717?style=for-the-badge&logo=github&logoColor=white"/>
</a>

</div>
