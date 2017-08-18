/*
http://www.davewentzel.com/content/service-broker-demystified-closed-conversations
http://rusanu.com/2006/04/06/fire-and-forget-good-for-the-military-but-not-for-service-broker-conversations/
https://blogs.msdn.microsoft.com/sqlsakthi/2011/04/04/service-broker-fire-and-forget-scenario-and-memory-allocation-failure/
*/
-- https://www.simple-talk.com/sql/learn-sql-server/service-broker-advanced-basics-workbench/
-- SSB Workbench Part 2: Advanced Basics --
/*
In the first part of this workbench series, we covered the foundations: Setting up message types, contracts, queues, and services, 
and sending and waiting for messages. This second part extends on the first. 
We'll get in to some of the catalog views that you can query to find out what Service Broker is up to, 
investigate how Service Broker handles transactions and locking, 
route our messages across databases, 
and process messages automatically with stored procedures.
Once you've finished with this second workbench, you will have a complete understanding of 
all of the most common SSB features that you will use on projects again and again. 
The few remaining interesting features will be covered in the third installment of this mega-workbench
, coming soon to a Simple-Talk near you...So with that, let's jump in!
*/
--Set up new DB
--To begin with, we'll create a database to work in.
CREATE DATABASE Simple_Talk_SSB2
GO

USE Simple_Talk_SSB2
GO

--Make sure that SSB is enabled
ALTER DATABASE Simple_Talk_SSB2
SET ENABLE_BROKER
WITH ROLLBACK IMMEDIATE
GO

--Create a master key
CREATE MASTER KEY
ENCRYPTION BY PASSWORD = 'onteuhoeu'
GO

/*
-- Setup --
Get a few basics in place: A message type without validation (meaning that we can send any binary data), 
a contract based on the message type, a couple of queues, and a couple of services. 
See the last workbench for details on all of this.
*/
CREATE MESSAGE TYPE BLOB
VALIDATION = NONE
GO

CREATE CONTRACT BLOB_Contract
(BLOB SENT BY ANY)
GO

CREATE QUEUE BLOB_Queue_Init
CREATE QUEUE BLOB_Queue_Target
GO

CREATE SERVICE BLOB_Service_Init
ON QUEUE BLOB_Queue_Init
(BLOB_Contract)

CREATE SERVICE BLOB_Service_Target
ON QUEUE BLOB_Queue_Target
(BLOB_Contract)
GO

/*
-- The Conversation Endpoints View --
The sys.conversation_endpoints view is the primary catalog view that you can use to get information 
about which conversations exist in the current database, and their current status. 
The view provides quite a bit of information about each conversation, and we can use it to gain some insights 
into the internals of Service Broker.

Since we have, presumably, just created the database, querying the view at this point should return an empty set of rows:
*/
SELECT * FROM sys.conversation_endpoints
GO

/*
Although there are almost 30 columns exposed by the view, for the sake of this workbench we'll consider only a few:
conversation_handle
    Conversation (or dialog) handles were discussed in detail in the previous workbench. 
	This column is effectively the primary key for the view. The view will have one row for each handle generated, 
	whether by an initiator or a target. 
conversation_id
    Each dialog has both an initiator and a target, with different dialog handles. 
	This column is a GUID which relates rows for initiators with the rows for their targets. 
is_iniator
    This is a bit column that will return 1 if the initiating handle was the one represented in the conversation_handle column, 
	or 0 otherwise. 
conversation_group_id
    Conversation groups and this column will be discussed in detail shortly. 
state_desc
    Any given side of a dialog, at any given time, can be in any of several states. These include "CONVERSING", 
	which means that the conversation is open for messages, or one of two "DISCONNECTED" states 
	that indicate that one or both parties have called END COVERSATION. 
far_service and far_broker_instance
    Both of these columns will be discussed when we get into routing. 

To look at some of the data exposed by the view, we'll first have to start a conversation.

*/
--Start a conversation
DECLARE @h UNIQUEIDENTIFIER

BEGIN DIALOG CONVERSATION @h
FROM SERVICE BLOB_Service_Init
TO SERVICE 'BLOB_Service_Target'
ON CONTRACT BLOB_Contract
WITH ENCRYPTION=OFF
GO

/*

Now that a conversation has been initiated, the following query should return one row:

*/
SELECT 
    conversation_handle,
    conversation_id,
    is_initiator,
    state_desc
FROM sys.conversation_endpoints

/*
Running this query, we see that for the one row returned, is_initiator is set to 1--which makes sense, 
given that we have just initiated a conversation. But why was only one row returned? 
If you're following along, you might recall that a dialog has two sides: an initiator and a target. 
And each of these sides gets their own conversation handle. Furthermore, you might recall that I just mentioned 
that the conversation handle is effectively the primary key for the Conversation Endpoints view. 
So wouldn't two rows make more sense?
The value of the state_desc column should give you a hint. It will read "STARTED_OUTBOUND". 
Initiating a dialog, as it turns out, only starts up the initiator's end of things. 
The target's side of the conversation doesn't actually exist until a message joins the fray 
and there is something for a target to receive...
*/
--Get the conversation handle
DECLARE @h UNIQUEIDENTIFIER

SELECT @h = conversation_handle
FROM sys.conversation_endpoints

--Send a message
;SEND ON CONVERSATION @h
MESSAGE TYPE BLOB
(CONVERT(varbinary, 'Hello Simple-Talk, pt. 2!'))

