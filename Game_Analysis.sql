
use game_analysis;

-- Problem Statement - Game Analysis dataset
-- 1) Players play a game divided into 3-levels (L0,L1 and L2)
-- 2) Each level has 3 difficulty levels (Low,Medium,High)
-- 3) At each level,players have to kill the opponents using guns/physical fight
-- 4) Each level has multiple stages at each difficulty level.
-- 5) A player can only play L1 using its system generated L1_code.
-- 6) Only players who have played Level1 can possibly play Level2 
--    using its system generated L2_code.
-- 7) By default a player can play L0.
-- 8) Each player can login to the game using a Dev_ID.
-- 9) Players can earn extra lives at each stage in a level.

--alter table pd modify L1_Status varchar(30);
--alter table pd modify L2_Status varchar(30);
--alter table pd modify P_ID int primary key;
--alter table pd drop myunknowncolumn;

--alter table ld drop myunknowncolumn;
--alter table ld change Dev_Id varchar(10);
--alter table ld add Difficulty varchar(15);
--alter table ld add primary key(P_ID,Dev_id,start_datetime);

-- pd (P_ID,PName,L1_status,L2_Status,L1_code,L2_Code)
-- ld (P_ID,Dev_ID,start_time,stages_crossed,level,difficulty,kill_count,
-- headshots_count,score,lives_earned)


-- Q1) Extract P_ID,Dev_ID,PName and Difficulty_level of all players 
-- at level 0

SELECT pd.P_ID,
       ld.Dev_ID,
       pd.PName,
       ld.Difficulty AS Difficulty_level
  FROM player_details pd INNER JOIN level_details2 ld ON pd.P_ID = ld.P_ID
 WHERE ld.Level = 0

-- Q2) Find Level1_code wise Avg_Kill_Count where lives_earned is 2 and atleast
--    3 stages are crossed

SELECT pd.L1_Code, AVG (CAST (ld.Kill_count AS INT)) AS Avg_kill_Count
  FROM player_details pd INNER JOIN level_details2 ld ON pd.P_ID = ld.P_ID
 WHERE ld.Lives_Earned = 2 AND ld.Stages_crossed >= 3
GROUP BY pd.L1_Code

-- Q3) Find the total number of stages crossed at each diffuculty level
-- where for Level2 with players use zm_series devices. Arrange the result
-- in decsreasing order of total number of stages crossed.

SELECT ld.Difficulty,
       SUM (CAST (ld.Stages_crossed AS INT)) AS Total_Stages_Crossed
  FROM player_details pd INNER JOIN level_details2 ld ON pd.P_ID = ld.P_ID
 WHERE ld.Level = '2' AND ld.Dev_ID LIKE '%zm_%'
GROUP BY ld.Difficulty
ORDER BY Total_Stages_Crossed DESC

-- Q4) Extract P_ID and the total number of unique dates for those players 
-- who have played games on multiple days.

SELECT pdd.P_ID, pdd.Total_Unique_Dates
  FROM (SELECT pd.P_ID, count (DISTINCT ld.TimeStamp) AS Total_Unique_Dates
          FROM    player_details pd
               INNER JOIN
                  level_details2 ld
               ON pd.P_ID = ld.P_ID
        GROUP BY pd.P_ID) pdd
 WHERE pdd.Total_Unique_Dates > 1

-- Q5) Find P_ID and level wise sum of kill_counts where kill_count
-- is greater than avg kill count for the Medium difficulty.

SELECT pd.P_ID, ld.Level, SUM (CAST (ld.Kill_count AS INT)) AS Kill_Counts
  FROM player_details pd INNER JOIN level_details2 ld ON pd.P_ID = ld.P_ID
 WHERE ld.Kill_Count >
          (SELECT AVG (CAST (ld.Kill_count AS INT)) AS Avg_kill_Count
             FROM    player_details pd
                  INNER JOIN
                     level_details2 ld
                  ON pd.P_ID = ld.P_ID
            WHERE ld.Difficulty = 'Medium')
GROUP BY pd.P_ID, ld.Level

-- Q6)  Find Level and its corresponding Level code wise sum of lives earned 
-- excluding level 0. Arrange in asecending order of level.

SELECT ld.Level,
       COALESCE (pd.L1_Code,pd.L2_Code)
          AS Level_Code,
       SUM (CAST (ld.Lives_Earned AS INT)) AS Total_Lives_Earned
  FROM player_details pd INNER JOIN level_details2 ld ON pd.P_ID = ld.P_ID
 WHERE ld.Level <> '0'
GROUP BY ld.Level, pd.L1_Code, pd.L2_Code
ORDER BY Total_Lives_Earned ASC

-- Q7) Find Top 3 score based on each dev_id and Rank them in increasing order
-- using Row_Number. Display difficulty as well. 

SELECT TOP 3
       (ld.score),
       ld.Dev_ID,
       row_number () OVER (PARTITION BY ld.Dev_ID ORDER BY ld.Score)
          AS RowNumber,
       ld.Difficulty
  FROM level_details2 ld
