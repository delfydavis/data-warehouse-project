/*
***DATAWAREHOUSE CREATION AND QUERIES TO RETRIEVE THE REQUIRED INFORMATION***
*/



/*DATA CLEANING
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--TABLE LOCUMDETAILS
CHECKING UNIQUNESS OF PRIMARY CONTRAINT IN LOCUMDETAILS TABLE
*/
SELECT LocumID
FROM LOCUMDETAILS
GROUP BY LocumID
HAVING COUNT(LocumID) > 1

--RESULT NO DUPLICATION FOUND
--MAKING BLACK SPACE CELL TO NULL VALUE
SELECT *
FROM LOCUMDETAILS

SELECT LocumID
FROM LOCUMDETAILS
GROUP BY LocumID
HAVING COUNT(LocumID) > 1

SELECT *
FROM SESSION

SELECT *
FROM [Template_Type of Cover]

-----------------------------------------------------------------------------------------------------------------------
--CLEANING SESSION TABLE
--CHECKING FOR THE REQUESTID IN SESSION TABLE WHICH IS NOT PRESENT IN THE LOCUMREQUEST TABLE
SELECT RequestID
FROM SESSION S
WHERE ISNULL(RequestID, 0) NOT IN (
		SELECT LocumRequestID
		FROM LOCUMREQUEST
		)

--NO RESULT FOUND
--CHECKING FOR THE LOCUMID WHICH IS NOT PRESENT IN THE LOCUM TABLE
SELECT LocumID
FROM SESSION S
WHERE ISNULL(LocumID, 0) NOT IN (
		SELECT LocumID
		FROM LOCUMDETAILS
		)

/*RESULT FOUND WITH LOCUMID WHICH IS NOT PRESNT IN LOCUM TABLE */
--REMOVING THOES DATA FROM THE SESSION TABLE AS THAT IS NOT RELEVANT
DELETE
FROM SESSION
WHERE ISNULL(LocumID, 0) NOT IN (
		SELECT LocumID
		FROM LOCUMDETAILS
		)

--CHECKING FOR THE TYPEID WHICH IS NOT PRESENT IN THE TEMPLATE_TYPECOVER TABLE
SELECT TYPE
FROM SESSION S
WHERE ISNULL(Type, 0) NOT IN (
		SELECT TypeofCoverID
		FROM [Template_Type of Cover]
		)

--RESULT TYPE 0 IN SESSION TABLE IS NOT MATCHING WITH TypeofCoverID IN [Template_Type of Cover] TABLE
--DELETING UNMACTED DATAS FROM SESSION TABLE
DELETE
FROM SESSION
WHERE ISNULL(Type, 0) NOT IN (
		SELECT TypeofCoverID
		FROM [Template_Type of Cover]
		)

--REMOVING UNWANTED COLUMN FROM SESSION TABLE WHICH IS HAVING ONLY NULL VALUES (DoctorCovered,DoPrint)
ALTER TABLE SESSION

DROP COLUMN DoctorCovered

ALTER TABLE SESSION

DROP COLUMN DoPrint

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--CLEANING LOCUMREQUEST TABLE
--droping column type of cover ,startdate ,enddate ,monday am,etc as they are empTy 
SELECT *
FROM LOCUMREQUEST

ALTER TABLE LOCUMREQUEST

DROP COLUMN [Type of Cover]
	,[Start date]
	,[End date]
	,[Monday AM]
	,[Monday PM]
	,[Tuesday AM]
	,[Tuesday PM]
	,[Wednesday AM]
	,[Wednesday PM]
	,[Thursday AM]
	,[Thursday PM]
	,[Friday AM]
	,[Friday PM]
	,[Saturday AM]
	,[Request Status]
	,[Number of weeks]
	,[Comments]

--CHECKING DUPLICATE --
SELECT PracticeID
	,COUNT(PracticeID)
FROM [Practice Details]
GROUP BY PracticeID
HAVING COUNT(PracticeID) > 1

-- NO RESULT FOUND
--CHECKING DUPLICATE LocumRequestID 
SELECT LocumRequestID
	,COUNT(LocumRequestID)
FROM LOCUMREQUEST
GROUP BY LocumRequestID
HAVING COUNT(LocumRequestID) > 1

-- NO RESULT FOUND 
--CHECKING DUPLICATE value in LOCUMREQUEST  --
SELECT L.PracticeID
FROM LOCUMREQUEST L
WHERE ISNULL(L.PracticeID, 0) NOT IN (
		SELECT PracticeID
		FROM [Practice Details]
		)