--Run the query again
SELECT 
    conversation_handle,
    conversation_id,
    is_initiator,
    state_desc
FROM sys.conversation_endpoints
GO

SELECT * FROM BLOB_Queue_Init
SELECT * FROM BLOB_Queue_Target

/*
Now we see both the initiator and the target, and for both rows the state_desc column's value is "CONVERSING". 
The conversation has started and all is well. Note the conversation_id column--its value is the same 
for both the initiator and the target. Should you ever need to find the target's conversation handle based on the initiator handle, 
or the other way around, this column is key.

Now that we've seen how a conversation starts, let's take a peek at what happens when it ends.

*/
--First, end the target conversation
DECLARE @h UNIQUEIDENTIFIER

;RECEIVE @h=conversation_handle
FROM BLOB_Queue_Target

END CONVERSATION @h

--What happened?
SELECT 
    conversation_handle,
    conversation_id,
    is_initiator,
    state_desc
FROM sys.conversation_endpoints
GO

/*

After running the preceding batch, you'll notice that the target's side of the conversation is now "CLOSED". 
The initiator, on the other hand, has now gone into the "DISCONNECTED_INBOUND" state. 
As mentioned in the previous workbench, a disconnected side of a conversation can only 
retrieve any remaining messages and then end the conversation itself. So let's do that.
*/
--End the initiator's side
DECLARE @h UNIQUEIDENTIFIER

;RECEIVE @h=conversation_handle
FROM BLOB_Queue_Init

END CONVERSATION @h

--What happened?
SELECT 
    conversation_handle,
    conversation_id,
    is_initiator,
    state_desc
FROM sys.conversation_endpoints
GO


/*
Now you might notice something interesting and wholly unexpected. The initiator's side of the conversation is gone
, no longer showing up in the result set for the view. But the target is still there, and still closed.
As it turns out, the target will sit there in a closed state for "about half an hour," according to Roger Wolter
, the architect behind Service Broker. This is a security precaution, he says in his chapter of "Inside Microsoft SQL Server 2005:
T-SQL Programming," in order to prevent replay attacks.
That topic is quite beyond the scope of this workbench, but it's important that you know that the target side 
does stay around for a while even after the conversation has been closed. We'll discuss why that's so important 
in the next workbench, so stay tuned...
*/

/*
-- Conversation Groups --
As we've now observed several times throughout the course of the two workbenches, each time a dialog is started 
a conversation handle is automatically generated by Service Broker. But what you may not have noticed is that 
in addition to the conversation handle, there is also a second automatically generated GUID, the conversation group ID:
*/
--Start a conversation
DECLARE @h UNIQUEIDENTIFIER

BEGIN DIALOG CONVERSATION @h
FROM SERVICE BLOB_Service_Init
TO SERVICE 'BLOB_Service_Target'
ON CONTRACT BLOB_Contract
WITH ENCRYPTION=OFF

SELECT 
    conversation_handle,
    conversation_group_id,
    conversation_id,
    is_initiator,
    state_desc
FROM sys.conversation_endpoints
WHERE conversation_handle = @h
GO

/*
The first thing that makes this GUID different than the conversation handle is that it doesn't have to be auto-generated. 
You can tell Service Broker which ID to use:
*/
--Start a conversation
DECLARE @h UNIQUEIDENTIFIER

BEGIN DIALOG CONVERSATION @h
FROM SERVICE BLOB_Service_Init
TO SERVICE 'BLOB_Service_Target'
ON CONTRACT BLOB_Contract
WITH
    RELATED_CONVERSATION_GROUP = '0F0F0F0F-0E0E-0D0D-0C0C-0B0B0B0B0B0B',
    ENCRYPTION=OFF

SELECT 
    conversation_handle,
    conversation_group_id,
    conversation_id,
    is_initiator,
    state_desc
FROM sys.conversation_endpoints
WHERE conversation_handle = @h
GO

/*
Running this, you'll see that the instantly-identifiable GUID I've created is used as the conversation_group_id. 
But that's just the initiator end of the conversation. What about the target?
*/
DECLARE @h UNIQUEIDENTIFIER, @i UNIQUEIDENTIFIER

SELECT 
    @h = conversation_handle,
    @i = conversation_id
FROM sys.conversation_endpoints
WHERE conversation_group_id = '0F0F0F0F-0E0E-0D0D-0C0C-0B0B0B0B0B0B'

;SEND ON CONVERSATION @h
MESSAGE TYPE BLOB
(CONVERT(varbinary, 'What''s my group?'))

SELECT
    conversation_handle,
    conversation_group_id,
    conversation_id,
    is_initiator,
    state_desc
FROM sys.conversation_endpoints
WHERE conversation_id = @i
GO

/*
Running the preceding batch, you'll see that the target conversation is not enlisted in the same group as the initiator. 
Given the decoupled nature of initiators and targets we've already seen in the world of Service Broker
, this should come as no huge shock, but there are some other reasons to keep these separate that 
I will show you in the section on locking and blocking.
*/
/*
-- Taking a Better Look at RECEIVE --
To see the basic utility of conversation groups, we'll first have to take a step back and look at the RECEIVE statement 
in a bit more depth than in the last workbench. Last time, we saw RECEIVE in its barest form
--the statement itself and a column list. The optional WHERE clause allows you to filter 
based on a given conversation handle or conversation group ID.

The following batch first uses RECEIVE with a conversation handle, then sends a message back to the initiator
, where it is received based on the conversation group ID.
*/
--First, get the target handle
DECLARE @h UNIQUEIDENTIFIER

