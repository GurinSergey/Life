create or replace package usr_operations
is
   c_execstep_func constant    number (5) := 1;
   c_operation_type constant   number (5) := 8;

   type payments_rec is record (paymentid number (10), dockind  number (5));

   type payments_nt is table of payments_rec;

   nt_payments                 payments_nt := payments_nt ();

   --процедура исполняет шаги операции в т.ч.пакетно
   procedure rsb_execute_step (p_paymentid         number,
                               p_dockind           number,
                               p_packmode          number,
                               p_pack_id       out number,
                               p_error_count   out number,
                               p_error         out varchar2,
                               p_logging in boolean default true
                                                           );

   --функция выполнения шага операции без записи в журнал usr_operations_log
   function rsb_execute_step_nolog (p_paymentid number, p_dockind number)
      return varchar2;

   --процедура исполняет шаги операции по платежам в doprtemp_tmp
   --с учетом очередности и в порядке поступления
   procedure exec_steps_for_temp;
end;
/
CREATE OR REPLACE PACKAGE BODY usr_operations
IS 
    gv_cnt       pls_integer; --счетчик записей 
    gv_pack_id   number (10); --ID пакета 
    gv_rindex    pls_integer; --ID "градусника" процесса в V$SESSION_LONGOPS 

    PROCEDURE rsb_execute_step (p_paymentid         number, 
                                p_dockind           number, 
                                p_packmode          number, 
                                p_pack_id       OUT number, 
                                p_error_count   OUT number, 
                                p_error         OUT varchar2, 
                                p_logging IN boolean DEFAULT TRUE ) 
    IS 
        v_stat         number; 
        v_retpmid      number (10); 
        v_ret_string   varchar2 (4000); 
        v_message      varchar2 (64); 
        v_ret_pipe     varchar2 (64); 
        v_slno         pls_integer; 
        v_logging      varchar2 (10); 
        v_dockind number; -- 2013-03-14 zip_z. C-16618 

        PROCEDURE reg_payment (pm payments_rec) IS 
        BEGIN 
            INSERT INTO usr_operations_log (pack_id, paymentid, dockind, error_text) VALUES (p_pack_id, pm.paymentid, pm.dockind, 'платеж ожидает обработки'); 
            COMMIT; 
        END; 

        PROCEDURE reg_payment_error (p_paymentid number, p_error_text varchar2) IS 
        BEGIN 
            UPDATE usr_operations_log SET error_text = p_error_text WHERE paymentid =  p_paymentid; 
            COMMIT; 
        END; 


    BEGIN 

        IF p_logging THEN v_logging := 'TRUE'; ELSE v_logging := 'FALSE'; END IF; 

        USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_operations'), 
                                            UPPER ('rsb_execute_step'), 
                                            ku$_vcnt (p_paymentid, 
                                                      p_dockind, 
                                                      p_packmode, 
                                                      p_pack_id, 
                                                      p_error_count, 
                                                      p_error, 
                                                      v_logging)); 
        -- 2013-03-14 zip_z. C-16618 > 
        IF p_dockind = usr_payments.C_DOCKIND_BANK_PAYM_VAL_BNK THEN 
            v_dockind := usr_payments.C_DOCKIND_BANK_PAYM_VAL; 
        ELSE 
            v_dockind := p_docKind; 
        END IF; 
        -- < 2013-03-14 zip_z. C-16618 

        p_error := usr_common.c_err_success; 

        IF gv_rindex IS NULL THEN 
            gv_rindex := dbms_application_info.set_session_longops_nohint; 
        END IF; 

        p_error_count := 0; 
        nt_payments.extend (1); 

        IF nt_payments.count = 1 THEN 
            --самая первая запись, определяется ID сеанса 
            gv_cnt := 1; 
            IF p_logging THEN 
                SELECT   usr_operation_packs_seq.nextval INTO gv_pack_id FROM dual; 
            ELSE 
                gv_pack_id := 1; 
            END IF; 
        END IF; 

        nt_payments (gv_cnt).paymentid := p_paymentid; 
        nt_payments (gv_cnt).dockind   := v_dockind;       -- 2013-03-14 zip_z. C-16618 
        p_pack_id := gv_pack_id; 

        IF p_packmode = 1 THEN 
            gv_cnt := gv_cnt + 1; 
        ELSE 
            FOR i IN nt_payments.first .. nt_payments.last LOOP 
                v_message := NULL; 
                usr_common.make_msg (v_message, c_operation_type); 
                usr_common.make_msg (v_message, c_execstep_func); 
                usr_common.make_msg (v_message, nt_payments (i).paymentid); 
                usr_common.make_msg (v_message, nt_payments (i).dockind); 
                usr_common.make_msg (v_message, gv_pack_id); 

                IF p_logging THEN 
                    reg_payment (nt_payments (i)); 
                END IF; 

                v_stat := usr_send_message (usr_common.m_pipename, v_message); 
            END LOOP; 

            FOR i IN nt_payments.first .. nt_payments.last LOOP 
                v_stat := usr_get_message (dbms_pipe.unique_session_name, v_ret_pipe, v_ret_string); 
                dbms_application_info.set_session_longops (rindex        => gv_rindex, 
                                                       slno          => v_slno, 
                                                       op_name       => 'Выполнение операции', 
                                                       sofar         => i, 
                                                       totalwork     => nt_payments.count, 
                                                       target_desc   => 'PackID=' || gv_pack_id, 
                                                       units         => 'платеж(ей)'); 
                p_error := substr (v_ret_string, 1, instr (v_ret_string, usr_common.c_delimiter) - 1); 
                v_retpmid := substr (v_ret_string, instr (v_ret_string, usr_common.c_delimiter) + 1); 


                IF p_error != usr_common.c_err_success THEN 
                    p_error_count := p_error_count + 1; 
                    --LAO 11.11.2013 Не используется внешними системами, ресурсоемкий апдейт. 
                 --   IF p_logging THEN 
                 --       reg_payment_error(v_retpmid, p_error); 
                 --   END IF; 
                END IF; 
            END LOOP; 

            nt_payments.delete; 
            gv_cnt := 1; 
        END IF; 
    EXCEPTION WHEN OTHERS THEN 
        p_error := 'ошибка при выполнении: ' || dbms_utility.format_error_stack || dbms_utility.format_error_backtrace; 
        nt_payments.delete; 
    END; 

    FUNCTION rsb_execute_step_nolog (p_paymentid number, p_dockind number) RETURN varchar2 IS 
        v_pack_id      number; 
        v_error_count  number; 
        v_error        varchar2(4000); 
        v_dockind      number;       -- 2013-03-14 zip_z. C-16618 

    BEGIN 

        USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_operations'), 
                                              UPPER ('rsb_execute_step_nolog'), 
                                              ku$_vcnt (p_paymentid, 
                                                        p_dockind)); 

        -- 2013-03-14 zip_z. C-16618 > 
        IF p_dockind = usr_payments.C_DOCKIND_BANK_PAYM_VAL_BNK THEN 
            v_dockind := usr_payments.C_DOCKIND_BANK_PAYM_VAL; 
        ELSE 
            v_dockind := p_docKind; 
        END IF; 
        -- < 2013-03-14 zip_z. C-16618 

        rsb_execute_step (p_paymentid     =>p_paymentid, 
                          p_dockind       =>v_dockind, 
                          p_packmode      =>0, 
                          p_pack_id       =>v_pack_id, 
                          p_error_count   =>v_error_count, 
                          p_error         =>v_error, 
                          p_logging       =>FALSE ); 
        RETURN v_error; 
    END; -- rsb_execute_step_nolog 

   PROCEDURE exec_steps_for_temp 
   IS 

        v_packid          number (10); 
        v_error           varchar2 (4000); 
        v_errcnt          number (5); 

        v_paymentidlast   number(10); 
        v_paymentid       number(10); 
        v_dockindlast     number(10); 
        v_dockind         number(10); 

        CURSOR c (cnt number) IS 
            SELECT pm.t_paymentid, op.t_dockind 
             FROM doprtemp_tmp op, dpmrmprop_dbt pm, dpmpaym_dbt pmp 
            WHERE op.t_documentid = pmp.t_documentid AND op.t_dockind = pmp.t_dockind AND pm.t_paymentid = pmp.t_paymentid 
              AND pm.t_priority = cnt 
            ORDER BY op.t_sort; 

    BEGIN 
        FOR i IN 0..6  LOOP --Gurin S. 09.08.2013 C-22197 
            OPEN c(i); 

            LOOP 

                FETCH c INTO v_paymentid,v_dockind; 

                IF c%NOTFOUND THEN 
                    IF v_paymentid IS NOT NULL THEN 
                        usr_operations.rsb_execute_step (p_paymentid     => v_paymentid, 
                                                         p_dockind       => v_dockind, 
                                                         p_packmode      => 2, 
                                                         p_pack_id       => v_packid, 
                                                         p_error_count   => v_errcnt, 
                                                         p_error         => v_error 
                                                        ); 



                    END IF; 

                    EXIT; 

                ELSE 
                    IF v_paymentidlast IS NOT NULL THEN 
                        usr_operations.rsb_execute_step (p_paymentid     => v_paymentidlast, 
                                                         p_dockind       => v_dockindlast, 
                                                         p_packmode      => 1, 
                                                         p_pack_id       => v_packid, 
                                                         p_error_count   => v_errcnt, 
                                                         p_error         => v_error 
                                                        ); 

                    END IF; 

                END IF; 

                v_paymentidlast := v_paymentid; 
                v_dockindlast   := v_dockind; 

            END LOOP; 

            CLOSE c; 

            v_paymentid := NULL; 
            v_paymentidlast := NULL; 

        END LOOP; -- FOR i IN 1..6  LOOP 
    END; -- exec_steps_for_temp 

    -- результат можно смотреть запросом 
    -- select pack_id, paymentid, message,error_text from usr_operations_log, doprtemp_tmp where t_dockind = dockind and t_documentid = paymentid 

END usr_operations; 
/
