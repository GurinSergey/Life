/*
„«п 6.20.30 ЌҐ®Ўе®¤Ё¬® ўлЇ®«­Ёвм б®§¤ ­ЁҐ б«Ґ¤гойЁе ®ЎкҐЄв®ў:
create or replace view daccount30_dbt as select * from daccount_dbt;
create or replace view daccount$30_dbt as select * from daccount$_dbt;
create or replace view drestdate30_dbt as select * from drestdate_dbt;
create or replace view drestdat$30_dbt as select * from drestdat$_dbt;
create or replace view darhdoc30_dbt as select * from darhdoc_dbt;
create or replace view darhdoc$30_dbt as select * from darhdoc$_dbt;
create or replace view dpmdocs30_dbt as select * from dpmdocs_dbt;
create global temporary table DDINFDOC1_TMP ON COMMIT PRESERVE ROWS as select * from darhdoc30_dbt where 1=0;
create or replace view dcurdate30_dbt as select * from dcurdate_dbt;
*/



create or replace view daccount30_dbt
as
select t_open_close,
       t_code_currency,
       t_account,
       t_client,
       t_oper,
       t_balance,
       t_sort,
       t_index2,
       t_index3,
       t_kind_account,
       t_type_account,
       t_etype_account,
       t_usertypeaccount,
       t_final_date,
       t_datenochange,
       chr(1) t_connect_account,
       t_symbol,
       rsi_rsb_account.GetAccLimit(t_account,t_chapter,t_code_currency,t_curdate) t_limit,
       t_open_date,
       t_close_date,
       rsb_account.debeta(t_account,t_chapter,t_curdate,t_curdate) t_d0,
       rsb_account.kredita(t_account,t_chapter,t_curdate,t_curdate) t_k0,
       rsb_account.resta(t_account,t_curdate,t_chapter,0) t_r0,
       rsi_rsb_account.planresta(t_account,t_curdate,t_chapter,0) t_planrest,
       t_nameaccount,
       t_change_date,
       t_change_dateprev,
       t_pairaccount,
       t_userfield1,
       t_userfield2,
       t_userfield3,
       t_userfield4,
       t_operationdate,
       t_daystoend,
       t_chapter,
       t_department,
       t_orscheme,
       t_contractrko,
       0 t_connect_chapter,
       0 t_connect_currency,
       t_officeid,
       t_depoacc,
       t_deporoot,
       t_havesubaccounts,
       t_branch,
       t_controloper,
       t_currencyeq,
       t_currencyeq_ratedate,
       0 t_resteqv,
       0 t_planresteqv,
       t_currencyeq_ratetype,
       t_currencyeq_rateextra,
       t_accountid,
       t_opucode
  from daccount_dbt, (select max(c.t_curdate) t_curdate from dcurdate_dbt c)
 where t_code_currency = 0
 union all
select t_open_close,
       0 t_code_currency,
       t_account,
       t_client,
       t_oper,
       t_balance,
       t_sort,
       t_index2,
       t_index3,
       t_kind_account,
       'П'|| t_type_account t_type_account,
       t_etype_account,
       t_usertypeaccount,
       t_final_date,
       t_datenochange,
       t_account t_connect_account,
       t_symbol,
       0 t_limit,
       t_open_date,
       t_close_date,
       rsb_account.debetac(t_account,t_chapter,t_code_currency,t_curdate,t_curdate,0) t_d0,
       rsb_account.kreditac(t_account,t_chapter,t_code_currency,t_curdate,t_curdate,0) t_k0,
       rsb_account.restac(t_account,t_code_currency,t_curdate,t_chapter,0,0) t_r0,
       rsi_rsb_account.planrestac(t_account,t_code_currency,t_curdate,t_chapter,0) t_planrest,
       t_nameaccount,
       t_change_date,
       t_change_dateprev,
       t_pairaccount,
       t_userfield1,
       t_userfield2,
       t_userfield3,
       t_userfield4,
       t_operationdate,
       t_daystoend,
       t_chapter,
       t_department,
       t_orscheme,
       t_contractrko,
       t_chapter t_connect_chapter,
       0 t_connect_currency,
       t_officeid,
       t_depoacc,
       t_deporoot,
       t_havesubaccounts,
       t_branch,
       t_controloper,
       t_currencyeq,
       t_currencyeq_ratedate,
       0 t_resteqv,
       0 t_planresteqv,
       t_currencyeq_ratetype,
       t_currencyeq_rateextra,
       t_accountid,
       t_opucode
  from daccount_dbt, (select max(c.t_curdate) t_curdate from dcurdate_dbt c)
 where t_code_currency != 0;