SELECT 
    @h = conversation_handle
FROM sys.conversation_endpoints
WHERE 
    conversation_id =
    (
        SELECT conversation_id
        FROM sys.conversation_endpoints
        WHERE conversation_group_id = '0F0F0F0F-0E0E-0D0D-0C0C-0B0B0B0B0B0B'
    )
    AND is_initiator = 0

--Now, receive the message, and end the conversation
;RECEIVE *
FROM Blob_Queue_Target
WHERE conversation_handle = @h

;END CONVERSATION @h

--Now use the conversation group ID to receive 
--the end conversation message
;RECEIVE *
FROM Blob_Queue_Init
WHERE conversation_group_id = '0F0F0F0F-0E0E-0D0D-0C0C-0B0B0B0B0B0B'
go
--Finally, since we're good Service Broker users, end
--the initiating conversation...
DECLARE @h UNIQUEIDENTIFIER
SELECT 
    @h = conversation_handle
FROM sys.conversation_endpoints
WHERE conversation_group_id = '0F0F0F0F-0E0E-0D0D-0C0C-0B0B0B0B0B0B'

END CONVERSATION @h
GO

/*
Now that we've seen the power of the RECEIVE statement's WHERE clause, it should be easy to see how 
it can be put to good use in conjunction with a conversation group ID. Suppose that for a certain task
, you want to start several distinct dialogs, but get back all of the responses using a single RECEIVE statement. 
Since RECEIVE's WHERE clause only supports the equality predicate, you can't ask for multiple conversations at once. 
You can instead group all of the conversations using a single conversation group, and use that to get all of the responses.

This same pattern gets even more powerful if you're creating multiple dialogs across more than one service or queue. 
To see what that looks like, we'll create a second target queue and a corresponding service:
*/
CREATE QUEUE BLOB_Queue_Target2

CREATE SERVICE BLOB_Service_Target2
ON QUEUE BLOB_Queue_Target2
(BLOB_Contract)
GO

/*
Dialogs can now be started between the initiator and both queues, using the same conversation group id:
*/
--Send to the BLOB_Service_Target
DECLARE @h UNIQUEIDENTIFIER

BEGIN DIALOG CONVERSATION @h
FROM SERVICE BLOB_Service_Init
TO SERVICE 'BLOB_Service_Target'
ON CONTRACT BLOB_Contract
WITH
    RELATED_CONVERSATION_GROUP = 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE',
    ENCRYPTION=OFF

;SEND ON CONVERSATION @h
MESSAGE TYPE BLOB
(CONVERT(varbinary, 'First Send'))
GO

DECLARE @h UNIQUEIDENTIFIER
--Send to the BLOB_Service_Target2
BEGIN DIALOG CONVERSATION @h
FROM SERVICE BLOB_Service_Init
TO SERVICE 'BLOB_Service_Target2'
ON CONTRACT BLOB_Contract
WITH
    RELATED_CONVERSATION_GROUP = 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE',
    ENCRYPTION=OFF

;SEND ON CONVERSATION @h
MESSAGE TYPE BLOB
(CONVERT(varbinary, 'Second Send'))


SELECT * FROM BLOB_QUEUE_Init
SELECT * FROM BLOB_QUEUE_Target
SELECT * FROM BLOB_QUEUE_Target2
SELECT * FROM sys.conversation_endpoints AS ce


--Get the endpoint data for the conversation group
SELECT
    conversation_handle,
    conversation_group_id,
    conversation_id,
    is_initiator,
    state_desc,
    far_service
FROM sys.conversation_endpoints
WHERE conversation_group_id = 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE'
GO

/*
Looking at the output of the query from the Conversation Endpoints view, you'll see that I've added a new column into the mix:
far_service. This column tells us what service the dialog is targeting, and you should see two dialogs
, each conversing to different services but both on the same conversation group.
Each of the targets can receive messages as usual, and send them back to the initiator:
*/
DECLARE @h UNIQUEIDENTIFIER

;RECEIVE @h = conversation_handle
FROM BLOB_Queue_Target

;SEND ON CONVERSATION @h
MESSAGE TYPE BLOB
(CONVERT(varbinary, 'Back at you from Queue_Target'))

;RECEIVE @h = conversation_handle
FROM BLOB_Queue_Target2

;SEND ON CONVERSATION @h
MESSAGE TYPE BLOB
(CONVERT(varbinary, 'Back at you from Queue_Target2'))
GO

/*
The initiator can now receive both messages that we've sent back, using only the conversation group ID 
-- despite the fact that the messages are on different conversations.
*/
RECEIVE * FROM BLOB_Queue_Init
WHERE conversation_group_id = 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE'
GO

/*
-- Conversation Group Locking --
We've now seen the power of conversation groups as a means by which to introduce some logical organization to sets of conversations. 
But conversation groups play a much bigger role in the overall Service Broker infrastructure.
Since the Service Broker is a database engine technology and supports all of the same ACID rules 
as any other data in your database, it should come as no surprise to hear that it uses locking 
(and, as a consequence, blocking) to achieve isolation. 
One might, at first glance, assume that the granularity of the locks will be at the conversation or dialog level. 
But the designers of Service Broker realized that some processes are much more distributed than a single conversation
--so locking instead occurs at the granularity of conversation groups.=
If you've been following along and running the examples, you should have two conversing dialogs at this point
, each with an initiator on the same conversation group. 
We can use these dialogs to examine the ins and outs of conversation group locking.
First we'll send a message from the Target2 service to the initiator:
*/
DECLARE @h UNIQUEIDENTIFIER

