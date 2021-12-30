CREATE OR REPLACE PACKAGE "USR_CLAIMS"
IS
   function get_curdate (p_department number)
      return date;

   PROCEDURE insert_claim (p_account       VARCHAR2,
                           p_oper          NUMBER,
                           p_comment       VARCHAR2 DEFAULT NULL ,
                           p_sum           NUMBER,
                           p_error     OUT VARCHAR2);

   PROCEDURE insert_claim_trn (p_account       VARCHAR2,
                               p_oper          NUMBER,
                               p_comment       VARCHAR2 DEFAULT NULL ,
                               p_sum           NUMBER,
                               p_error     OUT VARCHAR2);

   PROCEDURE delete_claim (p_account       VARCHAR2,
                           p_sum           NUMBER,
                           p_comment       VARCHAR2 DEFAULT NULL ,
                           p_error     OUT VARCHAR2);

   PROCEDURE delete_claim_trn (p_account       VARCHAR2,
                               p_sum           NUMBER,
                               p_comment       VARCHAR2 DEFAULT NULL ,
                               p_error     OUT VARCHAR2);

   PROCEDURE bind_fr_claim (p_account         VARCHAR2,
                            p_sum             NUMBER,
                            p_paymentid       NUMBER,
                            p_error       OUT VARCHAR2);

   FUNCTION get_claim (p_partyid IN NUMBER)
      RETURN NUMBER;

   FUNCTION usr_CheckInsUpdAcClaim (p_Chapter       IN NUMBER    --Глава счета
                                                             ,
                                    p_Account       IN VARCHAR2  --Номер счета
                                                               ,
                                    p_FIID          IN NUMBER   --Валюта счета
                                                             ,
                                    p_ClaimKind     IN NUMBER  --Вид претензии
                                                             ,
                                    p_RestKind      IN NUMBER  --Тип претензии
                                                             ,
                                    p_StartDate     IN DATE --Дата начала действия
                                                           ,
                                    p_StartAmount   IN NUMBER --Сумма претензии
                                                             ,
                                    p_Priority      IN NUMBER      --Приоритет
                                                             ,
                                    p_Incremental   IN NUMBER --Признак накопительной
                                                           )
      RETURN INTEGER; --LAO 20.08.2013 функция проверки возможности вставки претензии
