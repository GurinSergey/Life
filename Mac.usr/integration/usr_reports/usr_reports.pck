create or replace package usr_reports
-- Пакет для выпуска отчетности из внешних систем
-- 29.11.2012 Гуцу Е. В. C-12071 get_tarif_info()
-- 27.12.2012 Golovkin   C-16337 добавлено поле "Сеанс отправки"(get_bbdoc)
-- 27.12.2012 Golovkin   С-15512 изменение знака у активных счетов(get_accountbyday)
-- 24.01.2012 Golovkin   C-16874 Добавлена процедура get_arhdocs
-- 10.04.2012 zip_z.     C-18095 get_client_turns ()
-- 9.07.2013 Гуцу Е. В.  C-21263 get_sfdef() 

is
    procedure get_client_turns ( p_date in date, p_cursor out sys_refcursor );

    procedure get_statement ( p_account in varchar2
                             ,p_branch in varchar2
                             ,p_chapter in number
                             ,p_balance in varchar2
                             ,p_currency in varchar2
                             ,p_datebegin in date
                             ,p_dateend in date
                             ,p_usertypeaccount in varchar2
                             ,p_oper in   number
                             ,p_cursor   out sys_refcursor );

    procedure get_statement_arh ( p_account in varchar2
                                 ,p_branch in varchar2
                                 ,p_chapter in number
                                 ,p_balance in varchar2
                                 ,p_currency in varchar2
                                 ,p_datebegin in date
                                 ,p_dateend in date
                                 ,p_usertypeaccount in varchar2
                                 ,p_oper in   number
                                 ,p_cursor   out sys_refcursor );

    procedure get_vbsvs ( p_usertypeaccount in varchar2
                         ,p_branch in varchar2
                         ,p_chapter in number
                         ,p_datebegin in date
                         ,p_dateend in date
                         ,p_cursor   out sys_refcursor );

    procedure get_balance_mem ( p_code1 in number, p_code2 in number, p_repdate in date, p_cursor out sys_refcursor );

    procedure get_client_int ( p_code1 in number, p_code2 in number, p_repdate in date, p_cursor out sys_refcursor );

    procedure get_curr_mem ( p_code1 in number, p_code2 in number, p_repdate in date, p_cursor out sys_refcursor );

    procedure get_curr_conv ( p_code1 in number, p_code2 in number, p_repdate in date, p_cursor out sys_refcursor );

    procedure get_chap3 ( p_code1 in number, p_code2 in number, p_repdate in date, p_cursor out sys_refcursor );

    procedure get_vbs ( p_dep in    varchar2
                       ,p_chapt in  number
                       ,p_symb in   varchar2
                       ,p_datebegin in date
                       ,p_dateend in date
                       ,p_cursor   out sys_refcursor );

    procedure get_bbdoc ( p_oper in number, p_numberpack in number, p_repdate in date, p_cursor out sys_refcursor );

    procedure get_invent ( p_code1 in number, p_code2 in number, p_code_curr in varchar2, p_repdate in date, p_cursor out sys_refcursor );

    procedure get_bal_all ( p_code1 in  number
                           ,p_code2 in  number
                           ,p_code_curr in varchar2
                           ,p_repdate in date
                           ,p_type in   number
                           ,p_oper in   number
                           ,p_cursor   out sys_refcursor );

    procedure get_dotdels_dbt ( p_cursor out sys_refcursor );

    procedure get_otd_oper ( p_code1 in number, p_code2 in number, p_oper in number, p_repdate in date, p_cursor out sys_refcursor );

    procedure get_curr_conv_new ( p_code1 in number, p_code2 in number, p_repdate in date, p_cursor out sys_refcursor );

    procedure get_chap3_new ( p_code1 in number, p_code2 in number, p_repdate in date, p_cursor out sys_refcursor );

    procedure get_curr_conv_cons ( p_code1 in number, p_code2 in number, p_repdate in date, p_cursor out sys_refcursor );

    procedure get_chap3_cons ( p_code1 in number, p_code2 in number, p_repdate in date, p_cursor out sys_refcursor );

    procedure get_accountbyday ( p_dep in    varchar
                                ,p_currency in varchar
                                ,p_null in   number
                                ,p_balance in varchar
                                ,p_usertype in varchar
                                ,p_repdate in date
                                ,p_connect in number
                                ,p_cursor   out sys_refcursor );

    /* EVG 29/11/2012 Процедура для получения параметров тарифа комиссии (заявка C-12071)*/
    procedure get_tarif_info ( p_account in varchar2
                              ,p_rscode in varchar2
                              ,p_ficode in varchar2
                              ,p_sfcomtype in number
                              ,p_sfcomcode in varchar2
                              ,p_date in   date
                              ,p_cursor   out sys_refcursor );

    procedure get_arhdocs ( p_datebegin in date, p_dateend in date, p_currency in varchar2, p_oper in number, p_cursor out sys_refcursor );
    
    /* EVG 9/07/2013 Процедура для загрузки даты окончания периода оплаты из RS Bank во Фронт Лайф (заявка C-21263) */
    procedure get_sfdef ( p_date   in  date
                         ,p_cursor out sys_refcursor );
end; 
/
create or replace package body usr_reports
is
    -- KS 28.11.2013 Перенос пользовательских доработок в 31ю сборку
    --    Выполнена первоначальная адаптация
    --    Тут такие огромные запросы с юнионами, что даже не понятно - можно ли как-то избавиться от них
    --    при переходе на новую таблицу проводок
    --    Ещё радо разобраться с ИФ ЗЕН ЭЛС. Где идёт разделение по валютам
    procedure get_client_turns ( p_date in date, p_cursor out sys_refcursor )
    is
    begin
        open p_cursor for
            select (select p_date from dual) as t_date
                  ,t_account
                  ,t_code_currency
                  ,t_nameaccount
                  , ( select count ( 1 )
                     -- KS 28.11.2013 Перенос пользовательских доработок в 31ю сборку
                     --from darhdoc_dbt
                     from dacctrn_dbt
                     where t_account_receiver = ac.t_account and t_chapter = ac.t_chapter and t_date_carry = p_date )
                       n_kt
                  , ( select nvl ( sum ( t_sum_natcur ), 0 )
                     -- KS 28.11.2013 Перенос пользовательских доработок в 31ю сборку
                     --from darhdoc_dbt
                     from dacctrn_dbt t
                     where t_account_receiver = ac.t_account and t_chapter = ac.t_chapter and t_date_carry = p_date )
                       sum_kt
                  , ( select count ( 1 )
                     -- KS 28.11.2013 Перенос пользовательских доработок в 31ю сборку
                     --from darhdoc_dbt
                     from dacctrn_dbt
                     where t_account_receiver = ac.t_account and t_chapter = ac.t_chapter and t_date_carry = p_date and t_kind_oper != ' 3' )
                       n_kt_nocash
                  , ( select nvl ( sum ( t_sum_natcur ), 0 )
                     -- KS 28.11.2013 Перенос пользовательских доработок в 31ю сборку
                     --from darhdoc_dbt
                     from dacctrn_dbt
                     where t_account_receiver = ac.t_account and t_chapter = ac.t_chapter and t_date_carry = p_date and t_kind_oper != ' 3' )
                       sum_kt_nocash
                  , ( select count ( 1 )
                     -- KS 28.11.2013 Перенос пользовательских доработок в 31ю сборку
                     --from darhdoc_dbt
                     from dacctrn_dbt
                     where t_account_payer = ac.t_account and t_chapter = ac.t_chapter and t_date_carry = p_date )
                       n_dt
                  , ( select nvl ( sum ( t_sum_natcur ), 0 )
                     -- KS 28.11.2013 Перенос пользовательских доработок в 31ю сборку
                     --from darhdoc_dbt
                     from dacctrn_dbt
                     where t_account_payer = ac.t_account and t_chapter = ac.t_chapter and t_date_carry = p_date )
                       sum_dt
                  , ( select count ( 1 )
                     from dpmpaym_dbt pm, dpspayord_dbt ord
                     where pm.t_paymentid = ord.t_orderid
                       and pm.t_dockind = 201
                       and ord.t_dockind = 1
                       and t_valuedate = p_date
                       and pm.t_payeraccount = ac.t_account
                       and t_chapter = ac.t_chapter
                       and pm.t_paymstatus = 32000 )
                       n_pspayord
                  , ( select nvl ( sum ( t_amount ), 0 )
                     from dpmpaym_dbt pm, dpspayord_dbt ord
                     where pm.t_paymentid = ord.t_orderid
                       and pm.t_dockind = 201
                       and ord.t_dockind = 1
                       and t_valuedate = p_date
                       and pm.t_payeraccount = ac.t_account
                       and t_chapter = ac.t_chapter
                       and pm.t_paymstatus = 32000 )
                       sum_pspayord
            from daccount_dbt ac
            where regexp_like ( t_account, '^405|^406|^407|^40802|^40807' )
              and regexp_like ( t_balance, '^405|^406|^407|^40802|^40807' )
              and t_chapter = 1
              and instr ( t_type_account, 'П' ) = 0;
    end;

    /*Выписка по счетам*/
    procedure get_statement ( p_account in varchar2
                             ,p_branch in varchar2
                             ,p_chapter in number
                             ,p_balance in varchar2
                             ,p_currency in varchar2
                             ,p_datebegin in date
                             ,p_dateend in date
                             ,p_usertypeaccount in varchar2
                             ,p_oper in   number
                             ,p_cursor   out sys_refcursor )
    is
    begin
        if ( p_currency = '810' )
        then
            -- KS 28.11.2013 Перенос пользовательских доработок в 31ю сборку
            open p_cursor for
                select rownum as numb, a.*
                from ( select arh.t_date_carry
                             ,acc.t_account
                             --,rest.t_date_value
                             ,rest.t_restdate t_date_value
                             ,acc.t_nameaccount
                             ,abs ( rsb_account.resta ( acc.t_account, p_datebegin - 1, acc.t_chapter, 0/*acc.t_r0*/ ) ) as resta
                             ,abs ( rsb_account.resta ( acc.t_account, p_dateend, acc.t_chapter, 0/*acc.t_r0*/ ) ) as restb
                             ,arh.t_shifr_oper
                             ,arh.t_numb_document
                             ,obj.t_code
                             ,case when acc.t_account = arh.t_account_receiver then arh.t_account_payer else arh.t_account_receiver end корр
                             --,case when acc.t_account = arh.t_account_receiver then arh.t_sum else null end кредит
                             ,case when acc.t_account = arh.t_account_receiver then arh.t_sum_natcur else null end кредит
                             --,case when acc.t_account = arh.t_account_payer then arh.t_sum else null end дебет
                             ,case when acc.t_account = arh.t_account_payer then arh.t_sum_natcur else null end дебет
                             ,arh.t_ground
                             ,'Российский рубль' as curr
                             ,cl.t_name as client
                             ,nvl ( inn.t_code, '0' ) as inn
                       from daccount_dbt acc
                           ,daccblnc_dbt blnc
                           -- KS 28.11.2013 Перенос пользовательских доработок в 31ю сборку
                           --,darhdoc_dbt arh
                           ,dacctrn_dbt arh
                           ,dobjcode_dbt obj
                           ,dpmdocs_dbt doc
                           ,dpmpaym_dbt pm
                           ,ddp_dep_dbt dp
                           ,drestdate_dbt rest
                           ,dparty_dbt cl
                           ,dobjcode_dbt inn
                       where acc.t_type_account like '%' || p_usertypeaccount || '%'
                         and ( acc.t_type_account not like '%П%' and acc.t_type_account not like '%U%' and acc.t_type_account not like '%Н%' )
                         and blnc.t_account = acc.t_account
                         and blnc.t_chapter = acc.t_chapter
                         and blnc.t_balance0 = acc.t_balance
                         and arh.t_date_carry between p_datebegin and p_dateend
                         and ( acc.t_account = arh.t_account_receiver or acc.t_account = arh.t_account_payer )
                         and inn.t_codekind(+) = 16
                         and inn.t_objecttype(+) = 3
                         and inn.t_state(+) = 0
                         and inn.t_objectid(+) = acc.t_client
                         and cl.t_partyid = acc.t_client
                         and obj.t_codekind = 3
                         and obj.t_objecttype = 3
                         and obj.t_state = 0
                         and obj.t_objectid = case when t_kind_account = 'А' then pm.t_payerbankid else pm.t_receiverbankid end
                         -- KS 28.11.2013 Перенос пользовательских доработок в 31ю сборку
                         --and arh.t_applicationkey = doc.t_applicationkey
                         --and arh.t_iapplicationkind = doc.t_applicationkind
                         and arh.t_acctrnid = doc.t_acctrnid
--                         and arh.t_fiid_payer = 0
--                         and arh.t_fiid_receiver = 0
                         -- 13.03.2014 Golovkin надо правильно по валюте определять                        
                         and (1 =
                             case
                                when acc.t_account = arh.t_account_receiver
                                     and arh.t_fiid_receiver = 0
                                then
                                   1
                                when acc.t_account = arh.t_account_payer
                                     and arh.t_fiid_payer = 0
                                then
                                   1
                                else
                                   0
                             end)
                         and pm.t_paymentid = doc.t_paymentid
                         and ( 1 = case
                                       when p_account is null then 1
                                       when rsb_mask.comparestringwithmask ( p_account, acc.t_account ) = 1 then 1
                                       else 0
                                   end )
                         and acc.t_chapter = p_chapter
                         and ( 1 = case
                                       when p_balance is null then 1
                                       when acc.t_balance = p_balance then 1
                                       else 0
                                   end )
                         and ( 1 = case
                                       when p_oper is null then 1
                                       when acc.t_oper = p_oper then 1
                                       else 0
                                   end )
                         and acc.t_branch = dp.t_code
                         and dp.t_name = p_branch
                         -- KS 28.11.2013 Перенос пользовательских доработок в 31ю сборку
                         --and rest.t_date_value =
                         and rest.t_restdate =
                                 nvl ( ( --select max ( t_date_value )
                                         select max ( t_restdate )
                                           from drestdate_dbt r
                                           --where r.t_account = acc.t_account and r.t_date_value < p_datebegin and r.t_chapter = acc.t_chapter )
                                          where r.t_accountid = acc.t_accountid and r.t_restdate < p_datebegin)
                                      ,p_datebegin )
                         -- KS 28.11.2013 Перенос пользовательских доработок в 31ю сборку
                         --and rest.t_account = acc.t_account
                         --and rest.t_chapter = acc.t_chapter
                         and rest.t_accountid = acc.t_accountid
                       union all
                       select arh.t_date_carry
                             ,acc.t_account
                             --,rest.t_date_value
                             ,rest.t_restdate t_date_value
                             ,acc.t_nameaccount
                             ,abs ( rsb_account.resta ( acc.t_account, p_datebegin - 1, acc.t_chapter, 0/*acc.t_r0*/ ) ) as resta
                             ,abs ( rsb_account.resta ( acc.t_account, p_dateend, acc.t_chapter, 0/*acc.t_r0*/ ) ) as restb
                             ,arh.t_shifr_oper
                             ,arh.t_numb_document
                             ,''
                             ,case when acc.t_account = arh.t_account_receiver then arh.t_account_payer else arh.t_account_receiver end корр
                             -- KS 28.11.2013 Перенос пользовательских доработок в 31ю сборку
                             --,case when acc.t_account = arh.t_account_receiver then arh.t_sum else null end кредит
                             ,case when acc.t_account = arh.t_account_receiver then arh.t_sum_natcur else null end кредит
                             --,case when acc.t_account = arh.t_account_payer then arh.t_sum else null end дебет
                             ,case when acc.t_account = arh.t_account_payer then arh.t_sum_natcur else null end дебет
                             ,arh.t_ground
                             ,'Российский рубль' as curr
                             ,cl.t_name as client
                             ,nvl ( inn.t_code, '0' ) as inn
                       from daccount_dbt acc
                           ,daccblnc_dbt blnc
                           -- KS 28.11.2013 Перенос пользовательских доработок в 31ю сборку
                           --,darhdoc_dbt arh
                           ,dacctrn_dbt arh
                           ,ddp_dep_dbt dp
                           ,drestdate_dbt rest
                           ,dparty_dbt cl
                           ,dobjcode_dbt inn
                       where acc.t_type_account like '%' || p_usertypeaccount || '%'
                         and ( acc.t_type_account not like '%П%' and acc.t_type_account not like '%U%' and acc.t_type_account not like '%Н%' )
                         and inn.t_codekind(+) = 16
                         and inn.t_objecttype(+) = 3
                         and inn.t_state(+) = 0
                         and inn.t_objectid(+) = acc.t_client
                         and cl.t_partyid = acc.t_client
                         and blnc.t_account = acc.t_account
                         and blnc.t_chapter = acc.t_chapter
                         and blnc.t_balance0 = acc.t_balance
                         and arh.t_date_carry between p_datebegin and p_dateend
                         and ( acc.t_account = arh.t_account_receiver or acc.t_account = arh.t_account_payer )
                         and ( 1 = case
                                       when p_account is null then 1
                                       when rsb_mask.comparestringwithmask ( p_account, acc.t_account ) = 1 then 1
                                       else 0
                                   end )
                         and acc.t_chapter = p_chapter
                         and ( 1 = case
                                       when p_balance is null then 1
                                       when acc.t_balance = p_balance then 1
                                       else 0
                                   end )
                         and acc.t_branch = dp.t_code
                         and dp.t_name = p_branch
                         and not exists
                                 (select 1
                                  from dpmdocs_dbt doc, dpmpaym_dbt pm
                                  -- KS 28.11.2013 Перенос пользовательских доработок в 31ю сборку
                                  --where arh.t_applicationkey = doc.t_applicationkey
                                  --  and arh.t_iapplicationkind = doc.t_applicationkind
                                  where arh.t_acctrnid = doc.t_acctrnid
                                    and pm.t_paymentid = doc.t_paymentid)
                         -- KS 28.11.2013 Перенос пользовательских доработок в 31ю сборку
                         --and rest.t_date_value =
                         and rest.t_restdate =
                                 nvl ( ( --select max ( t_date_value )
                                         select max ( t_restdate )
                                           from drestdate_dbt r
                                          --where r.t_account = acc.t_account and r.t_date_value < p_datebegin and r.t_chapter = acc.t_chapter )
                                          where r.t_accountid = acc.t_accountid and r.t_restdate < p_datebegin)
                                      ,p_datebegin )
                         --and rest.t_account = acc.t_account
                         --and rest.t_chapter = acc.t_chapter
                         and rest.t_accountid = acc.t_accountid
