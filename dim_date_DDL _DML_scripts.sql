-- DIM_DATES - DDL & DML
-- =====================================================================
-- Purpose: Create and populate the date dimension
-- Schema: BL_DM
-- Date Range: 2023-01-01 to 2026-12-31
-- =====================================================================

DROP TABLE IF EXISTS BL_DM.DIM_DATES CASCADE;
DROP TABLE IF EXISTS BL_DM.DIM_DATES CASCADE;

-- =====================================
-- STEP 1: Create DIM_DATES table
-- =====================================
CREATE TABLE BL_DM.DIM_DATES (
    DATE_SURR_ID         BIGINT      NOT NULL,  
    EVENT_DT             DATE        NOT NULL,  
    YEAR_NUM             INT         NOT NULL,
    QUARTER_NUM          INT         NOT NULL,
    MONTH_NUM            INT         NOT NULL,
    DAY_NUM              INT         NOT NULL,
    DAY_OF_WEEK_NUM      INT         NOT NULL,  
    WEEK_OF_YEAR_NUM     INT         NOT NULL,
    IS_WEEKEND           CHAR(1)     NOT NULL, 
    TA_INSERT_DT         DATE        NOT NULL DEFAULT CURRENT_DATE,
    
    CONSTRAINT PK_DIM_DATES PRIMARY KEY (DATE_SURR_ID),
    CONSTRAINT UK_DIM_DATES_EVENT_DT UNIQUE (EVENT_DT),
    CONSTRAINT CHK_DIM_DATES_QUARTER CHECK (QUARTER_NUM BETWEEN 1 AND 4),
    CONSTRAINT CHK_DIM_DATES_MONTH CHECK (MONTH_NUM BETWEEN 1 AND 12),
    CONSTRAINT CHK_DIM_DATES_DAY CHECK (DAY_NUM BETWEEN 1 AND 31),
    CONSTRAINT CHK_DIM_DATES_DAY_OF_WEEK CHECK (DAY_OF_WEEK_NUM BETWEEN 1 AND 7),
    CONSTRAINT CHK_DIM_DATES_WEEK_OF_YEAR CHECK (WEEK_OF_YEAR_NUM BETWEEN 1 AND 53),
    CONSTRAINT CHK_DIM_DATES_WEEKEND CHECK (IS_WEEKEND IN ('Y','N'))
);

-- =====================================
-- Populate DIM_DATES (2023–2026)
-- =====================================
-- Dummy row for unknown dates, referenced by fact tables when date is missing

-- In case we run DDL and DML scripts not together we will need clean up
-- TRUNCATE TABLE BL_DM.DIM_DATES;
-- Also we using ON CONFLICT DO NOTHING, which Only inserts new rows that don’t exist yet--safe for duplication,
-- which is usually sufficient.
INSERT INTO BL_DM.DIM_DATES (
    DATE_SURR_ID,
    EVENT_DT,
    YEAR_NUM,
    QUARTER_NUM,
    MONTH_NUM,
    DAY_NUM,
    DAY_OF_WEEK_NUM,
    WEEK_OF_YEAR_NUM,
    IS_WEEKEND,
    TA_INSERT_DT
) VALUES (
    -1,                          -- DATE_SURR_ID (default row ID)
    '0001-01-01'::DATE,          -- EVENT_DT (dummy date), use clearly out of range data, in our case could be also 1990-01-01
    0001,                        -- YEAR_NUM
    1,                           -- QUARTER_NUM
    1,                           -- MONTH_NUM
    1,                           -- DAY_NUM
    1,                           -- DAY_OF_WEEK_NUM
    1,                           -- WEEK_OF_YEAR_NUM
    'N',                         -- IS_WEEKEND
    CURRENT_DATE                 -- TA_INSERT_DT
)
ON CONFLICT (EVENT_DT) DO NOTHING;

-- =====================================
-- STEP 4: Populate DIM_DATES for range 2023–2026
-- =====================================

INSERT INTO BL_DM.DIM_DATES (
    DATE_SURR_ID,
    EVENT_DT,
    YEAR_NUM,
    QUARTER_NUM,
    MONTH_NUM,
    DAY_NUM,
    DAY_OF_WEEK_NUM,
    WEEK_OF_YEAR_NUM,
    IS_WEEKEND,
    TA_INSERT_DT
)
SELECT
    TO_NUMBER(TO_CHAR(datum,'YYYYMMDD'), '99999999') AS DATE_SURR_ID,  -- PK
    datum AS EVENT_DT,
    EXTRACT(YEAR FROM datum)::INT AS YEAR_NUM,
    EXTRACT(QUARTER FROM datum)::INT AS QUARTER_NUM,
    EXTRACT(MONTH FROM datum)::INT AS MONTH_NUM,
    EXTRACT(DAY FROM datum)::INT AS DAY_NUM,
    EXTRACT(ISODOW FROM datum)::INT AS DAY_OF_WEEK_NUM,
    EXTRACT(WEEK FROM datum)::INT AS WEEK_OF_YEAR_NUM,
    CASE WHEN EXTRACT(ISODOW FROM datum) IN (6,7) THEN 'Y' ELSE 'N' END AS IS_WEEKEND,
    CURRENT_DATE AS TA_INSERT_DT
FROM GENERATE_SERIES('2023-01-01'::DATE, '2026-12-31'::DATE, INTERVAL '1 day') AS datum(datum)
ON CONFLICT (EVENT_DT) DO NOTHING
