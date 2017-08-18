USE [DAR_Members]
GO
/****** Object:  UserDefinedFunction [dbo].[fnHH_Number_Cleanup]    Script Date: 8/26/2015 4:07:20 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- SELECT [dbo].[fnHH_Number_Cleanup]('34ff7316fuf443')

CREATE FUNCTION [dbo].[fnHH_Number_Cleanup] (@StrVal AS VARCHAR(max))
RETURNS VARCHAR(max)
AS
BEGIN
      WHILE PATINDEX('%[^0-9]%', @StrVal) > 0
            SET @StrVal = REPLACE(@StrVal,
                SUBSTRING(@StrVal,PATINDEX('%[^0-9]%', @StrVal),1),'')
                      
      RETURN @StrVal
END

GO
