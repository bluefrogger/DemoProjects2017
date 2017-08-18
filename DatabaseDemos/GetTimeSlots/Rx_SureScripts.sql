
USE [coreDev.SolutaHealth.com]

CREATE TABLE dbo.RX_SureScripts(
	RX_SureScriptID INT IDENTITY(1,1) NOT NULL 
	, PharmacyName NVARCHAR(150) NULL
	, [Address] NVARCHAR(2000) NULL
	, [Message] NVARCHAR(4000) NULL
    , TextMessageId INT NULL
	, ScriptStatus TINYINT NULL
	, RX_ScriptStatusDescription TINYINT NULL
    , CONSTRAINT PK_RX_SureScripts PRIMARY KEY CLUSTERED (RX_SureScriptID)
)


CREATE TABLE dbo.RX_ScriptStatuses(
	RX_ScriptStatusId INT IDENTITY(1,1) NOT NULL
    , RX_ScriptStatusDescription NVARCHAR(250)
	, CONSTRAINT PK_RX_ScriptStatus PRIMARY KEY CLUSTERED (RX_ScriptStatusId)
)

USE ElevateDev

