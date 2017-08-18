
CREATE TABLE dbo.MyEmployees
(
	EmployeeID smallint NOT NULL,
	FirstName nvarchar(30)  NOT NULL,
	LastName  nvarchar(40) NOT NULL,
	Title nvarchar(50) NOT NULL,
	DeptID smallint NOT NULL,
	ManagerID int NULL,
 CONSTRAINT PK_EmployeeID PRIMARY KEY CLUSTERED (EmployeeID ASC) 
);
-- Populate the table with values.
INSERT INTO dbo.MyEmployees VALUES 
 (1, N'Ken', N'Sánchez', N'Chief Executive Officer',16,NULL)
,(273, N'Brian', N'Welcker', N'Vice President of Sales',3,1)
,(274, N'Stephen', N'Jiang', N'North American Sales Manager',3,273)
,(275, N'Michael', N'Blythe', N'Sales Representative',3,274)
,(276, N'Linda', N'Mitchell', N'Sales Representative',3,274)
,(285, N'Syed', N'Abbas', N'Pacific Sales Manager',3,273)
,(286, N'Lynn', N'Tsoflias', N'Sales Representative',3,285)
,(16,  N'David',N'Bradley', N'Marketing Manager', 4, 273)
,(23,  N'Mary', N'Gibson', N'Marketing Specialist', 4, 16);

select * from dbo.MyEmployees

;with Managers as(
	select EmployeeId, FirstName, LastName, Title, 0 as lvl
	from dbo.MyEmployees
	where ManagerID is null
	
	union all

	select emp.EmployeeId, emp.FirstName, emp.LastName, emp.Title, lvl + 1 as lvl
	from dbo.MyEmployees as emp
	join Managers as man
		on emp.ManagerId = man.EmployeeId
)
select * from Managers

