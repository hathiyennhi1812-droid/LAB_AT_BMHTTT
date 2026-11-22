IF DB_ID(N'LAB1_MaHoaCoDien') IS NULL 
    CREATE DATABASE [LAB1_MaHoaCoDien]; 
GO 
USE [LAB1_MaHoaCoDien]; 
GO 
IF OBJECT_ID(N'dbo.history', N'U') IS NULL 
BEGIN 
    CREATE TABLE dbo.history ( 
        id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY, 
        created_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(), 
        algorithm NVARCHAR(50) NOT NULL, 
        operation VARCHAR(10) NOT NULL, 
        input_text NVARCHAR(MAX) NOT NULL, 
        result_text NVARCHAR(MAX) NOT NULL, 
        CONSTRAINT CK_lab1_operation CHECK (operation IN ('ENCRYPT','DECRYPT')) 
    ); 
END; 
GO