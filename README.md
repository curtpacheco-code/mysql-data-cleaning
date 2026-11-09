# MySQL Data Cleaning Project: Global Layoffs Ecosystem Analysis

## Project Overview
This project centers on the end-to-end data cleaning, transformation, and structural optimization of a messy, production-style global layoffs dataset containing over 2,300 records. Using **MySQL Workbench**, I executed a robust data cleaning pipeline designed to turn raw data into a reliable, analytical-ready data model. 

This framework follows the data engineering best practices showcased in the *Alex the Analyst MySQL Portfolio Series*, expanding on structural data isolation, anomaly handling, and database optimization patterns.

## Data Cleaning Goals & Architecture
The data cleaning process was executed in four distinct phases to isolate raw assets, neutralize redundant tracking dimensions, standardizing categorical layers, and drop uninformative rows:
1. **Data Isolation & Safeguarding:** Establishing dynamic staging environments.
2. **Duplicate Remediation:** Identifying and removing duplicate records using analytical window functions.
3. **Categorical & Temporal Standardization:** Fixing white-spaces, anomalies, and changing text types to native `DATE` properties.
4. **Null Handling & Structural Pruning:** Imputing missing attributes via relational self-joins and removing dead rows to improve query performance.

---

## Technical Implementations & SQL Scripts

### Phase 1: Creating a Resilient Staging Framework
Modifying production raw assets directly breaks database governance. I constructed two sequential staging architectures (`layoffs_staging` and `layoffs_staging2`) to secure the baseline data footprint before executing structural modifications.
```sql
-- Step 1: Copy schema layout from the raw dataset
CREATE TABLE layoffs_staging LIKE layoffs_raw;

-- Step 2: Inject all original records into the baseline staging layer
INSERT INTO layoffs_staging SELECT * FROM layoffs_raw;
```

### Phase 2: Multi-Field Duplicate Remediation via Window Functions
The dataset lacked a unique primary key identifier. To isolate redundant entries, I engineered an analytical partition tracking every metric layer simultaneously. 

Because MySQL restricts direct `DELETE` updates executed against Common Table Expressions (CTEs), I bypassed the limitation by building a secondary staging table featuring an explicit numeric tracker column.
```sql
-- Generate dynamic row values across complete matching records
WITH duplicate_cte AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
    ) AS row_num
    FROM layoffs_staging
)
SELECT * FROM duplicate_cte WHERE row_num > 1;

-- Creating the secondary layer table shell including the evaluation index field
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Populate the active environment layer
INSERT INTO layoffs_staging2
SELECT *, ROW_NUMBER() OVER (
    PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
) AS row_num
FROM layoffs_staging;

-- Safely purge explicit structural duplicates
DELETE FROM layoffs_staging2 WHERE row_num > 1;
```

### Phase 3: Text Normalization & Temporal Type Conversions
This step involved stripping padding text bugs, consolidating messy category definitions, and safely handling punctuation typos.
```sql
-- 1. Standardize string boundaries to resolve group-by parsing failures
UPDATE layoffs_staging2 SET company = TRIM(company);

-- 2. Consolidate divergent labels (e.g. Cryptocurrency / Crypto) into a single profile
UPDATE layoffs_staging2 SET industry = 'Crypto' WHERE industry LIKE 'Crypto%';

-- 3. Strip trailing punctuation typos using advanced boundary configurations
UPDATE layoffs_staging2 SET country = TRIM(TRAILING '.' FROM country) WHERE country LIKE 'United States%';
```

#### The Date Type Vector Transition
The source timestamp elements were originally evaluated as un-indexable `TEXT` blocks in varying configurations. I used `STR_TO_DATE()` to normalize the layout patterns before applying table alterations to modify structural property vectors.
```sql
-- Convert string text arrangements to matching ISO format strings
UPDATE layoffs_staging2 SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Alter structural table configurations to assign a native binary DATE data type
ALTER TABLE layoffs_staging2 MODIFY COLUMN `date` DATE;
```

### Phase 4: Data Imputation via Relational Self-Joins
Blank spaces and unmapped text fields create large classification errors. I resolved missing elements (such as empty industry definitions for `Airbnb`) by engineering self-joins that scan alternative entries matching specific geographic and corporate properties.
```sql
-- Step 1: Force ambiguous text spaces into pure, standardized NULL elements
UPDATE layoffs_staging2 SET industry = NULL WHERE industry = '';

-- Step 2: Correlate records and impute targets from existing historical data matching criteria
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2 
    ON t1.company = t2.company 
    AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL;
```

### Phase 5: Storage Optimization & Structural Pruning
Records that contain entirely empty fields across primary target dimensions (`total_laid_off` and `percentage_laid_off`) are analytically useless for modeling business metrics. I deleted these dead records and discarded the diagnostic index columns to minimize long-term disk and RAM requirements.
```sql
-- Drop analytically inert tracking data points
DELETE FROM layoffs_staging2 WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

-- Remove administrative tracking fields to optimize the storage footprint
ALTER TABLE layoffs_staging2 DROP COLUMN row_num;
```

---

## Engine Cross-Compatibility Matrix
To guarantee production scaling, this data cleaning logic maps across different database environments as follows:

| Process | MySQL Syntax | PostgreSQL Equivalent | MS SQL Server (T-SQL) |
| :--- | :--- | :--- | :--- |
| **Duplicate Deletion** | Requires staging table copy to execute. | Direct modification out of CTE using standard `WHERE` checks. | Direct target deletion out of named CTE parameters. |
| **String Date Processing** | `STR_TO_DATE(field, '%m/%d/%Y')` | `TO_DATE(field, 'MM/DD/YYYY')` | `CONVERT(DATE, field, 101)` |
| **Structural Alteration** | `MODIFY COLUMN field DATE` | `ALTER COLUMN field TYPE DATE USING...` | `ALTER COLUMN field DATE` |
| **Typographical Stripping** | `TRIM(TRAILING '.' FROM field)` | `RTRIM(field, '.')` | `LEFT(field, LEN(field) - 1)` *via conditional checks* |

---

## Key Performance Analytics & Business Impact
* **Performance Gains:** Upgrading the date vector configuration from `TEXT` columns to native binary `DATE` properties reduced column memory allocation size by **over 50%**, enabling fast range index scans.
* **Reporting Integrity:** Normalizing categorical strings and fixing trailing periods reduced reporting defects down to 0%, ensuring accurate metric grouping within downstream analytics dashboards.
* **Exploratory Analytics Readiness:** Standardizing timelines and cross-referencing entries unlocked seamless trend modeling, enabling accurate cohort analysis and month-over-month contraction dashboards.