--NO RESULT FOUND
--CLEANING TABLE TEMPLATE_TYPE OF COVER
SELECT *
FROM [Template_Type of Cover]

SELECT TypeofCoverID
	,COUNT(TypeofCoverID)
FROM [Template_Type of Cover]
GROUP BY TypeofCoverID
HAVING COUNT(TypeofCoverID) > 1

--Result: no id found so this table doesnot violate unique key constraint.
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
DATAWAREHOUSE CREATION
**********************
AS FOR THE GIVEN  ML SOLUTION    WE ARE JUST  NEED OF FOUR MAIN TABLES ,i.e SESSION TABLE,[Template_Type of Cover],LOCUMREQUEST,TIMETABLE, LOCUMDETAILS AND PRACTISE DETAILS

*/
--Populating Tables--
----------------------
SELECT *
FROM SESSION

SELECT DATEPART(DAYOFYEAR, '2020-07-01')

-- fact table (DW_Session)and dimension tables are created using GUI of sql server management studio
--Insertion into Fact table and Time Table using Cursor
DECLARE @SessionID INT
	,@RequestID INT
	,@LocumID INT
	,@SessionDate DATETIME
	,@SessionStart DATETIME
	,@SessionEnd DATETIME
	,@SessionLength INT
	,@Sessionyear INT
	,@Sessionmonth INT
	,@Sessionweek INT
	,@SessionDayofyear INT
	,@Status VARCHAR(15)
	,@Type VARCHAR(10);

DECLARE c_Cursor CURSOR
FOR
SELECT convert(INT, SessionID)
	,convert(INT, RequestID)
	,convert(INT, LocumID)
	,convert(DATETIME, SessionDate)
	,convert(DATETIME, SessionStart)
	,convert(DATETIME, SessionEnd)
	,datediff(MINUTE, convert(DATETIME, SessionStart), convert(DATETIME, SessionEnd))
	,DATEPART(YEAR, SessionDate)
	,DATEPART(month, SessionDate)
	,DATEPART(WEEK, SessionDate)
	,DATEPART(DAYOFYEAR, SessionDate)
	,convert(VARCHAR, STATUS)
	,Type
FROM SESSION;

OPEN c_Cursor

FETCH NEXT
FROM c_Cursor
INTO @SessionID
	,@RequestID
	,@LocumID
	,@SessionDate
	,@SessionStart
	,@SessionEnd
	,@SessionLength
	,@Sessionyear
	,@Sessionmonth
	,@Sessionweek
	,@SessionDayofyear
	,@Status
	,@Type

WHILE @@FETCH_STATUS = 0
BEGIN
	INSERT INTO DW_SESSION (
		SessionId
		,RequestID
		,LocumID
		,SessionDate
		,SessionStart
		,SessionEnd
		,STATUS
		,Type
		,SessionLength
		)
	VALUES (
		@SessionID
		,@RequestID
		,@LocumID
		,@SessionDate
		,@SessionStart
		,@SessionEnd
		,@Status
		,@Type
		,@SessionLength
		)

	INSERT INTO DW_SessionTimetable (
		SessionDate
		,Year
		,month
		,Week
		,S_Dayofyear
		)
	VALUES (
		@SessionDate
		,@Sessionyear
		,@Sessionmonth
		,@Sessionweek
		,@SessionDayofyear
		)

	FETCH NEXT
	FROM c_Cursor
	INTO @SessionID
		,@RequestID
		,@LocumID
		,@SessionDate
		,@SessionStart
		,@SessionEnd
		,@SessionLength
		,@Sessionyear
		,@Sessionmonth
		,@Sessionweek
		,@SessionDayofyear
		,@Status
		,@Type;
END

CLOSE c_Cursor;

DEALLOCATE c_Cursor;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
Using Cursor timetable and DW_Session table has been populated but timetable has been populated with some duplicate value so below code removes the duplicate 
values from time table
*/
SELECT SessionDate
	,count(S_Dayofyear)
FROM DW_SessionTimetable
GROUP BY SessionDate
HAVING count(S_Dayofyear) > 1
/*
  Here we are using common table expression (cte) to delete duplicate rows.Row_num function find all the duplicate rows from the mentioned coloumn and then thoes rows are deleted.
  */
WITH cte AS (
		SELECT *
			,ROW_NUMBER() OVER (
				PARTITION BY SessionDate
				,S_Dayofyear ORDER BY SessionDate
					,S_Dayofyear
				) row_num
		FROM DW_SessionTimetable
		)

