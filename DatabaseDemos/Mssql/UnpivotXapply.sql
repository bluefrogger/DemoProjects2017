DECLARE @tab TABLE (
	id INT NULL
	, home NVARCHAR(50) NULL
	, work NVARCHAR(50) NULL
	, cell NVARCHAR(50) NULL
	, email NVARCHAR(50) NULL
	, wemail NVARCHAR(50) NULL
)

INSERT @tab (id, home, work, cell, email, wemail)
VALUES (1, 'Austin', 'Dallas', '999-999-9999', 'me@me.com', 'work@work.com')
	,(2, 'Houston', 'Kansas', '111-111-1111', 'rock@rock.com', 'do@do.com')

SELECT id
     , home
     , work
     , cell
     , email
     , wemail FROM @tab

SELECT tab.id, cros.col, cros.val
FROM @tab AS tab
CROSS APPLY (
	VALUES ('home', tab.home)
		, ('work', tab.work)
		, ('cell', tab.cell)
		, ('email', tab.email)
		, ('wemail', tab.wemail)
) AS cros(col, val)

SELECT upiv.id
     , upiv.val
     , upiv.col
FROM
(
	SELECT id
		 , home
		 , work
		 , cell
		 , email
		 , wemail
	FROM @tab
) AS src
UNPIVOT (
	val FOR col IN (
		home
		 , work
		 , cell
		 , email
		 , wemail
	)
) AS upiv
GO

