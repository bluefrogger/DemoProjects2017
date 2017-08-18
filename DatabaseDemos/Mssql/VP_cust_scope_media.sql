
select c.firstname, c.lastname, s.scopeid, m.mediaid, count(*) from edoc as e with(nolock)
inner join edocoperations as o with(nolock)
on e.docid = o.docid
inner join srm23.p00143_review.dbo.userviewdoc as v with(nolock)
on e.docid = v.docid
inner join media m with(nolock) on e.mediaid = m.mediaid
inner join scope s with(nolock) on m.scopeid = s.scopeid
inner join custodian c with(nolock) on s.custodianid = c.custodianid
where uvid = 761
and createtiffstatuscode = 7
and e.docid = 0000166428
group by c.firstname, c.lastname, s.scopeid, m.mediaid