DELETE
FROM cte
WHERE row_num > 1

SELECT Type
FROM DW_SESSION

SELECT *
FROM DW_SessionTimetable

-- updating date id in fact table--
UPDATE DW_SESSION
SET SDateId = t.DateId
FROM DW_SESSION s
	,DW_SessionTimetable t
WHERE s.SessionDate = t.SessionDate

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
Populating DW_LOUMREQUEST,DW_TYPECOVER,DW_PRACTICEDEATIL,DW_LOCUMDETAIL TABLES
*/
--Populating DW_LOCUMREQUEST from LOCUMREQUEST table
INSERT INTO DW_LOCUMREQUEST
SELECT CONVERT(INT, LocumRequestID)
	,CONVERT(INT, PracticeID)
	,CONVERT(DATETIME, [Request date])
	,DATEPART(WEEK, [Request date])
	,DATEPART(MONTH, [Request date])
	,DATEPART(DAYOFYEAR, [Request date])
	,DATEPART(YEAR, [Request date])
FROM LOCUMREQUEST

SELECT *
FROM DW_LOCUMREQUEST

--Populating DW_TypeCover table from [Template_Type of Cover] table
INSERT INTO DW_TypeCover
SELECT CONVERT(INT, TypeofCoverID)
	,CONVERT(VARCHAR, CoverDescription)
FROM [Template_Type of Cover]

SELECT *
FROM DW_TypeCover

--Populating DW_PracticeDetails table from [Practice Details] table
INSERT INTO DW_PracticeDetails
SELECT isnull(PracticeID, 0)
	,isnull([Practice Name], '')
	,isnull(County, '')
	,isnull(Postcode, '')
	,isnull([Type of Practice], '')
	,isnull([LNT practice code], '')
	,isnull([LNT practice code], '')
	,ISNULL(Town, '')
FROM [Practice Details]

SELECT *
FROM DW_PracticeDetails

--Populating DW_LocumDeatils table from LOCUMDETAILS table
INSERT INTO DW_LocumDetails
SELECT isnull(LocumID, 0)
	,isnull([First Name], '')
	,isnull([Last Name], '')
	,isnull(County, '')
	,isnull(Postcode, '')
	,isnull(Gender, '')
	,isnull([GMC Expiry Date], '')
FROM LOCUMDETAILS

SELECT *
FROM DW_LocumDetails

--------------------------------------------------------------------------------------------------------------------------------
--Making Primary key and forieng key connection 
--Here SQL server Management studios' gui is used to perform is operation
-----------------------------------------------------------------------------------------------------------------------------------
/* 
Queries on DatawareHouse To get requeried Infromation
*/
--Query 1
--The list of Sessions filled by type of cover by month--
SELECT t.month
	,s.Type
	,s.SessionId
	,s.RequestID
	,s.RequestID
	,s.SessionDate
	,s.SessionStart
	,s.SessionEnd
	,s.STATUS
	,s.SessionLength
FROM DW_SESSION s
INNER JOIN DW_SessionTimetable t ON s.SDateId = t.DateId
ORDER BY t.month
	,s.Type

--Query 2
--The number of Requests made by type of cover by week
SELECT r.ReqWeek
	,s.type
	,count(s.Type) AS TotalReqMade
FROM DW_LOCUMREQUEST r
INNER JOIN DW_SESSION s ON r.LocumRequestID = s.RequestID
GROUP BY r.ReqWeek
	,s.type

--Query 3 The number of Locum requests made by county by month--
SELECT r.ReqMonth AS Month
	,p.County AS Country
	,count(*) AS Number_of_LpcumReq
FROM DW_LOCUMREQUEST r
INNER JOIN DW_PracticeDetails p ON r.PracticeID = p.PracticeID
GROUP BY r.ReqMonth
	,p.County

---Query 4 The number of Sessions covered by month--
SELECT t.month AS Month
	,count(s.SessionId) AS Number_of_Sessions_Conducted
FROM DW_SESSION s
INNER JOIN DW_SessionTimetable t ON s.SDateId = t.DateId
GROUP BY t.month

--Query 5 A list of Locum requests by town by week
SELECT r.ReqWeek
	,p.Town
	,r.LocumRequestID
	,r.RequestDate
FROM DW_LOCUMREQUEST r
INNER JOIN DW_PracticeDetails p ON r.PracticeID = p.PracticeID
ORDER BY r.ReqWeek
	,p.Town
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
