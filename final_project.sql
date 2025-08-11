USE mlb_players_db;


-- PART I: SCHOOL ANALYSIS

-- 1. View the schools and school details tables
SELECT * FROM school_details;
SELECT * FROM schools;

-- 2. In each decade, how many schools were there that produced players?

-- Number of unique schoolIDs for each decade
-- IMPORTANT: If a player attended two schools, each will be counted as a school that produced players
WITH school_decades AS (SELECT	playerID, schoolID, 
								FLOOR(yearId / 10) * 10 AS decade 
						FROM	schools)
                        
SELECT	 decade,
		 COUNT(DISTINCT schoolID) AS num_of_schools
FROM	 school_decades
GROUP BY decade;

-- 3. What are the names of the top 5 schools that produced the most players (since 1980)?

-- IMPORTANT: If a player attended two schools, he will be counted as a produced player twice, for each school
SELECT	 s.schoolID, sd.name_full,
		 COUNT(DISTINCT s.playerID) AS players_produced
FROM	 schools s LEFT JOIN school_details sd
		 ON s.schoolID = sd.schoolID
WHERE	 s.yearID >= 1980
GROUP BY s.schoolID 
ORDER BY players_produced DESC
LIMIT 	 5;

-- 4. For each decade, what were the names of the top 3 schools that produced the most players?

/* School categorized by decade */
WITH s_dc AS (SELECT	schoolID, playerID, 
						FLOOR(yearId / 10) * 10 AS decade 
			  FROM		schools),
	 
     /* Schools and players they produced by decade */
     s_p_dc AS (SELECT	  s_dc.decade, s_dc.schoolID, s_dt.name_full,
						  COUNT(DISTINCT s_dc.playerID) AS players_produced
				 FROM	  s_dc LEFT JOIN school_details s_dt
						  ON s_dc.schoolID = s_dt.schoolID
				 GROUP BY s_dc.decade, s_dc.schoolID, s_dt.name_full),
	 
     /* Schools and their production rank in each decade*/
     s_pr_dc AS (SELECT	decade, schoolID, name_full, players_produced,
						ROW_NUMBER() OVER(PARTITION BY decade ORDER BY players_produced DESC) AS production_rank
				 FROM	s_p_dc)

SELECT 	 decade, name_full, players_produced 
FROM 	 s_pr_dc
WHERE	 production_rank <= 3
ORDER BY decade DESC, production_rank;


-- PART II: SALARY ANALYSIS

-- 1. View the salaries table
SELECT * FROM salaries;

-- 2. Return the top 20% of teams in terms of average annual spending
WITH ts AS (SELECT	yearID, teamID, 
					SUM(salary) AS total_annual_spending
			FROM	salaries
			GROUP BY teamID, yearID),
            
	 ts_ranked AS (SELECT	 teamID,
							 ROUND(AVG(total_annual_spending)) AS avg_annual_spending,
							 NTILE(5) OVER (ORDER BY AVG(total_annual_spending) DESC) AS percentile_group
					FROM	 ts
					GROUP BY teamID)
                    
SELECT   teamID, 
		 ROUND(avg_annual_spending / 1000000, 1) AS avg_annual_spending_millions
FROM	 ts_ranked
WHERE	 percentile_group = 1
ORDER BY avg_annual_spending DESC;


-- 3. For each team, show the cumulative sum of spending over the years
WITH ts AS (SELECT	yearID, teamID, 
					SUM(salary) AS total_annual_spending
			FROM	salaries
			GROUP BY teamID, yearID)

SELECT	teamID, yearID,
		ROUND(
			SUM(total_annual_spending) OVER (PARTITION BY teamID ORDER BY yearID) / 1000000,
			1
		) AS cumulative_annual_spending_millions
FROM	ts;

-- 4. Return the first year that each team's cumulative spending surpassed 1 billion
WITH ts AS (SELECT	yearID, teamID, 
					SUM(salary) AS total_annual_spending
			FROM	salaries
			GROUP BY teamID, yearID),
	 
     cs AS (SELECT	teamID, yearID,
					SUM(total_annual_spending) OVER (
						PARTITION BY teamID ORDER BY yearID
					) AS cumulative_annual_spending
			FROM	ts),
            
	 cs_over_billion AS (SELECT	  teamID, yearID, cumulative_annual_spending,
								  ROW_NUMBER() OVER (PARTITION BY teamID ORDER BY yearID) AS rn
						 FROM	  cs
						 WHERE	  cumulative_annual_spending >= 1000000000)

SELECT	teamID, yearID,
		ROUND(cumulative_annual_spending / 1000000000, 2) AS cumulative_annual_spending_billions 
FROM	cs_over_billion
WHERE	rn = 1;


-- PART III: PLAYER CAREER ANALYSIS

-- 1. View the players table and find the number of players in the table
SELECT * FROM players;
SELECT COUNT(playerID) FROM players;

-- 2. For each player, calculate their age at their first game, their last game, and their career length (all in years). Sort from longest career to shortest career.
WITH pb AS (SELECT	playerID,
					nameGiven,
					debut, 
					finalGame,
                    CAST(CONCAT(birthYear, '-', birthMonth, '-', birthDay) AS DATE) AS birthDate
			FROM players)

SELECT	 nameGiven,
		 TIMESTAMPDIFF(YEAR, birthDate, debut) AS debut_age,
		 TIMESTAMPDIFF(YEAR, birthDate, finalGame) AS final_game_age,
         TIMESTAMPDIFF(YEAR, debut, finalGame) AS career_length