create or replace view daccount$30_dbt
as
select t_open_close,
       t_code_currency,
       t_account,
       t_client,
       t_oper,
       t_balance,
       t_sort,
       t_index2,
       t_index3,
       t_kind_account,
       t_type_account,
       t_etype_account,
       t_usertypeaccount,
       t_final_date,
       t_datenochange,
       t_account t_connect_account,
       t_symbol,
       rsi_rsb_account.GetAccLimit(t_account,t_chapter,t_code_currency,t_curdate) t_limit,
       t_open_date,
       t_close_date,
       rsb_account.debetac(t_account,t_chapter,t_code_currency,t_curdate,t_curdate) t_d0,
       rsb_account.kreditac(t_account,t_chapter,t_code_currency,t_curdate,t_curdate) t_k0,
       rsb_account.restac(t_account,t_code_currency,t_curdate,t_chapter,0) t_r0,
       rsi_rsb_account.planrestac(t_account,t_code_currency,t_curdate,t_chapter) t_planrest,
       t_nameaccount,
       t_change_date,
       t_change_dateprev,
       t_pairaccount,
       t_userfield1,
       t_userfield2,
       t_userfield3,
       t_userfield4,
       t_operationdate,
       t_daystoend,
       t_chapter,
       t_department,
       t_orscheme,
       t_contractrko,
       t_chapter t_connect_chapter,
       0 t_connect_currency,
       t_officeid,
       t_depoacc,
       t_deporoot,
       t_havesubaccounts,
       t_branch,
       t_controloper,
       t_currencyeq,
       t_currencyeq_ratedate,
       0 t_resteqv,
       0 t_planresteqv,
       t_currencyeq_ratetype,
       t_currencyeq_rateextra,
       t_accountid,
       t_opucode
  from daccount_dbt, (select max(c.t_curdate) t_curdate from dcurdate_dbt c)
 where t_code_currency != 0;
