CREATE OR REPLACE PACKAGE USR_SOA_REPORT
is

   -- Остатки
   
   function GetAccountInfo ( pDateBegin in date,
                             pDateEnd   in date,
                             pAccount   in varchar2,
                             pSourceSystem in varchar2,
                             pChapter   in number default null)
     return sys_refcursor;

   -- Книга счетов
   function GetBookInfo ( pDate      in date,
                          pAccount   in varchar2 default '*',
                          pChapter   in number default null)
     return sys_refcursor;

   -- Проводки
   function GetArhdocInfo ( pDate      in date,
                            pAccount   in varchar2 default null,
                            pChapter   in number default null)
     return sys_refcursor;

   -- Проводки - Отчет по расчету резервов по сомнительным долгам (юр.лица)
   function GetRestInfoForDebts
     return sys_refcursor;

   -- Остатки - Отчет по расчету резервов по сомнительным долгам (юр.лица)
   function GetAccountInfoForDebts
     return sys_refcursor;

   -- Платежи выгруженные и загруженные из внешнихсистем через SOA
   function GetPayments( paym_type  in number,
                         origin     in number,
                         date_from  in date,
                         date_to    in date)
     return sys_refcursor;
end;
/
CREATE OR REPLACE PACKAGE BODY USR_SOA_REPORT
-- KS 14.09.2011
is

   function GetAccountInfo ( pDateBegin in date,
                             pDateEnd   in date,
                             pAccount   in varchar2,
                             pSourceSystem in varchar2,
                             pChapter   in number default null)
     return sys_refcursor
   is
     view_cur         sys_refcursor;
   begin

     if pSourceSystem = 'Rest' then
         open view_cur for
                 select
                    cast(a.t_account as varchar2(30)) as "AccountNumber",
                    cast(a.t_kind_account as varchar2(30)) as "kind_account",
                    cast(a.t_nameaccount as varchar2(255)) as "nameaccount",
                    cast((select max(t_ccy) from dfininstr_dbt f where f.t_fiid=a.t_code_currency) as varchar2(30)) as "Currency",
                    abs(case
                      when a.t_code_currency=0 then
                        cast(rsb_account.resta(a.t_account,pDateBegin-1,a.t_chapter,0/*a.t_r0*/) as number)
                      else
                        cast(rsb_account.restac(a.t_account,a.t_code_currency,pDateBegin-1,a.t_chapter,0/*a.t_r0*/) as number)
                    end) as "InBalance",
                    abs(case
                      when a.t_code_currency=0 then
                        cast(rsb_account.debeta(a.t_account,a.t_chapter,pDateBegin,pDateEnd) as number)
                      else
                        cast(rsb_account.debetac(a.t_account,a.t_chapter,a.t_code_currency,pDateBegin,pDateEnd) as number)
                    end) as "DebBalance",
                    abs(case
                      when a.t_code_currency=0 then
                        cast(rsb_account.kredita(a.t_account,a.t_chapter,pDateBegin,pDateEnd) as number)
                      else
                        cast(rsb_account.kreditac(a.t_account,a.t_chapter,a.t_code_currency,pDateBegin,pDateEnd) as number)
                    end) as  "CredBalance",
                    abs(case
                      when a.t_code_currency=0 then
                        cast(rsb_account.resta(a.t_account,pDateEnd,a.t_chapter,0/*a.t_r0*/) as number)
                      else
                        cast(rsb_account.restac(a.t_account,a.t_code_currency,pDateEnd,a.t_chapter,0/*a.t_r0*/) as number)
                    end) as "OutBalance"
                   -- KS 28.11.2013 Адаптация под 31ю сборку
                   --from daccounts_dbt a
                   from daccount_dbt a
                  where 1=1
                    --and rsb_mask.CompareStringWithMask(pAccount,)=1
                    and regexp_like (a.t_account, pAccount)
                    and (pChapter is null or pChapter=a.t_chapter);
      elsif pSourceSystem in ('Turn','CashDesk') then
          open view_cur for
                 select
                    cast(a.t_account as varchar2(30)) as "AccountNumber",
                    cast(a.t_kind_account as varchar2(30)) as "kind_account",
                    cast(a.t_nameaccount as varchar2(255)) as "nameaccount",
                    cast((select max(t_ccy) from dfininstr_dbt f where f.t_fiid=a.t_code_currency) as varchar2(30)) as "Currency",
                    abs(case
                      when a.t_code_currency=0 then
                        cast(rsb_account.resta(a.t_account,pDateBegin-1,a.t_chapter,0/*a.t_r0*/) as number)
                      else
                        cast(rsb_account.restac(a.t_account,a.t_code_currency,pDateBegin-1,a.t_chapter,0/*a.t_r0*/) as number)
                    end) as "InBalance",
                    abs(case
                      when a.t_code_currency=0 then
                        cast(rsb_account.debeta(a.t_account,a.t_chapter,pDateBegin,pDateEnd) as number)
                      else
                        cast(rsb_account.debetac(a.t_account,a.t_chapter,a.t_code_currency,pDateBegin,pDateEnd) as number)
                    end) as "DebBalance",
                    abs(case
                      when a.t_code_currency=0 then
                        cast(rsb_account.kredita(a.t_account,a.t_chapter,pDateBegin,pDateEnd) as number)
                      else
                        cast(rsb_account.kreditac(a.t_account,a.t_chapter,a.t_code_currency,pDateBegin,pDateEnd) as number)
                    end) as  "CredBalance",
                    abs(case
                      when a.t_code_currency=0 then
                        cast(rsb_account.resta(a.t_account,pDateEnd,a.t_chapter,0/*a.t_r0*/) as number)
                      else
                        cast(rsb_account.restac(a.t_account,a.t_code_currency,pDateEnd,a.t_chapter,0/*a.t_r0*/) as number)
                    end) as "OutBalance"
                   -- KS 28.11.2013 Адаптация под 31ю сборку
                   --from daccounts_dbt a
                   from daccount_dbt a
                  where 1=1
                    --and rsb_mask.CompareStringWithMask(pAccount,)=1
                    and a.t_account like pAccount||'%'
                    and (pChapter is null or pChapter=a.t_chapter);
      end if;

     return view_cur;

   end;

   function GetBookInfo ( pDate      in date,
                          pAccount   in varchar2 default '*',
                          pChapter   in number default null)
     return sys_refcursor
   is
     view_cur         sys_refcursor;

   begin

     -- запрос взят из BK_OPACC.MAC
     open view_cur for 
      WITH acc AS(
                    SELECT /*+ INDEX_JOIN(a)*/                  
                           a.t_Chapter                             t_Chapter,                  
                           a.t_Account                             t_Account,                  
                           a.t_balance                             t_balance,
                           a.t_Code_Currency                       t_Code_Currency,                  
                           a.t_Open_Date                           t_Open_Date,                  
                           a.t_Close_Date                          t_Close_Date,                  
                           a.t_Client                              t_Client,                  
                           a.t_Branch                              t_Branch,                  
                           a.t_type_account                        t_type_account,                  
                           a.t_NameAccount                         t_NameAccount,                  
                           TO_CHAR( a.t_chapter, 'FM0x')                  
                           || TO_CHAR( a.t_code_currency, 'FM0xxxxxx')                  
                           || a.t_account                  
                                                                   documentId,               
                           CASE                  
                               WHEN ((a.t_Balance BETWEEN '401' AND '407' OR a.t_Balance LIKE '407%') OR a.t_Balance LIKE '40802%' OR a.t_Balance LIKE '40807%')                  
                               THEN 1                  
                               ELSE 0                  
                           END isClientBalance
                      -- KS 28.11.2013 Адаптация под 31ю сборку
                      --from daccounts_dbt a,
                      from daccount_dbt a,
                           dbalance_dbt b
                     WHERE
                               (a.t_Open_Date = pDate OR a.t_close_Date  = pDate)
--                               a.t_Open_Date <= pDate
--                           AND (   a.t_Close_Date >= pDate        
--                                OR a.t_open_close = CHR(0))                  
                           AND INSTR (a.t_type_account, 'П') = 0                  
                           AND INSTR (a.t_type_account, 'L') = 0                  
                           AND INSTR (a.t_type_account, 'Y') = 0                  
                           AND                  
                               b.t_iNumPlan = 0                  
                           AND b.t_Chapter = 1                  
                           AND INSTR(b.t_type_balance, 'T') = 0                  
                           AND a.t_Chapter = b.t_Chapter                  
                           AND a.t_balance = b.t_balance                  
                   ),                  
           note AS(                  
                   SELECT acc.t_account,                  
                          acc.t_chapter,                  
                          nt.t_NoteKind,                  
                          CASE                  
                               WHEN nt.t_NoteKind != 9                  
                                   THEN rsb_kernel.ExtractText(nt.t_text)                  
                               ELSE NULL                  
                          END noteText,                  
                          CASE                  
                               WHEN nt.t_NoteKind = 9                  
                                   THEN rsb_kernel.ExtractDate(nt.t_text)                  
                               ELSE NULL                  
                          END noteDate                  
                     FROM dnotetext_dbt nt, acc                  
                    WHERE     nt.t_ObjectType = 4                  
                          AND nt.t_NoteKind IN(8, 9)                  
                          AND nt.t_Date <= pDate                 
                          AND nt.t_ValidToDate >= pDate                  
                          AND nt.t_text NOT LIKE '00%'                  
                          AND nt.t_DocumentId = acc.documentId                  
                   )                  
       SELECT a.t_Account Account,                  
