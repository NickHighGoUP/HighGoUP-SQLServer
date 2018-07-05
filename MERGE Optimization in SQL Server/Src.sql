/* **********************************
	Create a simple table for tests
************************************* */
CREATE TABLE Person
(
	Id INT NOT NULL IDENTITY(1, 1)
		CONSTRAINT PK_Person PRIMARY KEY CLUSTERED,
	FirstName NVARCHAR(100) NOT NULL,
	MiddleName NVARCHAR(100) NOT NULL,
	LastName NVARCHAR(100) NOT NULL,
	Gender CHAR(1) NOT NULL,
	BirthDate DATETIME NOT NULL,
	StartDate DATETIME NOT NULL
		CONSTRAINT DF_Person_StartDate DEFAULT GETDATE(),
	EndDate DATETIME NULL
)
GO


/* ************************************
	Populate the table with mock data
	Note: takes ~12 mins to complete
*************************************** */
INSERT INTO Person (
	[FirstName], 
	[MiddleName], 
	[LastName], 
	[Gender], 
	[BirthDate],
	[EndDate]
)
SELECT
	CONVERT(varchar(100), NEWID()),
	CONVERT(varchar(70), NEWID()),
	CONVERT(varchar(100), NEWID()),
	IIF(FLOOR(RAND()*2) = 1, 'M', 'F'),
	GETDATE(),
	IIF(FLOOR(RAND()*2) = 1, GETDATE(), NULL)
GO 1000000


/* **************************************************
	Copy records from the Person table to PersonSrc
	and modify some data
****************************************************** */
SELECT
	*
INTO PersonSrc
FROM Person

ALTER TABLE PersonSrc
ADD CONSTRAINT PK_PersonSrc PRIMARY KEY CLUSTERED (Id)
GO

UPDATE PersonSrc
SET
	MiddleName = MiddleName + 'q',
	LastName = LEFT(LastName, 88)
WHERE
	Id BETWEEN 500 AND 750500

	
/* **************************************
	Comparing MERGE and INSERT/UPDATE
***************************************** */
-- runs much faster with the EXISTS statement
-- CPU: 8358; Reads: 101766; Writes: 0; Duration: 1880
-- CPU: 10566; Reads: 1151747; Writes: 16571; Duration: 4211
-- CPU: 14562; Reads: 2214946; Writes: 36955; Duration: 10309
-- CPU: 15747; Reads: 3264063; Writes: 45768; Duration: 12215
MERGE Person AS Tgt
USING PersonSrc AS Src
	ON Tgt.Id = Src.Id
WHEN MATCHED AND EXISTS (
		SELECT Tgt.FirstName, Tgt.MiddleName, Tgt.LastName, Tgt.Gender, Tgt.BirthDate, Tgt.StartDate, Tgt.EndDate
		EXCEPT
		SELECT Src.FirstName, Src.MiddleName, Src.LastName, Src.Gender, Src.BirthDate, Src.StartDate, Src.EndDate
	)
	THEN UPDATE	SET 
		Tgt.FirstName = Src.FirstName,
		Tgt.MiddleName = Src.MiddleName,
		Tgt.LastName = Src.LastName,
		Tgt.Gender = Src.Gender,
		Tgt.BirthDate = Src.BirthDate,
		Tgt.EndDate = Src.EndDate
WHEN NOT MATCHED BY TARGET THEN
	INSERT (FirstName, MiddleName, LastName, Gender, BirthDate, StartDate, EndDate)
	VALUES (Src.FirstName, Src.MiddleName, Src.LastName, Src.Gender, Src.BirthDate, Src.StartDate, Src.EndDate);