CREATE OR REPLACE VIEW DACCOUNTS_VIEW AS
SELECT
    ACC.T_OPEN_CLOSE,
    ACC.T_CODE_CURRENCY,
    ACC.T_ACCOUNT,
    ACC.T_CLIENT,
    ACC.T_OPER,
    ACC.T_BALANCE,
    ACC.T_SORT,
    ACC.T_INDEX2,
    ACC.T_INDEX3,
    ACC.T_KIND_ACCOUNT,
    ACC.T_TYPE_ACCOUNT,
    ACC.T_ETYPE_ACCOUNT,
    ACC.T_USERTYPEACCOUNT,
    ACC.T_FINAL_DATE,
    ACC.T_DATENOCHANGE,
    ACC.T_CONNECT_ACCOUNT,
    ACC.T_SYMBOL,
    ACC.T_LIMIT,
    ACC.T_OPEN_DATE,
    ACC.T_CLOSE_DATE,
    ACC.T_D0,
    ACC.T_K0,
    ACC.T_R0,
    ACC.T_PLANREST,
    ACC.T_NAMEACCOUNT,
    ACC.T_CHANGE_DATE,
    ACC.T_CHANGE_DATEPREV,
    ACC.T_PAIRACCOUNT,
    ACC.T_USERFIELD1,
    ACC.T_USERFIELD2,
    ACC.T_USERFIELD3,
    ACC.T_USERFIELD4,
    ACC.T_OPERATIONDATE,
    ACC.T_DAYSTOEND,
    ACC.T_CHAPTER,
    ACC.T_DEPARTMENT,
    ACC.T_ORSCHEME,
    ACC.T_CONTRACTRKO,
    ACC.T_CONNECT_CHAPTER,
    ACC.T_CONNECT_CURRENCY,
    ACC.T_OFFICEID,
    ACC.T_DEPOACC,
    ACC.T_DEPOROOT,
    ACC.T_HAVESUBACCOUNTS,
    ACC.T_BRANCH,
    ACC.T_CONTROLOPER,
    ACC.T_CURRENCYEQ,
    ACC.T_CURRENCYEQ_RATEDATE,
    ACC.T_RESTEQV,
    ACC.T_PLANRESTEQV,
    ACC.T_CURRENCYEQ_RATETYPE,
    ACC.T_CURRENCYEQ_RATEEXTRA,
    ACC.T_ACCOUNTID,
    ACC.T_OPUCODE
  FROM DACCOUNT30_DBT ACC
   UNION ALL
  SELECT
    ACC$.T_OPEN_CLOSE,
    ACC$.T_CODE_CURRENCY,
    ACC$.T_ACCOUNT,
    ACC$.T_CLIENT,
    ACC$.T_OPER,
    ACC$.T_BALANCE,
    ACC$.T_SORT,
    ACC$.T_INDEX2,
    ACC$.T_INDEX3,
    ACC$.T_KIND_ACCOUNT,
    ACC$.T_TYPE_ACCOUNT,
    ACC$.T_ETYPE_ACCOUNT,
    ACC$.T_USERTYPEACCOUNT,
    ACC$.T_FINAL_DATE,
    ACC$.T_DATENOCHANGE,
    ACC$.T_CONNECT_ACCOUNT,
    ACC$.T_SYMBOL,
    ACC$.T_LIMIT,
    ACC$.T_OPEN_DATE,
    ACC$.T_CLOSE_DATE,
    ACC$.T_D0,
    ACC$.T_K0,
    ACC$.T_R0,
    ACC$.T_PLANREST,
    ACC$.T_NAMEACCOUNT,
    ACC$.T_CHANGE_DATE,
    ACC$.T_CHANGE_DATEPREV,
    ACC$.T_PAIRACCOUNT,
    ACC$.T_USERFIELD1,
    ACC$.T_USERFIELD2,
    ACC$.T_USERFIELD3,
    ACC$.T_USERFIELD4,
    ACC$.T_OPERATIONDATE,
    ACC$.T_DAYSTOEND,
    ACC$.T_CHAPTER,
    ACC$.T_DEPARTMENT,
    ACC$.T_ORSCHEME,
    ACC$.T_CONTRACTRKO,
    ACC$.T_CONNECT_CHAPTER,
    ACC$.T_CONNECT_CURRENCY,
    ACC$.T_OFFICEID,
    ACC$.T_DEPOACC,
    ACC$.T_DEPOROOT,
    ACC$.T_HAVESUBACCOUNTS,
    ACC$.T_BRANCH,
    ACC$.T_CONTROLOPER,
    ACC$.T_CURRENCYEQ,
    ACC$.T_CURRENCYEQ_RATEDATE,
    ACC$.T_RESTEQV,
    ACC$.T_PLANRESTEQV,
    ACC$.T_CURRENCYEQ_RATETYPE,
    ACC$.T_CURRENCYEQ_RATEEXTRA,
    ACC$.T_ACCOUNTID,
    ACC$.T_OPUCODE
  FROM DACCOUNT$30_DBT ACC$;

create or replace view drestdate30_dbt as
select a.t_account,
       0 t_code_currency,
       r.t_restdate t_date_value,
       t_rest,
       a.t_chapter,
       t_planrest,
       t_debet,
       t_credit,
       t_debetspod,
       t_creditspod
  from drestdate_dbt r, daccount_dbt a
 where r.t_accountid = a.t_accountid
   and (a.t_code_currency = 0 or r.t_restcurrency = 0);

