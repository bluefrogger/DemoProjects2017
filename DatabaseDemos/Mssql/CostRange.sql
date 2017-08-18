ALTER PROC [dbo].[KG_CostRange] (
	@Amount DECIMAL(18,4)
) AS
BEGIN
	DECLARE @Result TABLE (
		Amount DECIMAL(18,4)
	);
	DECLARE @CountAbove INT;
	DECLARE @CountBelow INT;

	INSERT INTO @Result (Amount)
	SELECT TOP (4) Amount 
	FROM dbo.KG_CostRangeAmounts -- Switch with actual table
	WHERE Amount >= @Amount 
	ORDER BY Amount ASC;

	SELECT @CountAbove = COUNT(*) FROM @Result;
	SELECT @CountBelow = 4 - @CountAbove;
	
	IF (@CountAbove = 4)
		SELECT TOP (4) Amount FROM @Result ORDER BY Amount DESC;
	ELSE IF (@CountBelow > 0) 
	BEGIN
		INSERT @Result (Amount)
		SELECT TOP (@CountBelow) Amount	
		FROM dbo.KG_CostRangeAmounts -- Switch with actual table
		WHERE Amount < @Amount	
		ORDER BY Amount DESC;

		SELECT TOP (4) Amount FROM @Result ORDER BY Amount DESC;
	END
END
