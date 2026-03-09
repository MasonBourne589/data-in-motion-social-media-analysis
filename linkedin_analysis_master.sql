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