create or replace view drestdat$30_dbt as
select a.t_account,
       a.t_code_currency,
       r.t_restdate t_date_value,
       t_rest,
       a.t_chapter,
       t_planrest,
       t_debet,
       t_credit,
       t_debetspod,
       t_creditspod
  from drestdate_dbt r, daccount_dbt a
 where r.t_accountid = a.t_accountid
   and a.t_code_currency != 0
   and r.t_restcurrency != 0;

create or replace view darhdoc30_dbt as
select t_acctrnid t_autokey,
       t_chapter,
       0 t_code_currency,
       t_account_payer,
       t_account_receiver,
       t_sum_natcur t_sum,
       t_date_carry,
       -- KS Чтобы не усложнять RSB_DINFCACH1 передам в t_iapplicationkind ноль
       --case
       --  when a.t_fiid_payer = 0 and a.t_fiid_receiver = 0 then 3
       --  else 2
       --end t_iapplicationkind, -- KS приблизительная эмуляция полей
       0 t_iapplicationkind, -- KS приблизительная эмуляция полей
       -- KS Чтобы не усложнять RSB_DINFCACH1 добью t_acctrnid нулями
       --to_char(decode(a.t_systemdate,to_date('00010101','YYYYMMDD'),a.t_date_carry,a.t_systemdate),'YYYYMMDD')||
       --to_char(a.t_systemtime,'HH24MISS')||
       --lpad(t_acctrnid,10,'0') t_applicationkey, -- KS приблизительная эмуляция полей
       lpad(t_acctrnid,24,'0') t_applicationkey, -- KS приблизительная эмуляция полей. 0 в начале для отличия проводок покрытия от валютных проводок
       t_result_carry,
       t_number_pack,
       t_oper,
       t_department,
       t_kind_oper,
       t_shifr_oper,
       -- KS Чтобы не усложнять RSB_DINFCACH1 передам в t_iapplicationkind ноль
       --case
       --  when a.t_fiid_payer = 0 and a.t_fiid_receiver = 0 then 3
       --  else 2
       --end t_connappkind,
       1 t_connappkind,
       lpad(t_acctrnid,24,'0') t_connappkey, -- KS приблизительная эмуляция полей. 0 в начале для отличия проводок покрытия от валютных проводок
       t_numb_document,
       t_ground,
       t_typedocument,
       t_usertypedocument,
       t_userfield1,
       t_userfield2,
       t_userfield3,
       t_userfield4,
       case
         when t_fiid_payer = 0 and t_fiid_receiver = 0 then 1
         else 0
       end t_carryacnt,
       0 t_creditstatus,
       t_nu_status,
       t_nu_kind,
       t_nu_startdate,
       t_nu_enddate,
       t_nu_ackdate,
       0 t_fu_iapplicationkind,
       chr(1) t_fu_applicationkey,
       t_priority,
       t_minphase,
       t_maxphase,
       case
         when t_fiid_payer = 0 and t_fiid_receiver = 0 then 1
         else 0
       end t_state,
       t_systemdate,
       t_systemtime,
       t_checksum,
       chr(0) t_isresteqchange,
       cast(0 as NUMBER(32,12)) t_sumeq_payer,
       cast(0 as NUMBER(32,12)) t_sumeq_receiver,
       -1 t_cureq_payer,
       -1 t_cureq_receiver,
       t_claimid,
       t_branch,
       cast(0 as NUMBER(32,12)) t_sumequivalentcarry,
       0 t_parentappkind,
       chr(1) t_parentappkey
  from dacctrn_dbt a;

