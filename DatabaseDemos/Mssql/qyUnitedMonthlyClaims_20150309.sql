use dar_raw_data

/*
1. Every claimcod that has a paydte has only one:
Server: ybcm1s5
use dar_raw_data
*/
select claimcod, paydte
into #ss
from raw.United_medClaims 
where paydte is not NULL
group by claimcod, paydte

select claimcod, count(*)
from #ss
group by claimcod
having count(*) > 1

/*
2. There are 112408 claimcod with no paydte at all.
These claimcod only had fileperiods from 201409, 201410, 201411.
Maybe these three dates had no paydte yet. (see point 4)
*/
select aa.claimcod 
from raw.united_medclaims as aa
left join (
      select claimcod from #ss
) as ss
on aa.claimcod = ss.claimcod
where ss.claimcod is null


select distinct fileperiod
from raw.united_medclaims as aa
left join (
      select claimcod from #ss
) as ss
on aa.claimcod = ss.claimcod
where ss.claimcod is null

/*
3. Here is modified source table to compare fileperiod and paydte:
*/
select  
    aa.MEMCODE
    ,aa.CLAIMCOD
    ,aa.seq
    ,'201308' as fileperiodstart --same for all rows
    ,right(substring(aa.fileperiod, 8, len(aa.fileperiod)),4)
        + left(substring(aa.fileperiod, 8, len(aa.fileperiod)),2) as fileperiodend --splits start from fileperiod
    ,row_number() over (partition by aa.memcode, aa.claimcod order by aa.fileperiod) as sort --orders fileperiods for each claimcod
    ,convert(varchar(6), aa.paydte, 112) as paydte --reformat paydte for easier compare
    ,convert(varchar(6), cc.pdate, 112) as maxpaydte --reformat maxpaydte
      ,datediff(
       mm
       ,cast(cc.pdate as smalldatetime)
       ,cast(right(substring(aa.fileperiod, 8, len(aa.fileperiod)),4)
        + left(substring(aa.fileperiod, 8, len(aa.fileperiod)),2) + '01' as smalldatetime)
   ) as paidTime --difference between max(paydte) and fileperiod
    ,aa.DX1_DESC
into #tt
from raw.United_medClaims as aa
inner join(
    select claimcod, max(paydte) as pdate
    from raw.United_medClaims as bb    
    group by claimcod
    ) as cc
on aa.claimcod = cc.claimcod

/*
4. Using modified source: We see paydte compared to fileperiod 
occurred 1 to 15 months prior to fileperiod 
and anytime from 201308 to 201408
*/
select 
    min(paidTime)
    , max(paidTime)
    ,min(maxpaydte)
    ,max(maxpaydte)
from #tt
where paydte is null
/*
5. A more detailed view of the same:
*/
select DISTINCT
      paidTime
      ,fileperiodend
      ,maxpaydte
from #tt
where paydte is null
order by fileperiodend, maxpaydte
/*
Conclusion: The fileperiods with missing paydte either
1. occurred on 201409, 201410, 201411 (after 201408)
2. had a paydte anytime 1 to 15 months prior 
*/

--6. Here’s an updated source that also shows the last fileperiod with a paydte:
--drop table #tt
select 
    aa.MEMCODE
    ,aa.CLAIMCOD
    ,aa.seq
    ,'201308' as fileperiodstart --same for all rows
    ,right(substring(aa.fileperiod, 8, len(aa.fileperiod)),4)
        + left(substring(aa.fileperiod, 8, len(aa.fileperiod)),2) as fileperiodend --splits start from fileperiod
    ,row_number() over (partition by aa.memcode, aa.claimcod order by aa.fileperiod) as sort --orders fileperiods for each claimcod
    ,convert(varchar(6), aa.paydte, 112) as paydte --reformat paydte for easier compare
    ,convert(varchar(6), cc.pdate, 112) as maxpaydte --reformat maxpaydte
      ,datediff(
       mm
       ,cast(cc.pdate as smalldatetime)
       ,cast(right(substring(aa.fileperiod, 8, len(aa.fileperiod)),4)
        + left(substring(aa.fileperiod, 8, len(aa.fileperiod)),2) + '01' as smalldatetime)
   ) as paidTime --difference between max(paydte) and fileperiod
   ,right(substring(dd.ldate, 8, len(dd.ldate)),4)
        + left(substring(dd.ldate, 8, len(dd.ldate)),2) as lastdate --splits start from ldate
    ,aa.DX1_DESC
into #tt
from raw.United_medClaims as aa
inner join(
    select claimcod, max(paydte) as pdate
    from raw.United_medClaims as bb    
    group by claimcod
    ) as cc
on aa.claimcod = cc.claimcod
inner join(
      select claimcod, max(fileperiod) as ldate
      from raw.United_medClaims as bb
      where paydte is not null
    group by claimcod
) as dd
on aa.claimcod = dd.claimcod


--7. Any fileperiod with a paydte had one 1 to 12 months prior (1 to 15 actually includes no paydte too)
select distinct 
      maxpaydte
      ,lastdate
      ,datediff(
            mm
            ,left(maxpaydte,4) + right(maxpaydte,2) + '01'
            ,left(lastdate,4) + right(lastdate,2) + '01'
      ) as monthpaid
from #tt
order by monthpaid

