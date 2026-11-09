-- =========================================================================
-- TITLE: Database Initialization and Mock Data Population Script
-- PROJECT: Global Layoffs Data Cleaning Portfolio Case Study
-- TARGET ENVIRONMENT: MySQL 8.0+
-- =========================================================================

-- 1. SCHEMA ISOLATION AND MANAGEMENT
DROP DATABASE IF EXISTS world_layoffs;
CREATE DATABASE world_layoffs;
USE world_layoffs;

-- 2. CREATE RAW SCHEMA LAYER (Replicating Data Import Wizard Structure)
-- String columns are designated as TEXT/VARCHAR to capture messy formatting bugs.
DROP TABLE IF EXISTS layoffs_raw;
CREATE TABLE layoffs_raw (
    company VARCHAR(100),
    location VARCHAR(100),
    industry VARCHAR(100),
    total_laid_off INT DEFAULT NULL,
    percentage_laid_off VARCHAR(50) DEFAULT NULL,
    `date` VARCHAR(50),  -- Messy string input from raw CSV import
    stage VARCHAR(50),
    country VARCHAR(100),
    funds_raised_millions INT DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 3. INJECT MOCK DATASETS (Featuring identical bugs handled in the tutorial video)
INSERT INTO layoffs_raw 
(company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) 
VALUES
-- Anomaly Type A: Blatant Duplicate Rows (Identical metric payloads across all fields)
('Casper', 'New York City', 'Consumer', 150, '0.21', '03/11/2022', 'Post-IPO', 'United States', 339),
('Casper', 'New York City', 'Consumer', 150, '0.21', '03/11/2022', 'Post-IPO', 'United States', 339), -- Duplicate row

-- Anomaly Type B: String Trailing Spaces & Categorical Discrepancies
('  Oda', 'Oslo', 'Logistics', 70, '0.15', '11/18/2022', 'Series C', 'Norway', 240), -- Leading space bug
('Gemini', 'New York City', 'Cryptocurrency', 68, '0.10', '06/02/2022', 'Series', 'United States', 400),
('Coinbase', 'SF Bay Area', 'Crypto', 1100, '0.18', '06/14/2022', 'Post-IPO', 'United States', 540), -- 'Crypto' vs 'Cryptocurrency' divergent label mismatch

-- Anomaly Type C: Punctuation Typos
('Stripes', 'Austin', 'Finance', 200, '0.14', '10/24/2022', 'Series D', 'United States.', 300), -- Trailing period typo

-- Anomaly Type D: Missing Attributes (Empty strings and explicit Null references)
('Airbnb', 'SF Bay Area', '', 600, '0.25', '05/05/2020', 'Post-IPO', 'United States', 6400), -- Empty string industry target
('Airbnb', 'SF Bay Area', 'Travel', 30, '0.01', '12/14/2021', 'Post-IPO', 'United States', 6400), -- Clean historical record for imputation matching
('Carvana', 'Phoenix', '', 2500, '0.12', '05/19/2022', 'Post-IPO', 'United States', 1200),  -- Unpopulated industry
('Carvana', 'Phoenix', 'Transportation', 1500, '0.08', '11/18/2022', 'Post-IPO', 'United States', 1200), -- Clean match target

-- Anomaly Type E: Analytical Dead Weight Rows (Completely empty metrics on analysis columns)
('Ballys', 'Providence', NULL, NULL, NULL, '06/28/2022', 'Seed', 'United States', 5), -- Missing metric pair (Industry Null only)
('InertCorp', 'London', 'Retail', NULL, NULL, '04/15/2023', 'Series A', 'United Kingdom', 12); -- Dead row: completely Null layoffs metrics


-- 4. VERIFICATION SCRIPTS (Confirm baseline environment status)
SELECT 'SUCCESS: Database initialized and target mock parameters loaded.' AS Execution_Status;
SELECT * FROM layoffs_raw;