SELECT @h = conversation_handle
FROM sys.conversation_endpoints
WHERE 
    conversation_id = 
    (
        SELECT conversation_id
        FROM sys.conversation_endpoints
        WHERE far_service = 'BLOB_Service_Target2'
    )
    AND is_initiator = 0

;SEND ON CONVERSATION @h
MESSAGE TYPE BLOB
(CONVERT(varbinary, 'Hello again, from Queue_Target2'))
GO

SELECT * FROM sys.conversation_endpoints
SELECT * FROM BLOB_Queue_Init
SELECT * FROM BLOB_Queue_Target
SELECT * FROM BLOB_Queue_Target2
/*

To show the effects of locking, open a new SSMS window, begin a transaction and do a RECEIVE for the conversation group:
--- RUN THIS IN A NEW WINDOW!
BEGIN TRAN

;RECEIVE *
FROM BLOB_Queue_Init
WHERE conversation_group_id = 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE'
---

Back in this window, let's try sending a message to the Target service:

*/
DECLARE @h UNIQUEIDENTIFIER

SELECT @h = conversation_handle
FROM sys.conversation_endpoints
WHERE
    conversation_group_id = 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE'
    AND far_service = 'BLOB_Service_Target'

;SEND ON CONVERSATION @h
MESSAGE TYPE BLOB
(CONVERT(varbinary, 'Hi, Queue_Target'))
GO

--Once you get sick of waiting for this to finish, go ahead
--and hit the Stop button.

/*

As you can see, we're blocked, even though we're sending a message on a different conversation 
than the one that we've received a message on. The net effect is that the entire group 
represents a single transactional unit--a powerful concept
, if you need to do several subtasks as part of some bigger piece of work.

But now for the cool part. The conversation group that we're working with is locked
, but remember that a dialog has two sides, each of which operates under its own conversation group. 
This means that even when one side is locked, the other side is free to continue working
, and even free to continue sending messages:
*/
DECLARE @h UNIQUEIDENTIFIER

SELECT @h = conversation_handle
FROM sys.conversation_endpoints
WHERE 
    conversation_id = 
    (
        SELECT conversation_id
        FROM sys.conversation_endpoints
        WHERE far_service = 'BLOB_Service_Target2'
    )
    AND is_initiator = 0

;SEND ON CONVERSATION @h
MESSAGE TYPE BLOB
(CONVERT(varbinary, 'Another hello from Queue_Target2'))
GO

/*

We've now sent a message. Let's take a peek and see if it showed up:

*/
SELECT *
FROM BLOB_Queue_Init WITH (NOLOCK)
GO

/*

Running the preceding query should return one row, for the message that we just sent. 
The NOLOCK hint is necessary, in order to get around the locked messages, still held by the transaction in the other window.
What do you think will happen if we try to do a second RECEIVE outside the scope of the transaction?
*/
RECEIVE *
FROM BLOB_Queue_Init
WHERE conversation_group_id = 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE'

/*
If you've just run the preceding query, you might be surprised by the results. 
We have a message in the queue for the specified conversation group
, and the conversation group is locked by the transaction
, so shouldn't we see some blocking rather than an empty result set?

To help explain this phenomenon, initiate a new conversation, from the Target service to the Init service
, and send a message:
*/
DECLARE @h UNIQUEIDENTIFIER

BEGIN DIALOG CONVERSATION @h
FROM SERVICE BLOB_Service_Target
TO SERVICE 'BLOB_Service_Init'
ON CONTRACT BLOB_Contract
WITH ENCRYPTION=OFF

;SEND ON CONVERSATION @h
MESSAGE TYPE BLOB
(CONVERT(varbinary, 'Initiating from Target'))

--What's in the queue now?
SELECT *
FROM BLOB_Queue_Init WITH (NOLOCK)
GO

/*
Now there are two messages in the queue, each belonging to different conversation groups. 
What will be the result, then, of a RECEIVE with no WHERE clause?
*/
RECEIVE *
FROM BLOB_Queue_Init
GO

/*
This RECEIVE is not blocked--and that's a good thing, because we want multiple readers 
to be able to work with the queue simultaneously. What Service Broker actually does internally 
as part of the RECEIVE, is use the equivalent of a READPAST hint. 
The locked conversation groups are skipped, thereby greatly increasing concurrency.

There is one other side-effect of the way Service Broker handles conversation group locking. 
To prepare, first go back to the other window and commit the transaction:
--- RUN THIS IN THE OTHER WINDOW
COMMIT
---

Now start another dialog and send a message to the Init queue:

*/
DECLARE @h UNIQUEIDENTIFIER

BEGIN DIALOG CONVERSATION @h
FROM SERVICE BLOB_Service_Target
TO SERVICE 'BLOB_Service_Init'
ON CONTRACT BLOB_Contract
WITH ENCRYPTION=OFF

;SEND ON CONVERSATION @h
MESSAGE TYPE BLOB
(CONVERT(varbinary, 'Initiating from Target... Again'))

