-- OGE Field Operations & Outage Portal - schema
-- Target: SQL Server (Express) - database OgeFieldOps
-- Run against the OgeFieldOps database (see provisioning script for DB + login creation).

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('dbo.OutageDocuments', 'U') IS NOT NULL DROP TABLE dbo.OutageDocuments;
IF OBJECT_ID('dbo.Outages', 'U') IS NOT NULL DROP TABLE dbo.Outages;
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL DROP TABLE dbo.Users;
GO

CREATE TABLE dbo.Users
(
    Id            INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Users PRIMARY KEY,
    Username      NVARCHAR(64)  NOT NULL,
    DisplayName   NVARCHAR(128) NULL,
    Role          NVARCHAR(32)  NOT NULL,
    PasswordSalt  NVARCHAR(64)  NOT NULL,
    PasswordHash  NVARCHAR(128) NOT NULL,
    IsActive      BIT           NOT NULL CONSTRAINT DF_Users_IsActive DEFAULT(1),
    CreatedAt     DATETIME      NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT(GETDATE())
);
GO

CREATE UNIQUE INDEX UX_Users_Username ON dbo.Users(Username);
GO

CREATE TABLE dbo.Outages
(
    Id                INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Outages PRIMARY KEY,
    TicketNumber      NVARCHAR(32)  NOT NULL,
    Region            NVARCHAR(64)  NOT NULL,
    Cause             NVARCHAR(128) NULL,
    Status            NVARCHAR(32)  NOT NULL,
    CustomersAffected INT           NOT NULL CONSTRAINT DF_Outages_Customers DEFAULT(0),
    ReportedAt        DATETIME      NOT NULL,
    RestoredAt        DATETIME      NULL,
    ReportedBy        NVARCHAR(64)  NULL
);
GO

CREATE INDEX IX_Outages_ReportedAt ON dbo.Outages(ReportedAt DESC);
GO

CREATE TABLE dbo.OutageDocuments
(
    Id          INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_OutageDocuments PRIMARY KEY,
    OutageId    INT           NOT NULL CONSTRAINT FK_OutageDocuments_Outages REFERENCES dbo.Outages(Id),
    FileName    NVARCHAR(260) NOT NULL,
    StoredPath  NVARCHAR(512) NOT NULL,
    SizeBytes   BIGINT        NOT NULL,
    UploadedAt  DATETIME      NOT NULL,
    UploadedBy  NVARCHAR(64)  NULL
);
GO

CREATE INDEX IX_OutageDocuments_OutageId ON dbo.OutageDocuments(OutageId);
GO
