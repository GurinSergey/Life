select a1, a2 from (
select t_account a1, null a2 from daccount_dbt
where t_account like '40702%'
union
select null,t_account  from daccount_dbt)
where rownum <= 1000


select a1.t_account ac1
  from daccount_dbt a1
 where a1.t_chapter = 1
   and a1.t_open_close = chr (0)
   and a1.t_department = 1
   and a1.t_type_account not like '%Ï%'
   and a1.t_type_account not like '%Ò%'
   and a1.t_type_account not like '%Ó%'
   and abs (a1.t_r0) < 1000
   and a1.t_account like '40702%'
   and rownum <= 1000




create table acc (debet varchar2(20), kredit varchar2(20))