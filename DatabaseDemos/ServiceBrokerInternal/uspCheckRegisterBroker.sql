USE [ODS]
GO
/****** Object:  StoredProcedure [dbo].[SSRS_CheckRegisterBroker]    Script Date: 9/23/2016 1:44:26 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[SSRS_CheckRegisterBroker]
AS
BEGIN
	--Create message and contract
	CREATE MESSAGE TYPE CheckRegisterMessage
	CREATE CONTRACT	CheckRegisterContract(
		CheckRegisterMessage SENT BY ANY
	)

	--Create queues 
	CREATE QUEUE CheckRegisterInitQueue
	CREATE QUEUE CheckRegisterTargetQueue

	--Create services on queues with contract
	CREATE SERVICE CheckRegisterInitService
	ON QUEUE CheckRegisterInitQueue(
		CheckRegisterContract
	)

	CREATE SERVICE CheckRegisterTargetService
	ON QUEUE CheckRegisterTargetQueue(
		CheckRegisterContract
	)

	ALTER QUEUE dbo.CheckRegisterInitQueue 
	WITH ACTIVATION(
		STATUS = ON
		, PROCEDURE_NAME = dbo.SSRS_CheckRegisterInitActivation
		, MAX_QUEUE_READERS = 1
		, EXECUTE AS SELF
	)
END