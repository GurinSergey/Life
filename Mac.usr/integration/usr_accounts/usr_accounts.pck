CREATE OR REPLACE PACKAGE usr_accounts
IS
          c_create_func  CONSTANT   NUMBER (5) := 1;
          c_update_func  CONSTANT   NUMBER (5) := 2;
          c_close_func   CONSTANT   NUMBER (5) := 3;
          c_account_type CONSTANT   NUMBER (5) := 1;
   c_account_change_type CONSTANT   NUMBER (5) := 4;
   
   
   PROCEDURE create_account (p_account         IN     VARCHAR2,
                             p_chapter         IN     NUMBER DEFAULT NULL ,
                             p_department      IN     NUMBER,
                             p_branch          IN     NUMBER DEFAULT NULL ,
                             p_client          IN     NUMBER,
                             p_oper            IN     NUMBER,
                             p_acc_type        IN     VARCHAR2 DEFAULT NULL ,
                             p_acc_user_type   IN     VARCHAR2 DEFAULT NULL ,
                             p_acc_name        IN     VARCHAR2,
                             p_pack_mode       IN     NUMBER,
                             p_open_date       IN     DATE DEFAULT NULL ,
                             p_error_message      OUT VARCHAR2,
                             p_planid          IN     NUMBER DEFAULT NULL );

   PROCEDURE update_account (p_account         IN     VARCHAR2,
                             p_chapter         IN     NUMBER,
                             p_overdraft       IN     VARCHAR2 DEFAULT NULL ,
                             p_limit           IN     NUMBER DEFAULT NULL ,
                             p_valid_date      IN     DATE DEFAULT NULL ,
                             p_error_message      OUT VARCHAR2);

   PROCEDURE close_account (p_account         IN     VARCHAR2,
                            p_chapter         IN     NUMBER,
                            p_close_date      IN     DATE DEFAULT NULL ,
                            p_error_message      OUT VARCHAR2);

   PROCEDURE create_account_link (p_account_1       IN     VARCHAR2,
                                  p_account_2       IN     VARCHAR2,
                                  p_linktype        IN     NUMBER,
                                  p_error_message      OUT VARCHAR2);

   PROCEDURE create_account_type (p_account         IN     VARCHAR2,
                                  p_funct           IN     NUMBER,
                                  p_acc_type        IN     VARCHAR2,
                                  p_error_message      OUT VARCHAR2);