create or replace view darhdoc$30_dbt as
select t_acctrnid t_autokey,
       t_chapter,
       a.t_fiid_payer t_code_currency,
       t_account_payer,
       t_account_receiver,
       t_sum_payer t_sum,
       t_date_carry,
       -- KS Чтобы не усложнять RSB_DINFCACH1 передам в t_iapplicationkind ноль
       --2 t_iapplicationkind, -- KS приблизительная эмуляция полей
       1 t_iapplicationkind, -- KS приблизительная эмуляция полей
       -- KS Чтобы не усложнять RSB_DINFCACH1 добью t_acctrnid нулями
       --to_char(decode(a.t_systemdate,to_date('00010101','YYYYMMDD'),a.t_date_carry,a.t_systemdate),'YYYYMMDD')||
       --to_char(a.t_systemtime,'HH24MISS')||
       --lpad(t_acctrnid,10,'0') t_applicationkey, -- KS приблизительная эмуляция полей
       lpad(t_acctrnid,24,'0') t_applicationkey, -- KS приблизительная эмуляция полей. 1 в начале для отличия проводок покрытия от валютных проводок
       t_result_carry,
       t_number_pack,
       t_oper,
       t_department,
       t_kind_oper,
       t_shifr_oper,
       0 t_connappkind,
       chr(1) t_connappkey,
       t_numb_document,
       t_ground,
       t_typedocument,
       t_usertypedocument,
       t_userfield1,
       t_userfield2,
       t_userfield3,
       t_userfield4,
       case
         when t_fiid_payer = 0 and t_fiid_receiver = 0 then 1
         else 0
       end t_carryacnt,
       0 t_creditstatus,
       t_nu_status,
       t_nu_kind,
       t_nu_startdate,
       t_nu_enddate,
       t_nu_ackdate,
       0 t_fu_iapplicationkind,
       chr(1) t_fu_applicationkey,
       t_priority,
       t_minphase,
       t_maxphase,
       case
         when a.t_fiid_payer = 0 and a.t_fiid_receiver = 0 then 1
         else 0
       end t_state,
       t_systemdate,
       t_systemtime,
       t_checksum,
       chr(0) t_isresteqchange,
       cast(0 as NUMBER(32,12)) t_sumeq_payer,
       cast(0 as NUMBER(32,12)) t_sumeq_receiver,
       -1 t_cureq_payer,
       -1 t_cureq_receiver,
       t_claimid,
       t_branch,
       cast(0 as NUMBER(32,12)) t_sumequivalentcarry,
       0 t_parentappkind,
       chr(1) t_parentappkey
  from dacctrn_dbt a
 where a.t_fiid_payer != 0 and a.t_fiid_receiver != 0
   and a.t_fiid_payer = a.t_fiid_receiver;

/*
create or replace view dmultycar30_dbt as
select a.t_acctrnid t_carryid,
       -1 t_methodid,       
       -- KS Чтобы не усложнять RSB_DINFCACH1 передам в t_iapplicationkind ноль
       --15 t_iapplicationkind,
       1 t_iapplicationkind,
       lpad(t_acctrnid,24,'0') t_applicationkey,
       a.t_fiid_payer t_fiid_from,
       a.t_fiid_receiver t_fiid_to,
       a.t_sum_payer t_amount_from,
       a.t_sum_receiver t_amount_to,
       t_chapter,
       a.t_accountid_payer t_account_from,
       a.t_accountid_receiver t_account_to,
       chr(1) t_accocp_from,
       chr(1) t_accocp_to,
       chr(1) t_account1,
       chr(1) t_account2,
       chr(1) t_account3,
       chr(1) t_account4,
       chr(1) t_comment,
       666 t_paymentidr,
       666 t_paymentidc,
       a.t_date_carry t_date,
       a.t_date_carry t_date_document,
       t_numb_document,
       t_number_pack,
       t_ground,
       t_department,
       1 t_paymenttpr,
       1 t_paymenttpc,
       a.t_shifr_oper t_shifroper,
       t_oper,
       t_kind_oper,
       0 t_forcemove,
       a.t_typedocument t_type_document,
       t_date_rate,
       chr(0) t_isdeleted,
       t_userfield1,
       t_userfield2,
       t_userfield3,
       t_userfield4,
       chr(88) t_keeptechaccounts,
       chr(0) t_isresteqchange,
       cast(0 as NUMBER(32,12)) t_sumeq_payer,
       cast(0 as NUMBER(32,12)) t_sumeq_receiver,
       -1 t_cureq_payer,
       -1 t_cureq_receiver,
       t_result_carry,
       cast(0 as NUMBER(32,12)) t_sumequivalentcarry,
       cast(0 as NUMBER(32,12)) t_connsum,
       t_claimid,
       t_rate,
       t_scale,
       t_point,
       t_isinverse
  from dacctrn_dbt a
 where a.t_fiid_payer != 0 and a.t_fiid_receiver != 0
   and a.t_fiid_payer != a.t_fiid_receiver;
   
*/

