prompt usr_payments_log

drop table usr_payments_log;

create table USR_PAYMENTS_LOG
(
  PACK_ID     NUMBER(10),
  DOCKIND     NUMBER(5),
  PAYMENTID   NUMBER(10),
  NDOC        VARCHAR2(25),
  PAYERACC    VARCHAR2(35),
  RECEIVERACC VARCHAR2(35),
  AMOUNT      NUMBER(32,12),
  GROUND      VARCHAR2(600),
  OPER        NUMBER(5),
  DATE_DOC    DATE,
  ERROR_TEXT  VARCHAR2(4000),
  CREATE_TIME DATE default sysdate,
  LOG_DATA    VARCHAR2(4000 CHAR)
)
tablespace USERS;

comment on column USR_PAYMENTS_LOG.LOG_DATA;

create index USR_PAYMENTS_LOG_IDX0 on USR_PAYMENTS_LOG (PACK_ID)
  tablespace INDX;

create unique index USR_PAYMENTS_LOG_IDX1 on USR_PAYMENTS_LOG (NDOC, PAYERACC, RECEIVERACC, AMOUNT, GROUND, DATE_DOC, LOG_DATA)
  tablespace INDX;

create index USR_PAYMENTS_LOG_IDX2 on USR_PAYMENTS_LOG (PAYMENTID)
  tablespace INDX;

drop sequence usr_payment_packs_seq;


create sequence usr_payment_packs_seq
   increment by 1
   start with 1
   nomaxvalue
   nocycle;

Prompt usr_pmdocs


drop table usr_pmdocs;

create table USR_PMDOCS
(
  ACCTRNID         NUMBER(10),
  PAYMENTID        NUMBER(10),
  OPERATIONID      NUMBER(10),
  CARRYNUM         NUMBER(5),
  FIID_PAYER       NUMBER(5),
  FIID_RECEIVER    NUMBER(5),
  CHAPTER          NUMBER(5),
  PAYER_ACCOUNT    VARCHAR2(25),
  RECEIVER_ACCOUNT VARCHAR2(25),
  SUM              NUMBER,
  SUM_PAYER        NUMBER,
  SUM_RECEIVER     NUMBER,
  DATE_CARRY       DATE,
  OPER             NUMBER(5),
  PACK             NUMBER(5),
  NUM_DOC          VARCHAR2(15),
  GROUND           VARCHAR2(600),
  DEPARTMENT       NUMBER(5),
  VSP              NUMBER(5),
  KIND_OPER        VARCHAR2(2),
  SHIFR_OPER       VARCHAR2(6),
  ERROR_TEXT       VARCHAR2(4000),
  CREATE_TIME      DATE
)
tablespace USERS;

create unique index usr_pmdocs_idx0
   on usr_pmdocs (paymentid, carrynum) tablespace INDX;

create index usr_pmdocs_idx1
   on usr_pmdocs (ACCTRNID) tablespace INDX;

prompt usr_operations_log

drop table usr_operations_log;

create table usr_operations_log
(
   pack_id      number (10),
   paymentid    number (10),
   dockind      number (5),
   message      varchar2 (4000),
   error_text   varchar2 (4000)
);


create unique index usr_operations_log_idx0
   on usr_operations_log (paymentid, pack_id);

drop sequence usr_operation_packs_seq;

create sequence usr_operation_packs_seq
   increment by 1
   start with 1
   nomaxvalue
   nocycle;

--prompt usr_rscode_range

--drop table usr_rscode_range;

--create table USR_RSCODE_RANGE
--(
--  RANGE_ID             NUMBER(3),
--  IS_ARTIFICIAL_PERSON CHAR(1) default 'N',
--  IS_FOREIGN_PERSON    CHAR(1) default 'N',
--  IS_BANK              CHAR(1) default 'N',
--  LOW_LIMIT            NUMBER(7),
--  HIGH_LIMIT           NUMBER(7),
--  LAST_CODE            NUMBER(7),
--  DESCRIPTION          VARCHAR2(48)
--);

--Insert into USR_RSCODE_RANGE
-- Values
--   (1, 'N', 'N', 'N', 40000, 49999, null, 'физлицо резидент');
--Insert into USR_RSCODE_RANGE
-- Values
--   (2, 'Y', 'N', 'N', 30000, 89999, null, 'юрлицо резидент');
--Insert into USR_RSCODE_RANGE
-- Values
--   (3, 'N', 'Y', 'N', 50000, 59999, null, 'физлицо нерезидент');
--Insert into USR_RSCODE_RANGE
-- Values
--   (4, 'N', 'N', 'Y', 70000, 79999, null, 'банк');
--Insert into USR_RSCODE_RANGE
-- Values
--   (5, 'Y', 'Y', 'N', 30000, 39999, null, 'юрлицо нерезидент');
--COMMIT;*/

--prompt usr_route_parm

--drop table usr_route_parm;

