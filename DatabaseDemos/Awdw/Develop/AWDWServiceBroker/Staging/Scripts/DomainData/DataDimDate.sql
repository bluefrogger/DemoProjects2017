
declare @StartDate date = '2000-01-01'
declare @EndDate date = '2003-12-31'

select
	nb
	, dt.Dt
	, convert(char(8), dt.Dt, 112) as Dt112
	, convert(char(10), dt.Dt, 101) as Dt101
	, dp.YY
	, dp.MM
	, dp.FDtofMM
	, dp.LDtofMM
	, dp.QQ
	, min(dt.Dt) over (partition by dp.QQ) as FDtofQQ
	, max(dt.Dt) over (partition by dp.QQ) as LDtofQQ
	, dp.DD
	, dp.Dw
	, DwName
	, convert(nchar(3), dp.DwName) as DwShort
	, convert(nchar(2), dp.DwName) as DwAbbr
	, dp.Dy as DDofYY
	, dp.Dw as DDofWk
	, dp.Dy / 7 + 1 as WkofYY
	, dp.DD / 7 + 1 as WkOfMM
	, (datepart(dd, dp.LDtofMM) - dp.DD) / 7 + 1 as WkNoReverse
	, datepart(dd, dp.LDtofMM) as LDDofMM
from dbo.Tally
cross apply(
	select dateadd(dd, nb, @StartDate) as Dt
) as dt
cross apply(
	select datepart(yy, dt.Dt) as YY
		, datepart(mm, dt.Dt) as MM
		, datepart(dd, dt.Dt) as DD
		, datepart(qq, dt.Dt) as QQ
		, datepart(dw, dt.Dt) as Dw
		, datename(dw, dt.Dt) as DwName
		, datepart(dy, dt.Dt) as Dy
		, convert(date, dateadd(mm, datediff(mm, 0, dt.DT), 0)) as FDtofMM
		, convert(date, dateadd(mm, datediff(mm, -1, dt.DT), -1)) as LDtofMM
) as dp
where nb <= datediff(dd, @StartDate, @Enddate)