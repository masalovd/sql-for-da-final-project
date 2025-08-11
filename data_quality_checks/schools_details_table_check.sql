USE maven_advanced_sql;

-- Number of records
SELECT COUNT(*) AS total_school_details FROM school_details;


-- Duplicate check (single school)
SELECT	 schoolID, COUNT(*) AS cnt
FROM	 school_details
GROUP BY schoolID
HAVING	 COUNT(*) > 1;


-- Number of NULL values in key columns
SELECT
    SUM(CASE WHEN schoolID IS NULL THEN 1 ELSE 0 END) AS null_schoolID,
    SUM(CASE WHEN nameFull IS NULL THEN 1 ELSE 0 END) AS null_nameFull,
    SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS null_country
FROM school_details;


-- Name anomalies (school names that are too short)
SELECT	*
FROM	school_details
WHERE	LENGTH(name_full) < 10;