GROUP BY ld.Score, ld.Dev_ID, ld.Difficulty

-- Q8) Find first_login datetime for each device id

SELECT min (ld.start_time) AS First_Login, ld.Dev_ID
  FROM level_details2 ld
GROUP BY ld.Dev_ID

-- Q9) Find Top 5 score based on each difficulty level and Rank them in 
-- increasing order using Rank. Display dev_id as well.

SELECT TOP 5
       (ld.score),
       ld.difficulty,
       ld.dev_id,
       rank () OVER (PARTITION BY ld.dev_id ORDER BY score ASC) AS Rank_Order
  FROM level_details2 ld

-- Q10) Find the device ID that is first logged in(based on start_datetime) 
-- for each player(p_id). Output should contain player id, device id and 
-- first login datetime.

SELECT ld.P_ID, ld.Dev_ID, min (ld.Start_Time) AS First_Login_DateTime
  FROM level_details2 ld
GROUP BY ld.P_ID, ld.Dev_ID

-- Q11) For each player and date, how many kill_count played so far by the player. That is, the total number of games played -- by the player until that date.
-- a) window function

SELECT ld.P_ID,
       ld.Start_Time,
       sum (cast (ld.Kill_Count AS INT))
          AS Total_Games_Played
  FROM level_details2 ld
GROUP BY ld.P_ID, ld.Start_Time, ld.Kill_Count
ORDER BY ld.Start_Time

-- b) without window function

SELECT ld.P_ID,
       ld.Start_Time,
       (SELECT sum (cast (Kill_Count AS INT)) AS Total_Played
          FROM level_details2 lld
         WHERE lld.P_ID = ld.P_ID AND lld.Start_Time = ld.Start_Time)
          AS Total_Games_Played
  FROM level_details2 ld
GROUP BY ld.P_ID, ld.Start_Time, ld.Kill_Count
ORDER BY ld.Start_Time

-- Q12) Find the cumulative sum of stages crossed over a start_datetime 

SELECT ld.P_ID,
       ld.Start_Time,
       sum (cast (ld.Stages_crossed AS INT))
          AS Stages_Crossed
  FROM level_details2 ld
GROUP BY ld.P_ID, ld.Start_Time,  ld.Stages_crossed

-- Q13) Find the cumulative sum of an stages crossed over a start_datetime 
-- for each player id but exclude the most recent start_datetime

SELECT ld.P_ID,
       ld.Start_Time,
       sum (cast (ld.Stages_crossed AS INT)) AS Stages_Crossed
  FROM level_details2 ld
 WHERE ld.Start_Time <>
          (SELECT max (start_time) AS Recent_Start_DateTime
             FROM level_details2)
GROUP BY ld.P_ID, ld.Start_Time, ld.Stages_crossed

-- Q14) Extract top 3 highest sum of score for each device id and the corresponding player_id

SELECT TOP 3
       sum (cast (ld.Score AS INT)) AS Highest_Score, ld.Dev_ID, ld.P_ID
  FROM level_details2 ld
GROUP BY ld.P_ID, ld.Dev_ID
ORDER BY sum (cast (ld.Score AS INT)) DESC

-- Q15) Find players who scored more than 50% of the avg score scored by sum of 
-- scores for each player_id


SELECT ld.P_ID, sum (cast (ld.Score AS INT)) AS Total_Scores
  FROM level_details2 ld
GROUP BY ld.P_ID
HAVING sum (cast (ld.Score AS INT)) > 0.5
                                      * (SELECT avg (cast (ld.Score AS INT))
                                           FROM level_details2 ld)

-- Q16) Create a stored procedure to find top n headshots_count based on each dev_id and Rank them in increasing order
-- using Row_Number. Display difficulty as well.

CREATE PROCEDURE Top_Headshots_Count 
	-- Add the parameters for the stored procedure here
	@n INT
AS
BEGIN
	SELECT ld.Dev_Id,
		   ld.headshots_count,
		   ld.difficulty,
		   row_number ()
			  OVER (PARTITION BY ld.Dev_ID ORDER BY ld.Headshots_Count)
			  AS RowNumber
	  FROM level_details2 ld
	ORDER BY ld.Dev_Id, RowNumber

	OFFSET 0 ROWS
	FETCH next
	@n ROWS ONLY;
END
GO

EXEC	@return_value = [dbo].[Top_Headshots_Count]
		@n = 10

-- Q17) Create a function to return sum of Score for a given player_id.

CREATE FUNCTION Total_Score
(	
	-- Add the parameters for the function here
	@player_id as int
)
RETURNS int 
AS
Begin 

	declare @Total_Score as int;
	-- Add the SELECT statement with parameter references here
	SELECT @Total_Score = sum(cast(Score as int) )
	from level_details2
	where P_ID = @player_id;

	return @Total_Score;

end;
GO

SELECT [dbo].[Total_Score] (656) as Total_Score;
