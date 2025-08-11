USE mlb_players_db;

-- Number of records
SELECT COUNT(*) AS total_players FROM players;


-- Primary key (playerID) uniqueness
SELECT	 playerID, COUNT(*) AS cnt
FROM	 players
GROUP BY playerID
HAVING	 COUNT(*) > 1;


-- Number of NULL values in key columns
SELECT	SUM(CASE WHEN playerID IS NULL THEN 1 ELSE 0 END) AS null_playerID,
		SUM(CASE WHEN birthYear IS NULL THEN 1 ELSE 0 END) AS null_birth_year,
		SUM(CASE WHEN birthMonth IS NULL THEN 1 ELSE 0 END) AS null_birth_month,
		SUM(CASE WHEN birthDay IS NULL THEN 1 ELSE 0 END) AS null_birth_day,
		SUM(CASE WHEN birthCountry IS NULL THEN 1 ELSE 0 END) AS null_birth_country,
		SUM(CASE WHEN birthState IS NULL THEN 1 ELSE 0 END) AS null_birth_state,
		SUM(CASE WHEN birthCity IS NULL THEN 1 ELSE 0 END) AS null_birth_city,
		SUM(CASE WHEN nameFirst IS NULL THEN 1 ELSE 0 END) AS null_first_name,
		SUM(CASE WHEN nameLast IS NULL THEN 1 ELSE 0 END) AS null_last_name,
		SUM(CASE WHEN weight IS NULL THEN 1 ELSE 0 END) AS null_weight,
		SUM(CASE WHEN height IS NULL THEN 1 ELSE 0 END) AS null_height,
		SUM(CASE WHEN bats IS NULL THEN 1 ELSE 0 END) AS null_bats,
		SUM(CASE WHEN throws IS NULL THEN 1 ELSE 0 END) AS null_throws,
		SUM(CASE WHEN debut IS NULL THEN 1 ELSE 0 END) AS null_debut,
		SUM(CASE WHEN finalGame IS NULL THEN 1 ELSE 0 END) AS null_finalGame
FROM	players;


-- Wrong dates (finalGame < debut or dates in the future)
SELECT	*
FROM	players
WHERE	finalGame < debut
		OR	debut > CURDATE()
		OR finalGame > CURDATE();


-- Number of outlier weight/height values (in inches for height, and in pounds for weight)

-- For identifying how many outliers we have we use Q1 - 1.5*IQR and Q3 + 1.5*IQR bounds
-- All values that are below lower bound or above upper bound will be classified as outliers
WITH hq AS (SELECT	quartiles.Q1,
					quartiles.Q3,
					quartiles.Q3 - quartiles.Q1 AS IQR,
					quartiles.Q1 - 1.5 * (quartiles.Q3 - quartiles.Q1) AS lower_bound,
					quartiles.Q3 + 1.5 * (quartiles.Q3 - quartiles.Q1) AS upper_bound
			FROM (
				SELECT	MAX(CASE WHEN rn <= total * 0.25 THEN height END) AS Q1,
						MIN(CASE WHEN rn >= total * 0.75 THEN height END) AS Q3
				FROM (
					SELECT	 height,
							 ROW_NUMBER() OVER (ORDER BY height) AS rn,
							 COUNT(height) OVER () AS total
					FROM	 players
					WHERE	 height IS NOT NULL
					ORDER BY height
				) AS sorted_data
			) AS quartiles),
            
	 wq AS (SELECT	quartiles.Q1,
					quartiles.Q3,
					quartiles.Q3 - quartiles.Q1 AS IQR,
					quartiles.Q1 - 1.5 * (quartiles.Q3 - quartiles.Q1) AS lower_bound,
					quartiles.Q3 + 1.5 * (quartiles.Q3 - quartiles.Q1) AS upper_bound
		   FROM (
				SELECT	MAX(CASE WHEN rn <= total * 0.25 THEN weight END) AS Q1,
						MIN(CASE WHEN rn >= total * 0.75 THEN weight END) AS Q3
				FROM (
					SELECT	 weight,
							 ROW_NUMBER() OVER (ORDER BY weight) AS rn,
							 COUNT(weight) OVER () AS total
					FROM	 players
					WHERE	 weight IS NOT NULL
					ORDER BY weight
				) AS sorted_data
			) AS quartiles)

SELECT	*
FROM	players p, hq, wq
WHERE	p.height NOT BETWEEN hq.lower_bound AND hq.upper_bound
		OR p.weight NOT BETWEEN wq.lower_bound AND wq.upper_bound;

-- Invalid bats/throws values
SELECT DISTINCT bats FROM players WHERE bats NOT IN ('R', 'L', 'B') AND bats IS NOT NULL;
SELECT DISTINCT throws FROM players WHERE throws NOT IN ('R', 'L') AND throws IS NOT NULL;
