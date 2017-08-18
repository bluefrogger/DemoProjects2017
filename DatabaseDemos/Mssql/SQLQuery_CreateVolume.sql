
;with fam as
(
select top 30000 id from tbldoc with(nolock)
where srm_prodvolume = 'MS101002'
and srm_delvolume is null
and attachlvl = 0
and attachpid <> 0
order by begdoc#
),
nofam as
(
select top 30000 id from tbldoc with(nolock)
where srm_prodvolume = 'MS101002'
and srm_delvolume is null
and attachlvl = 0
and attachpid = 0
order by begdoc#
)
select count(*) from tbldoc docs
inner join
(
select fam_all.id from tbldoc as fam_all
inner join fam
on fam_all.attachpid = fam.id
union all
select id from nofam
) as id_all
on docs.id = id_all.id


;WITH fam
AS (
	SELECT TOP 30000 id
	FROM tbldoc WITH (NOLOCK)
	WHERE srm_prodvolume = 'MS101002'
		AND srm_delvolume IS NULL
		AND attachlvl = 0
		AND attachpid <> 0
	ORDER BY begdoc#
	)
	,nofam
AS (
	SELECT TOP 30000 id
	FROM tbldoc WITH (NOLOCK)
	WHERE srm_prodvolume = 'MS101002'
		AND srm_delvolume IS NULL
		AND attachlvl = 0
		AND attachpid = 0
	ORDER BY begdoc#
	)
SELECT count(*)
--update tbldoc set srm_delvolume = 'CTRL004'
FROM tbldoc docs
INNER JOIN 
(
	SELECT fam_all.id
	FROM tbldoc AS fam_all 
	INNER JOIN fam ON fam_all.attachpid = fam.id
	
	UNION ALL
	
	SELECT id
	FROM nofam
) AS id_all 
ON docs.id = id_all.id