create index dacctrn_dbt_usr1 on dacctrn_dbt(lpad(t_acctrnid,24,'0'));
--create index dacctrn_dbt_usr0 on dacctrn_dbt('0'||lpad(t_acctrnid,23,'0'));   
--create index dacctrn_dbt_usr1 on dacctrn_dbt('1'||lpad(t_acctrnid,23,'0'));
--drop index dacctrn_dbt_usr2;
--create index dacctrn_dbt_usr2 on dacctrn_dbt(t_chapter,
--                                             case
--                                               when t_fiid_payer = 0 and t_fiid_receiver = 0 then chr(1)
--                                               else '1'||lpad(t_acctrnid,23,'0')
--                                             end);
--create index dacctrn_dbt_usr2 on dacctrn_dbt('2'||lpad(t_acctrnid,23,'0'));
--drop index dacctrn_dbt_usr2;
drop table DDINFDOC1_TMP;
CREATE GLOBAL TEMPORARY TABLE DDINFDOC1_TMP
ON COMMIT PRESERVE ROWS
AS
SELECT *
  FROM darhdoc30_dbt
 WHERE 1=0;
alter table DDINFCACH1_TMP modify T_INSTANCEID NUMBER(20);

create or replace view dpmdocs30_dbt as
select 1 t_linkkindid,
       t_paymentid,
       0 t_applicationkind,
       lpad(t_acctrnid,24,'0') t_applicationkey,
       (select a.t_sum_natcur from dacctrn_dbt a where p.t_acctrnid = a.t_acctrnid) t_amount,
       t_autokey,
       t_keeptechfields,
       t_pmaddpiid,
       t_reason
-- Для рублёвых проводок
  from dpmdocs_dbt p
union all
select 1 t_linkkindid,
       t_paymentid,
       1 t_applicationkind,
       lpad(t_acctrnid,24,'0') t_applicationkey,
       (select a.t_sum_natcur from dacctrn_dbt a where p.t_acctrnid = a.t_acctrnid) t_amount,
       t_autokey,
       t_keeptechfields,
       t_pmaddpiid,
       t_reason
-- Для нерублёвых проводок
  from dpmdocs_dbt p
 where p.t_acctrnid in (select a.t_acctrnid from dacctrn_dbt a
   where a.t_fiid_payer != 0 and a.t_fiid_receiver != 0);

--create index dpmdocs_dbt_usr0 on dpmdocs_dbt('0'||lpad(t_acctrnid,23,'0'));   
--create index dpmdocs_dbt_usr1 on dpmdocs_dbt('1'||lpad(t_acctrnid,23,'0'));
--create index dpmdocs_dbt_usr2 on dpmdocs_dbt('2'||lpad(t_acctrnid,23,'0'));
--drop index dpmdocs_dbt_usr2 ;
create index dpmdocs_dbt_usr1 on dpmdocs_dbt(lpad(t_acctrnid,24,'0'));

drop view dcurdate30_dbt;
create view dcurdate30_dbt as
select t_curdate,
       t_point,
       t_branch,
       t_minphase,
       t_maxphase,
       t_isclosed,
       chr(0) t_isspecmode
  from dcurdate_dbt d
 where d.t_curdate <= (select max(t_curdate)
                         from dcurdate_dbt cd
                        where cd.t_branch = d.t_branch
                          and cd.t_ismain = chr(88));