--What's in the queue now?
SELECT *
FROM BLOB_Queue_Init
GO

/*
We once again have two messages in the queue, both on separate conversation groups. 
But this time the NOLOCK hint wasn't needed for the SELECT
--no transactions are active and neither of the conversation groups are locked.

So once again we pose an all-important question: In this situation, how should a RECEIVE with no WHERE clause behave?
*/
RECEIVE *
FROM BLOB_Queue_Init
GO

/*
Running the RECEIVE, you'll see that only a single message is returned. 
This doesn't mean that RECEIVE can't return multiple messages at a time
--it can, and as shown in the previous workbench it supports the TOP clause. 
What we're actually seeing in this case is RECEIVE only returning messages from a single conversation group at a time.

Yet again, this is an effort by the Service Broker team to promote high concurrency. 
If you have a farm of workers, each pulling tasks off of a central Service Broker queue
, this single group at a time behavior ensures that each worker takes at most a single task
, and at the same time the READPAST guarantees that workers don't block each other. 
The result is a high performance and highly concurrent queuing system
--exactly what we want from something like Service Broker.

In the next installment of this workbench I'll discuss worker farms and considerations 
for read performance in quite a bit more depth. 
Until then, you should now have a good feeling for how Service Broker handles locking and blocking.
*/

/*
-- Message Activation --
We are programmers, and a prerequisite for being a programmer is being an incredibly lazy person. 
The whole point of computer programming is to spend a bit of time upfront to make a machine do 
all of the repetitive tasks while we sit back and watch. Programming is a fantastic career 
for those of us who prefer surfing the Web to sitting around waiting for data to come in for us to process. 
We let the computers do this grunt work. Yet we haven't really let the computer do anything with Service Broker yet. 
We have run all of the RECEIVE statements ourselves--seriously cutting into our surfing habit.

Luckily, the creators of Service Broker are also programmers, and they understand that we need time to ourselves. 
The answer to this burning need for freedom is Service Broker's message activation feature. 
Turning on message activation for a queue tells Service Broker to sit and quietly wait for a message to arrive. 
When--and only when--a message shows up, Service Broker suddenly comes alive
, running whatever stored procedure you've told it to start up in the event that a message does appear.

Message activation is nothing difficult to understand now that we've gone through most of the 
Service Broker infrastructure in detail. A properly written activation stored procedure uses 
the same RECEIVE logic and statements we've already covered. The only difference, as you'll see
, is that an activation procedure generally wraps these constructs in a loop in order to make things a bit more efficient.

To demonstrate activation, our procedure needs to actually do something that we can observe 
once it has taken place. So to start with, create the following table, which we'll insert some rows into asynchronously:

*/
CREATE TABLE TestActivation
(
    theMessage VARBINARY(MAX)
)
GO

/*
Once the table has been created, we can put our very first activation procedure into place. 
This procedure is nothing more than a slightly-modified version of the code from the 
"Ending the Conversation, Part 2" section of the first part of this workbench, wrapped in a stored procedure.
*/
CREATE PROCEDURE InsertTestActivation
AS
BEGIN
    SET NOCOUNT ON

    DECLARE 
        @h UNIQUEIDENTIFIER,
        @t sysname,
        @b varbinary(max)

    --Get all of the messages on the queue
    WHILE 1=1
    BEGIN
        SET @h = NULL

        --Note the semicolon..!
        ;RECEIVE TOP(1) 
            @h = conversation_handle,
            @t = message_type_name,
            @b = message_body
        FROM BLOB_Queue_Target

        --No message RECEIVEd
        IF @h IS NULL
        BEGIN
            BREAK
        END
        --BLOB message
        ELSE IF @t = 'BLOB'
        BEGIN
            INSERT TestActivation 
            VALUES (@b)
        END
        --EndDialog message
        ELSE IF @t = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
        BEGIN
            INSERT TestActivation 
            VALUES (CONVERT(varbinary(MAX), 'EndDialog'))

            END CONVERSATION @h
        END
        --Any other message type
        ELSE
        BEGIN
            INSERT TestActivation
            VALUES (CONVERT(varbinary(MAX), 'Unknown'))
        END
    END        
END
GO

/*
This stored procedure loops over all of the messages in the BLOB_Service_Target queue
, inserting the bodies into the TestActivation table. It also follows all of the rules 
of being a good Service Broker consumer; if it gets an EndDialog message, it ends its own side of the conversation. 
And if it receives a a message it doesn't know how to deal with, it gracefully handles the situation.

Since there is still a message sitting on the queue from a previous run, you can test the procedure now
, before actually enabling it for activation.

*/
EXEC InsertTestActivation
GO

SELECT * FROM TestActivation
GO

DELETE FROM TestActivation
GO

/*
Actually using the procedure as an activation service is a simple matter of using
ALTER QUEUE and telling Service Broker about the module:
*/
ALTER QUEUE BLOB_Queue_Target
WITH ACTIVATION
(
    STATUS = ON,
    PROCEDURE_NAME = InsertTestActivation,
    MAX_QUEUE_READERS = 1,
    EXECUTE AS OWNER
)
GO