-- CPU: 3657; Reads: 133848; Writes: 0; Duration: 3508
-- CPU: 6455; Reads: 472219; Writes: 16786; Duration: 4766
-- CPU: 5094; Reads: 638341; Writes: 16722; Duration: 5546
-- CPU: 8563; Reads: 972262; Writes: 41735; Duration: 9436
BEGIN TRY
	BEGIN TRANSACTION

		UPDATE Tgt
		SET 
			Tgt.FirstName = Src.FirstName,
			Tgt.MiddleName = Src.MiddleName,
			Tgt.LastName = Src.LastName,
			Tgt.Gender = Src.Gender,
			Tgt.BirthDate = Src.BirthDate,
			Tgt.EndDate = Src.EndDate
		FROM Person AS Tgt
		INNER JOIN PersonSrc AS Src
			ON Src.Id = Tgt.Id
		WHERE
			EXISTS (
				SELECT Tgt.FirstName, Tgt.MiddleName, Tgt.LastName, Tgt.Gender, Tgt.BirthDate, Tgt.StartDate, Tgt.EndDate
				EXCEPT
				SELECT Src.FirstName, Src.MiddleName, Src.LastName, Src.Gender, Src.BirthDate, Src.StartDate, Src.EndDate
			)

		INSERT INTO Person (
			FirstName,
			MiddleName, 
			LastName, 
			Gender,
			BirthDate, 
			StartDate, 
			EndDate
		)
        SELECT 
			Src.FirstName,
			Src.MiddleName, 
			Src.LastName, 
			Src.Gender,
			Src.BirthDate, 
			Src.StartDate, 
			Src.EndDate
        FROM PersonSrc AS Src
        LEFT JOIN Person AS Tgt
            ON Src.Id = Tgt.Id
        WHERE 
			Tgt.Id IS NULL

	COMMIT;
END TRY
BEGIN CATCH
	ROLLBACK;
	THROW;
END CATCH


/* ***********************
	Useful templates
************************** */
-- MERGE
MERGE <Target Table Name> AS Tgt
USING <Source Table Name> AS Src
	ON Tgt.Id = Src.Id --add more columns
WHEN MATCHED AND EXISTS (
		SELECT Tgt.<Column Name>, Tgt.<Column Name>
		EXCEPT
		SELECT Src.<Column Name>, Src.<Column Name>
	)
	THEN UPDATE SET 
		Tgt.<Column Name> = Src.<Column Name>,
		Tgt.<Column Name> = Src.<Column Name>
WHEN NOT MATCHED BY TARGET THEN
		INSERT (<Column Name>, <Column Name>)
		VALUES (Src.<Column Name>, Src.<Column Name>)
/* DELETE Clause - Use When Needed
WHEN NOT MATCHED BY SOURCE THEN
DELETE*/
;

-- UPDATE/INSERT/DELETE
BEGIN TRY
	BEGIN TRANSACTION

		UPDATE Tgt
		SET 
			Tgt.<Column Name> = Src.<Column Name>,
			Tgt.<Column Name> = Src.<Column Name>
		FROM <Target Table Name> AS Tgt
		INNER JOIN <Source Table Name> AS Src
			ON Src.Id = Tgt.Id --add more columns
		WHERE
			EXISTS (
				SELECT Tgt.<Column Name>, Tgt.<Column Name>
				EXCEPT
				SELECT Src.<Column Name>, Src.<Column Name>
			)

		INSERT INTO Person (
			<Column Name>,
<Column Name>
		)
        SELECT 
			Src.<Column Name>,
			Src.<Column Name>
        FROM <Source Table Name> AS Src
        LEFT JOIN <Target Table Name> AS Tgt
            ON Src.Id = Tgt.Id --add more columns
        WHERE 
	Tgt.Id IS NULL
/*DELETE Clause - Use When Needed*/
/*DELETE Tgt
FROM <Target Table Name> AS Tgt
LEFT JOIN <Source Table Name> AS Src
	ON Tgt.Id = Src.Id --add more columns
WHERE
	Src.Id IS NULL*/
	COMMIT;
END TRY
BEGIN CATCH
	ROLLBACK;
	THROW;
END CATCH