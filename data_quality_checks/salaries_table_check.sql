USE maven_advanced_db;

-- Number of records
SELECT COUNT(*) AS total_salaries FROM salaries;


-- Duplicate check (single player, year, team, league)
SELECT	 playerID, yearID, teamID, lgID, COUNT(*) AS cnt
FROM	 salaries
GROUP BY playerID, yearID, teamID, lgID
HAVING	 COUNT(*) > 1;


-- Number of NULL values in key columns
SELECT	SUM(CASE WHEN playerID IS NULL THEN 1 ELSE 0 END) AS null_playerID,
		SUM(CASE WHEN teamID IS NULL THEN 1 ELSE 0 END) AS null_teamID,
		SUM(CASE WHEN lgID IS NULL THEN 1 ELSE 0 END) AS null_lgID,
		SUM(CASE WHEN yearID IS NULL THEN 1 ELSE 0 END) AS null_yearID,
		SUM(CASE WHEN salary IS NULL THEN 1 ELSE 0 END) AS null_salary
FROM	salaries;


-- Negative or zero salaries
SELECT	*
FROM	salaries
WHERE	salary <= 0;


-- Invalid teamID and lgID values
SELECT DISTINCT lgID FROM salaries WHERE lgID NOT IN ('NL', 'AL');
SELECT DISTINCT teamID FROM salaries WHERE LENGTH(teamID) != 3; -- all teams have 3-letter code 
