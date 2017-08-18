/*
http://gavindraper.com/2012/06/03/sql-server-service-broker-explained/
*/

CREATE MESSAGE TYPE [PrintRequest] VALIDATION = WELLFORMEDXML 
CREATE MESSAGE TYPE [PrintResponse] VALIDATION = WELLFORMEDXML 
CREATE MESSAGE TYPE [ProcessPaymentRequest]  VALIDATION = WELLFORMEDXML 
CREATE MESSAGE TYPE [ProcessPaymentResponse] VALIDATION = WELLFORMEDXML

CREATE QUEUE PrintInitiatorQueue WITH ACTIVATION  
(
    STATUS = ON,
    PROCEDURE_NAME = [BrokerPrintMessageProcessed],
    MAX_QUEUE_READERS = 4,
    EXECUTE AS SELF
)
CREATE QUEUE PrintTargetQueue WITH STATUS = ON  
CREATE QUEUE ProcessPaymentInitiatorQueue WITH ACTIVATION  
(
    STATUS = ON,
    PROCEDURE_NAME = [BrokerPaymentMessageProcessed],
    MAX_QUEUE_READERS = 4,
    EXECUTE AS SELF
)
CREATE QUEUE ProcessPaymentTargetQueue WITH STATUS = ON

CREATE CONTRACT [ProcessPaymentContract]  
(
    [ProcessPaymentResponse] SENT BY TARGET,
    [ProcessPaymentRequest] SENT BY INITIATOR
)
CREATE CONTRACT [PrintContract]  
(
    [PrintRequest] SENT BY INITIATOR,
    [PrintResponse] SENT BY TARGET
)

CREATE SERVICE PrintInitiatorService ON QUEUE PrintInitiatorQueue(PrintContract)  
CREATE SERVICE PrintTargetService ON QUEUE PrintTargetQueue(PrintContract)  
CREATE SERVICE ProcessPaymentInitiatorService ON QUEUE ProcessPaymentInitiatorQueue(ProcessPaymentContract)  
CREATE SERVICE ProcessPaymentTargetService ON QUEUE ProcessPaymentTargetQueue(ProcessPaymentContract)  

go
CREATE PROCEDURE [dbo].[CreateBooking]  
(
 @EventId INT,
 @CreditCard VARCHAR(20)
)
AS

BEGIN TRANSACTION  
BEGIN TRY  
    INSERT INTO Bookings(EventId,CreditCard)
    VALUES(@EventId,@CreditCard)

    DECLARE @BookingId INT = SCOPE_IDENTITY()

    --Send messagge for payment process
    DECLARE @ConversationHandle UNIQUEIDENTIFIER
        BEGIN DIALOG CONVERSATION @ConversationHandle
           FROM SERVICE [ProcessPaymentInitiatorService]
           TO SERVICE 'ProcessPaymentTargetService'
           ON CONTRACT [ProcessPaymentContract]
           WITH ENCRYPTION = OFF
        DECLARE @Msg NVARCHAR(MAX) 
        SET @Msg = '' + CAST(@BookingId AS NVARCHAR(10)) + '' + @CreditCard + '';
        SEND ON CONVERSATION @ConversationHandle MESSAGE TYPE [ProcessPaymentRequest](@Msg)
    COMMIT
END TRY  
BEGIN CATCH  
    RAISERROR('Booking Failed',1,1)
    ROLLBACK
    RETURN
END CATCH

go
CREATE PROCEDURE [dbo].[BrokerPaymentMessageProcessed]  
AS  
DECLARE @ConversationHandle UNIQUEIDENTIFIER  
DECLARE @MessageType NVARCHAR(256)  
DECLARE @MessageBody XML  
DECLARE @ResponseMessage XML

WHILE(1=1)  
BEGIN  
    BEGIN TRY
        BEGIN TRANSACTION
        WAITFOR(RECEIVE TOP(1)
            @ConversationHandle = conversation_handle,
            @MessageType = message_type_name,
            @MessageBody = CAST(message_body AS XML)
        FROM
            ProcessPaymentInitiatorQueue
            ), TIMEOUT 1000
        IF(@@ROWCOUNT=0)
            BEGIN
                ROLLBACK TRANSACTION 
                RETURN
            END
        SELECT @MessageType
        IF @MessageType = 'ProcessPaymentResponse'
            BEGIN
            --Parse the Message and update tables based on contents
            DECLARE @PaymentStatus INT = @MessageBody.value('/Payment[1]/PaymentStatus[1]','INT')
            DECLARE @BookingId INT = @MessageBody.value('/Payment[1]/BookingId[1]','INT')
            UPDATE Bookings SET Bookings.PaymentStatus = @PaymentStatus WHERE Id = @BookingId
            --Close the conversation on the Payment Service
            END CONVERSATION @ConversationHandle                
            --Start a new conversation on the print service
            BEGIN DIALOG CONVERSATION @ConversationHandle
                FROM SERVICE [PrintInitiatorService]
                TO SERVICE 'PrintTargetService'
                ON CONTRACT [PrintContract]
                WITH ENCRYPTION = OFF
            DECLARE @Msg NVARCHAR(MAX) = '' +  CAST(@BookingId AS NVARCHAR(10)) +  '';
            SELECT @ConversationHandle;
            SEND ON CONVERSATION @ConversationHandle MESSAGE TYPE [PrintRequest](@Msg)                      
            END
        COMMIT
    END TRY
    BEGIN CATCH
        SELECT ERROR_MESSAGE()
        ROLLBACK TRANSACTION
    END CATCH
END  

go