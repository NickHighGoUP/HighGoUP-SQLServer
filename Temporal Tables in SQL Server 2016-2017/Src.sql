/* ****************************************************
	Prepare our workplace.
	Create a simple Book table
******************************************************* */
CREATE TABLE Book
(
	BookID INT IDENTITY (1, 1) 
		CONSTRAINT PK_Book PRIMARY KEY CLUSTERED,
	Name VARCHAR(100) NOT NULL
)
GO

INSERT INTO Book (Name)
VALUES
	('SQL Server 2016'),
	('SQL Server 2017')
GO


/* ****************************************************
	Create the BookPrice Temporal table
******************************************************* */
CREATE TABLE BookPrice
(
	BookPriceID INT IDENTITY (1, 1) 
		CONSTRAINT PK_BookPrice PRIMARY KEY CLUSTERED,
	Price DECIMAL(10, 2) NOT NULL,
	BookID INT NOT NULL
		CONSTRAINT FK_BookPrice_Book FOREIGN KEY REFERENCES Book(BookID),
	SysStartTime DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL, --we can add HIDDEN after the START keyword
	SysEndTime DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL, --we can add HIDDEN after the END keyword
	PERIOD FOR SYSTEM_TIME(SysStartTime, SysEndTime)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.BookPriceHistory))
GO

INSERT INTO BookPrice (Price, BookID)
VALUES
	(11.99, 1),
	(20.99, 2)
GO

SELECT * FROM BookPrice


/* ****************************************************
	Update a price
******************************************************* */
UPDATE BookPrice
SET
	Price = 15.99
WHERE
	BookPriceID = 2
	
SELECT * FROM BookPrice --current records only
SELECT * FROM BookPriceHistory --historic records only

SELECT * FROM BookPrice
FOR SYSTEM_TIME AS OF '2018-04-25' --active records as of 04/25/18

SELECT * FROM BookPrice
FOR SYSTEM_TIME ALL --full history (current records + historic records)


/* ****************************************************
	Delete a price
******************************************************* */
DELETE BookPrice WHERE BookPriceID = 1

SELECT * FROM BookPrice --current records only

SELECT * FROM BookPrice 
FOR SYSTEM_TIME ALL --full history (current records + historic records)


/* ****************************************************
	Create and query the vw_BookPrice view with the new clause
******************************************************* */
CREATE VIEW vw_BookPrice
AS
	SELECT
		bp.BookPriceID,
		bp.Price,
		b.Name,
		bp.SysStartTime,
		bp.SysEndTime
	FROM BookPrice AS bp
	INNER JOIN Book AS b
ON bp.BookID = b.BookID
GO

SELECT * FROM vw_BookPrice --current records only

SELECT * FROM vw_BookPrice
FOR SYSTEM_TIME AS OF '2018-04-26' --records as of 04/26/18


/* ****************************************************
	Alter columns in the Temporal table -
	the History table will be updated automatically
******************************************************* */
ALTER TABLE BookPrice 
ADD Notes VARCHAR(300) NULL
GO

ALTER TABLE BookPrice 
ALTER COLUMN Price DECIMAL(8,2) NOT NULL
GO


/* ****************************************************
	Turn off System versioning on the Temporal table - 
	both, the History and Temporal tables, will be converted to ordinary ones
******************************************************* */
ALTER TABLE BookPrice SET (SYSTEM_VERSIONING = OFF)
GO


/* ****************************************************
	Turn on System versioning on the BookPrice table -
	it will be converted into Temporal table + BookPriceHistory will be converted to its History table
******************************************************* */
ALTER TABLE dbo.BookPrice
SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE=dbo.BookPriceHistory, HISTORY_RETENTION_PERIOD=10 DAYS)) --setting Retention Period to 10 days
GO


/* ****************************************************
	See Retention Period for Temporal tables
******************************************************* */
SELECT 
	SCHEMA_NAME(T1.schema_id) + '.' + T1.name AS TemporalTable,
	SCHEMA_NAME(T2.schema_id) + '.' + T2.name AS HistoryTable,
	T1.history_retention_period AS RetentionPeriod,
	T1.history_retention_period_unit_desc AS RetentionPeriodUnitDescription
FROM sys.tables T1
LEFT JOIN sys.tables T2   
	ON T1.history_table_id = T2.object_id 
WHERE 
	T1.temporal_type = 2


/* ****************************************************
	Convert the Book table to Temporal table
******************************************************* */
ALTER TABLE Book
ADD
	SysStartTime DATETIME2 GENERATED ALWAYS AS ROW START
		CONSTRAINT DF_Book_SysStartTime DEFAULT SYSUTCDATETIME() NOT NULL,
	SysEndTime DATETIME2 GENERATED ALWAYS AS ROW END
		CONSTRAINT DF_Book_SysEndTime DEFAULT '9999-12-31 23:59:59.9999999' NOT NULL,
	PERIOD FOR SYSTEM_TIME(SysStartTime, SysEndTime)
GO

ALTER TABLE dbo.Book
SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE=dbo.BookHistory))
GO
