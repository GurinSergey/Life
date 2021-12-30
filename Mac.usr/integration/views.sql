prompt view_payment
CREATE OR REPLACE VIEW VIEW_PAYMENT
(paymentid, dockind, amount, paymentnumber, payeraccount, payercodename, payercode, payername, receiveraccount, receivercodename, receivercode, receivername, department, valuedate, ground, numpack, userfield1, userfield2, userfield3, userfield4, paymstatus)
AS
SELECT   paym.t_paymentid,
            paym.t_dockind,
            paym.t_amount,
            rmprop.t_number,
            paym.t_payeraccount,
            objkcode_p.t_name,
            pmprop_p.t_bankcode,
            rmprop.t_payername,
            paym.t_receiveraccount,
            objkcode_r.t_name,
            pmprop_r.t_bankcode,
            rmprop.t_receivername,
            paym.t_department,
            paym.t_valuedate,
            rmprop.t_ground,
            paym.t_numberpack,
            usr_rep_get_userfields(PAYM.T_PAYMENTID, paym.t_dockind, 1  ),
            usr_rep_get_userfields(PAYM.T_PAYMENTID, paym.t_dockind, 2  ),
            usr_rep_get_userfields(PAYM.T_PAYMENTID, paym.t_dockind, 3  ),
            usr_rep_get_userfields(PAYM.T_PAYMENTID, paym.t_dockind, 4  ),
            paym.t_paymstatus
     FROM   dpmpaym_dbt paym,
            dpmrmprop_dbt rmprop,
            dobjkcode_dbt objkcode_p,
            dobjkcode_dbt objkcode_r,
            dpmprop_dbt pmprop_p,
            dpmprop_dbt pmprop_r
    WHERE       paym.t_paymentid = rmprop.t_paymentid
            AND pmprop_p.t_codekind = objkcode_p.t_codekind(+)
            AND objkcode_p.t_objecttype(+) = 3
            AND pmprop_r.t_codekind = objkcode_r.t_codekind(+)
            AND objkcode_r.t_objecttype(+) = 3
            AND pmprop_p.t_debetcredit = 0
            AND pmprop_p.t_paymentid = paym.t_paymentid
            AND pmprop_r.t_debetcredit = 1
            AND pmprop_r.t_paymentid = paym.t_paymentid
;


prompt view_party
/*Лавренов: поменял на нормальную кодировку*/
create or replace view view_party
(partyid, name, partytype, codekind, code)
as
select pt.t_partyid,
          pt.t_name,
          decode (pt.t_legalform,
                  2,
                  'клиент ФЛ',
                  1,
                  nvl ( (select 'рег. орган'
                         from dpartyown_dbt ptown
                         where pt.t_partyid = ptown.t_partyid
                               and ptown.t_partykind = 6),
                       'клиент ЮЛ'
                  )
          )
             partytype,
          c.t_codekind,
          c.t_code
   from dparty_dbt pt, dobjcode_dbt c
   where     pt.t_partyid = c.t_objectid(+)
         and c.t_objecttype(+) = 3
         and c.t_state = 0;

prompt view_department
create or replace view view_department
(name, codename, code, parentcode, nodetypename, nodetype)
as
select   pt.t_name,
            dep.t_name,
            dep.t_code,
            dep.t_parentcode,
            (case dep.t_nodetype
                when 1 then 'филиал'
                when 2 then 'ВСП'
             end),
            dep.t_nodetype
     from   ddp_dep_dbt dep, dparty_dbt pt
    where   pt.t_partyid = dep.t_partyid;


prompt view_adrtype
create or replace view view_adrtype (name, adrtype)
as
   select t_name, t_type
     from dadrtype_dbt;

prompt view_objkdoc
create or replace view view_objkdoc (name, code)
as
   select t_name, t_regdockind
     from dobjkdoc_dbt where t_objecttype = 3;

prompt view_objkrgpt
create or replace view view_objkrgpt (name, regpartykind)
as
   select t_name, t_regpartykind
     from dobjkrgpt_dbt;

prompt view_paprkind
create or replace view view_paprkind (name, paperkind)
as
   select t_name, t_paperkind
     from dpaprkind_dbt;

prompt VIEW_COUNTRY
CREATE OR REPLACE VIEW VIEW_COUNTRY
(countryid, name, code)
AS
SELECT t_countryid, t_name, t_codelat3
   FROM dcountry_dbt ;

prompt VIEW_OBJKPARTY
CREATE OR REPLACE VIEW VIEW_OBJKPARTY
(name, codekind)
AS
SELECT t_name, t_codekind
   FROM dobjkcode_dbt
   WHERE t_objecttype = 3 ;

prompt VIEW_PTSERVKIND
CREATE OR REPLACE VIEW VIEW_PTSERVKIND
(partyid, servicekind, servicename, finishdate)
AS
SELECT   pt.t_partyid, pt.t_servicekind, kind.t_name, pt.t_finishdate
     FROM   dclient_dbt pt, dservkind_dbt kind
    WHERE   pt.t_servicekind = kind.t_servisekind;

prompt view_servkind
CREATE OR REPLACE VIEW VIEW_SERVKIND
(name, servicekind)
AS
SELECT t_name, t_servisekind
   FROM dservkind_dbt ;

