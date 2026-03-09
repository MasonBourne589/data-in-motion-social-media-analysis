SHOW TABLES;
DESCRIBE li_engagement;
DESCRIBE li_followers;

CREATE OR REPLACE VIEW li_engagement_clean AS
SELECT
    STR_TO_DATE(Date, '%m/%d/%Y') AS Date,
    Impressions,
    Engagements,
    CASE 
        WHEN Impressions > 0 THEN Engagements / Impressions
        ELSE NULL
    END AS engagement_rate
    FROM li_engagement;


SELECT * 
FROM li_engagement_clean
LIMIT 10;


CREATE OR REPLACE VIEW li_daily_combined AS
SELECT
    e.Date,
    e.Impressions,
    e.Engagements,
    e.engagement_rate,
    f.`New followers` AS new_followers
FROM li_engagement_clean e
LEFT JOIN li_followers f
    ON DATE(e.Date) = DATE(f.Date);
    
    SELECT *
FROM li_daily_combined
ORDER BY Date
LIMIT 15;



-- Insight 1: Correlation Style Check
SELECT
    ROUND(AVG(engagement_rate), 4) AS avg_engagement_rate,
    ROUND(AVG(new_followers), 2) AS avg_new_followers
FROM li_daily_combined;

SELECT
    CASE 
        WHEN engagement_rate >= 0.01 THEN 'High Engagement'
        ELSE 'Low Engagement'
    END AS engagement_bucket,
    ROUND(AVG(new_followers), 2) AS avg_new_followers,
    COUNT(*) AS days_count
FROM li_daily_combined
GROUP BY engagement_bucket;

-- Insight 2: Top Engagemenet Days 
SELECT *
FROM li_daily_combined
ORDER BY engagement_rate DESC
LIMIT 10;

-- Insight 3: Follower Spike Days
SELECT *
FROM li_daily_combined
ORDER BY new_followers DESC
LIMIT 10;

-- 
SELECT 
    CASE 
        WHEN Impressions >= 30000 THEN 'High Reach'
        ELSE 'Low Reach'
    END AS reach_bucket,
    ROUND(AVG(new_followers), 2) AS avg_new_followers,
    COUNT(*) AS days_count
FROM li_daily_combined
GROUP BY reach_bucket;

SELECT *
FROM li_top_posts
ORDER BY Impressions DESC
LIMIT 15;

SELECT *
FROM li_top_posts
WHERE `Data Source` = 'Both'
ORDER BY Impressions DESC
LIMIT 15;

/*
   Clean Top Posts View
   - Convert text fields to numeric
   - Recalculate engagement rate
   - Prepare for analysis & Tableau
*/
CREATE OR REPLACE VIEW li_top_posts_clean AS
SELECT
    `Post URL`,
    `Publish Date`,
    CAST(REPLACE(Impressions, ',', '') AS UNSIGNED) AS Impressions,
    CAST(REPLACE(Engagements, ',', '') AS UNSIGNED) AS Engagements,
    CASE 
        WHEN CAST(REPLACE(Impressions, ',', '') AS UNSIGNED) > 0
        THEN CAST(REPLACE(Engagements, ',', '') AS UNSIGNED) 
             / CAST(REPLACE(Impressions, ',', '') AS UNSIGNED)
        ELSE NULL
    END AS engagement_rate,
    `Data Source`
FROM li_top_posts;

SELECT 
    Impressions,
    ROUND(engagement_rate, 4) AS engagement_rate,
    Engagements,
    `Publish Date`,
    `Data Source`
FROM li_top_posts_clean
ORDER BY Impressions DESC
LIMIT 15;

SELECT 
    Impressions,
    ROUND(engagement_rate, 4) AS engagement_rate,
    Engagements,
    `Publish Date`,
    `Data Source`
FROM li_top_posts_clean
ORDER BY Impressions DESC
LIMIT 15;

SELECT 
    ROUND(AVG(engagement_rate), 4) AS avg_er_high_reach
FROM li_top_posts_clean
WHERE Impressions >= 100000;

SELECT 
    ROUND(AVG(engagement_rate), 4) AS avg_er_low_reach
FROM li_top_posts_clean
WHERE Impressions < 100000;



-- =========================================================
-- LinkedIn Performance Analysis Project
-- Database: linkedin_analysis
-- Purpose: Clean, transform, and prepare data for Tableau
-- =========================================================

SHOW CREATE VIEW li_engagement_clean;

SHOW CREATE VIEW li_daily_combined;

SHOW CREATE VIEW li_top_posts_clean;


-- =====================================
-- Daily Combined View
-- =====================================
CREATE OR REPLACE VIEW li_daily_combined AS
SELECT 
    e.Date AS Date,
    e.Impressions AS Impressions,
    e.Engagements AS Engagements,
    e.engagement_rate AS engagement_rate,
    f.`New followers` AS new_followers
FROM li_engagement_clean e
LEFT JOIN li_followers f
    ON CAST(e.Date AS DATE) = CAST(f.Date AS DATE);
    
    -- =====================================
-- Clean Daily Engagement (Date + Impressions + Engagements + Rate)
-- Fixes Date parsing + calculates engagement_rate safely
-- =====================================
CREATE OR REPLACE VIEW li_engagement_clean AS
SELECT
    STR_TO_DATE(Date, '%m/%d/%Y') AS Date,
    Impressions,
    Engagements,
    CASE
        WHEN Impressions > 0 THEN Engagements / Impressions
        ELSE NULL
    END AS engagement_rate
FROM li_engagement;

-- =====================================
-- Clean Top Posts (robust casting)
-- Handles commas + blanks safely + calculates engagement_rate
-- =====================================
CREATE OR REPLACE VIEW li_top_posts_clean AS
SELECT
    `Post URL` AS `Post URL`,
    `Publish Date` AS `Publish Date`,

    -- Convert impressions to integer safely (blanks -> NULL)
    CAST(NULLIF(REPLACE(Impressions, ',', ''), '') AS UNSIGNED) AS Impressions,

    -- Convert engagements to integer safely (blanks -> NULL)
    CAST(NULLIF(REPLACE(Engagements, ',', ''), '') AS UNSIGNED) AS Engagements,

    -- Safe engagement rate
    CASE
        WHEN CAST(NULLIF(REPLACE(Impressions, ',', ''), '') AS UNSIGNED) > 0
        THEN CAST(NULLIF(REPLACE(Engagements, ',', ''), '') AS UNSIGNED)
             / CAST(NULLIF(REPLACE(Impressions, ',', ''), '') AS UNSIGNED)
        ELSE NULL
    END AS engagement_rate,

    `Data Source` AS `Data Source`
FROM li_top_posts;

-- =====================================
-- Tableau Export Tables (Frozen snapshots)
-- =====================================

DROP TABLE IF EXISTS li_dashboard_daily;

CREATE TABLE li_dashboard_daily AS
SELECT
    Date,
    Impressions,
    Engagements,
    CAST(engagement_rate AS DECIMAL(10,6)) AS engagement_rate,
    new_followers
FROM li_daily_combined;


DROP TABLE IF EXISTS li_dashboard_posts;

CREATE TABLE li_dashboard_posts AS
SELECT
    `Post URL`,
    `Publish Date`,
    Impressions,
    Engagements,
    CAST(engagement_rate AS DECIMAL(10,6)) AS engagement_rate,
    `Data Source`
FROM li_top_posts_clean;

SELECT COUNT(*) FROM li_dashboard_daily;
SELECT COUNT(*) FROM li_dashboard_posts;

SELECT * FROM li_dashboard_daily;

SELECT * FROM li_dashboard_posts;

