create procedure awlt2011.uspextractaddresscallback(
	@handle       uniqueidentifier = '00000000-0000-0000-0000-000000000000'
  , @servername   sysname
  , @databasename sysname
  , @schemaname   sysname
  , @objectname   sysname)
as
	begin
	begin try
		declare @synonymname sysname = 'synaddress';
		DECLARE @LoginName sysname = SUSER_NAME();
		DECLARE @UserName sysname = USER_NAME();

		exec awlt2011.synonymswitch @handle = @handle, @synonymname = @synonymname, @servername = @servername, @databasename = @databasename, @schemaname = @schemaname, @objectname = @objectname;

		declare @sql nvarchar(4000) = 'select * from '+
		(
			select awlt2011.ufnopenqueryaddress(@synonymname)
		);

		DECLARE @uttAddress awlt2011.uttAddress;

		insert @uttAddress
		exec @sql;

		exec dbo.usplogactivity @handle = @handle, @procid = @@procid, @parameter = @synonymname, @returnvalue = 'awlt2011.address', @loginname = @LoginName, @username = @UserName, @logstatus = 6;

		insert awlt2011.address (addressid, addressline1, addressline2, city, stateprovince, countryregion, postalcode, rowguid, modifieddate)
		select addressid , addressline1, addressline2, city, stateprovince, countryregion, postalcode, rowguid, modifieddate
		from awlt2011.uttaddress;

		exec dbo.usplogactivity @handle = @handle, @procid = @@procid, @parameter = 'awlt2011.uttaddress', @returnvalue = 'awlt2011.address', @loginname = @loginname, @username = @username, @logstatus = 6;
	end try
	begin catch
		declare @errornumber int = error_number();
		declare @errorseverity int = error_severity();
		declare @errorstate int = error_state();
		declare @errorprocedure sysname = error_procedure();
		declare @errorline int = error_line();
		declare @errormessage nvarchar(4000) = error_message();

		exec dbo.usplogerror @handle = @handle, @errornumber = @errornumber, @errorseverity = @errorseverity, @errorstate = @errorstate, @errorprocedure = @errorprocedure, @errorline = @errorline, @errormessage = @errormessage;
	end catch;
	end;