END; 
/
CREATE OR REPLACE PACKAGE BODY USR_CLAIMS
is
   c_default_comm   constant varchar2 (64) := 'блокировка остатка инициирована внешней системой';
   -- состояние пакета, если null - то нужна инициализация;
   v_state                   number;
   e_account_notfound        exception;
   e_account_closed          exception;
   e_invalid_acc_kind        exception;
   e_department_notfound     exception;

   cursor cr_operday
   is
      --курсор для определения опердня в филиалах
      select   max (d.t_curdate) t_curdate, d.t_branch
          from dcurdate_dbt d
         where d.t_isclosed <> chr (88)
      group by d.t_branch;

   cursor cr_acc (account varchar2, chapter number)
   is
      --курсор определяющие основные атрибуты счета
      -- KS 28.11.2013 Перенос пользовательских доработок в 31ю сборку
      select   ac.t_open_close, ac.t_kind_account, ac.t_department, ac.t_oper, --ac.t_planrest,
               rsi_rsb_account.planresta(account, get_curdate(ac.t_department) , chapter) t_planrest,
               nvl (sum (cl.t_startamount), 0) claim_sum
          from daccount_dbt ac, dacclaim_dbt cl
         where ac.t_account = account and ac.t_chapter = chapter and cl.t_account(+) = ac.t_account
               and cl.t_chapter(+) = ac.t_chapter
               and ac.t_code_currency = 0
      --group by ac.t_open_close, ac.t_kind_account, ac.t_department, ac.t_oper, ac.t_planrest;
      group by ac.t_open_close, ac.t_kind_account, ac.t_department, ac.t_oper, 
               rsi_rsb_account.planresta(account, get_curdate(ac.t_department) , chapter);

   type acc_parm_rec is record (
      t_open_close     daccount_dbt.t_open_close%type,
      t_kind_account   daccount_dbt.t_kind_account%type,
      t_department     daccount_dbt.t_department%type,
      t_oper           daccount_dbt.t_oper%type,
      -- KS 28.11.2013 Перенос пользовательских доработок в 31ю сборку
      --t_planrest       daccount_dbt.t_planrest%type,
      t_planrest       drestdate_dbt.t_planrest%type,
      claim_sum        dacclaim_dbt.t_startamount%type
   );

   type curdate_nt is table of cr_operday%rowtype;

   nt_curdate                curdate_nt;

   procedure init
   is
   begin
      if v_state is null
      then
         --здесь инициализация
         usr_common.init;
         v_state := 1;

         open cr_operday;

         fetch cr_operday
         bulk collect into nt_curdate;

         close cr_operday;
      end if;
   end;

   function get_curdate (p_department number)
      return date
   is
      --функция определения опердня в нужном филиале
      v_date   date;
   begin
      for i in nt_curdate.first .. nt_curdate.last
      loop
         if nt_curdate (i).t_branch = p_department
         then
            v_date := nt_curdate (i).t_curdate;
            exit;
         end if;
      end loop;

      if v_date is null
      then
         raise e_department_notfound;
      end if;

      return v_date;
   end;

   function get_acc_parm (p_account number)
      return acc_parm_rec
   is
      rec_acc_parm   acc_parm_rec;
   begin
      open cr_acc (p_account, usr_common.get_chapter (p_account));

      fetch cr_acc
       into rec_acc_parm;

      if cr_acc%rowcount = 0
      then
         close cr_acc;

         raise e_account_notfound;
      end if;

      close cr_acc;

      if rec_acc_parm.t_open_close = 'З'
      then
         raise e_account_closed;
      elsif instr (rec_acc_parm.t_kind_account, 'П') = 0
      then
         raise e_invalid_acc_kind;
      end if;

      return rec_acc_parm;
   end;

   procedure insert_claim_trn (
      p_account         varchar2,
      p_oper            number,
      p_comment         varchar2 default null,
      p_sum             number,
      p_error     out   varchar2
   )
   is
      v_recid     number;
      v_claimid   number;
      acc_parm    acc_parm_rec;
   begin
   
      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_claims'),
                                            UPPER ('insert_claim_trn'),
                                            ku$_vcnt (p_account,
                                                      p_oper,
                                                      p_comment,
                                                      p_sum,
                                                      p_error));
                                                      
      init;
      p_error := usr_common.c_err_success;
      acc_parm := get_acc_parm (p_account);

      if abs (acc_parm.t_planrest) - acc_parm.claim_sum < p_sum
      then
         p_error := 'ошибка создания претензии: недостаточно средств для блокировки';
      else
         rsi_rsb_acclaim.makereserve_ex (dockind         => null,
                                         documentid      => null,
                                         account_        => p_account,
                                         chapter         => usr_common.get_chapter (p_account),
                                         fiid            => usr_common.get_fiid (p_account),
                                         docnumber       => chr(1),
                                         docdate         => usr_common.c_nulldate,
                                         sysdate         => trunc (sysdate),
                                         startdate       => get_curdate (acc_parm.t_department),
                                         amount          => p_sum,
                                         oper            => p_oper,
                                         recid           => v_recid,
                                         claimid         => v_claimid,
                                         comment         => nvl (p_comment, c_default_comm)
                                        );
      end if;
   exception
      when e_account_notfound
      then
         p_error := 'ошибка создания претензии: счет не найден';
         rollback;
      when e_account_closed
      then
         p_error := 'ошибка создания претензии: счет закрыт';
         rollback;
      when e_invalid_acc_kind
      then
         p_error := 'ошибка создания претензии: счет должен быть пассивным';
         rollback;
      when e_department_notfound
      then
         p_error := 'ошибка создания претензии: не определен филиал по счету';
         rollback;
      when others
      then
         p_error := 'ошибка создания претензии: ' || sqlerrm;
         rollback;
   end;

   procedure insert_claim (
      p_account         varchar2,
      p_oper            number,
      p_comment         varchar2 default null,
      p_sum             number,
      p_error     out   varchar2
   )
   is
   begin
   
      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_claims'),
                                            UPPER ('insert_claim'),
                                            ku$_vcnt (p_account,
                                                      p_oper,
                                                      p_comment,
                                                      p_sum,
                                                      p_error));
                                                      
      insert_claim_trn (p_account      => p_account,
                        p_oper         => p_oper,
                        p_comment      => p_comment,
                        p_sum          => p_sum,
                        p_error        => p_error
                       );
      commit;
   end;

   procedure delete_claim_trn (
      p_account                varchar2,
      p_sum                    number,
      p_comment                varchar2 default null,
      p_error     out nocopy   varchar2
   )
   is
      v_claimid   number;
      v_stat      number;
      acc_parm    acc_parm_rec;
   begin
   
      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_claims'),
                                            UPPER ('delete_claim_trn'),
                                            ku$_vcnt (p_account,
                                                      p_sum,
                                                      p_comment,
                                                      p_error));
                                                      
      p_error := usr_common.c_err_success;
      init;
      acc_parm := get_acc_parm (p_account);
      v_claimid :=
         rsi_rsb_acclaim.searchreserve (account      => p_account,
                                        chapter      => usr_common.get_chapter (p_account),
                                        fiid         => usr_common.get_fiid (p_account),
                                        psum         => p_sum,
                                        comment      => nvl (p_comment, c_default_comm)
                                       );

      if v_claimid <> 0
      then
         v_stat := rsi_rsb_acclaim.freereserveex (v_claimid);

         if v_stat <> 0
         then
            p_error := 'ошибка снятия претензии: код=' || v_stat;
         end if;
      else
         p_error := 'ошибка снятия претензии: запись претензии не найдена';
      end if;
   exception
      when e_account_notfound
      then
         p_error := 'ошибка снятия претензии: счет не найден';
         rollback;
      when e_account_closed
      then
         p_error := 'ошибка снятия претензии: счет закрыт';
         rollback;
      when e_invalid_acc_kind
      then
         p_error := 'ошибка снятия претензии: счет должен быть пассивным';
         rollback;
      when others
      then
         p_error := 'ошибка снятия претензии: ' || sqlerrm;
         rollback;
   end;

   procedure delete_claim (p_account varchar2, p_sum number, p_comment varchar2 default null, p_error out varchar2)
   is
   begin
   
      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_claims'),
                                            UPPER ('delete_claim'),
                                            ku$_vcnt (p_account,
                                                      p_sum,
                                                      p_comment,
                                                      p_error));
      init;
      delete_claim_trn (p_account => p_account, p_sum => p_sum, p_comment => p_comment, p_error => p_error);

      if p_error = usr_common.c_err_success
      then
         commit;
      end if;
   end;

   procedure bind_fr_claim (p_account varchar2, p_sum number, p_paymentid number, p_error out varchar2)
   is
      v_stat      number;
      v_claimid   number;
   begin
   
      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_claims'),
                                            UPPER ('bind_fr_claim'),
                                            ku$_vcnt (p_account,
                                                      p_sum,
                                                      p_paymentid,
                                                      p_error));   
   
      init;
      p_error := usr_common.c_err_success;
      v_claimid :=
         rsi_rsb_acclaim.searchreserve (account      => p_account,
                                        chapter      => usr_common.get_chapter (p_account),
                                        fiid         => usr_common.get_fiid (p_account),
                                        psum         => p_sum,
                                        comment      => usr_common.c_fr_comment
                                       );

      if v_claimid <> 0
      then
         v_stat := rsi_rsb_acclaim.bindreserveex (claimid => v_claimid, dockind => 201, documentid => p_paymentid);

         if v_stat = 2
         then
            p_error := 'ошибка привязки претензии: '||v_stat;
            rollback;
         else
            commit;
         end if;
      else
         p_error := 'ошибка привязки претензии: запись претензии не найдена';
         rollback;
      end if;
   exception
      when others
      then
         p_error := 'ошибка привязки претензии:' || sqlerrm;
         rollback;
   end;

   -- KS 12.07.2012 C-12384 
   --    Разработать процедуру . При обращении к ней ФРОНТ отправляет ИД Клиента, а РСБанк возвращает  значение тип данных: "Истина/Ложь"
   --    При таком обращении РСБанк должен анализировать приостановления по счетам Клиента с заданным ИД и если есть активные, возвращать "Истина".
   --    При этом: 1. В поле инициатор должно стоять налоговый орган, 2. В поле статус: Активно. 
   --    Анализ должен быть проведен по всем счетам Клиента (открытым и закрытым).
   function get_claim (p_partyid in number)
     return number
   is
     cnt number(1);
   begin
      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_claims'),
                                            UPPER ('get_claim'),
                                            ku$_vcnt (p_partyid));
     --return true;
     
     -- тк эта функция выпадает из всего пакета, то не буду использовать местные функции по
     -- определению текущено опердня. Использую usr_common.getcurdate
     -- Перебираю счета по одному. Как ни странно так получилось быстрее.
     -- В 31м патче, когда будет одна таблица счетов, можно попробовать переделать
     -- KS 28.11.2013 Перенос пользовательских доработок в 31ю сборку
     for rec in (select a.t_account,a.t_code_currency,a.t_chapter from daccount_dbt a where a.t_client = p_partyid
                 /*union
                 select a.t_account,a.t_code_currency,a.t_chapter from daccount$_dbt a where a.t_client = p_partyid*/)
      loop
        -- макет запроса взял из доработок в RSI_RSB_ACCLAIM
        select count(1) into cnt
          from dacclaim_dbt t,dacclaimstate_dbt st 
         where t.t_claimid = st.t_claimid 
           and (st.t_claimid, st.t_statedate) in 
               (select s.t_claimid, max(s.t_statedate) 
                  from dacclaimstate_dbt s 
                 where s.t_claimid in 
                       (select t_claimid 
                          from dacclaim_dbt 
                         where t_account = rec.t_account
                           and t_fiid = rec.t_code_currency
                           and t_chapter = rec.t_chapter)
                   -- берём все статусы с корректной датой
                   and s.t_statedate <= usr_common.getcurdate(1)
                   /*and ( s.t_state in (1,2,4)
                         or (s.t_state = 5 AND s.t_statedate <= usr_common.getcurdate(1))) */
                 group by s.t_claimid) 
           and st.t_state in (1,2)
           and t.t_initiator = 1
           and rownum = 1;
         if cnt>0 then -- быстрый выход
           return 1;
         end if;
      end loop;
      return 0;
   end;
   
   --LAO 20.02.2013 проверяем возможность вставки преетнзии
   FUNCTION USR_CheckInsUpdAcClaim
  ( p_Chapter       IN  NUMBER   --Глава счета
   ,p_Account       IN  VARCHAR2 --Номер счета
   ,p_FIID          IN  NUMBER   --Валюта счета
   ,p_ClaimKind     IN  NUMBER   --Вид претензии
   ,p_RestKind      IN  NUMBER   --Тип претензии
   ,p_StartDate     IN  DATE     --Дата начала действия
   ,p_StartAmount   IN  NUMBER   --Сумма претензии
   ,p_Priority      IN  NUMBER   --Приоритет
   ,p_Incremental   IN  NUMBER     --Признак накопительной
  ) RETURN INTEGER
  IS
    m_FreeAmount NUMBER;
  BEGIN

   

      IF p_ClaimKind = RSI_RSB_ACCLAIM.ACCLAIM_KIND_SPECIAL OR
        (p_ClaimKind =RSI_RSB_ACCLAIM.ACCLAIM_KIND_ARREST AND p_Incremental = 0 AND
        (p_RestKind = RSI_RSB_ACCLAIM.ACCLAIM_TYPE_AMOUNT OR p_RestKind = RSI_RSB_ACCLAIM.ACCLAIM_TYPE_SECUR)) THEN
        --проверяем свободный остаток на дату начала действия претензии
        m_FreeAmount := RSI_RSB_ACCLAIM.GetFreeAmountForInputClaim(p_Account
                                                  ,p_Chapter
                                                  ,p_FIID
                                                  ,p_StartDate
                                                  ,p_Priority
                                                  );
        IF m_FreeAmount < p_StartAmount THEN
          RETURN 1;
        END IF;
      END IF;

    

    RETURN 0;
  END;
end; 
/