--              a.t_Code_Currency Code_Currency,                  
              a.t_Chapter Chapter,                  
              a.t_Open_Date Open_Date,                  
              a.t_Close_Date Close_Date,
              case 
                    when (instr(t_type_account,'Ч')>0) then 'Текущий Счет' 
                else 
                    case 
                        when (t_balance between '42301' and'42307')or
                             (t_balance between '42601' and'42607') then
                             (select b.t_name_part from dbalance_dbt b where b.t_balance=a.t_balance)  
                    end 
                end type_acc,
              (select p.t_name from dparty_dbt p                  
                where p.t_partyid=                  
                  CASE                  
                      WHEN a.isClientBalance = 1                  
                          THEN a.t_Client                  
                      ELSE                  
                          DECODE (rsb_rep_pt.is_our_bank (a.t_Client, (select t_partyid from ddp_dep_dbt where t_parentcode=0)),                  
                                  0, (SELECT t_PartyId                  
                                        FROM ddp_dep_dbt                  
                                       WHERE t_Code = a.t_Branch),                  
                                  a.t_Client)                  
                  END) Client,
              NVL(                  
                  NVL(                  
                      NVL( (SELECT t_Number                  
                              FROM dsfcontr_dbt                  
                             WHERE t_ObjectType = 1 AND t_Object = a.t_Account AND t_FIID = a.t_Code_Currency AND t_ServKind = 9),                  
                           (SELECT t_Number                  
                              FROM dsfcontr_dbt                  
                             WHERE t_ObjectType = 1 AND t_Object = a.t_Account AND t_FIID = a.t_Code_Currency AND t_ServKind = 3)                  
                         ),                  
                      (SELECT t_Number                  
                         FROM dsfcontr_dbt                  
                        WHERE t_ObjectType = 1 AND t_Object = a.t_Account AND t_FIID = a.t_Code_Currency AND ROWNUM < 2)                  
                  ),                  
                  NVL (noteContractNumber.noteText, null)                  
              ) ContractNumber,                  
              NVL(                  
                  NVL(                  
                      NVL( (SELECT t_DateBegin                  
                              FROM dsfcontr_dbt                  
                             WHERE t_ObjectType = 1 AND t_Object = a.t_Account AND t_FIID = a.t_Code_Currency AND t_ServKind = 9),                  
                           (SELECT t_DateBegin                  
                              FROM dsfcontr_dbt                  
                             WHERE t_ObjectType = 1 AND t_Object = a.t_Account AND t_FIID = a.t_Code_Currency AND t_ServKind = 3)),                  
                      (SELECT t_DateBegin                  
                         FROM dsfcontr_dbt                  
                        WHERE t_ObjectType = 1 AND t_Object = a.t_Account AND t_FIID = a.t_Code_Currency AND ROWNUM < 2)                  
                  ),                  
                  NVL (noteContractDate.noteDate, TO_DATE('01-01-0001', 'DD-MM-YYYY'))                  
              ) ContractDate                  
         FROM acc a                  
              LEFT OUTER JOIN note noteContractNumber ON (    noteContractNumber.t_account  = a.t_account                  
                                                          AND noteContractNumber.t_chapter  = a.t_chapter                  
                                                          AND noteContractNumber.t_NoteKind = 8                  
                                                         )                  
              LEFT OUTER JOIN note noteContractDate ON (    noteContractDate.t_account  = a.t_account                  
                                                          AND noteContractDate.t_chapter  = a.t_chapter                  
                                                          AND noteContractDate.t_NoteKind = 9                  
                                                         )                  
        WHERE rsb_mask.CompareStringWithMask(pAccount,a.t_account)=1;

     return view_cur;

   end;

   function GetArhdocInfo ( pDate      in date,
                            pAccount   in varchar2 default null,
                            pChapter   in number default null)
     return sys_refcursor
   is
     view_cur         sys_refcursor;

   begin

     open view_cur for
                 select
                    a.t_account_payer    account,
                    0                    payer_sum,
                    a.t_sum_receiver     receiver_sum,
                    a.t_account_payer    account_payer,
                    a.t_account_receiver account_receiver,
                    a.t_ground           ground,
                    a.t_date_carry       date_carry
                   from (select ad.t_account_payer,
                                ad.t_account_receiver,
                                ad.t_date_carry,
                                ad.t_sum_receiver,
                                ad.t_ground,
                                ad.t_chapter
                           -- KS 28.11.2013 Адаптация под 31ю сборку
                           --from darhdoc_dbt ad
                           from dacctrn_dbt ad
                          where ad.t_date_carry = pDate
                          /*union
                         select ad.t_account_payer,
                                ad.t_account_receiver,
                                ad.t_date_carry,
                                ad.t_sum,
                                ad.t_ground,
                                ad.t_chapter
                           from darhdoc$_dbt ad
                          where ad.t_date_carry = pDate*/
                        ) a
                  where rsb_mask.CompareStringWithMask(pAccount,a.t_account_payer)=1
                    and (pChapter is null or pChapter=a.t_chapter)
                   union
                 select
                    a.t_account_receiver account,
                    a.t_sum_payer        payer_sum,
                    0                    receiver_sum,
                    a.t_account_payer    account_payer,
                    a.t_account_receiver account_receiver,
                    a.t_ground           ground,
                    a.t_date_carry       date_carry
                   from (select ad.t_account_payer,
                                ad.t_account_receiver,
                                ad.t_date_carry,
                                ad.t_sum_payer,
                                ad.t_ground,
                                ad.t_chapter
                           -- KS 28.11.2013 Адаптация под 31ю сборку
                           --from darhdoc_dbt ad
                           from dacctrn_dbt ad
                          where ad.t_date_carry = pDate
                          /*union
                         select ad.t_account_payer,
                                ad.t_account_receiver,
                                ad.t_date_carry,
                                ad.t_sum,
                                ad.t_ground,
                                ad.t_chapter
                           from darhdoc$_dbt ad
                          where ad.t_date_carry = pDate*/
                        ) a
                  where rsb_mask.CompareStringWithMask(pAccount,a.t_account_receiver)=1
                    and (pChapter is null or pChapter=a.t_chapter);

     return view_cur;

   end;

   -- Проводки - Отчет по расчету резервов по сомнительным долгам (юр.лица)
   function GetRestInfoForDebts
     return sys_refcursor
   is
     view_cur         sys_refcursor;
   begin
     -- KS 28.11.2013 Адаптация под 31ю сборку
     -- Пересал на поле T_RESTDATE, дописал связку с daccount_dbt
     open view_cur for
          select a.t_account, r.T_RESTDATE t_Date_Value, r.t_Rest
            from drestdate_dbt r, daccount_dbt a
           where ((substr(a.t_account, 1, 3) = '459' and substr(a.t_account, 1, 5) != '45918') or
                  (substr(a.t_account, 1, 5) = '47423') or
                  (substr(a.t_account, 1, 5) = '91604'))
             and r.T_RESTDATE >= to_date('1998-01-01', 'YYYY-MM-DD')
             and a.t_accountid = r.t_accountid;

     return view_cur;

   end;

   -- Остатки - Отчет по расчету резервов по сомнительным долгам (юр.лица)
   function GetAccountInfoForDebts
     return sys_refcursor
   is
     view_cur         sys_refcursor;
   begin

     open view_cur for
          SELECT a.t_open_date, a.t_final_date, a.t_Account, c.t_Name, '1' as tip
            FROM dparty_dbt c, daccount_dbt a
           WHERE a.t_balance = '47423'
             and a.t_chapter = 1
             and a.t_client = c.t_partyid
          UNION
          SELECT a.t_open_date, a.t_final_date, a.t_Account, c.t_Name, '2' as tip
            FROM dparty_dbt c, daccount_dbt a
           WHERE substr(a.t_balance,1,3) = '459'
             and a.t_Close_Date = to_date('0001-01-01','YYYY-MM-DD')
             and a.t_open_date >= to_date('1998-01-01','YYYY-MM-DD')
             and a.t_balance != '45918'
             and a.t_client = c.t_partyid
          UNION
          SELECT a.t_open_date, a.t_final_date, a.t_Account, c.t_Name, '3' as tip
            FROM dparty_dbt c, daccount_dbt a
           where a.t_balance = '91604'
             and a.t_chapter = 3
             and a.t_open_date >= to_date('1998-01-01','YYYY-MM-DD')
             and a.t_client = c.t_partyid;

     return view_cur;

   end;
   
   function GetPayments( paym_type  in number,
                         origin     in number,
                         date_from  in date,
                         date_to    in date)
     return sys_refcursor
   is
     view_cur         sys_refcursor;
   begin
     if(paym_type=0)then
       open view_cur for
          select p.t_paymentid paymentid, -- ид платежа в РС6 (которые возвращается мне при вставке)
                 p.t_dockind dockind, -- док кайнд
                 p.t_amount amount, -- сумма
                 pr.t_date docdate, -- дата документа
                 p.t_creationdate doccreationdate, --дата создания документа
                 p.t_valuedate valuedate, --дата значени документа
                 p.t_paymstatus docstate, -- статус документа (т.е место положение документа, там в закрытых он находится, в отложенных или еще где)
                 st.t_name docstatetext, -- статус документа (т.е место положение документа, там в закрытых он находится, в отложенных или еще где)
                 p.t_payeraccount accountpayer, -- счета плательщика
                 p.t_receiveraccount accountreceiver, -- счет получателя
                 p.t_origin origin, -- происхождение.
                 p.t_numberpack packnum -- номер пачки--*/
            from dpmpaym_dbt p, dpmrmprop_dbt pr, dllvalues_dbt st
           where p.t_paymentid=pr.t_paymentid
             and st.t_list=2054
             and p.t_paymstatus=st.t_element(+)
             and (p.t_origin in (2200,2300,2400,2500,2600,2800,2900,3000,3100,3200,3300))
             and (origin in (0,p.t_origin))
             and p.t_creationdate between date_from and date_to;
     elsif(paym_type=1)then
       open view_cur for
          select p.t_paymentid       paymentid, -- ид платежа в РС6 (которые возвращается мне при вставке)
                 p.t_dockind         dockind, -- док кайнд
                 p.t_amount          amount, -- сумма
                 pr.t_date           docdate, -- дата документа
                 p.t_creationdate    doccreationdate, --дата создания документа
                 p.t_valuedate       valuedate, --дата значени документа
                 p.t_paymstatus      docstate, -- статус документа (т.е место положение документа, там в закрытых он находится, в отложенных или еще где)
                 st.t_name           docstatetext, -- статус документа (т.е место положение документа, там в закрытых он находится, в отложенных или еще где)
                 p.t_payeraccount    accountpayer, -- счета плательщика
                 p.t_receiveraccount accountreceiver, -- счет получателя
                 decode(rp.rule_id, 51, 0, 52, 1, -1) origin, -- происхождение.
                 p.t_numberpack packnum -- номер пачки--*/
            from dpmpaym_dbt   p,
                 dpmrmprop_dbt pr,
                 dllvalues_dbt st,
                 doproper_dbt  oper,
                 DOPRSTEP_DBT  os,
                 usr_route_parm rp
           where p.t_paymentid = pr.t_paymentid
             and st.t_list = 2054
             and p.t_paymstatus = st.t_element(+)
             and oper.T_ID_OPERATION = os.t_Id_Operation
             and oper.T_DOCUMENTID = lpad(p.T_PAYMENTID, 34, '0')
             and os.t_blockid = 11000120
             and os.t_number_step = 10
             and p.t_creationdate between date_from and date_to
             and origin in (decode(rp.rule_id, 51, 0, 52, 1, -1),2)
             and rp.state = 0 -- Переписал под правила маршрутизации,
                              -- т.к. чтение категории было не опримально
             and regexp_like(p.t_payeraccount, rp.deb_accmask)
             and regexp_like(p.t_receiveraccount, rp.kred_accmask)
             and not regexp_like (nvl(p.t_payeraccount,' '), nvl (rp.deb_accmask_skip, '^$')) 
             and not regexp_like (nvl(p.t_receiveraccount,' '), nvl (rp.kred_accmask_skip, '^$'))
           group by p.t_paymentid, p.t_dockind, p.t_amount, pr.t_date,
                    p.t_creationdate, p.t_valuedate, p.t_paymstatus, st.t_name,
                    p.t_payeraccount, p.t_receiveraccount, decode(rp.rule_id, 51, 0, 52, 1, -1), p.t_numberpack
          having chr(min(ascii(os.t_isexecute))) != 'R';
     end if;
     return view_cur;
   end;

begin
   null;
end;
/
