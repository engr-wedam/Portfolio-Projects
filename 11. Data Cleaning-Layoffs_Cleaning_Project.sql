-- Data Cleaning --

SELECT *
FROM layoffs ;

-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Null Values ro blank values
-- 4. Remove Any Columns or Rows

CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT * FROM world_layoffs.layoffs_staging;

INSERT INTO layoffs_staging
SELECT*
FROM layoffs
 ;
 
 -- Duplicates removal --
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

WITH duplicate_cte AS 
(
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging 
)
SELECT * 
FROM duplicate_cte
WHERE row_num > 1;

CREATE TABLE `layoffs_staging3` (
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
 
INSERT INTO layoffs_staging3
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging 
;
DELETE
FROM layoffs_staging3
WHERE row_num > 1 ;

SELECT*
FROM layoffs_staging3
WHERE row_num > 1 ;

-- Standardizing Data
SELECT*
FROM layoffs_staging3;

SELECT company, TRIM(company)
FROM layoffs_staging3;
-- now that we can see trim is better in company we will update the table with the new one --

UPDATE layoffs_staging3
SET company = TRIM(company);

-- now we look into the location column to standardize --
SELECT DISTINCT location
FROM layoffs_staging3;

-- all good so now we look into the industry column to standardize --
SELECT DISTINCT industry
FROM layoffs_staging3;

SELECT*
FROM layoffs_staging3
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging3
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- now we look into the country column to standardize --
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging3
ORDER BY 1;

UPDATE layoffs_staging
SET country = 'United States'
WHERE country LIKE 'United States%';

-- date is advisable to be in date format for analysis --
SELECT 
    date, STR_TO_DATE(`date`,'%m/%d/%Y')
FROM
    `world_layoffs`.`layoffs_staging3`;

UPDATE layoffs_staging3
SET date = STR_TO_DATE(`date`,'%m/%d/%Y');

#we use the alter table to modify the date's column#

ALTER TABLE layoffs_staging3
MODIFY COLUMN `date` DATE;

--------------------------------- 
-- dealing with NULLS --
---------------------------------

------------------------------------------------ industry --
SELECT* 
FROM layoffs_staging3 t1
JOIN layoffs_staging3 t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry= '')
AND (t2.industry IS NOT NULL);

SELECT t1.industry, t2.industry
FROM layoffs_staging3 t1
JOIN layoffs_staging3 t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry= '')
AND (t2.industry IS NOT NULL)
;
UPDATE layoffs_staging3
SET industry = NULL
WHERE industry = '' ;

UPDATE layoffs_staging3 t1
JOIN layoffs_staging3 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry= '')
AND (t2.industry IS NOT NULL);

-- eg--
SELECT *
FROM layoffs_staging3
WHERE company = 'Airbnb';

------------- total_laid_off & %laid_off--
SELECT*
FROM layoffs_staging3
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;

DELETE
FROM layoffs_staging3
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;

SELECT*
FROM layoffs_staging3;

ALTER TABLE layoffs_staging3
DROP COLUMN row_num;