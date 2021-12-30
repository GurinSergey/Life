CREATE OR REPLACE PACKAGE usr_operations_proc
AS
   PROCEDURE start_operations (p_dockind            NUMBER,
                               p_paymentid          NUMBER,
                               p_error       IN OUT VARCHAR);

   PROCEDURE finish_operations (p_dockind            NUMBER,
                                p_paymentid          NUMBER,
                                p_error       IN OUT VARCHAR);
END; 
/
CREATE OR REPLACE PACKAGE BODY usr_operations_proc
AS
   ----------- виды документов --------------------------------
   C_DOCKIND_CASH_IN CONSTANT               NUMBER := 430;   -- кассовый, приходный
   C_DOCKIND_CASH_OUT CONSTANT              NUMBER := 440;   -- кассовый, расходный
   C_DOCKIND_CASH_INOUT CONSTANT            NUMBER := 400;   -- кассовый, подкрепление
   C_DOCKIND_MEMORDER CONSTANT              NUMBER := 70;        -- мем. ордер
   C_DOCKIND_MEMORDER_BANK_ORDER CONSTANT   NUMBER := 286;   -- банковский ордер для 30ки
   C_DOCKIND_MULTYCARRY CONSTANT            NUMBER := 15;   -- мультивалютный
   C_DOCKIND_BANK_PAYM CONSTANT             NUMBER := 16;         -- платеж ББ
   C_DOCKIND_BANK_ORDER CONSTANT            NUMBER := 17;   -- требование ББ (только рубли)
   C_DOCKIND_CLIENT_PAYM CONSTANT           NUMBER := 2011;      -- платеж РКО
   C_DOCKIND_CLIENT_ORDER CONSTANT          NUMBER := 2012;   -- требование РКО (только рубли)
   C_DOCKIND_CLIENT_CASH_IN CONSTANT        NUMBER := 410;   -- объявление на взнос наличных
   C_DOCKIND_CLIENT_CASH_OUT CONSTANT       NUMBER := 420;   -- клиентский чек
   C_DOCKIND_EXTERNAL_IN CONSTANT           NUMBER := 320;   -- внешний входящий платёж-- KS 25.05.2011 C-731
   C_DOCKIND_CLIENT_PAYM_B CONSTANT         NUMBER := 2001;   -- покупка валюты
   C_DOCKIND_CLIENT_PAYM_S CONSTANT         NUMBER := 2002;   -- продажа валюты
   C_DOCKIND_CLIENT_PAYM_K CONSTANT         NUMBER := 2003;   -- конверсия валюты
   C_DOCKIND_CLIENT_PAYM_VAL CONSTANT       NUMBER := 202;   -- валютный платеж РКО
   C_DOCKIND_BANK_PAYM_VAL CONSTANT         NUMBER := 27;   -- валютный платеж банка
   C_DOCKIND_BANK_PAYM_VAL_BNK CONSTANT     NUMBER := 666;   -- валютный платеж банка (позиционируется в МБР как общий банковский перевод) zip_z. 2013-03-04 C-16618


   /*** КОДЫ ПОЛЬЗОВАТЕЛЬСКИХ ИСКЛЮЧЕНИЙ ***/
   e_error_start_operation EXCEPTION;
   e_error_run_operation EXCEPTION;


   PROCEDURE change_stats_oper
   IS
      stat   NUMBER;
   -- kind_oper     NUMBER;
   -- oprblock_id   NUMBER;
   BEGIN
      /* SELECT   o.t_kind_operation, opb.t_operblockid
         INTO   kind_oper, oprblock_id
         FROM   doproblck_dbt opb, doprblock_dbt bl, doprkoper_dbt o
        WHERE       opb.t_kind_operation = o.t_kind_operation
                AND opb.t_blockid = bl.t_blockid
                AND UPPER (bl.t_name) LIKE 'ЗАЧИСЛЕНИЕ'
                AND o.t_dockind = 29
                AND o.t_notinuse <> 'X'
                AND o.t_kind_operation > 0;

       FOR i IN (SELECT   t_statuskindid, t_numvalue
                   FROM   doprinist_dbt
                  WHERE   t_kind_operation = kind_oper
                 UNION
                 SELECT   t_statuskindid, t_numvalue
                   FROM   doprcblck_dbt
                  WHERE   t_operblockid = oprblock_id AND t_condition = 0)
       LOOP*/
      stat := rsbemoperation.opr_setoprstatusvalue (117, 2);
      stat := rsbemoperation.opr_setoprstatusvalue (118, 1);
      stat := rsbemoperation.opr_setoprstatusvalue (292, 4);
      stat := rsbemoperation.opr_setoprstatusvalue (296, 2);
      stat := rsbemoperation.opr_setoprstatusvalue (305, 1);
      stat := rsbemoperation.opr_setoprstatusvalue (307, 2);


      IF stat <> 0
      THEN
         RAISE e_error_start_operation;
      END IF;
   -- END LOOP;
   END;

   FUNCTION is_external (p_paymentid IN NUMBER)
      RETURN BOOLEAN
   IS
      v_pgroup    NUMBER;
      v_psender   CHAR;
      v_rgroup    NUMBER;
      v_rsender   CHAR;
   BEGIN
      SELECT   PAYER.T_GROUP pgroup,
               PAYER.T_ISSENDER psender,
               receiver.T_GROUP rgroup,
               receiver.T_ISSENDER rsender
        INTO   v_pgroup,
               v_psender,
               v_rgroup,
               v_rsender
        FROM   dpmprop_dbt payer, dpmprop_dbt receiver
       WHERE       PAYER.T_DEBETCREDIT = 0
               AND RECEIVER.T_DEBETCREDIT = 1
               AND payer.t_paymentid = receiver.t_paymentid
               AND payer.t_paymentid = p_paymentid;

      IF ( (v_pgroup = pm_common.PAYMENTS_GROUP_EXTERNAL
            AND v_psender != pm_common.SET_CHAR)
          AND v_rgroup != pm_common.PAYMENTS_GROUP_EXTERNAL)
         OR ( (v_rgroup = pm_common.PAYMENTS_GROUP_EXTERNAL
               AND v_rsender != pm_common.SET_CHAR)
             AND v_pgroup != pm_common.PAYMENTS_GROUP_EXTERNAL)
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END is_external;

   PROCEDURE insert_payment_into_tmptable (p_paymentid IN NUMBER)
   IS
   BEGIN
      DELETE FROM   doprtemp_tmp;

      INSERT INTO doprtemp_tmp (t_id_operation,
                                t_sort,
                                t_dockind,
                                t_documentid,
                                t_orderid,
                                t_kind_operation,
                                t_start_date,
                                t_isnew,
                                t_id_step)
         (SELECT   op.t_id_operation,
                   NULL,
                   pmpaym.t_dockind,
                   LPAD (TO_CHAR (pmpaym.t_paymentid), 34, '0'),
                   pmpaym.t_paymentid,
                   DECODE (
                      op.t_kind_operation,
                      0,
                      (SELECT   MIN (t_kind_operation)
                         FROM   doprkoper_dbt
                        WHERE       t_dockind = 29
                                AND t_notinuse = CHR (0)
                                AND t_kind_operation > 0),
                      op.t_kind_operation
                   ),
                   rsbsessiondata.curdate,
                   CHR (88),
                   NULL
            FROM   dpmpaym_dbt pmpaym, doproper_dbt op
           WHERE   op.t_documentid =
                      LPAD (TO_CHAR (pmpaym.t_paymentid), 34, '0')
                   AND op.t_dockind = pmpaym.t_dockind
                   AND pmpaym.t_paymentid = p_paymentid);
   END;

   PROCEDURE start_operations (p_dockind            NUMBER,
                               p_paymentid          NUMBER,
                               p_error       IN OUT VARCHAR)
   IS
      paym           NUMBER;
      v_dockind      NUMBER;
      lv_stat        NUMBER;
      v_last_error   VARCHAR (4000);
      v_oper         NUMBER;
   BEGIN
      v_last_error := 'no_error';

      SELECT   t_oper
        INTO   v_oper
        FROM   dpmpaym_dbt
       WHERE   t_paymentid = p_paymentid;

      insert_payment_into_tmptable (p_paymentid);
       --Статус операции Документооборот Зачисление (4)


      change_stats_oper ();

      lv_stat := rsbemoperation.opr_startoperation ();

      IF lv_stat <> 0
      THEN
         v_last_error :=
            'ошибка при старте операции(opr_startoperation), код ' || lv_stat;
         RAISE e_error_start_operation;
      END IF;

      --установка статусов первички
      IF p_dockind = c_dockind_memorder
      THEN
         lv_stat :=
            bb_memorder.changememorderstatus (
               0,
               bb_memorder.cb_doc_state_working,
               0,
               0
            );
      ELSIF p_dockind IN (c_dockind_cash_in, c_dockind_cash_out, c_dockind_cash_inout, c_dockind_client_cash_in, c_dockind_client_cash_out)
      THEN
         lv_stat :=
            rsb_cashord.changecashordstatus (
               0,
               rsb_cashord.stat_cash_order_open,
               0,
               0
            );
      ELSIF p_dockind = c_dockind_multycarry
      THEN
         lv_stat :=
            bb_multydoc.changemultydocstatus (0,
                                              bb_multydoc.mcdoc_status_open,
                                              0,
                                              0);
      ELSIF p_dockind = c_dockind_bank_paym
      THEN
         lv_stat :=
            bb_bankpaym.changebankpaymstatus (
               0,
               bb_bankpaym.memorder_status_open,
               0,
               0
            );
      END IF;


      IF lv_stat <> 0
      THEN
         v_last_error :=
            'ошибка при смене статуса документа первички, код ' || lv_stat;
         RAISE e_error_start_operation;
      END IF;

      --установка статусов платежа
      IF p_dockind != c_dockind_external_in
      THEN
         -- KS 08.06.2011 Для внешних входящих оставим 2990
         lv_stat :=
            pm_common.changepaymstatus (0,
                                        1000,
                                        0,
                                        0,
                                        v_oper);

         IF lv_stat != 0
         THEN
            v_last_error :=
               'ошибка при изменении статуса платежа, код ' || lv_stat;
            RAISE e_error_start_operation;
         END IF;
      END IF;

      lv_stat :=
         pm_common.changepmpropstatus (0,
                                       NULL,
                                       pm_common.pm_finished,
                                       NULL);

      IF lv_stat != 0
      THEN
         v_last_error :=
            'ошибка при изменении внешнего статуса платежа, код ' || lv_stat;
         RAISE e_error_start_operation;
      END IF;

      --установка статусов операции
      lv_stat := rsbemoperation.opr_setoprstatusvalue (291, 2);

      --Состояние платежа=Открыт

      IF lv_stat != 0
      THEN
         v_last_error :=
            'ошибка при установке статуса операции(открыт), код ' || lv_stat;
         RAISE e_error_start_operation;
      END IF;


      --  usr_payments
      -- очистка временной таблицы
      DELETE FROM   doprtemp_tmp;

      P_ERROR := v_last_error;
   EXCEPTION
      WHEN e_error_start_operation
      THEN
         p_error := v_last_error;
         ROLLBACK;
      WHEN OTHERS
      THEN
         p_error :=
               'ошибка выполнения операции: '
            || DBMS_UTILITY.format_error_stack
            || DBMS_UTILITY.format_error_backtrace;
         ROLLBACK;
   END start_operations;

   PROCEDURE finish_operations (p_dockind            NUMBER,
                                p_paymentid          NUMBER,
                                p_error       IN OUT VARCHAR)
   IS
      v_is_external   BOOLEAN;
      v_dockind       NUMBER;
      v_stat          NUMBER;
      v_oper          NUMBER;
      v_last_error    VARCHAR (4000);
   BEGIN
      v_is_external := is_external (p_paymentid);
      v_dockind := p_dockind;
      v_last_error := 'no_error';

      SELECT   t_oper
        INTO   v_oper
        FROM   dpmpaym_dbt
       WHERE   t_paymentid = p_paymentid;

      insert_payment_into_tmptable (p_paymentid);

      -- insert into doprtemp_tmp
      --
      UPDATE   doprtemp_tmp
         SET   t_id_step = 1;

      -- выполняется шаг операции по платежам, к которым проводки прошли без ошибок
      -- и в случае, если есть такие платежи
      IF v_dockind = c_dockind_memorder
      THEN
         v_stat :=
            bb_memorder.changememorderstatus (
               0,
               bb_memorder.cb_doc_state_closed,
               0,
               0
            );
      ELSIF v_dockind IN (c_dockind_cash_in, c_dockind_cash_out, c_dockind_cash_inout, c_dockind_client_cash_in, c_dockind_client_cash_out)
      THEN
         v_stat :=
            rsb_cashord.changecashordstatus (
               0,
               rsb_cashord.stat_cash_order_close,
               0,
               0
            );
      ELSIF v_dockind = c_dockind_multycarry
      THEN
         v_stat :=
            bb_multydoc.changemultydocstatus (0,
                                              bb_multydoc.mcdoc_status_close,
                                              0,
                                              0);
      ELSIF v_dockind = c_dockind_bank_paym AND (NOT v_is_external)
      THEN
         v_stat :=
            bb_bankpaym.changebankpaymstatus (
               0,
               bb_bankpaym.memorder_status_close,
               0,
               0
            );
      END IF;



      IF NOT v_is_external
      THEN
         v_stat :=
            pm_common.changepaymstatus (0,
                                        pm_common.pm_finished,
                                        0,
                                        0,
                                        v_oper);

         -- KS 03.08.2011 Адаптация Патч 30
         UPDATE   dpmpaym_dbt pm
            SET   pm.t_closedate = rsbsessiondata.m_curdate
          WHERE   pm.t_paymentid IN
                        (SELECT   tmp.t_orderid
                           FROM   doprtemp_tmp tmp
                          WHERE   tmp.t_errorstatus = 0
                                  AND tmp.t_skipdocument = 0);
      ELSE
         v_stat :=
            pm_common.changepaymstatus (0,
                                        pm_common.pm_ready_to_send,
                                        0,
                                        0,
                                        v_oper);
      END IF;

      IF v_stat != 0
      THEN
         v_last_error :=
            'ошибка при изменении статуса платежа, код ' || v_stat;
         RAISE e_error_run_operation;
      END IF;

      IF NOT v_is_external
      THEN
         v_stat :=
            pm_common.changepmpropstatus (0,
                                          NULL,
                                          pm_common.pm_finished,
                                          NULL);
      END IF;

      IF v_stat != 0
      THEN
         v_last_error :=
            'ошибка при изменении внешнего статуса документа, код ' || v_stat;
         RAISE e_error_run_operation;
      END IF;

      IF NOT v_is_external
      THEN
         --Состояние платежа=Закрыт
         v_stat := rsbemoperation.opr_setoprstatusvalue (291, 3);
      ELSE
         --Документооборот = Выгрузка
         v_stat := rsbemoperation.opr_setoprstatusvalue (292, 2);
         --Направление=Исходящий
         v_stat := rsbemoperation.opr_setoprstatusvalue (295, 3);
      END IF;

      IF v_stat != 0
      THEN
         v_last_error :=
            'ошибка при установке статуса операции, код ' || v_stat;
         RAISE e_error_run_operation;
      END IF;

      v_stat := rsbemoperation.opr_massexecutestep (NULL);

      IF v_stat != 0
      THEN
         v_last_error := 'ошибка при выполнения шага, код ' || v_stat;
         RAISE e_error_run_operation;
      END IF;

      p_error := v_last_error;
   EXCEPTION
      WHEN e_error_run_operation
      THEN
         p_error := v_last_error;
         ROLLBACK;
      WHEN OTHERS
      THEN
         p_error :=
               'ошибка выполнения операции: '
            || DBMS_UTILITY.format_error_stack
            || DBMS_UTILITY.format_error_backtrace;
         ROLLBACK;
   END;
--usr_payments

END usr_operations_proc; 
/