/*create table usr_route_parm
(
   rule_id                  number (2),
   bo_id                    number (2),
   state                    number (1),
   deb_accmask              varchar2 (4000),
   kred_accmask             varchar2 (4000),
   deb_accmask_skip         varchar2 (1024),
   kred_accmask_skip        varchar2 (1024),
   dockind_case             varchar2 (48),
   origin_case              varchar2 (128),
   cur_mask                 varchar2 (48),
   deb_sys_acctype_case     varchar2 (48),
   kred_sys_acctype_case    varchar2 (48),
   deb_user_acctype_case    varchar2 (48),
   kred_user_acctype_case   varchar2 (48),
   connstring               varchar2 (256),
   extprocname              varchar2 (48),
   execcarry_type           number (1),
   note                     varchar2 (512)
);*/


prompt usr_trnsf_notify

drop table usr_trnsf_notify;

create table usr_trnsf_notify 
(
   notify_num number (10), 
   notify_date date, 
   payment_id number (10)
);

alter table usr_trnsf_notify add (
  primary key
€€notify_num))
  using index 
  tablespace INDX;

prompt usr_trnsf_order

drop table usr_trnsf_order;

create table usr_trnsf_order
(
   order_num        number (10),
   notify_num       number (10),
   date_value       date,
   sell_sum         number (32, 12),
   sell_rate        number (32, 12),
   sell_scale       number (10),
   sell_account     varchar2 (25 byte),
   sell_bik         varchar2 (9 byte),
   sell_docid       number (10),
   transf_sum       number (32, 12),
   transf_account   varchar2 (25 byte),
   transf_docid     number (10),
   origin           number (1),
   sys_date         date default trunc (sysdate) ,
   sys_time         date
);

--create unique index usr_trnsf_order_pk
--   on usr_trnsf_order (notify_num, order_num)
--   logging
--   noparallel;

alter table USR_TRNSF_ORDER
  add constraint USR_TRNSF_ORDER_PK primary key (NOTIFY_NUM, ORDER_NUM, DATE_VALUE)
  using index 
  tablespace INDX;

drop table USR_DEBUG_DUMP;

create table USR_DEBUG_DUMP
(
  PAYMENTID NUMBER(10),
  DUMP_TEXT clob
)
tablespace USERS;

create unique index USR_DEBUG_DUMP_IDX1 on USR_DEBUG_DUMP (paymentid)
  tablespace INDX;

prompt usr_curdate

drop table usr_curdate;

create table usr_curdate as
select max(t.t_curdate) t_curdate
  from dcurdate_dbt t
 where t.t_minphase = 1 and t.t_isclosed!=chr(88);

prompt USR_FIXDOC_DBT

drop table USR_FIXDOC_DBT;

create table USR_FIXDOC_DBT
(
  T_SID             NUMBER,
  T_STARTTIME       DATE,
  T_LASTTIME        DATE,
  T_LOGFILE         VARCHAR2(50),
  T_ERRMSG          VARCHAR2(250),
  T_ALLDOC          NUMBER,
  T_DAYDOC          NUMBER,
  T_ALLDOCAVERTIME  NUMBER,
  T_DAYDOCAVERTIME  NUMBER,
  T_ROBOT           VARCHAR2(20),
  T_SENDER_PIPENAME VARCHAR2(50),
  T_AUDSID          NUMBER,
  T_SERIAL          NUMBER
);

prompt USR_ARGUMENTS_LOG

drop table USR_ARGUMENTS_LOG;

create table USR_ARGUMENTS_LOG
(
  T_ID           NUMBER,
  T_DATE         DATE,
  T_NAME_OBJECT  VARCHAR2(100),
  T_XMLARGUMENTS XMLTYPE,
  T_TECHFIELD    VARCHAR2(100)
)
tablespace USERS;

create unique index USR_ARGUMENTS_LOG_IDX0 on USR_ARGUMENTS_LOG (T_ID)
  tablespace INDX;

create index USR_ARGUMENTS_LOG_IDX2 on USR_ARGUMENTS_LOG (T_DATE, T_NAME_OBJECT)
  tablespace INDX;

prompt USR_FINANC_SOURCE_DBT

drop table USR_FINANC_SOURCE_DBT;

create table USR_FINANC_SOURCE_DBT
(
  T_PAYMENTID NUMBER(10),
  T_SOURCE    NUMBER(1),
  T_OPER      NUMBER(6),
  T_DATE      DATE,
  T_SYSTIME   DATE default SYSDATE
)
tablespace USERS;

create unique index USR_FINANC_SOURCE_CTR0 on USR_FINANC_SOURCE_DBT (T_PAYMENTID, T_SYSTIME)
  tablespace INDX;

create index USR_FINANC_SOURCE_IDX1 on USR_FINANC_SOURCE_DBT (T_PAYMENTID)
  tablespace INDX;

prompt USR_IPPTFROMSOGL_LOG

create table USR_IPPTFROMSOGL_LOG
(
  T_PAYMENTID NUMBER(10) not null,
  T_VALUEDATE DATE
)
tablespace USERS;

-- Create/Recreate indexes 
create index USR_IPPTFROMSOGL_LOG_IDX0 on USR_IPPTFROMSOGL_LOG (T_PAYMENTID)
  tablespace INDX;