/*
prompt view_accrest
create or replace view view_accrest (account, fiid, chapter, rest)
as
   select   ac.t_account, ac.t_code_currency, ac.t_chapter,
            nvl (  abs (ac.t_r0)
                 - sum ((select t.t_currentamount
                           from dacclaimstate_dbt t
                          where t.t_state <> 4
                            and t.t_claimid = cl.t_claimid
                            and t_statedate = (select max (t_statedate)
                                                 from dacclaimstate_dbt
                                                where t_claimid = t.t_claimid))
                       ),
                 abs (ac.t_r0)
                ) free_sum
       from daccount_dbt ac, dacclaim_dbt cl
      where cl.t_account(+) = ac.t_account and cl.t_chapter(+) = ac.t_chapter and cl.t_fiid(+) = ac.t_code_currency
   group by ac.t_account, ac.t_code_currency, ac.t_chapter, ac.t_r0
   union
   select   ac.t_account, ac.t_code_currency, ac.t_chapter,
            nvl (  abs (ac.t_r0)
                 - sum ((select t.t_currentamount
                           from dacclaimstate_dbt t
                          where t.t_state <> 4
                            and t.t_claimid = cl.t_claimid
                            and t_statedate = (select max (t_statedate)
                                                 from dacclaimstate_dbt
                                                where t_claimid = t.t_claimid))
                       ),
                 abs (ac.t_r0)
                ) free_sum
       from daccount$_dbt ac, dacclaim_dbt cl
      where cl.t_account(+) = ac.t_account and cl.t_chapter(+) = ac.t_chapter and cl.t_fiid(+) = ac.t_code_currency
   group by ac.t_account, ac.t_code_currency, ac.t_chapter, ac.t_r0
*/

/*
prompt view_acclaim
create or replace view view_acclaim (account, chapter, description, startamount)
as
   select   ac.t_account, ac.t_chapter, ac.t_comment, sum (st.t_currentamount)
    from dacclaim_dbt ac, dacclaimstate_dbt st
   where ac.t_claimid = st.t_claimid and st.t_state <> 4 and st.t_statedate = (select max (t_statedate)
                                                                                 from dacclaimstate_dbt
                                                                                where t_claimid = st.t_claimid)
group by ac.t_account, ac.t_comment, ac.t_chapter
*/

prompt view_notekind
create or replace view view_notekind (objecttype, objname, notekind, name)
as
   select t_objecttype, case t_objecttype
                            when 3
                               then 'субъект'
                            when 4
                               then 'счет'
                            when 501
                               then 'платеж'                           
                         end, t_notekind, t_name
     from dnotekind_dbt where t_objecttype in (3,4,501);

prompt view_objects
create or replace view view_objects (objecttype, name)
as
   select t_objecttype, t_name
     from dobjects_dbt;

prompt view_categories
create or replace view view_categories
(objecttype, objtypename, groupid, groupname, name, attrid, attrname, attrfullname)
as
select   objgroup.t_objecttype,
            case objgroup.t_objecttype
               when 3 then 'субъект'
               when 4 then 'счет'
               when 501 then 'платеж'
            end,
            objgroup.t_groupid,
            objgroup.t_name,
            objattr.t_nameobject,
            objattr.t_attrid,
            objattr.t_name,
            objattr.t_fullname
     from   dobjgroup_dbt objgroup, dobjattr_dbt objattr
    where       objgroup.t_objecttype = objattr.t_objecttype
            and objgroup.t_groupid = objattr.t_groupid
            and objgroup.t_objecttype in (3, 4, 501);

prompt view_usr_payment
create or replace view view_usr_payment
(pack_id, payment_id, status, error, carry_num, carry_error)
as
select   pack_id,
            up.paymentid,
            nvl ( (select   st.t_name
                     from   dpmstatus_dbt st
                    where   pm.t_paymstatus = st.t_paymstatus and st.t_type = 0), 'Платеж не найден')
               stat,
            up.error_text, ud.carrynum, ud.error_text
     from   usr_payments_log up, dpmpaym_dbt pm, usr_pmdocs ud
    where   pm.t_paymentid(+) = up.paymentid and ud.paymentid(+) = up.paymentid;

prompt view_usr_accountrest
create or replace view view_usr_accountrest as
-- KS 28.11.2013 Перенос пользовательских доработок в 31ю сборку
create or replace view view_usr_accountrest as
select   acc.t_client as partyid,
            acc.t_account as account,
            abs (rsb_account.resta (acc.t_account,
                                    dates.dt,
                                    acc.t_chapter,
                                    0/*acc.t_r0*/))
               rest,
            t_nameaccount as descr,
            dates.dt as daterest
     from   daccount_dbt acc, (    select   trunc (sysdate - level) dt
                                     from   dual
                               connect by   level <= 365) dates
    /*where   acc.t_type_account not like '%П%'
   union all
   select   acc.t_client as partyid,
            acc.t_account as account,
            abs (rsb_account.restac (acc.t_account,
                                     acc.t_code_currency,
                                     dates.dt,
                                     acc.t_chapter,
                                     acc.t_r0))
               rest,
            t_nameaccount as descr,
            dates.dt as daterest
     from   daccount$_dbt acc, (    select   trunc (sysdate - level) dt
                                      from   dual
                                connect by   level <= 365) dates*/
;