/*
few notes on the options I've used:
STATUS = ON is simple enough. Setting STATUS to ON enables activation for the queue
, meaning that as soon as a message arrives the activation procedure will be fired.

The PROCEDURE_NAME is, of course, the name of the activation procedure.

And EXECUTE AS OWNER tells Service Broker to call the activation stored procedure 
using the credentials of whatever principal owns it--in this case, presumably your user.

I haven't forgotten about MAX_QUEUE_READERS, but rather saved it; we'll get to it in just a moment
, but first let's test activation by sending a message and seeing whether it arrives in the table.
*/
DECLARE @h UNIQUEIDENTIFIER

BEGIN DIALOG CONVERSATION @h
FROM SERVICE BLOB_Service_Init
TO SERVICE 'BLOB_Service_Target'
ON CONTRACT BLOB_Contract
WITH ENCRYPTION=OFF

;SEND ON CONVERSATION @h
MESSAGE TYPE BLOB
(CONVERT(varbinary, 'Test TestActivation'))

SELECT * FROM TestActivation
GO

/*
If you've just run the preceding batch, you might notice that no rows were returned by the query. 
Is activation broken? The answer, if you've been running all of the code to this point, is of course no. 
The reason that no rows were returned is that activation is an asynchronous process
, kicked off by a queue monitor thread that only checks for new messages every few seconds. 
Therefore, after a message is sent, you shouldn't expect the stored procedure to instantly kick in
--it might take a second or two before the queue monitor passes by and starts things up.

Running the SELECT again, you should now see the expected row:
*/

SELECT * FROM TestActivation
GO

/*
As an aside, if activation still wasn't working in a real system, you might want to check the 
Service Queues catalog view, which includes columns to help you determine whether activation is enabled
, and which stored procedure has been configured for activation.
*/
SELECT
    name,
    activation_procedure,
    is_activation_enabled
FROM sys.service_queues
WHERE name = 'BLOB_Queue_Target'
GO

/*
Back to the main task at hand: At this point we've handled a single message with a single queue reader. 
Now it's time to talk about multiple readers, as specified by the MAX_QUEUE_READERS option.
This is the feature that makes activation much more than just a simple background process. 
Sure, we can do one message, but what about when multiple messages show up? With MAX_QUEUE_READERS set to 1
, Service Broker will only start up one instance of the procedure at a time. 
And this is fine for us, since our procedure has a loop; it can handle multiple messages after being called just once. 
But what if its processing duties are slow, and it's not clearing the queue fast enough? 
This is when a higher MAX_QUEUE_READERS value starts to look interesting.

If MAX_QUEUE_READERS is set to a value above 1, the same queue monitor that started activation 
to begin with will eventually kick off more instances of the stored procedure. This will keep going until 
either the queue empties, or the number of running instances hits the maximum specified by the option.

To see this in action, a WAITFOR DELAY can be inserted into the a test stored procedure to slow it down 
and keep the queue from clearing too quickly. To keep things simple, I am trimming off all of the "
best practice" code involving ending conversations and dealing with unknown message types.

*/
CREATE PROCEDURE ActivationWithDelay
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @h UNIQUEIDENTIFIER

    --Get all of the messages on the queue
    WHILE 1=1
    BEGIN
        SET @h = NULL

        --Note the semicolon..!
        ;RECEIVE TOP(1) 
            @h = conversation_handle
        FROM BLOB_Queue_Target

        --No message received
        IF @h IS NULL
        BEGIN
            BREAK
        END
        ELSE
        BEGIN
            --Wait one quarter of a second
            WAITFOR DELAY '00:00:00.20'
        END
    END
END
GO

/*
To test activation timing and get a feel for how it works, we'll first disable activation on the queue
, then send 2500 messages to prime the pump.
*/
ALTER QUEUE BLOB_Queue_Target
WITH Activation
(
    STATUS = OFF
)
GO

DECLARE @h UNIQUEIDENTIFIER

BEGIN DIALOG CONVERSATION @h
FROM SERVICE BLOB_Service_Init
TO SERVICE 'BLOB_Service_Target'
ON CONTRACT BLOB_Contract
WITH ENCRYPTION=OFF

;SEND ON CONVERSATION @h
MESSAGE TYPE BLOB
(CONVERT(varbinary, 'DELAY'))
GO 2500

/*
To monitor the activation, we will use the Broker Activated Tasks view. The following query should 
return a count of 0, since activation is currently disabled on the queue:
*/

SELECT COUNT(*)
FROM sys.dm_broker_activated_tasks t
WHERE t.queue_id = OBJECT_ID('BLOB_Queue_Target')
GO

/*
The next batch will turn activation back on for the queue, with a specified maximum number 
of activation procedures set to 10. It will then start looping until the first activation procedure kicks in. 
After that it will report on the number of active activation procedures once every two seconds
, until they're all gone (meaning that the queue is empty). After starting the batch
, you should switch to the Messages pane in SSMS unless you have Results to Text mode enabled. 
Note that this batch takes around one minute to run on my notebook. Your timing may vary!
*/
ALTER QUEUE BLOB_Queue_Target
WITH ACTIVATION
(
    STATUS = ON,
    PROCEDURE_NAME = ActivationWithDelay,
    MAX_QUEUE_READERS = 10,
    EXECUTE AS OWNER
)

DECLARE @startTime DATETIME
SET @startTime = GETDATE()

WHILE NOT EXISTS 
(
    SELECT *
    FROM sys.dm_broker_activated_tasks t
    WHERE t.queue_id = OBJECT_ID('BLOB_Queue_Target')
)
    WAITFOR DELAY '00:00:00.25'

