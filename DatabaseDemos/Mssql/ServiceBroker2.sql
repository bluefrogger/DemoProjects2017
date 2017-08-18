/*
https://www.mssqltips.com/sqlservertip/1836/sql-server-service-broker-example-on-how-to-configure-send-and-receive-messages/
*/

--Enabling service broker
USE master
ALTER DATABASE ServiceBrokerTest
SET ENABLE_BROKER; 

--Create Message Types for Request and Reply messages
USE Control;
-- For Request
CREATE MESSAGE TYPE [//SBTest/SBSample/RequestMessage] VALIDATION=WELL_FORMED_XML; 
-- For Reply
CREATE MESSAGE TYPE [//SBTest/SBSample/ReplyMessage] VALIDATION=WELL_FORMED_XML; 

--Create Contract for the Conversation 
CREATE CONTRACT [//SBTest/SBSample/SBContract]
(
	[//SBTest/SBSample/RequestMessage] SENT BY INITIATOR 
	,[//SBTest/SBSample/ReplyMessage] SENT BY TARGET 
);

--Create Queue for the Initiator
CREATE QUEUE SBInitiatorQueue; 
--Create Queue for the Target
CREATE QUEUE SBTargetQueue;

--Create Service for the Target and the Initiator.
--Create Service for the Initiator. No contract so no targeting or receiving/replying
CREATE SERVICE [//SBTest/SBSample/SBInitiatorService] ON QUEUE SBInitiatorQueue; 
--Create Service for the Target.
CREATE SERVICE [//SBTest/SBSample/SBTargetService] ON QUEUE SBTargetQueue ([//SBTest/SBSample/SBContract]);

--Sending a Request Message to the Target
DECLARE @InitDlgHandle UNIQUEIDENTIFIER
DECLARE @RequestMessage VARCHAR(1000) 
BEGIN TRAN 
	--Determine the Initiator Service, Target Service and the Contract 
	BEGIN DIALOG @InitDlgHandle
		FROM SERVICE [//SBTest/SBSample/SBInitiatorService]
		TO SERVICE '//SBTest/SBSample/SBTargetService'
		ON CONTRACT [//SBTest/SBSample/SBContract]
		WITH ENCRYPTION=OFF; 
	--Prepare the Message
	SELECT @RequestMessage = N'<RequestMessage> Send a Message to Target </RequestMessage>'; 
	--Send the Message
	SEND ON CONVERSATION @InitDlgHandle 
	MESSAGE TYPE [//SBTest/SBSample/RequestMessage]	(@RequestMessage);

	SELECT @RequestMessage AS SentRequestMessage; 
COMMIT TRAN 

--Receiving a Message and sending a Reply from the Target 
DECLARE @TargetDlgHandle UNIQUEIDENTIFIER
DECLARE @ReplyMessage VARCHAR(1000)
DECLARE @ReplyMessageName Sysname 

BEGIN TRAN; 
	--Receive message from Initiator
	RECEIVE TOP(1) @TargetDlgHandle=Conversation_Handle, @ReplyMessage=Message_Body, @ReplyMessageName=Message_Type_Name
	FROM SBTargetQueue; 
	SELECT @ReplyMessage AS ReceivedRequestMessage; 

	-- Confirm and Send a reply
	IF @ReplyMessageName=N'//SBTest/SBSample/RequestMessage'
	BEGIN
		DECLARE @RplyMsg VARCHAR(1000)
		SELECT @RplyMsg =N'<RplyMsg> Send a Message to Initiator</RplyMsg>'; 
		SEND ON CONVERSATION @TargetDlgHandle
		MESSAGE TYPE [//SBTest/SBSample/ReplyMessage](@RplyMsg);
		END CONVERSATION @TargetDlgHandle;
	END 
	SELECT @RplyMsg AS SentReplyMessage; 
COMMIT TRAN;

--Receiving Reply Message from the Target.
DECLARE @InitiatorReplyDlgHandle UNIQUEIDENTIFIER
DECLARE @ReplyReceivedMessage VARCHAR(1000) 
BEGIN TRAN; 
	RECEIVE TOP(1) @InitiatorReplyDlgHandle=Conversation_Handle, @ReplyReceivedMessage=Message_Body
	FROM SBInitiatorQueue; 
	END CONVERSATION @InitiatorReplyDlgHandle; 
	SELECT @ReplyReceivedMessage AS ReceivedRepliedMessage; 
COMMIT TRAN;

--Checking the usage of the Messages, Contracts and Queues using System views.
SELECT * FROM sys.service_contract_message_usages 
SELECT * FROM sys.service_contract_usages
SELECT * FROM sys.service_queue_usages