END usr_accounts; 
/
CREATE OR REPLACE PACKAGE BODY USR_ACCOUNTS
IS
    /*** справочники пользовательских типов счетов ***/
    USR_TYPEACCOUNT_RUR CONSTANT pls_integer := 2;
    USR_TYPEACCOUNT_CUR CONSTANT pls_integer := 5;
    
    /*** код валюты в номере счета  ***/
    CODECURRENCY_RUR    VARCHAR2 (3)         := '810';
    
    PROCEDURE create_account (
            p_account       IN     VARCHAR2,
            p_chapter       IN     NUMBER DEFAULT NULL,
            p_department    IN     NUMBER,
            p_branch        IN     NUMBER DEFAULT NULL,
            p_client        IN     NUMBER,
            p_oper          IN     NUMBER,
            p_acc_type      IN     VARCHAR2 DEFAULT NULL,
            p_acc_user_type IN     VARCHAR2 DEFAULT NULL,
            p_acc_name      IN     VARCHAR2,
            p_pack_mode     IN     NUMBER,
            p_open_date     IN     DATE DEFAULT NULL,
            p_error_message    OUT VARCHAR2,
            p_planid        IN     NUMBER DEFAULT NULL -- тарифный план
        )
    IS
        v_stat       NUMBER;
        v_ret_string VARCHAR2 (2048) ;
        v_ret_pipe   VARCHAR2 (64) ;
        v_op_date    VARCHAR2 (16) ;
        v_oprdprt    NUMBER;
        v_planid     NUMBER; -- тарифный план
        v_typeExist  NUMBER;
    BEGIN
        --25.12.2012 Golovkin запись параметров в лог
        usr_interface_logging.save_arguments (upper ('usr_accounts'), 
                                              upper ('create_account'), 
                                              ku$_vcnt (p_account, 
                                                        p_chapter, 
                                                        p_department,
                                                        p_branch, 
                                                        p_client, 
                                                        p_oper, 
                                                        p_acc_type, 
                                                        p_acc_user_type, 
                                                        p_acc_name, 
                                                        p_pack_mode, 
                                                        p_open_date, 
                                                        p_error_message, 
                                                        p_planid)) ;

        p_error_message := usr_common.c_err_success;
    
        /* Тарифный план */
        IF p_planid  IS NULL THEN
            v_planid := 0;
        ELSE
            v_planid := p_planid;
        END IF;
    
        IF p_open_date IS NULL THEN
            v_op_date  := '00.00.0000';
        ELSE
            v_op_date := TO_CHAR (p_open_date, 'DD.MM.YYYY') ;
        END IF;
    
        IF p_branch IS NOT NULL THEN
            BEGIN
                 SELECT t_code INTO v_oprdprt FROM ddp_dep_dbt WHERE t_code = p_branch;
            EXCEPTION
            WHEN no_data_found THEN
                p_error_message := 'подразделение с кодом ' || p_branch || ' отсутствует в ТС';
            END;
        ELSE
            BEGIN
                 SELECT t_codedepart INTO v_oprdprt FROM dperson_dbt WHERE t_oper = p_oper;
            EXCEPTION
            WHEN no_data_found THEN
                p_error_message := 'операционист с номером ' || p_oper || ' не найден в справочнике';
            END;
        END IF;

        /* EVG 29/05/2013 Проверка наличия пользовательского типа (заявка C-20718) */
        -- 16.08.2013 Golovkin переделал запрос без bulk collect
        IF p_acc_user_type IS NOT NULL THEN
            BEGIN
                FOR c IN 1 .. LENGTH (p_acc_user_type)
                LOOP
                    -- Определяем валютность, исходя из номера счёта
                    SELECT 1
                      INTO v_typeExist
                      FROM dtypeac_dbt
                     WHERE     t_inumtype     = DECODE (SUBSTR (p_account, 6, 3), CODECURRENCY_RUR, USR_TYPEACCOUNT_RUR, USR_TYPEACCOUNT_CUR) 
                           AND t_type_account = SUBSTR (p_acc_user_type, c, 1);
                END LOOP;
            EXCEPTION
            WHEN no_data_found THEN
                p_error_message := 'Неправильный пользовательский тип: ' || p_acc_user_type || '. Счет не открыт.';
            END;

        END IF;

        usr_common.make_msg (v_ret_string, c_account_type) ;
        usr_common.make_msg (v_ret_string, c_create_func) ;
        usr_common.make_msg (v_ret_string, p_account) ;
        usr_common.make_msg (v_ret_string, NVL (p_chapter, usr_common.get_chapter (p_account))) ;
        usr_common.make_msg (v_ret_string, v_oprdprt) ;-- zmp 17.07.2012 I-00209743 заменил p_branch на v_oprdprt
        usr_common.make_msg (v_ret_string, p_department) ;
        usr_common.make_msg (v_ret_string, p_client) ;
        usr_common.make_msg (v_ret_string, p_oper) ;
        usr_common.make_msg (v_ret_string, p_acc_type) ;
        usr_common.make_msg (v_ret_string, p_acc_user_type) ;
        usr_common.make_msg (v_ret_string, p_acc_name) ;
        usr_common.make_msg (v_ret_string, p_pack_mode) ;
        usr_common.make_msg (v_ret_string, v_op_date) ;
        usr_common.make_msg (v_ret_string, v_planid) ; -- тарифный план

        IF p_error_message = usr_common.c_err_success THEN
            v_stat        := usr_send_message (usr_common.m_pipename, v_ret_string) ;
        END IF;

        IF p_pack_mode         = 0 OR p_pack_mode = 2 THEN
            IF p_error_message = usr_common.c_err_success THEN
                v_stat        := usr_get_message (dbms_pipe.unique_session_name, v_ret_pipe, p_error_message) ;
            END IF;
        END IF;
    END;

    PROCEDURE update_account (
            p_account    IN VARCHAR2,
            p_chapter    IN NUMBER,
            p_overdraft  IN VARCHAR2 DEFAULT NULL,
            p_limit      IN NUMBER DEFAULT NULL,
            p_valid_date IN DATE DEFAULT NULL,
            p_error_message OUT VARCHAR2)
    IS
        v_ret_string VARCHAR2 (2048) ;
        v_ret_pipe   VARCHAR2 (64) ;
        v_stat       NUMBER;
    BEGIN
        usr_interface_logging.save_arguments (upper ('usr_accounts'), upper ('update_account'), ku$_vcnt (p_account, p_chapter, p_overdraft,
        p_limit, p_valid_date, p_error_message)) ;

        usr_common.make_msg (v_ret_string, c_account_type) ;
        usr_common.make_msg (v_ret_string, c_update_func) ;
        usr_common.make_msg (v_ret_string, p_account) ;
        usr_common.make_msg (v_ret_string, p_chapter) ;
        usr_common.make_msg (v_ret_string, p_overdraft) ;
        usr_common.make_msg (v_ret_string, TO_CHAR (p_limit, '99999999999999.99')) ;
        usr_common.make_msg (v_ret_string, TO_CHAR (p_valid_date, 'DD.MM.YYYY')) ;

        v_stat := usr_send_message (usr_common.m_pipename, v_ret_string) ;
        v_stat := usr_get_message (dbms_pipe.unique_session_name, v_ret_pipe, p_error_message) ;
    END;

    PROCEDURE close_account (
            p_account    IN VARCHAR2,
            p_chapter    IN NUMBER,
            p_close_date IN DATE DEFAULT NULL,
            p_error_message OUT VARCHAR2)
    IS
        v_ret_string VARCHAR2 (2048) ;
        v_ret_pipe   VARCHAR2 (64) ;
        v_stat       NUMBER;
    BEGIN
        usr_interface_logging.save_arguments (upper ('usr_accounts'), upper ('close_account'), ku$_vcnt (p_account, p_chapter, p_close_date,
        p_error_message)) ;

        usr_common.make_msg (v_ret_string, c_account_type) ;
        usr_common.make_msg (v_ret_string, c_close_func) ;
        usr_common.make_msg (v_ret_string, p_account) ;
        usr_common.make_msg (v_ret_string, p_chapter) ;
        usr_common.make_msg (v_ret_string, p_close_date) ;

        v_stat := usr_send_message (usr_common.m_pipename, v_ret_string) ;
        v_stat := usr_get_message (dbms_pipe.unique_session_name, v_ret_pipe, p_error_message) ;
    END;

    PROCEDURE create_account_link (
            p_account_1 IN VARCHAR2,
            p_account_2 IN VARCHAR2,
            p_linktype  IN NUMBER,
            p_error_message OUT VARCHAR2)
    IS
        v_statstr   VARCHAR (256) ;
        v_fiid_1    NUMBER;
        v_fiid_2    NUMBER;
        v_chapter_1 NUMBER;
        v_chapter_2 NUMBER;

    FUNCTION check_account (
            p_account  VARCHAR2,
            p_linktype NUMBER,
            p_fiid     NUMBER)
        RETURN VARCHAR2
    IS
        v_type_account    VARCHAR2 (32) ;
        --v_connect_account VARCHAR2 (20) ;
        v_pairaccount     VARCHAR2 (20) ;
    BEGIN
        -- KS 27.11.2013 Адаптация под 31ю сборку
        --               Связанных счетов теперь нет
        --IF p_fiid = 0 THEN
             SELECT t_type_account, /*t_connect_account,*/ t_pairaccount
               INTO v_type_account, /*v_connect_account,*/ v_pairaccount
               FROM daccount_dbt
              WHERE t_account = p_account AND
                t_chapter     = usr_common.get_chapter (p_account) AND
                t_open_close  = chr (0) ;/*
        ELSE
             SELECT t_type_account, t_connect_account, t_pairaccount
               INTO v_type_account, v_connect_account, v_pairaccount
               FROM daccount$_dbt
              WHERE t_account   = p_account AND
                t_chapter       = usr_common.get_chapter (p_account) AND
                t_code_currency = p_fiid AND
                t_open_close    = chr (0) ;
        END IF;*/

        IF p_linktype         = 1 THEN --парный
            IF v_pairaccount <> chr (1) OR instr (v_type_account, 'Ш') > 0 THEN
                RETURN 'счет ' || p_account || ' уже является парным';
            END IF;
        elsif p_linktype      = 2 THEN --связанный
            IF v_pairaccount <> chr (1) THEN
                RETURN 'счет ' || p_account || ' уже является связанным';
            END IF;
        ELSE
            RETURN 'неверное значение параметра p_linktype';
        END IF;

        RETURN usr_common.c_err_success;
    EXCEPTION
    WHEN no_data_found THEN
        RETURN 'счет ' || p_account || ' не найден или закрыт';
    END;

    BEGIN
        usr_interface_logging.save_arguments (upper ('usr_accounts'), upper ('create_account_link'), ku$_vcnt (p_account_1, p_account_2,
        p_linktype, p_error_message)) ;

        p_error_message := usr_common.c_err_success;
        v_fiid_1        := usr_common.get_fiid (p_account_1) ;
        v_fiid_2        := usr_common.get_fiid (p_account_2) ;
        v_chapter_1     := usr_common.get_chapter (p_account_1) ;
        v_chapter_2     := usr_common.get_chapter (p_account_2) ;
        v_statstr       := check_account (p_account_1, p_linktype, v_fiid_1) ;

        IF v_statstr     = usr_common.c_err_success THEN
            v_statstr   := check_account (p_account_2, p_linktype, v_fiid_2) ;
        END IF;

        IF v_statstr        <> usr_common.c_err_success THEN
                p_error_message := v_statstr;
        elsif v_fiid_1      <> v_fiid_2 THEN
            p_error_message := 'не совпадает валюта счетов';
        elsif v_chapter_1   <> v_chapter_2 THEN
            p_error_message := 'не совпадает глава счетов';
        ELSE
            IF p_linktype = 1 --парный
                THEN
                -- KS 27.11.2013 Адаптация под 31ю сборку
                --IF v_fiid_1 = 0 THEN
                  UPDATE daccount_dbt
                     SET t_pairaccount = p_account_2, t_type_account = REPLACE (t_type_account ||
                        'Ш', chr (1), '')
                   WHERE t_chapter = v_chapter_1 AND
                        t_account     = p_account_1;
                  UPDATE daccount_dbt
                     SET t_pairaccount = p_account_1, t_type_account = REPLACE (t_type_account ||
                        'Ш', chr (1), '')
                   WHERE t_chapter = v_chapter_1 AND
                         t_account     = p_account_2;
                   COMMIT;
                /*ELSE
                   UPDATE daccount$_dbt
                      SET t_pairaccount = p_account_2, t_type_account = REPLACE (t_type_account ||
                          'Ш', chr (1), '')
                    WHERE t_chapter   = v_chapter_1 AND
                          t_account       = p_account_1 AND
                          t_code_currency = v_fiid_1;
                   UPDATE daccount$_dbt
                      SET t_pairaccount = p_account_1, t_type_account = REPLACE (t_type_account ||
                          'Ш', chr (1), '')
                    WHERE t_chapter   = v_chapter_1 AND
                          t_account       = p_account_2 AND
                          t_code_currency = v_fiid_1;
                END IF;*/
            /*
            elsif p_linktype = 2 --связанный
                THEN
                IF v_fiid_1 = 0 THEN
                  UPDATE daccount_dbt
                     SET t_connect_account = p_account_2
                   WHERE t_chapter     = v_chapter_1 AND
                         t_account         = p_account_1;
                  UPDATE daccount_dbt
                     SET t_connect_account = p_account_1
                   WHERE t_chapter     = v_chapter_1 AND
                         t_account         = p_account_2;
                ELSE
                 UPDATE daccount_dbt
                    SET t_connect_account = p_account_2
                  WHERE t_chapter     = v_chapter_1 AND
                        t_account         = p_account_1 AND
                        t_code_currency   = v_fiid_1;
                 UPDATE daccount_dbt
                    SET t_connect_account = p_account_1
                  WHERE t_chapter     = v_chapter_1 AND
                        t_account         = p_account_2 AND
                        t_code_currency   = v_fiid_1;
                END IF;*/
            END IF;
        END IF;
        COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_error_message := 'ошибка создания связи счетов: ' || dbms_utility.format_error_stack || dbms_utility.format_error_backtrace;
    END;

    --добавление  пользовательского типа к счету LAO 29.01.2013
    PROCEDURE create_account_type (p_account       IN     VARCHAR2,
                                   p_funct         IN     NUMBER,
                                   p_acc_type      IN     VARCHAR2,
                                   p_error_message    OUT VARCHAR2)
    IS
        v_ret_string   VARCHAR2 (2048) ;
        v_ret_pipe     VARCHAR2 (64) ;
        v_stat         NUMBER;
        v_typeExist    NUMBER;
        e_typeNotExist EXCEPTION;
    BEGIN
        usr_interface_logging.save_arguments (upper ('usr_accounts'), 
                                              upper ('create_account_type'), 
                                              ku$_vcnt (p_account, 
                                                        p_funct, 
                                                        p_acc_type,  
                                                        p_error_message)) ;

        /* EVG 29/05/2013 Проверка наличия пользовательского типа (заявка C-20718) */
        -- 16.08.2013 Golovkin переделал запрос без bulk collect
        IF p_acc_type IS NOT NULL THEN   
            BEGIN
                -- Определяем валютность, исходя из номера счёта
                SELECT  1 
                  INTO  v_typeExist                       
                  FROM  dtypeac_dbt
                 WHERE      t_inumtype     = DECODE (SUBSTR (p_account, 6, 3), CODECURRENCY_RUR, USR_TYPEACCOUNT_RUR, USR_TYPEACCOUNT_CUR) 
                        AND t_type_account = p_acc_type;
            EXCEPTION
            WHEN no_data_found THEN
                -- 16.08.2013 Golovkin I-00412451 делаю возврат ошибки через exception
                RAISE e_typeNotExist;
            END;
        END IF;

        usr_common.make_msg (v_ret_string, c_account_type) ;
        usr_common.make_msg (v_ret_string, c_account_change_type) ;
        usr_common.make_msg (v_ret_string, p_account) ;
        usr_common.make_msg (v_ret_string, p_funct) ;
        usr_common.make_msg (v_ret_string, p_acc_type) ;
        
        /* EVG При наличии ошибки не отправляем сообщение */
        -- Golovkin сделал возврат ошибки через exception, убрал проверку 
        v_stat := usr_send_message (usr_common.m_pipename, v_ret_string) ;
        v_stat := usr_get_message  (dbms_pipe.unique_session_name, v_ret_pipe, p_error_message) ;
    EXCEPTION
        WHEN e_typeNotExist THEN
            p_error_message := 'Неправильный пользовательский тип: ' || p_acc_type || '. Пользовательский тип счета не установлен.';
        WHEN OTHERS THEN
            p_error_message := 'ошибка добавления/удаления типа пользовательского счета: ' || dbms_utility.format_error_stack || dbms_utility.format_error_backtrace;
    END;
END usr_accounts; 
/