--                         and arh.t_fiid_payer = 0
--                         and arh.t_fiid_receiver = 0
                         -- 13.03.2014 Golovkin надо правильно по валюте определять                        
                         and (1 =
                             case
                                when acc.t_account = arh.t_account_receiver
                                     and arh.t_fiid_receiver = 0
                                then
                                   1
                                when acc.t_account = arh.t_account_payer
                                     and arh.t_fiid_payer = 0
                                then
                                   1
                                else
                                   0
                             end)
                       order by t_account, ДЕБЕТ nulls first, КРЕДИТ ) a;
        else
            -- KS 28.11.2013 Перенос пользовательских доработок в 31ю сборку
            open p_cursor for
                select rownum as numb, a.*
                from ( select arh.t_date_carry
                             ,acc.t_account
                             --,rest.t_date_value
                             ,rest.t_restdate t_date_value
                             ,acc.t_nameaccount
                             ,abs ( rsb_account.restac ( acc.t_account, acc.t_code_currency, p_datebegin - 1, acc.t_chapter, 0/*acc.t_r0*/ ) )
                                  as resta
                             ,abs ( rsb_account.restac ( acc.t_account, acc.t_code_currency, p_dateend, acc.t_chapter, 0/*acc.t_r0*/ ) ) as restb
                             ,arh.t_shifr_oper
                             ,arh.t_numb_document
                             ,obj.t_code
                             ,case
                                  when acc.t_account = arh.t_account_receiver
                                  then
                                      decode ( arh.t_account_payer, 'ОВП', pm.t_payeraccount, arh.t_account_payer )
                                  else
                                      decode ( arh.t_account_receiver, 'ОВП', pm.t_receiveraccount, arh.t_account_receiver )
                              end
                                  корр
                             --,case when acc.t_account = arh.t_account_receiver then arh.t_sum else null end кредит
                             ,case when acc.t_account = arh.t_account_receiver then arh.t_sum_receiver else null end кредит
                             --,case when acc.t_account = arh.t_account_payer then arh.t_sum else null end дебет
                             ,case when acc.t_account = arh.t_account_payer then arh.t_sum_payer else null end дебет
                             ,rm.t_ground
                             ,fin.t_name as curr
                             ,cl.t_name as client
                             ,nvl ( inn.t_code, '0' ) as inn
                       from --daccount$_dbt acc
                           daccount_dbt acc
                           --,daccblnc$_dbt blnc
                           ,daccblnc_dbt blnc
                           --,darhdoc$_dbt arh
                           ,dacctrn_dbt arh
                           ,dobjcode_dbt obj
                           ,dpmdocs_dbt doc
                           ,dpmpaym_dbt pm
                           ,dfininstr_dbt fin
                           ,ddp_dep_dbt dp
                           ,drestdate_dbt rest
                           ,dparty_dbt cl
                           ,dobjcode_dbt inn
                           ,dpmrmprop_dbt rm
                       where rm.t_paymentid = pm.t_paymentid
                         and acc.t_type_account like '%' || p_usertypeaccount || '%'
                         and blnc.t_account = acc.t_account
                         and blnc.t_chapter = acc.t_chapter
                         and blnc.t_balance0 = acc.t_balance
                         and arh.t_date_carry between p_datebegin and p_dateend
                         and ( acc.t_account = arh.t_account_receiver or acc.t_account = arh.t_account_payer )
                         and inn.t_codekind(+) = 16
                         and inn.t_objecttype(+) = 3
                         and inn.t_state(+) = 0
                         and inn.t_objectid(+) = acc.t_client
                         and cl.t_partyid = acc.t_client
                         and obj.t_codekind = 3
                         and obj.t_objecttype = 3
                         and obj.t_state = 0
                         and obj.t_objectid = case when t_kind_account = 'А' then pm.t_payerbankid else pm.t_receiverbankid end
                         --and arh.t_applicationkey = doc.t_applicationkey
                         --and arh.t_iapplicationkind = doc.t_applicationkind
                         and arh.t_acctrnid = doc.t_acctrnid
                         and pm.t_paymentid = doc.t_paymentid
                         and ( 1 = case
                                       when p_account is null then 1
                                       when rsb_mask.comparestringwithmask ( p_account, acc.t_account ) = 1 then 1
                                       else 0
                                   end )
                         and acc.t_chapter = p_chapter
                         and ( 1 = case
                                       when p_balance is null then 1
                                       when acc.t_balance = p_balance then 1
                                       else 0
                                   end )
                         and acc.t_branch = dp.t_code
                         and dp.t_name = p_branch
                         --and fin.t_fiid = arh.t_code_currency
--                         and fin.t_fiid = arh.t_fiid_payer
                         and fin.t_fi_code = p_currency
                         --and rest.t_date_value =
                         and rest.t_restdate =
                                 nvl ( ( --select max ( t_date_value )
                                         select max ( t_restdate )
                                           from drestdate_dbt r
                                          --where r.t_account = acc.t_account and r.t_date_value < p_datebegin and r.t_chapter = acc.t_chapter )
                                          where r.t_accountid = acc.t_accountid and r.t_restdate < p_datebegin
                                            and r.t_restcurrency = fin.t_fiid)
                                      ,p_datebegin )
                         --and rest.t_account = acc.t_account
                         --and rest.t_chapter = acc.t_chapter
--                         and (arh.t_fiid_payer != 0 or arh.t_fiid_receiver != 0)
                         and rest.t_restcurrency = fin.t_fiid
                         and (1 = case
                                     when acc.t_account = arh.t_account_receiver
                                          and arh.t_fiid_receiver = fin.t_fiid
                                     then
                                        1
                                     when acc.t_account = arh.t_account_payer
                                          and arh.t_fiid_payer = fin.t_fiid
                                     then
                                        1
                                     else
                                        0
                                  end)
                         and rest.t_accountid = acc.t_accountid
                       union all
                       select arh.t_date_carry
                             ,acc.t_account
                             ,--rest.t_date_value
                             rest.t_restdate t_date_value
                             ,acc.t_nameaccount
                             ,abs ( rsb_account.restac ( acc.t_account, acc.t_code_currency, p_datebegin - 1, acc.t_chapter, 0/*acc.t_r0*/ ) )
                                  as resta
                             ,abs ( rsb_account.restac ( acc.t_account, acc.t_code_currency, p_dateend, acc.t_chapter, 0/*acc.t_r0*/ ) ) as restb
                             ,arh.t_shifr_oper
                             ,arh.t_numb_document
                             ,null
                             ,case when acc.t_account = arh.t_account_receiver then arh.t_account_payer else arh.t_account_receiver end корр
                             --,case when acc.t_account = arh.t_account_receiver then arh.t_sum else null end кредит
                             --,case when acc.t_account = arh.t_account_payer then arh.t_sum else null end дебет
                             ,case when acc.t_account = arh.t_account_receiver then arh.t_sum_receiver else null end кредит
                             ,case when acc.t_account = arh.t_account_payer then arh.t_sum_payer else null end дебет
                             ,arh.t_ground
                             ,fin.t_name as curr
                             ,cl.t_name as client
                             ,nvl ( inn.t_code, '0' ) as inn
                       from --daccount$_dbt acc
                           daccount_dbt acc
                           --,daccblnc$_dbt blnc
                           ,daccblnc_dbt blnc
                           --,darhdoc$_dbt arh
                           ,dacctrn_dbt arh
                           ,dfininstr_dbt fin
                           ,ddp_dep_dbt dp
                           ,drestdate_dbt rest
                           ,dparty_dbt cl
                           ,dobjcode_dbt inn
                       where acc.t_type_account like '%' || p_usertypeaccount || '%'
                         and inn.t_codekind(+) = 16
                         and inn.t_objecttype(+) = 3
                         and inn.t_state(+) = 0
                         and inn.t_objectid(+) = acc.t_client
                         and cl.t_partyid = acc.t_client
                         and blnc.t_account = acc.t_account
                         and blnc.t_chapter = acc.t_chapter
                         and blnc.t_balance0 = acc.t_balance
                         and arh.t_date_carry between p_datebegin and p_dateend
                         and ( acc.t_account = arh.t_account_receiver or acc.t_account = arh.t_account_payer )
                         and ( 1 = case
                                       when p_account is null then 1
                                       when rsb_mask.comparestringwithmask ( p_account, acc.t_account ) = 1 then 1
                                       else 0
                                   end )
                         and acc.t_chapter = p_chapter
                         and ( 1 = case
                                       when p_balance is null then 1
                                       when acc.t_balance = p_balance then 1
                                       else 0
                                   end )
                         and acc.t_branch = dp.t_code
                         and dp.t_name = p_branch
                         --and fin.t_fiid = arh.t_code_currency
--                          ШТА??!
--                         and fin.t_fiid = arh.t_fiid_payer
                         and fin.t_fi_code = p_currency
                         and not exists
                                 (select 1
                                  from dpmdocs_dbt doc, dpmpaym_dbt pm
                                  --where arh.t_applicationkey = doc.t_applicationkey
                                  --  and arh.t_iapplicationkind = doc.t_applicationkind
                                  where arh.t_acctrnid = doc.t_acctrnid
                                    and pm.t_paymentid = doc.t_paymentid)
                         --and rest.t_date_value =
                         and rest.t_restdate =
                                 nvl ( ( --select max ( t_date_value )
                                         select max ( t_restdate )
                                           from drestdate_dbt r
                                          --where r.t_account = acc.t_account and r.t_date_value < p_datebegin and r.t_chapter = acc.t_chapter )
                                          where r.t_accountid = acc.t_accountid and r.t_restdate < p_datebegin
                                            and r.t_restcurrency = fin.t_fiid)
                                      ,p_datebegin )
                         --and rest.t_account = acc.t_account
                         --and rest.t_chapter = acc.t_chapter
                         and rest.t_accountid = acc.t_accountid
--                          ШТА??!
--                         and (arh.t_fiid_payer != 0 or arh.t_fiid_receiver != 0)
                         and rest.t_restcurrency = fin.t_fiid
                         and (1 = case
                                     when acc.t_account = arh.t_account_receiver
                                          and arh.t_fiid_receiver = fin.t_fiid
                                     then
                                        1
                                     when acc.t_account = arh.t_account_payer
                                          and arh.t_fiid_payer = fin.t_fiid
                                     then
                                        1
                                     else
                                        0
                                  end)
                       order by t_account, ДЕБЕТ nulls first, КРЕДИТ ) a;
        end if;
    end;

    /*Выписка по счетам - проводки*/
    procedure get_statement_arh ( p_account in varchar2
                                 ,p_branch in varchar2
                                 ,p_chapter in number
                                 ,p_balance in varchar2
                                 ,p_currency in varchar2
                                 ,p_datebegin in date
                                 ,p_dateend in date
                                 ,p_usertypeaccount in varchar2
                                 ,p_oper in   number
                                 ,p_cursor   out sys_refcursor )
    is
    begin
        -- KS 28.11.2013 Перенос пользовательских доработок в 31ю сборку
        if ( p_currency = '810' )
        then
            open p_cursor for
                select rownum as numb, a.*
                from ( select arh.t_date_carry
                             ,acc.t_account
                             --,rest.t_date_value
                             ,rest.t_restdate t_date_value
                             ,acc.t_nameaccount
                             ,abs ( rsb_account.resta ( acc.t_account, p_datebegin - 1, acc.t_chapter, 0/*acc.t_r0*/ ) ) as resta
                             ,abs ( rsb_account.resta ( acc.t_account, p_dateend, acc.t_chapter, 0/*acc.t_r0*/ ) ) as restb
                             ,arh.t_shifr_oper
                             ,arh.t_numb_document
                             ,''
                             ,case when acc.t_account = arh.t_account_receiver then arh.t_account_payer else arh.t_account_receiver end корр
                             --,case when acc.t_account = arh.t_account_receiver then arh.t_sum else null end кредит
                             --,case when acc.t_account = arh.t_account_payer then arh.t_sum else null end дебет
                             ,case when acc.t_account = arh.t_account_receiver then arh.t_sum_receiver else null end кредит
                             ,case when acc.t_account = arh.t_account_payer then arh.t_sum_payer else null end дебет
                             ,arh.t_ground
                             ,'Российский рубль' as curr
                             ,cl.t_name as client
                             ,nvl ( inn.t_code, '0' ) as inn
                       from daccount_dbt acc
                           ,daccblnc_dbt blnc
                           --,darhdoc_dbt arh
                           ,dacctrn_dbt arh
                           ,ddp_dep_dbt dp
                           ,drestdate_dbt rest
                           ,dparty_dbt cl
                           ,dobjcode_dbt inn
                       where acc.t_type_account like '%' || p_usertypeaccount || '%'
                         and ( acc.t_type_account not like '%П%' and acc.t_type_account not like '%U%' and acc.t_type_account not like '%Н%' )
                         and inn.t_codekind(+) = 16
                         and inn.t_objecttype(+) = 3
                         and inn.t_state(+) = 0
                         and inn.t_objectid(+) = acc.t_client
                         and cl.t_partyid = acc.t_client
                         and blnc.t_account = acc.t_account
                         and blnc.t_chapter = acc.t_chapter
                         and blnc.t_balance0 = acc.t_balance
                         and arh.t_date_carry between p_datebegin and p_dateend
                         and ( acc.t_account = arh.t_account_receiver or acc.t_account = arh.t_account_payer )
                         and ( 1 = case
                                       when p_account is null then 1
                                       when rsb_mask.comparestringwithmask ( p_account, acc.t_account ) = 1 then 1
                                       else 0
                                   end )
                         and acc.t_chapter = p_chapter
                         and ( 1 = case
                                       when p_balance is null then 1
                                       when acc.t_balance = p_balance then 1
                                       else 0
                                   end )
                         and acc.t_branch = dp.t_code
                         and dp.t_name = p_branch
                         --and rest.t_date_value =
                         and rest.t_restdate =
                                 nvl ( ( --select max ( t_date_value )
                                         select max ( t_restdate )
                                           from drestdate_dbt r
                                          --where r.t_account = acc.t_account and r.t_date_value < p_datebegin and r.t_chapter = acc.t_chapter )
                                          where r.t_accountid = acc.t_accountid and r.t_restdate < p_datebegin)
                                      ,p_datebegin )
                         --and rest.t_account = acc.t_account
                         --and rest.t_chapter = acc.t_chapter
                         and rest.t_accountid = acc.t_accountid
--                         and arh.t_fiid_payer = 0
--                         and arh.t_fiid_receiver = 0                        
                         -- 13.03.2014 Golovkin надо правильно по валюте определять                        
                         and (1 =
                             case
                                when acc.t_account = arh.t_account_receiver
                                     and arh.t_fiid_receiver = 0
                                then
                                   1
                                when acc.t_account = arh.t_account_payer
                                     and arh.t_fiid_payer = 0
                                then
                                   1
                                else
                                   0
                             end)
                       order by t_account, ДЕБЕТ nulls first, КРЕДИТ ) a;
        else
            open p_cursor for
                select rownum as numb, a.*
                from ( select arh.t_date_carry
                             ,acc.t_account
                             ,--rest.t_date_value
                             rest.t_restdate t_date_value
                             ,acc.t_nameaccount
                             ,abs ( rsb_account.restac ( acc.t_account, acc.t_code_currency, p_datebegin - 1, acc.t_chapter, 0/*acc.t_r0*/ ) )
                                  as resta
                             ,abs ( rsb_account.restac ( acc.t_account, acc.t_code_currency, p_dateend, acc.t_chapter, 0/*acc.t_r0*/ ) ) as restb
                             ,arh.t_shifr_oper
                             ,arh.t_numb_document
                             ,null
                             ,case when acc.t_account = arh.t_account_receiver then arh.t_account_payer else arh.t_account_receiver end корр
                             --,case when acc.t_account = arh.t_account_receiver then arh.t_sum else null end кредит
                             --,case when acc.t_account = arh.t_account_payer then arh.t_sum else null end дебет
                             ,case when acc.t_account = arh.t_account_receiver then arh.t_sum_receiver else null end кредит
                             ,case when acc.t_account = arh.t_account_payer then arh.t_sum_payer else null end дебет
                             ,arh.t_ground
                             ,fin.t_name as curr
                             ,cl.t_name as client
                             ,nvl ( inn.t_code, '0' ) as inn
                       from --daccount$_dbt acc
                            daccount_dbt acc
                           --,daccblnc$_dbt blnc
                           ,daccblnc_dbt blnc
                           --,darhdoc$_dbt arh
                           ,dacctrn_dbt arh
                           ,dfininstr_dbt fin
                           ,ddp_dep_dbt dp
                           ,drestdate_dbt rest
                           ,dparty_dbt cl
                           ,dobjcode_dbt inn
                       where acc.t_type_account like '%' || p_usertypeaccount || '%'
                         and inn.t_codekind(+) = 16
                         and inn.t_objecttype(+) = 3
                         and inn.t_state(+) = 0
                         and inn.t_objectid(+) = acc.t_client
                         and cl.t_partyid = acc.t_client
                         and blnc.t_account = acc.t_account
                         and blnc.t_chapter = acc.t_chapter
                         and blnc.t_balance0 = acc.t_balance
                         and arh.t_date_carry between p_datebegin and p_dateend
                         and ( acc.t_account = arh.t_account_receiver or acc.t_account = arh.t_account_payer )
                         and ( 1 = case
                                       when p_account is null then 1
                                       when rsb_mask.comparestringwithmask ( p_account, acc.t_account ) = 1 then 1
                                       else 0
                                   end )
                         and acc.t_chapter = p_chapter
                         and ( 1 = case
                                       when p_balance is null then 1
                                       when acc.t_balance = p_balance then 1
                                       else 0
                                   end )
                         and acc.t_branch = dp.t_code
                         and dp.t_name = p_branch
                         --and fin.t_fiid = arh.t_code_currency
--                         and fin.t_fiid = arh.t_fiid_payer
                         and fin.t_fi_code = p_currency
                         --and rest.t_date_value =
                         and rest.t_restdate =
                                 nvl ( ( --select max ( t_date_value )
                                         select max ( t_restdate )
                                           from drestdate_dbt r
                                          --where r.t_account = acc.t_account and r.t_date_value < p_datebegin and r.t_chapter = acc.t_chapter )
                                          where r.t_accountid = acc.t_accountid and r.t_restdate < p_datebegin
                                            and r.t_restcurrency = fin.t_fiid)
                                      ,p_datebegin )
                         --and rest.t_account = acc.t_account
                         --and rest.t_chapter = acc.t_chapter
                         and rest.t_accountid = acc.t_accountid