FROM	 pb
ORDER BY career_length DESC;

-- 3. What team did each player play on for their starting and ending years?            
SELECT	p.nameGiven,
        s1.yearID AS starting_year, s1.teamID AS starting_team,
		s2.yearID AS ending_year, s2.teamID AS ending_team
FROM	players p INNER JOIN salaries s1
					ON p.playerID = s1.playerID 
					AND YEAR(p.debut) = s1.yearID
				  INNER JOIN salaries s2
					ON p.playerID = s2.playerID 
                    AND YEAR(p.finalGame) = s2.yearID;
        
-- 4. How many players started and ended on the same team and also played for over a decade?
WITH pa AS (SELECT	p.nameGiven,
					s1.yearID AS starting_year, s1.teamID AS starting_team,
					s2.yearID AS ending_year, s2.teamID AS ending_team
			FROM	players p INNER JOIN salaries s1
								ON p.playerID = s1.playerID 
								AND YEAR(p.debut) = s1.yearID
							  INNER JOIN salaries s2
								ON p.playerID = s2.playerID 
								AND YEAR(p.finalGame) = s2.yearID)

SELECT	COUNT(*) 
FROM	pa
WHERE	starting_team = ending_team 
		AND (ending_year - starting_year) > 10;


-- PART IV: PLAYER COMPARISON ANALYSIS

-- 1. View the players table
SELECT * FROM players;

-- 2. Which players have the same birthday?
WITH p_bd AS (SELECT	CAST(CONCAT(birthYear, '-', birthMonth, '-', birthDay) AS DATE) AS birth_date,
						nameGiven
			  FROM		players
              WHERE		birthYear IS NOT NULL 
						AND birthMonth IS NOT NULL
                        AND birthDay IS NOT NULL)

SELECT	 birth_date,
		 GROUP_CONCAT(nameGiven SEPARATOR ', ') AS players
FROM	 p_bd
WHERE	YEAR(birth_date) BETWEEN 1980 AND 2000
GROUP BY birth_date
ORDER BY birth_date;

-- 3. Create a summary table that shows for each team, what percent of players bat right, left and both

-- This is summary for each team for it's whole history 
WITH sp AS (SELECT  DISTINCT s.teamID, s.playerID, p.bats 
			FROM	salaries s LEFT JOIN players p
					ON s.playerID = p.playerID)

SELECT	 teamID,
		 ROUND((COUNT(CASE WHEN bats = 'R' THEN 1 END) / COUNT(*)) * 100, 1) AS bat_right_pcnt,
		 ROUND((COUNT(CASE WHEN bats = 'L' THEN 1 END) / COUNT(*)) * 100, 1) AS bat_left_pcnt,
		 ROUND((COUNT(CASE WHEN bats = 'B' THEN 1 END) / COUNT(*)) * 100, 1) AS bat_both_pcnt
FROM	 sp
GROUP BY teamID;

-- This is year to year stats for each team
WITH pb AS (SELECT	s.yearID, s.teamID, s.playerID, p.nameGiven,
					CASE WHEN bats = 'R' THEN 1 END AS bat_right,
					CASE WHEN bats = 'L' THEN 1 END AS bat_left,
					CASE WHEN bats = 'B' THEN 1 END AS bat_both
			FROM	salaries s LEFT JOIN players p
					ON s.playerID = p.playerID)

SELECT	 yearID, teamID,
		 ROUND((COUNT(bat_right) / COUNT(*)) * 100, 2) AS bat_right_pcnt,
		 ROUND((COUNT(bat_left) / COUNT(*)) * 100, 2) AS bat_left_pcnt,
		 ROUND((COUNT(bat_both) / COUNT(*)) * 100, 2) AS bat_both_pcnt
FROM	 pb
GROUP BY yearID, teamID;

-- 4. How have average height and weight at debut game changed over the years, and what's the decade-over-decade difference?

-- Difference over the years
WITH ys AS (SELECT	YEAR(debut) AS debut_year,
					ROUND(AVG(weight), 1) AS avg_weight_yr,
					ROUND(AVG(height), 1) AS avg_height_yr
			FROM	players
			WHERE	debut IS NOT NULL 
			GROUP BY YEAR(debut)
			ORDER BY debut_year)
            
SELECT	debut_year,
		avg_weight_yr,
		avg_height_yr,
        avg_weight_yr - LAG(avg_weight_yr) OVER (ORDER BY debut_year) AS prior_weight_diff,
        avg_height_yr - LAG(avg_height_yr) OVER (ORDER BY debut_year) AS prior_height_diff
FROM	ys;

-- Difference over decades
WITH ds AS (SELECT	 FLOOR(YEAR(debut) / 10) * 10 AS decade,
					 ROUND(AVG(weight), 1) AS avg_weight_dec,
					 ROUND(AVG(height), 1) AS avg_height_dec
			FROM	 players
            WHERE	 debut IS NOT NULL
            GROUP BY decade)

SELECT	decade,
		avg_weight_dec,
		avg_height_dec,
        avg_weight_dec - LAG(avg_weight_dec) OVER (ORDER BY decade) AS prior_weight_diff,
        avg_height_dec - LAG(avg_height_dec) OVER (ORDER BY decade) AS prior_height_diff
FROM	ds;