DECLARE @numReaders INT
DECLARE @count INT

WHILE 1=1
BEGIN
    SELECT @numReaders = COUNT(*)
    FROM sys.dm_broker_activated_tasks
    WHERE queue_id = OBJECT_ID('BLOB_Queue_Target')

    IF @numReaders > 0
    BEGIN
        SELECT
            @count = COUNT(*)
        FROM BLOB_Queue_Target WITH (NOLOCK)

        DECLARE @message VARCHAR(100)
        SET @message = 
            'Elapsed Time (seconds): ' +
            CONVERT(VARCHAR, DATEDIFF(ss, @startTime, GETDATE())) +
            ' Number of Readers: ' +
            CONVERT(VARCHAR, @numReaders) +
            ' Remaining Messages: ' +
            CONVERT(VARCHAR, @count)
        RAISERROR(@message, 10, 1) WITH NOWAIT

        WAITFOR DELAY '00:00:02'
    END
    ELSE
    BEGIN
        RAISERROR('Finished!', 10, 1) WITH NOWAIT
        BREAK
    END
END
GO

/*
By now you should have a feeling for the basics of how activation behaves, but it's important to stress 
that you need to think beyond just getting messages through the queue. We must consider activation 
in the context of the entire server. Should you set the maximum number of readers to a huge enough number 
to keep the queue mostly clear all the time? While that would certainly make your services return more quickly
, it would also add a large amount of stress to the server. One of the reasons that queues are handy is that 
they can let work back up if it can't be handled right away. When working with Service Broker, make sure to consider all aspects of the system, not just maximization of the one piece you're focusing on.

The activation procedures shown here could be made a bit better. I've left out two key parts of 
the generally accepted activation procedure pattern: Use of WAITFOR on the receive and use of a transaction.

To see the utility of WAITFOR(RECEIVE), consider what happened at the end of the test run in the last batch. 
The moment there were no messages left to process, all of the activation procedures immediately stopped running. 
What if another batch of messages arrived just afterward? All of the procedures would have to spin back up
, and the newly arrived messages would not be handled as quickly as the final messages that were on the queue 
at the end of the test. By using WAITFOR(RECEIVE) with a small timeout--say, a few seconds
--we can make sure that the stored procedures stick around once the work is done, in case more should arrive.

Another issue is use of a transaction. What if a hardware error occurs between receiving the message from the queue 
and processing it? The message would be lost--unless we wrap the entire thing in a transaction.

An updated version of the InsertTestActivation stored procedure follows. This version uses a transaction in conjunction 
with the XACT_ABORT setting, to make sure that a rollback will occur in the event of any error. 
The procedure also uses WAITFOR(RECEIVE), with a timeout of five seconds.

Note that one consequence of transactions is what happens when a certain message keeps causing a rollback. 
I won't get into the details here; search Books Online for "poison message handling" for more information.

*/
ALTER PROCEDURE InsertTestActivation
AS
BEGIN
    SET NOCOUNT ON
    SET XACT_ABORT ON

    DECLARE 
        @h UNIQUEIDENTIFIER,
        @t sysname,
        @b varbinary(max)

    --Get all of the messages on the queue
    WHILE 1=1
    BEGIN
        BEGIN TRANSACTION

        SET @h = NULL

        --Wait up to five seconds for a message
        WAITFOR
        (
            RECEIVE TOP(1) 
                @h = conversation_handle,
                @t = message_type_name,
                @b = message_body
            FROM BLOB_Queue_Target
        ), TIMEOUT 5000

        --No message received
        IF @h IS NULL
        BEGIN
            ROLLBACK
            BREAK
        END
        --BLOB message
        ELSE IF @t = 'BLOB'
        BEGIN
            INSERT TestActivation 
            VALUES (@b)
        END
        --EndDialog message
        ELSE IF @t = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
        BEGIN
            INSERT TestActivation 
            VALUES (CONVERT(varbinary(MAX), 'EndDialog'))

            END CONVERSATION @h
        END
        --Any other message type
        ELSE
        BEGIN
            INSERT TestActivation
            VALUES (CONVERT(varbinary(MAX), 'Unknown'))
        END

        
        COMMIT
    END        
END
GO

/*
-- Routing and Cross-Database Messaging --
We've now covered just about every aspect of same-database conversations that you'll commonly need to be concerned with 
when you work with Service Broker. But we need to remember that SSB is more than just a queuing system
--it's also a messaging infrastructure.

Same-database messaging certainly has its utility, but when we usually talk about messaging we think about 
communication between remote parties. For the sake of this workbench I won't ask you to set up a separate server
--our remote parties will be two databases in the same instance--but the concepts and all of the code 
I'll show you will be the same if you choose to extend the example across multiple servers or even multiple data centers.

Routing is a complex topic, and I'll just cover the basics here. What you need to know is that 
whenever you specify a target service when creating a message, you are not limited to a service in the local database
; you can tell Service Broker about remote services in other databases or on other instances
, using the CREATE ROUTE DDL statement. These routes are exposed via a catalog view called sys.routes:
*/

SELECT * FROM sys.routes
GO

/*
Running the above query, you should see only one route, which is automatically created for the local database. 
But what if we want to send a message to another database? Let's create one and find out what happens:
*/
CREATE DATABASE Simple_Talk_SSB2a
GO
USE Simple_Talk_SSB2a
GO

