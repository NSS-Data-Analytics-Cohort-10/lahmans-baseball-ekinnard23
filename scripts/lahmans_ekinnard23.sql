### Use SQL queries to find answers to the *Initial Questions*. If time permits, choose one (or more) of the *Open-Ended Questions*. Toward the end of the bootcamp, we will revisit this data if time allows to combine SQL, Excel Power Pivot, and/or Python to answer more of the *Open-Ended Questions*.



**Initial Questions**

1. What range of years for baseball games played does the provided database cover? 

SELECT MIN(yearid), MAX(yearid)
FROM teams
--1871-2016

2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?

SELECT*
FROM appearances

SELECT namefirst,
	namelast,
	height,
	teams.teamid,
	teams.name,
	appearances.g_all	
FROM people
LEFT JOIN appearances
USING (playerid)
LEFT JOIN teams
USING (teamid)
ORDER BY height ASC
LIMIT 1

--Eddie Gaedel - St. Louis Browns - 1 game


3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?
SELECT*
FROM salaries
ORDER BY schoolname DESC

SELECT people.namefirst,
	people.namelast,
	schools.schoolname,
	salaries.yearid,
	SUM(salary)::numeric::money 
FROM people
INNER JOIN salaries
USING (playerid)
INNER JOIN collegeplaying
USING (playerid)
INNER JOIN schools
ON collegeplaying.schoolid = schools.schoolid
WHERE schools.schoolname = 'Vanderbilt University'
GROUP BY people.namefirst, people.namelast, salaries.salary, schools.schoolname,salaries.yearid
ORDER BY salaries.salary DESC

--David Price - Vanderbilt - $245,553,888
	

4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.
 
SELECT playerid,
	yearid,
	pos,
	po,
	CASE WHEN pos = 'OF' THEN 'OUTFIELD'
	WHEN pos = 'SS' OR pos = '1B' OR pos = '2B' OR pos = '3B' THEN 'INFIELD'
	WHEN pos = 'P' OR pos = 'C' THEN 'Battery' END AS position
FROM fielding	 

WITH position AS (SELECT playerid,
	yearid,
	pos,
	po,
	CASE WHEN pos = 'OF' THEN 'OUTFIELD'
	WHEN pos = 'SS' OR pos = '1B' OR pos = '2B' OR pos = '3B' THEN 'INFIELD'
	WHEN pos = 'P' OR pos = 'C' THEN 'Battery' END AS position
FROM fielding)

SELECT position, 
	SUM(f.po) AS po_per_position
FROM position
INNER JOIN fielding AS f
USING (playerid)
WHERE f.yearid = 2016
GROUP BY position

--Battery 317,472 Infield 689,431 Outfield 285,322


5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

SELECT CASE WHEN RIGHT(yearid::text, 2):: integer BETWEEN 10 AND 19 THEN '2010s'
	WHEN RIGHT(yearid::text, 2):: integer BETWEEN 20 AND 29 THEN '1920s'
	WHEN RIGHT(yearid::text, 2):: integer BETWEEN 30 AND 39 THEN '1930s'
	WHEN RIGHT(yearid::text, 2):: integer BETWEEN 40 AND 49 THEN '1940s'
	WHEN RIGHT(yearid::text, 2):: integer BETWEEN 50 AND 59 THEN '1950s'
	WHEN RIGHT(yearid::text, 2):: integer BETWEEN 60 AND 69 THEN '1960s'
	WHEN RIGHT(yearid::text, 2):: integer BETWEEN 70 AND 79 THEN '1970s'
	WHEN RIGHT(yearid::text, 2):: integer BETWEEN 80 AND 89 THEN '1980s'
	WHEN RIGHT(yearid::text, 2):: integer BETWEEN 90 AND 99 THEN '1990s'
	WHEN RIGHT(yearid::text, 2):: integer BETWEEN 00 AND 09 THEN '2000s'
	ELSE 'ERROR' END AS decade,
	ROUND(AVG(soa * 1.0/g), 2) AS strikeouts_per_game,
	ROUND(AVG(HR * 1.0/g), 2) AS homeruns_per_game
FROM teams
WHERE yearid > 1919
GROUP BY decade
ORDER BY decade

--Each metric has more than doubled

6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.

SELECT namefirst,
	namelast,
	sb,
	cs,
	sb+cs AS sbcs,
	ROUND((sb * 1.0/(sb+cs)) * 100, 2) AS sb_success
FROM batting
INNER JOIN people
USING(playerid)
WHERE yearid = 2016 AND sb+cs >= 20
ORDER BY sb_success DESC

--Chris Owings 91.3%

7.a  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 

SELECT*
FROM teams
WHERE wswin = 'N'
	AND yearid >= 1970
ORDER BY w DESC

--116

7.b What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. 

SELECT*
FROM teams
WHERE wswin = 'N'
	AND yearid >= 1970
ORDER BY w ASC

--37

7.c Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?



WITH league_win_rank AS (SELECT name,
						w,
						wswin,
						Rank() OVER (PARTITION BY yearid ORDER BY w DESC) AS 							total_league_win_rank
						FROM teams
						WHERE yearid <>1981
						AND yearid >= 1970
						ORDER BY total_league_win_rank)
SELECT COUNT(*) AS wins_for_team_w_most_wins,
	ROUND((COUNT(*)*1.0/46) * 100, 2) AS wins_for_team_w_most_wins_percentage
FROM league_win_rank
WHERE wswin = 'Y'
	AND total_league_win_rank = 1

--12 teams - 26.09%

8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

WITH top_2016_attendance AS (SELECT park_name,
								team,
								homegames.attendance/games AS avg_attendance
						FROM homegames
						INNER JOIN parks
						USING(park)
						WHERE games >=10 AND year = 2016
						ORDER BY avg_attendance DESC
						LIMIT 5)
							
SELECT park_name,
	teams.name,
	avg_attendance
	FROM top_2016_attendance
	JOIN teams
	ON teams.teamid = top_2016_attendance.team
	WHERE yearid =2016

WITH bottom_2016_attendance AS (SELECT park_name,
								team,
								homegames.attendance/games AS avg_attendance
						FROM homegames
						INNER JOIN parks
						USING(park)
						WHERE games >=10 AND year = 2016
						ORDER BY avg_attendance ASC
						LIMIT 5)
							
SELECT park_name,
	teams.name,
	avg_attendance
	FROM bottom_2016_attendance
	JOIN teams
	ON teams.teamid = bottom_2016_attendance.team
	WHERE yearid =2016
	
--TOP: Dodgers/Dodger Stadium, Cartinals/Busch Stadium, Blue Jays/Rogers Centre, Giants/AT&T Park, Cubs/Wrigley Field
--BOTTOM: Rays/Tropicana Field, Athletics/Alameda Coliseum, Indians/Progressive Field, Marlins/Marlins Park, White Sox/US Cellular

9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players'0' first and last names and the number of home runs they hit in 2016.


**Open-ended questions**

11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

12. In this question, you will explore the connection between number of wins and attendance.
    <ol type="a">
      <li>Does there appear to be any correlation between attendance at home games and number of wins? </li>
      <li>Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.</li>
    </ol>


13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?
