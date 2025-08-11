USE maven_advanced_sql;

-- Number of records
SELECT COUNT(*) AS total_schools_records FROM schools;


-- Number of NULL values in key columns
SELECT	SUM(CASE WHEN playerID IS NULL THEN 1 ELSE 0 END) AS null_playerID,
		SUM(CASE WHEN schoolID IS NULL THEN 1 ELSE 0 END) AS null_schoolID,
		SUM(CASE WHEN yearID IS NULL THEN 1 ELSE 0 END) AS null_yearID
FROM	schools;


-- Duplicates (single player, school, year)
SELECT	 playerID, schoolID, yearID, COUNT(*) AS cnt
FROM	 schools
GROUP BY playerID, schoolID, yearID
HAVING	 COUNT(*) > 1;