-- Create table
create global temporary table DDINFCACH1_TMP
(
  T_AUTOKEY            NUMBER(10) not null,
  T_APPLICATIONKIND    NUMBER(5),
  T_APPLICATIONKEY     VARCHAR2(29),
  T_CODE_CURRENCY      NUMBER(10) not null,
  T_INSTANCEID         NUMBER(20) not null,
  T_PAYERACCOUNT       VARCHAR2(35),
  T_PAYERNAME          VARCHAR2(320),
  T_PAYERINN           VARCHAR2(15),
  T_PAYERINN_KPP       VARCHAR2(35),
  T_PAYERBANKNAME      VARCHAR2(320),
  T_PAYERCORRACC       VARCHAR2(25),
  T_PAYERBANKCODE      VARCHAR2(35),
  T_PAYERCODEKIND      NUMBER(5),
  T_PAYERFIID          NUMBER(10),
  T_PAYERAMOUNT        NUMBER(32,12),
  T_PAYERBIC           VARCHAR2(35),
  T_PAYERSWIFT         VARCHAR2(35),
  T_RECEIVERACCOUNT    VARCHAR2(35),
  T_RECEIVERNAME       VARCHAR2(320),
  T_RECEIVERINN        VARCHAR2(15),
  T_RECEIVERINN_KPP    VARCHAR2(35),
  T_RECEIVERBANKNAME   VARCHAR2(320),
  T_RECEIVERCORRACC    VARCHAR2(25),
  T_RECEIVERBANKCODE   VARCHAR2(35),
  T_RECEIVERCODEKIND   NUMBER(5),
  T_RECEIVERFIID       NUMBER(10),
  T_RECEIVERAMOUNT     NUMBER(32,12),
  T_RECEIVERBIC        VARCHAR2(35),
  T_RECEIVERSWIFT      VARCHAR2(35),
  T_PAYMENTID          NUMBER(10),
  T_CARRYID            NUMBER(10),
  T_FIID               NUMBER(10),
  T_AMOUNT             NUMBER(32,12),
  T_DATE               DATE,
  T_PAYDATE            DATE,
  T_DATE_CARRY         DATE,
  T_PRIORITY           NUMBER(5),
  T_NUMBER_PACK        NUMBER(5),
  T_NUMB_DOCUMENT      VARCHAR2(25),
  T_SHIFR_OPER         VARCHAR2(6),
  T_GROUND             VARCHAR2(600),
  T_CORRBANKNAME       VARCHAR2(320),
  T_CORRBANKACC        VARCHAR2(35),
  T_PAYERCHARGEOFFDATE DATE,
  T_TAXAUTHORSTATE     VARCHAR2(2),
  T_BTTTICODE          VARCHAR2(20),
  T_OKATOCODE          VARCHAR2(11),
  T_TAXPMGROUND        VARCHAR2(2),
  T_TAXPMPERIOD        VARCHAR2(10),
  T_TAXPMNUMBER        VARCHAR2(15),
  T_TAXPMDATE          VARCHAR2(10),
  T_TAXPMTYPE          VARCHAR2(2),
  T_PURPOSE            VARCHAR2(80),
  T_PAYMENTKIND        VARCHAR2(10),
  T_DEPARTMENT         NUMBER(5),
  T_TIME_CARRY         DATE,
  T_RECEIVERACCOUNT_A  VARCHAR2(35),
  T_PAYERACCOUNT_A     VARCHAR2(35),
  T_MT103              VARCHAR2(1500)
)
on commit preserve rows;
-- Create/Recreate indexes 
create unique index DDINFCACH1_TMP_IDX0 on DDINFCACH1_TMP (T_AUTOKEY, T_CODE_CURRENCY, T_INSTANCEID);
create unique index DDINFCACH1_TMP_IDX1 on DDINFCACH1_TMP (T_APPLICATIONKIND, T_APPLICATIONKEY, T_CODE_CURRENCY, T_INSTANCEID);