--Setup all the basics
CREATE MASTER KEY
ENCRYPTION BY PASSWORD = 'onteuhoeu'
GO
CREATE MESSAGE TYPE BLOB
VALIDATION = NONE
GO
CREATE CONTRACT BLOB_Contract
(BLOB SENT BY ANY)
GO
CREATE QUEUE BLOB_Queue_Remote
GO
CREATE SERVICE BLOB_Service_Remote
ON QUEUE BLOB_Queue_Remote(BLOB_Contract)
GO

/*
A final step is required because we'll be talking to a remote database: permissions to set who can 
send messages to the service. For simplicity we'll set it to [Public] (everyone)
; in your real applications you should configure this to something more realistic based on your security requirements.
*/
GRANT SEND ON SERVICE::BLOB_Service_Remote TO [Public];
GO

/*
Back in the SSB2 database, try sending a message to the remote queue and see if it shows up:
*/
USE Simple_Talk_SSB2
GO

DECLARE @h UNIQUEIDENTIFIER

BEGIN DIALOG CONVERSATION @h
FROM SERVICE BLOB_Service_Init
TO SERVICE 'BLOB_Service_Remote'
ON CONTRACT BLOB_Contract
WITH ENCRYPTION=OFF

;SEND ON CONVERSATION @h
MESSAGE TYPE BLOB
(CONVERT(VARBINARY, 'Test_Remote'))
GO

/*
Once the message is sent, query the remote queue.
*/
SELECT * FROM Simple_Talk_SSB2a..BLOB_Queue_Remote
GO

/*
You should now see an empty result set. Where did the message go?
The primary tool used when debugging routing issues is the Transmission Queue, a catalog view that we can interrogate 
to see messages that weren't successfully sent. The following query should return one row
, for the message that we know has just failed.

*/
SELECT 
    to_service_name,
    message_body,
    transmission_status
FROM sys.transmission_queue
GO

/*
If a message ends up in the transmission queue, it's usually not dead. Service Broker will retry the send periodically
, waiting up to a minute between each try. This means that once you fix the problem
, the messages sitting in the transmission queue will eventually make it to their destination.

The problem in this situation is that Service Broker cannot cross database boundaries without a route
, if the database is not set for TRUSTWORTHY mode. That's a good thing--it helps ensure security
--so let's take the high road and tell Service Broker how to route the message.

The first step in routing is to create a Service Broker endpoint on each instance of SQL Server involved in the route. 
In this case we have only one instance, so a single endpoint will do. The following CREATE ENDPOINT statement 
creates an endpoint on port 9998. Since the SQL Server service account always has access to its own service
, we'll use Windows authentication. In your actual environments you can choose either Windows authentication 
or use of a certificate; see Books Online for more information. Finally, again for simplicity, we'll keep encryption disabled.

*/
CREATE ENDPOINT SSB_Endpoint
STATE = STARTED
AS TCP 
(
    LISTENER_PORT = 9998
)
FOR SERVICE_BROKER
(
    AUTHENTICATION = WINDOWS,
    ENCRYPTION = DISABLED
)
GO


/*
We can verify that the endpoint was successfully created and
started by using the Service Broker Endpoints view:
*/
SELECT
    name,
    state_desc
FROM sys.service_broker_endpoints


/*
Once the endpoint has been created, a route can be put into place, using the TCP address of the endpoint: localhost:9998.
The route will be created for messages being sent to the service called 'BLOB_Service_Remote'
, and we'll tell Service Broker which database the remote service is in, by using the Broker Instance GUID 
that is automatically created for each database. To get the GUID, query sys.databases:
*/

SELECT service_broker_guid
FROM sys.databases
WHERE name = 'Simple_Talk_SSB2a'
GO

/*
Once you've obtained the GUID, replace the one below and create
the route:
*/
CREATE ROUTE TestRemoteRoute
WITH
    SERVICE_NAME = 'BLOB_Service_Remote',
    ADDRESS = 'tcp://localhost:9998',
    --Use the GUID from above
    BROKER_INSTANCE = 'EECFA1EA-EBA9-4042-9C76-6470AD9ED2B3'
GO


/*
To verify that the route has been successfully created, you can
once again query the sys.routes view:
*/
SELECT
    remote_service_name,
    broker_instance,
    address
FROM sys.routes
WHERE name = 'TestRemoteRoute'
GO

/*
At this point, assuming that you're not an exceptionally fast reader, a minute has probably passed since 
the message send originally failed. If the following query returns no rows, wait a few more moments and try again. 
Now that the route is in place, the message should eventually show up.

*/
SELECT * FROM Simple_Talk_SSB2a..BLOB_Queue_Remote
GO

/*
Clean Up Our Mess!
*/
USE master
GO
DROP DATABASE Simple_Talk_SSB2
GO
DROP DATABASE Simple_Talk_SSB2a
GO
DROP ENDPOINT SSB_Endpoint
GO

/*
We've certainly come a long way from Part 1 of this workbench! After reading this second part
, you should now be equipped to handle most Service Broker challenges, including some troubleshooting 
and maintenance using the catalog views and Service Broker specific DDL. You should also understand 
some of the transactional internals as well as activation and routing behaviors.

The third and final part of this workbench series will apply what we've already covered
, to create some interesting technical solutions that would not be nearly as easy to put together without Service Broker. 
Stay tuned for Part 3, coming to Simple Talk soon!
*/