--                         and (arh.t_fiid_payer != 0 or arh.t_fiid_receiver != 0)
                         and rest.t_restcurrency = fin.t_fiid
                         and (1 = case
                                     when acc.t_account = arh.t_account_receiver
                                          and arh.t_fiid_receiver = fin.t_fiid
                                     then
                                        1
                                     when acc.t_account = arh.t_account_payer
                                          and arh.t_fiid_payer = fin.t_fiid
                                     then
                                        1
                                     else
                                        0
                                  end)
                       order by t_account, ДЕБЕТ nulls first, КРЕДИТ ) a;
        end if;
    end;

    /*Оборотно-сальдовая ведомость*/
    procedure get_vbsvs ( p_usertypeaccount in varchar2
                         ,p_branch in varchar2
                         ,p_chapter in number
                         ,p_datebegin in date
                         ,p_dateend in date
                         ,p_cursor   out sys_refcursor )
    is
    begin
        open p_cursor for
            select decode ( substr ( account, 1, instr ( account, chr ( 1 ) ) - 1 ),
                            '', 'Итого по главе',
                            substr ( account, 1, instr ( account, chr ( 1 ) ) - 1 ) )
                       account
                  ,substr ( account, instr ( account, chr ( 1 ) ) + 1, ( instr ( account, chr ( 2 ) ) - instr ( account, chr ( 1 ) ) - 2 ) )
                       as nameaccount
                  ,balance
                  ,sum ( restb ) restbegin
                  ,sum ( reste ) restend
                  ,sum ( credit ) credit
                  ,sum ( debet ) debet
                  ,grouping ( balance ) groupbal
                  ,substr ( account, instr ( account, chr ( 2 ) ) + 1, instr ( account, chr ( 2 ) ) - 1 ) as branch
            from ( select acc.t_account || chr ( 1 ) || acc.t_nameaccount || chr ( 2 ) || party.t_name account
                         ,acc.t_nameaccount namea
                         ,acc.t_balance balance
                         ,acc.t_branch
                         ,acc.t_department
                         ,acc.t_type_account
                         ,blnc.t_chapter
                         ,rsb_account.resta ( acc.t_account, p_datebegin - 1, acc.t_chapter, 0/*acc.t_r0*/ ) restb
                         ,rsb_account.resta ( acc.t_account, p_dateend, acc.t_chapter, 0/*acc.t_r0*/ ) reste
                         ,rsb_account.kredita ( acc.t_account, acc.t_chapter, p_datebegin, p_dateend ) credit
                         ,rsb_account.debeta ( acc.t_account, acc.t_chapter, p_datebegin, p_dateend ) debet
                   from daccount_dbt acc, daccblnc_dbt blnc, ddp_dep_dbt dp, dparty_dbt party
                   where ( t_open_close = chr ( 0 ) or t_close_date > p_datebegin )
                     and t_open_date <= p_dateend
                     and blnc.t_account = acc.t_account
                     and acc.t_chapter = blnc.t_chapter
                     and acc.t_chapter = blnc.t_chapter
                     and acc.t_usertypeaccount like '%' || p_usertypeaccount || '%'
                     and acc.t_branch = dp.t_code
                     and dp.t_name = p_branch
                     and party.t_partyid = dp.t_partyid
                     and blnc.t_chapter = p_chapter
                     and ( acc.t_type_account not like '%П%' and acc.t_type_account not like '%U%' and acc.t_type_account not like '%Н%' ) )
            --                              where restb > 0 or reste>0
            group by rollup ( balance, account );
    end;

    /*Документы дня*/
    procedure get_balance_mem ( p_code1 in number, p_code2 in number, p_repdate in date, p_cursor out sys_refcursor )
    is
        regvalpay1     varchar2 ( 200 ) := '^30110|^30114|^30115|^47417|^47416';
        -- Настройка по умолчанию
        regvalrec1     varchar2 ( 200 ) := '^30110|^30114|^30115|^47417|^47416';
        -- Настройка по умолчанию
        regvalpay2     varchar2 ( 200 ) := '^47416'; -- Настройка по умолчанию
        regvalrec2     varchar2 ( 200 ) := '^30110|^30114|^30115|^47417|^47416';
        -- Настройка по умолчанию
        regvalpack     varchar2 ( 200 ) := 998; -- Настройка по умолчанию
    begin
        regvalpay1 :=   nvl ( rsb_common.getregstrvalue ( 'PRBB\REPORT\FRONT\ВНУТРЕННИЕ МЕМОРИАЛЬНЫЕ\МАСКА_ПЛАТЕЛЬЩИКА1', 0 ), regvalpay1 );
        regvalrec1 :=   nvl ( rsb_common.getregstrvalue ( 'PRBB\REPORT\FRONT\ВНУТРЕННИЕ МЕМОРИАЛЬНЫЕ\МАСКА_ПОЛУЧАТЕЛЯ1', 0 ), regvalrec1 );
        regvalpay2 :=   nvl ( rsb_common.getregstrvalue ( 'PRBB\REPORT\FRONT\ВНУТРЕННИЕ МЕМОРИАЛЬНЫЕ\МАСКА_ПЛАТЕЛЬЩИКА2', 0 ), regvalpay2 );
        regvalrec2 :=   nvl ( rsb_common.getregstrvalue ( 'PRBB\REPORT\FRONT\ВНУТРЕННИЕ МЕМОРИАЛЬНЫЕ\МАСКА_ПОЛУЧАТЕЛЯ2', 0 ), regvalrec2 );
        regvalpack :=   nvl ( rsb_common.getregstrvalue ( 'PRBB\REPORT\FRONT\ВНУТРЕННИЕ МЕМОРИАЛЬНЫЕ\ПАЧКА_СЧЕТА', 0 ), regvalpack );

        open p_cursor for
            select sum ( sum1 ) result, oper, name1, count ( 1 ) total, 'RUR' as fiid
            from ( --select arh.t_sum as sum1, arh.t_oper as oper, tp.t_name as name1
                   select arh.t_sum_natcur as sum1, arh.t_oper as oper, tp.t_name as name1
                   from --darhdoc_dbt arh
                        dacctrn_dbt arh
                       ,dpmpaym_dbt pmpaym
                       ,doproper_dbt opr
                       ,doprdocs_dbt oprd
                       ,dperson_dbt tp
                       ,dpmrmprop_dbt rm
                   where ( not regexp_like ( arh.t_account_payer, regvalpay1 ) or not regexp_like ( arh.t_account_receiver, regvalrec1 ) )
                     and arh.t_account_payer not like 'ОВП%'
                     and arh.t_account_receiver not like 'ОВП%'
                     and arh.t_chapter = 1
                     and substr ( arh.t_account_payer, 6, 3 ) in ('810')
                     and substr ( arh.t_account_receiver, 6, 3 ) in ('810')
                     and arh.t_result_carry not in (14, 18, 23)
                     and arh.t_number_pack != regvalpack
                     and arh.t_date_carry = p_repdate
                     --                              AND rm.t_shifroper IN ('09', '17')
                     and trim ( arh.t_kind_oper ) in ('6')
                     and tp.t_oper in
                                 ( select t.t_oper
                                  from dop_otdel_dbt t
                                  where t.t_code1 = p_code1
                                    and t.t_code2 = p_code2
                                    and ( t.t_dateend >= p_repdate or t.t_dateend = to_date ( '01.01.0001', 'dd.mm.yyyy' ) )
                                    and t.t_datebegin <= p_repdate )
                     and arh.t_oper = tp.t_oper
                     and opr.t_documentid = pmpaym.t_documentid
                     and oprd.t_id_operation = opr.t_id_operation
                     --and '0000' || arh.t_iapplicationkind || arh.t_applicationkey = oprd.t_documentid
                     and arh.t_acctrnid = oprd.t_acctrnid
                     and rm.t_paymentid = pmpaym.t_paymentid
                     and oprd.t_dockind = 1
                     and oprd.t_origin = 0
                   union all
                   --select arh1.t_sum as sum1, arh1.t_oper as oper, tp1.t_name as name1
                   select arh1.t_sum_natcur as sum1, arh1.t_oper as oper, tp1.t_name as name1
                   --from darhdoc_dbt arh1, dperson_dbt tp1
                   from dacctrn_dbt arh1, dperson_dbt tp1
                   where ( not regexp_like ( arh1.t_account_payer, regvalpay1 ) or not regexp_like ( arh1.t_account_receiver, regvalrec1 ) )
                     and arh1.t_account_payer not like 'ОВП%'
                     and arh1.t_account_receiver not like 'ОВП%'
                     and arh1.t_chapter = 1
                     and substr ( arh1.t_account_payer, 6, 3 ) in ('810')
                     and substr ( arh1.t_account_receiver, 6, 3 ) in ('810')
                     and arh1.t_result_carry not in (14, 18, 23)
                     and arh1.t_number_pack != regvalpack
                     and arh1.t_date_carry = p_repdate
                     --                              AND arh1.t_shifr_oper IN ('09', '17')
                     and trim ( arh1.t_kind_oper ) in ('6')
                     and tp1.t_oper in
                                 ( select t1.t_oper
                                  from dop_otdel_dbt t1
                                  where t1.t_code1 = p_code1
                                    and t1.t_code2 = p_code2
                                    and ( t1.t_dateend >= p_repdate or t1.t_dateend = to_date ( '01.01.0001', 'dd.mm.yyyy' ) )
                                    and t1.t_datebegin <= p_repdate )
                     and arh1.t_oper = tp1.t_oper
                     and not exists
                             (select 1
                              from dpmpaym_dbt pmpaym1, doproper_dbt opr1, doprdocs_dbt oprd1
                              where opr1.t_documentid = pmpaym1.t_documentid
                                and oprd1.t_id_operation = opr1.t_id_operation
                                --and '0000' || arh1.t_iapplicationkind || arh1.t_applicationkey = oprd1.t_documentid
                                and arh1.t_acctrnid = oprd1.t_acctrnid
                                and oprd1.t_dockind = 1
                                and oprd1.t_origin = 0)
                     and arh1.t_fiid_payer = 0
                     and arh1.t_fiid_receiver = 0
                   union all
                   --select arh2.t_sum as sum1, arh2.t_oper as oper, tp2.t_name as name1
                   select arh2.t_sum_natcur as sum1, arh2.t_oper as oper, tp2.t_name as name1
                   from --darhdoc_dbt arh2
                        dacctrn_dbt arh2
                       ,dpmpaym_dbt pmpaym2
                       ,doproper_dbt opr2
                       ,doprdocs_dbt oprd2
                       ,dperson_dbt tp2
                       ,dpmrmprop_dbt rm2
                   where regexp_like ( arh2.t_account_payer, regvalpay2 )
                     and not regexp_like ( arh2.t_account_receiver, regvalrec2 )
                     and arh2.t_account_payer not like 'ОВП%'
                     and arh2.t_account_receiver not like 'ОВП%'
                     and arh2.t_chapter = 1
                     and substr ( arh2.t_account_payer, 6, 3 ) in ('810')
                     and substr ( arh2.t_account_receiver, 6, 3 ) in ('810')
                     and arh2.t_result_carry not in (14, 18, 23)
                     and arh2.t_number_pack != regvalpack
                     and arh2.t_date_carry = p_repdate
                     --                              AND arh2.t_shifr_oper IN ('09', '17')
                     and trim ( arh2.t_kind_oper ) in ('6')
                     and tp2.t_oper in
                                 ( select t2.t_oper
                                  from dop_otdel_dbt t2
                                  where t2.t_code1 = p_code1
                                    and t2.t_code2 = p_code2
                                    and ( t2.t_dateend >= p_repdate or t2.t_dateend = to_date ( '01.01.0001', 'dd.mm.yyyy' ) )
                                    and t2.t_datebegin <= p_repdate )
                     and arh2.t_oper = tp2.t_oper
                     and opr2.t_documentid = pmpaym2.t_documentid
                     and oprd2.t_id_operation = opr2.t_id_operation
                     --and '0000' || arh2.t_iapplicationkind || arh2.t_applicationkey = oprd2.t_documentid
                     and arh2.t_acctrnid = oprd2.t_acctrnid
                     and rm2.t_paymentid = pmpaym2.t_paymentid
                     and oprd2.t_dockind = 1
                     and oprd2.t_origin = 0 
                     and arh2.t_fiid_payer = 0
                     and arh2.t_fiid_receiver = 0)
            group by (oper, name1)
            order by oper;
    end;

    procedure get_client_int ( p_code1 in number, p_code2 in number, p_repdate in date, p_cursor out sys_refcursor )
    is
        regvalpay1     varchar2 ( 200 ) := '^30110|^30114|^30115|^30208|^47416';
        -- Настройка по умолчанию
        regvalrec1     varchar2 ( 200 ) := '^30110|^30114|^30115|^30208';
        -- Настройка по умолчанию
        regvalpay2     varchar2 ( 200 ) := '^47416'; -- Настройка по умолчанию
        regvalrec2     varchar2 ( 200 ) := '^30110|^30114|^30115|^30208';
        -- Настройка по умолчанию
        regvalpack     varchar2 ( 200 ) := 998; -- Настройка по умолчанию
    begin
        regvalpay1 :=   nvl ( rsb_common.getregstrvalue ( 'PRBB\REPORT\FRONT\ВНУТРИКЛИЕНТСКИЕ\МАСКА_ПЛАТЕЛЬЩИКА1', 0 ), regvalpay1 );
        regvalrec1 :=   nvl ( rsb_common.getregstrvalue ( 'PRBB\REPORT\FRONT\ВНУТРИКЛИЕНТСКИЕ\МАСКА_ПОЛУЧАТЕЛЯ1', 0 ), regvalrec1 );
        regvalpay2 :=   nvl ( rsb_common.getregstrvalue ( 'PRBB\REPORT\FRONT\ВНУТРИКЛИЕНТСКИЕ\МАСКА_ПЛАТЕЛЬЩИКА2', 0 ), regvalpay2 );
        regvalrec2 :=   nvl ( rsb_common.getregstrvalue ( 'PRBB\REPORT\FRONT\ВНУТРИКЛИЕНТСКИЕ\МАСКА_ПОЛУЧАТЕЛЯ2', 0 ), regvalrec2 );
        regvalpack :=   nvl ( rsb_common.getregstrvalue ( 'PRBB\REPORT\FRONT\ВНУТРИКЛИЕНТСКИЕ\ПАЧКА_СЧЕТА', 0 ), regvalpack );

        open p_cursor for
            select sum ( sum1 ) result, oper, name1, count ( 1 ) total, 'RUR' as fiid
            from ( --select arh.t_sum as sum1, arh.t_oper as oper, tp.t_name as name1
                   select arh.t_sum_natcur as sum1, arh.t_oper as oper, tp.t_name as name1
                   from --darhdoc_dbt arh
                        dacctrn_dbt arh
                       ,dpmpaym_dbt pmpaym
                       ,doproper_dbt opr
                       ,doprdocs_dbt oprd
                       ,dperson_dbt tp
                       ,dpmrmprop_dbt rm
                   where ( not regexp_like ( arh.t_account_payer, regvalpay1 ) or not regexp_like ( arh.t_account_receiver, regvalrec1 ) )
                     and arh.t_account_payer not like 'ОВП%'
                     and arh.t_account_receiver not like 'ОВП%'
                     and arh.t_chapter = 1
                     and substr ( arh.t_account_payer, 6, 3 ) in ('810')
                     and substr ( arh.t_account_receiver, 6, 3 ) in ('810')
                     and arh.t_result_carry not in (14, 18, 23)
                     and arh.t_number_pack != regvalpack
                     and arh.t_date_carry = p_repdate
                     and rm.t_shifroper in ('01')
                     and trim ( arh.t_kind_oper ) in ('6')
                     and tp.t_oper in
                                 ( select t.t_oper
                                  from dop_otdel_dbt t
                                  where t.t_code1 = p_code1
                                    and t.t_code2 = p_code2
                                    and ( t.t_dateend >= p_repdate or t.t_dateend = to_date ( '01.01.0001', 'dd.mm.yyyy' ) )
                                    and t.t_datebegin <= p_repdate )
                     and arh.t_oper = tp.t_oper
                     and opr.t_documentid = pmpaym.t_documentid
                     and oprd.t_id_operation = opr.t_id_operation
                     --and '0000' || arh.t_iapplicationkind || arh.t_applicationkey = oprd.t_documentid
                     and arh.t_acctrnid = oprd.t_acctrnid
                     and rm.t_paymentid = pmpaym.t_paymentid
                     and oprd.t_dockind = 1
                     and oprd.t_origin = 0
                     and arh.t_fiid_payer = 0
                     and arh.t_fiid_receiver = 0
                   union all
                   --select arh1.t_sum as sum1, arh1.t_oper as oper, tp1.t_name as name1
                   --from darhdoc_dbt arh1, dperson_dbt tp1
                   select arh1.t_sum_natcur as sum1, arh1.t_oper as oper, tp1.t_name as name1
                   from dacctrn_dbt arh1, dperson_dbt tp1
                   where ( not regexp_like ( arh1.t_account_payer, regvalpay1 ) or not regexp_like ( arh1.t_account_receiver, regvalrec1 ) )
                     and arh1.t_account_payer not like 'ОВП%'
                     and arh1.t_account_receiver not like 'ОВП%'
                     and arh1.t_chapter = 1
                     and substr ( arh1.t_account_payer, 6, 3 ) in ('810')
                     and substr ( arh1.t_account_receiver, 6, 3 ) in ('810')
                     and arh1.t_result_carry not in (14, 18, 23)
                     and arh1.t_number_pack != regvalpack
                     and arh1.t_date_carry = p_repdate
                     and arh1.t_shifr_oper in ('01')
                     and trim ( arh1.t_kind_oper ) in ('6')
                     and tp1.t_oper in
                                 ( select t1.t_oper
                                  from dop_otdel_dbt t1
                                  where t1.t_code1 = p_code1
                                    and t1.t_code2 = p_code2
                                    and ( t1.t_dateend >= p_repdate or t1.t_dateend = to_date ( '01.01.0001', 'dd.mm.yyyy' ) )
                                    and t1.t_datebegin <= p_repdate )
                     and arh1.t_oper = tp1.t_oper
                     and not exists
                             (select 1
                              from dpmpaym_dbt pmpaym1, doproper_dbt opr1, doprdocs_dbt oprd1
                              where opr1.t_documentid = pmpaym1.t_documentid
                                and oprd1.t_id_operation = opr1.t_id_operation
                                --and '0000' || arh1.t_iapplicationkind || arh1.t_applicationkey = oprd1.t_documentid
                                and arh1.t_acctrnid = oprd1.t_acctrnid
                                and oprd1.t_dockind = 1
                                and oprd1.t_origin = 0)
                     and arh1.t_fiid_payer = 0
                     and arh1.t_fiid_receiver = 0
                   union all
                   --select arh2.t_sum as sum1, arh2.t_oper as oper, tp2.t_name as name1
                   select arh2.t_sum_natcur as sum1, arh2.t_oper as oper, tp2.t_name as name1
                   from --darhdoc_dbt arh2
                        dacctrn_dbt arh2
                       ,dpmpaym_dbt pmpaym2
                       ,doproper_dbt opr2
                       ,doprdocs_dbt oprd2
                       ,dperson_dbt tp2
                       ,dpmrmprop_dbt rm2
                   where ( regexp_like ( arh2.t_account_payer, regvalpay2 ) and not regexp_like ( arh2.t_account_receiver, regvalrec2 ) )
                     and arh2.t_account_payer not like 'ОВП%'
                     and arh2.t_account_receiver not like 'ОВП%'
                     and arh2.t_chapter = 1
                     and substr ( arh2.t_account_payer, 6, 3 ) in ('810')
                     and substr ( arh2.t_account_receiver, 6, 3 ) in ('810')
                     and arh2.t_result_carry not in (14, 18, 23)
                     and arh2.t_number_pack != regvalpack
                     and arh2.t_date_carry = p_repdate
                     and arh2.t_shifr_oper in ('01')
                     and trim ( arh2.t_kind_oper ) in ('6')
                     and tp2.t_oper in
                                 ( select t2.t_oper
                                  from dop_otdel_dbt t2
                                  where t2.t_code1 = p_code1
                                    and t2.t_code2 = p_code2
                                    and ( t2.t_dateend >= p_repdate or t2.t_dateend = to_date ( '01.01.0001', 'dd.mm.yyyy' ) )
                                    and t2.t_datebegin <= p_repdate )
                     and arh2.t_oper = tp2.t_oper
                     and opr2.t_documentid = pmpaym2.t_documentid
                     and oprd2.t_id_operation = opr2.t_id_operation
                     --and '0000' || arh2.t_iapplicationkind || arh2.t_applicationkey = oprd2.t_documentid
                     and arh2.t_acctrnid = oprd2.t_acctrnid
                     and rm2.t_paymentid = pmpaym2.t_paymentid
                     and oprd2.t_dockind = 1
                     and oprd2.t_origin = 0 
                     and arh2.t_fiid_payer = 0
                     and arh2.t_fiid_receiver = 0)
            group by (oper, name1)
            order by oper;
    end;

    procedure get_curr_mem ( p_code1 in number, p_code2 in number, p_repdate in date, p_cursor out sys_refcursor )
    is
        regvalpay1     varchar2 ( 200 ) := '^30110|^30114|^30115';
        -- Настройка по умолчанию
        regvalrec1     varchar2 ( 200 ) := '^30110|^30114|^30115|^47416|^47417';
        -- Настройка по умолчанию
        regvalpack     varchar2 ( 200 ) := 998; -- Настройка по умолчанию
    begin
        regvalpay1 :=   nvl ( rsb_common.getregstrvalue ( 'PRBB\REPORT\FRONT\ВАЛЮТА ВНУТРЕННИЕ\МАСКА_ПЛАТЕЛЬЩИКА1', 0 ), regvalpay1 );
        regvalrec1 :=   nvl ( rsb_common.getregstrvalue ( 'PRBB\REPORT\FRONT\ВАЛЮТА ВНУТРЕННИЕ\МАСКА_ПОЛУЧАТЕЛЯ1', 0 ), regvalrec1 );
        regvalpack :=   nvl ( rsb_common.getregstrvalue ( 'PRBB\REPORT\FRONT\ВАЛЮТА ВНУТРЕННИЕ\ПАЧКА_СЧЕТА', 0 ), regvalpack );

        -- KS 28.11.2013 Перенос пользовательских доработок в 31ю сборку
        open p_cursor for
            select sum ( sum1 ) result
                  ,oper
                  ,name1
                  ,count ( 1 ) total
                  ,fiid
                  ,rsb_fiinstr.convsum ( sum ( sum1 ), fi, 0, p_repdate, 1 ) as sumrur
            from ( --select arh.t_sum as sum1, arh.t_oper as oper, tp.t_name as name1, fi.t_ccy as fiid, fi.t_fiid as fi
                   select arh.t_sum_payer as sum1, arh.t_oper as oper, tp.t_name as name1, fi.t_ccy as fiid, fi.t_fiid as fi
                   from --darhdoc$_dbt arh
                        dacctrn_dbt arh
                       ,dpmpaym_dbt pmpaym
                       ,doproper_dbt opr
                       ,doprdocs_dbt oprd
                       ,dperson_dbt tp
                       ,dpmrmprop_dbt rm
                       ,dfininstr_dbt fi
                   where ( not regexp_like ( arh.t_account_payer, regvalpay1 ) or not regexp_like ( arh.t_account_receiver, regvalrec1 ) )
                     and arh.t_account_payer not like 'ОВП%'
                     and arh.t_account_receiver not like 'ОВП%'
                     and arh.t_chapter = 1
                     and arh.t_result_carry not in (14, 18, 23)
                     and arh.t_number_pack != regvalpack
                     and arh.t_date_carry = p_repdate
                     and rm.t_shifroper in ('09', '17')
                     and trim ( arh.t_kind_oper ) in ('6')
                     and tp.t_oper in
                                 ( select t.t_oper
                                  from dop_otdel_dbt t
                                  where t.t_code1 = p_code1
                                    and t.t_code2 = p_code2
                                    and ( t.t_dateend >= p_repdate or t.t_dateend = to_date ( '01.01.0001', 'dd.mm.yyyy' ) )
                                    and t.t_datebegin <= p_repdate )
                     and arh.t_oper = tp.t_oper
                     and opr.t_documentid = pmpaym.t_documentid
                     and oprd.t_id_operation = opr.t_id_operation
                     --and '0000' || arh.t_iapplicationkind || arh.t_applicationkey = oprd.t_documentid
                     and arh.t_acctrnid = oprd.t_acctrnid
                     and rm.t_paymentid = pmpaym.t_paymentid
                     and oprd.t_dockind = 1
                     and oprd.t_origin = 0
                     and fi.t_fi_kind = 1
                     and fi.t_fiid <> 0
                     --and arh.t_code_currency = fi.t_fiid
                     and arh.t_fiid_payer = fi.t_fiid
                     and (arh.t_fiid_payer != 0 or arh.t_fiid_receiver != 0)
                   union all
                   --select arh1.t_sum as sum1, arh1.t_oper as oper, tp1.t_name as name1, fi1.t_ccy as fiid, fi1.t_fiid as fi
                   --from darhdoc$_dbt arh1, dperson_dbt tp1, dfininstr_dbt fi1
                   select arh1.t_sum_payer as sum1, arh1.t_oper as oper, tp1.t_name as name1, fi1.t_ccy as fiid, fi1.t_fiid as fi
                   from dacctrn_dbt arh1, dperson_dbt tp1, dfininstr_dbt fi1
                   where ( not regexp_like ( arh1.t_account_payer, regvalpay1 ) or not regexp_like ( arh1.t_account_receiver, regvalrec1 ) )
                     and arh1.t_account_payer not like 'ОВП%'
                     and arh1.t_account_receiver not like 'ОВП%'
                     and arh1.t_chapter = 1
                     and arh1.t_result_carry not in (14, 18, 23)
                     and arh1.t_number_pack != regvalpack
                     and arh1.t_date_carry = p_repdate
                     --                              AND arh1.t_shifr_oper IN ('09', '17')
                     and trim ( arh1.t_kind_oper ) in ('6')
                     and tp1.t_oper in
                                 ( select t1.t_oper
                                  from dop_otdel_dbt t1
                                  where t1.t_code1 = p_code1
                                    and t1.t_code2 = p_code2
                                    and ( t1.t_dateend >= p_repdate or t1.t_dateend = to_date ( '01.01.0001', 'dd.mm.yyyy' ) )
                                    and t1.t_datebegin <= p_repdate )
                     and arh1.t_oper = tp1.t_oper
                     and not exists
                             (select 1
                              from dpmpaym_dbt pmpaym1, doproper_dbt opr1, doprdocs_dbt oprd1
                              where opr1.t_documentid = pmpaym1.t_documentid
                                and oprd1.t_id_operation = opr1.t_id_operation
                                --and '0000' || arh1.t_iapplicationkind || arh1.t_applicationkey = oprd1.t_documentid
                                and arh1.t_acctrnid = oprd1.t_acctrnid
                                and oprd1.t_dockind = 1
                                and oprd1.t_origin = 0)
                     and fi1.t_fi_kind = 1
                     and fi1.t_fiid <> 0
                     --and arh1.t_code_currency = fi1.t_fiid 
                     and arh1.t_fiid_payer = fi1.t_fiid
                     and (arh1.t_fiid_payer != 0 or arh1.t_fiid_receiver != 0))
            group by (oper, name1, fiid, fi)
            order by fiid desc, oper;
    end;

    -- KS 28.11.2013 Перенос пользовательских доработок в 31ю сборку
    procedure get_curr_conv ( p_code1 in number, p_code2 in number, p_repdate in date, p_cursor out sys_refcursor )
    is
    begin
        open p_cursor for
            select 0 as result, arh.t_oper, tp.t_name as name1, count ( distinct ( pm.t_paymentid ) ) total, '' as fiid
            --from dpmdocs_dbt pm, darhdoc$_dbt arh, dperson_dbt tp, dfininstr_dbt fi
            from dpmdocs_dbt pm, dacctrn_dbt arh, dperson_dbt tp, dfininstr_dbt fi
            where --pm.t_applicationkey = arh.t_applicationkey
              --and pm.t_applicationkind = arh.t_iapplicationkind
              /*and*/ pm.t_acctrnid = arh.t_acctrnid
              and arh.t_date_carry = p_repdate
              and arh.t_chapter = 1
              and ( arh.t_account_payer like 'ОВП%' or arh.t_account_receiver like 'ОВП%' )
              and arh.t_oper in
                          ( select t.t_oper
                           from dop_otdel_dbt t
                           where t.t_code1 = p_code1
                             and t.t_code2 = p_code2
                             and ( t.t_dateend >= p_repdate or t.t_dateend = to_date ( '01.01.0001', 'dd.mm.yyyy' ) )
                             and t.t_datebegin <= p_repdate )
              and arh.t_oper = tp.t_oper
              and fi.t_fi_kind = 1
              and fi.t_fiid <> 0
              --and arh.t_code_currency = fi.t_fiid
              and arh.t_fiid_payer = fi.t_fiid
              and (arh.t_fiid_payer != 0 or arh.t_fiid_receiver != 0)
            group by tp.t_name, arh.t_oper
            order by t_oper;
    end;

    procedure get_chap3 ( p_code1 in number, p_code2 in number, p_repdate in date, p_cursor out sys_refcursor )
    is
        regvalpack     varchar2 ( 200 ) := 998; -- Настройка по умолчанию
    begin
        regvalpack :=   nvl ( rsb_common.getregstrvalue ( 'PRBB\REPORT\FRONT\КОНВЕРСИОННЫЕ\ПАЧКА_СЧЕТА', 0 ), regvalpack );

        -- KS 28.11.2013 Перенос пользовательских доработок в 31ю сборку
        open p_cursor for
            --select sum ( arh.t_sum ) as result, arh.t_oper as oper, tp.t_name, count ( 1 ) as total, 'RUR' as fiid
            select sum ( arh.t_sum_natcur ) as result, arh.t_oper as oper, tp.t_name, count ( 1 ) as total, 'RUR' as fiid
            --from darhdoc_dbt arh, dperson_dbt tp
            from dacctrn_dbt arh, dperson_dbt tp
            where arh.t_chapter = 3
              and substr ( arh.t_account_payer, 6, 3 ) in ('810')
              and substr ( arh.t_account_receiver, 6, 3 ) in ('810')
              and arh.t_result_carry not in (14, 18, 23)
              and arh.t_number_pack != regvalpack
              and arh.t_date_carry = p_repdate
              and tp.t_oper in
                          ( select t.t_oper
                           from dop_otdel_dbt t
                           where t.t_code1 = p_code1
                             and t.t_code2 = p_code2
                             and ( t.t_dateend >= p_repdate or t.t_dateend = to_date ( '01.01.0001', 'dd.mm.yyyy' ) )
                             and t.t_datebegin <= p_repdate )
              and arh.t_oper = tp.t_oper
              and arh.t_fiid_payer = 0
              and arh.t_fiid_receiver = 0
            group by (arh.t_oper, tp.t_name)
            order by oper;
    end;

    /*Выписка по внебалансовым счетам*/
    procedure get_vbs ( p_dep in    varchar2
                       ,p_chapt in  number
                       ,p_symb in   varchar2
                       ,p_datebegin in date
                       ,p_dateend in date
                       ,p_cursor   out sys_refcursor )
    is
    begin
        -- KS 28.11.2013 Перенос пользовательских доработок в 31ю сборку
        open p_cursor for
            select acc.t_account
                  ,acc.t_oper
                  --,rest.t_date_value
                  ,rest.t_restdate t_date_value
                  ,acc.t_nameaccount
                  ,abs ( rsb_account.resta ( acc.t_account, p_datebegin - 1, acc.t_chapter, 0/*acc.t_r0*/ ) ) as resta
                  ,abs ( rsb_account.resta ( acc.t_account, p_dateend, acc.t_chapter, 0/*acc.t_r0*/ ) ) as restb
                  ,abs ( rsb_account.debeta ( acc.t_account, acc.t_chapter, p_datebegin, p_dateend ) ) as sumdeb
                  ,abs ( rsb_account.kredita ( acc.t_account, acc.t_chapter, p_datebegin, p_dateend ) ) as sumkr
                  ,arh.t_shifr_oper
                  ,arh.t_numb_document
                  ,obj.t_code
                  ,case
                       when acc.t_kind_account = 'А' and acc.t_account = arh.t_account_receiver then arh.t_account_payer
                       when acc.t_kind_account = 'П' and acc.t_account = arh.t_account_payer then arh.t_account_receiver
                       else arh.t_account_receiver
                   end
                       корр
                  ,case
                       when acc.t_kind_account = 'А' and acc.t_account = arh.t_account_payer then null
                       when acc.t_kind_account = 'П' and acc.t_account = arh.t_account_receiver then null
                       --else arh.t_sum
                       else arh.t_sum_receiver
                   end
                       кредит
                  ,case
                       when acc.t_kind_account = 'А' and acc.t_account = arh.t_account_receiver then null
                       when acc.t_kind_account = 'П' and acc.t_account = arh.t_account_payer then null
                       --else arh.t_sum
                       else arh.t_sum_payer
                   end
                       дебет
                  ,arh.t_ground
            from daccount_dbt acc
                ,daccblnc_dbt blnc
                --,darhdoc_dbt arh
                ,dacctrn_dbt arh
                ,dobjcode_dbt obj
                ,dpmdocs_dbt doc
                ,dpmpaym_dbt pm
                ,ddp_dep_dbt dp
                ,drestdate_dbt rest
            where acc.t_usertypeaccount like '%' || p_symb || '%'
              and ( acc.t_type_account not like '%П%' and acc.t_type_account not like '%U%' and acc.t_type_account not like '%Н%' )
              and blnc.t_account = acc.t_account
              and acc.t_chapter = p_chapt
              and acc.t_branch = dp.t_code
              and dp.t_name = p_dep
              and blnc.t_chapter = acc.t_chapter
              and blnc.t_balance0 = acc.t_balance
              and arh.t_date_carry between p_datebegin and p_dateend
              and ( acc.t_account = arh.t_account_receiver or acc.t_account = arh.t_account_payer )
              and obj.t_codekind = 3
              and obj.t_objecttype = 3
              and obj.t_state = 0
              and obj.t_objectid = case when t_kind_account = 'А' then pm.t_payerbankid else pm.t_receiverbankid end
              --and arh.t_applicationkey = doc.t_applicationkey
              --and arh.t_iapplicationkind = doc.t_applicationkind
              and arh.t_acctrnid = doc.t_acctrnid
              and pm.t_paymentid = doc.t_paymentid
              --and rest.t_account = acc.t_account
              and rest.t_accountid = acc.t_accountid
              --and rest.t_chapter = acc.t_chapter
              --and rest.t_date_value =
              and rest.t_restdate =
                      nvl ( ( --select max ( t_date_value )
                              select max ( t_restdate )
                                from drestdate_dbt r
                               --where r.t_account = acc.t_account and r.t_date_value < p_datebegin and r.t_chapter = acc.t_chapter )
                               where r.t_accountid = acc.t_accountid and r.t_restdate < p_datebegin)
                           ,p_datebegin )
              and arh.t_fiid_payer = 0
              and arh.t_fiid_receiver = 0
            --order by acc.t_account, ДЕБЕТ nulls first, КРЕДИТ, arh.t_sum;
            order by acc.t_account, ДЕБЕТ nulls first, КРЕДИТ, arh.t_sum_natcur;
    end;

    /*Внешние документы*/
    procedure get_bbdoc ( p_oper in number, p_numberpack in number, p_repdate in date, p_cursor out sys_refcursor )
    is
    begin
        open p_cursor for
            select rm.t_number
                  ,obj.t_code
                  ,pmpaym.t_payeraccount
                  ,pmpaym.t_receiveraccount
                  ,pmpaym.t_numberpack
                  ,pmpaym.t_amount
                  ,rm.t_ground
                  ,pmprop.t_transferdate
                  , -- 27.12.2012 Golovkin C-16337 добавлено поле "Сеанс отправки"
                   nvl (
                         ( select    'Платёж был отправлен '
                                  || mes.t_outsideabonentdate
                                  || ' '
                                  || to_char ( mes.t_outsideabonenttime, 'hh24:mi:ss' )
                                  || '  сеансом №'
                                  || ses.t_number
                                  || '. ID платежа в сеансе  '
                                  || mes.t_mesid
                          from dwlpm_dbt wlp, dwlmeslnk_dbt lnk, dwlmes_dbt mes, dwlsess_dbt ses
                          where wlp.t_paymentid = pmpaym.t_paymentid
                            and lnk.t_objkind = '501'
                            and lnk.t_objid = wlp.t_wlpmid
                            and mes.t_mesid = lnk.t_mesid
                            and ses.t_sessionid = mes.t_sessionid
                            and ses.t_direct != 'X' )
                        , -- исходящие
                         'Отсутствуют данные в программе RS-Bank'
                   )
                       as sess
            from doproper_dbt opr
                ,dpmprop_dbt pmprop
                ,dpmpaym_dbt pmpaym
                ,dpmrmprop_dbt rm
                ,dobjcode_dbt obj
                ,doprcurst_dbt curst
                ,doprcurst_dbt curst1
            where pmprop.t_group = 1
              and curst.t_id_operation = opr.t_id_operation
              and curst.t_statuskindid = 296
              and obj.t_codekind = 3
              and obj.t_objecttype = 3
              and obj.t_objectid = pmpaym.t_payerbankid
              and pmprop.t_issender = chr ( 0 )
              and pmpaym.t_fiid = 0
              and pmpaym.t_dockind = opr.t_dockind
              and ( curst.t_numvalue = 1 or curst.t_numvalue = 2 )
              and ( 1 = case
                            when p_numberpack is null then 1
                            when pmpaym.t_numberpack = p_numberpack then 1
                            else 0
                        end )
              and ( 1 = case
                            when p_oper is null then 1
                            when pmpaym.t_oper = p_oper then 1
                            else 0
                        end )
              and pmpaym.t_paymentid = rm.t_paymentid
              and pmprop.t_transferdate = p_repdate
              and pmpaym.t_paymentid = pmprop.t_paymentid
              and opr.t_documentid = lpad ( to_char ( pmpaym.t_paymentid ), 34, '0' )
              and curst1.t_id_operation = opr.t_id_operation
              and curst1.t_statuskindid = 292
              and curst1.t_numvalue in (2, 4, 5, 9, 24);
    end;

    /*Кусор по ОргСтруктуре*/
    procedure get_dotdels_dbt ( p_cursor out sys_refcursor )
    is
    begin
        open p_cursor for
            select dotdels_dbt.t_code1, dotdels_dbt.t_code2, dotdels_dbt.t_name
            from dotdels_dbt
            order by t_name;
    end;

    /*Реестр платежей банка*/
    procedure get_invent ( p_code1 in number, p_code2 in number, p_code_curr in varchar2, p_repdate in date, p_cursor out sys_refcursor )
    is
        regvalpay1     varchar2 ( 200 )
                := '30110*,30114*,30118*,30119*,30202*,30204*,30208*,30210*,30211*,30213*,30220*,30221*,30222*,30223*,30224*,30228*,47416*,47417*' ; -- Настройка по умолчанию
        regvalpay2     varchar2 ( 200 ) := '30301*,30302*,30305*,30306*';
        -- Настройка по умолчанию
        regvalpay3     varchar2 ( 200 ) := '30109*,30111*,30122*,30123*,30231*,401-408,40911*,40912*,40913*, 410-426'; -- Настройка по умолчанию
        regvalpay4     varchar2 ( 200 ) := '30109*,30111*,30122*,30123*,30231*,401-408,40911*,40912*,40913*, 410-426'; -- Настройка по умолчанию
        regvalrec4     varchar2 ( 200 ) := '47423*,47422*,60312*,60311*';
        -- Настройка по умолчанию
        regvalcash     varchar2 ( 200 ) := '^20202|^20203|^20207';
    -- Настройка по умолчанию
    begin
        regvalpay1 :=   nvl ( rsb_common.getregstrvalue ( 'PRBB\REPORT\FRONT\РЕЕСТР\МАСКА_НОСТРО', 0 ), regvalpay1 );
        regvalpay2 :=   nvl ( rsb_common.getregstrvalue ( 'PRBB\REPORT\FRONT\РЕЕСТР\МАСКА_МФР', 0 ), regvalpay2 );
        regvalpay3 :=   nvl ( rsb_common.getregstrvalue ( 'PRBB\REPORT\FRONT\РЕЕСТР\МАСКА_КЛИЕНТ', 0 ), regvalpay3 );
        regvalpay4 :=   nvl ( rsb_common.getregstrvalue ( 'PRBB\REPORT\FRONT\РЕЕСТР\МАСКА_БАНК', 0 ), regvalpay4 );
        regvalrec4 :=   nvl ( rsb_common.getregstrvalue ( 'PRBB\REPORT\FRONT\РЕЕСТР\МАСКА_ПОЛУЧАТ_БАНК', 0 ), regvalrec4 );
        regvalcash :=   nvl ( rsb_common.getregstrvalue ( 'PRBB\REPORT\FRONT\РЕЕСТР\МАСКА_КАССА', 0 ), regvalcash );

        -- KS 28.11.2013 Перенос пользовательских доработок в 31ю сборку
        if ( p_code_curr = '810' )
        then
            open p_cursor for
                select count ( 1 ) as cnt
                      ,sum ( sum ) as amount
                      ,0 as cur
                      ,nvl ( type, 'Всего' ) as typ
                      ,decode ( orig, 1, 'Э', 0, 'Б', 'Все' ) as arch
                from ( select distinct
                              dotdels_dbt.t_code1
                             ,dotdels_dbt.t_code2
                             ,dotdels_dbt.t_name as name_otdel
                             ,arh.t_oper
                             ,arh.t_numb_document as numdoc
                             ,arh.t_account_payer as accdeb
                             ,acc1.t_nameaccount name1
                             ,arh.t_account_receiver as acckr
                             ,acc2.t_nameaccount name2
                             --,arh.t_sum as sum
                             ,arh.t_sum_natcur as sum
                             ,arh.t_shifr_oper || '/' || t_kind_oper sh
                             ,arh.t_ground as ground
                             --,arh.t_iapplicationkind as appkind
                             --,arh.t_applicationkey appkey
                             ,arh.t_acctrnid
                             ,arh.t_typedocument
                             ,prop.t_paymentkind paymkind
                             ,user_ea.getorigin ( paym.t_dockind, paym.t_paymentid ) origin
                             ,arh.t_chapter chapter
                             ,paym.t_dockind dockind
                             ,arh.t_number_pack numb_pack
                             ,arh.t_shifr_oper shifr_oper
                             ,paym.t_fiid cred_fiid
                             ,paym.t_payfiid deb_fiid
                             --,arh.t_code_currency
                             ,arh.t_fiid_payer t_code_currency
                             ,case
                                  when ( rsb_mask.comparestringwithmask ( regvalpay1, arh.t_account_payer ) = 1 )
                                    or ( rsb_mask.comparestringwithmask ( regvalpay1, arh.t_account_receiver ) = 1 )
                                  then
                                      'НОСТРО'
                                  when ( rsb_mask.comparestringwithmask ( regvalpay2, arh.t_account_payer ) = 1 )
                                    or ( rsb_mask.comparestringwithmask ( regvalpay2, arh.t_account_receiver ) = 1 )
                                  then
                                      'МФР'
                                  when ( ( rsb_mask.comparestringwithmask ( regvalpay3, arh.t_account_payer ) = 1 )
                                    and ( rsb_mask.comparestringwithmask ( regvalpay3, arh.t_account_receiver ) = 1 ) )
                                  then
                                      'Внутриклиентские'
                                  when ( ( rsb_mask.comparestringwithmask ( regvalpay4, arh.t_account_payer ) = 1 )
                                    and ( rsb_mask.comparestringwithmask ( regvalpay4, arh.t_account_receiver ) = 0 ) )
                                    or ( ( rsb_mask.comparestringwithmask ( regvalrec4, arh.t_account_payer ) = 1 )
                                    and ( rsb_mask.comparestringwithmask ( regvalpay4, arh.t_account_receiver ) = 1 ) )
                                  then
                                      'Внутрибанковские'
                                  else
                                      'Внутренние ордера'
                              end
                                  as type
                             , ( select storekind
                                from table ( user_ea.get_dev_prop ( paym.t_dockind
                                                                   ,user_ea.getorigin ( paym.t_dockind, paym.t_paymentid )
                                                                   ,prop.t_paymentkind
                                                                   ,arh.t_shifr_oper
                                                                   ,arh.t_number_pack
                                                                   ,arh.t_chapter
                                                                   ,arh.t_typedocument
                                                                   ,arh.t_account_payer
                                                                   --,arh.t_code_currency
                                                                   ,arh.t_fiid_payer
                                                                   ,arh.t_account_receiver
                                                                   --,arh.t_code_currency
                                                                   ,arh.t_fiid_receiver
                                                                   ,null ) ) )
                                  as orig
                       from --darhdoc_dbt arh
                            dacctrn_dbt arh
                           ,dpmdocs_dbt docs
                           ,dpmpaym_dbt paym
                           ,daccount_dbt acc1
                           ,daccount_dbt acc2
                           ,dop_otdel_dbt
                           ,dotdels_dbt
                           ,dpmrmprop_dbt prop
                       where arh.t_date_carry = p_repdate
                         and ( dop_otdel_dbt.t_dateend >= p_repdate or t_dateend = to_date ( '01.01.0001', 'DD.MM.YYYY' ) )
                         --AND  p_repdate between   DOP_OTDEL_DBT.t_datebegin and nvl(DOP_OTDEL_DBT.t_dateend,p_repdate)
                         and t_datebegin <= p_repdate
                         and acc1.t_account = arh.t_account_payer
                         and acc2.t_account = arh.t_account_receiver
                         and arh.t_chapter = acc1.t_chapter
                         and acc1.t_chapter = acc2.t_chapter
                         and arh.t_chapter = 1
                         --and arh.t_applicationkey = docs.t_applicationkey(+)
                         and arh.t_acctrnid = docs.t_acctrnid(+)
                         and arh.t_fiid_payer = 0
                         and arh.t_fiid_receiver = 0
                         and docs.t_paymentid = paym.t_paymentid(+)
                         and prop.t_paymentid(+) = paym.t_paymentid
                         and substr ( arh.t_account_payer, 6, 3 ) = '810'
                         and substr ( arh.t_account_receiver, 6, 3 ) = '810'
                         and not regexp_like ( arh.t_account_payer, regvalcash )
                         and not regexp_like ( arh.t_account_receiver, regvalcash )
                         and arh.t_oper = dop_otdel_dbt.t_oper
                         and dop_otdel_dbt.t_code1 = dotdels_dbt.t_code1
                         and dop_otdel_dbt.t_code2 = dotdels_dbt.t_code2
                         and dotdels_dbt.t_code1 = p_code1
                         and dotdels_dbt.t_code2 = p_code2
                         and ( exists
                                  (select 1
                                   from dpmprop_dbt deb, dpmprop_dbt cred
                                   where cred.t_paymentid = docs.t_paymentid
                                     and deb.t_paymentid = docs.t_paymentid
                                     and deb.t_paymentid = cred.t_paymentid
                                     and deb.t_debetcredit = 0
                                     and cred.t_debetcredit = 1
                                     and cred.t_group <> 1
                                     and deb.t_group <> 1)
                           or docs.t_paymentid is null ) ) a
                group by rollup ( type, orig )
                order by type desc nulls last, orig nulls last;
        else
            open p_cursor for
                select count ( 1 ) as cnt
                      ,0 as amount
                      ,sum ( sum ) as cur
                      ,nvl ( type, 'Всего' ) as typ
                      ,decode ( orig, 1, 'Э', 0, 'Б', 'Все' ) as arch
                from ( select distinct
                              dotdels_dbt.t_code1
                             ,dotdels_dbt.t_code2
                             ,dotdels_dbt.t_name as name_otdel
                             ,arh.t_oper
                             ,arh.t_numb_document as numdoc
                             ,arh.t_account_payer as accdeb
                             ,acc1.t_nameaccount name1
                             ,arh.t_account_receiver as acckr
                             ,acc2.t_nameaccount name2
                             --,rsb_fiinstr.convsum ( arh.t_sum, arh.t_code_currency, 0, p_repdate, 1 ) as sum
                             ,arh.t_sum_natcur as sum
                             ,arh.t_shifr_oper || '/' || t_kind_oper sh
                             ,arh.t_ground as ground
                             --,arh.t_iapplicationkind as appkind
                             --,arh.t_applicationkey appkey
                             ,arh.t_acctrnid
                             ,arh.t_typedocument
                             ,prop.t_paymentkind paymkind
                             ,user_ea.getorigin ( paym.t_dockind, paym.t_paymentid ) origin
                             ,arh.t_chapter chapter
                             ,paym.t_dockind dockind
                             ,arh.t_number_pack numb_pack
                             ,arh.t_shifr_oper shifr_oper
                             ,paym.t_fiid cred_fiid
                             ,paym.t_payfiid deb_fiid
                             --,arh.t_code_currency
                             ,arh.t_fiid_payer t_code_currency
                             ,case
                                  when ( rsb_mask.comparestringwithmask ( regvalpay1, arh.t_account_payer ) = 1 )
                                    or ( rsb_mask.comparestringwithmask ( regvalpay1, arh.t_account_receiver ) = 1 )
                                  then
                                      'НОСТРО'
                                  when ( rsb_mask.comparestringwithmask ( regvalpay2, arh.t_account_payer ) = 1 )
                                    or ( rsb_mask.comparestringwithmask ( regvalpay2, arh.t_account_receiver ) = 1 )
                                  then
                                      'МФР'
                                  when ( ( rsb_mask.comparestringwithmask ( regvalpay3, arh.t_account_payer ) = 1 )
                                    and ( rsb_mask.comparestringwithmask ( regvalpay3, arh.t_account_receiver ) = 1 ) )
                                  then
                                      'Внутриклиентские'
                                  when ( ( rsb_mask.comparestringwithmask ( regvalpay4, arh.t_account_payer ) = 1 )
                                    and ( rsb_mask.comparestringwithmask ( regvalpay4, arh.t_account_receiver ) = 0 ) )
                                    or ( ( rsb_mask.comparestringwithmask ( regvalrec4, arh.t_account_payer ) = 1 )
                                    and ( rsb_mask.comparestringwithmask ( regvalpay4, arh.t_account_receiver ) = 1 ) )
                                  then
                                      'Внутрибанковские'
                                  else
                                      'Внутренние ордера'
                              end
                                  as type
                             , ( select storekind
                                from table ( user_ea.get_dev_prop ( paym.t_dockind
                                                                   ,user_ea.getorigin ( paym.t_dockind, paym.t_paymentid )
                                                                   ,prop.t_paymentkind
                                                                   ,arh.t_shifr_oper
                                                                   ,arh.t_number_pack
                                                                   ,arh.t_chapter
                                                                   ,arh.t_typedocument
                                                                   ,arh.t_account_payer
                                                                   --,arh.t_code_currency
                                                                   ,arh.t_fiid_payer
                                                                   ,arh.t_account_receiver
                                                                   --,arh.t_code_currency
                                                                   ,arh.t_fiid_receiver
                                                                   ,null ) ) )
                                  as orig
                       from --darhdoc$_dbt arh
                            dacctrn_dbt arh
                           ,dpmdocs_dbt docs
                           ,dpmpaym_dbt paym
                           ,daccount_dbt acc1
                           ,daccount_dbt acc2
                           ,dop_otdel_dbt
                           ,dotdels_dbt
                           ,dpmrmprop_dbt prop
                           ,dfininstr_dbt fin
                       where arh.t_date_carry = p_repdate
                         and ( dop_otdel_dbt.t_dateend >= p_repdate or t_dateend = to_date ( '01.01.0001', 'DD.MM.YYYY' ) )
                         --and fin.t_fiid = arh.t_code_currency
                         and fin.t_fiid = arh.t_fiid_payer
                         and fin.t_fi_code = p_code_curr
                         --AND  p_repdate between   DOP_OTDEL_DBT.t_datebegin and nvl(DOP_OTDEL_DBT.t_dateend,p_repdate)
                         and t_datebegin <= p_repdate
                         and acc1.t_account = arh.t_account_payer
                         and acc2.t_account = arh.t_account_receiver
                         and arh.t_chapter = acc1.t_chapter
                         and acc1.t_chapter = acc2.t_chapter
                         and arh.t_chapter = 1
                         --and arh.t_applicationkey = docs.t_applicationkey(+)
                         and arh.t_acctrnid = docs.t_acctrnid(+)
                         and (arh.t_fiid_payer != 0 or arh.t_fiid_receiver != 0)
                         and docs.t_paymentid = paym.t_paymentid(+)
                         and prop.t_paymentid(+) = paym.t_paymentid
                         and substr ( arh.t_account_payer, 6, 3 ) = substr ( arh.t_account_receiver, 6, 3 )
                         and not regexp_like ( arh.t_account_payer, regvalcash )
                         and not regexp_like ( arh.t_account_receiver, regvalcash )
                         and arh.t_oper = dop_otdel_dbt.t_oper
                         and dop_otdel_dbt.t_code1 = dotdels_dbt.t_code1
                         and dop_otdel_dbt.t_code2 = dotdels_dbt.t_code2
                         and dotdels_dbt.t_code1 = p_code1
                         and dotdels_dbt.t_code2 = p_code2
                         and ( exists
                                  (select 1
                                   from dpmprop_dbt deb, dpmprop_dbt cred
                                   where cred.t_paymentid = docs.t_paymentid
                                     and deb.t_paymentid = docs.t_paymentid
                                     and deb.t_paymentid = cred.t_paymentid
                                     and deb.t_debetcredit = 0
                                     and cred.t_debetcredit = 1
                                     and cred.t_group <> 1
                                     and deb.t_group <> 1)
                           or docs.t_paymentid is null ) ) a
                group by (type, orig, t_code_currency)
                order by type desc nulls last, orig nulls last;
        end if;
    end;

    /*Сводный реестр платежей*/
    procedure get_bal_all ( p_code1 in  number
                           ,p_code2 in  number
                           ,p_code_curr in varchar2
                           ,p_repdate in date
                           ,p_type in   number
                           ,p_oper in   number
                           ,p_cursor   out sys_refcursor )
    is
        regvalpay1     varchar2 ( 200 )
                := '30110*,30114*,30118*,30119*,30202*,30204*,30208*,30210*,30211*,30213*,30220*,30221*,30222*,30223*,30224*,30228*,47416*,47417*' ; -- Настройка по умолчанию
        regvalpay2     varchar2 ( 200 ) := '30301*,30302*,30305*,30306*';
        -- Настройка по умолчанию
        regvalpay3     varchar2 ( 200 ) := '30109*,30111*,30122*,30123*,30231*,401-408,40911*,40912*,40913*, 410-426'; -- Настройка по умолчанию
        regvalpay4     varchar2 ( 200 ) := '30109*,30111*,30122*,30123*,30231*,401-408,40911*,40912*,40913*, 410-426'; -- Настройка по умолчанию
        regvalrec4     varchar2 ( 200 ) := '47423*,47422*,60312*,60311*';
        -- Настройка по умолчанию
        regvalcash     varchar2 ( 200 ) := '^20202|^20203|^20207';
    -- Настройка по умолчанию
    begin
        -- KS 28.11.2013 Перенос пользовательских доработок в 31ю сборку
        regvalpay1 :=   nvl ( rsb_common.getregstrvalue ( 'PRBB\REPORT\FRONT\РЕЕСТР\МАСКА_НОСТРО', 0 ), regvalpay1 );
        regvalpay2 :=   nvl ( rsb_common.getregstrvalue ( 'PRBB\REPORT\FRONT\РЕЕСТР\МАСКА_МФР', 0 ), regvalpay2 );
        regvalpay3 :=   nvl ( rsb_common.getregstrvalue ( 'PRBB\REPORT\FRONT\РЕЕСТР\МАСКА_КЛИЕНТ', 0 ), regvalpay3 );
        regvalpay4 :=   nvl ( rsb_common.getregstrvalue ( 'PRBB\REPORT\FRONT\РЕЕСТР\МАСКА_БАНК', 0 ), regvalpay4 );
        regvalrec4 :=   nvl ( rsb_common.getregstrvalue ( 'PRBB\REPORT\FRONT\РЕЕСТР\МАСКА_ПОЛУЧАТ_БАНК', 0 ), regvalrec4 );
        regvalcash :=   nvl ( rsb_common.getregstrvalue ( 'PRBB\REPORT\FRONT\РЕЕСТР\МАСКА_КАССА', 0 ), regvalcash );

        if ( p_code_curr = '810' )
        then
            open p_cursor for
                select distinct t_code1
                               ,t_code2
                               ,name_otdel
                               ,t_oper
                               ,numdoc
                               ,accdeb
                               ,name1
                               ,acckr
                               ,name2
                               ,sum
                               ,sum as sumr
                               ,'810' as cur
                               ,sh
                               ,ground
                               ,t_code_currency
                               ,orig
                               ,decode ( orig, 1, 'Э', 0, 'Б', 'Все' ) as arch
                               ,opername
                               ,operc
                from ( select distinct
                              dotdels_dbt.t_code1
                             ,dotdels_dbt.t_code2
                             ,dotdels_dbt.t_name as name_otdel
                             ,arh.t_oper
                             ,arh.t_numb_document as numdoc
                             ,arh.t_account_payer as accdeb
                             ,acc1.t_nameaccount name1
                             ,arh.t_account_receiver as acckr
                             ,acc2.t_nameaccount name2
                             --,arh.t_sum as sum
                             ,arh.t_sum_natcur as sum
                             ,arh.t_shifr_oper || '/' || t_kind_oper sh
                             ,arh.t_ground as ground
                             --,arh.t_iapplicationkind as appkind
                             --,arh.t_applicationkey appkey
                             ,arh.t_acctrnid
                             ,arh.t_typedocument
                             ,prop.t_paymentkind paymkind
                             ,user_ea.getorigin ( paym.t_dockind, paym.t_paymentid ) origin
                             ,arh.t_chapter chapter
                             ,paym.t_dockind dockind
                             ,arh.t_number_pack numb_pack
                             ,arh.t_shifr_oper shifr_oper
                             ,paym.t_fiid cred_fiid
                             ,paym.t_payfiid deb_fiid
                             --,arh.t_code_currency
                             ,arh.t_fiid_payer t_code_currency
                             ,case
                                  when ( rsb_mask.comparestringwithmask ( regvalpay1, arh.t_account_payer ) = 1 )
                                    or ( rsb_mask.comparestringwithmask ( regvalpay1, arh.t_account_receiver ) = 1 )
                                  then
                                      1
                                  when ( rsb_mask.comparestringwithmask ( regvalpay2, arh.t_account_payer ) = 1 )
                                    or ( rsb_mask.comparestringwithmask ( regvalpay2, arh.t_account_receiver ) = 1 )
                                  then
                                      2
                                  when ( ( rsb_mask.comparestringwithmask ( regvalpay3, arh.t_account_payer ) = 1 )
                                    and ( rsb_mask.comparestringwithmask ( regvalpay3, arh.t_account_receiver ) = 1 ) )
                                  then
                                      3
                                  when ( ( rsb_mask.comparestringwithmask ( regvalpay4, arh.t_account_payer ) = 1 )
                                    and ( rsb_mask.comparestringwithmask ( regvalpay4, arh.t_account_receiver ) = 0 ) )
                                    or ( ( rsb_mask.comparestringwithmask ( regvalrec4, arh.t_account_payer ) = 1 )
                                    and ( rsb_mask.comparestringwithmask ( regvalpay4, arh.t_account_receiver ) = 1 ) )
                                  then
                                      4
                                  else
                                      5
                              end
                                  as type
                             , ( select storekind
                                from table ( user_ea.get_dev_prop ( paym.t_dockind
                                                                   ,user_ea.getorigin ( paym.t_dockind, paym.t_paymentid )
                                                                   ,prop.t_paymentkind
                                                                   ,arh.t_shifr_oper
                                                                   ,arh.t_number_pack
                                                                   ,arh.t_chapter
                                                                   ,arh.t_typedocument
                                                                   ,arh.t_account_payer
                                                                   --,arh.t_code_currency
                                                                   ,arh.t_fiid_payer
                                                                   ,arh.t_account_receiver
                                                                   --,arh.t_code_currency
                                                                   ,arh.t_fiid_receiver
                                                                   ,null ) ) )
                                  as orig
                             ,party.t_name as opername
                             ,arh.t_userfield2 as operc
                       from --darhdoc_dbt arh
                            dacctrn_dbt arh
                           ,dpmdocs_dbt docs
                           ,dpmpaym_dbt paym
                           ,daccount_dbt acc1
                           ,daccount_dbt acc2
                           ,dop_otdel_dbt
                           ,dotdels_dbt
                           ,dpmrmprop_dbt prop
                           ,dparty_dbt party
                           ,dperson_dbt pers
                       where pers.t_oper = arh.t_oper and party.t_partyid = pers.t_partyid and arh.t_date_carry = p_repdate
                         and ( dop_otdel_dbt.t_dateend >= p_repdate
                           or dop_otdel_dbt.t_dateend = to_date ( '01.01.0001', 'DD.MM.YYYY' ) --AND  p_repdate between   DOP_OTDEL_DBT.t_datebegin and nvl(DOP_OTDEL_DBT.t_dateend,p_repdate)
                                                                                              and dop_otdel_dbt.t_datebegin <= p_repdate )
                         and acc1.t_account = arh.t_account_payer
                         and acc2.t_account = arh.t_account_receiver
                         and arh.t_chapter = acc1.t_chapter
                         and acc1.t_chapter = acc2.t_chapter
                         and arh.t_chapter = 1
                         --and arh.t_applicationkey = docs.t_applicationkey(+)
                         and arh.t_acctrnid = docs.t_acctrnid(+)
                         and arh.t_fiid_payer = 0
                         and arh.t_fiid_receiver = 0
                         and docs.t_paymentid = paym.t_paymentid(+)
                         and prop.t_paymentid(+) = paym.t_paymentid
                         and substr ( arh.t_account_payer, 6, 3 ) = '810'
                         and substr ( arh.t_account_receiver, 6, 3 ) = '810'
                         and not regexp_like ( arh.t_account_payer, regvalcash )
                         and not regexp_like ( arh.t_account_receiver, regvalcash )
                         and arh.t_oper = dop_otdel_dbt.t_oper
                         and dop_otdel_dbt.t_code1 = dotdels_dbt.t_code1
                         and dop_otdel_dbt.t_code2 = dotdels_dbt.t_code2
                         and 1 = case
                                     when p_code1 is null then 1
                                     when dop_otdel_dbt.t_code1 = p_code1 then 1
                                     else 0
                                 end
                         and 1 = case
                                     when p_code2 is null then 1
                                     when dop_otdel_dbt.t_code2 = p_code2 then 1
                                     else 0
                                 end
                         and 1 = case
                                     when p_oper is null then 1
                                     when dop_otdel_dbt.t_oper = p_oper then 1
                                     else 0
                                 end
                         and ( exists
                                  (select 1
                                   from dpmprop_dbt deb, dpmprop_dbt cred
                                   where cred.t_paymentid = docs.t_paymentid
                                     and deb.t_paymentid = docs.t_paymentid
                                     and deb.t_paymentid = cred.t_paymentid
                                     and deb.t_debetcredit = 0
                                     and cred.t_debetcredit = 1
                                     and cred.t_group <> 1
                                     and deb.t_group <> 1)
                           or docs.t_paymentid is null ) ) a
                where a.type = p_type
                order by t_oper, orig nulls last;
        else
            open p_cursor for
                select distinct t_code1
                               ,t_code2
                               ,name_otdel
                               ,t_oper
                               ,numdoc
                               ,accdeb
                               ,name1
                               ,acckr
                               ,name2
                               ,sum
                               ,rsb_fiinstr.convsum ( sum, t_code_currency, 0, p_repdate, 1 ) as sumr
                               ,t_ccy as cur
                               ,sh
                               ,ground
                               ,t_code_currency
                               ,orig
                               ,decode ( orig, 1, 'Э', 0, 'Б', 'Все' ) as arch
                               ,opername
                               ,operc
                from ( select distinct
                              dotdels_dbt.t_code1
                             ,dotdels_dbt.t_code2
                             ,dotdels_dbt.t_name as name_otdel
                             ,arh.t_oper
                             ,arh.t_numb_document as numdoc
                             ,arh.t_account_payer as accdeb
                             ,acc1.t_nameaccount name1
                             ,arh.t_account_receiver as acckr
                             ,acc2.t_nameaccount name2
                             --,arh.t_sum as sum
                             ,arh.t_sum_natcur as sum
                             ,arh.t_shifr_oper || '/' || t_kind_oper sh
                             ,arh.t_ground as ground
                             --,arh.t_iapplicationkind as appkind
                             --,arh.t_applicationkey appkey
                             ,arh.t_acctrnid
                             ,arh.t_typedocument
                             ,prop.t_paymentkind paymkind
                             ,user_ea.getorigin ( paym.t_dockind, paym.t_paymentid ) origin
                             ,arh.t_chapter chapter
                             ,paym.t_dockind dockind
                             ,arh.t_number_pack numb_pack
                             ,arh.t_shifr_oper shifr_oper
                             ,paym.t_fiid cred_fiid
                             ,paym.t_payfiid deb_fiid
                             --,arh.t_code_currency
                             ,arh.t_fiid_payer t_code_currency
                             ,fin.t_ccy
                             ,case
                                  when ( rsb_mask.comparestringwithmask ( regvalpay1, arh.t_account_payer ) = 1 )
                                    or ( rsb_mask.comparestringwithmask ( regvalpay1, arh.t_account_receiver ) = 1 )
                                  then
                                      1
                                  when ( rsb_mask.comparestringwithmask ( regvalpay2, arh.t_account_payer ) = 1 )
                                    or ( rsb_mask.comparestringwithmask ( regvalpay2, arh.t_account_receiver ) = 1 )
                                  then
                                      2
                                  when ( ( rsb_mask.comparestringwithmask ( regvalpay3, arh.t_account_payer ) = 1 )
                                    and ( rsb_mask.comparestringwithmask ( regvalpay3, arh.t_account_receiver ) = 1 ) )
                                  then
                                      3
                                  when ( ( rsb_mask.comparestringwithmask ( regvalpay4, arh.t_account_payer ) = 1 )
                                    and ( rsb_mask.comparestringwithmask ( regvalpay4, arh.t_account_receiver ) = 0 ) )
                                    or ( ( rsb_mask.comparestringwithmask ( regvalrec4, arh.t_account_payer ) = 1 )
                                    and ( rsb_mask.comparestringwithmask ( regvalpay1, arh.t_account_receiver ) = 1 ) )
                                  then
                                      4
                                  else
                                      5
                              end
                                  as type
                             , ( select storekind
                                from table ( user_ea.get_dev_prop ( paym.t_dockind
                                                                   ,user_ea.getorigin ( paym.t_dockind, paym.t_paymentid )
                                                                   ,prop.t_paymentkind
                                                                   ,arh.t_shifr_oper
                                                                   ,arh.t_number_pack
                                                                   ,arh.t_chapter
                                                                   ,arh.t_typedocument
                                                                   ,arh.t_account_payer
                                                                   --,arh.t_code_currency
                                                                   ,arh.t_fiid_payer
                                                                   ,arh.t_account_receiver
                                                                   --,arh.t_code_currency
                                                                   ,arh.t_fiid_receiver
                                                                   ,null ) ) )
                                  as orig
                             ,party.t_name as opername
                             ,arh.t_userfield2 as operc
                       from --darhdoc$_dbt arh
                            dacctrn_dbt arh
                           ,dpmdocs_dbt docs
                           ,dpmpaym_dbt paym
                           ,daccount_dbt acc1
                           ,daccount_dbt acc2
                           ,dop_otdel_dbt
                           ,dotdels_dbt
                           ,dpmrmprop_dbt prop
                           ,dparty_dbt party
                           ,dfininstr_dbt fin
                           ,dperson_dbt pers
                       where pers.t_oper = arh.t_oper
                         and party.t_partyid = pers.t_partyid
                         --and fin.t_fiid = arh.t_code_currency
                         and fin.t_fiid = arh.t_fiid_payer
                         and fin.t_fi_code = p_code_curr
                         and arh.t_date_carry = p_repdate
                         and ( dop_otdel_dbt.t_dateend >= p_repdate
                           or dop_otdel_dbt.t_dateend = to_date ( '01.01.0001', 'DD.MM.YYYY' ) --       AND  p_repdate between   DOP_OTDEL_DBT.t_datebegin and nvl(DOP_OTDEL_DBT.t_dateend,p_repdate)
                                                                                              and dop_otdel_dbt.t_datebegin <= p_repdate )
                         and acc1.t_account = arh.t_account_payer
                         and acc2.t_account = arh.t_account_receiver
                         and arh.t_chapter = acc1.t_chapter
                         and acc1.t_chapter = acc2.t_chapter
                         and arh.t_chapter = 1
                         --and arh.t_applicationkey = docs.t_applicationkey(+)
                         and arh.t_acctrnid = docs.t_acctrnid(+)
                         and (arh.t_fiid_payer != 0 or arh.t_fiid_receiver != 0)
                         and docs.t_paymentid = paym.t_paymentid(+)
                         and prop.t_paymentid(+) = paym.t_paymentid
                         and substr ( arh.t_account_payer, 6, 3 ) = substr ( arh.t_account_receiver, 6, 3 )
                         and not regexp_like ( arh.t_account_payer, regvalcash )
                         and not regexp_like ( arh.t_account_receiver, regvalcash )
                         and arh.t_oper = dop_otdel_dbt.t_oper
                         and dop_otdel_dbt.t_code1 = dotdels_dbt.t_code1
                         and dop_otdel_dbt.t_code2 = dotdels_dbt.t_code2
                         and 1 = case
                                     when p_code1 is null then 1
                                     when dop_otdel_dbt.t_code1 = p_code1 then 1
                                     else 0
                                 end
                         and 1 = case
                                     when p_code2 is null then 1
                                     when dop_otdel_dbt.t_code2 = p_code2 then 1
                                     else 0
                                 end
                         and 1 = case
                                     when p_oper is null then 1
                                     when dop_otdel_dbt.t_oper = p_oper then 1
                                     else 0
                                 end
                         and ( exists
                                  (select 1
                                   from dpmprop_dbt deb, dpmprop_dbt cred
                                   where cred.t_paymentid = docs.t_paymentid
                                     and deb.t_paymentid = docs.t_paymentid
                                     and deb.t_paymentid = cred.t_paymentid
                                     and deb.t_debetcredit = 0
                                     and cred.t_debetcredit = 1
                                     and cred.t_group <> 1
                                     and deb.t_group <> 1)
                           or docs.t_paymentid is null ) ) a
                where a.type = p_type
                order by t_oper, orig nulls last;
        end if;
    end;

    /*Список сотрудников в Отделе*/
    procedure get_otd_oper ( p_code1 in number, p_code2 in number, p_oper in number, p_repdate in date, p_cursor out sys_refcursor )
    is
    begin
        open p_cursor for
            select otd.t_oper
                  ,otd.t_datebegin
                  ,otd.t_dateend
                  ,pers.t_name
                  ,o.t_name nameof
                  ,otd.t_code1
                  ,otd.t_code2
            from dop_otdel_dbt otd, dperson_dbt pers, dotdels_dbt o
            where pers.t_oper = otd.t_oper
              and o.t_code1 = otd.t_code1
              and o.t_code2 = otd.t_code2
              and 1 = case
                          when p_code1 is null then 1
                          when otd.t_code1 = p_code1 then 1
                          else 0
                      end
              and 1 = case
                          when p_code2 is null then 1
                          when otd.t_code2 = p_code2 then 1
                          else 0
                      end
              and 1 = case
                          when p_oper is null then 1
                          when otd.t_oper = p_oper then 1
                          else 0
                      end
              and p_repdate between otd.t_datebegin
                                and  decode ( otd.t_dateend, to_date ( '01.01.0001', 'dd.mm.yyyy' ), p_repdate, otd.t_dateend )
            order by otd.t_oper, otd.t_datebegin;
    end;

    /*Новая конверсия*/
    procedure get_curr_conv_new ( p_code1 in number, p_code2 in number, p_repdate in date, p_cursor out sys_refcursor )
    is
    begin
        open p_cursor for
            select sum ( sumr ) as resultr
                  ,sum ( sume ) as resulte
                  ,sum ( sum ) as result
                  ,count ( 1 ) as total
                  ,decode ( vid_hran, 1, 'Э', 'Б' ) as kind_doc
            from ( select t_code1
                         ,t_code2
                         ,name_otdel
                         ,t_oper
                         ,numdoc
                         ,accdeb
                         ,name1
                         ,acckr
                         ,name2
                         ,case
                              when ( ( substr ( acckr, 14, 5 ) in ('21010', '22010') )
                                 or ( substr ( accdeb, 14, 5 ) in ('21010', '22010') )
                                 or ( t_result_carry in (18, 82) ) )
                              then
                                  sum
                              else
                                  0
                          end
                              sumr
                         ,case
                              when ( ( substr ( acckr, 14, 5 ) not in ('21010', '22010') )
                                and ( substr ( accdeb, 14, 5 ) not in ('21010', '22010') )
                                and ( t_result_carry not in (18, 82) ) )
                              then
                                  sum
                              else
                                  0
                          end
                              sume
                         ,sum
                         ,sh
                         ,ground
                         ,t_code_currency
                         ,nvl ( paymentid, -1 ) paymentid
                         , ( select storekind
                            from table ( user_ea.get_dev_prop ( a.dockind
                                                               ,a.origin
                                                               ,a.paymkind
                                                               ,a.shifr_oper
                                                               ,a.numb_pack
                                                               ,a.chapter
                                                               ,a.t_typedocument
                                                               ,a.accdeb
                                                               ,a.t_code_currency
                                                               ,a.acckr
                                                               ,a.t_code_currency
                                                               ,null ) ) )
                              vid_hran
                         ,a.t_result_carry
                         --,appkey
                         ,t_acctrnid
                         ,name_oper
                   from ( select distinct dotdels_dbt.t_code1
                                         ,dotdels_dbt.t_code2
                                         ,dotdels_dbt.t_name as name_otdel
                                         ,arh.t_oper
                                         ,arh.t_numb_document as numdoc
                                         ,arh.t_account_payer as accdeb
                                         ,acc1.t_nameaccount name1
                                         ,arh.t_account_receiver as acckr
                                         ,acc2.t_nameaccount name2
                                         --,arh.t_sum as sum
                                         ,arh.t_sum_natcur as sum
                                         ,arh.t_shifr_oper || '/' || t_kind_oper sh
                                         ,arh.t_ground as ground
                                         --,arh.t_iapplicationkind as appkind
                                         --,arh.t_applicationkey appkey
                                         ,arh.t_acctrnid
                                         ,paym.t_typedocument
                                         ,prop.t_paymentkind paymkind
                                         ,user_ea.getorigin ( paym.t_dockind, paym.t_paymentid ) origin
                                         ,paym.t_chapter chapter
                                         ,paym.t_dockind dockind
                                         ,arh.t_number_pack numb_pack
                                         ,arh.t_shifr_oper shifr_oper
                                         ,paym.t_fiid cred_fiid
                                         ,paym.t_payfiid deb_fiid
                                         --,arh.t_code_currency
                                         ,arh.t_fiid_payer t_code_currency
                                         ,paym.t_paymentid paymentid
                                         ,arh.t_result_carry
                                         ,pers.t_name as name_oper
                          from --darhdoc_dbt arh
                               dacctrn_dbt arh
                              ,dpmdocs_dbt docs
                              ,dpmpaym_dbt paym
                              ,daccount_dbt acc1
                              ,daccount_dbt acc2
                              ,dotdels_dbt
                              ,dpmrmprop_dbt prop
                              , ( select *
                                  from dop_otdel_dbt
                                  where ( t_oper, t_datebegin ) in
                                                ( select t_oper, max ( t_datebegin ) t_datebegin
                                                 from dop_otdel_dbt
                                                 where t_datebegin <= p_repdate
                                                   and ( t_dateend >= p_repdate or t_dateend = to_date ( '01.01.0001', 'DD.MM.YYYY' ) )
                                                 group by t_oper ) ) dop_otdel_dbt
                              ,dperson_dbt pers
                          where arh.t_date_carry = p_repdate
                            and ( dop_otdel_dbt.t_dateend >= p_repdate or t_dateend = to_date ( '01.01.0001', 'DD.MM.YYYY' ) )
                            and t_datebegin <= p_repdate
                            and acc1.t_account(+) = arh.t_account_payer
                            and acc2.t_account(+) = arh.t_account_receiver
                            and arh.t_chapter = 1
                            and arh.t_oper = pers.t_oper
                            --and arh.t_applicationkey = docs.t_applicationkey(+)
                            and arh.t_acctrnid = docs.t_acctrnid(+)
                            and arh.t_fiid_payer = 0
                            and arh.t_fiid_receiver = 0
                            and docs.t_paymentid = paym.t_paymentid(+)
                            and prop.t_paymentid(+) = paym.t_paymentid
                            and substr ( arh.t_account_payer, 6, 3 ) <> substr ( arh.t_account_receiver, 6, 3 )
                            and ( substr ( arh.t_account_payer, 1, 5 ) not in ('20202', '20203', '20207') or arh.t_result_carry in (18, 82) )
                            and ( substr ( arh.t_account_receiver, 1, 5 ) not in ('20202', '20203', '20207')
                              or arh.t_result_carry in (18, 82) )
                            and arh.t_account_payer <> 'ОВП'
                            and arh.t_account_receiver <> 'ОВП'
                            and arh.t_oper = dop_otdel_dbt.t_oper
                            and dop_otdel_dbt.t_code1 = dotdels_dbt.t_code1
                            and dop_otdel_dbt.t_code2 = dotdels_dbt.t_code2
                            and dop_otdel_dbt.t_code1 = p_code1
                            and dop_otdel_dbt.t_code2 = p_code2
                            and ( exists
                                     (select 1
                                      from dpmprop_dbt deb, dpmprop_dbt cred
                                      where cred.t_paymentid = docs.t_paymentid
                                        and deb.t_paymentid = docs.t_paymentid
                                        and deb.t_paymentid = cred.t_paymentid
                                        and deb.t_debetcredit = 0
                                        and cred.t_debetcredit = 1
                                        and cred.t_group <> 1
                                        and deb.t_group <> 1)
                              or docs.t_paymentid is null )
                          union all
                          select distinct dotdels_dbt.t_code1
                                         ,dotdels_dbt.t_code2
                                         ,dotdels_dbt.t_name as name_otdel
                                         ,arh.t_oper
                                         ,arh.t_numb_document as numdoc
                                         ,arh.t_account_payer as accdeb
                                         ,acc1.t_nameaccount name1
                                         ,arh.t_account_receiver as acckr
                                         ,acc2.t_nameaccount name2
                                         --,arh.t_sum as sum
                                         ,arh.t_sum_payer as sum
                                         ,arh.t_shifr_oper || '/' || t_kind_oper sh
                                         ,arh.t_ground as ground
                                         --,arh.t_iapplicationkind as appkind
                                         --,arh.t_applicationkey appkey
                                         ,arh.t_acctrnid
                                         ,arh.t_typedocument
                                         ,prop.t_paymentkind paymkind
                                         ,user_ea.getorigin ( paym.t_dockind, paym.t_paymentid ) origin
                                         ,paym.t_chapter chapter
                                         ,paym.t_dockind dockind
                                         ,arh.t_number_pack numb_pack
                                         ,arh.t_shifr_oper shifr_oper
                                         ,paym.t_fiid cred_fiid
                                         ,paym.t_payfiid deb_fiid
                                         --,arh.t_code_currency
                                         ,arh.t_fiid_payer t_code_currency
                                         ,paym.t_paymentid paymentid
                                         ,arh.t_result_carry
                                         ,pers.t_name name_oper
                          from --darhdoc$_dbt arh
                               dacctrn_dbt arh
                              ,dpmdocs_dbt docs
                              ,dpmpaym_dbt paym
                              ,daccount_dbt acc1
                              ,daccount_dbt acc2
                              ,dotdels_dbt
                              ,dpmrmprop_dbt prop
                              , ( select *
                                  from dop_otdel_dbt
                                  where ( t_oper, t_datebegin ) in
                                                ( select t_oper, max ( t_datebegin ) t_datebegin
                                                 from dop_otdel_dbt
                                                 where t_datebegin <= p_repdate
                                                   and ( t_dateend >= p_repdate or t_dateend = to_date ( '01.01.0001', 'DD.MM.YYYY' ) )
                                                 group by t_oper ) ) dop_otdel_dbt
                              ,dperson_dbt pers
                          where arh.t_date_carry = p_repdate
                            and ( dop_otdel_dbt.t_dateend >= p_repdate or t_dateend = to_date ( '01.01.0001', 'DD.MM.YYYY' ) )
                            and t_datebegin <= p_repdate
                            and acc1.t_account(+) = arh.t_account_payer
                            and acc2.t_account(+) = arh.t_account_receiver
                            and arh.t_chapter = acc1.t_chapter
                            and acc1.t_chapter = acc2.t_chapter
                            and arh.t_chapter = 1
                            and pers.t_oper = arh.t_oper
                            --and arh.t_applicationkey = docs.t_applicationkey(+)
                            and arh.t_acctrnid = docs.t_acctrnid(+)
                            and (arh.t_fiid_payer != 0 or arh.t_fiid_receiver != 0)
                            and docs.t_paymentid = paym.t_paymentid(+)
                            and prop.t_paymentid(+) = paym.t_paymentid
                            and substr ( arh.t_account_payer, 6, 3 ) <> substr ( arh.t_account_receiver, 6, 3 )
                            and ( substr ( arh.t_account_payer, 1, 5 ) not in ('20202', '20203', '20207') or arh.t_result_carry in (18, 82) )
                            and ( substr ( arh.t_account_receiver, 1, 5 ) not in ('20202', '20203', '20207')
                              or arh.t_result_carry in (18, 82) )
                            and arh.t_account_payer <> 'ОВП'
                            and arh.t_account_receiver <> 'ОВП'
                            and arh.t_oper = dop_otdel_dbt.t_oper
                            and dop_otdel_dbt.t_code1 = dotdels_dbt.t_code1
                            and dop_otdel_dbt.t_code2 = dotdels_dbt.t_code2
                            and dop_otdel_dbt.t_code1 = p_code1
                            and dop_otdel_dbt.t_code2 = p_code2
                            and ( exists
                                     (select 1
                                      from dpmprop_dbt deb, dpmprop_dbt cred
                                      where cred.t_paymentid = docs.t_paymentid
                                        and deb.t_paymentid = docs.t_paymentid
                                        and deb.t_paymentid = cred.t_paymentid
                                        and deb.t_debetcredit = 0
                                        and cred.t_debetcredit = 1
                                        and cred.t_group <> 1
                                        and deb.t_group <> 1)
                              or docs.t_paymentid is null ) ) a )
            group by vid_hran
            order by vid_hran;
    end;

    /*Новый внебаланс*/
    procedure get_chap3_new ( p_code1 in number, p_code2 in number, p_repdate in date, p_cursor out sys_refcursor )
    is
    begin
        open p_cursor for
            select sum ( sum ) as result, sum ( sum ) as resultr, count ( 1 ) as total, decode ( vid_hran, 1, 'Э', 'Б' ) as kind_doc
            from ( select distinct t_code1
                                  ,t_code2
                                  ,name_otdel
                                  ,t_oper
                                  ,numdoc
                                  ,accdeb
                                  ,name1
                                  ,acckr
                                  ,name2
                                  ,sum
                                  ,sh
                                  ,ground
                                  ,t_code_currency
                                  ,nvl ( paymentid, -1 ) paymentid
                                  , ( select storekind
                                     from table ( user_ea.get_dev_prop ( null
                                                                        ,a.origin
                                                                        ,null
                                                                        ,a.shifr_oper
                                                                        ,a.numb_pack
                                                                        ,a.chapter
                                                                        ,a.t_typedocument
                                                                        ,a.accdeb
                                                                        ,a.t_code_currency
                                                                        ,a.acckr
                                                                        ,a.t_code_currency
                                                                        ,null ) ) )
                                       vid_hran
                                  --,appkey
                                  ,t_acctrnid
                   from ( select distinct dotdels_dbt.t_code1
                                         ,dotdels_dbt.t_code2
                                         ,dotdels_dbt.t_name as name_otdel
                                         ,arh.t_oper
                                         ,arh.t_numb_document as numdoc
                                         ,arh.t_account_payer as accdeb
                                         ,acc1.t_nameaccount name1
                                         ,arh.t_account_receiver as acckr
                                         ,acc2.t_nameaccount name2
                                         --,arh.t_sum as sum
                                         ,arh.t_sum_payer as sum
                                         ,arh.t_shifr_oper || '/' || t_kind_oper sh
                                         ,arh.t_ground as ground
                                         --,arh.t_iapplicationkind as appkind
                                         --,arh.t_applicationkey appkey
                                         ,arh.t_acctrnid
                                         ,arh.t_typedocument
                                         ,prop.t_paymentkind paymkind
                                         ,user_ea.getorigin ( paym.t_dockind, paym.t_paymentid ) origin
                                         ,arh.t_chapter chapter
                                         ,paym.t_dockind dockind
                                         ,arh.t_number_pack numb_pack
                                         ,arh.t_shifr_oper shifr_oper
                                         ,paym.t_fiid cred_fiid
                                         ,paym.t_payfiid deb_fiid
                                         --,arh.t_code_currency
                                         ,arh.t_fiid_payer t_code_currency
                                         ,paym.t_paymentid paymentid
                          from --darhdoc_dbt arh
                               dacctrn_dbt arh
                              ,dpmdocs_dbt docs
                              ,dpmpaym_dbt paym
                              ,daccount_dbt acc1
                              ,daccount_dbt acc2
                              ,dotdels_dbt
                              ,dpmrmprop_dbt prop
                              , ( select *
                                  from dop_otdel_dbt
                                  where ( t_oper, t_datebegin ) in
                                                ( select t_oper, max ( t_datebegin ) t_datebegin
                                                 from dop_otdel_dbt
                                                 where t_datebegin <= p_repdate
                                                   and ( t_dateend >= p_repdate or t_dateend = to_date ( '01.01.0001', 'DD.MM.YYYY' ) )
                                                 group by t_oper ) ) dop_otdel_dbt
                              ,dperson_dbt pers
                          where arh.t_date_carry = p_repdate
                            and ( dop_otdel_dbt.t_dateend >= p_repdate or t_dateend = to_date ( '01.01.0001', 'DD.MM.YYYY' ) )
                            and t_datebegin <= p_repdate
                            and acc1.t_account(+) = arh.t_account_payer
                            and acc2.t_account(+) = arh.t_account_receiver
                            and arh.t_chapter = 3
                            and pers.t_oper = arh.t_oper
                            --and arh.t_applicationkey = docs.t_applicationkey(+)
                            and arh.t_acctrnid = docs.t_acctrnid(+)
                            and arh.t_fiid_payer = 0
                            and arh.t_fiid_receiver = 0
                            and docs.t_paymentid = paym.t_paymentid(+)
                            and prop.t_paymentid(+) = paym.t_paymentid
                            and ( ( substr ( arh.t_account_payer, 6, 3 ) = '810' and substr ( arh.t_account_receiver, 6, 3 ) = '810' )
                              or ( substr ( arh.t_account_payer, 6, 3 ) <> substr ( arh.t_account_receiver, 6, 3 ) ) )
                            and substr ( arh.t_account_payer, 1, 5 ) not in ('20202', '20203', '20207')
                            and substr ( arh.t_account_receiver, 1, 5 ) not in ('20202', '20203', '20207')
                            and arh.t_oper = dop_otdel_dbt.t_oper(+)
                            and dop_otdel_dbt.t_code1 = dotdels_dbt.t_code1(+)
                            and dop_otdel_dbt.t_code2 = dotdels_dbt.t_code2(+)
                            and dop_otdel_dbt.t_code1 = p_code1
                            and dop_otdel_dbt.t_code2 = p_code2 ) a )
            group by vid_hran
            order by vid_hran;
    end;

    /*Новая конверсия Сводный реестр*/
    procedure get_curr_conv_cons ( p_code1 in number, p_code2 in number, p_repdate in date, p_cursor out sys_refcursor )
    is
    begin
        open p_cursor for
            select distinct
                   t_code1
                  ,t_code2
                  ,name_otdel
                  ,numdoc
                  ,accdeb
                  ,acckr
                  ,case
                       when ( ( substr ( acckr, 14, 5 ) in ('21010', '22010') ) or ( substr ( accdeb, 14, 5 ) in ('21010', '22010') ) )
                       then
                           '-'
                       else
                           to_char ( sumr )
                   end
                       sumr
                  ,case
                       when ( ( substr ( acckr, 14, 5 ) in ('21010', '22010') ) or ( substr ( accdeb, 14, 5 ) in ('21010', '22010') ) )
                       then
                           'RUR'
                       else
                           code_pay
                   end
                       code_pay
                  ,case
                       when ( ( substr ( acckr, 14, 5 ) in ('21010', '22010') ) or ( substr ( accdeb, 14, 5 ) in ('21010', '22010') ) )
                       then
                           '-'
                       else
                           to_char ( sume )
                   end
                       sume
                  ,case
                       when ( ( substr ( acckr, 14, 5 ) in ('21010', '22010') ) or ( substr ( accdeb, 14, 5 ) in ('21010', '22010') ) )
                       then
                           'RUR'
                       else
                           code_rec
                   end
                       code_rec
                  ,sum
                  ,sh
                  ,t_oper
                  ,ground
                  ,decode ( orig, 1, 'Э', 0, 'Б', 'Все' ) as arch
                  ,name_oper
                  ,operc
                  ,paymentid
            from ( select t_code1
                         ,t_code2
                         ,name_otdel
                         ,t_oper
                         ,numdoc
                         ,accdeb
                         ,name1
                         ,acckr
                         ,name2
                         ,case
                              when substr ( accdeb, 6, 3 ) <> '810'
                              then
                                  nvl (
                                        ( select arh.t_sum_payer --arh.t_sum
                                         --from darhdoc$_dbt arh, dpmdocs_dbt docs, dfininstr_dbt fi
                                         from dacctrn_dbt arh, dpmdocs_dbt docs, dfininstr_dbt fi
                                         --where arh.t_applicationkey = docs.t_applicationkey
                                         where arh.t_acctrnid = docs.t_acctrnid
                                           and fi.t_codeinaccount = substr ( arh.t_account_payer, 6, 3 )
                                           and docs.t_paymentid = paymentid )
                                       ,0
                                  )
                              else
                                  sum
                          end
                              sumr
                         ,case
                              when substr ( acckr, 6, 3 ) <> '810'
                              then
                                  nvl (
                                        ( select arh.t_sum_receiver --arh.t_sum
                                         --from darhdoc$_dbt arh, dpmdocs_dbt docs, dfininstr_dbt fi
                                         from dacctrn_dbt arh, dpmdocs_dbt docs, dfininstr_dbt fi
                                         --where arh.t_applicationkey = docs.t_applicationkey
                                         where arh.t_acctrnid = docs.t_acctrnid
                                           and fi.t_codeinaccount = substr ( arh.t_account_receiver, 6, 3 )
                                           and docs.t_paymentid = paymentid )
                                       ,0
                                  )
                              else
                                  sum
                          end
                              sume
                         ,sum
                         ,sh
                         ,ground
                         ,t_code_currency
                         ,nvl ( paymentid, -1 ) paymentid
                         , ( select storekind
                            from table ( user_ea.get_dev_prop ( a.dockind
                                                               ,a.origin
                                                               ,a.paymkind
                                                               ,a.shifr_oper
                                                               ,a.numb_pack
                                                               ,a.chapter
                                                               ,a.t_typedocument
                                                               ,a.accdeb
                                                               ,a.t_code_currency
                                                               ,a.acckr
                                                               ,a.t_code_currency
                                                               ,null ) ) )
                              orig
                         ,a.t_result_carry
                         --,appkey
                         ,t_acctrnid
                         ,name_oper
                         ,operc
                         ,code_rec
                         ,code_pay
                   from ( select distinct dotdels_dbt.t_code1
                                         ,dotdels_dbt.t_code2
                                         ,dotdels_dbt.t_name as name_otdel
                                         ,arh.t_oper
                                         ,arh.t_numb_document as numdoc
                                         ,arh.t_account_payer as accdeb
                                         ,acc1.t_nameaccount name1
                                         ,arh.t_account_receiver as acckr
                                         ,acc2.t_nameaccount name2
                                         --,arh.t_sum as sum
                                         ,arh.t_sum_natcur as sum
                                         ,arh.t_shifr_oper || '/' || t_kind_oper sh
                                         ,arh.t_ground as ground
                                         --,arh.t_iapplicationkind as appkind
                                         --,arh.t_applicationkey appkey
                                         ,arh.t_acctrnid
                                         ,paym.t_typedocument
                                         ,prop.t_paymentkind paymkind
                                         ,user_ea.getorigin ( paym.t_dockind, paym.t_paymentid ) origin
                                         ,paym.t_chapter chapter
                                         ,paym.t_dockind dockind
                                         ,arh.t_number_pack numb_pack
                                         ,arh.t_shifr_oper shifr_oper
                                         ,paym.t_fiid cred_fiid
                                         ,paym.t_payfiid deb_fiid
                                         --,arh.t_code_currency
                                         ,arh.t_fiid_payer t_code_currency
                                         ,paym.t_paymentid paymentid
                                         ,arh.t_result_carry
                                         ,pers.t_name as name_oper
                                         ,arh.t_userfield2 as operc
                                         ,fin1.t_ccy code_pay
                                         ,fin2.t_ccy code_rec
                          from --darhdoc_dbt arh
                               dacctrn_dbt arh
                              ,dpmdocs_dbt docs
                              ,dpmpaym_dbt paym
                              ,daccount_dbt acc1
                              ,daccount_dbt acc2
                              ,dotdels_dbt
                              ,dpmrmprop_dbt prop
                              , ( select *
                                  from dop_otdel_dbt
                                  where ( t_oper, t_datebegin ) in
                                                ( select t_oper, max ( t_datebegin ) t_datebegin
                                                 from dop_otdel_dbt
                                                 where t_datebegin <= p_repdate
                                                   and ( t_dateend >= p_repdate or t_dateend = to_date ( '01.01.0001', 'DD.MM.YYYY' ) )
                                                 group by t_oper ) ) dop_otdel_dbt
                              ,dperson_dbt pers
                              ,dfininstr_dbt fin1
                              ,dfininstr_dbt fin2
                          where arh.t_date_carry = p_repdate
                            and ( dop_otdel_dbt.t_dateend >= p_repdate or t_dateend = to_date ( '01.01.0001', 'DD.MM.YYYY' ) )
                            and t_datebegin <= p_repdate
                            and acc1.t_account(+) = arh.t_account_payer
                            and acc2.t_account(+) = arh.t_account_receiver
                            and arh.t_chapter = 1
                            and arh.t_oper = pers.t_oper
                            --and arh.t_applicationkey = docs.t_applicationkey(+)
                            and arh.t_acctrnid = docs.t_acctrnid(+)
                            and arh.t_fiid_payer = 0
                            and arh.t_fiid_receiver = 0
                            and docs.t_paymentid = paym.t_paymentid(+)
                            and prop.t_paymentid(+) = paym.t_paymentid
                            and substr ( arh.t_account_payer, 6, 3 ) <> substr ( arh.t_account_receiver, 6, 3 )
                            and ( substr ( arh.t_account_payer, 1, 5 ) not in ('20202', '20203', '20207') or arh.t_result_carry in (18, 82) )
                            and ( substr ( arh.t_account_receiver, 1, 5 ) not in ('20202', '20203', '20207')
                              or arh.t_result_carry in (18, 82) )
                            and arh.t_account_payer <> 'ОВП'
                            and arh.t_account_receiver <> 'ОВП'
                            and arh.t_oper = dop_otdel_dbt.t_oper
                            and dop_otdel_dbt.t_code1 = dotdels_dbt.t_code1
                            and dop_otdel_dbt.t_code2 = dotdels_dbt.t_code2
                            and dop_otdel_dbt.t_code1 = p_code1
                            and dop_otdel_dbt.t_code2 = p_code2
                            and ( exists
                                     (select 1
                                      from dpmprop_dbt deb, dpmprop_dbt cred
                                      where cred.t_paymentid = docs.t_paymentid
                                        and deb.t_paymentid = docs.t_paymentid
                                        and deb.t_paymentid = cred.t_paymentid
                                        and deb.t_debetcredit = 0
                                        and cred.t_debetcredit = 1
                                        and cred.t_group <> 1
                                        and deb.t_group <> 1)
                              or docs.t_paymentid is null )
                            and fin1.t_codeinaccount = substr ( arh.t_account_payer, 6, 3 )
                            and fin2.t_codeinaccount = substr ( arh.t_account_receiver, 6, 3 )
                          union all
                          select distinct dotdels_dbt.t_code1
                                         ,dotdels_dbt.t_code2
                                         ,dotdels_dbt.t_name as name_otdel
                                         ,arh.t_oper
                                         ,arh.t_numb_document as numdoc
                                         ,arh.t_account_payer as accdeb
                                         ,acc1.t_nameaccount name1
                                         ,arh.t_account_receiver as acckr
                                         ,acc2.t_nameaccount name2
                                         --,arh.t_sum as sum
                                         ,arh.t_sum_payer as sum
                                         ,arh.t_shifr_oper || '/' || t_kind_oper sh
                                         ,arh.t_ground as ground
                                         --,arh.t_iapplicationkind as appkind
                                         --,arh.t_applicationkey appkey
                                         ,arh.t_acctrnid
                                         ,arh.t_typedocument
                                         ,prop.t_paymentkind paymkind
                                         ,user_ea.getorigin ( paym.t_dockind, paym.t_paymentid ) origin
                                         ,paym.t_chapter chapter
                                         ,paym.t_dockind dockind
                                         ,arh.t_number_pack numb_pack
                                         ,arh.t_shifr_oper shifr_oper
                                         ,paym.t_fiid cred_fiid
                                         ,paym.t_payfiid deb_fiid
                                         --,arh.t_code_currency
                                         ,arh.t_fiid_payer t_code_currency
                                         ,paym.t_paymentid paymentid
                                         ,arh.t_result_carry
                                         ,pers.t_name name_oper
                                         ,arh.t_userfield2 as operc
                                         ,fin1.t_ccy code_pay
                                         ,fin2.t_ccy code_rec
                          from --darhdoc$_dbt arh
                               dacctrn_dbt arh
                              ,dpmdocs_dbt docs
                              ,dpmpaym_dbt paym
                              ,daccount_dbt acc1
                              ,daccount_dbt acc2
                              ,dotdels_dbt
                              ,dpmrmprop_dbt prop
                              , ( select *
                                  from dop_otdel_dbt
                                  where ( t_oper, t_datebegin ) in
                                                ( select t_oper, max ( t_datebegin ) t_datebegin
                                                 from dop_otdel_dbt
                                                 where t_datebegin <= p_repdate
                                                   and ( t_dateend >= p_repdate or t_dateend = to_date ( '01.01.0001', 'DD.MM.YYYY' ) )
                                                 group by t_oper ) ) dop_otdel_dbt
                              ,dperson_dbt pers
                              ,dfininstr_dbt fin1
                              ,dfininstr_dbt fin2
                          where arh.t_date_carry = p_repdate
                            and ( dop_otdel_dbt.t_dateend >= p_repdate or t_dateend = to_date ( '01.01.0001', 'DD.MM.YYYY' ) )
                            and t_datebegin <= p_repdate
                            and acc1.t_account(+) = arh.t_account_payer
                            and acc2.t_account(+) = arh.t_account_receiver
                            and arh.t_chapter = acc1.t_chapter
                            and acc1.t_chapter = acc2.t_chapter
                            and arh.t_chapter = 1
                            and pers.t_oper = arh.t_oper
                            --and arh.t_applicationkey = docs.t_applicationkey(+)
                            and arh.t_acctrnid = docs.t_acctrnid(+)
                            and (arh.t_fiid_payer != 0 or arh.t_fiid_receiver != 0)
                            and docs.t_paymentid = paym.t_paymentid(+)
                            and prop.t_paymentid(+) = paym.t_paymentid
                            and substr ( arh.t_account_payer, 6, 3 ) <> substr ( arh.t_account_receiver, 6, 3 )
                            and ( substr ( arh.t_account_payer, 1, 5 ) not in ('20202', '20203', '20207') or arh.t_result_carry in (18, 82) )
                            and ( substr ( arh.t_account_receiver, 1, 5 ) not in ('20202', '20203', '20207')
                              or arh.t_result_carry in (18, 82) )
                            and arh.t_account_payer <> 'ОВП'
                            and arh.t_account_receiver <> 'ОВП'
                            and arh.t_oper = dop_otdel_dbt.t_oper
                            and dop_otdel_dbt.t_code1 = dotdels_dbt.t_code1
                            and dop_otdel_dbt.t_code2 = dotdels_dbt.t_code2
                            and dop_otdel_dbt.t_code1 = p_code1
                            and dop_otdel_dbt.t_code2 = p_code2
                            and ( exists
                                     (select 1
                                      from dpmprop_dbt deb, dpmprop_dbt cred
                                      where cred.t_paymentid = docs.t_paymentid
                                        and deb.t_paymentid = docs.t_paymentid
                                        and deb.t_paymentid = cred.t_paymentid
                                        and deb.t_debetcredit = 0
                                        and cred.t_debetcredit = 1
                                        and cred.t_group <> 1
                                        and deb.t_group <> 1)
                              or docs.t_paymentid is null )
                            and fin1.t_codeinaccount = substr ( arh.t_account_payer, 6, 3 )
                            and fin2.t_codeinaccount = substr ( arh.t_account_receiver, 6, 3 ) ) a )
            order by t_oper, paymentid, numdoc, accdeb, sum;
    end;

    /*Новый внебаланс*/
    procedure get_chap3_cons ( p_code1 in number, p_code2 in number, p_repdate in date, p_cursor out sys_refcursor )
    is
    begin
        open p_cursor for
            select distinct t_code1
                           ,t_code2
                           ,name_otdel
                           ,t_oper
                           ,numdoc
                           ,accdeb
                           ,name1
                           ,acckr
                           ,name2
                           ,sum
                           ,sh
                           ,ground
                           ,decode ( ( select storekind
                                      from table ( user_ea.get_dev_prop ( null
                                                                         ,origin
                                                                         ,null
                                                                         ,shifr_oper
                                                                         ,numb_pack
                                                                         ,chapter
                                                                         ,t_typedocument
                                                                         ,accdeb
                                                                         ,t_code_currency
                                                                         ,acckr
                                                                         ,t_code_currency
                                                                         ,null ) ) ),
                                     1, 'Э',
                                     'Б' )
                                as vid_hran
                           ,name_oper
                           ,operc
            from ( select distinct dotdels_dbt.t_code1
                                  ,dotdels_dbt.t_code2
                                  ,dotdels_dbt.t_name as name_otdel
                                  ,arh.t_oper
                                  ,arh.t_numb_document as numdoc
                                  ,arh.t_account_payer as accdeb
                                  ,acc1.t_nameaccount name1
                                  ,arh.t_account_receiver as acckr
                                  ,acc2.t_nameaccount name2
                                  --,arh.t_sum as sum
                                  ,arh.t_sum_natcur as sum
                                  ,arh.t_shifr_oper || '/' || t_kind_oper sh
                                  ,arh.t_ground as ground
                                  --,arh.t_iapplicationkind as appkind
                                  --,arh.t_applicationkey appkey
                                  ,arh.t_acctrnid
                                  ,arh.t_typedocument
                                  ,prop.t_paymentkind paymkind
                                  ,user_ea.getorigin ( paym.t_dockind, paym.t_paymentid ) origin
                                  ,arh.t_chapter chapter
                                  ,paym.t_dockind dockind
                                  ,arh.t_number_pack numb_pack
                                  ,arh.t_shifr_oper shifr_oper
                                  ,paym.t_fiid cred_fiid
                                  ,paym.t_payfiid deb_fiid
                                  --,arh.t_code_currency
                                  ,arh.t_fiid_payer t_code_currency
                                  ,paym.t_paymentid paymentid
                                  ,pers.t_name name_oper
                                  ,arh.t_userfield2 as operc
                   from --darhdoc_dbt arh
                        dacctrn_dbt arh
                       ,dpmdocs_dbt docs
                       ,dpmpaym_dbt paym
                       ,daccount_dbt acc1
                       ,daccount_dbt acc2
                       ,dotdels_dbt
                       ,dpmrmprop_dbt prop
                       , ( select *
                           from dop_otdel_dbt
                           where ( t_oper, t_datebegin ) in
                                         ( select t_oper, max ( t_datebegin ) t_datebegin
                                          from dop_otdel_dbt
                                          where t_datebegin <= p_repdate
                                            and ( t_dateend >= p_repdate or t_dateend = to_date ( '01.01.0001', 'DD.MM.YYYY' ) )
                                          group by t_oper ) ) dop_otdel_dbt
                       ,dperson_dbt pers
                   where arh.t_date_carry = p_repdate
                     and ( dop_otdel_dbt.t_dateend >= p_repdate or t_dateend = to_date ( '01.01.0001', 'DD.MM.YYYY' ) )
                     and t_datebegin <= p_repdate
                     and acc1.t_account(+) = arh.t_account_payer
                     and acc2.t_account(+) = arh.t_account_receiver
                     and arh.t_chapter = 3
                     and pers.t_oper = arh.t_oper
                     --and arh.t_applicationkey = docs.t_applicationkey(+)
                     and arh.t_acctrnid = docs.t_acctrnid(+)
                     and arh.t_fiid_payer = 0
                     and arh.t_fiid_receiver = 0
                     and docs.t_paymentid = paym.t_paymentid(+)
                     and prop.t_paymentid(+) = paym.t_paymentid
                     and ( ( substr ( arh.t_account_payer, 6, 3 ) = '810' and substr ( arh.t_account_receiver, 6, 3 ) = '810' )
                       or ( substr ( arh.t_account_payer, 6, 3 ) <> substr ( arh.t_account_receiver, 6, 3 ) ) )
                     and substr ( arh.t_account_payer, 1, 5 ) not in ('20202', '20203', '20207')
                     and substr ( arh.t_account_receiver, 1, 5 ) not in ('20202', '20203', '20207')
                     and arh.t_oper = dop_otdel_dbt.t_oper(+)
                     and dop_otdel_dbt.t_code1 = dotdels_dbt.t_code1(+)
                     and dop_otdel_dbt.t_code2 = dotdels_dbt.t_code2(+)
                     and dop_otdel_dbt.t_code1 = p_code1
                     and dop_otdel_dbt.t_code2 = p_code2 )
            order by t_oper, numdoc, accdeb, sum;
    end;

    /*Состояние лицевых счетов*/
    procedure get_accountbyday ( p_dep in    varchar
                                ,p_currency in varchar
                                ,p_null in   number
                                ,p_balance in varchar
                                ,p_usertype in varchar
                                ,p_repdate in date
                                ,p_connect in number
                                ,p_cursor   out sys_refcursor )
    is
    begin
        if ( p_currency = 1 )
        then
            open p_cursor for
                select inst.t_fi_code
                      ,acc.t_balance
                      ,acc.t_account
                      ,acc.t_nameaccount
                      , -- 27.12.2012 Golovkin доработка по ТЗ С-15512 Изменение знака у активных счетов
                       decode ( acc.t_kind_account,
                                'А', -rsb_account.resta ( acc.t_account, p_repdate, acc.t_chapter, null ),
                                rsb_account.resta ( acc.t_account, p_repdate, acc.t_chapter, null ) )
                           as rest
                      ,acc.t_kind_account
                      ,acc.t_open_date
                      ,acc.t_close_date
                      ,part.t_name
                from daccount_dbt acc, dfininstr_dbt inst, ddp_dep_dbt ddp, dparty_dbt part
                where rsb_mask.comparestringwithmask ( p_balance, substr ( acc.t_account, 1, 5 ) ) = 1
                  and acc.t_branch = ddp.t_code
                  and ddp.t_name = p_dep
                  and 1 =
                          ( case
                               when p_connect = 0
                               then
                                   1
                               when acc.t_type_account not like ( '%U%' )
                                and acc.t_type_account not like ( '%П%' )
                                and acc.t_type_account not like ( '%Н%' )
                               then
                                   1
                               else
                                   0
                           end )
                  and inst.t_fiid = acc.t_code_currency
                  and 1 = (case
                               when p_usertype is null then 1
                               when acc.t_usertypeaccount like p_usertype then 1
                               else 0
                           end)
                  and ( acc.t_open_close = chr ( 0 ) or acc.t_close_date > p_repdate )
                  and acc.t_open_date <= p_repdate
                  and 1 = (case
                               when p_null = 0 then 1
                               when rsb_account.resta ( acc.t_account, p_repdate, acc.t_chapter, null ) != 0 then 1
                               else 0
                           end)
                  and part.t_partyid = ddp.t_partyid
                order by acc.t_balance, acc.t_code_currency;
        else
            -- KS 28.11.2013 Перенос пользовательских доработок в 31ю сборку
            open p_cursor for
                select inst.t_fi_code
                      ,acc.t_balance
                      ,acc.t_account
                      ,acc.t_nameaccount
                      , -- 27.12.2012 Golovkin доработка по ТЗ С-15512 Изменение знака у активных счетов
                       decode ( acc.t_kind_account,
                                'А', -rsb_account.restac ( acc.t_account, acc.t_code_currency, p_repdate, acc.t_chapter, 0/*acc.t_r0*/ ),
                                rsb_account.restac ( acc.t_account, acc.t_code_currency, p_repdate, acc.t_chapter, 0/*acc.t_r0*/ ) )
                           as rest
                      ,acc.t_kind_account
                      ,acc.t_open_date
                      ,acc.t_close_date
                      ,part.t_name
                --from daccount$_dbt acc, dfininstr_dbt inst, ddp_dep_dbt ddp, dparty_dbt part
                from daccount_dbt acc, dfininstr_dbt inst, ddp_dep_dbt ddp, dparty_dbt part
                where rsb_mask.comparestringwithmask ( p_balance, substr ( acc.t_account, 1, 5 ) ) = 1
                  and acc.t_branch = ddp.t_code
                  and ddp.t_name = p_dep
                  and inst.t_fiid = acc.t_code_currency
                  and acc.t_code_currency != 0
                  and 1 = (case
                               when p_usertype is null then 1
                               when acc.t_usertypeaccount like p_usertype then 1
                               else 0
                           end)
                  and ( acc.t_open_close = chr ( 0 ) or acc.t_close_date > p_repdate )
                  and acc.t_open_date <= p_repdate
                  and 1 =
                          ( case
                               when p_null = 0
                               then
                                   1
                               when rsb_account.restac ( acc.t_account, acc.t_code_currency, p_repdate, acc.t_chapter, 0/*acc.t_r0*/ ) != 0
                               then
                                   1
                               else
                                   0
                           end )
                  and part.t_partyid = ddp.t_partyid
                order by acc.t_balance, acc.t_code_currency;
        end if;
    end;

    /* EVG 29/11/2012 Процедура для получения параметров тарифа комиссии (заявка C-12071) */
    procedure get_tarif_info ( p_account in varchar2
                              ,p_rscode in varchar2
                              ,p_ficode in varchar2
                              ,p_sfcomtype in number
                              ,p_sfcomcode in varchar2
                              ,p_date in   date
                              ,p_cursor   out sys_refcursor )
    is
        sfcontrid      number ( 10 );
        comnumber      number ( 5 );
    begin
        -- Если в параметре пришел счёт клиента, берём ДО по нему
        if p_account is not null
        then
            select t_id
            into sfcontrid
            from dsfcontr_dbt
            where t_objecttype = 1 and t_object = p_account;
        -- Если счёт не пришел, то попробуем найти актуальный ДО по "рс-коду" клиента
        elsif p_rscode is not null and p_ficode is not null
        then
            select max ( cntr.t_id )
            into sfcontrid
            from dobjcode_dbt code, dsfcontr_dbt cntr
            where code.t_objecttype = 3
              and code.t_codekind = 101
              and code.t_code = p_rscode
              and cntr.t_partyid = code.t_objectid
              and cntr.t_objecttype = 1
              and cntr.t_servkind = 3
              and cntr.t_datebegin <= p_date
              and ( cntr.t_dateclose > p_date or cntr.t_dateclose = to_date ( '01-01-0001', 'dd-mm-rrrr' ) )
              /* Наиболее вероятно, что актуальный тариф будет на расчётных счетах
                 клиента, поэтому наложим маску по номеру счёта и валюте.
                 Вариант, когда у клиента нету р/сч в нашем банке пока отбрасываем.*/
              and cntr.t_object like '40_0_' || p_ficode || '%';
        end if;

        -- Определяем ID комиссии
        select t_number
        into comnumber
        from dsfcomiss_dbt
        where t_feetype = p_sfcomtype and t_code = p_sfcomcode;

        -- Строим курсор с тарифом по комиссии
        -- KS 02.12.2013 Адаптация под 31ю сборку. updsftar193668.sql
        open p_cursor for
            with t
                    as (select nvl ( trf.t_tarifsum / 10000, 0 ) tval
                              ,nvl ( trf.t_minvalue / 10000, 0 ) minval
                              ,nvl ( trf.t_maxvalue / 10000, 0 ) maxval
                        from dsftarif_dbt trf
                            ,dsftarscl_dbt scl
                            ,dsfconcom_dbt concom
                            , ( select cp.t_sfplanid plid
                                from dsfcontrplan_dbt cp
                                where cp.t_sfcontrid = sfcontrid
                                  and cp.t_begin = (select max ( cp1.t_begin )
                                                    from dsfcontrplan_dbt cp1
                                                    where cp1.t_sfcontrid = cp.t_sfcontrid and cp1.t_begin <= p_date) ) sfplan
                        --where ( ( concom.t_objecttype = 659 and concom.t_objectid = sfcontrid and scl.t_sfplanid = sfplan.plid )
                          --  or ( concom.t_objecttype = 57 and concom.t_objectid = sfplan.plid and scl.t_objectid = sfplan.plid ) )
                          where ( ( concom.t_objecttype = 659 and concom.t_objectid = sfcontrid and concom.t_sfplanid = sfplan.plid )
                            or ( concom.t_objecttype = 57 and concom.t_objectid = sfplan.plid and concom.t_objectid = sfplan.plid ) )
                          and concom.t_feetype = p_sfcomtype
                          and concom.t_commnumber = comnumber
                          and scl.t_feetype = concom.t_feetype
                          and scl.t_commnumber = concom.t_commnumber
                          and ( scl.t_begindate <= p_date or scl.t_begindate = to_date ( '01-01-0001', 'DD-MM-YYYY' ) )
                          --and scl.t_objecttype = concom.t_objecttype
                          --and scl.t_objectid = concom.t_objectid
                          and scl.t_ConComID = concom.t_ID
                          and trf.t_tarsclid = scl.t_id
                        --order by scl.t_objecttype desc)
                        order by concom.t_objecttype desc)
            select *
            from t
            where rownum = 1;
    exception
        when others
        then
            null;
    end;

    procedure get_arhdocs ( p_datebegin in date, p_dateend in date, p_currency in varchar2, p_oper in number, p_cursor out sys_refcursor )
    is
    begin
        /*if ( p_currency = '810' )
        then
            open p_cursor for
                select doc.t_paymentid paymentid
                      ,arh.t_numb_documen num_document
                      ,arh.t_account_payer debet
                      ,arh.t_account_receiver credit
                      ,arh.t_sum sum
                      ,arh.t_ground ground
                from darhdoc_dbt arh, dpmdocs_dbt doc
                where arh.t_date_carry between p_datebegin and p_dateend
                  and arh.t_applicationkey = doc.t_applicationkey
                  and arh.t_iapplicationkind = doc.t_applicationkind
                  and arh.t_oper = p_oper;
        else*/
            open p_cursor for
                select doc.t_paymentid paymentid
                      ,arh.t_numb_document num_document
                      ,arh.t_account_payer debet
                      ,arh.t_account_receiver credit
                      --,arh.t_sum sum
                      ,arh.t_sum_payer sum
                      ,arh.t_ground ground
                from dacctrn_dbt /*darhdoc$_dbt*/ arh, dpmdocs_dbt doc, dfininstr_dbt fin
                where arh.t_date_carry between p_datebegin and p_dateend
                  --and arh.t_applicationkey = doc.t_applicationkey
                  --and arh.t_iapplicationkind = doc.t_applicationkind
                  and arh.t_acctrnid = doc.t_acctrnid
                  and arh.t_oper = p_oper
                  --and fin.t_fiid = arh.t_code_currency
                  and fin.t_fiid = arh.t_fiid_payer
                  and fin.t_fi_code = p_currency;
        --end if;
    end;


    
    /* EVG 9/07/2013 Процедура для загрузки даты окончания периода оплаты из RS Bank во Фронт Лайф (заявка C-21263) */
    procedure get_sfdef ( p_date   in  date
                         ,p_cursor out sys_refcursor )
    is
    begin

        -- Строим курсор с результирующей информацией
        open p_cursor for
         select rownum, rp.*
           from    
            ( select sfd.t_sum comSum, contr.t_object comAcc, contr.t_partyid comClient,
                     -- Наверное, КПП не нужно. Если не так, уберите CASE и оставьте просто code.t_code
                     CASE WHEN ( instr(  code.t_code, '/' ) > 0 )
                          THEN substr( code.t_code, 1, (instr(code.t_code, '/')-1) )
                          ELSE code.t_code
                     END clientInn,  
                     com.t_code comCode
                from dsfdef_dbt sfd,
                     dsfcomiss_dbt com,
                     dsfcontr_dbt contr,
                     dobjcode_dbt code
               where com.t_feetype = 1
                 and com.t_code in ( '2.2.1',          -- банки РББ, ЭВ, ГЭБ, комиссия за годовое обслуживание
                                     '2.2.2',          --      -- // --     , комиссия с оплатой раз в полгода
                                     '2.2.3.1',        -- банк ВУЗ, годовое обслуживание
                                     '2.2.3.2',        -- -- // --, годовое обслуживание
                                     '2.2.3.4' )       -- -- // --, комиссия с оплатой раз в полгода
                 and sfd.t_feetype       = com.t_feetype
                 and sfd.t_commnumber    = com.t_number
                 and sfd.t_status        = 40
                 and sfd.t_dateperiodend = p_date
                 and contr.t_id          = sfd.t_sfcontrid
                 and code.t_objecttype   = 3
                 and code.t_objectid     = contr.t_partyid
                 and code.t_codekind     = 16
                 and code.t_state        = 0
                 order by com.t_code, sfd.t_sum ) rp;
              
    exception
        when others
        then
            null;
    end;    
end; 
/
