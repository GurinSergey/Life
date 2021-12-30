CREATE OR REPLACE PACKAGE USR_PAYMENTS
IS
    -----------------------------------------------------------------------------------------------------------------
    -- !!! УМОЛЯЮ, НЕ ЖМИТЕ АВТОФОРМАТ, ЗДЕСЬ ВСЁ СЪЕДЕТ К ЧЁРТОВОЙ БАБУШКЕ !!!
    --                                                                                             regards, The Zeep
    -----------------------------------------------------------------------------------------------------------------


    gv_cnt      pls_integer;
    gv_prepared BOOLEAN := false;

    ----------- виды документов --------------------------------
    C_DOCKIND_CASH_IN                 CONSTANT NUMBER := 430;   -- кассовый, приходный
    C_DOCKIND_CASH_OUT                CONSTANT NUMBER := 440;   -- кассовый, расходный
    C_DOCKIND_CASH_INOUT              CONSTANT NUMBER := 400;   -- кассовый, подкрепление
    C_DOCKIND_MEMORDER                CONSTANT NUMBER := 70;    -- мем. ордер
    C_DOCKIND_MEMORDER_BANK_ORDER     CONSTANT NUMBER := 286;   -- банковский ордер для 30ки
    C_DOCKIND_MULTYCARRY              CONSTANT NUMBER := 15;    -- мультивалютный
    C_DOCKIND_BANK_PAYM               CONSTANT NUMBER := 16;    -- платеж ББ
    C_DOCKIND_BANK_ORDER              CONSTANT NUMBER := 17;    -- требование ББ (только рубли)
    C_DOCKIND_CLIENT_PAYM             CONSTANT NUMBER := 2011;  -- платеж РКО
    C_DOCKIND_CLIENT_ORDER            CONSTANT NUMBER := 2012;  -- требование РКО (только рубли)
    C_DOCKIND_CLIENT_CASH_IN          CONSTANT NUMBER := 410;   -- объявление на взнос наличных
    C_DOCKIND_CLIENT_CASH_OUT         CONSTANT NUMBER := 420;   -- клиентский чек
    C_DOCKIND_EXTERNAL_IN             CONSTANT NUMBER := 320;   -- внешний входящий платёж-- KS 25.05.2011 C-731
    C_DOCKIND_CLIENT_PAYM_B           CONSTANT NUMBER := 2001;  -- покупка валюты
    C_DOCKIND_CLIENT_PAYM_S           CONSTANT NUMBER := 2002;  -- продажа валюты
    C_DOCKIND_CLIENT_PAYM_K           CONSTANT NUMBER := 2003;  -- конверсия валюты
    C_DOCKIND_CLIENT_PAYM_VAL         CONSTANT NUMBER := 202;   -- валютный платеж РКО
    C_DOCKIND_BANK_PAYM_VAL           CONSTANT NUMBER := 27;    -- валютный платеж банка
    C_DOCKIND_BANK_PAYM_VAL_BNK       CONSTANT NUMBER := 666;   -- валютный платеж банка (позиционируется в МБР как общий банковский перевод) zip_z. 2013-03-04 C-16618


    type client_param_rec IS record
    (
        account      daccount_dbt.t_account%type,
        type_account daccount_dbt.t_type_account%type,
        chapter      daccount_dbt.t_chapter%type,
        oper         daccount_dbt.t_oper%type,
        department   daccount_dbt.t_department%type,
        vsp          daccount_dbt.t_department%type,
        client_id    daccount_dbt.t_client%type,
        name         dparty_dbt.t_name%type,
        inn          dobjcode_dbt.t_code%type,
        nameaccount  daccount_dbt.t_nameaccount%type
    ) ;


    type pay_instr_rec IS record
    (
        account             VARCHAR2 (35),
        type_account        daccount_dbt.t_type_account%type,
        client_name         dparty_dbt.t_name%type,
        client_code         dobjcode_dbt.t_code%type, -- EVG 26/11/2012 Для обработки переданного в процедуру p_receiver_bic / p_receiver_bank_bic
        bank_code           dobjcode_dbt.t_code%type,
        bank_codekind       dobjcode_dbt.t_codekind%type,
        bank_codename       dobjkcode_dbt.t_name%type,
        inn                 dobjcode_dbt.t_code%type,
        coracc              dpmrmprop_dbt.t_receivercorraccnostro%type,
        cur_iso             VARCHAR (3),
        fiid                dfininstr_dbt.t_fiid%type,
        department          daccount_dbt.t_department%type,
        vsp                 daccount_dbt.t_department%type,
        client_id           dpmpaym_dbt.t_payer%type,
        bank_id             dpmpaym_dbt.t_payerbankid%type,
        bank_name           dpmrmprop_dbt.t_payerbankname%type,
        bank_place_name     dbankdprt_dbt.t_placename%type,
        med_bank_name       dparty_dbt.t_name%type,
        med_bank_code       dobjcode_dbt.t_code%type,
        med_bank_codekind   dobjcode_dbt.t_codekind%type,
        med_bank_codename   dobjcode_dbt.t_codekind%type,
        med_bank_place_name dbankdprt_dbt.t_placename%type
    ) ;


    type tech_param_rec IS record
    (
        is_debet                BOOLEAN,
        is_our_payer            BOOLEAN,
        is_our_receiver         BOOLEAN,
        check_exists            BOOLEAN,
        run_operation           BOOLEAN,
        autorun_operation       BOOLEAN,
        make_carry_from_payment BOOLEAN,
        error_text              VARCHAR2 (4000),
        pack_id                 NUMBER (10),
        pack_mode               NUMBER (1),
        in_transaction          BOOLEAN
    ) ;


    type tp_glob_rec IS record
    (
        start_work_date DATE,
        nls_num_delim   CHAR (2)
    ) ;

    
    type tp_cash_symbols_rec IS record
    (
        cash_sum    NUMBER,
        cash_symbol dlistsymb_dbt.t_symb_cash%type,
        symb_type   dlistsymb_dbt.t_type_symbol%type
    ) ;

    type cash_symbs_rec IS record
    (
        symbol    dlistsymb_dbt.t_symb_cash%type,
        symb_type dlistsymb_dbt.t_type_symbol%type
    ) ;

    -- структура типа должна совпадать со структурой таблицы usr_pmdocs
    -- zip_z.: %ROWTYPE ????

    type tp_carry_rec IS record
    (
        autokey          NUMBER (10),
        paymentid        NUMBER (10),
        operationid      NUMBER (10),
        carrynum         NUMBER (5),
        -- KS 10.12.2012 Адаптация под 31ю сборку
        --fiid             daccount_dbt.t_code_currency%type,
        fiid_payer       daccount_dbt.t_code_currency%type,
        fiid_receiver    daccount_dbt.t_code_currency%type,
        chapter          daccount_dbt.t_chapter%type,
        payer_account    dpmpaym_dbt.t_payeraccount%type,
        receiver_account dpmpaym_dbt.t_receiveraccount%type,
        -- KS 11.12.2012 Адаптация под 31ю сборку
        --SUM              dpmpaym_dbt.t_amount%type,
        SUM              dacctrn_dbt.t_sum_natcur%type,
        sum_payer        dacctrn_dbt.t_sum_payer%type,
        sum_receiver     dacctrn_dbt.t_sum_receiver%type,
        date_carry       DATE,
        oper             NUMBER (5),
        pack             dpmpaym_dbt.t_numberpack%type,
        num_doc          dpmrmprop_dbt.t_number%type,
        ground           dpmrmprop_dbt.t_ground%type,
        department       daccount_dbt.t_department%type,
        vsp              daccount_dbt.t_branch%type,
        -- KS 14.11.2012 Адаптация под 31ю сборку
        --kind_oper        darhdoc_dbt.t_kind_oper%type,
        --shifr_oper       darhdoc_dbt.t_shifr_oper%type,
        kind_oper        dacctrn_dbt.t_kind_oper%type,
        shifr_oper       dacctrn_dbt.t_shifr_oper%type,
        error            VARCHAR2 (4000)
    ) ;

    type nt_carry        IS TABLE OF tp_carry_rec;
    type nt_cash_symbols IS TABLE OF tp_cash_symbols_rec;

    type main_doc_rec IS record
    (
    chapter       NUMBER (2),
    oper          NUMBER (5),
    pack          NUMBER (5),
    num_operation NUMBER (5),
    num_doc       VARCHAR2 (25),
    typedoc       VARCHAR2 (16),
    usertypedoc   VARCHAR2 (16),
    debet_sum     NUMBER (32, 2),
    kredit_sum    NUMBER (32, 2),
    rate          NUMBER,
    ground        VARCHAR2 (600),
    department    NUMBER (5),
    priority      NUMBER (5),
    shifr         VARCHAR2 (6),
    value_date    DATE,
    doc_date      DATE,
    corschem      NUMBER,
    doc_kind      NUMBER (5),
    cash_symbs    VARCHAR2 (100),
    fio_client    VARCHAR2 (80),
    userfield1    VARCHAR2 (120),
    userfield2    VARCHAR2 (40),
    userfield3    VARCHAR2 (80),
    userfield4    VARCHAR2 (80),
    accept_term   NUMBER (1),
    accept_date   DATE,
    pay_condition VARCHAR2 (160),
    accept_period dpspaydem_dbt.t_AcceptPeriod%type,
    creator_status   VARCHAR2 (2),
    kbk_code         VARCHAR2 (20),
    okato_code       VARCHAR2 (11),
    ground_tax_doc   VARCHAR2 (2),
    tax_period       VARCHAR2 (10),
    num_tax_doc      VARCHAR2 (15),
    tax_date         VARCHAR2 (10),
    tax_type         VARCHAR2 (2),
    origin           NUMBER (5),
    payment_id       NUMBER (10),
    operation_id     NUMBER (10),
    corrpos          NUMBER (1),
    doc_cur_iso      VARCHAR2 (3),
    doc_cur_fiid     NUMBER (5),
    comiss_acc       VARCHAR2 (25),
    comiss_fiid      VARCHAR2 (25),
    expense_transfer VARCHAR (3),
    vo_code          VARCHAR2 (16),
    vo_codeid        NUMBER (5),
    gtd              VARCHAR2 (50),
    gtd_date         DATE,
    gtd_cur_iso      VARCHAR2 (3),
    deal_passport    VARCHAR2 (30),
    deal_date        DATE,
    ground_add       VARCHAR2 (210),
    transfer_date    DATE,
    receiver_pi_rec pay_instr_rec,
    payer_pi_rec pay_instr_rec,
    tech_parm_rec tech_param_rec,
    carry_nt nt_carry:=nt_carry(), -- LAO 30.05.2013 Так должгно быть! I-00376459-3
    cash_symbols_nt nt_cash_symbols,
    bosspost           VARCHAR2 (210),
    bossfio            VARCHAR2 (210),
    paymentkind        VARCHAR2 (2),
    paperkind          NUMBER (5),     -- KS 24.10.2011
    paperseries        VARCHAR2 (9),   -- KS 24.10.2011
    papernumber        VARCHAR2 (25),  -- KS 24.10.2011
    paperissueddate    DATE,           -- KS 24.10.2011
    paperissuer        VARCHAR2 (264), -- KS 24.10.2011
    payerchargeoffdate DATE,           -- KS 28.10.2011
    paytype            NUMBER (10),     -- UDA 26.07.2012 По запросу I-00225239
    SubKindMessageDebet     dpmprop_dbt.t_subKindMessage%type, -- zip_z. 2013-03-04 C-16618
    SubKindMessageCredit    dpmprop_dbt.t_subKindMessage%type,  -- zip_z. 2013-03-04 C-16618
    uin                VARCHAR2(25)       -- VDN 27.03.2014 C-28175
  ) ;
type main_doc_nt
IS
  TABLE OF main_doc_rec;
type client_param_nt
IS
  TABLE OF client_param_rec;
  nt_main_doc main_doc_nt := main_doc_nt () ;
  nt_client_param client_param_nt;
  PROCEDURE insert_payment (
      p_payer_account    IN VARCHAR2,
      p_payer_name       IN VARCHAR2 DEFAULT NULL,
      p_payer_bic        IN VARCHAR2 DEFAULT NULL,
      p_payer_inn        IN VARCHAR2 DEFAULT NULL,
      p_payer_kpp        IN VARCHAR2 DEFAULT NULL,
      p_receiver_account IN VARCHAR2,
      p_receiver_name    IN VARCHAR2 DEFAULT NULL,
      p_receiver_bic     IN VARCHAR2 DEFAULT NULL,
      p_receiver_inn     IN VARCHAR2 DEFAULT NULL,
      p_receiver_kpp     IN VARCHAR2 DEFAULT NULL,
      p_oper             IN NUMBER,
      p_pack             IN NUMBER DEFAULT NULL,
      p_corschem         IN NUMBER DEFAULT NULL,
      p_num_operation    IN NUMBER DEFAULT NULL,
      p_num_doc          IN VARCHAR2,
      p_typedoc          IN VARCHAR2 DEFAULT NULL,
      p_usertypedoc      IN VARCHAR2 DEFAULT NULL,
      p_debet_sum        IN NUMBER,
      p_kredit_sum       IN NUMBER DEFAULT NULL,
      p_rate             IN NUMBER DEFAULT NULL,
      p_ground           IN VARCHAR2,
      p_branch           IN NUMBER DEFAULT NULL,
      p_priority         IN NUMBER DEFAULT NULL,
      p_shifr            IN VARCHAR2 DEFAULT NULL,
      p_value_date       IN DATE DEFAULT NULL,
      p_doc_date         IN DATE DEFAULT NULL,
      p_doc_kind         IN NUMBER,
      p_cash_symbs       IN VARCHAR2 DEFAULT NULL,
      p_fio_client       IN VARCHAR2 DEFAULT NULL,
      p_userfield1       IN VARCHAR2 DEFAULT NULL,
      p_userfield2       IN VARCHAR2 DEFAULT NULL,
      p_userfield3       IN VARCHAR2 DEFAULT NULL,
      p_userfield4       IN VARCHAR2 DEFAULT NULL,
      p_accept_term      IN NUMBER DEFAULT NULL,
      p_accept_date      IN DATE DEFAULT NULL,
      p_pay_condition    IN VARCHAR2 DEFAULT NULL,
      p_accept_period    IN NUMBER DEFAULT NULL,
      p_creator_status   IN VARCHAR2 DEFAULT NULL,
      p_kbk_code         IN VARCHAR2 DEFAULT NULL,
      p_okato_code       IN VARCHAR2 DEFAULT NULL,
      p_ground_tax_doc   IN VARCHAR2 DEFAULT NULL,
      p_tax_period       IN VARCHAR2 DEFAULT NULL,
      p_num_tax_doc      IN VARCHAR2 DEFAULT NULL,
      p_tax_date         IN VARCHAR2 DEFAULT NULL,
      p_tax_type         IN VARCHAR2 DEFAULT NULL,
      p_origin           IN NUMBER,
      p_skip_check_mask NUMBER DEFAULT 0,
      p_check_exists            IN NUMBER DEFAULT NULL,
      p_run_operation           IN NUMBER DEFAULT NULL,
      p_pack_mode               IN NUMBER DEFAULT NULL,
      p_make_carry_from_payment IN NUMBER DEFAULT NULL,
      p_payment_id OUT NUMBER,
      p_error OUT VARCHAR2,
      p_transaction_mode IN NUMBER DEFAULT 0, -- 1 = транзакцией управляет вызывающее приложение, 0 = транзакцией управляет процедура
      p_doc_cur_iso              VARCHAR2 DEFAULT NULL,    --валюта перевода
      p_receiver_account_cur_iso VARCHAR2 DEFAULT NULL,    --валюта получателя
      p_comiss_acc               VARCHAR2 DEFAULT NULL,    --счет комиссии
      p_expense_transfer         VARCHAR2 DEFAULT NULL,    --комиссии и расходы
      p_vo_code                  VARCHAR2 DEFAULT NULL,    --код ВО
      p_gtd                      VARCHAR2 DEFAULT NULL,    --номер контракта
      p_gtd_date                 DATE DEFAULT NULL,        --дата контракта
      p_gtd_cur_iso              VARCHAR2 DEFAULT NULL,    --валюта контракта
      p_deal_passport            VARCHAR2 DEFAULT NULL,    --паспорт сделки
      p_deal_date                DATE DEFAULT NULL,        --дата паспорта
      p_med_bankname             VARCHAR2 DEFAULT NULL,    --название банка посредника
      p_med_bic                  VARCHAR2 DEFAULT NULL,    --код банка посредника
      p_receiver_bankname        VARCHAR2 DEFAULT NULL,    -- название банка получателя
      p_receiver_bankcoracc      VARCHAR2 DEFAULT NULL,    --корсчет счет банка получателя
      p_receiver_bank_bic        VARCHAR2 DEFAULT NULL,    --код банка получателя-банка
      p_ground_add               VARCHAR2 DEFAULT NULL,
      p_transfer_date            DATE DEFAULT NULL,
      p_bosspost                 VARCHAR2 DEFAULT NULL, -- Должность босс
      p_bossfio                  VARCHAR2 DEFAULT NULL, -- Имя босс
      p_paymentkind              VARCHAR2 DEFAULT 'Н',  -- Вид платежа -- TAM 16.07.2013 R-216001 Э->Н
      p_autorun_operation IN NUMBER DEFAULT NULL,       -- Запуск операции
      p_paperkind          NUMBER DEFAULT NULL,                  -- KS 24.10.2011 Для кассвовых - тип документа
      p_paperseries        VARCHAR2 DEFAULT NULL,                -- KS 24.10.2011 Для кассвовых - серия
      p_papernumber        VARCHAR2 DEFAULT NULL,                -- KS 24.10.2011 Для кассвовых - номер
      p_paperissueddate    DATE DEFAULT NULL,                    -- KS 24.10.2011 Для кассвовых - дата
      p_paperissuer        VARCHAR2 DEFAULT NULL,                -- KS 24.10.2011 Для кассвовых - выдан
      p_payerchargeoffdate DATE DEFAULT NULL,                    -- KS 28.10.2011 Списано со сч. плат.
      p_paytype IN NUMBER DEFAULT 0,                              -- UDA 26.07.2012 По запросу I-00225239
      p_SubKindMessageDebet  in dpmprop_dbt.t_subKindMessage%type default null, -- zip_z. 2013-03-04 C-16618
      p_SubKindMessageCredit in dpmprop_dbt.t_subKindMessage%type default null, -- zip_z. 2013-03-04 C-16618
      p_uin               IN VARCHAR2 DEFAULT NULL               -- VDN 27.03.2014 C-28175       
    ) ;
    
    PROCEDURE add_carry (
      p_payment_id       NUMBER,
      p_payer_account    VARCHAR2 DEFAULT NULL,
      p_receiver_account VARCHAR2 DEFAULT NULL,
      p_ground           VARCHAR2 DEFAULT NULL,
      p_sum              NUMBER   DEFAULT NULL,
      p_pack             NUMBER   DEFAULT NULL,
      p_num_doc          VARCHAR2 DEFAULT NULL,
      p_error        OUT VARCHAR2,
      -- KS 13.12.2013 Адаптация под 31ю сборку 
      p_sum_payer                                 NUMBER DEFAULT NULL,
      p_sum_receiver                              NUMBER DEFAULT NULL
    ) ;

    PROCEDURE add_deffered_carry (
      p_payment_id       NUMBER,
      p_carrynum         NUMBER,
      p_payer_account    VARCHAR2,
      p_receiver_account VARCHAR2,
      p_sum              NUMBER,
      p_date_carry       DATE,
      p_oper             NUMBER,
      p_pack             NUMBER,
      p_num_doc          VARCHAR2,
      p_ground           VARCHAR2,
      p_kind_oper        VARCHAR2,
      p_shifr_oper       VARCHAR2,
      p_department       NUMBER DEFAULT NULL,
      p_branch           NUMBER DEFAULT NULL,
      p_typedoc       IN VARCHAR2 DEFAULT NULL,
      p_usertypedoc   IN VARCHAR2 DEFAULT NULL,
      p_error        OUT VARCHAR2,
      -- KS 11.12.2013 Адаптация под 31ю сборку 
      p_sum_payer        NUMBER DEFAULT NULL,
      p_sum_receiver     NUMBER DEFAULT NULL) ;

  PROCEDURE run_operation (
      p_pack_id OUT NUMBER,
      p_error_count OUT NUMBER,
      p_error OUT VARCHAR2) ;

  PROCEDURE delete_payment (
      p_payment_id IN NUMBER,
      p_error OUT VARCHAR2,
      p_oper IN NUMBER DEFAULT 0) ;
  
  --процедура удаляет первичный документ
  --вызывается обработчиком во веремя вызова delete_payment
  --после удаления проводки
  PROCEDURE delete_payment_callback (
      p_payment_id IN NUMBER,
      p_error OUT VARCHAR2) ;
END; 
/
CREATE OR REPLACE PACKAGE BODY USR_PAYMENTS AS
    gv_rindex                                    PLS_INTEGER;                        -- ID "градусника" процесса в V$SESSION_LONGOPS
    gv_slno                                      PLS_INTEGER;                        -- какой-то нужный объект для "градусника"

    -- 18.06.2013 Golovkin по множеству заявок
    -- Ввел флаг ready_to_run_operation
    -- Суть:
    -- Если при insert_payment pack_mode 0 или 2 и run_operation 1 то,
    -- ready_to_run_operation := TRUE
    -- при выполнении run_operation флаг сбрасывается
    -- ready_to_run_operation := FALSE
    -- При использовании insert_payment если флаг ready_to_run_operation установлен, то
    -- до вставки нового документа удаляется пачка (delete_pack) и флаг сбарсывается 
    ready_to_run_operation                       BOOLEAN  := FALSE;

    c_mode_debug                                 BOOLEAN  := FALSE;                  -- отладочный режим, включает вывод отладочной информации
    c_msg_delim                         CONSTANT CHAR (1) := usr_common.c_delimiter; -- разделитель для строки сообщения, передаваемой в RS-Bank
    
    c_service_type                      CONSTANT CHAR (1) := '6';                    -- вид обработки pipe сервера = выполнение проводки
    c_check_type                        CONSTANT CHAR (1) := '7';                    -- вид обработки pipe сервера = тест связи
    
    /*** КОДЫ ПОЛЬЗОВАТЕЛЬСКИХ ИСКЛЮЧЕНИЙ ***/
    c_err_acc_notfound                  CONSTANT VARCHAR2 (1024) := 'счет %p1 %p2 не найден';
    c_err_department_mismatch           CONSTANT VARCHAR2 (1024) := 'счет %p1 не принадлежит филиалу';
    c_err_fiid_notfound                 CONSTANT VARCHAR2 (1024) := 'не определена валюта по счету %p1';
    c_err_oper_incorrect                CONSTANT VARCHAR2 (1024) := 'операционист %p1 не является владельцем счета %p2';
    c_err_department_not_found          CONSTANT VARCHAR2 (1024) := 'филиал для платежа не определен';
    c_err_name_notfound                 CONSTANT VARCHAR2 (1024) := 'не задано наименование %p1 для внешнего платежа';
    c_err_name_mismatch                 CONSTANT VARCHAR2 (1024) := 'наименование %p1 не совпадает с наименованием в БД' ;
    c_err_bank_notfound                 CONSTANT VARCHAR2 (1024) := 'банк %p1 не найден по коду %p2';
    c_err_inn_notfound                  CONSTANT VARCHAR2 (1024) := 'не задан ИНН %p1 для внешнего платежа';
    c_err_inn_mismatch                  CONSTANT VARCHAR2 (1024) := 'ИНН %p1 не совпадает с ИНН в БД';
    c_err_bic_notfound                  CONSTANT VARCHAR2 (1024) := 'не задан код банка %p1 для внешнего платежа';
    c_err_bnkname_notfound              CONSTANT VARCHAR2 (1024) := 'не задано наименование банка %p1 для внешнего платежа' ;
    c_err_corschem_notset               CONSTANT VARCHAR2 (1024) := 'не задан номер корсхемы для внешнего платежа';
    c_err_corschem_notaufound           CONSTANT VARCHAR2 (1024) := 'ошибка при автопоиске корсхемы для внешнего платежа:схема не найдена' ;
    c_err_corschem_notfound             CONSTANT VARCHAR2 (1024) := 'не найдена корсхема с номером %p1';
    c_err_tpparm_notdef                 CONSTANT VARCHAR2 (1024) := 'не определены параметры обмена';
    c_err_origin_mismatch               CONSTANT VARCHAR2 (1024) := 'вид происхождения задан неверно';
    c_err_date_order_notset             CONSTANT VARCHAR2 (1024) := 'не задана дата окончания акцепта';
    c_err_accept_per_notset             CONSTANT VARCHAR2 (1024) := 'не задан период акцепта';
    c_err_pay_condition_notset          CONSTANT VARCHAR2 (1024) := 'не заданы условия оплаты';
    c_err_acceptterm_incorrect          CONSTANT VARCHAR2 (1024) := 'неверный вид акцепта';
    c_err_fiid_mismatch                 CONSTANT VARCHAR2 (1024) := 'для заданного вида документа валюта счетов должна совпадать' ;
    c_err_chapter_mismatch              CONSTANT VARCHAR2 (1024) := 'не совпадает глава учета для счетов';
    c_err_dep_mismatch                  CONSTANT VARCHAR2 (1024) := 'не совпадает филиал счетов';
    c_err_cash_symb_not_set             CONSTANT VARCHAR2 (1024) := 'для кассового документа не заданы кассовые символы' ;
    c_err_cash_symb_notfound            CONSTANT VARCHAR2 (1024) := 'кассовый символ %p1 не найден в справочнике';
    c_err_cash_symb_mismatch            CONSTANT VARCHAR2 (1024) := 'кассовый символ %p1 не подходит для операции %p2';
    c_err_cash_sum_notcont              CONSTANT VARCHAR2 (1024) := 'не совпадает сумма по символам с суммой документа' ;
    c_err_doc_exists                    CONSTANT VARCHAR2 (1024) := 'документ дублируется';
    c_err_dockind_mismatch              CONSTANT VARCHAR2 (1024) := 'вид документа в пакетном режиме должен быть одинаковым' ;
    c_err_oper_mismatch                 CONSTANT VARCHAR2 (1024) := 'номер операциониста а пакетном режиме должен быть одинаковым для всех документов' ;
    c_err_dockind_not_supp              CONSTANT VARCHAR2 (1024) := 'заданный вид документа не обрабатывется';
    c_err_dock_direct_mismatch          CONSTANT VARCHAR2 (1024) := 'направление платежа в пакетном режиме должно быть одинаковым' ;
    c_err_dockind_not_supp_run          CONSTANT VARCHAR2 (1024) := 'заданный вид документа не подлежит автом. обработке' ;
    c_err_numdoc_notset                 CONSTANT VARCHAR2 (1024) := 'не задан номер документа';
    c_err_init_error                    CONSTANT VARCHAR2 (1024) := 'ошибка инициализации пакета: %p1';
    c_err_opr_notfound                  CONSTANT VARCHAR2 (1024) := 'операция вида %p1 не найдена или не активна';
    c_err_trn_mode                      CONSTANT VARCHAR2 (1024) := 'режим работы в транзакции доступен только для отложенных документов' ;
    c_err_opt_notset                    CONSTANT VARCHAR2 (1024) := 'не задан номер операции';
    c_err_iso_notfound                  CONSTANT VARCHAR2 (1024) := 'не определена валюта %p1';
    c_err_vocode_notfound               CONSTANT VARCHAR2 (1024) := 'не найден код ВО %p1';
    c_err_comisscharges_notfound        CONSTANT VARCHAR2 (1024) := 'не определен вид комисии %p1';
    c_err_transfdate_invalid            CONSTANT VARCHAR2 (1024) := 'ДПП должна быть больше или равной дате значения документа' ;
    c_err_notsingle                     CONSTANT VARCHAR2 (1024) := 'автоматическая проводка доступна только в режиме единичной вставки' ;
    c_err_oper_invalid                  CONSTANT VARCHAR2 (1024) := 'пользователь %p1 не найден';
    c_err_transit                       CONSTANT VARCHAR2 (1024) := 'транзитные платежи не обрабатываются';                                         -- KS C-731
    c_err_wrong_payment_sum             CONSTANT VARCHAR2 (1024) := 'сумма платежа содержит более двух знаков после запятой (%p1)' ;                -- Golovkin 18.09.2012
    c_err_wrong_refer_num               CONSTANT VARCHAR2 (1024) := 'Невозможно сформировать референс';
    c_err_wrong_okato_code              CONSTANT VARCHAR2 (1024) := 'Неверный код ОКАТО (%p1)';                                                     -- Golovkin 22.01.2013 I-00314776

    c_log_success                       CONSTANT PLS_INTEGER := 0;
    c_log_doc_exists                    CONSTANT PLS_INTEGER := 1;
    
    c_cash_doc_type                     CONSTANT CHAR (1) := 'А';        -- тип кассы
    с_cash_acc_ex                       CONSTANT VARCHAR (5) := '20208'; -- исключение балансовых счетов кассы для проверки символов
    
    /*** типы игнорируемых проверок ***/
    c_chk_default                       CONSTANT PLS_INTEGER := 0;          -- все проверки работают
    c_chk_payacc_exists                 CONSTANT PLS_INTEGER := 1;          -- не проверять наличие счета плательщика
    c_chk_payname_match                 CONSTANT PLS_INTEGER := 2;          -- не проверять наименование плательщика
    c_chk_recacc_exists                 CONSTANT PLS_INTEGER := 4;          -- не проверять наличие счета получателя
    c_chk_recname_match                 CONSTANT PLS_INTEGER := 8;          -- не проверять наименование получателя
    c_chk_pay_inn_fill                  CONSTANT PLS_INTEGER := 16;         -- не проверять/заполнять ИНН плательщика
    c_chk_rec_inn_fill                  CONSTANT PLS_INTEGER := 32;         -- не проверять/заполнять ИНН получателя
    c_chk_payacc_exists_full            CONSTANT PLS_INTEGER := 64;         -- не проверять наличие счета плательщика вообще
    c_chk_recacc_exists_full            CONSTANT PLS_INTEGER := 128;        -- не проверять наличие счета получател вообще
    c_chk_bic                           CONSTANT PLS_INTEGER := 256;        -- не проверять бики
    
    /*** название сторон ПИ ***/
    c_str_payer                         CONSTANT CHAR (11) := 'плательщика';
    c_str_receiver                      CONSTANT CHAR (10) := 'получателя';
    
    /*** некоторые коды субъектов ***/
    ptck_bic                            CONSTANT NUMBER (5) := 3;      -- БИК (РФ)
    ptck_clir                           CONSTANT NUMBER (5) := 5;      -- код клиринга СБ РФ
    ptck_swift                          CONSTANT NUMBER (5) := 6;      -- BIC ISO SWIFT

    v_err_in_pack                                BOOLEAN := FALSE;     -- флаг ошибки в пакете
    c_service_timeout                            PLS_INTEGER := 600;   -- таймаут ожидания сервиса в секундах
    v_last_error                                 VARCHAR2 (1024);      -- сообщение об ошибке
    
    c_ubs_pack                          CONSTANT NUMBER (5) := 162;       -- Номер пачки для "зелёного коридора" по умолчанию
    gv_ubs_pack                                  NUMBER (5) := 162;       -- Номер пачки для "зелёного коридора" из настройки PRBB\ИНТЕРФЕЙСЫ\UBS_PACK
    gv_igb_pack                                  VARCHAR2 (1024) := NULL; -- KS C-885 Номер пачки
    gv_igb_bic                                   VARCHAR2 (1024) := NULL; -- KS C-885 БИк получателя

    --- курсор для кэширования параметров нашего банка и всех филиалов ---
    -- ищется БИК вышестоящего узла, если для его нет у подчиненного
    -- ищется корсчет вышестоящего узла, если нет БИК у подчиненного
    CURSOR cr_init_bank_param  IS
        SELECT code, parent_code, party_id,
               DECODE (bic,
                       pm_common.rsb_empty_string, NVL ( (SELECT t_partyid
                                                            FROM ddp_dep_dbt d
                                                           WHERE d.t_code = parent_code),
                                                        party_id),
                       party_id)
                   parent_party_id,
               name,
               sw_name,
               curdate,                                                                          
               DECODE (
                   bic,
                   pm_common.rsb_empty_string, NVL (
                                                   (SELECT c.t_code
                                                      FROM dobjcode_dbt c, ddp_dep_dbt d
                                                     WHERE     c.t_objectid = d.t_partyid
                                                           AND c.t_objecttype = pm_common.objtype_party
                                                           AND c.t_codekind = ptck_bic
                                                           AND d.t_code = parent_code
                                                           AND c.t_state = 0),
                                                   NULL),
                   bic)
                   bic,
               DECODE (
                   swift,
                   pm_common.rsb_empty_string, NVL (
                                                   (SELECT c.t_code
                                                      FROM dobjcode_dbt c, ddp_dep_dbt d
                                                     WHERE     c.t_objectid = d.t_partyid
                                                           AND c.t_objecttype = pm_common.objtype_party
                                                           AND c.t_codekind = ptck_swift
                                                           AND d.t_code = parent_code
                                                           AND c.t_state = 0),
                                                   NULL),
                   swift)
                   swift,
               DECODE (
                   klir,
                   pm_common.rsb_empty_string, NVL (
                                                   (SELECT c.t_code
                                                      FROM dobjcode_dbt c, ddp_dep_dbt d
                                                     WHERE     c.t_objectid = d.t_partyid
                                                           AND c.t_objecttype = pm_common.objtype_party
                                                           AND c.t_codekind = ptck_clir
                                                           AND d.t_code = parent_code
                                                           AND c.t_state = 0),
                                                   NULL),
                   klir)
                   klir,
               DECODE (
                   inn,
                   pm_common.rsb_empty_string, NVL (
                                                   (SELECT c.t_code
                                                      FROM dobjcode_dbt c, ddp_dep_dbt d
                                                     WHERE     c.t_objectid = d.t_partyid
                                                           AND c.t_objecttype = pm_common.objtype_party
                                                           AND c.t_codekind = pm_common.ptck_inn
                                                           AND d.t_code = parent_code
                                                           AND c.t_state = 0),
                                                   pm_common.rsb_empty_string),
                   inn)
                   inn,                                                                          
               DECODE (bic,
                       pm_common.rsb_empty_string, NVL ( (SELECT b.t_coracc
                                                            FROM dbankdprt_dbt b, ddp_dep_dbt d
                                                           WHERE b.t_partyid = d.t_partyid AND d.t_code = parent_code),
                                                        pm_common.rsb_empty_string),
                       coracc)
                   coracc
          FROM (  SELECT /*+INDEX(bnk dbankdprt_dbt_idx0)*/
                        f.t_code code,
                         (    SELECT MAX (t_code)
                                --ищется вышестоящий филиал, имеющий БИК
                                FROM ddp_dep_dbt dep
                               WHERE EXISTS
                                         (SELECT t_code
                                            FROM dpartcode_dbt
                                           WHERE t_partyid = dep.t_partyid AND t_codekind = pm_common.ptck_bic)
                          CONNECT BY PRIOR dep.t_parentcode = dep.t_code
                          START WITH dep.t_code = f.t_code)
                             parent_code,
                         f.t_partyid party_id,
                         p.t_name || ' ' || UPPER (bnk.t_place) || ' ' || bnk.t_placename name,
                         bnk_sw.t_institutionname || ' ' || bnk_sw.t_location sw_name,
                         NVL (MAX (d.t_curdate), TO_DATE ('01-01-0001', 'DD-MM-YYYY')) curdate,
                         NVL (bic.t_code, pm_common.rsb_empty_string) bic,
                         NVL (swift.t_code, pm_common.rsb_empty_string) swift,
                         NVL (klir.t_code, pm_common.rsb_empty_string) klir,
                         NVL (inn.t_code, pm_common.rsb_empty_string) inn,
                         NVL (bnk.t_coracc, pm_common.rsb_empty_string) coracc
                    FROM ddp_dep_dbt f,
                         dcurdate_dbt d,
                         dparty_dbt p,
                         dobjcode_dbt inn,
                         dobjcode_dbt swift,
                         dobjcode_dbt bic,
                         dobjcode_dbt klir,
                         dbankdprt_dbt bnk,
                         dptbicdir_dbt bnk_sw
                   WHERE     d.t_branch(+) = f.t_code
                         AND p.t_partyid(+) = f.t_partyid
                         AND d.t_isclosed(+) <> 'X'
                         AND d.t_ismain(+) = 'X' -- KS 13.02.2014 Нужен именно текущий день филиала
                         AND inn.t_objecttype(+) = pm_common.objtype_party
                         AND inn.t_codekind(+) = pm_common.ptck_inn
                         AND inn.t_objectid(+) = f.t_partyid
                         AND bic.t_objecttype(+) = pm_common.objtype_party
                         AND bic.t_codekind(+) = ptck_bic
                         AND bic.t_objectid(+) = f.t_partyid
                         AND klir.t_objecttype(+) = pm_common.objtype_party
                         AND klir.t_codekind(+) = ptck_clir
                         AND klir.t_objectid(+) = f.t_partyid
                         AND swift.t_objectid(+) = f.t_partyid
                         AND swift.t_objecttype(+) = pm_common.objtype_party
                         AND swift.t_codekind(+) = ptck_swift
                         AND bnk.t_partyid(+) = f.t_partyid
                         AND bnk_sw.t_partyid(+) = f.t_partyid
                GROUP BY f.t_code,
                         f.t_partyid,
                         p.t_name,
                         bic.t_code,
                         inn.t_code,
                         swift.t_code,
                         klir.t_code,
                         bnk.t_coracc,
                         bnk.t_place,
                         bnk.t_placename,
                         bnk_sw.t_location,
                         bnk_sw.t_institutionname);
    --- курсор для кэширования корсхем ---
    CURSOR cr_init_corschem  IS SELECT cs.t_number num, cs.t_fiid fiid, cs.t_account account, cs.t_department department FROM dcorschem_dbt cs WHERE t_state = 0;

    --- курсор для cправочника видов валютных операций ---
    CURSOR cr_init_voopkind  IS SELECT NVL (vok.t_direction, 0) direction, vok.t_element element FROM dvoopkind_dbt vok;

    --- курсор для cправочника стран ---
    CURSOR cr_init_country  IS SELECT NVL (cdb.t_codenum3, pm_common.rsb_empty_string) codenum, cdb.t_codelat3 codelat FROM dcountry_dbt cdb WHERE cdb.t_codelat3 != pm_common.rsb_empty_string;

    --Gurin S. 18.12.2013 C-25621-7 добавил параметр packsnumbers
    CURSOR cr_find_corschem ( department NUMBER, fiid NUMBER, bank_id NUMBER, packsnumbers VARCHAR2) IS
        --курсор поиска корсхемы по БИКу банка
        SELECT t_number
          FROM (SELECT t_number, 9998 t_sort                                                                          --ищется схема расчетов для корреспондента
                  FROM dcorschem_dbt cs
                 WHERE cs.t_fiid = fiid AND t_state = 0 AND t_department = 1 AND t_corrid = bank_id
                UNION
                SELECT t_schem, t_sort                                                                          --ищется схема расчетов с банком корреспондентом
                  FROM dbnkschem_dbt cs, dobjcode_dbt ob, dcorschem_dbt c
                 WHERE     cs.t_fiid = fiid
                       AND cs.t_fi_kind = 1
                       AND cs.t_state = 0
                       AND cs.t_codekind = ob.t_codekind
                       AND cs.t_department = department
                       AND TO_DATE ('01010001' || TO_CHAR (SYSDATE, ' HH24MISS'), 'DDMMYYYY HH24MISS') >=
                               DECODE (TO_CHAR (t_beginperiod, 'HH24MISS'), '000000', TO_DATE ('01010001 000001', 'DDMMYYYY HH24MISS'), t_beginperiod)
                       AND TO_DATE ('01010001' || TO_CHAR (SYSDATE, ' HH24MISS'), 'DDMMYYYY HH24MISS') <
                               DECODE (TO_CHAR (t_endperiod, 'HH24MISS'), '000000', TO_DATE ('01010001 235959', 'DDMMYYYY HH24MISS'), t_endperiod)
                       -- KS Адаптация патч 30 04.07.2011
                       AND (rsi_rsb_mask.comparestringwithmask (cs.t_bankcode, ob.t_code) = 1 OR cs.t_bankcode = pm_common.rsb_empty_string)
                       --Gurin S. 18.12.2013 C-25621-7
                       AND (wld_pos.PT_PackIncludedRange(cs.t_packsnumbers, to_number(packsnumbers) ) = 0 OR cs.t_packsnumbers = pm_common.rsb_empty_string)
                       AND ob.t_objecttype = pm_common.objtype_party
                       AND ob.t_objectid = bank_id
                       AND c.t_number = cs.t_schem
                       AND c.t_state = 0
                UNION
                SELECT t_schem, t_sort                                                                           --ищется схема расчетов по умолчанию для валюты
                  FROM dbnkschem_dbt cs, dcorschem_dbt c
                 WHERE     cs.t_fiid = fiid
                       AND cs.t_fi_kind = 1
                       AND cs.t_state = 0
                       AND cs.t_department = department
                       AND cs.t_bankid = -1
                       AND c.t_number = cs.t_schem
                       AND c.t_state = 0
                       --Gurin S. 18.12.2013 C-25621-7
                       AND (wld_pos.PT_PackIncludedRange(cs.t_packsnumbers, to_number(packsnumbers) ) = 0 OR cs.t_packsnumbers = pm_common.rsb_empty_string)
                UNION
                SELECT t_number, 9999
                  FROM dcorschem_dbt cs                                                                              --ищется валютная схема расчетов для валюты
                 WHERE cs.t_fiid = fiid AND cs.t_fiid <> 0 AND cs.t_fi_kind = 1 AND t_state = 0 AND t_department = department
                ORDER BY t_sort);

    CURSOR cr_get_account/*_rub*/ (-- KS 27.11.2013 Адаптация 31ю сборку
        account VARCHAR2,
        chapter NUMBER,
        fiid    NUMBER -- KS 27.11.2013 Адаптация 31ю сборку
        ) IS
        SELECT t_account,
               t_type_account,
               t_chapter,
               t_oper,
               t_department,
               t_branch,
               t_client,
               t_name,
               t_code,
               t_nameaccount
          FROM (SELECT ac.t_account,
                       ac.t_type_account,
                       ac.t_chapter,
                       ac.t_oper,
                       ac.t_department,
                       ac.t_branch,
                       ac.t_client,
                       NVL (pt.t_name, pm_common.rsb_empty_string) t_name,
                       NVL (cd1.t_code, pm_common.rsb_empty_string) t_code,
                       ac.t_nameaccount
                  FROM daccount_dbt ac, dparty_dbt pt, dobjcode_dbt cd1
                 WHERE     t_account = account
                       AND t_chapter = chapter
                       and t_code_currency = fiid -- KS 27.11.2013 Адаптация 31ю сборку
                       AND pt.t_partyid(+) = ac.t_client
                       AND cd1.t_objecttype(+) = pm_common.objtype_party
                       AND cd1.t_objectid(+) = pt.t_partyid
                       AND cd1.t_codekind(+) = pm_common.ptck_inn
                       AND cd1.t_state(+) = 0);
                       
    -- KS 27.11.2013 Адаптация 31ю сборку
/*
    CURSOR cr_get_account_val (
        account                                  VARCHAR2,
        chapter                                  NUMBER,
        fiid                                     NUMBER) IS
        SELECT t_account,
               t_type_account,
               t_chapter,
               t_oper,
               t_department,
               t_branch,
               t_client,
               t_name,
               t_code,
               t_nameaccount
          FROM (  SELECT ac.t_account,
                         ac.t_type_account,
                         ac.t_chapter,
                         ac.t_oper,
                         ac.t_department,
                         ac.t_branch,
                         ac.t_client,
                         NVL (pt.t_name, pm_common.rsb_empty_string) t_name,
                         NVL (cd1.t_code, pm_common.rsb_empty_string) t_code,
                         ac.t_nameaccount
                    FROM daccount$_dbt ac, dparty_dbt pt, dobjcode_dbt cd1
                   WHERE     t_account = account
                         AND t_chapter = chapter
                         AND t_code_currency = fiid
                         AND pt.t_partyid(+) = ac.t_client
                         AND cd1.t_objecttype(+) = pm_common.objtype_party
                         AND cd1.t_objectid(+) = pt.t_partyid
                         AND cd1.t_codekind(+) = pm_common.ptck_inn
                         AND cd1.t_state(+) = 0
                ORDER BY 1 DESC);
*/

    CURSOR cr_get_bank_info (
        code VARCHAR2) IS
        --курсор для получения информации о банке по его коду БИК или SWIFT
        SELECT t_objectid,
               CASE ob.t_codekind
                   WHEN ptck_swift THEN
                       (SELECT t_institutionname
                          FROM dptbicdir_dbt
                         WHERE t_partyid = ob.t_objectid)
                   WHEN ptck_bic THEN
                       (SELECT t_name
                          FROM dparty_dbt
                         WHERE t_partyid = ob.t_objectid)
                   WHEN ptck_clir THEN
                       (SELECT t_name
                          FROM dparty_dbt
                         WHERE t_partyid = ob.t_objectid)
               END
                   t_name,
               CASE ob.t_codekind
                   WHEN ptck_swift THEN
                       pm_common.rsb_empty_string
                   WHEN ptck_bic THEN
                       (SELECT t_coracc
                          FROM dbankdprt_dbt
                         WHERE t_partyid = ob.t_objectid)
                   WHEN ptck_clir THEN
                       (SELECT t_coracc
                          FROM dbankdprt_dbt
                         WHERE t_partyid = ob.t_objectid)
               END
                   t_coracc,
               CASE ob.t_codekind
                   WHEN ptck_swift THEN
                       (SELECT t_city
                          FROM dptbicdir_dbt
                         WHERE t_partyid = ob.t_objectid)
                   WHEN ptck_bic THEN
                       (SELECT UPPER (t_place || ' ' || t_placename)
                          FROM dbankdprt_dbt
                         WHERE t_partyid = ob.t_objectid)
                   WHEN ptck_clir THEN
                       (SELECT UPPER (t_place || ' ' || t_placename)
                          FROM dbankdprt_dbt
                         WHERE t_partyid = ob.t_objectid)
               END
                   t_place,
               ob.t_codekind,
               obk.t_shortname
          FROM dobjcode_dbt ob, dobjkcode_dbt obk
         WHERE     ob.t_objecttype = pm_common.objtype_party
               AND ob.t_code = code
               AND ob.t_state = 0
               AND ob.t_codekind IN (ptck_bic, ptck_swift, ptck_clir)
               AND obk.t_codekind = ob.t_codekind
               AND obk.t_objecttype = ob.t_objecttype;


    CURSOR cr_valid_origins  IS
        --Происх-ние руб.пл. документов--------
        SELECT 200, t_element
          FROM dllvalues_dbt
         WHERE t_list = 1660
        UNION ALL                                                                                                                --Происх-ние руб.пл. документов
        SELECT 201, t_element
          FROM dllvalues_dbt
         WHERE t_list = 1650
        UNION ALL
        --Происх-ние платежей банка
        SELECT 16, t_element
          FROM dllvalues_dbt
         WHERE t_list = 1665
        UNION ALL
        --Происх-ние мемориальных орд.
        SELECT 70, t_element
          FROM dllvalues_dbt
         WHERE t_list = 1670
        UNION ALL
        --Происх-ние мультивалютных
        SELECT 15, t_element
          FROM dllvalues_dbt
         WHERE t_list = 1671
        UNION ALL
        --Происх-ние кассовых ордеров
        SELECT 400, t_element
          FROM dllvalues_dbt
         WHERE t_list = 1672
        UNION ALL
        --Происх-ние вал.пл. документов
        SELECT 202, t_element
          FROM dllvalues_dbt
         WHERE t_list = 1655
        UNION ALL
        --Происх-ние валютных платежей банка
        SELECT 27, t_element
          FROM dllvalues_dbt
         WHERE t_list = 1665
        UNION ALL
        --Происх-ние внешних входящих платежей
        SELECT 320, t_element
          FROM dllvalues_dbt
         WHERE t_list = 1674
        UNION ALL
        --Происх-ние банковских ордеров
        SELECT 286, t_element
          FROM dllvalues_dbt
         WHERE t_list = 1674;


    CURSOR cr_init_tp_glob_rec  IS
        --курсор для получения вспомогательных данных
        SELECT SYSDATE, SUBSTR (VALUE, 0, 1)
          FROM v$nls_parameters
         WHERE parameter = 'NLS_NUMERIC_CHARACTERS';

    TYPE docs_origin_rec IS RECORD
    (
        doc_kind                                     NUMBER,
        origin                                       NUMBER
    );


    CURSOR cr_init_cash_symbs  IS
        --курсор для кэширования кассовых символов
        SELECT t_symb_cash, t_type_symbol
          FROM dlistsymb_dbt
         WHERE t_dockind = 1 AND t_symb_cash NOT IN (' 03', ' 23', ' 62')                                               -- UDA 15.08.2012 по заявке I-00236973-2
        UNION
        SELECT ' 0', 3 FROM DUAL;                                                                            -- KS 28.10.2011 Для возможности ввода без символов

    CURSOR cr_init_comisscharge  IS
        SELECT t_code code, t_element id
          FROM dllvalues_dbt
         WHERE t_list = 1680;

    CURSOR cr_init_vo  IS
        SELECT t_code code, t_element id
          FROM dllvalues_dbt
         WHERE t_list = 1805;

    CURSOR opr_values (operblockid NUMBER, kind_operation NUMBER, is2carry NUMBER --курсор для кэширования значений сегментов статусов для отложенного платежа и
                                                                                 --для планирования блока зачисление
                                                                                 /*1 = для выполнение шага зачисления 0 = для отложенных*/
    ) IS
        SELECT t_statuskindid, t_numvalue
          FROM doprinist_dbt
         WHERE t_kind_operation = kind_operation
        UNION
        SELECT t_statuskindid, t_numvalue
          FROM doprcblck_dbt
         WHERE t_operblockid = operblockid AND t_condition = 0 AND is2carry = 1;

    CURSOR cr_oper                                                                                                       -- KS 15.04.2011 Проверим операциониста
                  IS
        SELECT t_oper
          FROM dperson_dbt person
         WHERE person.t_userblocked = pm_common.rsb_empty_char AND person.t_userclosed = pm_common.rsb_empty_char;

    TYPE our_bank_param_rec IS RECORD
    (
        code                                         ddp_dep_dbt.t_code%TYPE,
        parent_code                                  ddp_dep_dbt.t_code%TYPE,                                     -- код и ID вышестоящего филиала, имеющего БИК
        party_id                                     dparty_dbt.t_partyid%TYPE,
        parent_party_id                              dparty_dbt.t_partyid%TYPE,
        name                                         dparty_dbt.t_name%TYPE,
        sw_name                                      dparty_dbt.t_name%TYPE,
        curdate                                      DATE,
        bic_code                                     dobjcode_dbt.t_code%TYPE,
        swift_code                                   dobjcode_dbt.t_code%TYPE,
        klir_code                                    dobjcode_dbt.t_code%TYPE,
        inn                                          dobjcode_dbt.t_code%TYPE,
        coracc                                       daccount_dbt.t_account%TYPE
    );

    TYPE check_rules_rec IS RECORD
    (
        skip_payacc_exists                           BOOLEAN,
        skip_payname_match                           BOOLEAN,
        skip_recacc_exists                           BOOLEAN,
        skip_recname_match                           BOOLEAN,
        skip_rec_inn_fill                            BOOLEAN,
        skip_pay_inn_fill                            BOOLEAN,
        skip_payacc_exists_full                      BOOLEAN,
        skip_recacc_exists_full                      BOOLEAN,
        skip_bic                                     BOOLEAN
    );

    TYPE dockind_param_rec IS RECORD
    (
        dockind                                      NUMBER,
        fillname_keypath                             VARCHAR (128),
        fillname_value                               NUMBER,
        fillbank_keypath                             VARCHAR (128),
        fillbank_value                               NUMBER
    );

    TYPE stats_rec IS RECORD
    (
        statid                                       NUMBER,
        statvalue                                    NUMBER
    );

    TYPE nt_stats IS TABLE OF stats_rec;

    TYPE oprstat_rec IS RECORD
    (
        opr_id                                       NUMBER,
        carry_step_id                                NUMBER,
        statvalues_2carry                            nt_stats,
        statvalues_2deff                             nt_stats
    );

    TYPE oprstat_nt IS TABLE OF oprstat_rec;

    nt_oprstat                                   oprstat_nt := oprstat_nt ();

    TYPE oprcurst_nt IS TABLE OF doprcurst_dbt%ROWTYPE;

    TYPE pmpaym_nt IS TABLE OF dpmpaym_dbt%ROWTYPE;

    TYPE pmprop_nt IS TABLE OF dpmprop_dbt%ROWTYPE;

    TYPE pmrmprop_nt IS TABLE OF dpmrmprop_dbt%ROWTYPE;

    TYPE cb_doc_nt IS TABLE OF dcb_doc_dbt%ROWTYPE;

    TYPE pspayord_nt IS TABLE OF dpspayord_dbt%ROWTYPE;

    TYPE pspaydem_nt IS TABLE OF dpspaydem_dbt%ROWTYPE;

    TYPE oproper_nt IS TABLE OF doproper_dbt%ROWTYPE;

    TYPE memorder_nt IS TABLE OF dmemorder_dbt%ROWTYPE;

    TYPE pscshdoc_nt IS TABLE OF dpscshdoc_dbt%ROWTYPE;

    TYPE symbcash_nt IS TABLE OF dsymbcash_dbt%ROWTYPE;

    TYPE multydoc_nt IS TABLE OF dmultydoc_dbt%ROWTYPE;

    TYPE pscpord_nt IS TABLE OF dpscpord_dbt%ROWTYPE;

    TYPE wlpm_nt IS TABLE OF dwlpm_dbt%ROWTYPE;


    TYPE dps_bcord_nt IS TABLE OF dps_bcord_dbt%ROWTYPE;                                                                                                   -----

    TYPE dps_bcexe_nt IS TABLE OF dps_bcexe_dbt%ROWTYPE;                                                                                                   -----

    TYPE dps_ordoc_nt IS TABLE OF dps_ordoc_dbt%ROWTYPE;                                                                                                   -----


    TYPE pmco_nt IS TABLE OF dpmco_dbt%ROWTYPE;

    TYPE pmcurtr_nt IS TABLE OF dpmcurtr_dbt%ROWTYPE;                                                         -- KS Адаптация патч 30 05.09.2011 co2029_2030.sql

    TYPE bbcpord_nt IS TABLE OF dbbcpord_dbt%ROWTYPE;

    TYPE our_bank_param_nt IS TABLE OF cr_init_bank_param%ROWTYPE;

    TYPE corschemes_nt IS TABLE OF cr_init_corschem%ROWTYPE;

    TYPE docs_origin_nt IS TABLE OF docs_origin_rec;

    TYPE voopkind_nt IS TABLE OF cr_init_voopkind%ROWTYPE;                                                    -- KS Адаптация патч 30 05.09.2011 co2029_2030.sql

    TYPE country_nt IS TABLE OF cr_init_country%ROWTYPE;                                                      -- KS Адаптация патч 30 05.09.2011 co2029_2030.sql

    TYPE cash_symbs_nt IS TABLE OF cash_symbs_rec;

    TYPE dockind_param_nt IS TABLE OF dockind_param_rec;

    TYPE vocode_nt IS TABLE OF cr_init_vo%ROWTYPE;

    TYPE comisscharges_nt IS TABLE OF cr_init_comisscharge%ROWTYPE;

    TYPE oper_nt IS TABLE OF cr_oper%ROWTYPE;

    nt_dockind_param                             dockind_param_nt := dockind_param_nt ();
    nt_pmpaym                                    pmpaym_nt := pmpaym_nt ();
    nt_pmprop                                    pmprop_nt := pmprop_nt ();
    nt_pmrmprop                                  pmrmprop_nt := pmrmprop_nt ();
    nt_cb_doc                                    cb_doc_nt := cb_doc_nt ();
    nt_pspayord                                  pspayord_nt := pspayord_nt ();
    nt_pspaydem                                  pspaydem_nt := pspaydem_nt ();
    nt_oproper                                   oproper_nt := oproper_nt ();
    nt_memorder                                  memorder_nt := memorder_nt ();
    nt_symbcash                                  symbcash_nt := symbcash_nt ();
    nt_pscshdoc                                  pscshdoc_nt := pscshdoc_nt ();
    nt_oprcurst                                  oprcurst_nt := oprcurst_nt ();
    nt_oprcurst_tmp                              oprcurst_nt := oprcurst_nt ();
    nt_cash_symbs                                cash_symbs_nt := cash_symbs_nt ();
    nt_multydoc                                  multydoc_nt := multydoc_nt ();
    nt_pscpord                                   pscpord_nt := pscpord_nt ();
    nt_bbcpord                                   bbcpord_nt := bbcpord_nt ();
    nt_pmco                                      pmco_nt := pmco_nt ();
    nt_pmcurtr                                   pmcurtr_nt := pmcurtr_nt ();                                 -- KS Адаптация патч 30 05.09.2011 co2029_2030.sql
    nt_wlpm                                      wlpm_nt := wlpm_nt ();
    nt_vocode                                    vocode_nt;
    nt_comisscharges                             comisscharges_nt;
    nt_oper                                      oper_nt;


    nt_dps_bcord                                 dps_bcord_nt := dps_bcord_nt ();                                                                           ----
    nt_dps_bcexe                                 dps_bcexe_nt := dps_bcexe_nt ();                                                                           ----
    nt_dps_ordoc                                 dps_ordoc_nt := dps_ordoc_nt ();                                                                            ---

    nt_our_bank_param                            our_bank_param_nt;
    nt_corschemes                                corschemes_nt;
    nt_docs_origin                               docs_origin_nt;
    nt_voopkind                                  voopkind_nt;                                                 -- KS Адаптация патч 30 05.09.2011 co2029_2030.sql
    nt_country                                   country_nt;                                                  -- KS Адаптация патч 30 05.09.2011 co2029_2030.sql
    check_rules                                  check_rules_rec;
    tp_glob                                      tp_glob_rec;
    --
    e_error_due_pack_first                       EXCEPTION;
    e_error_due_pack_next                        EXCEPTION;
    e_error_due_single                           EXCEPTION;
    e_error_due_create                           EXCEPTION;
    e_error_due_complete                         EXCEPTION;
    e_error_check_payment                        EXCEPTION;
    e_error_start_oper                           EXCEPTION;
    e_error_carry_backout                        EXCEPTION;
    e_error_del_payment                          EXCEPTION;
    e_error_sum_mismatch                         EXCEPTION;
    e_error_run_operation                        EXCEPTION;
    e_error_service_not_ready                    EXCEPTION;

    FUNCTION get_parent_department_code (p_department IN NUMBER)
        RETURN NUMBER IS
    BEGIN
        FOR i IN nt_our_bank_param.FIRST .. nt_our_bank_param.LAST LOOP
            IF nt_our_bank_param (i).code = p_department THEN
                RETURN nt_our_bank_param (i).parent_code;
                EXIT;
            END IF;
        END LOOP;

        RETURN NULL;
    END;

    FUNCTION get_parent_department_id (p_department IN NUMBER)
        RETURN NUMBER IS
    BEGIN
        FOR i IN nt_our_bank_param.FIRST .. nt_our_bank_param.LAST LOOP
            IF nt_our_bank_param (i).code = p_department THEN
                RETURN nt_our_bank_param (i).parent_party_id;
                EXIT;
            END IF;
        END LOOP;

        RETURN NULL;
    END;

    PROCEDURE make_error_text (err_msg                                 IN            VARCHAR2,
                               err_text                                IN OUT NOCOPY VARCHAR2,
                               err_param1                              IN            VARCHAR2 DEFAULT NULL,
                               err_param2                              IN            VARCHAR2 DEFAULT NULL) IS
    BEGIN
        IF err_text = usr_common.c_err_success THEN
            err_text     := REPLACE (REPLACE (err_msg, '%p1', err_param1), '%p2', err_param2);
        ELSE
            err_text     := err_text || CHR (10) || REPLACE (REPLACE (err_msg, '%p1', err_param1), '%p2', err_param2);
        END IF;
    END;

    PROCEDURE parse_check_rules (rule_mask NUMBER) IS
    BEGIN
        check_rules.skip_payacc_exists          := BITAND (rule_mask, c_chk_payacc_exists) = c_chk_payacc_exists;
        check_rules.skip_payname_match          := BITAND (rule_mask, c_chk_payname_match) = c_chk_payname_match;
        check_rules.skip_recacc_exists          := BITAND (rule_mask, c_chk_recacc_exists) = c_chk_recacc_exists;
        check_rules.skip_recname_match          := BITAND (rule_mask, c_chk_recname_match) = c_chk_recname_match;
        check_rules.skip_rec_inn_fill           := BITAND (rule_mask, c_chk_rec_inn_fill) = c_chk_rec_inn_fill;
        check_rules.skip_pay_inn_fill           := BITAND (rule_mask, c_chk_pay_inn_fill) = c_chk_pay_inn_fill;
        check_rules.skip_recacc_exists_full     := BITAND (rule_mask, c_chk_recacc_exists_full) = c_chk_recacc_exists_full;
        check_rules.skip_payacc_exists_full     := BITAND (rule_mask, c_chk_payacc_exists_full) = c_chk_payacc_exists_full;
        check_rules.skip_bic                    := BITAND (rule_mask, c_chk_bic) = c_chk_bic;
    END;


    FUNCTION get_carry_fiid (p_payacc VARCHAR2, p_recacc VARCHAR2)
        RETURN NUMBER IS
        v_pay_fiid                                   NUMBER;
        v_rec_fiid                                   NUMBER;
        v_doc_fiid                                   NUMBER;
    BEGIN
        v_pay_fiid     := usr_common.get_fiid (p_payacc);
        v_rec_fiid     := usr_common.get_fiid (p_recacc);

        IF (v_pay_fiid = 0 OR v_rec_fiid = 0) OR (v_pay_fiid > 0 AND v_rec_fiid > 0 AND v_pay_fiid <> v_rec_fiid)                    --проводка между покрытиями
                                                                                                                 THEN
            v_doc_fiid     := 0;
        ELSE
            --определяем валюту проводки по одному из счетов
            IF v_pay_fiid != -1 THEN
                v_doc_fiid     := v_pay_fiid;
            ELSE
                v_doc_fiid     := v_rec_fiid;
            END IF;
        END IF;

        RETURN v_doc_fiid;
    END;


    PROCEDURE modify_oprstatval (oprid                                    NUMBER,
                                 statid                                   NUMBER,
                                 statvalue                                NUMBER,
                                 is2run                                   BOOLEAN) IS
        --процедура изменения/добавлнения значений сегментов статусов операции
        lv_found                                     BOOLEAN := FALSE;
    BEGIN
        FOR i IN nt_oprstat.FIRST .. nt_oprstat.LAST LOOP
            IF nt_oprstat (i).opr_id = oprid THEN
                IF is2run THEN
                    FOR j IN nt_oprstat (i).statvalues_2carry.FIRST .. nt_oprstat (i).statvalues_2carry.LAST LOOP
                        IF nt_oprstat (i).statvalues_2carry (j).statid = statid THEN
                            nt_oprstat (i).statvalues_2carry (j).statvalue     := statvalue;
                            lv_found                                           := TRUE;
                            EXIT;
                        END IF;
                    END LOOP;

                    IF NOT lv_found THEN
                        nt_oprstat (i).statvalues_2carry.EXTEND (1);
                        nt_oprstat (i).statvalues_2carry (nt_oprstat (i).statvalues_2carry.COUNT).statid        := statid;
                        nt_oprstat (i).statvalues_2carry (nt_oprstat (i).statvalues_2carry.COUNT).statvalue     := statvalue;
                    END IF;
                ELSE
                    FOR j IN nt_oprstat (i).statvalues_2deff.FIRST .. nt_oprstat (i).statvalues_2deff.LAST LOOP
                        IF nt_oprstat (i).statvalues_2deff (j).statid = statid THEN
                            nt_oprstat (i).statvalues_2deff (j).statvalue     := statvalue;
                            lv_found                                          := TRUE;
                            EXIT;
                        END IF;
                    END LOOP;


                    IF NOT lv_found THEN
                        nt_oprstat (i).statvalues_2deff.EXTEND (1);
                        nt_oprstat (i).statvalues_2deff (nt_oprstat (i).statvalues_2deff.COUNT).statid        := statid;
                        nt_oprstat (i).statvalues_2deff (nt_oprstat (i).statvalues_2deff.COUNT).statvalue     := statvalue;
                    END IF;
                END IF;
            END IF;
        END LOOP;
    END;


    PROCEDURE init IS
        FUNCTION init_nt (p_dockind NUMBER, p_fillname_path VARCHAR2, p_fillbank_path VARCHAR2)
            RETURN dockind_param_rec IS
            nt                                           dockind_param_rec;
        BEGIN
            nt.dockind              := p_dockind;
            nt.fillname_keypath     := p_fillname_path;
            nt.fillname_value       :=                                                                                                                  /*1;--*/
                                      NVL (rsb_common.getregintvalue (p_fillname_path, 0), 1);                 --KS 10.10.2011 Раскомментировал чтение настройки
            nt.fillbank_keypath     := p_fillbank_path;
            nt.fillbank_value       :=                                                                                                                  /*1;--*/
                                      NVL (rsb_common.getregintvalue (p_fillbank_path, 0), 1);                 --KS 10.10.2011 Раскомментировал чтение настройки

            RETURN nt;
        EXCEPTION
            WHEN OTHERS THEN
                make_error_text (c_err_init_error, nt_main_doc (gv_cnt).tech_parm_rec.ERROR_TEXT, ' при чтении настроек реестра');
        END;

    BEGIN
        gv_cnt                    := 1;
        gv_rindex                 := DBMS_APPLICATION_INFO.set_session_longops_nohint;
        usr_common.init;

        -- KS 21.04.2011 Номер пачки для "Зелёного коридора"
        gv_ubs_pack               := NVL (rsb_common.getregintvalue ('PRBB\ИНТЕРФЕЙСЫ\UBS_PACK', 0), c_ubs_pack);
        -- KS 23.05.2011 Включить дебаг-режим
        c_mode_debug              := NVL (rsb_common.getregboolvalue ('PRBB\ИНТЕРФЕЙСЫ\MODE_DEBUG', 0), c_mode_debug);
        -- KS 16.06.2011 C-885
        gv_igb_pack               :=
            rsb_common.getregstrvalue ('PRBB\МЕЖБАНКОВСКИЕ РАСЧЕТЫ\СХЕМА_МОМЕНТАЛЬНЫХ_ПЕРЕВОДОВ\ПАЧКА', 0);
        gv_igb_bic                :=
            rsb_common
             .getregstrvalue (
                'PRBB\МЕЖБАНКОВСКИЕ РАСЧЕТЫ\СХЕМА_МОМЕНТАЛЬНЫХ_ПЕРЕВОДОВ\БИК_ПОЛУЧАТЕЛЯ',
                0);

        /*if c_mode_debug
        then
           execute immediate 'alter session set plsql_ccflags = ''TRACE:TRUE''';
        end if;*/
        --инициализация правил заполнения наименований в документе
        nt_dockind_param.EXTEND (12);
        nt_dockind_param (1)      := init_nt (c_dockind_client_paym, 'PS\PAYORDER\ORDER\FILLNAME', 'PS\PAYORDER\ORDER\FILLBANK');
        nt_dockind_param (2)      := init_nt (c_dockind_client_order, 'PS\PAYORDER\DEMAND\FILLNAME', 'PS\PAYORDER\DEMAND\FILLBANK');
        nt_dockind_param (3)      := init_nt (c_dockind_bank_paym, 'BBANK\PAYORDER\PAYMENT\FILLNAME', 'BBANK\PAYORDER\PAYMENT\FILLBANK');
        nt_dockind_param (4)      := init_nt (c_dockind_client_cash_out, 'PS\CASHORDER\OUTORDER\FILLNAME', 'PS\CASHORDER\OUTORDER\FILLBANK');
        nt_dockind_param (5)      := init_nt (c_dockind_client_cash_in, 'PS\CASHORDER\INCORDER\FILLNAME', 'PS\CASHORDER\INCORDER\FILLBANK');
        nt_dockind_param (6)      := init_nt (c_dockind_cash_inout, 'BBANK\CASHORDER\ADDORDER\FILLNAME', 'BBANK\CASHORDER\ADDORDER\FILLBANK');
        nt_dockind_param (7)      := init_nt (c_dockind_cash_in, 'BBANK\CASHORDER\INCORDER\FILLNAME', 'BBANK\CASHORDER\INCORDER\FILLBANK');
        nt_dockind_param (8)      := init_nt (c_dockind_cash_out, 'BBANK\CASHORDER\OUTORDER\FILLNAME', 'BBANK\CASHORDER\OUTORDER\FILLBANK');
        nt_dockind_param (9)      := init_nt (c_dockind_multycarry, 'BBANK\MCDOC\FILLNAME', 'BBANK\MCDOC\FILLBANK');
        nt_dockind_param (10)     := init_nt (c_dockind_memorder, 'BBANK\MEMORDER\FILLNAME', 'BBANK\MEMORDER\FILLBANK');
        nt_dockind_param (11)     := init_nt (c_dockind_bank_order, 'BBANK\PAYORDER\CLAIM\FILLNAME', 'BBANK\PAYORDER\CLAIM\FILLBANK');
        nt_dockind_param (12)     := init_nt (c_dockind_memorder_bank_order, 'BBANK\BANKORDER\FILLNAME', 'BBANK\BANKORDER\FILLBANK'); -- KS 29.07.2011 Банковский ордер

        OPEN cr_init_bank_param;

        FETCH cr_init_bank_param
            BULK COLLECT INTO nt_our_bank_param;

        CLOSE cr_init_bank_param;

        OPEN cr_init_corschem;

        FETCH cr_init_corschem
            BULK COLLECT INTO nt_corschemes;

        CLOSE cr_init_corschem;

        OPEN cr_valid_origins;

        FETCH cr_valid_origins
            BULK COLLECT INTO nt_docs_origin;

        CLOSE cr_valid_origins;

        OPEN cr_init_tp_glob_rec;

        FETCH cr_init_tp_glob_rec INTO tp_glob;

        CLOSE cr_init_tp_glob_rec;

        OPEN cr_init_cash_symbs;

        FETCH cr_init_cash_symbs
            BULK COLLECT INTO nt_cash_symbs;

        CLOSE cr_init_cash_symbs;

        FOR i
            IN (SELECT ROWNUM num, o.t_kind_operation, opb.t_operblockid
                  FROM doproblck_dbt opb, doprblock_dbt bl, doprkoper_dbt o
                 WHERE     opb.t_kind_operation = o.t_kind_operation
                       AND opb.t_blockid = bl.t_blockid
                       AND UPPER (bl.t_name) LIKE 'ЗАЧИСЛЕНИЕ'
                       AND o.t_dockind = 29
                       AND o.t_notinuse <> pm_common.set_char
                       AND o.t_kind_operation > 0) LOOP
            nt_oprstat.EXTEND (1);
            nt_oprstat (i.num).opr_id     := i.t_kind_operation;

            OPEN opr_values (i.t_operblockid, i.t_kind_operation, 0);

            FETCH opr_values
                BULK COLLECT INTO nt_oprstat (i.num).statvalues_2deff;

            CLOSE opr_values;

            OPEN opr_values (i.t_operblockid, i.t_kind_operation, 1);

            FETCH opr_values
                BULK COLLECT INTO nt_oprstat (i.num).statvalues_2carry;

            CLOSE opr_values;
        END LOOP;

        OPEN cr_init_vo;

        FETCH cr_init_vo
            BULK COLLECT INTO nt_vocode;

        CLOSE cr_init_vo;

        OPEN cr_init_comisscharge;

        FETCH cr_init_comisscharge
            BULK COLLECT INTO nt_comisscharges;

        CLOSE cr_init_comisscharge;

        OPEN cr_oper;

        FETCH cr_oper
            BULK COLLECT INTO nt_oper;

        CLOSE cr_oper;

        -- KS Адаптация патч 30 05.09.2011 co2029_2030.sql
        OPEN cr_init_voopkind;

        FETCH cr_init_voopkind
            BULK COLLECT INTO nt_voopkind;

        CLOSE cr_init_voopkind;

        -- KS Адаптация патч 30 05.09.2011 co2029_2030.sql
        OPEN cr_init_country;

        FETCH cr_init_country
            BULK COLLECT INTO nt_country;

        CLOSE cr_init_country;
    END;

    FUNCTION get_our_bank_params (p_department IN NUMBER)
        RETURN our_bank_param_rec IS
        v_curdate                                    DATE := usr_common.c_nulldate;
    BEGIN
        FOR i IN nt_our_bank_param.FIRST .. nt_our_bank_param.LAST LOOP
            IF nt_our_bank_param (i).code = p_department THEN
                RETURN nt_our_bank_param (i);
                EXIT;
            END IF;
        END LOOP;

        RETURN NULL;
    END;

    FUNCTION get_vocodeid (code IN VARCHAR2, err_text IN OUT NOCOPY VARCHAR2)
        RETURN NUMBER IS
    BEGIN
        FOR i IN nt_vocode.FIRST .. nt_vocode.LAST LOOP
            IF nt_vocode (i).code = code THEN
                RETURN nt_vocode (i).id;
            END IF;
        END LOOP;

        make_error_text (c_err_vocode_notfound, err_text, code);
        RETURN 0;
    END;

    FUNCTION get_comisscharges (code IN VARCHAR2, err_text IN OUT NOCOPY VARCHAR2)
        RETURN NUMBER IS
    BEGIN
        FOR i IN nt_comisscharges.FIRST .. nt_comisscharges.LAST LOOP
            IF nt_comisscharges (i).code = code THEN
                RETURN nt_comisscharges (i).id;
            END IF;
        END LOOP;

        make_error_text (c_err_comisscharges_notfound, err_text, code);
        RETURN 0;
    END;



    -- функция определяет фин. инструмент
    FUNCTION get_fiid (acc IN VARCHAR2, err_text IN OUT NOCOPY VARCHAR2, iso_cur IN VARCHAR2 DEFAULT pm_common.rsb_empty_string)
        RETURN NUMBER IS
        v_fiid                                       NUMBER;
    BEGIN
        IF iso_cur <> pm_common.rsb_empty_string THEN
            v_fiid     := usr_common.get_fiid ('12345' || iso_cur);

            IF v_fiid = -1 THEN
                --'Не определена валюта %p1'
                make_error_text (c_err_iso_notfound, err_text, iso_cur);
                RETURN -1;
            ELSE
                RETURN v_fiid;
            END IF;
        ELSE
            v_fiid     := usr_common.get_fiid (acc);

            IF v_fiid = -1 THEN
                --'Не определена валюта по счету %p1'
                make_error_text (c_err_fiid_notfound, err_text, acc);
                RETURN -1;
            ELSE
                RETURN v_fiid;
            END IF;
        END IF;
    END;

    FUNCTION isvalidoper (                                                                                               -- KS 15.04.2011 Проверим операциониста
                          oper IN VARCHAR2)
        RETURN BOOLEAN IS
    BEGIN
        FOR i IN nt_oper.FIRST .. nt_oper.LAST LOOP
            IF nt_oper (i).t_oper = oper THEN
                RETURN TRUE;
            END IF;
        END LOOP;

        -- если операционист не найден - переинициализируем курсор
        -- таким образом, если посреди рабочего дня появиться новый операционист - проблем не будет
        -- а вот если операциониста закроют, то под ним всё равно можно работать, пока не введут нового
        OPEN cr_oper;

        FETCH cr_oper
            BULK COLLECT INTO nt_oper;

        CLOSE cr_oper;

        FOR i IN nt_oper.FIRST .. nt_oper.LAST LOOP
            IF nt_oper (i).t_oper = oper THEN
                RETURN TRUE;
            END IF;
        END LOOP;

        RETURN FALSE;
    END;

    PROCEDURE parse_cash_symbols (doc IN OUT NOCOPY main_doc_rec) IS
        --функция разбирает строку кассовых симоволов и их сумм
        --заданной в формате символ:сумма;симол:сумма...
        v_sum                                        VARCHAR2 (16);
        v_symb                                       VARCHAR2 (2);
        i                                            PLS_INTEGER := 0;
        j                                            PLS_INTEGER := 0;
        c                                            CHAR (1);
        v_is_symb                                    BOOLEAN := TRUE;
        v_symbol                                     VARCHAR2 (100);
        v_total_sum                                  NUMBER := 0;
        v_inc                                        NUMBER := 1;

        FUNCTION get_cash_symb_type (p_symb VARCHAR2)
            RETURN NUMBER IS
        --вспомогательная функция определяет тип кассового симола
        BEGIN
            FOR i IN nt_cash_symbs.FIRST .. nt_cash_symbs.LAST LOOP
                IF nt_cash_symbs (i).symbol = p_symb THEN
                    RETURN nt_cash_symbs (i).symb_type;
                END IF;
            END LOOP;

            RETURN NULL;
        END;

    BEGIN
        v_symbol     := doc.cash_symbs;
        --для исключения ошибки преобразования varchar2->number
        v_symbol     := REPLACE (v_symbol, '.', tp_glob.nls_num_delim);
        v_symbol     := REPLACE (v_symbol, ',', tp_glob.nls_num_delim);
        v_symbol     := REPLACE (v_symbol, ' ');

        WHILE i <= LENGTH (v_symbol) LOOP
            i     := i + 1;
            c     := SUBSTR (v_symbol, i, 1);

            IF c NOT IN (';', ':') THEN
                IF v_is_symb THEN
                    v_symb     := v_symb || c;
                ELSE
                    v_sum     := v_sum || c;
                END IF;
            ELSIF c = ':' THEN
                doc.cash_symbols_nt.EXTEND (1);
                j                                       := j + 1;
                v_is_symb                               := FALSE;
                doc.cash_symbols_nt (j).cash_symbol     := v_symb;
                doc.cash_symbols_nt (j).symb_type       := get_cash_symb_type (' ' || v_symb);
                v_symb                                  := '';
            END IF;

            IF c = ';' OR i = LENGTH (v_symbol) THEN
                v_is_symb                            := TRUE;
                doc.cash_symbols_nt (j).cash_sum     := TO_NUMBER (v_sum);

                IF doc.cash_symbols_nt (j).symb_type <> 3 THEN
                    v_total_sum     := v_total_sum + doc.cash_symbols_nt (j).cash_sum;
                ELSE
                    --для забалансовых символов разноски не бывает
                    v_total_sum     := doc.debet_sum;
                END IF;

                v_sum                                := '';
            END IF;
        END LOOP;

        IF doc.doc_kind = c_dockind_cash_inout THEN
            v_inc     := 2;                                                --для подкрепления нужно поделить сумму на 2 т.к. оба символа указаны на сумму ордера
        END IF;

        --проверяем сумму по платежу и символам
        --раздельно по дебету и кредиту для случая с мультивалютками
        IF doc.cash_symbols_nt.COUNT > 0 THEN
            IF INSTR (doc.payer_pi_rec.type_account, 'А') > 0 AND v_total_sum / v_inc <> doc.debet_sum AND doc.payer_pi_rec.fiid = 0 THEN
                --не совпадает сумма по символам с суммой документа
                make_error_text (c_err_cash_sum_notcont, doc.tech_parm_rec.ERROR_TEXT);
            ELSIF INSTR (doc.receiver_pi_rec.type_account, 'А') > 0 AND v_total_sum / v_inc <> doc.kredit_sum AND doc.receiver_pi_rec.fiid = 0 THEN
                --не совпадает сумма по символам с суммой документа
                make_error_text (c_err_cash_sum_notcont, doc.tech_parm_rec.ERROR_TEXT);
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            make_error_text ('ошибка при разборе кассовых символов: ' || SQLERRM, doc.tech_parm_rec.ERROR_TEXT);
    END;

    FUNCTION write_log (doc IN main_doc_rec)
        RETURN PLS_INTEGER IS
    BEGIN
        INSERT INTO usr_payments_log (pack_id,
                                      dockind,
                                      paymentid,
                                      ndoc,
                                      payeracc,
                                      receiveracc,
                                      amount,
                                      ground,
                                      oper,
                                      date_doc,
                                      ERROR_TEXT)
             VALUES (doc.tech_parm_rec.pack_id,
                     doc.doc_kind,
                     doc.payment_id,
                     doc.num_doc,
                     doc.payer_pi_rec.account,
                     doc.receiver_pi_rec.account,
                     doc.debet_sum,
                     doc.ground,
                     doc.oper,
                     doc.doc_date,
                     doc.tech_parm_rec.ERROR_TEXT);

        RETURN c_log_success;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            INSERT INTO usr_payments_log (pack_id,
                                          dockind,
                                          paymentid,
                                          ndoc,
                                          payeracc,
                                          receiveracc,
                                          amount,
                                          ground,
                                          oper,
                                          date_doc,
                                          ERROR_TEXT)
                 VALUES (doc.tech_parm_rec.pack_id,
                         doc.doc_kind,
                         doc.payment_id,
                         doc.num_doc,
                         doc.payer_pi_rec.account,
                         doc.receiver_pi_rec.account,
                         doc.debet_sum,
                         SUBSTR (doc.ground, 1, 550) || ' дубль:' || SYSTIMESTAMP,
                         doc.oper,
                         doc.doc_date,
                         doc.tech_parm_rec.ERROR_TEXT);

            RETURN c_log_doc_exists;
    END;

    PROCEDURE complete_params (doc IN OUT NOCOPY main_doc_rec)                                       --производятся дозаполнение необязательных полей и проверки
                                                              IS
        our_bank_param                               our_bank_param_rec;
        v_found_corschem                             BOOLEAN := FALSE;

        nt_pay_acc                                   client_param_nt := client_param_nt ();
        nt_rec_acc                                   client_param_nt := client_param_nt ();


        PROCEDURE check_outer_params (pm                                      IN OUT NOCOPY pay_instr_rec,
                                      direction                                             VARCHAR2,
                                      err_out                                 IN OUT NOCOPY VARCHAR2,
                                      dockind                                 IN            NUMBER) IS
            lv_tmpbuf                                    VARCHAR2 (512);
            lv_bnkname_set                               BOOLEAN;
        BEGIN
            --внешний платеж, все параметры плат. инструкции должны быть заполнены
            IF     pm.bank_code = pm_common.rsb_empty_string
               AND dockind NOT IN
                       (c_dockind_client_paym_val, c_dockind_bank_paym_val, c_dockind_client_paym_s, c_dockind_client_paym_b, c_dockind_client_paym_k) THEN
                --'Не задан БИК %p1 для внешнего платежа'
                make_error_text (c_err_bic_notfound, err_out, direction);
            ELSIF pm.bank_code <> pm_common.rsb_empty_string THEN
                OPEN cr_get_bank_info (pm.bank_code);

                IF pm.coracc = pm_common.rsb_empty_string THEN
                    IF pm.bank_name = pm_common.rsb_empty_string THEN
                        lv_bnkname_set     := FALSE;

                        FETCH cr_get_bank_info
                            INTO pm.bank_id, pm.bank_name, pm.coracc, pm.bank_place_name, pm.bank_codekind, pm.bank_codename;
                    ELSE
                        lv_bnkname_set     := TRUE;

                        FETCH cr_get_bank_info
                            INTO pm.bank_id, lv_tmpbuf, pm.coracc, lv_tmpbuf, pm.bank_codekind, pm.bank_codename;
                    END IF;
                ELSE
                    IF pm.bank_name = pm_common.rsb_empty_string THEN
                        lv_bnkname_set     := FALSE;

                        FETCH cr_get_bank_info
                            INTO pm.bank_id, pm.bank_name, lv_tmpbuf, pm.bank_place_name, pm.bank_codekind, pm.bank_codename;
                    ELSE
                        lv_bnkname_set     := TRUE;

                        FETCH cr_get_bank_info
                            INTO pm.bank_id, lv_tmpbuf, lv_tmpbuf, lv_tmpbuf, pm.bank_codekind, pm.bank_codename;
                    END IF;
                END IF;

                CLOSE cr_get_bank_info;

                --наименование банка должно быть с местонахождением
                IF TRIM (REPLACE (pm.bank_place_name, pm_common.rsb_empty_string, '')) IS NOT NULL AND NOT lv_bnkname_set THEN
                    pm.bank_name     := pm.bank_name || ' ' || pm.bank_place_name;
                END IF;

                IF pm.bank_id = 0 THEN
                    --'Банк %p1 не найден по БИКу %p2';
                    IF NOT check_rules.skip_bic THEN
                        make_error_text (c_err_bank_notfound,
                                         err_out,
                                         direction,
                                         pm.bank_code);
                    END IF;
                END IF;
            END IF;

            IF     pm.client_name IS NULL
               AND dockind NOT IN
                       (c_dockind_client_paym_val, c_dockind_bank_paym_val, c_dockind_client_paym_b, c_dockind_client_paym_s, c_dockind_client_paym_k) THEN
                --'Не задано наименование %p1 для внешнего платежа'
                make_error_text (c_err_name_notfound, err_out, direction);
            END IF;

            IF pm.inn IS NULL THEN
                NULL;
            --'Не задан ИНН %p1 для внешнего платежа'
            --Пока не считаем ошибкой
            --make_error_text (c_err_inn_notfound, err_out, direction);
            END IF;


            IF pm.med_bank_code <> pm_common.rsb_empty_string THEN
                OPEN cr_get_bank_info (pm.med_bank_code);

                IF pm.med_bank_name = pm_common.rsb_empty_string THEN
                    lv_bnkname_set     := FALSE;

                    FETCH cr_get_bank_info
                        INTO lv_tmpbuf, pm.med_bank_name, lv_tmpbuf, pm.med_bank_place_name, pm.med_bank_codekind, lv_tmpbuf;
                ELSE
                    lv_bnkname_set     := TRUE;

                    FETCH cr_get_bank_info
                        INTO lv_tmpbuf, lv_tmpbuf, lv_tmpbuf, lv_tmpbuf, pm.med_bank_codekind, lv_tmpbuf;
                END IF;

                CLOSE cr_get_bank_info;

                IF TRIM (REPLACE (pm.med_bank_place_name, pm_common.rsb_empty_string, '')) IS NOT NULL AND NOT lv_bnkname_set THEN
                    pm.med_bank_name     := pm.med_bank_name || ' ' || pm.med_bank_place_name;
                END IF;
            END IF;
        END;

        PROCEDURE check_inner_params (pm                                      IN OUT NOCOPY pay_instr_rec, --полученные реквизиты клиента из входных параметров ,
                                      param                                                 client_param_rec, --реквизиты клиента в БД, определнные по его счету,
                                      direction                                             VARCHAR2,
                                      err_out                                 IN OUT NOCOPY VARCHAR2) IS
            FUNCTION check_inn (inn_our VARCHAR2, inn_outer VARCHAR2)
                RETURN BOOLEAN IS
                lv_inn                                       VARCHAR2 (32);
                lv_kpp                                       VARCHAR2 (32);
            BEGIN
                IF inn_our = pm_common.rsb_empty_string AND inn_outer IS NULL THEN
                    --если ИНН и КПП нет ни в платеже ни у клиента
                    RETURN TRUE;
                END IF;

                IF INSTR (inn_our, '/') > 0 THEN                                                                                        --КПП клиента существует
                    lv_inn     := SUBSTR (inn_our, 1, INSTR (inn_our, '/') - 1);
                    lv_kpp     := SUBSTR (inn_our, INSTR (inn_our, '/', 1) + 1);
                ELSE
                    lv_inn     := inn_our;
                    lv_kpp     := NULL;
                END IF;

                IF (INSTR (inn_outer, '/') > 0 AND lv_kpp IS NOT NULL) THEN
                    --если КПП задан в платеже и существует у клиента, то проверяется пара ИНН+КПП
                    IF SUBSTR (inn_outer, 1, INSTR (inn_outer, '/') - 1) = lv_inn             /*and substr (inn_outer, instr (inn_outer, '/', 1) + 1) = lv_kpp*/
                                                                                  --проеверяем только ИНН
                    THEN
                        RETURN TRUE;
                    END IF;
                ELSIF INSTR (inn_outer, '/') > 0 THEN
                    --если КПП задан в платеже но отсутствует у клиента, то проверяется только ИНН
                    IF SUBSTR (inn_outer, 1, INSTR (inn_outer, '/') - 1) = lv_inn THEN
                        RETURN TRUE;
                    END IF;
                ELSE
                    --если в платеже указан только ИНН, то КПП клиента не проверяется
                    IF inn_outer = lv_inn THEN
                        RETURN TRUE;
                    END IF;
                END IF;

                RETURN FALSE;
            END;

        BEGIN
            IF (direction = c_str_receiver AND NOT check_rules.skip_recname_match) OR (direction = c_str_payer AND NOT check_rules.skip_payname_match) THEN
                IF pm.client_name IS NOT NULL AND UPPER (pm.client_name) <> UPPER (param.name) THEN
                    --'Наименование %p1 не совпадает с наименованием в БД'
                    make_error_text (c_err_name_mismatch, doc.tech_parm_rec.ERROR_TEXT, direction);
                END IF;
            END IF;

            IF direction = c_str_receiver AND NOT check_rules.skip_rec_inn_fill AND pm.inn IS NOT NULL THEN
                IF NOT check_inn (param.inn, pm.inn) THEN
                    --'ИНН %p1 не совпадает с ИНН в БД'
                    make_error_text (c_err_inn_mismatch, doc.tech_parm_rec.ERROR_TEXT, direction);
                END IF;
            ELSIF direction = c_str_payer AND NOT check_rules.skip_pay_inn_fill AND pm.inn IS NOT NULL THEN
                IF NOT check_inn (param.inn, pm.inn) THEN
                    --'ИНН %p1 не совпадает с ИНН в БД'
                    make_error_text (c_err_inn_mismatch, doc.tech_parm_rec.ERROR_TEXT, direction);
                END IF;
            END IF;
        END;

        PROCEDURE check_main_param (doc IN OUT NOCOPY main_doc_rec, param client_param_rec)             --производится инициализация основных параметров платежа
                                                                                           IS
            lv_found_origin                              BOOLEAN := FALSE;
            lv_temp_dockind                              NUMBER;
        BEGIN
            --устанавливаются глобальные переменные для работы функций операций
            --rsbsessiondata.m_curdate := our_bank_param.curdate;
            rsbsessiondata.m_ourbank     := our_bank_param.party_id;
            rsbsessiondata.m_oper        := doc.oper;

            --pm_common.m_curdate := our_bank_param.curdate;



            IF our_bank_param.code IS NULL THEN
                --'Филиал для платежа не определен'
                make_error_text (c_err_department_not_found, doc.tech_parm_rec.ERROR_TEXT);
            ELSE
                doc.value_date               := NVL (doc.value_date, our_bank_param.curdate);
                doc.transfer_date            := NVL (doc.transfer_date, doc.value_date);
                doc.doc_date                 := NVL (doc.doc_date, our_bank_param.curdate);
                doc.chapter                  := NVL (doc.chapter, param.chapter);
                doc.oper                     := NVL (doc.oper, param.oper);

                rsbsessiondata.m_curdate     := doc.value_date;

                -- KS Адаптация патч 30 04.07.2011
                --pm_common.m_curdate := doc.value_date;



                IF doc.doc_kind IN (c_dockind_cash_in, c_dockind_cash_out, c_dockind_cash_inout, c_dockind_client_cash_in, c_dockind_client_cash_out) THEN
                    lv_temp_dockind     := 400;
                ELSIF doc.doc_kind IN (c_dockind_client_paym, c_dockind_client_order) THEN
                    lv_temp_dockind     := 201;
                ELSIF doc.doc_kind IN (c_dockind_client_paym_b, c_dockind_client_paym_k, c_dockind_client_paym_s) THEN
                    lv_temp_dockind     := 200;
                ELSE
                    lv_temp_dockind     := doc.doc_kind;
                END IF;

                --проверки
                FOR i IN nt_docs_origin.FIRST .. nt_docs_origin.LAST LOOP
                    IF nt_docs_origin (i).doc_kind = lv_temp_dockind AND nt_docs_origin (i).origin = doc.origin THEN
                        lv_found_origin     := TRUE;
                        EXIT;
                    END IF;
                END LOOP;

                IF NOT lv_found_origin THEN
                    --вид происхождения задан неверно
                    make_error_text (c_err_origin_mismatch, doc.tech_parm_rec.ERROR_TEXT);
                END IF;

                IF doc.doc_kind = c_dockind_client_order THEN
                    --проверки для требований
                    IF doc.accept_term = 0                                                                                                          --с акцептом
                                          THEN
                        IF doc.accept_date = usr_common.c_nulldate THEN
                            --не задана дата окончания акцепта
                            make_error_text (c_err_date_order_notset, doc.tech_parm_rec.ERROR_TEXT);
                        END IF;

                        IF doc.accept_period = 0 THEN
                            --не задан период акцепта
                            make_error_text (c_err_accept_per_notset, doc.tech_parm_rec.ERROR_TEXT);
                        END IF;
                    ELSIF doc.accept_term = 1 THEN
                        --без акцепта
                        IF doc.pay_condition = pm_common.rsb_empty_string THEN
                            --не заданы условия оплаты
                            make_error_text (c_err_pay_condition_notset, doc.tech_parm_rec.ERROR_TEXT);
                        END IF;
                    ELSE
                        --неверный вид акцепта
                        make_error_text (c_err_acceptterm_incorrect, doc.tech_parm_rec.ERROR_TEXT);
                    END IF;
                END IF;

                IF doc.oper != param.oper THEN
                    IF doc.tech_parm_rec.is_debet THEN
                        NULL;
                    --'Операционист %p1 не является владельцем счета %p2'
                    /*make_error_text (c_err_oper_incorrect, doc.tech_parm_rec.error_text, doc.oper, doc.payer_pi_rec.account);
                 else
                    make_error_text (c_err_oper_incorrect, doc.tech_parm_rec.error_text, doc.oper, doc.receiver_pi_rec.account);
                    */
                    END IF;
                END IF;

                IF doc.department != param.department AND doc.department != param.vsp THEN
                    IF doc.tech_parm_rec.is_debet THEN
                        --'Счет %p1 не принадлежит филиалу'
                        make_error_text (c_err_department_mismatch, doc.tech_parm_rec.ERROR_TEXT, doc.payer_pi_rec.account);
                    ELSE
                        make_error_text (c_err_department_mismatch, doc.tech_parm_rec.ERROR_TEXT, doc.receiver_pi_rec.account);
                    END IF;
                END IF;

                IF doc.doc_cur_iso <> pm_common.rsb_empty_string THEN
                    doc.doc_cur_fiid     := get_fiid (NULL, doc.tech_parm_rec.ERROR_TEXT, doc.doc_cur_iso);
                ELSE
                    doc.doc_cur_fiid     := doc.payer_pi_rec.fiid;
                END IF;

                IF doc.comiss_acc <> pm_common.rsb_empty_string THEN
                    doc.comiss_fiid     := get_fiid (doc.comiss_acc, doc.tech_parm_rec.ERROR_TEXT);
                END IF;

                IF doc.vo_code <> pm_common.rsb_empty_string THEN
                    doc.vo_codeid     := get_vocodeid (doc.vo_code, doc.tech_parm_rec.ERROR_TEXT);
                END IF;
            END IF;

            IF doc.transfer_date < doc.value_date THEN
                make_error_text (c_err_transfdate_invalid, doc.tech_parm_rec.ERROR_TEXT);
            END IF;
        END;

        PROCEDURE find_corschem (doc IN OUT NOCOPY main_doc_rec) IS
            lv_codekind                                  NUMBER := ptck_bic;
        BEGIN
            IF doc.doc_kind IN (c_dockind_client_paym_val, c_dockind_bank_paym_val, c_dockind_client_paym_k, c_dockind_client_paym_s, c_dockind_client_paym_b) THEN
                lv_codekind     := ptck_swift;
            END IF;
            
            --внешний платеж
            IF doc.corschem = -1 THEN 
                doc.corrpos     := pm_common.pm_corrpos_type_user; -- zip_z. C-16618

                --если задан код клиринга сначала ищется схема схему по нему, если схема не найдена, ищется по БИКу
                IF doc.tech_parm_rec.is_our_payer THEN
                    OPEN cr_find_corschem (get_parent_department_code (doc.department), doc.doc_cur_fiid, doc.receiver_pi_rec.bank_id, doc.pack);

                    FETCH cr_find_corschem INTO doc.corschem;

                    CLOSE cr_find_corschem;
                ELSIF doc.tech_parm_rec.is_our_receiver THEN
                    OPEN cr_find_corschem (get_parent_department_code (doc.department), doc.doc_cur_fiid, doc.payer_pi_rec.bank_id, doc.pack);

                    FETCH cr_find_corschem INTO doc.corschem;

                    CLOSE cr_find_corschem;
                ELSE 
                    make_error_text (c_err_transit, doc.tech_parm_rec.ERROR_TEXT);
                    doc.corschem     := -2;                                                                                               -- Ошибка - транзитные
                END IF;

                -- KS 11.02.2011 I-00008404 Если схема не найдена, то ищем схему по валюте счета плательщика
                IF (doc.corschem = -1) AND (doc.doc_cur_fiid <> doc.payer_pi_rec.fiid) THEN
                    --Teleshova
                    -- doc.doc_cur_fiid := doc.payer_pi_rec.fiid;
                    IF doc.tech_parm_rec.is_our_payer THEN
                        OPEN cr_find_corschem (get_parent_department_code (doc.department), doc.payer_pi_rec.fiid, doc.receiver_pi_rec.bank_id, doc.pack);

                        FETCH cr_find_corschem INTO doc.corschem;
                    ELSIF doc.tech_parm_rec.is_our_receiver THEN
                        OPEN cr_find_corschem (get_parent_department_code (doc.department), doc.payer_pi_rec.fiid, doc.payer_pi_rec.bank_id, doc.pack);

                        FETCH cr_find_corschem INTO doc.corschem;
                    END IF;

                    CLOSE cr_find_corschem;
                END IF;
                
                IF doc.corschem = -1 THEN 
                    --ошибка при автопоиске корсхемы для внешнего платежа:схема не найдена'
                    IF doc.origin = 2100 THEN --Gurin S. 09.08.2013 C-22197
                        IF check_rules.skip_payacc_exists THEN        
                            OPEN cr_find_corschem (get_parent_department_code (doc.department), doc.receiver_pi_rec.fiid, doc.receiver_pi_rec.bank_id, doc.pack);

                            FETCH cr_find_corschem INTO doc.corschem;
                        
                            CLOSE cr_find_corschem;
                        ELSIF check_rules.skip_bic THEN
                            doc.corschem := -1;
                        END IF;                            
                    ELSE
                        make_error_text (c_err_corschem_notaufound, doc.tech_parm_rec.ERROR_TEXT);
                    END IF; 
                END IF;
            ELSE
                doc.corrpos     := 1;                                                                                      --позиционирование = пользовательское

                FOR i IN nt_corschemes.FIRST .. nt_corschemes.LAST LOOP
                    IF nt_corschemes (i).num = doc.corschem THEN
                        v_found_corschem     := TRUE;

                        /*if doc.tech_parm_rec.is_our_payer
                        then
                           doc.carry_nt (1).receiver_account := nt_corschemes (i).account;
                        else
                           doc.carry_nt (1).payer_account := nt_corschemes (i).account;
                        end if;*/

                        EXIT;
                    END IF;
                END LOOP;

                IF NOT v_found_corschem THEN  
                    --не найдена корсхема с номером %p1
                    make_error_text (c_err_corschem_notfound, doc.tech_parm_rec.ERROR_TEXT, doc.corschem);
                END IF;
            END IF;
        END;

        PROCEDURE fill_name (p_dockind NUMBER, pm client_param_rec, pay_instr IN OUT pay_instr_rec) IS
            --функция заполняет наименование плательщика/получателя и банков по слeд. правилам
            -- для плательщика/получателя:
            --   1-полное наимен.клиента;
            --   2-наимен.счета;
            --для остальных вариантов возвращается наименование клиента
            -- для банков
            --!!!по наименованию банка пока приостановлено

            lv_fillname_val                              NUMBER;
            lv_fillbank_val                              NUMBER;
        BEGIN
            --если наименования уже заполнены - не переопределяются
            IF pay_instr.client_name IS NOT NULL THEN
                RETURN;
            END IF;

            /*if pay_instr.bank_name is not null
            then
               return;
            end if;*/

            FOR i IN nt_dockind_param.FIRST .. nt_dockind_param.LAST LOOP
                IF nt_dockind_param (i).dockind = p_dockind THEN
                    lv_fillname_val     := nt_dockind_param (i).fillname_value;
                    EXIT;
                END IF;
            END LOOP;

            IF lv_fillname_val = 1 THEN
                pay_instr.client_name     := pm.name;
            ELSIF lv_fillname_val = 2 THEN
                pay_instr.client_name     := pm.nameaccount;
            ELSE
                pay_instr.client_name     := pm.name;
            END IF;
        END;

        FUNCTION isexternal (doc main_doc_rec)
            RETURN BOOLEAN IS
        BEGIN
            IF NOT doc.tech_parm_rec.is_our_payer OR NOT doc.tech_parm_rec.is_our_receiver THEN
                RETURN TRUE;
            ELSE
                RETURN FALSE;
            END IF;
        END;

    BEGIN
        doc.tech_parm_rec.ERROR_TEXT     := usr_common.c_err_success;


        IF doc.doc_kind = c_dockind_bank_order THEN
            doc.tech_parm_rec.is_debet     := FALSE;
        ELSE
            doc.tech_parm_rec.is_debet     := TRUE;
        END IF;

        IF doc.num_doc IS NULL THEN
            --'не задан номер документа';
            make_error_text (c_err_numdoc_notset, doc.tech_parm_rec.ERROR_TEXT);
        END IF;

        IF     doc.payer_pi_rec.account IS NOT NULL
           AND doc.receiver_pi_rec.account IS NOT NULL
           AND NOT check_rules.skip_recacc_exists
           AND NOT check_rules.skip_payacc_exists
           AND usr_common.get_chapter (doc.payer_pi_rec.account) <> usr_common.get_chapter (doc.receiver_pi_rec.account)
           AND doc.payer_pi_rec.fiid = 0 THEN
            --не совпадает глава учета для счетов
            make_error_text (c_err_chapter_mismatch, doc.tech_parm_rec.ERROR_TEXT);
        --raise e_error_check_payment;
        END IF;


        IF check_rules.skip_payacc_exists AND doc.doc_kind != c_dockind_multycarry THEN
            --в случае отсутсвия одного из счетов, валюту опеределяем по существующему
            --но для мультивалюток пытаемся определить для обоих
            doc.payer_pi_rec.fiid     := get_fiid (doc.receiver_pi_rec.account, doc.tech_parm_rec.ERROR_TEXT, doc.receiver_pi_rec.cur_iso);
        ELSE
            doc.payer_pi_rec.fiid     := get_fiid (doc.payer_pi_rec.account, doc.tech_parm_rec.ERROR_TEXT);
        END IF;

        IF check_rules.skip_recacc_exists AND doc.doc_kind != c_dockind_multycarry THEN
            --в случае отсутсвия одного из счетов, валюту опеределяем по существующему
            --но для мультивалюток пытаемся определить для обоих
            doc.receiver_pi_rec.fiid     := get_fiid (doc.payer_pi_rec.account, doc.tech_parm_rec.ERROR_TEXT);
        ELSE
            doc.receiver_pi_rec.fiid     := get_fiid (doc.receiver_pi_rec.account, doc.tech_parm_rec.ERROR_TEXT, doc.receiver_pi_rec.cur_iso);
        END IF;

        doc.chapter                      := usr_common.get_chapter (NVL (doc.payer_pi_rec.account, doc.receiver_pi_rec.account));


        -- KS 27.11.2013 Адаптация под 31ю сборку. Начало
        --IF doc.payer_pi_rec.fiid = 0 THEN
            OPEN cr_get_account/*_rub*/ (doc.payer_pi_rec.account, doc.chapter, doc.payer_pi_rec.fiid);

            FETCH cr_get_account/*_rub*/
                BULK COLLECT INTO nt_pay_acc;

            CLOSE cr_get_account/*_rub*/;
        /*ELSIF doc.payer_pi_rec.fiid != 0 THEN
            OPEN cr_get_account_val (doc.payer_pi_rec.account, doc.chapter, doc.payer_pi_rec.fiid);

            FETCH cr_get_account_val
                BULK COLLECT INTO nt_pay_acc;

            CLOSE cr_get_account_val;
        END IF;*/

        --IF doc.receiver_pi_rec.fiid = 0 THEN
            OPEN cr_get_account/*_rub*/ (doc.receiver_pi_rec.account, doc.chapter, doc.receiver_pi_rec.fiid);

            FETCH cr_get_account/*_rub*/
                BULK COLLECT INTO nt_rec_acc;

            CLOSE cr_get_account/*_rub*/;
        /*ELSIF doc.receiver_pi_rec.fiid != 0 THEN
            OPEN cr_get_account_val (doc.receiver_pi_rec.account, doc.chapter, doc.receiver_pi_rec.fiid);

            FETCH cr_get_account_val
                BULK COLLECT INTO nt_rec_acc;

            CLOSE cr_get_account_val;
        END IF;*/
        -- KS 27.11.2013 Адаптация под 31ю сборку. Окончание

        IF nt_pay_acc.EXISTS (1) AND nt_rec_acc.EXISTS (1) THEN
            nt_pay_acc.EXTEND (1);
            nt_pay_acc (2)      := nt_rec_acc (1);
            nt_client_param     := nt_pay_acc;
        ELSIF nt_pay_acc.EXISTS (1) THEN
            nt_client_param     := nt_pay_acc;
        ELSIF nt_rec_acc.EXISTS (1) THEN
            nt_client_param     := nt_rec_acc;
        END IF;



        IF nt_client_param.EXISTS (1) THEN
            -- определяется ВСП или филиал по первому счету если не задан
            doc.department     := NVL (doc.department, nt_client_param (1).vsp);
            -- определяются все параметры нашего филиала
            our_bank_param     := get_our_bank_params (get_parent_department_code (doc.department));
            


            IF doc.payer_pi_rec.account = doc.receiver_pi_rec.account THEN
                --если счета одинаковые, нужно дублировать ПИ
                nt_client_param.EXTEND (1);
                nt_client_param (2)     := nt_client_param (1);
            END IF;

            FOR i IN nt_client_param.FIRST .. nt_client_param.LAST LOOP
                -- рассматривается 3 варианта:
                -- 1. найдены параметры первой ПИ
                -- 2. найдены параметры второй ПИ
                -- 3. найдены параметры обоих ПИ
                IF     nt_client_param (i).account = doc.payer_pi_rec.account
                   --если счета одинаковые, то на второй итерации - переход на заполнение ПИ получателя
                   AND (doc.payer_pi_rec.account != doc.receiver_pi_rec.account OR i = 1)
                   --счет для внешнего платежа может совпадать со счетом в нашей БД, по этому дополнительно проверяется БИК
                   AND (   doc.payer_pi_rec.bank_code = pm_common.rsb_empty_string
                        OR doc.payer_pi_rec.bank_code IN (our_bank_param.bic_code, our_bank_param.swift_code, our_bank_param.klir_code)) THEN
                    --найдены параметры первой ПИ - плательщика

                    doc.tech_parm_rec.is_our_payer     := TRUE;


                    --дозаполнение основных параметров документа
                    IF i = 1 THEN
                        check_main_param (doc, nt_client_param (i));
                    END IF;

                    --дозаполнение платежной инструкции
                    --сначала проверки
                    check_inner_params (doc.payer_pi_rec,
                                        nt_client_param (i),
                                        c_str_payer,
                                        doc.tech_parm_rec.ERROR_TEXT);
                    --заполняется наименование плательщика согласно систмным правилам
                    fill_name (doc.doc_kind, nt_client_param (i), doc.payer_pi_rec);
                    doc.payer_pi_rec.type_account      := nt_client_param (i).type_account;
                    doc.payer_pi_rec.department        := nt_client_param (i).department;
                    doc.payer_pi_rec.vsp               := nt_client_param (i).vsp;

                    --если счет внутрибанковский и принадлежит ВСП, то плательщик - вышестоящий филиал
                    IF (nt_client_param (i).client_id = our_bank_param.party_id AND our_bank_param.party_id <> our_bank_param.parent_party_id) THEN
                        doc.payer_pi_rec.client_id     := our_bank_param.parent_party_id;
                    ELSE
                        doc.payer_pi_rec.client_id     := nt_client_param (i).client_id;
                    END IF;

                    --если сказано не заполнять ИНН в случае если не передан - не заполняется
                    IF NOT check_rules.skip_pay_inn_fill AND doc.payer_pi_rec.inn IS NULL THEN
                        doc.payer_pi_rec.inn     := nt_client_param (i).inn;
                    ELSIF doc.payer_pi_rec.inn IS NOT NULL THEN
                        doc.payer_pi_rec.inn     := doc.payer_pi_rec.inn;
                    END IF;

                    doc.payer_pi_rec.bank_code         := our_bank_param.bic_code;
                    doc.payer_pi_rec.bank_codekind     := ptck_bic;
                    doc.payer_pi_rec.bank_codename     := 'БИК';
                    doc.payer_pi_rec.coracc            := our_bank_param.coracc;
                    doc.payer_pi_rec.bank_id           := our_bank_param.parent_party_id;
                    doc.payer_pi_rec.bank_name         := our_bank_param.name;
                    doc.payer_pi_rec.department        := nt_client_param (i).department;
                    doc.payer_pi_rec.vsp               := nt_client_param (i).vsp;
                ELSIF     nt_client_param (i).account = doc.receiver_pi_rec.account
                      --счет для внешнего платежа может совпадать со счетом в нашей БД, по этому дополнительно проверяется БИК
                      AND (   doc.receiver_pi_rec.bank_code = pm_common.rsb_empty_string
                           OR doc.receiver_pi_rec.bank_code IN (our_bank_param.bic_code, our_bank_param.swift_code, our_bank_param.klir_code)) THEN
                    doc.tech_parm_rec.is_our_receiver     := TRUE;

                    --найдены параметры ПИ получателя
                    --дозаполнение основных параметров документа
                    IF i = 1 THEN
                        check_main_param (doc, nt_client_param (i));
                    END IF;

                    --дозаполнение платежной инструкции
                    check_inner_params (doc.receiver_pi_rec,
                                        nt_client_param (i),
                                        c_str_receiver,
                                        doc.tech_parm_rec.ERROR_TEXT);
                    --заполняется наименование получателя согласно систмным правилам
                    fill_name (doc.doc_kind, nt_client_param (i), doc.receiver_pi_rec);
                    doc.receiver_pi_rec.type_account      := nt_client_param (i).type_account;

                    --если счет получателя внутрибанковский и принадлежит ВСП, то получатель - вышестоящий филиал
                    IF (nt_client_param (i).client_id = our_bank_param.party_id AND our_bank_param.party_id <> our_bank_param.parent_party_id) THEN
                        doc.receiver_pi_rec.client_id     := our_bank_param.parent_party_id;
                    ELSE
                        doc.receiver_pi_rec.client_id     := nt_client_param (i).client_id;
                    END IF;

                    --если сказано не заполнять ИНН в случае если не передан - не заполняется
                    IF NOT check_rules.skip_rec_inn_fill AND doc.receiver_pi_rec.inn IS NULL THEN
                        doc.receiver_pi_rec.inn     := nt_client_param (i).inn;
                    ELSIF doc.receiver_pi_rec.inn IS NOT NULL THEN
                        doc.receiver_pi_rec.inn     := doc.receiver_pi_rec.inn;
                    END IF;

                    doc.receiver_pi_rec.bank_code         := our_bank_param.bic_code;
                    doc.receiver_pi_rec.bank_codekind     := ptck_bic;
                    doc.receiver_pi_rec.bank_codename     := 'БИК';
                    doc.receiver_pi_rec.coracc            := our_bank_param.coracc;
                    doc.receiver_pi_rec.bank_id           := our_bank_param.parent_party_id;
                    doc.receiver_pi_rec.bank_name         := our_bank_param.name;
                    doc.receiver_pi_rec.department        := nt_client_param (i).department;
                    doc.receiver_pi_rec.vsp               := nt_client_param (i).vsp;
                END IF;
            END LOOP;
        END IF;

        IF doc.doc_kind = c_dockind_external_in THEN                                                                                            -- KS 01.06.2011
            doc.payer_pi_rec.bank_codekind     := ptck_bic;
            doc.payer_pi_rec.bank_codename     := 'БИК';

            SELECT b.t_coracc, b.t_partyid, rsi_rsbparty.getfullbankname (b.t_partyid)
              INTO doc.payer_pi_rec.coracc, doc.payer_pi_rec.bank_id, doc.payer_pi_rec.bank_name
              FROM dobjcode_dbt t, dbankdprt_dbt b
             WHERE     (t.t_objecttype = pm_common.objtype_party AND t.t_codekind = pm_common.ptck_bic AND t.t_code = doc.payer_pi_rec.bank_code)
                   AND b.t_partyid = t.t_objectid
                   AND t.t_state = 0;                                                                                                           -- KS 14.11.2011
        END IF;

        --дозаполнение ПИ для случая остутствия одного из счетов
        IF doc.doc_kind IN
               (c_dockind_cash_in,
                c_dockind_client_cash_in,
                c_dockind_cash_out,
                c_dockind_client_cash_out,
                c_dockind_cash_inout,
                c_dockind_memorder,
                c_dockind_memorder_bank_order,                                                                                 -- KS 29.07.2011 Банковский ордер
                c_dockind_multycarry)       --если игнорируется проверка существования счета, считается что счет получателя внутренний для мемордеров и кассовых
                                      --для платежей - по умолчанию считается, что отсутствующий счет внешний
        THEN
            IF check_rules.skip_payacc_exists THEN
                doc.payer_pi_rec.bank_code         := our_bank_param.bic_code;
                doc.payer_pi_rec.bank_codekind     := ptck_bic;
                doc.payer_pi_rec.bank_codename     := 'БИК';
                doc.payer_pi_rec.coracc            := our_bank_param.coracc;
                doc.payer_pi_rec.bank_id           := our_bank_param.parent_party_id;
                doc.payer_pi_rec.bank_name         := our_bank_param.name;
                doc.tech_parm_rec.is_our_payer     := TRUE;
            ELSIF check_rules.skip_recacc_exists THEN
                doc.receiver_pi_rec.bank_code         := our_bank_param.bic_code;
                doc.receiver_pi_rec.bank_codekind     := ptck_bic;
                doc.receiver_pi_rec.bank_codename     := 'БИК';
                doc.receiver_pi_rec.coracc            := our_bank_param.coracc;
                doc.receiver_pi_rec.bank_id           := our_bank_param.parent_party_id;
                doc.receiver_pi_rec.bank_name         := our_bank_param.name;
                doc.tech_parm_rec.is_our_receiver     := TRUE;
            END IF;
        --Gurin S. 09.08.2013 C-22197
        ELSIF doc.doc_kind = c_dockind_client_paym AND doc.origin = 2100 THEN
            IF check_rules.skip_payacc_exists THEN
                doc.department := 1 ;
                doc.doc_cur_fiid   := get_fiid (doc.receiver_pi_rec.account, doc.tech_parm_rec.ERROR_TEXT, doc.receiver_pi_rec.cur_iso);
                our_bank_param     := get_our_bank_params (get_parent_department_code (doc.department));
                doc.payer_pi_rec.bank_code         := our_bank_param.bic_code;
                doc.payer_pi_rec.bank_codekind     := ptck_bic;
                doc.payer_pi_rec.bank_codename     := 'БИК';
                doc.payer_pi_rec.coracc            := our_bank_param.coracc;
                doc.payer_pi_rec.bank_id           := our_bank_param.parent_party_id;
                doc.payer_pi_rec.bank_name         := our_bank_param.name;
                doc.tech_parm_rec.is_our_payer     := TRUE;           
            ELSIF check_rules.skip_bic THEN 
                doc.receiver_pi_rec.bank_codekind     := ptck_bic;
                doc.receiver_pi_rec.bank_codename     := 'БИК';
            END IF;           
        ELSIF     NOT doc.tech_parm_rec.is_our_receiver
              AND doc.receiver_pi_rec.bank_code IN (our_bank_param.bic_code, our_bank_param.swift_code, our_bank_param.klir_code) THEN --если указан наш код считается что получатель - внутренний
            IF check_rules.skip_recacc_exists THEN
                doc.receiver_pi_rec.bank_code         := our_bank_param.bic_code;
                doc.receiver_pi_rec.bank_codekind     := ptck_bic;
                doc.receiver_pi_rec.bank_codename     := 'БИК';
                doc.receiver_pi_rec.coracc            := our_bank_param.coracc;
                doc.receiver_pi_rec.bank_id           := our_bank_param.parent_party_id;
                doc.receiver_pi_rec.bank_name         := our_bank_param.name;
                doc.tech_parm_rec.is_our_receiver     := TRUE;
            ELSE
                IF NOT check_rules.skip_recacc_exists_full THEN
                    make_error_text (c_err_acc_notfound,
                                     doc.tech_parm_rec.ERROR_TEXT,
                                     c_str_receiver,
                                     doc.receiver_pi_rec.account);
                END IF;
            END IF;
        END IF;

        --производятся проверки заполненности платежных инструкций
        IF doc.tech_parm_rec.is_debet THEN
            IF (NOT doc.tech_parm_rec.is_our_payer) AND (doc.doc_kind != c_dockind_external_in)                                                 -- KS 02.06.2011
                                                                                               THEN
                --'Счет %p1 %p2 не найден';
                IF NOT check_rules.skip_payacc_exists_full THEN
                    make_error_text (c_err_acc_notfound,
                                     doc.tech_parm_rec.ERROR_TEXT,
                                     c_str_payer,
                                     doc.payer_pi_rec.account);
                END IF;
            ELSIF NOT doc.tech_parm_rec.is_our_receiver THEN
                --проверка для внутренних документов
                IF doc.doc_kind IN
                       (c_dockind_cash_in,
                        c_dockind_client_cash_in,
                        c_dockind_cash_out,
                        c_dockind_client_cash_out,
                        c_dockind_cash_inout,
                        c_dockind_memorder,
                        c_dockind_memorder_bank_order,                                                                         -- KS 29.07.2011 Банковский ордер
                        c_dockind_multycarry) THEN
                    --'Счет %p1 %p2 не найден';
                    IF NOT check_rules.skip_recacc_exists_full THEN
                        make_error_text (c_err_acc_notfound,
                                         doc.tech_parm_rec.ERROR_TEXT,
                                         c_str_receiver,
                                         doc.receiver_pi_rec.account);
                    END IF;
                ELSE
                    check_outer_params (doc.receiver_pi_rec,
                                        c_str_receiver,
                                        doc.tech_parm_rec.ERROR_TEXT,
                                        doc.doc_kind);
                END IF;
            END IF;
        ELSE
            IF NOT doc.tech_parm_rec.is_our_receiver THEN
                --'Счет %p1 %p2 не найден';
                IF NOT check_rules.skip_recacc_exists_full THEN
                    make_error_text (c_err_acc_notfound,
                                     doc.tech_parm_rec.ERROR_TEXT,
                                     c_str_receiver,
                                     doc.receiver_pi_rec.account);
                END IF;
            ELSIF NOT doc.tech_parm_rec.is_our_payer THEN
                check_outer_params (doc.payer_pi_rec,
                                    c_str_payer,
                                    doc.tech_parm_rec.ERROR_TEXT,
                                    doc.doc_kind);
            END IF;
        END IF;

        IF check_rules.skip_payacc_exists THEN
            --в случае отсутсвия одного из счетов, валюту опеределяем по существующему
            doc.payer_pi_rec.fiid     := get_fiid (doc.receiver_pi_rec.account, doc.tech_parm_rec.ERROR_TEXT, doc.receiver_pi_rec.cur_iso);
        ELSE
            doc.payer_pi_rec.fiid     := get_fiid (doc.payer_pi_rec.account, doc.tech_parm_rec.ERROR_TEXT);
        END IF;

        IF check_rules.skip_recacc_exists THEN
            --в случае отсутсвия одного из счетов, валюту опеределяем по существующему
            doc.receiver_pi_rec.fiid     := get_fiid (doc.payer_pi_rec.account, doc.tech_parm_rec.ERROR_TEXT);
        ELSE
            doc.receiver_pi_rec.fiid     := get_fiid (doc.receiver_pi_rec.account, doc.tech_parm_rec.ERROR_TEXT, doc.receiver_pi_rec.cur_iso);
        END IF;


        IF     doc.payer_pi_rec.fiid <> doc.receiver_pi_rec.fiid
           AND doc.doc_kind NOT IN
                   (c_dockind_multycarry,
                    c_dockind_client_paym_val,
                    c_dockind_bank_paym_val,
                    c_dockind_client_paym_s,
                    c_dockind_client_paym_k,
                    c_dockind_client_paym_b) THEN
            --для заданного вида документа валюта счетов должна совпадать
            make_error_text (c_err_fiid_mismatch, doc.tech_parm_rec.ERROR_TEXT);
        END IF;

        IF doc.payer_pi_rec.department <> doc.receiver_pi_rec.department THEN
            --'не совпадает филиал счетов'
            make_error_text (c_err_dep_mismatch, doc.tech_parm_rec.ERROR_TEXT);
        END IF;

        --заполняются параметры проводки по платежу
        IF (doc.tech_parm_rec.run_operation AND doc.tech_parm_rec.make_carry_from_payment) OR NOT doc.tech_parm_rec.run_operation THEN
            IF doc.doc_kind <> c_dockind_multycarry AND NOT isexternal (doc) THEN
                IF NOT doc.carry_nt.EXISTS (1) THEN
                    --doc.carry_nt
                    doc.carry_nt.EXTEND (1);
                END IF;

                doc.carry_nt (1).autokey              := 0;
                doc.carry_nt (1).carrynum             := doc.carry_nt.COUNT;
                -- KS 10.12.2013 Адаптация под 31ю сборку 
                --doc.carry_nt (1).fiid                 := get_carry_fiid (doc.payer_pi_rec.account, doc.receiver_pi_rec.account);
                doc.carry_nt (1).fiid_payer           := usr_common.get_fiid (doc.payer_pi_rec.account);
                doc.carry_nt (1).fiid_receiver        := usr_common.get_fiid (doc.receiver_pi_rec.account);
                doc.carry_nt (1).chapter              := doc.chapter;
                --пока счета заполняются по документу, корсчет если надо будет установлен позднее
                doc.carry_nt (1).payer_account        := doc.payer_pi_rec.account;
                doc.carry_nt (1).receiver_account     := doc.receiver_pi_rec.account;
                -- KS 11.12.2012 Адаптация под 31ю сборку
                --doc.carry_nt (1).SUM                  := doc.debet_sum;
                if doc.carry_nt (1).fiid_payer=0 then
                  doc.carry_nt (1).SUM                := doc.debet_sum;
                elsif doc.carry_nt (1).fiid_receiver=0 then
                  doc.carry_nt (1).SUM                := doc.kredit_sum;
                else
                  -- ???
                  doc.carry_nt (1).SUM                := 0;
                end if;
                doc.carry_nt (1).sum_payer            := doc.debet_sum;
                doc.carry_nt (1).sum_receiver         := doc.kredit_sum;
                doc.carry_nt (1).date_carry           := doc.value_date;
                doc.carry_nt (1).oper                 := doc.oper;
                doc.carry_nt (1).pack                 := doc.pack;
                doc.carry_nt (1).num_doc              := doc.num_doc;
                doc.carry_nt (1).ground               := doc.ground;
                doc.carry_nt (1).department           := get_parent_department_code (doc.department);
                doc.carry_nt (1).vsp                  := doc.department;

                IF INSTR (doc.shifr, '/') = 0 THEN
                    doc.carry_nt (1).kind_oper     := ' 6';
                ELSE
                    doc.carry_nt (1).kind_oper     := SUBSTR (doc.shifr, INSTR (doc.shifr, '/') + 1);
                END IF;

                doc.carry_nt (1).shifr_oper           := NVL (SUBSTR (doc.shifr, 1, INSTR (doc.shifr, '/') - 1), doc.shifr);

                IF doc.doc_kind IN (c_dockind_cash_in, c_dockind_cash_out, c_dockind_cash_inout, c_dockind_client_cash_in, c_dockind_client_cash_out) THEN
                    doc.carry_nt (1).payer_account        := doc.receiver_pi_rec.account;
                    doc.carry_nt (1).receiver_account     := doc.payer_pi_rec.account;
                END IF;



                IF doc.tech_parm_rec.run_operation THEN
                    doc.carry_nt (1).error     := 'проводка ожидает выполнения';
                ELSE
                    doc.carry_nt (1).error     := 'проводка для отложенного документа';
                END IF;
            END IF;
        END IF;

        IF doc.tech_parm_rec.ERROR_TEXT = usr_common.c_err_success THEN
            --проверяется корсхема
            IF NOT doc.tech_parm_rec.is_our_receiver OR NOT doc.tech_parm_rec.is_our_payer THEN
               find_corschem (doc);
            END IF;

            IF    (    doc.doc_kind IN (c_dockind_cash_in, c_dockind_client_cash_in, c_dockind_cash_out, c_dockind_client_cash_out, c_dockind_cash_inout)
                   AND doc.payer_pi_rec.fiid = 0                                                                                  --для кассовых только в рублях
                   AND doc.chapter = 1                                                                                                              -- и глава А
                                      )
               --кроме кассовых ордеров, символа должны быть заданы и для мультивалюток и для мемордеров
               --если всречается рублевый счет кассы и счет кассы не является исключением, как 20208
               OR (    doc.doc_kind IN (c_dockind_multycarry, c_dockind_memorder, c_dockind_memorder_bank_order)               -- KS 29.07.2011 Банковский ордер
                   AND (   (INSTR (doc.payer_pi_rec.type_account, c_cash_doc_type) > 0 AND doc.payer_pi_rec.fiid = 0)
                        OR (INSTR (doc.receiver_pi_rec.type_account, c_cash_doc_type) > 0 AND doc.receiver_pi_rec.fiid = 0))
                   AND doc.payer_pi_rec.fiid = 0                                                                                  --для кассовых только в рублях
                   AND doc.chapter = 1                                                                                                              -- и глава А
                                      )
               OR (doc.cash_symbs IS NOT NULL                                                               --или символа явно заданы: скорее всего забалансовые
                                             ) THEN
                IF    (SUBSTR (doc.payer_pi_rec.account, 1, 5) != с_cash_acc_ex AND SUBSTR (doc.receiver_pi_rec.account, 1, 5) != с_cash_acc_ex)
                   OR doc.cash_symbs IS NOT NULL THEN
                    parse_cash_symbols (doc);

                    IF doc.cash_symbols_nt.COUNT = 0 THEN
                        --для кассового документа не заданы кассовые сиволы
                        make_error_text (c_err_cash_symb_not_set, doc.tech_parm_rec.ERROR_TEXT);
                    ELSE
                        FOR i IN doc.cash_symbols_nt.FIRST .. doc.cash_symbols_nt.LAST LOOP
                            IF doc.cash_symbols_nt (i).symb_type IS NULL THEN
                                --кассовый симол %p1 не найден в справочнике
                                make_error_text (c_err_cash_symb_notfound, doc.tech_parm_rec.ERROR_TEXT, doc.cash_symbols_nt (i).cash_symbol);
                            ELSIF doc.cash_symbols_nt (i).symb_type NOT IN (1, 3) AND doc.doc_kind IN (c_dockind_cash_in, c_dockind_client_cash_in) THEN
                                --кассовый симол %p1 не подходит для операции %p2
                                make_error_text (c_err_cash_symb_mismatch,
                                                 doc.tech_parm_rec.ERROR_TEXT,
                                                 doc.cash_symbols_nt (i).cash_symbol,
                                                 'приход в кассу');
                            ELSIF doc.cash_symbols_nt (i).symb_type NOT IN (2, 3) AND doc.doc_kind IN (c_dockind_cash_out, c_dockind_client_cash_out) THEN
                                --кассовый симол %p1 не подходит для операции %p2
                                make_error_text (c_err_cash_symb_mismatch,
                                                 doc.tech_parm_rec.ERROR_TEXT,
                                                 doc.cash_symbols_nt (i).cash_symbol,
                                                 'расход из кассы');
                            END IF;
                        END LOOP;
                    END IF;
                END IF;
            END IF;
        END IF;

        IF doc.tech_parm_rec.ERROR_TEXT = usr_common.c_err_success THEN
            --если все правильно то производятся финальные действия
            --определяется ID будущего документа и ID его операции
            SELECT dpmpaym_dbt_seq.NEXTVAL, doproper_dbt_seq.NEXTVAL
              INTO doc.payment_id, doc.operation_id
              FROM DUAL;

            IF doc.carry_nt.EXISTS (1) THEN
                doc.carry_nt (1).paymentid       := doc.payment_id;
                doc.carry_nt (1).operationid     := doc.operation_id;
            END IF;
        ELSE
            doc.tech_parm_rec.ERROR_TEXT      :=
                doc.tech_parm_rec.ERROR_TEXT || CHR (10) || 'документ # ' || doc.num_doc || ' на сумму ' || doc.debet_sum;
        END IF;
    EXCEPTION
        WHEN e_error_check_payment THEN
            NULL;
    END;

    PROCEDURE DUMP (doc main_doc_rec) IS
        dump_text                                    usr_debug_dump.dump_text%TYPE;
    BEGIN
        dump_text      :=
            dump_text || 'main_doc:' || CHR (10) || 'chapter:' || doc.chapter || ' oper:' || doc.oper || ' pack:' || doc.pack || ' num_operation:' || doc.
            num_operation || ' num_doc:' || doc.num_doc || ' debet_sum:' || doc.debet_sum || ' kredit_sum:' || doc.kredit_sum || ' ground:' || doc.ground ||
            ' department:' || doc.department || ' priority:' || doc.priority || ' shifr:' || doc.shifr || ' value_date:' || doc.value_date || ' doc_date:' ||
            doc.doc_date || ' doc_kind:' || doc.doc_kind || ' cash_symbs:' || doc.cash_symbs || ' fio_client:' || doc.fio_client || ' userfield1:' || doc.
            userfield1 || ' userfield2:' || doc.userfield2 || ' userfield3:' || doc.userfield3 || ' userfield4:' || doc.userfield4 || ' accept_term:' || doc.
            accept_term || ' pay_condition:' || doc.pay_condition || ' accept_period:' || doc.accept_period || ' creator_status:' || doc.creator_status ||
            ' kbk_code:' || doc.kbk_code || ' okato_code:' || doc.okato_code || ' ground_tax_doc:' || doc.ground_tax_doc || ' tax_period:' || doc.tax_period ||
            ' num_tax_doc:' || doc.num_tax_doc || ' tax_date:' || doc.tax_date || ' tax_type:' || doc.tax_type || ' origin:' || doc.origin || ' payment_id:' ||
            doc.payment_id || CHR (10) || ' payer:' || CHR (10) || ' account:' || doc.payer_pi_rec.account || ' client_name:' || doc.payer_pi_rec.client_name
            || ' bic:' || doc.payer_pi_rec.bank_code || ' inn:' || doc.payer_pi_rec.inn || ' coracc:' || doc.payer_pi_rec.coracc || ' fiid:' || doc.
            payer_pi_rec.fiid || ' bank_id:' || doc.payer_pi_rec.bank_id || ' bank_name:' || doc.payer_pi_rec.bank_name || ' client_id:' || doc.payer_pi_rec.
            client_id || CHR (10) || ' receiver:' || CHR (10) || ' account ' || doc.receiver_pi_rec.account || ' client_name:' || doc.receiver_pi_rec.
            client_name || ' bic:' || doc.receiver_pi_rec.bank_code || ' inn:' || doc.receiver_pi_rec.inn || ' coracc:' || doc.receiver_pi_rec.coracc ||
            ' fiid:' || doc.receiver_pi_rec.fiid || ' bank_id:' || doc.receiver_pi_rec.bank_id || ' bank_name:' || doc.receiver_pi_rec.bank_name ||
            ' client_id:' || doc.receiver_pi_rec.client_id || CHR (10) || ' tech:' || CHR (10) || ' error_text:' || doc.tech_parm_rec.ERROR_TEXT;

        dump_text     := dump_text || ' carry: count=' || doc.carry_nt.COUNT;

        IF doc.carry_nt.EXISTS (1) THEN
            FOR i IN doc.carry_nt.FIRST .. doc.carry_nt.LAST LOOP
                dump_text      :=
                    dump_text || ' chapter: ' || doc.carry_nt (i).chapter || ' payer_account: ' || doc.carry_nt (i).payer_account || ' receiver_account:' ||
                    doc.carry_nt(i).receiver_account || ' ground: ' || doc.carry_nt (i).ground || ' sum: ' || doc.carry_nt (i).SUM || ' pack: ' || doc.carry_nt (i).pack ||
                    ' num_doc: ' || doc.carry_nt (i).num_doc || ' error: ' || doc.carry_nt (i).error;
            END LOOP;
        END IF;

        INSERT INTO usr_debug_dump (paymentid, dump_text)
             VALUES (doc.payment_id, dump_text);

        DBMS_OUTPUT.put_line (dump_text);
    /*for i in nt_our_bank_param.first .. nt_our_bank_param.last
 loop
    --dbms_output.put_line (nt_our_bank_param (i).name);
 end loop;*/
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            NULL;
    END;

    PROCEDURE fill_nt_tables (doc IN OUT NOCOPY main_doc_rec) IS
        v_cnt                                        PLS_INTEGER;
        v_cnt_pmprop                                 PLS_INTEGER;

        PROCEDURE fill_oprcurst (t_statuskindid IN NUMBER, t_numvalue IN NUMBER) AS
            i                                            PLS_INTEGER;
            j                                            PLS_INTEGER;
        BEGIN
            i                                      := nt_oprcurst.COUNT + 1;
            j                                      := nt_oprcurst_tmp.COUNT + 1;

            nt_oprcurst.EXTEND (1);
            nt_oprcurst_tmp.EXTEND (1);
            nt_oprcurst (i).t_id_operation         := doc.operation_id;
            nt_oprcurst (i).t_statuskindid         := t_statuskindid;
            nt_oprcurst_tmp (j).t_statuskindid     := t_statuskindid;
            nt_oprcurst (i).t_numvalue             := t_numvalue;
            nt_oprcurst_tmp (j).t_numvalue         := t_numvalue;
            nt_oprcurst (i).t_dockind              := doc.doc_kind;
        END;

        PROCEDURE complete_oprcurst IS
            --процедура дозаполняет значения сегментов статусов операции, согласно настроек операции
            s                                            PLS_INTEGER;
            lv_found                                     BOOLEAN := FALSE;
            lv_found_opr                                 BOOLEAN := FALSE;
        BEGIN
            FOR i IN nt_oprstat.FIRST .. nt_oprstat.LAST LOOP
                IF nt_oprstat (i).opr_id = doc.num_operation THEN
                    IF doc.tech_parm_rec.run_operation THEN
                        FOR j IN nt_oprstat (i).statvalues_2carry.FIRST .. nt_oprstat (i).statvalues_2carry.LAST LOOP
                            FOR k IN nt_oprcurst_tmp.FIRST .. nt_oprcurst_tmp.LAST LOOP
                                lv_found     := (nt_oprcurst_tmp (k).t_statuskindid = nt_oprstat (i).statvalues_2carry (j).statid);

                                IF lv_found THEN
                                    EXIT;
                                END IF;
                            END LOOP;

                            IF NOT lv_found THEN
                                fill_oprcurst (nt_oprstat (i).statvalues_2carry (j).statid, nt_oprstat (i).statvalues_2carry (j).statvalue);
                            END IF;
                        END LOOP;
                    ELSE
                        FOR j IN nt_oprstat (i).statvalues_2deff.FIRST .. nt_oprstat (i).statvalues_2deff.LAST LOOP
                            FOR k IN nt_oprcurst_tmp.FIRST .. nt_oprcurst_tmp.LAST LOOP
                                lv_found     := (nt_oprcurst_tmp (k).t_statuskindid = nt_oprstat (i).statvalues_2deff (j).statid);

                                IF lv_found THEN
                                    EXIT;
                                END IF;
                            END LOOP;

                            IF NOT lv_found THEN
                                fill_oprcurst (nt_oprstat (i).statvalues_2deff (j).statid, nt_oprstat (i).statvalues_2deff (j).statvalue);
                            END IF;
                        END LOOP;
                    END IF;

                    lv_found_opr     := TRUE;
                END IF;
            END LOOP;

            IF NOT lv_found_opr THEN
                make_error_text (c_err_opr_notfound, doc.tech_parm_rec.ERROR_TEXT, doc.num_operation);
            END IF;

            nt_oprcurst_tmp.delete;
        END;



        FUNCTION get_coracc (corschem IN NUMBER, fiid IN NUMBER)
            RETURN VARCHAR IS
        BEGIN
            FOR i IN nt_corschemes.FIRST .. nt_corschemes.LAST LOOP
                IF nt_corschemes (i).num = corschem AND nt_corschemes (i).fiid = fiid THEN
                    RETURN nt_corschemes (i).account;
                END IF;
            END LOOP;

            RETURN pm_common.rsb_empty_string;
        END;

        -- KS Адаптация патч 30 05.09.2011
        -- co2029_2030.sql
        FUNCTION get_vodirect (vo_code IN NUMBER)
            RETURN NUMBER IS
        BEGIN
            FOR i IN nt_voopkind.FIRST .. nt_voopkind.LAST LOOP
                IF nt_voopkind (i).element = vo_code THEN
                    RETURN nt_voopkind (i).direction;
                END IF;
            END LOOP;

            RETURN 0;
        END;

        -- KS Адаптация патч 30 05.09.2011
        -- co2029_2030.sql
        FUNCTION get_countrycode (bankid IN NUMBER)
            RETURN dcountry_dbt.t_codenum3%TYPE                                                                                    -- KS 27.03.2012 Исправил тип
                                               IS
            lv_country                                   VARCHAR2 (3) := pm_common.rsb_empty_string;
        BEGIN
            SELECT t_country
              INTO lv_country
              FROM (  SELECT adb.t_country
                        FROM dadress_dbt adb
                       -- KS 27.03.2012 надо проверять не только Юридический адрес
                       --               но и фактический
                       WHERE adb.t_type IN (1, 2) AND adb.t_partyid = bankid
                    ORDER BY adb.t_type)
             WHERE ROWNUM = 1;

            FOR i IN nt_country.FIRST .. nt_country.LAST LOOP
                IF nt_country (i).codelat = lv_country THEN
                    RETURN nt_country (i).codenum;
                END IF;
            END LOOP;

            RETURN pm_common.rsb_empty_string;
        EXCEPTION
            WHEN OTHERS THEN
                RETURN pm_common.rsb_empty_string;
        END;

    BEGIN
        v_cnt                                               := nt_pmpaym.COUNT + 1;
        v_cnt_pmprop                                        := nt_pmprop.COUNT + 1;
        nt_pmpaym.EXTEND (1);
        nt_pmprop.EXTEND (2);
        nt_pmrmprop.EXTEND (1);
        nt_oproper.EXTEND (1);

        IF NOT doc.tech_parm_rec.run_operation THEN
            fill_oprcurst (292, 6);                                                                                              --Документооборот=Предобработка
        /*         fill_oprcurst (291, 1);   --Состояние платежа=Отложен
                 fill_oprcurst (292, 6);   --Документооборот=Предобработка
                 fill_oprcurst (296, 1);   --Контроль=Не проконтролирован
              else

                 fill_oprcurst (296, 2);   --Контроль=Проконтролирован
                 fill_oprcurst (305, 1);   --Акцепт=Не требуется*/
        END IF;

        --doprcurst_dbt
        fill_oprcurst (291, 1);
        fill_oprcurst (293, 1);                                                                                                    --ЦАБС=Проведен по счетам МФР
        fill_oprcurst (294, 1);                                                                                               --Квитовка начального=Не сквитован
        fill_oprcurst (297, 1);                                                                                                             --Обработка в БО=Нет
        fill_oprcurst (300, 2);                                                                                             --Плата за обслуживание=Не требуется
        fill_oprcurst (301, 2);                                                                               --Уточнение причастности к терроризму=Не требуется
        fill_oprcurst (302, 2);                                                                                                  --Ручная обработка=Не требуется
        fill_oprcurst (303, 2);                                                                                                     --Межфилиальный в ЦАБС=Нет*/

        --для акцепнтых требований
        IF (doc.doc_kind = c_dockind_client_order AND doc.accept_term = 0) THEN
            fill_oprcurst (304, 2);                                                                                                      --Картотека=Картотека 1
        ELSE
            fill_oprcurst (304, 1);                                                                                                              --Картотека=Нет
        END IF;

        --dpmpaym_dbt
        nt_pmpaym (v_cnt).t_paymentid                       := doc.payment_id;

        IF doc.doc_kind IN (c_dockind_client_paym, c_dockind_client_order) THEN
            nt_pmpaym (v_cnt).t_dockind     := 201;
        ELSE
            nt_pmpaym (v_cnt).t_dockind     := doc.doc_kind;
        END IF;

        nt_pmpaym (v_cnt).t_paymstatus                      := 0;
        nt_pmpaym (v_cnt).t_documentid                      := doc.payment_id;
        nt_pmpaym (v_cnt).t_subpurpose                      := 0;
        nt_pmpaym (v_cnt).t_fiid                            := doc.payer_pi_rec.fiid;

        -- UDA 02.10.2012 по заявке I-00228014-2
        -- begin >
        IF     (doc.doc_kind = c_dockind_client_paym_val)                                                  --проверка на конверсионный платёж, вставляемый из ИК
           AND (doc.origin = 2)
           AND ( (doc.payer_pi_rec.fiid <> doc.doc_cur_fiid) OR (doc.receiver_pi_rec.fiid <> doc.doc_cur_fiid)) THEN
            nt_pmpaym (v_cnt).t_amount          := 0;                                                                         --сумма в валюте счета плательщика
            nt_pmpaym (v_cnt).t_baseamount      := doc.debet_sum;                                                                                --сумма платежа
            nt_pmpaym (v_cnt).t_orderamount     := doc.debet_sum;                                                                               --сумма перевода
        ELSE
            nt_pmpaym (v_cnt).t_amount          := doc.debet_sum;
            nt_pmpaym (v_cnt).t_baseamount      := nt_pmpaym (v_cnt).t_amount;
            nt_pmpaym (v_cnt).t_orderamount     := nt_pmpaym (v_cnt).t_amount;
        END IF;

        -- < end
        nt_pmpaym (v_cnt).t_payfiid                         := doc.receiver_pi_rec.fiid;
        nt_pmpaym (v_cnt).t_payer                           := doc.payer_pi_rec.client_id;
        nt_pmpaym (v_cnt).t_payerbankid                     := doc.payer_pi_rec.bank_id;
        nt_pmpaym (v_cnt).t_payeraccount                    := NVL (doc.payer_pi_rec.account, pm_common.rsb_empty_string);
        nt_pmpaym (v_cnt).t_receiver                        := doc.receiver_pi_rec.client_id;
        nt_pmpaym (v_cnt).t_receiverbankid                  := doc.receiver_pi_rec.bank_id;
        nt_pmpaym (v_cnt).t_receiveraccount                 := NVL (doc.receiver_pi_rec.account, pm_common.rsb_empty_string);
        nt_pmpaym (v_cnt).t_valuedate                       := doc.value_date;
        nt_pmpaym (v_cnt).t_deliverykind                    := 0;
        nt_pmpaym (v_cnt).t_netting                         := pm_common.rsb_empty_char;
        nt_pmpaym (v_cnt).t_department                      := get_parent_department_code (doc.department);
        nt_pmpaym (v_cnt).t_prockind                        := 0;
        nt_pmpaym (v_cnt).t_planpaymid                      := 0;
        nt_pmpaym (v_cnt).t_factpaymid                      := 0;
        nt_pmpaym (v_cnt).t_numberpack                      := doc.pack;
        nt_pmpaym (v_cnt).t_subsplittedpayment              := 0;
        nt_pmpaym (v_cnt).t_createdinss                     := 0;
        nt_pmpaym (v_cnt).t_lastsplitsession                := 0;
        nt_pmpaym (v_cnt).t_tobackoffice                    := pm_common.rsb_empty_char;
        nt_pmpaym (v_cnt).t_legid                           := 0;
        nt_pmpaym (v_cnt).t_indoorstorage                   := 0;
        nt_pmpaym (v_cnt).t_amountnds                       := 0;
        nt_pmpaym (v_cnt).t_accountnds                      := pm_common.rsb_empty_string;
        nt_pmpaym (v_cnt).t_isplanpaym                      := pm_common.set_char;
        nt_pmpaym (v_cnt).t_isfactpaym                      := pm_common.rsb_empty_char;
        nt_pmpaym (v_cnt).t_reserv1                         := 0;
        nt_pmpaym (v_cnt).t_recallamount                    := 0;
        nt_pmpaym (v_cnt).t_payamount                       := doc.kredit_sum;
        nt_pmpaym (v_cnt).t_ratetype                        := 0;
        nt_pmpaym (v_cnt).t_isinverse                       := pm_common.rsb_empty_char;
        nt_pmpaym (v_cnt).t_scale                           := 0;
        nt_pmpaym (v_cnt).t_point                           := 0;
        nt_pmpaym (v_cnt).t_isfixamount                     := pm_common.rsb_empty_char;
        nt_pmpaym (v_cnt).t_feetype                         := 0;
        nt_pmpaym (v_cnt).t_defcomid                        := 0;

        IF nt_pmpaym (v_cnt).t_dockind = c_dockind_client_paym_val THEN
            nt_pmpaym (v_cnt).t_payercodekind     := pm_common.ptck_inn;
            nt_pmpaym (v_cnt).t_payercode         := doc.payer_pi_rec.inn;
        ELSE
            nt_pmpaym (v_cnt).t_payercodekind     := 0;
            nt_pmpaym (v_cnt).t_payercode         := pm_common.rsb_empty_string;
        END IF;

        IF nt_pmpaym (v_cnt).t_dockind IN (c_dockind_client_paym_b, c_dockind_client_paym_s, c_dockind_client_paym_k) THEN
            nt_pmpaym (v_cnt).t_payercodekind     := pm_common.ptck_inn;
            nt_pmpaym (v_cnt).t_payercode         := doc.payer_pi_rec.inn;
        ELSE
            nt_pmpaym (v_cnt).t_payercodekind     := 0;
            nt_pmpaym (v_cnt).t_payercode         := pm_common.rsb_empty_string;
        END IF;


        nt_pmpaym (v_cnt).t_receivercodekind                := 0;
        nt_pmpaym (v_cnt).t_receivercode                    := pm_common.rsb_empty_string;
        nt_pmpaym (v_cnt).t_rate                            := doc.rate;
        --nt_pmpaym (v_cnt).t_baseamount := nt_pmpaym (v_cnt).t_amount; --UDA перенёс под условие выше
        nt_pmpaym (v_cnt).t_basefiid                        := doc.doc_cur_fiid;
        nt_pmpaym (v_cnt).t_ratedate                        := usr_common.c_nulldate;
        nt_pmpaym (v_cnt).t_baseratetype                    := 0;
        nt_pmpaym (v_cnt).t_baserate                        := 0;
        nt_pmpaym (v_cnt).t_basepoint                       := 0;
        nt_pmpaym (v_cnt).t_basescale                       := 0;
        nt_pmpaym (v_cnt).t_isbaseinverse                   := pm_common.rsb_empty_char;
        nt_pmpaym (v_cnt).t_baseratedate                    := usr_common.c_nulldate;
        nt_pmpaym (v_cnt).t_futurepayeramount               := nt_pmpaym (v_cnt).t_amount;
        nt_pmpaym (v_cnt).t_futurereceiveramount            := nt_pmpaym (v_cnt).t_payamount;
        nt_pmpaym (v_cnt).t_subkind                         := 0;
        nt_pmpaym (v_cnt).t_payerdpnode                     := 0;
        nt_pmpaym (v_cnt).t_receiverdpnode                  := 0;
        nt_pmpaym (v_cnt).t_payerdpblock                    := -1;
        nt_pmpaym (v_cnt).t_receiverdpblock                 := -1;
        nt_pmpaym (v_cnt).t_i2placedate                     := usr_common.c_nulldate;
        nt_pmpaym (v_cnt).t_payerbankmarkdate               := usr_common.c_nulldate;
        nt_pmpaym (v_cnt).t_receiverbankmarkdate            := usr_common.c_nulldate;
        nt_pmpaym (v_cnt).t_partpaymnumber                  := 0;
        nt_pmpaym (v_cnt).t_partpaymshifrmain               := pm_common.rsb_empty_string;
        nt_pmpaym (v_cnt).t_partpaymnummain                 := pm_common.rsb_empty_string;
        nt_pmpaym (v_cnt).t_partpaymdatemain                := usr_common.c_nulldate;
        nt_pmpaym (v_cnt).t_partpaymrestamountmain          := 0;
        nt_pmpaym (v_cnt).t_kindoperation                   := 0;
        nt_pmpaym (v_cnt).t_claimid                         := 0;
        nt_pmpaym (v_cnt).t_oper                            := doc.oper;

        IF (doc.origin < 1000) THEN
            nt_pmpaym (v_cnt).t_origin     := 2;
        ELSE
            nt_pmpaym (v_cnt).t_origin     := doc.origin;
        END IF;

        nt_pmpaym (v_cnt).t_startdepartment                 := get_parent_department_code (doc.department);
        nt_pmpaym (v_cnt).t_enddepartment                   := get_parent_department_code (doc.department);
        nt_pmpaym (v_cnt).t_dbflag                          := pm_common.rsb_empty_char;
        nt_pmpaym (v_cnt).t_ispurpose                       := pm_common.rsb_empty_char;
        nt_pmpaym (v_cnt).t_notforbackoffice                := pm_common.rsb_empty_char;
        nt_pmpaym (v_cnt).t_placetoindex                    := pm_common.rsb_empty_char;
        nt_pmpaym (v_cnt).t_primdockind                     := 0;
        nt_pmpaym (v_cnt).t_converted                       := pm_common.rsb_empty_char;
        nt_pmpaym (v_cnt).t_payerdppartition                := pm_common.rsb_empty_string;
        nt_pmpaym (v_cnt).t_receiverdppartition             := pm_common.rsb_empty_string;
        nt_pmpaym (v_cnt).t_linkamountkind                  := 0;
        nt_pmpaym (v_cnt).t_comissfiid                      := doc.comiss_fiid;
        nt_pmpaym (v_cnt).t_comissaccount                   := doc.comiss_acc;
        nt_pmpaym (v_cnt).t_contrnversion                   := 0;
        nt_pmpaym (v_cnt).t_boprocesskind                   := 0;
        -- KS 27.11.2013 Адаптация под 31ю сборку
        -- pm_drop_benefit.sql
        --nt_pmpaym (v_cnt).t_benefit                         := 0;
        -- KS Адаптация патч 30 27.06.2011
        -- pmpaym_135153.sql
        nt_pmpaym (v_cnt).t_futuredratetype                 := 0;
        nt_pmpaym (v_cnt).t_futuredrate                     := 0;
        nt_pmpaym (v_cnt).t_futuredratepoint                := 0;
        nt_pmpaym (v_cnt).t_futuredratescale                := 0;
        nt_pmpaym (v_cnt).t_futuredrateisinverse            := pm_common.rsb_empty_char;
        nt_pmpaym (v_cnt).t_futuredratedate                 := usr_common.c_nulldate;
        nt_pmpaym (v_cnt).t_futurecratetype                 := 0;
        nt_pmpaym (v_cnt).t_futurecrate                     := 0;
        nt_pmpaym (v_cnt).t_futurecratepoint                := 0;
        nt_pmpaym (v_cnt).t_futurecratescale                := 0;
        nt_pmpaym (v_cnt).t_futurecrateisinverse            := pm_common.rsb_empty_char;
        nt_pmpaym (v_cnt).t_futurecratedate                 := usr_common.c_nulldate;
        -- KS end Адаптация патч 30 27.06.2011
        nt_pmpaym (v_cnt).t_futureratedepartment            := 0;
        nt_pmpaym (v_cnt).t_chapter                         := doc.chapter;
        nt_pmpaym (v_cnt).t_futurebaseamount                := nt_pmpaym (v_cnt).t_amount;
        nt_pmpaym (v_cnt).t_futurepayeraccount              := nt_pmpaym (v_cnt).t_payeraccount;
        nt_pmpaym (v_cnt).t_futurereceiveraccount           := nt_pmpaym (v_cnt).t_receiveraccount;
        nt_pmpaym (v_cnt).t_fiid_futurepayacc               := nt_pmpaym (v_cnt).t_fiid;
        nt_pmpaym (v_cnt).t_fiid_futurerecacc               := nt_pmpaym (v_cnt).t_payfiid;
        nt_pmpaym (v_cnt).t_opernode                        := doc.department;
        -- KS Адаптация патч 30 27.06.2011
        -- 149919.sql
        nt_pmpaym (v_cnt).t_checkterror                     := 0;
        nt_pmpaym (v_cnt).t_primdocorigin                   := doc.origin;                                               -- KS 05.09.2011 По замечанию Лавренова
        nt_pmpaym (v_cnt).t_typedocument                    := pm_common.rsb_empty_string;
        nt_pmpaym (v_cnt).t_userfield1                      := pm_common.rsb_empty_string;
        nt_pmpaym (v_cnt).t_userfield2                      := pm_common.rsb_empty_string;
        nt_pmpaym (v_cnt).t_userfield3                      := pm_common.rsb_empty_string;
        nt_pmpaym (v_cnt).t_userfield4                      := pm_common.rsb_empty_string;
        nt_pmpaym (v_cnt).t_usertypedocument                := pm_common.rsb_empty_string;
        -- pmpaym_135153.sql
        nt_pmpaym (v_cnt).t_orderfiid                       := nt_pmpaym (v_cnt).t_payfiid;
        --nt_pmpaym (v_cnt).t_orderamount := nt_pmpaym (v_cnt).t_amount; --UDA перенёс под условие выше
        -- pmpaym165700.sql
        nt_pmpaym (v_cnt).t_creationdate                    := TRUNC (SYSDATE);
        nt_pmpaym (v_cnt).t_creationtime                    := TO_DATE ('01.01.0001', 'DD.MM.YYYY') + (SYSDATE - TRUNC (SYSDATE));
        -- pmpaym149467.sql
        nt_pmpaym (v_cnt).t_mcmethodid                      := 0;
        -- 148658.sql
        nt_pmpaym (v_cnt).t_paytype                         := doc.paytype;                                              -- UDA 26.07.2012 По запросу I-00225239
        -- closedate2030.sql
        nt_pmpaym (v_cnt).t_closedate                       := usr_common.c_nulldate;
        -- KS end Адаптация патч 30 27.06.2011
        -- KS 27.11.2013 Адаптация под 31ю сборку
        -- pmpaym170350.sql
        nt_pmpaym (v_cnt).t_minimizationturn := chr(0);
        -- 188833.sql
        nt_pmpaym (v_cnt).t_ContentOperation := chr(1);
        -- KS end 27.11.2013 Адаптация 31ю сборку

        /* EVG 26/11/2012 Для вставки переданного swift-кода клиента-получателя */
        IF doc.receiver_pi_rec.client_code IS NOT NULL THEN
            nt_pmpaym (v_cnt).t_receivercodekind     := ptck_swift;                             -- Пока исходим из того, что передаваться может только bic-swift
            nt_pmpaym (v_cnt).t_receivercode         := doc.receiver_pi_rec.client_code;
        END IF;


        --dpmprop_dbt
        nt_pmprop (v_cnt_pmprop).t_propstatus               := 0;
        nt_pmprop (v_cnt_pmprop).t_paymentid                := doc.payment_id;
        nt_pmprop (v_cnt_pmprop).t_debetcredit              := 0;                                                               --плательщик в дебетовом платеже
        nt_pmprop (v_cnt_pmprop).t_codekind                 := doc.payer_pi_rec.bank_codekind;
        nt_pmprop (v_cnt_pmprop).t_codename                 := doc.payer_pi_rec.bank_codename;
        nt_pmprop (v_cnt_pmprop).t_bankcode                 := doc.payer_pi_rec.bank_code;
        nt_pmprop (v_cnt_pmprop).t_payfiid                  := nt_pmpaym (v_cnt).t_payfiid;
        nt_pmprop (v_cnt_pmprop).t_corschem                 := -1;
        nt_pmprop (v_cnt_pmprop).t_issender                 := pm_common.set_char;
        nt_pmprop (v_cnt_pmprop).t_tpid                     := 0;
        nt_pmprop (v_cnt_pmprop).t_transferdate             := usr_common.c_nulldate;
        nt_pmprop (v_cnt_pmprop).t_corracc                  := pm_common.rsb_empty_string;
        nt_pmprop (v_cnt_pmprop).t_corrcodekind             := 0;
        nt_pmprop (v_cnt_pmprop).t_corrcodename             := pm_common.rsb_empty_string;
        nt_pmprop (v_cnt_pmprop).t_corrcode                 := pm_common.rsb_empty_string;
        nt_pmprop (v_cnt_pmprop).t_sortkey                  := 0;
        nt_pmprop (v_cnt_pmprop).t_corrpostype              := 0;
        nt_pmprop (v_cnt_pmprop).t_instructionabonent       := 0;
        nt_pmprop (v_cnt_pmprop).t_settlementsystemcode     := pm_common.rsb_empty_string;
        nt_pmprop (v_cnt_pmprop).t_corrid                   := -1;
        nt_pmprop (v_cnt_pmprop).t_ourcorrid                := 1;
        nt_pmprop (v_cnt_pmprop).t_ourcorrcodekind          := 0;
        nt_pmprop (v_cnt_pmprop).t_ourcorrcode              := pm_common.rsb_empty_string;
        nt_pmprop (v_cnt_pmprop).t_ourcorracc               := pm_common.rsb_empty_string;
        nt_pmprop (v_cnt_pmprop).t_inourbalance             := pm_common.rsb_empty_char;
        nt_pmprop (v_cnt_pmprop).t_group                    := pm_common.payments_group_branch;
        nt_pmprop (v_cnt_pmprop).t_contrnversion            := 0;
        nt_pmprop (v_cnt_pmprop).t_tpschemid                := 0;
        nt_pmprop (v_cnt_pmprop).t_rlsformid                := 0;
        nt_pmprop (v_cnt_pmprop).t_subkindmessage           := NVL (doc.subkindmessagedebet, wld_common.wld_subkind_paym_cln);      -- zip_z. 2013-03-04 C-16618
        nt_pmprop (v_cnt_pmprop).t_reserve                  := pm_common.rsb_empty_string;

        IF doc.doc_kind = c_dockind_external_in                                                                          -- KS 03.06.2011 И для внешних входящих
                                               THEN
            nt_pmprop (v_cnt_pmprop).t_corschem         := doc.corschem;
            nt_pmprop (v_cnt_pmprop).t_transferdate     := doc.transfer_date;

            -- KS 14.11.2011 Если Указали корсхему, то меняем t_corrpostype
            -- zip_z. 2013-03-04 C-16618
            IF doc.corschem != -1 OR doc.subkindmessagedebet IS NOT NULL THEN
                nt_pmprop (v_cnt_pmprop).t_corrpostype     := pm_common.pm_corrpos_type_user;
            END IF;

            nt_pmprop (v_cnt_pmprop).t_propstatus       := pm_common.pm_prop_loaded;
            nt_pmprop (v_cnt_pmprop).t_group            := pm_common.payments_group_external;
            nt_pmprop (v_cnt_pmprop).t_ourcorrid        := -1;
        END IF;

        --получатель
        v_cnt_pmprop                                        := v_cnt_pmprop + 1;
        nt_pmprop (v_cnt_pmprop)                            := nt_pmprop (v_cnt_pmprop - 1);

        -- zip_z. 2013-03-04 C-16618
        nt_pmprop (v_cnt_pmprop).t_subkindmessage           := NVL (doc.subkindmessagecredit, wld_common.wld_subkind_paym_cln);

        IF doc.corschem != -1 OR doc.subkindmessagecredit IS NOT NULL THEN
            nt_pmprop (v_cnt_pmprop).t_corrpostype     := pm_common.pm_corrpos_type_user;
        END IF;

        IF     doc.doc_kind IN
                   (c_dockind_bank_paym,
                    c_dockind_client_paym_k,
                    c_dockind_client_paym_s,
                    c_dockind_client_paym_b,
                    c_dockind_client_paym,
                    c_dockind_client_paym_val,
                    c_dockind_bank_paym_val,
                    c_dockind_client_order)
           AND NOT doc.tech_parm_rec.is_our_receiver THEN
            nt_pmprop (v_cnt_pmprop).t_group            := pm_common.payments_group_external;
            nt_pmprop (v_cnt_pmprop).t_bankcode         := doc.receiver_pi_rec.bank_code;
            nt_pmprop (v_cnt_pmprop).t_corschem         := doc.corschem;
            nt_pmprop (v_cnt_pmprop).t_transferdate     := doc.transfer_date;
            nt_pmprop (v_cnt_pmprop).t_corrpostype      := doc.corrpos;
            nt_pmprop (v_cnt_pmprop).t_codekind         := doc.receiver_pi_rec.bank_codekind;
            nt_pmprop (v_cnt_pmprop).t_codename         := doc.receiver_pi_rec.bank_codename;
            nt_pmprop (v_cnt_pmprop).t_corrcodekind     := doc.receiver_pi_rec.med_bank_codekind;
            nt_pmprop (v_cnt_pmprop).t_corrcode         := doc.receiver_pi_rec.med_bank_code;
        END IF;

        IF doc.doc_kind = c_dockind_external_in                                                                          -- KS 03.06.2011 И для внешних входящих
                                               THEN
            nt_pmprop (v_cnt_pmprop).t_group            := pm_common.PAYMENTS_GROUP_BRANCH;
            nt_pmprop (v_cnt_pmprop).t_bankcode         := doc.receiver_pi_rec.bank_code;
            nt_pmprop (v_cnt_pmprop).t_corschem         := -1;
            nt_pmprop (v_cnt_pmprop).t_transferdate     := doc.transfer_date;
            nt_pmprop (v_cnt_pmprop).t_corrpostype      := 0;
            nt_pmprop (v_cnt_pmprop).t_codekind         := doc.receiver_pi_rec.bank_codekind;
            nt_pmprop (v_cnt_pmprop).t_codename         := doc.receiver_pi_rec.bank_codename;
            nt_pmprop (v_cnt_pmprop).t_corrcodekind     := NVL (doc.receiver_pi_rec.med_bank_codekind, 0);
            nt_pmprop (v_cnt_pmprop).t_corrcode         := doc.receiver_pi_rec.med_bank_code;
            nt_pmprop (v_cnt_pmprop).t_propstatus       := pm_common.pm_prop_loaded;
        END IF;

        nt_pmprop (v_cnt_pmprop).t_debetcredit              := 1;
        nt_pmprop (v_cnt_pmprop).t_issender                 := pm_common.rsb_empty_char;
        --dpmrmprop_dbt
        nt_pmrmprop (v_cnt).t_paymentid                     := nt_pmpaym (v_cnt).t_paymentid;
        nt_pmrmprop (v_cnt).t_number                        := doc.num_doc;
        nt_pmrmprop (v_cnt).t_reference                     := pm_common.rsb_empty_string;
        nt_pmrmprop (v_cnt).t_date                          := doc.doc_date;
        nt_pmrmprop (v_cnt).t_payercorraccnostro            := doc.payer_pi_rec.coracc;
        nt_pmrmprop (v_cnt).t_payerbankname                 := NVL (doc.payer_pi_rec.bank_name, pm_common.rsb_empty_string);
        nt_pmrmprop (v_cnt).t_payername                     := NVL (doc.payer_pi_rec.client_name, pm_common.rsb_empty_string);
        nt_pmrmprop (v_cnt).t_payerinn                      := NVL (doc.payer_pi_rec.inn, pm_common.rsb_empty_string);
        nt_pmrmprop (v_cnt).t_receivercorraccnostro         := doc.receiver_pi_rec.coracc;
        nt_pmrmprop (v_cnt).t_receiverbankname              := NVL (doc.receiver_pi_rec.bank_name, pm_common.rsb_empty_string);
        nt_pmrmprop (v_cnt).t_receivername                  := NVL (doc.receiver_pi_rec.client_name, pm_common.rsb_empty_string);
        nt_pmrmprop (v_cnt).t_receiverinn                   := NVL (doc.receiver_pi_rec.inn, pm_common.rsb_empty_string);
        nt_pmrmprop (v_cnt).t_shifroper                     := NVL (SUBSTR (doc.shifr, 1, INSTR (doc.shifr, '/') - 1), doc.shifr);
        nt_pmrmprop (v_cnt).t_priority                      := doc.priority;
        nt_pmrmprop (v_cnt).t_ground                        := doc.ground;
        nt_pmrmprop (v_cnt).t_clientdate                    := doc.doc_date;
        nt_pmrmprop (v_cnt).t_processkind                   := pm_common.rsb_empty_string;
        nt_pmrmprop (v_cnt).t_paymentkind                   := doc.paymentkind;
        nt_pmrmprop (v_cnt).t_messagetype                   := pm_common.rsb_empty_string;
        nt_pmrmprop (v_cnt).t_partyinfo                     := pm_common.rsb_empty_string;
        nt_pmrmprop (v_cnt).t_payercorrbankname             := pm_common.rsb_empty_string;
        nt_pmrmprop (v_cnt).t_receivercorrbankname          := doc.receiver_pi_rec.med_bank_name || ' ' || doc.receiver_pi_rec.med_bank_place_name;
        nt_pmrmprop (v_cnt).t_isshortformat                 := pm_common.rsb_empty_char;
        nt_pmrmprop (v_cnt).t_kindpaycurrency               := 0;
        nt_pmrmprop (v_cnt).t_ourpayercorrname              := pm_common.rsb_empty_string;
        nt_pmrmprop (v_cnt).t_ourreceivercorrname           := pm_common.rsb_empty_string;
        nt_pmrmprop (v_cnt).t_payerchargeoffdate            := nt_main_doc (gv_cnt).payerchargeoffdate;
        nt_pmrmprop (v_cnt).t_taxauthorstate                := doc.creator_status;
        nt_pmrmprop (v_cnt).t_bttticode                     := doc.kbk_code;
        nt_pmrmprop (v_cnt).t_okatocode                     := doc.okato_code;
        nt_pmrmprop (v_cnt).t_taxpmground                   := doc.ground_tax_doc;
        nt_pmrmprop (v_cnt).t_taxpmperiod                   := doc.tax_period;
        nt_pmrmprop (v_cnt).t_taxpmnumber                   := doc.num_tax_doc;
        nt_pmrmprop (v_cnt).t_taxpmdate                     := doc.tax_date;
        nt_pmrmprop (v_cnt).t_taxpmtype                     := doc.tax_type;

        IF doc.cash_symbols_nt.COUNT > 0 AND doc.cash_symbols_nt (1).symb_type = 3  THEN
            nt_pmrmprop (v_cnt).t_symbnotbaldebet     := LPAD (doc.cash_symbols_nt (1).cash_symbol, 3, ' ');  
        ELSE
            nt_pmrmprop (v_cnt).t_symbnotbaldebet     := pm_common.rsb_empty_string;
        END IF;

        nt_pmrmprop (v_cnt).t_instancy                      := 0;
        nt_pmrmprop (v_cnt).t_docdispatchdate               := usr_common.c_nulldate;

        IF (doc.doc_kind IN (c_dockind_memorder, c_dockind_multycarry, c_dockind_memorder_bank_order)) AND doc.cash_symbols_nt.COUNT > 0 THEN
            nt_pmrmprop (v_cnt).t_cashsymboldebet      := pm_common.rsb_empty_string;
            nt_pmrmprop (v_cnt).t_cashsymbolcredit     := pm_common.rsb_empty_string;

            FOR i IN doc.cash_symbols_nt.FIRST .. doc.cash_symbols_nt.LAST LOOP
                IF doc.cash_symbols_nt (i).symb_type = 1 THEN
                    nt_pmrmprop (v_cnt).t_cashsymboldebet     := LPAD (doc.cash_symbols_nt (i).cash_symbol, 3, ' '); 
                ELSIF doc.cash_symbols_nt (i).symb_type = 2 THEN
                    nt_pmrmprop (v_cnt).t_cashsymbolcredit     := LPAD (doc.cash_symbols_nt (i).cash_symbol, 3, ' ');
                END IF;
            END LOOP;
        ELSE
            nt_pmrmprop (v_cnt).t_cashsymboldebet      := pm_common.rsb_empty_string;
            nt_pmrmprop (v_cnt).t_cashsymbolcredit     := pm_common.rsb_empty_string;
        END IF;

        nt_pmrmprop (v_cnt).t_symbnotbalcredit              := pm_common.rsb_empty_string;
        nt_pmrmprop (v_cnt).t_isoptimbytime                 := pm_common.rsb_empty_char;

        IF doc.doc_kind IN (c_dockind_client_paym_val, c_dockind_bank_paym_val) THEN
            nt_pmrmprop (v_cnt).t_comisscharges     := get_comisscharges (doc.expense_transfer, doc.tech_parm_rec.ERROR_TEXT);
        ELSE
            nt_pmrmprop (v_cnt).t_comisscharges     := 0;
        END IF;

        nt_pmrmprop (v_cnt).t_instructioncode               := pm_common.rsb_empty_string;
        nt_pmrmprop (v_cnt).t_additionalinfo                := doc.ground_add;
        nt_pmrmprop (v_cnt).t_contrnversion                 := 0;
        -- KS 27.11.2013 Адаптация под 31ю сборку
        -- pm_drop_benefit.sql
        --nt_pmrmprop (v_cnt).t_benefitnote                   := pm_common.rsb_empty_string;
        nt_pmrmprop (v_cnt).t_neednotify                    := pm_common.rsb_empty_char;
        nt_pmrmprop (v_cnt).t_kindoper                      := pm_common.rsb_empty_string;

        IF doc.doc_kind IN (c_dockind_memorder, c_dockind_memorder_bank_order) THEN
            nt_pmrmprop (v_cnt).t_paymentkind     := pm_common.rsb_empty_char;
            nt_pmrmprop (v_cnt).t_paydate         := usr_common.c_nulldate;
        ELSE
            nt_pmrmprop (v_cnt).t_paydate     := doc.doc_date;
        END IF;

        -- VDN 27.03.2014 C-28175
        nt_pmrmprop (v_cnt).t_uin             := doc.uin;   

        --doproper_dbt
        nt_oproper (v_cnt).t_id_operation                   := doc.operation_id;
        nt_oproper (v_cnt).t_dockind                        := nt_pmpaym (v_cnt).t_dockind;
        nt_oproper (v_cnt).t_documentid                     := LPAD (nt_pmrmprop (v_cnt).t_paymentid, 34, '0');
        nt_oproper (v_cnt).t_kind_operation                 := doc.num_operation;
        nt_oproper (v_cnt).t_isnew                          := pm_common.rsb_empty_char;
        nt_oproper (v_cnt).t_completed                      := pm_common.rsb_empty_char;
        nt_oproper (v_cnt).t_end_date                       := usr_common.c_nulldate;
        nt_oproper (v_cnt).t_sort                           := pm_common.rsb_empty_string;
        nt_oproper (v_cnt).t_boactions                      := 0;
        nt_oproper (v_cnt).t_bocode                         := 0;
        nt_oproper (v_cnt).t_ko_manualselection             := pm_common.rsb_empty_char;
        nt_oproper (v_cnt).t_deferdate                      := usr_common.c_nulldate;
        nt_oproper (v_cnt).t_contrnversion                  := 0;
        nt_oproper (v_cnt).t_init_oper                      := 0;
        nt_oproper (v_cnt).t_start_date                     := usr_common.c_nulldate;
        nt_oproper (v_cnt).t_syst_date                      := usr_common.c_nulldate;
        nt_oproper (v_cnt).t_syst_time                      := usr_common.c_nulldate;
        nt_oproper (v_cnt).t_parent_id_operation            := 0;
        nt_oproper (v_cnt).t_parent_id_step                 := 0;

        IF doc.doc_kind = c_dockind_memorder THEN
            nt_pmpaym (v_cnt).t_purpose                := 48;
            nt_pmpaym (v_cnt).t_payerbankenterdate     := usr_common.c_nulldate;
            nt_pmpaym (v_cnt).t_payermesbankid         := nt_pmpaym (v_cnt).t_payerbankid;
            nt_pmpaym (v_cnt).t_receivermesbankid      := nt_pmpaym (v_cnt).t_receiverbankid;

            nt_cb_doc.EXTEND (1);
            nt_cb_doc (v_cnt).t_documentid             := nt_pmpaym (v_cnt).t_paymentid;
            nt_cb_doc (v_cnt).t_kind_operation         := doc.num_operation;
            nt_cb_doc (v_cnt).t_oper                   := doc.oper;
            nt_cb_doc (v_cnt).t_chapter                := doc.chapter;
            nt_cb_doc (v_cnt).t_code_currency          := doc.payer_pi_rec.fiid;
            nt_cb_doc (v_cnt).t_state                  := bb_memorder.cb_doc_state_deferred;
            nt_cb_doc (v_cnt).t_result_carry           := 1;

            IF INSTR (doc.shifr, '/') = 0 THEN
                nt_cb_doc (v_cnt).t_kind_oper     := ' 6';
            ELSE
                nt_cb_doc (v_cnt).t_kind_oper     := SUBSTR (doc.shifr, INSTR (doc.shifr, '/') + 1);
            END IF;

            nt_cb_doc (v_cnt).t_typedocument           := doc.typedoc;
            nt_cb_doc (v_cnt).t_usertypedocument       := doc.usertypedoc;
            nt_cb_doc (v_cnt).t_userfield1             := doc.userfield1;
            nt_cb_doc (v_cnt).t_userfield2             := doc.userfield2;
            nt_cb_doc (v_cnt).t_userfield3             := doc.userfield3;
            nt_cb_doc (v_cnt).t_userfield4             := doc.userfield4;
            nt_cb_doc (v_cnt).t_origin                 := doc.origin;
            nt_cb_doc (v_cnt).t_contrnversion          := 0;

            fill_oprcurst (298, 285); -- Вид документа=Мемориальный документ
            fill_oprcurst (295, 1);   -- Направление=Внутренний для ЦАБС
        ELSIF doc.doc_kind = c_dockind_memorder_bank_order THEN
            IF nt_pmpaym (v_cnt).t_fiid = 0 THEN
                nt_pmpaym (v_cnt).t_purpose     := pm_common.pm_purp_bankorder;                                                                         
            ELSE
                nt_pmpaym (v_cnt).t_purpose     := pm_common.pm_purp_cbankorder;                                                                      
            END IF;

            nt_pmpaym (v_cnt).t_payerbankenterdate     := usr_common.c_nulldate;
            nt_pmpaym (v_cnt).t_payermesbankid         := nt_pmpaym (v_cnt).t_payerbankid;
            nt_pmpaym (v_cnt).t_receivermesbankid      := nt_pmpaym (v_cnt).t_receiverbankid;
            nt_pmpaym (v_cnt).t_userfield1             := doc.userfield1;
            nt_pmpaym (v_cnt).t_userfield2             := doc.userfield2;
            nt_pmpaym (v_cnt).t_userfield3             := doc.userfield3;
            nt_pmpaym (v_cnt).t_userfield4             := doc.userfield4;

            fill_oprcurst (298, 286);      -- Вид документа=Банковский ордер
            fill_oprcurst (295, 1);        -- Направление=Внутренний для ЦАБС
        END IF;

        IF doc.doc_kind IN (c_dockind_bank_paym, c_dockind_bank_paym_val) THEN
            fill_oprcurst (298, 281);        -- Вид документа=Платеж банка
            nt_pmpaym (v_cnt).t_purpose                := 15;
            nt_pmpaym (v_cnt).t_payermesbankid         := 0;

            IF doc.tech_parm_rec.is_our_receiver THEN
                nt_pmpaym (v_cnt).t_receivermesbankid     := 0;
                fill_oprcurst (295, 1);         -- Направление=Внутренний для ЦАБС
            ELSE
                --внешний платеж банка
                nt_pmpaym (v_cnt).t_receivermesbankid         := nt_pmpaym (v_cnt).t_receiverbankid;
                nt_pmpaym (v_cnt).t_futurereceiveraccount     := get_coracc (doc.corschem, nt_pmpaym (v_cnt).t_basefiid);
                fill_oprcurst (295, 3);        --Направление=Исходящий
                fill_oprcurst (299, 1);        --Квитанция=Не подтвержден
            END IF;


            nt_pmpaym (v_cnt).t_payerbankenterdate     := rsi_rsboperday.getdepartmentoperdate (1);

            nt_memorder.EXTEND (1);
            nt_memorder (v_cnt).t_orderid              := nt_pmpaym (v_cnt).t_paymentid;
            nt_memorder (v_cnt).t_dockind              := doc.doc_kind;
            nt_memorder (v_cnt).t_kind_operation       := doc.num_operation;
            nt_memorder (v_cnt).t_oper                 := doc.oper;
            nt_memorder (v_cnt).t_status               := bb_bankpaym.memorder_status_post;
            nt_memorder (v_cnt).t_userfield1           := doc.userfield1;
            nt_memorder (v_cnt).t_userfield2           := doc.userfield2;
            nt_memorder (v_cnt).t_userfield3           := doc.userfield3;
            nt_memorder (v_cnt).t_userfield4           := doc.userfield4;
            nt_memorder (v_cnt).t_origin               := doc.origin;
            nt_memorder (v_cnt).t_maketid              := 0;
            nt_memorder (v_cnt).t_contrnversion        := 0;
            nt_memorder (v_cnt).t_reserve              := pm_common.rsb_empty_string;
        END IF;

        -- KS 03.06.2011 внешний входящий
        IF doc.doc_kind = c_dockind_external_in THEN
            nt_pmpaym (v_cnt).t_purpose                := 28;
            nt_pmpaym (v_cnt).t_payermesbankid         := 0;
            nt_pmpaym (v_cnt).t_receivermesbankid      := nt_pmpaym (v_cnt).t_receiverbankid;
            nt_pmpaym (v_cnt).t_futurepayeraccount     := get_coracc (doc.corschem, nt_pmpaym (v_cnt).t_basefiid);
            nt_pmpaym (v_cnt).t_payerbankenterdate     := rsi_rsboperday.getdepartmentoperdate (1);
            nt_pmpaym (v_cnt).t_paymstatus             := 2990;
            nt_wlpm.EXTEND (1);
            nt_wlpm (v_cnt).t_wlpmid                   := 0;
            nt_wlpm (v_cnt).t_wlpmnum                  := 0;
            nt_wlpm (v_cnt).t_paymentid                := nt_pmpaym (v_cnt).t_paymentid;
            nt_wlpm (v_cnt).t_direct                   := pm_common.set_char;
            nt_wlpm (v_cnt).t_propstatus               := nt_pmprop (v_cnt_pmprop).t_propstatus;
            nt_wlpm (v_cnt).t_payfiid                  := nt_pmpaym (v_cnt).t_payfiid;
            nt_wlpm (v_cnt).t_corschem                 := nt_pmprop (v_cnt_pmprop).t_corschem;
            nt_wlpm (v_cnt).t_cardfiledatein           := usr_common.c_nulldate;
            nt_wlpm (v_cnt).t_cardfiledateout          := usr_common.c_nulldate;
            nt_wlpm (v_cnt).t_cardfilekind             := 0;
            nt_wlpm (v_cnt).t_storedatevalue           := usr_common.c_nulldate;
            nt_wlpm (v_cnt).t_valuedate                := nt_pmpaym (v_cnt).t_valuedate;
            nt_wlpm (v_cnt).t_isunknown                := pm_common.rsb_empty_char;
            nt_wlpm (v_cnt).t_isprinted                := pm_common.rsb_empty_char;
            nt_wlpm (v_cnt).t_contrnversion            := 0;
            fill_oprcurst (295, 2);           --Направление=входящий (4 - транзитный)
            fill_oprcurst (296, 2);           -- контроль - 2 - проконтролирован
            fill_oprcurst (298, 320);         -- вид документа - ответный
            fill_oprcurst (3201, 2);          -- квитовка ответного - 2- сквитован

--            IF doc.num_operation <> 0 THEN
--                fill_oprcurst (291, 1);       --Состояние платежа=Отложен
--            END IF;
        END IF;

        IF doc.doc_kind IN
               (c_dockind_client_paym,
                c_dockind_client_order,
                c_dockind_client_paym_val,
                c_dockind_client_paym_s,
                c_dockind_client_paym_k,
                c_dockind_client_paym_b) THEN
            IF doc.doc_kind NOT IN (c_dockind_client_paym_s, c_dockind_client_paym_k, c_dockind_client_paym_b) THEN
                fill_oprcurst (298, 283);     --Вид документа=Клиентский платеж
                nt_pmpaym (v_cnt).t_purpose     := 7;
            END IF;

            nt_pmpaym (v_cnt).t_payermesbankid         := 0;


            IF doc.tech_parm_rec.is_our_receiver THEN
                nt_pmpaym (v_cnt).t_receivermesbankid     := 0;
                fill_oprcurst (295, 1);       --Направление=Внутренний для ЦАБС
            ELSE
                --внешний платеж
                nt_pmpaym (v_cnt).t_receivermesbankid         := nt_pmpaym (v_cnt).t_receiverbankid;
                nt_pmpaym (v_cnt).t_futurereceiveraccount     := get_coracc (doc.corschem, nt_pmpaym (v_cnt).t_basefiid);
                fill_oprcurst (295, 3);       --Направление=Исходящий
                fill_oprcurst (299, 1);       --Квитанция=Не подтвержден
            END IF;

            -- KS Адаптация патч 30 04.07.2011
            nt_pmpaym (v_cnt).t_payerbankenterdate     := rsi_rsboperday.getdepartmentoperdate (1);
            --dpspayord_dbt
            nt_pspayord.EXTEND (1);
            nt_pspayord (v_cnt).t_orderid              := nt_pmpaym (v_cnt).t_paymentid;

            IF doc.doc_kind = c_dockind_client_order THEN
                nt_pspayord (v_cnt).t_dockind           := 2;
                --dpspaydem_dbt
                nt_pspaydem.EXTEND (1);
                nt_pspaydem (v_cnt).t_orderid           := nt_pmpaym (v_cnt).t_paymentid;
                nt_pspaydem (v_cnt).t_reqsum            := nt_pmpaym (v_cnt).t_amount;
                nt_pspaydem (v_cnt).t_acceptdate        := doc.accept_date;
                nt_pspaydem (v_cnt).t_acceptperiod      := doc.accept_period;
                nt_pspaydem (v_cnt).t_acceptterm        := doc.accept_term;

                IF doc.accept_term = 1 THEN
                    nt_pspaydem (v_cnt).t_accept     := 3;
                ELSE
                    nt_pspaydem (v_cnt).t_accept     := 0;
                END IF;

                nt_pspaydem (v_cnt).t_paycondition      := doc.pay_condition;
                nt_pspaydem (v_cnt).t_contrnversion     := 0;
                nt_pspaydem (v_cnt).t_reserve           := pm_common.rsb_empty_string;
            ELSE
                nt_pspayord (v_cnt).t_dockind     := 1;
            END IF;

            nt_pspayord (v_cnt).t_origin               := doc.origin;
            nt_pspayord (v_cnt).t_kind_operation       := doc.num_operation;
            nt_pspayord (v_cnt).t_oper                 := doc.oper;
            nt_pspayord (v_cnt).t_control              := pm_common.rsb_empty_char;
            nt_pspayord (v_cnt).t_opercontrol          := 0;
            nt_pspayord (v_cnt).t_currentstate         := 0;
            nt_pspayord (v_cnt).t_payeraccount         := doc.payer_pi_rec.account;
            nt_pspayord (v_cnt).t_userfield1           := doc.userfield1;
            nt_pspayord (v_cnt).t_userfield2           := doc.userfield2;
            nt_pspayord (v_cnt).t_userfield3           := doc.userfield3;
            nt_pspayord (v_cnt).t_userfield4           := doc.userfield4;
            nt_pspayord (v_cnt).t_invertflags          := HEXTORAW (RPAD ('0', 80, '0'));
            nt_pspayord (v_cnt).t_maketid              := 0;
            nt_pspayord (v_cnt).t_contrnversion        := 0;
            nt_pspayord (v_cnt).t_reserve              := pm_common.rsb_empty_string;
        END IF;

        IF doc.doc_kind = c_dockind_client_paym_val THEN
            --dpscpord_dbt
            nt_pscpord.EXTEND (1);
            nt_pscpord (v_cnt).t_orderid            := nt_pmpaym (v_cnt).t_paymentid;
            nt_pscpord (v_cnt).t_origin             := doc.origin;
            nt_pscpord (v_cnt).t_kind_operation     := doc.num_operation;
            nt_pscpord (v_cnt).t_oper               := doc.oper;
            nt_pscpord (v_cnt).t_currentstate       := 0;
            nt_pscpord (v_cnt).t_payeraccount       := doc.payer_pi_rec.account;
            nt_pscpord (v_cnt).t_userfield1         := doc.userfield1;
            nt_pscpord (v_cnt).t_userfield2         := doc.userfield2;
            nt_pscpord (v_cnt).t_userfield3         := doc.userfield3;
            nt_pscpord (v_cnt).t_userfield4         := doc.userfield4;
            nt_pscpord (v_cnt).t_maketid            := 0;
            nt_pscpord (v_cnt).t_contrnversion      := 0;
            nt_pscpord (v_cnt).t_reserve            := pm_common.rsb_empty_string;
        END IF;


        IF doc.doc_kind IN (c_dockind_client_paym_s, c_dockind_client_paym_k, c_dockind_client_paym_b) THEN
            nt_pmpaym (v_cnt).t_rate                   := doc.rate;
            nt_pmpaym (v_cnt).t_scale                  := 1;
            nt_pmpaym (v_cnt).t_point                  := 4;
            nt_pmpaym (v_cnt).t_rate                   := doc.rate * RPAD ('1', nt_pmpaym (v_cnt).t_point + 1, '0');

            IF doc.doc_kind IN (c_dockind_client_paym_s) THEN
                nt_pmpaym (v_cnt).t_fiid            := doc.payer_pi_rec.fiid;
                nt_pmpaym (v_cnt).t_payfiid         := doc.receiver_pi_rec.fiid;
                nt_pmpaym (v_cnt).t_isfixamount     := pm_common.set_char;
            ELSIF doc.doc_kind IN (c_dockind_client_paym_b) THEN
                nt_pmpaym (v_cnt).t_fiid                 := doc.payer_pi_rec.fiid;
                nt_pmpaym (v_cnt).t_payfiid              := doc.receiver_pi_rec.fiid;
                nt_pmpaym (v_cnt).t_basefiid             := doc.receiver_pi_rec.fiid;
                nt_pmpaym (v_cnt).t_baseamount           := nt_pmpaym (v_cnt).t_payamount;
                nt_pmpaym (v_cnt).t_futurebaseamount     := nt_pmpaym (v_cnt).t_payamount;
            END IF;

            nt_pmpaym (v_cnt).t_dockind                := pm_common.ps_buycurorder;
            nt_pmpaym (v_cnt).t_purpose                := 59;
            nt_pmpaym (v_cnt).t_payermesbankid         := nt_pmpaym (v_cnt).t_payerbankid;
            nt_pmpaym (v_cnt).t_receivermesbankid      := nt_pmpaym (v_cnt).t_receiverbankid;
            nt_dps_bcord.EXTEND (1);                                                                                                                        ----
            nt_dps_bcord (v_cnt).t_paymentid           := nt_pmpaym (v_cnt).t_paymentid;
            nt_dps_bcord (v_cnt).t_convoper            := 1;
            nt_dps_bcord (v_cnt).t_oper                := doc.oper;
            nt_dps_bcord (v_cnt).t_kindoperation       := 24002;
            nt_dps_bcord (v_cnt).t_state               := 0;
            nt_dps_bcord (v_cnt).t_bosspost            := doc.bosspost;
            nt_dps_bcord (v_cnt).t_bossfio             := doc.bossfio;
            nt_dps_bcord (v_cnt).t_bankfunds           := pm_common.set_char;
            nt_dps_bcord (v_cnt).t_exchangeid          := -1;
            nt_dps_bcord (v_cnt).t_exchangefiid        := -1;
            nt_dps_bcord (v_cnt).t_limrate             := 0;
            nt_dps_bcord (v_cnt).t_limratescale        := 1;
            nt_dps_bcord (v_cnt).t_limrateinv          := pm_common.rsb_empty_char;
            nt_dps_bcord (v_cnt).t_limratepoint        := 4;
            nt_dps_bcord (v_cnt).t_cause               := pm_common.rsb_empty_string;
            nt_dps_bcord (v_cnt).t_searchreceiver      := pm_common.rsb_empty_char;
            nt_dps_bcord (v_cnt).t_origin              := doc.origin;
            nt_dps_bcord (v_cnt).t_userfield1          := pm_common.rsb_empty_string;
            nt_dps_bcord (v_cnt).t_userfield2          := pm_common.rsb_empty_string;
            nt_dps_bcord (v_cnt).t_userfield3          := pm_common.rsb_empty_string;
            nt_dps_bcord (v_cnt).t_userfield4          := pm_common.rsb_empty_string;
            nt_dps_bcord (v_cnt).t_contrnversion       := 0;

            --dps_bcexe_dbt
            nt_dps_bcexe.EXTEND (1);                                                                                                                        ----
            nt_dps_bcexe (v_cnt).t_paymentid           := nt_pmpaym (v_cnt).t_paymentid;
            nt_dps_bcexe (v_cnt).t_requestid           := 0;
            nt_dps_bcexe (v_cnt).t_execdate            := TO_DATE ('31.12.9999', 'DD.MM.YYYY');
            nt_dps_bcexe (v_cnt).t_amount              := 0;
            nt_dps_bcexe (v_cnt).t_bankfundsamount     := 0;
            nt_dps_bcexe (v_cnt).t_rate                := doc.rate;
            nt_dps_bcexe (v_cnt).t_ratescale           := 4;
            nt_dps_bcexe (v_cnt).t_rateinv             := 1;
            nt_dps_bcexe (v_cnt).t_ratepoint           := 0;
            nt_dps_bcexe (v_cnt).t_writeoffamount      := 0;
            nt_dps_bcexe (v_cnt).t_satisfiedamount     := 0;
            nt_dps_bcexe (v_cnt).t_depositrest         := 0;
            nt_dps_bcexe (v_cnt).t_contrnversion       := 0;

            --dps_ordoc_dbt
            nt_dps_ordoc.EXTEND (1);                                                                                                                        ----
            nt_dps_ordoc (v_cnt).t_paymentid           := nt_pmpaym (v_cnt).t_paymentid;
            nt_dps_ordoc (v_cnt).t_orderdoctype        := 4;
            nt_dps_ordoc (v_cnt).t_number              := pm_common.rsb_empty_string;
            nt_dps_ordoc (v_cnt).t_date_document       := usr_common.c_nulldate;
            nt_dps_ordoc (v_cnt).t_comment             := pm_common.rsb_empty_string;
        END IF;

        IF doc.doc_kind = c_dockind_bank_paym_val THEN
            --dbbcpord_dbt
            nt_bbcpord.EXTEND (1);
            nt_bbcpord (v_cnt).t_orderid            := nt_pmpaym (v_cnt).t_paymentid;
            nt_bbcpord (v_cnt).t_origin             := doc.origin;
            nt_bbcpord (v_cnt).t_kind_operation     := doc.num_operation;
            nt_bbcpord (v_cnt).t_oper               := doc.oper;
            nt_bbcpord (v_cnt).t_currentstate       := 0;
            nt_bbcpord (v_cnt).t_payeraccount       := doc.payer_pi_rec.account;
            nt_bbcpord (v_cnt).t_userfield1         := doc.userfield1;
            nt_bbcpord (v_cnt).t_userfield2         := doc.userfield2;
            nt_bbcpord (v_cnt).t_userfield3         := doc.userfield3;
            nt_bbcpord (v_cnt).t_userfield4         := doc.userfield4;
            nt_bbcpord (v_cnt).t_maketid            := 0;
            nt_bbcpord (v_cnt).t_contrnversion      := 0;
            nt_bbcpord (v_cnt).t_reserve            := pm_common.rsb_empty_string;
        END IF;

        IF doc.doc_kind IN (c_dockind_client_paym, c_dockind_client_order) THEN
            nt_oproper (v_cnt).t_dockind     := 201;
        END IF;

        IF doc.doc_kind IN (c_dockind_client_paym_b, c_dockind_client_paym_k, c_dockind_client_paym_s) THEN
            IF doc.doc_kind = c_dockind_client_paym_b THEN
                nt_dps_bcord (v_cnt).t_bcordkind     := 1;
            ELSIF doc.doc_kind = c_dockind_client_paym_k THEN
                nt_dps_bcord (v_cnt).t_bcordkind     := 3;
            ELSE
                nt_dps_bcord (v_cnt).t_bcordkind     := 2;
            END IF;

            nt_oproper (v_cnt).t_dockind     := pm_common.ps_buycurorder;
        END IF;

        IF doc.doc_kind IN (c_dockind_cash_in, c_dockind_cash_out, c_dockind_cash_inout, c_dockind_client_cash_in, c_dockind_client_cash_out) THEN
            nt_pmpaym (v_cnt).t_primdockind            := doc.doc_kind;
            nt_pmpaym (v_cnt).t_payerbankenterdate     := usr_common.c_nulldate;
            
            nt_pmrmprop (v_cnt).t_shifroper            := pm_common.rsb_empty_string;
            nt_pmrmprop (v_cnt).t_priority             := 0;
            nt_pmrmprop (v_cnt).t_paymentkind          := pm_common.rsb_empty_char;
            
            nt_pmpaym (v_cnt).t_purpose                := 14;
            nt_pmpaym (v_cnt).t_receivermesbankid      := 0;
            nt_pmpaym (v_cnt).t_payermesbankid         := 0;
            
            --dpscshdoc_dbt
            nt_pscshdoc.EXTEND (1);
            nt_pscshdoc (v_cnt).t_autokey              := doc.payment_id;
            nt_pscshdoc (v_cnt).t_dockind              := doc.doc_kind;
            nt_pscshdoc (v_cnt).t_kind_operation       := doc.num_operation;
            nt_pscshdoc (v_cnt).t_oper                 := doc.oper;
            nt_pscshdoc (v_cnt).t_fioclient            := doc.fio_client;
            nt_pscshdoc (v_cnt).t_nameissuer           := pm_common.rsb_empty_string;
            nt_pscshdoc (v_cnt).t_connectappkind       := 0;
            nt_pscshdoc (v_cnt).t_connectappkey        := pm_common.rsb_empty_string;
            --в кассовых платежах ПИ "переворачиваются"
            nt_pscshdoc (v_cnt).t_clientaccount        := doc.payer_pi_rec.account;
            
            nt_pmpaym (v_cnt).t_payer                  := doc.receiver_pi_rec.client_id;
            nt_pmpaym (v_cnt).t_receiver               := doc.payer_pi_rec.client_id;
            nt_pmpaym (v_cnt).t_payeraccount           := doc.receiver_pi_rec.account;
            nt_pmpaym (v_cnt).t_receiveraccount        := doc.payer_pi_rec.account;
            
            nt_pmrmprop (v_cnt).t_payername            := doc.receiver_pi_rec.client_name;
            nt_pmrmprop (v_cnt).t_payerinn             := doc.receiver_pi_rec.inn;
            nt_pmrmprop (v_cnt).t_receivername         := doc.payer_pi_rec.client_name;
            nt_pmrmprop (v_cnt).t_receiverinn          := doc.payer_pi_rec.inn;

            nt_pscshdoc (v_cnt).t_iscurrency           := pm_common.rsb_empty_char;

            IF doc.doc_kind IN (c_dockind_client_cash_in, c_dockind_client_cash_out) THEN
                nt_pscshdoc (v_cnt).t_backofficekind     := pm_common.rsb_empty_char;
                -- KS 16.01.2014 6->5
                nt_pmrmprop (v_cnt).t_priority           := 5;
            ELSE
                nt_pscshdoc (v_cnt).t_backofficekind     := pm_common.set_char;
            END IF;

            nt_pscshdoc (v_cnt).t_series               := pm_common.rsb_empty_string;
            nt_pscshdoc (v_cnt).t_origin               := doc.origin;
            nt_pscshdoc (v_cnt).t_clientid             := 0;
            nt_pscshdoc (v_cnt).t_status               := rsb_cashord.stat_cash_order_post;
            nt_pscshdoc (v_cnt).t_paperkind            := doc.paperkind;                                                                        -- KS 24.10.2011
            nt_pscshdoc (v_cnt).t_paperseries          := doc.paperseries;                                                                      -- KS 24.10.2011
            nt_pscshdoc (v_cnt).t_papernumber          := doc.papernumber;                                                                      -- KS 24.10.2011
            nt_pscshdoc (v_cnt).t_paperissueddate      := doc.paperissueddate;                                                                  -- KS 24.10.2011
            nt_pscshdoc (v_cnt).t_paperissuer          := doc.paperissuer;                                                                      -- KS 24.10.2011
            nt_pscshdoc (v_cnt).t_contrnversion        := 0;
            nt_pscshdoc (v_cnt).t_userfield1           := doc.userfield1;
            nt_pscshdoc (v_cnt).t_userfield2           := doc.userfield2;
            nt_pscshdoc (v_cnt).t_userfield3           := doc.userfield3;
            nt_pscshdoc (v_cnt).t_userfield4           := doc.userfield4;
            
            fill_oprcurst (298, 284);   --Вид документа=Кассовый документ
            fill_oprcurst (295, 1);     --Направление=Внутренний для ЦАБС

            IF doc.cash_symbols_nt.COUNT > 0 THEN
                FOR i IN doc.cash_symbols_nt.FIRST .. doc.cash_symbols_nt.LAST LOOP
                    --KS 28.10.2011 Для ввода без символа
                    IF (doc.cash_symbols_nt (i).cash_symbol <> '0') THEN  
                        --dsymbcash_dbt
                        nt_symbcash.EXTEND (1);
                        nt_symbcash (i).t_dockind            := 1;
                        nt_symbcash (i).t_kind               := doc.cash_symbols_nt (i).symb_type;
                        nt_symbcash (i).t_applicationkey     := LPAD (doc.payment_id, 34, '0');
                        nt_symbcash (i).t_symbol             := ' ' || doc.cash_symbols_nt (i).cash_symbol;
                        nt_symbcash (i).t_sum                := doc.cash_symbols_nt (i).cash_sum;
                        nt_symbcash (i).t_date               := usr_common.c_nulldate;
                        nt_symbcash (i).t_reserved           := pm_common.rsb_empty_string;
                        -- KS 05.12.2013 Адаптация под 31ю сборку.
                        nt_symbcash (i).t_acctrnid           := null;
                    END IF;
                END LOOP;
            END IF;
        END IF;


        IF doc.doc_kind = c_dockind_multycarry THEN
            nt_pmpaym (v_cnt).t_purpose                := 49;
            nt_pmpaym (v_cnt).t_isplanpaym             := pm_common.rsb_empty_char;
            nt_pmpaym (v_cnt).t_primdockind            := doc.doc_kind;
            nt_pmpaym (v_cnt).t_payerbankenterdate     := usr_common.c_nulldate;
            nt_pmpaym (v_cnt).t_rate                   := doc.rate;
            nt_pmpaym (v_cnt).t_scale                  := 1;
            nt_pmpaym (v_cnt).t_point                  := 4;
            nt_pmpaym (v_cnt).t_rate                   := doc.rate * RPAD ('1', nt_pmpaym (v_cnt).t_point + 1, '0');
            nt_pmpaym (v_cnt).t_payermesbankid         := 0;
            nt_pmpaym (v_cnt).t_receivermesbankid      := 0;
            nt_pmrmprop (v_cnt).t_shifroper            := pm_common.rsb_empty_string;
            nt_pmrmprop (v_cnt).t_priority             := 0;
            nt_pmpaym (v_cnt).t_fiid_futurepayacc      := nt_pmpaym (v_cnt).t_fiid;
            nt_pmpaym (v_cnt).t_fiid_futurerecacc      := nt_pmpaym (v_cnt).t_payfiid;

            IF nt_pmpaym (v_cnt).t_fiid = 0 THEN
                nt_pmpaym (v_cnt).t_isinverse     := pm_common.set_char;
            END IF;

            nt_pmrmprop (v_cnt).t_paymentkind          := pm_common.rsb_empty_char;
            --dmultydoc_dbt
            nt_multydoc.EXTEND (1);
            nt_multydoc (v_cnt).t_autokey              := doc.payment_id;
            nt_multydoc (v_cnt).t_chapter              := doc.chapter;
            nt_multydoc (v_cnt).t_oper                 := doc.oper;
            nt_multydoc (v_cnt).t_kind_operation       := doc.num_operation;
            --nt_multydoc (v_cnt).t_closedate := usr_common.c_nulldate; -- KS Адаптация патч 30 27.06.2011
            nt_multydoc (v_cnt).t_userfield1           := doc.userfield1;
            nt_multydoc (v_cnt).t_userfield2           := doc.userfield2;
            nt_multydoc (v_cnt).t_userfield3           := doc.userfield3;
            nt_multydoc (v_cnt).t_userfield4           := doc.userfield4;
            nt_multydoc (v_cnt).t_status               := bb_multydoc.mcdoc_status_post;
            nt_multydoc (v_cnt).t_type_document        := doc.typedoc;
            nt_multydoc (v_cnt).t_origin               := doc.origin;
            nt_multydoc (v_cnt).t_contrnversion        := 0;
            fill_oprcurst (295, 1);   --Направление=Внутренний для ЦАБС
            fill_oprcurst (298, 285); --Вид документа=Мемориальный документ
        END IF;

        --dpmco_dbt
        IF doc.vo_code <> pm_common.rsb_empty_string THEN
            nt_pmco.EXTEND (1);

            nt_pmco (v_cnt).t_paymentid                   := doc.payment_id;
            nt_pmco (v_cnt).t_vo_code                     := doc.vo_codeid;
            nt_pmco (v_cnt).t_passportnumber              := doc.deal_passport;
            nt_pmco (v_cnt).t_passportdate                := doc.deal_date;
            nt_pmco (v_cnt).t_contractnumber              := doc.gtd;
            nt_pmco (v_cnt).t_contractdate                := doc.gtd_date;
            nt_pmco (v_cnt).t_amount                      := nt_pmpaym (v_cnt).t_baseamount;
            nt_pmco (v_cnt).t_contractamount              := 0;
            nt_pmco (v_cnt).t_general                     := pm_common.set_char;
            nt_pmco (v_cnt).t_pmcoid                      := 0;

            IF doc.gtd_cur_iso <> pm_common.rsb_empty_string THEN
                nt_pmco (v_cnt).t_contractfiid     := get_fiid (NULL, doc.tech_parm_rec.ERROR_TEXT, doc.gtd_cur_iso);
            ELSE
                nt_pmco (v_cnt).t_contractfiid     := -1;
            END IF;

            nt_pmcurtr.EXTEND (1);
            nt_pmcurtr (v_cnt).t_paymentid                := doc.payment_id;
            nt_pmcurtr (v_cnt).t_isvo                     := pm_common.set_char;
            nt_pmcurtr (v_cnt).t_accept                   := 0;
            nt_pmcurtr (v_cnt).t_oper                     := 0;
            nt_pmcurtr (v_cnt).t_fiid                     := nt_pmpaym (v_cnt).t_basefiid;
            nt_pmcurtr (v_cnt).t_direct                   := get_vodirect (doc.vo_codeid);
            nt_pmcurtr (v_cnt).t_payerbankid              := doc.payer_pi_rec.bank_id;
            nt_pmcurtr (v_cnt).t_payerbankcodekind        := doc.payer_pi_rec.bank_codekind;
            nt_pmcurtr (v_cnt).t_payerbankcode            := doc.payer_pi_rec.bank_code;
            nt_pmcurtr (v_cnt).t_payerbankcountry         := get_countrycode (doc.payer_pi_rec.bank_id);
            nt_pmcurtr (v_cnt).t_receiverbankid           := doc.receiver_pi_rec.bank_id;
            nt_pmcurtr (v_cnt).t_receiverbankcodekind     := doc.receiver_pi_rec.bank_codekind;
            nt_pmcurtr (v_cnt).t_receiverbankcode         := doc.receiver_pi_rec.bank_code;
            nt_pmcurtr (v_cnt).t_receiverbankcountry      := get_countrycode (doc.receiver_pi_rec.bank_id);
        END IF;

        IF doc.num_operation <> 0 THEN
            complete_oprcurst;
--        ELSE
--            fill_oprcurst (291, 1);
        END IF;
    END;

    PROCEDURE delete_pack IS
    BEGIN
        gv_cnt                 := 1;
        ready_to_run_operation := FALSE;
        
        nt_main_doc.delete;
        nt_pmpaym.delete;
        nt_pmprop.delete;
        nt_pmrmprop.delete;
        nt_oproper.delete;
        nt_pspayord.delete;
        nt_pscpord.delete;
        nt_pmco.delete;
        nt_pmcurtr.delete; 
        nt_pspaydem.delete;
        nt_cb_doc.delete;
        nt_memorder.delete;
        nt_oprcurst.delete;
        nt_oprcurst_tmp.delete;
        nt_pscshdoc.delete;
        nt_symbcash.delete;
        nt_multydoc.delete;
        nt_bbcpord.delete;
        nt_wlpm.delete;

        nt_dps_bcord.delete;
        nt_dps_bcexe.delete;
        nt_dps_ordoc.delete;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;

    PROCEDURE create_payments (p_run_operation BOOLEAN, p_in_transact BOOLEAN) IS
        v_stat                                       NUMBER;
    BEGIN
        FORALL i IN nt_pmpaym.FIRST   .. nt_pmpaym.LAST   INSERT INTO dpmpaym_dbt   VALUES nt_pmpaym   (i);
        FORALL i IN nt_pmprop.FIRST   .. nt_pmprop.LAST   INSERT INTO dpmprop_dbt   VALUES nt_pmprop   (i);
        FORALL i IN nt_pmrmprop.FIRST .. nt_pmrmprop.LAST INSERT INTO dpmrmprop_dbt VALUES nt_pmrmprop (i);
        FORALL i IN nt_cb_doc.FIRST   .. nt_cb_doc.LAST   INSERT INTO dcb_doc_dbt   VALUES nt_cb_doc   (i);
        FORALL i IN nt_pspayord.FIRST .. nt_pspayord.LAST INSERT INTO dpspayord_dbt VALUES nt_pspayord (i);
        FORALL i IN nt_pscpord.FIRST  .. nt_pscpord.LAST  INSERT INTO dpscpord_dbt  VALUES nt_pscpord  (i);
        FORALL i IN nt_pspaydem.FIRST .. nt_pspaydem.LAST INSERT INTO dpspaydem_dbt VALUES nt_pspaydem (i);
        FORALL i IN nt_oproper.FIRST  .. nt_oproper.LAST  INSERT INTO doproper_dbt  VALUES nt_oproper  (i);
        FORALL i IN nt_memorder.FIRST .. nt_memorder.LAST INSERT INTO dmemorder_dbt VALUES nt_memorder (i);
        FORALL i IN nt_pscshdoc.FIRST .. nt_pscshdoc.LAST INSERT INTO dpscshdoc_dbt VALUES nt_pscshdoc (i);
        FORALL i IN nt_symbcash.FIRST .. nt_symbcash.LAST INSERT INTO dsymbcash_dbt VALUES nt_symbcash (i);
        FORALL i IN nt_multydoc.FIRST .. nt_multydoc.LAST INSERT INTO dmultydoc_dbt VALUES nt_multydoc (i);

        -- KS 01.08.2011 см. триггер SET_DO_2CARRY
        FOR i IN nt_oprcurst.FIRST .. nt_oprcurst.LAST LOOP
            DELETE doprcurst_dbt oprcurst WHERE oprcurst.t_id_operation = nt_oprcurst (i).t_id_operation AND t_statuskindid = 292 AND oprcurst.t_dockind = 320;
        END LOOP;

        FORALL i IN nt_oprcurst.FIRST  .. nt_oprcurst.LAST  INSERT INTO doprcurst_dbt VALUES nt_oprcurst (i);
        FORALL i IN nt_pmco.FIRST      .. nt_pmco.LAST      INSERT INTO dpmco_dbt     VALUES nt_pmco (i);
        FORALL i IN nt_pmcurtr.FIRST   .. nt_pmcurtr.LAST   INSERT INTO dpmcurtr_dbt  VALUES nt_pmcurtr (i);
        FORALL i IN nt_bbcpord.FIRST   .. nt_bbcpord.LAST   INSERT INTO dbbcpord_dbt  VALUES nt_bbcpord (i);
        FORALL i IN nt_dps_bcord.FIRST .. nt_dps_bcord.LAST INSERT INTO dps_bcord_dbt VALUES nt_dps_bcord (i);
        FORALL i IN nt_dps_bcexe.FIRST .. nt_dps_bcexe.LAST INSERT INTO dps_bcexe_dbt VALUES nt_dps_bcexe (i);
        FORALL i IN nt_dps_ordoc.FIRST .. nt_dps_ordoc.LAST INSERT INTO dps_ordoc_dbt VALUES nt_dps_ordoc (i);
        FORALL i IN nt_wlpm.FIRST      .. nt_wlpm.LAST      INSERT INTO dwlpm_dbt     VALUES nt_wlpm (i);

        FOR i IN nt_main_doc.FIRST .. nt_main_doc.LAST LOOP
            IF    (nt_main_doc (i).tech_parm_rec.run_operation AND nt_main_doc (i).tech_parm_rec.make_carry_from_payment)
               OR NOT nt_main_doc (i).tech_parm_rec.run_operation THEN
                IF nt_main_doc (i).carry_nt.EXISTS (1) THEN
                    INSERT INTO usr_pmdocs
                         VALUES (nt_main_doc (i).carry_nt (1).autokey,
                                 nt_main_doc (i).carry_nt (1).paymentid,
                                 nt_main_doc (i).carry_nt (1).operationid,
                                 nt_main_doc (i).carry_nt (1).carrynum,
                                 -- KS 10.12.2013 Адаптация под 31ю сборку 
                                 --nt_main_doc (i).carry_nt (1).fiid,
                                 nt_main_doc (i).carry_nt (1).fiid_payer,
                                 nt_main_doc (i).carry_nt (1).fiid_receiver,
                                 nt_main_doc (i).carry_nt (1).chapter,
                                 nt_main_doc (i).carry_nt (1).payer_account,
                                 nt_main_doc (i).carry_nt (1).receiver_account,
                                 nt_main_doc (i).carry_nt (1).SUM,
                                 -- KS 11.12.2013 Адаптация под 31ю сборку 
                                 nt_main_doc (i).carry_nt (1).sum_payer,
                                 nt_main_doc (i).carry_nt (1).sum_receiver,
                                 nt_main_doc (i).carry_nt (1).date_carry,
                                 nt_main_doc (i).carry_nt (1).oper,
                                 nt_main_doc (i).carry_nt (1).pack,
                                 nt_main_doc (i).carry_nt (1).num_doc,
                                 nt_main_doc (i).carry_nt (1).ground,
                                 nt_main_doc (i).carry_nt (1).department,
                                 nt_main_doc (i).carry_nt (1).vsp,
                                 nt_main_doc (i).carry_nt (1).kind_oper,
                                 nt_main_doc (i).carry_nt (1).shifr_oper,
                                 nt_main_doc (i).carry_nt (1).error,
                                 SYSTIMESTAMP);
                END IF;
            END IF;
        END LOOP;

        IF p_run_operation THEN
            DELETE FROM doprtemp_tmp;

            FOR i IN nt_pmpaym.FIRST .. nt_pmpaym.LAST LOOP
                INSERT INTO doprtemp_tmp (t_sort,
                                          t_dockind,
                                          t_documentid,
                                          t_orderid,
                                          t_kind_operation,
                                          t_start_date,
                                          t_isnew,
                                          t_id_step)
                     VALUES (i,
                             nt_pmpaym (i).t_dockind,
                             LPAD (TO_CHAR (nt_pmpaym (i).t_paymentid), 34, '0'),
                             nt_pmpaym (i).t_paymentid,
                             nt_main_doc (gv_cnt).num_operation,
                             rsbsessiondata.curdate,
                             pm_common.set_char,
                             NULL);
            END LOOP;
        ELSE
            IF NOT p_in_transact THEN
                COMMIT;
            END IF;

            delete_pack;
        END IF;
    END;

    PROCEDURE rollback_trn (in_transaction BOOLEAN, p_error VARCHAR2) IS
    BEGIN
        delete_pack;

        IF in_transaction THEN
            raise_application_error (-20001, p_error);
        ELSE
            ROLLBACK;
        END IF;
    END;

    FUNCTION get_usertypeaccount (p_account IN VARCHAR2)
        RETURN VARCHAR IS
        v_usertypeaccount                            VARCHAR2 (16);
    BEGIN
        SELECT t.t_usertypeaccount
          INTO v_usertypeaccount
        -- KS 27.11.2013 Адаптация под 31ю сборку
        --  FROM daccounts_dbt t
          FROM daccount_dbt t
         WHERE t.t_account = p_account;

        RETURN v_usertypeaccount;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    PROCEDURE insert_payment (p_payer_account                         IN     VARCHAR2,
                              p_payer_name                            IN     VARCHAR2 DEFAULT NULL,
                              p_payer_bic                             IN     VARCHAR2 DEFAULT NULL,
                              p_payer_inn                             IN     VARCHAR2 DEFAULT NULL,
                              p_payer_kpp                             IN     VARCHAR2 DEFAULT NULL,
                              p_receiver_account                      IN     VARCHAR2,
                              p_receiver_name                         IN     VARCHAR2 DEFAULT NULL,
                              p_receiver_bic                          IN     VARCHAR2 DEFAULT NULL,
                              p_receiver_inn                          IN     VARCHAR2 DEFAULT NULL,
                              p_receiver_kpp                          IN     VARCHAR2 DEFAULT NULL,
                              p_oper                                  IN     NUMBER,
                              p_pack                                  IN     NUMBER DEFAULT NULL,
                              p_corschem                              IN     NUMBER DEFAULT NULL,
                              p_num_operation                         IN     NUMBER DEFAULT NULL,
                              p_num_doc                               IN     VARCHAR2,
                              p_typedoc                               IN     VARCHAR2 DEFAULT NULL,
                              p_usertypedoc                           IN     VARCHAR2 DEFAULT NULL,
                              p_debet_sum                             IN     NUMBER,
                              p_kredit_sum                            IN     NUMBER DEFAULT NULL,
                              p_rate                                  IN     NUMBER DEFAULT NULL,
                              p_ground                                IN     VARCHAR2,
                              p_branch                                IN     NUMBER DEFAULT NULL,
                              p_priority                              IN     NUMBER DEFAULT NULL,
                              p_shifr                                 IN     VARCHAR2 DEFAULT NULL,
                              p_value_date                            IN     DATE DEFAULT NULL,
                              p_doc_date                              IN     DATE DEFAULT NULL,
                              p_doc_kind                              IN     NUMBER,
                              p_cash_symbs                            IN     VARCHAR2 DEFAULT NULL,
                              p_fio_client                            IN     VARCHAR2 DEFAULT NULL,
                              p_userfield1                            IN     VARCHAR2 DEFAULT NULL,
                              p_userfield2                            IN     VARCHAR2 DEFAULT NULL,
                              p_userfield3                            IN     VARCHAR2 DEFAULT NULL,
                              p_userfield4                            IN     VARCHAR2 DEFAULT NULL,
                              p_accept_term                           IN     NUMBER DEFAULT NULL,
                              p_accept_date                           IN     DATE DEFAULT NULL,
                              p_pay_condition                         IN     VARCHAR2 DEFAULT NULL,
                              p_accept_period                         IN     NUMBER DEFAULT NULL,
                              p_creator_status                        IN     VARCHAR2 DEFAULT NULL,
                              p_kbk_code                              IN     VARCHAR2 DEFAULT NULL,
                              p_okato_code                            IN     VARCHAR2 DEFAULT NULL,
                              p_ground_tax_doc                        IN     VARCHAR2 DEFAULT NULL,
                              p_tax_period                            IN     VARCHAR2 DEFAULT NULL,
                              p_num_tax_doc                           IN     VARCHAR2 DEFAULT NULL,
                              p_tax_date                              IN     VARCHAR2 DEFAULT NULL,
                              p_tax_type                              IN     VARCHAR2 DEFAULT NULL,
                              p_origin                                IN     NUMBER,
                              p_skip_check_mask                              NUMBER DEFAULT 0,
                              p_check_exists                          IN     NUMBER DEFAULT NULL,
                              p_run_operation                         IN     NUMBER DEFAULT NULL,
                              p_pack_mode                                    NUMBER DEFAULT NULL,
                              p_make_carry_from_payment               IN     NUMBER DEFAULT NULL,
                              p_payment_id                               OUT NUMBER,
                              p_error                                    OUT VARCHAR2,
                              p_transaction_mode                      IN     NUMBER DEFAULT 0,
                              p_doc_cur_iso                                  VARCHAR2 DEFAULT NULL,                                            --валюта перевода
                              p_receiver_account_cur_iso                     VARCHAR2 DEFAULT NULL,                                          --валюта получателя
                              p_comiss_acc                                   VARCHAR2 DEFAULT NULL,                                              --счет комиссии
                              p_expense_transfer                             VARCHAR2 DEFAULT NULL,                                         --комиссии и расходы
                              p_vo_code                                      VARCHAR2 DEFAULT NULL,                                                     --код ВО
                              p_gtd                                          VARCHAR2 DEFAULT NULL,                                            --номер контракта
                              p_gtd_date                                     DATE DEFAULT NULL,                                                 --дата контракта
                              p_gtd_cur_iso                                  VARCHAR2 DEFAULT NULL,                                           --валюта контракта
                              p_deal_passport                                VARCHAR2 DEFAULT NULL,                                             --паспорт сделки
                              p_deal_date                                    DATE DEFAULT NULL,                                                  --дата паспорта
                              p_med_bankname                                 VARCHAR2 DEFAULT NULL,                                  --название банка посредника
                              --p_med_coracc varchar2 default null, --корсчет банка посредника
                              p_med_bic                                      VARCHAR2 DEFAULT NULL,                                       --код банка посредника
                              p_receiver_bankname                            VARCHAR2 DEFAULT NULL,                                 -- название банка получателя
                              p_receiver_bankcoracc                          VARCHAR2 DEFAULT NULL,                              --корсчет счет банка получателя
                              p_receiver_bank_bic                            VARCHAR2 DEFAULT NULL,                                 --код банка получателя-банка
                              p_ground_add                                   VARCHAR2 DEFAULT NULL,
                              p_transfer_date                                DATE DEFAULT NULL,
                              p_bosspost                                     VARCHAR2 DEFAULT NULL,                                            -- Должность босс
                              p_bossfio                                      VARCHAR2 DEFAULT NULL,                                                  -- Имя босс
                              p_paymentkind                                  VARCHAR2 DEFAULT 'Н',                        -- Вид платежа TAM 16.07.2013 R-216001 
                              p_autorun_operation                     IN     NUMBER DEFAULT NULL,                                             -- Запуск операции
                              p_paperkind                                    NUMBER DEFAULT NULL,                 -- KS 24.10.2011 Для кассвовых - тип документа
                              p_paperseries                                  VARCHAR2 DEFAULT NULL,                       -- KS 24.10.2011 Для кассвовых - серия
                              p_papernumber                                  VARCHAR2 DEFAULT NULL,                       -- KS 24.10.2011 Для кассвовых - номер
                              p_paperissueddate                              DATE DEFAULT NULL,                            -- KS 24.10.2011 Для кассвовых - дата
                              p_paperissuer                                  VARCHAR2 DEFAULT NULL,                       -- KS 24.10.2011 Для кассвовых - выдан
                              p_payerchargeoffdate                           DATE DEFAULT NULL,                            -- KS 28.10.2011 Списано со сч. плат.
                              p_paytype                               IN     NUMBER DEFAULT 0,                           -- UDA 26.07.2012 По запросу I-00225239
                              p_subkindmessagedebet                   IN     dpmprop_dbt.t_subkindmessage%TYPE DEFAULT NULL,
                              p_subkindmessagecredit                  IN     dpmprop_dbt.t_subkindmessage%TYPE DEFAULT NULL,
                              p_uin                                   IN     VARCHAR2 DEFAULT NULL                        -- VDN 27.03.2014 C-28175
                              ) IS
        v_ex_errortext                               VARCHAR2 (1024);
        v_stat                                       NUMBER;
        v_pack_id                                    NUMBER;
        v_err_cnt                                    NUMBER;
        v_num_doc                                    VARCHAR2 (30);                                     -- генерация  номера документа для ББ вал бб и мемордера
        
        v_doc_kind                    dpmpaym_dbt.t_docKind%type;
        v_subkindmessagecredit        dpmprop_dbt.t_subkindmessage%TYPE; 
        
    BEGIN
        --  C-16618 zip_z.
        --  для всех видов  проводок фронт использует один набор передаваемых параметров. 
        --  Проводки выгружаются агентом, использующим процедуру с фиксированным набором параметров. Поэтому просто так использовать
        --  p_subkindmessagedebet / p_subkindmessagecredit не получается (добавление параметров - долго). 
        --  Вводим суррогатный DocKind.
        --  !!! todo: после перехода на IFX задавать подтип платежа явным образом, предусмотреть в формате обмена.
        
        IF p_doc_kind = C_DOCKIND_BANK_PAYM_VAL_BNK THEN
            v_doc_kind := C_DOCKIND_BANK_PAYM_VAL; -- валютный платёж банка
            v_subkindMessageCredit := WLD_COMMON.WLD_SUBKIND_PAYM_BANK_GEN; -- подтип платежа = общий банковский перевод
        else
            v_doc_kind := p_doc_kind;
        END IF;
        
        --25.12.2012 Golovkin запись параметров в лог
        usr_interface_logging.save_arguments (UPPER ('usr_payments'),
                                              UPPER ('insert_payment'),
                                              ku$_vcnt (p_payer_account, p_payer_name, p_payer_bic, p_payer_inn, p_payer_kpp, p_receiver_account,
                                                        p_receiver_name, p_receiver_bic, p_receiver_inn, p_receiver_kpp, p_oper, p_pack,
                                                        p_corschem, p_num_operation, p_num_doc, p_typedoc, p_usertypedoc, p_debet_sum,
                                                        p_kredit_sum, p_rate, p_ground, p_branch, p_priority, p_shifr, p_value_date,
                                                        p_doc_date, v_doc_kind, p_cash_symbs, p_fio_client, p_userfield1, p_userfield2, p_userfield3,
                                                        p_userfield4, p_accept_term, p_accept_date, p_pay_condition, p_accept_period,
                                                        p_creator_status, p_kbk_code, p_okato_code, p_ground_tax_doc, p_tax_period,
                                                        p_num_tax_doc, p_tax_date, p_tax_type, p_origin, p_skip_check_mask, p_check_exists,
                                                        p_run_operation, p_pack_mode, p_make_carry_from_payment, p_payment_id,
                                                        p_error, p_transaction_mode, p_doc_cur_iso, p_receiver_account_cur_iso, p_comiss_acc,
                                                        p_expense_transfer, p_vo_code, p_gtd, p_gtd_date, p_gtd_cur_iso, p_deal_passport,
                                                        p_deal_date, p_med_bankname, p_med_bic, p_receiver_bankname, p_receiver_bankcoracc,
                                                        p_receiver_bank_bic, p_ground_add, p_transfer_date, p_bosspost, p_bossfio,
                                                        p_paymentkind, p_autorun_operation, p_paperkind, p_paperseries, p_papernumber,
                                                        p_paperissueddate, p_paperissuer, p_payerchargeoffdate, p_paytype, 
                                                        p_subkindmessagedebet, v_subkindmessagecredit, p_uin
                                                        ));
                                                        
        IF ready_to_run_operation THEN
            delete_pack;
            ready_to_run_operation := FALSE;
        END IF;
                                                           
        --инициализация параметров по-умолчанию и заполнение обязательными параметрами
        nt_main_doc.EXTEND (1);

        --здесь возможна ошибка 06531: Reference to uninitialized collection
        --чтобы вылечить, нужно сделать:
        --alter system set event = '10943 trace name context level 2097152' scope=spfile;
        --и перестаротовать экзкмпляр
        IF NOT gv_prepared THEN
            --первый вызов пакета в сессии
            --здесь делается инициализация глобализмов
            init ();

            --если при инициализации были ошибки - вызывается исключение
            IF (nt_main_doc (gv_cnt).tech_parm_rec.ERROR_TEXT != usr_common.c_err_success) THEN
                RAISE e_error_due_single;
            END IF;

            gv_prepared     := TRUE;
        END IF;

        -- Golovkin 22.01.2012 I-00314776
        IF LENGTH (p_okato_code) > 11 THEN
            make_error_text (c_err_wrong_okato_code, nt_main_doc (gv_cnt).tech_parm_rec.ERROR_TEXT, 'p_okato_code = ' || p_okato_code);
            RAISE e_error_due_single;
        END IF;

        -- проверяем сумму платежа на наличие двух знаков после запятой
        IF (ROUND (p_debet_sum, 2) != p_debet_sum) THEN
            make_error_text (c_err_wrong_payment_sum, nt_main_doc (gv_cnt).tech_parm_rec.ERROR_TEXT, 'p_debet_sum = ' || p_debet_sum);
        END IF;

        IF (p_kredit_sum IS NOT NULL AND ROUND (p_kredit_sum, 2) != p_kredit_sum) THEN
            make_error_text (c_err_wrong_payment_sum, nt_main_doc (gv_cnt).tech_parm_rec.ERROR_TEXT, 'p_kredit_sum = ' || p_kredit_sum);
        END IF;

        -- Проверка дат
        --   if P_DOC_DATE is not null
        --      P_DOC_DATE:=trunc(P_DOC_DATE);
        --   end if;
        nt_main_doc (gv_cnt).carry_nt                                  := nt_carry ();
        nt_main_doc (gv_cnt).cash_symbols_nt                           := nt_cash_symbols ();
        --платежи накапливаются в коллекции для массовой и еденичной вставки
        nt_main_doc (gv_cnt).chapter                                   := usr_common.get_chapter (p_payer_account);
        nt_main_doc (gv_cnt).oper                                      := p_oper;
        nt_main_doc (gv_cnt).pack                                      := NVL (p_pack, 0);
        nt_main_doc (gv_cnt).num_operation                             := NVL (p_num_operation, 0);
        -- nt_main_doc (gv_cnt).num_doc := p_num_doc;
        nt_main_doc (gv_cnt).typedoc                                   := NVL (p_typedoc, pm_common.rsb_empty_string);
        nt_main_doc (gv_cnt).usertypedoc                               := NVL (p_usertypedoc, pm_common.rsb_empty_string);
        nt_main_doc (gv_cnt).debet_sum                                 := p_debet_sum;
        nt_main_doc (gv_cnt).kredit_sum                                := NVL (p_kredit_sum, p_debet_sum);
        nt_main_doc (gv_cnt).rate                                      := NVL (p_rate, 0);
        nt_main_doc (gv_cnt).department                                := p_branch;
        -- KS 16.01.2014 6 -> 5
        --nt_main_doc (gv_cnt).priority                                  := NVL (p_priority, 6);
        nt_main_doc (gv_cnt).priority                                  := NVL (p_priority, 5);
        if nt_main_doc (gv_cnt).priority = 6 then
          nt_main_doc (gv_cnt).priority := 5;
        end if;
        -- KS I-108932 RSB V6. Обработка документов из внешней системы UBS таможенная карта
        rsbsessiondata.m_curdate                                       := usr_common.getcurdate (NVL (p_branch, 1));
        v_num_doc                                                      := p_num_doc;

        -- LAO 06.11.2012 C-15287  Генерация номера документа для ББ мемордера и ББ вал
        IF (v_num_doc IS NULL OR v_num_doc = '') THEN
            IF v_doc_kind IN (c_dockind_bank_paym, c_dockind_bank_paym_val, c_dockind_memorder) THEN
                v_stat     := usr_get_numbpaym (p_date => rsbsessiondata.m_curdate, p_number => v_num_doc, p_msgerr => v_ex_errortext);

                IF v_stat > 1 THEN
                    v_num_doc     := NULL;
                    make_error_text (c_err_wrong_refer_num, nt_main_doc (gv_cnt).tech_parm_rec.ERROR_TEXT);
                ELSE
                    v_stat     := 0;
                END IF;
            END IF;
        END IF;

        nt_main_doc (gv_cnt).num_doc                                   := v_num_doc;


        IF (SUBSTR (p_receiver_account, 1, 5) = '70601' AND get_usertypeaccount (p_payer_account) LIKE '%G%' AND p_origin = 1900) THEN
            nt_main_doc (gv_cnt).pack         := 1;
            nt_main_doc (gv_cnt).shifr        := '17/ 6';
            nt_main_doc (gv_cnt).doc_date     := rsbsessiondata.m_curdate;
        ELSIF (SUBSTR (p_receiver_account, 1, 5) = '30232' AND get_usertypeaccount (p_payer_account) LIKE '%G%' AND p_origin = 1900) THEN
            nt_main_doc (gv_cnt).doc_date     := rsbsessiondata.m_curdate;
        ELSIF (get_usertypeaccount (p_payer_account) LIKE '%G%' AND SUBSTR (p_receiver_account, 1, 5) = '30110' AND p_origin = 1900) THEN
            nt_main_doc (gv_cnt).pack         := gv_ubs_pack;
            nt_main_doc (gv_cnt).shifr        := '17/ 1';
            nt_main_doc (gv_cnt).doc_date     := rsbsessiondata.m_curdate;
        ELSE
            nt_main_doc (gv_cnt).shifr     := NVL (p_shifr, '09/ 6');
        END IF;

        -- KS end
        nt_main_doc (gv_cnt).doc_date                                  := NVL (nt_main_doc (gv_cnt).doc_date, p_doc_date);
        nt_main_doc (gv_cnt).ground                                    := p_ground;
        --LAO 14.02.2012 I-00321949 внесена обработка SYSDATE переданного в параметр p_value_date
        nt_main_doc (gv_cnt).value_date                                := TRUNC (NVL (p_value_date, rsbsessiondata.m_curdate));

        -- KS 01.08.2011 Банковский ордер
        IF ( (SUBSTR (nt_main_doc (gv_cnt).shifr, 1, 2) = '17') AND (v_doc_kind = c_dockind_memorder) AND (nt_main_doc (gv_cnt).chapter = 1)) THEN
            nt_main_doc (gv_cnt).doc_kind     := c_dockind_memorder_bank_order;
        ELSE
            nt_main_doc (gv_cnt).doc_kind     := v_doc_kind;
        END IF;

        -- KS end
        --nt_main_doc (gv_cnt).doc_kind := v_doc_kind;
        nt_main_doc (gv_cnt).cash_symbs                                := p_cash_symbs;
        nt_main_doc (gv_cnt).corschem                                  := NVL (p_corschem, -1);
        nt_main_doc (gv_cnt).fio_client                                := NVL (p_fio_client, pm_common.rsb_empty_string);
        nt_main_doc (gv_cnt).userfield1                                := NVL (p_userfield1, pm_common.rsb_empty_string);
        nt_main_doc (gv_cnt).userfield2                                := NVL (p_userfield2, pm_common.rsb_empty_string);
        nt_main_doc (gv_cnt).userfield3                                := NVL (p_userfield3, pm_common.rsb_empty_string);
        nt_main_doc (gv_cnt).userfield4                                := NVL (p_userfield4, pm_common.rsb_empty_string);
        nt_main_doc (gv_cnt).accept_period                             := NVL (p_accept_period, 5);
        nt_main_doc (gv_cnt).accept_date                               := NVL (p_accept_date, usr_common.c_nulldate);
        nt_main_doc (gv_cnt).accept_term                               := NVL (p_accept_term, 0);
        nt_main_doc (gv_cnt).pay_condition                             := NVL (p_pay_condition, pm_common.rsb_empty_string);
        nt_main_doc (gv_cnt).creator_status                            := NVL (p_creator_status, pm_common.rsb_empty_string);
        nt_main_doc (gv_cnt).kbk_code                                  := NVL (p_kbk_code, pm_common.rsb_empty_string);
        nt_main_doc (gv_cnt).okato_code                                := NVL (p_okato_code, pm_common.rsb_empty_string);
        nt_main_doc (gv_cnt).ground_tax_doc                            := NVL (p_ground_tax_doc, pm_common.rsb_empty_string);
        nt_main_doc (gv_cnt).tax_period                                := NVL (p_tax_period, pm_common.rsb_empty_string);
        nt_main_doc (gv_cnt).num_tax_doc                               := NVL (p_num_tax_doc, pm_common.rsb_empty_string);
        nt_main_doc (gv_cnt).tax_date                                  := NVL (p_tax_date, pm_common.rsb_empty_string);
        nt_main_doc (gv_cnt).tax_type                                  := NVL (p_tax_type, pm_common.rsb_empty_string);
        nt_main_doc (gv_cnt).origin                                    := p_origin;

        nt_main_doc (gv_cnt).bosspost                                  := p_bosspost;
        nt_main_doc (gv_cnt).bossfio                                   := p_bossfio;

        -- KS 16.01.2013 По-умолчанию Н
        --nt_main_doc (gv_cnt).paymentkind                               := NVL (p_paymentkind, pm_common.rsb_empty_char);
        nt_main_doc (gv_cnt).paymentkind                               := NVL (p_paymentkind, 'Н');

        nt_main_doc (gv_cnt).paperkind                                 := NVL (p_paperkind, 0);                                                 -- KS 24.10.2011
        nt_main_doc (gv_cnt).paperseries                               := NVL (p_paperseries, pm_common.rsb_empty_string);                      -- KS 24.10.2011
        nt_main_doc (gv_cnt).papernumber                               := NVL (p_papernumber, pm_common.rsb_empty_string);                      -- KS 24.10.2011
        nt_main_doc (gv_cnt).paperissueddate                           := NVL (p_paperissueddate, usr_common.c_nulldate);                       -- KS 24.10.2011
        nt_main_doc (gv_cnt).paperissuer                               := NVL (p_paperissuer, pm_common.rsb_empty_string);                      -- KS 24.10.2011

        nt_main_doc (gv_cnt).payerchargeoffdate                        := NVL (p_payerchargeoffdate, nt_main_doc (gv_cnt).value_date); -- KS 28.10.2011 Списано со сч. плат

        --
        IF p_payer_kpp IS NULL THEN
            nt_main_doc (gv_cnt).payer_pi_rec.inn     := p_payer_inn;
        ELSE
            nt_main_doc (gv_cnt).payer_pi_rec.inn     := p_payer_inn || '/' || p_payer_kpp;
        END IF;

        IF p_receiver_kpp IS NULL THEN
            nt_main_doc (gv_cnt).receiver_pi_rec.inn     := p_receiver_inn;
        ELSE
            nt_main_doc (gv_cnt).receiver_pi_rec.inn     := p_receiver_inn || '/' || p_receiver_kpp;
        END IF;

        nt_main_doc (gv_cnt).payer_pi_rec.account                      := p_payer_account;
        nt_main_doc (gv_cnt).payer_pi_rec.client_name                  := p_payer_name;
        nt_main_doc (gv_cnt).payer_pi_rec.client_id                    := -1;
        nt_main_doc (gv_cnt).payer_pi_rec.bank_code                    := NVL (p_payer_bic, pm_common.rsb_empty_string);
        nt_main_doc (gv_cnt).payer_pi_rec.bank_id                      := 0;

        nt_main_doc (gv_cnt).receiver_pi_rec.account                   := p_receiver_account;
        nt_main_doc (gv_cnt).receiver_pi_rec.client_name               := p_receiver_name;
        nt_main_doc (gv_cnt).receiver_pi_rec.client_id                 := -1;

        --TAM 02.07.2013 не важно соответсвие коду получателя, он мб пустым, и тогда p_receiver_bank_bic <> p_receiver_bic ложно.
        IF p_receiver_bank_bic IS NULL THEN 
            nt_main_doc (gv_cnt).receiver_pi_rec.bank_code := NVL (p_receiver_bic, pm_common.rsb_empty_string);
        ELSE
            IF p_receiver_bic is null THEN
                /* EVG 27/11/2012 В p_receiver_bank_bic может передаваться заглушка XXXXXXXXXXXX в случае, когда передаётся только БИК клиента. Тогда заполнять bank_code не нужно. */
                IF p_receiver_bank_bic <> LPAD (pm_common.set_char, 12, pm_common.set_char) THEN
                    nt_main_doc (gv_cnt).receiver_pi_rec.bank_code     := NVL (p_receiver_bank_bic, pm_common.rsb_empty_string);
                END IF;
                nt_main_doc (gv_cnt).receiver_pi_rec.client_code     := NVL (p_receiver_bic, pm_common.rsb_empty_string); 
            ELSE
                IF p_receiver_bank_bic <> p_receiver_bic THEN
                    IF p_receiver_bank_bic <> LPAD (pm_common.set_char, 12, pm_common.set_char) THEN
                        nt_main_doc (gv_cnt).receiver_pi_rec.bank_code     := NVL (p_receiver_bank_bic, pm_common.rsb_empty_string);
                    END IF;
                    nt_main_doc (gv_cnt).receiver_pi_rec.client_code     := NVL (p_receiver_bic, pm_common.rsb_empty_string);
                ELSE 
                    nt_main_doc (gv_cnt).receiver_pi_rec.bank_code := NVL (p_receiver_bic, pm_common.rsb_empty_string);
                END IF;
            END IF;         
        END IF;

        nt_main_doc (gv_cnt).receiver_pi_rec.bank_id                   := 0;

        nt_main_doc (gv_cnt).receiver_pi_rec.bank_name                 := NVL (p_receiver_bankname, pm_common.rsb_empty_string);
        nt_main_doc (gv_cnt).receiver_pi_rec.coracc                    := NVL (p_receiver_bankcoracc, pm_common.rsb_empty_string);
        nt_main_doc (gv_cnt).receiver_pi_rec.med_bank_code             := NVL (p_med_bic, pm_common.rsb_empty_string);
        nt_main_doc (gv_cnt).receiver_pi_rec.med_bank_name             := NVL (p_med_bankname, pm_common.rsb_empty_string);
        nt_main_doc (gv_cnt).receiver_pi_rec.cur_iso                   := NVL (p_receiver_account_cur_iso, pm_common.rsb_empty_string);

        nt_main_doc (gv_cnt).tech_parm_rec.is_our_payer                := FALSE;
        nt_main_doc (gv_cnt).tech_parm_rec.is_our_receiver             := FALSE;
        nt_main_doc (gv_cnt).tech_parm_rec.check_exists                := (NVL (p_check_exists, 0) = 1);
        nt_main_doc (gv_cnt).tech_parm_rec.run_operation               := (NVL (p_run_operation, 0) = 1);
        nt_main_doc (gv_cnt).tech_parm_rec.autorun_operation           := (NVL (p_autorun_operation, 0) = 1);
        nt_main_doc (gv_cnt).tech_parm_rec.make_carry_from_payment     := (NVL (p_make_carry_from_payment, 0) = 1);
        nt_main_doc (gv_cnt).tech_parm_rec.in_transaction              := (NVL (p_transaction_mode, 0) = 1);
        nt_main_doc (gv_cnt).tech_parm_rec.pack_mode                   := NVL (p_pack_mode, 0);


        nt_main_doc (gv_cnt).doc_cur_iso                               := NVL (p_doc_cur_iso, pm_common.rsb_empty_string);
        nt_main_doc (gv_cnt).comiss_acc                                := NVL (p_comiss_acc, pm_common.rsb_empty_string);
        nt_main_doc (gv_cnt).comiss_fiid                               := 0;
        nt_main_doc (gv_cnt).expense_transfer                          := NVL (p_expense_transfer, pm_common.rsb_empty_string);
        nt_main_doc (gv_cnt).vo_code                                   := NVL (p_vo_code, pm_common.rsb_empty_string);
        nt_main_doc (gv_cnt).gtd                                       := NVL (p_gtd, pm_common.rsb_empty_string);
        nt_main_doc (gv_cnt).gtd_date                                  := NVL (p_gtd_date, usr_common.c_nulldate);
        nt_main_doc (gv_cnt).gtd_cur_iso                               := NVL (p_gtd_cur_iso, pm_common.rsb_empty_string);
        nt_main_doc (gv_cnt).deal_passport                             := NVL (p_deal_passport, pm_common.rsb_empty_string);
        nt_main_doc (gv_cnt).deal_date                                 := NVL (p_deal_date, usr_common.c_nulldate);
        nt_main_doc (gv_cnt).ground_add                                := NVL (p_ground_add, pm_common.rsb_empty_string);
        nt_main_doc (gv_cnt).transfer_date                             := NVL (p_transfer_date, nt_main_doc (gv_cnt).value_date);

        nt_main_doc (gv_cnt).paytype                                   := NVL (p_paytype, 0);                            -- UDA 26.07.2012 По запросу I-00225239

        IF p_subkindmessagedebet IS NOT NULL THEN
            nt_main_doc (gv_cnt).subkindmessagedebet     := p_subkindmessagedebet;
        END IF;

        IF v_subkindmessagecredit IS NOT NULL THEN
            nt_main_doc (gv_cnt).subkindmessagecredit     := v_subkindmessagecredit;
        END IF;        
        
        nt_main_doc (gv_cnt).uin                                     := NVL(p_uin, pm_common.rsb_empty_string);               -- VDN 27.03.2014 C-28175  


        --разбор маски проверок, инициализируется рекорд check_rules
        parse_check_rules (p_skip_check_mask);

        IF nt_main_doc (gv_cnt).tech_parm_rec.run_operation AND nt_main_doc (gv_cnt).num_operation = 0 THEN
            make_error_text (c_err_opt_notset, nt_main_doc (gv_cnt).tech_parm_rec.ERROR_TEXT);
        END IF;

        --проверка на допустимый вид документа для вставки
        IF v_doc_kind NOT IN
               (c_dockind_cash_in,
                c_dockind_cash_out,
                c_dockind_cash_inout,
                c_dockind_memorder,
                c_dockind_multycarry,
                c_dockind_bank_paym,
                c_dockind_bank_order,
                c_dockind_memorder_bank_order,                                                                                 -- KS 29.07.2011 Банковский ордер
                c_dockind_client_paym,
                c_dockind_client_paym_val,
                c_dockind_client_paym_b,
                c_dockind_client_paym_k,
                c_dockind_client_paym_s,
                c_dockind_bank_paym_val,
                c_dockind_client_order,
                c_dockind_client_cash_in,
                c_dockind_client_cash_out,
                c_dockind_external_in                                                                                                     -- KS 01.06.2011 C-731
                                     ) THEN
            make_error_text (c_err_dockind_not_supp, nt_main_doc (gv_cnt).tech_parm_rec.ERROR_TEXT);
        --проверка на допустимый вид документа для автообработки
        ELSIF     nt_main_doc (gv_cnt).tech_parm_rec.run_operation
              AND v_doc_kind NOT IN
                      (c_dockind_cash_in,
                       c_dockind_cash_out,
                       c_dockind_cash_inout,
                       c_dockind_memorder,
                       c_dockind_memorder_bank_order,                                                                          -- KS 29.07.2011 Банковский ордер
                       c_dockind_multycarry,
                       c_dockind_client_cash_in,
                       c_dockind_client_cash_out,
                       c_dockind_bank_paym,
                       c_dockind_external_in                                                                                                    -- KS 24.06.2011
                                            ) THEN
            make_error_text (c_err_dockind_not_supp_run, nt_main_doc (gv_cnt).tech_parm_rec.ERROR_TEXT);
        --проверка совместимости режима работы в транзакции и автовыполнение операции
        ELSIF nt_main_doc (gv_cnt).tech_parm_rec.run_operation AND nt_main_doc (gv_cnt).tech_parm_rec.in_transaction THEN
            make_error_text (c_err_trn_mode, nt_main_doc (gv_cnt).tech_parm_rec.ERROR_TEXT);
        -- KS 15.04.2011 Проверим операциониста
        ELSIF NOT isvalidoper (nt_main_doc (gv_cnt).oper) THEN
            make_error_text (c_err_oper_invalid, nt_main_doc (gv_cnt).tech_parm_rec.ERROR_TEXT, nt_main_doc (gv_cnt).oper);
        END IF;

        IF nt_main_doc (gv_cnt).tech_parm_rec.ERROR_TEXT <> usr_common.c_err_success THEN
            IF nt_main_doc (gv_cnt).tech_parm_rec.pack_mode <> 0 AND gv_cnt = 1 THEN
                RAISE e_error_due_pack_first;
            ELSIF nt_main_doc (gv_cnt).tech_parm_rec.pack_mode <> 0 AND gv_cnt > 1 THEN
                RAISE e_error_due_pack_next;
            ELSE
                RAISE e_error_due_single;
            END IF;
        END IF;

        -- ID пакета переходит к следующему документу
        -- для не пакетного режима так же определяется ID пакета,
        -- т.к. один документ в пакете с запуском операции - так же пакетный режим
        IF    nt_main_doc (gv_cnt).tech_parm_rec.pack_mode IN (1, 2)
           OR (nt_main_doc (gv_cnt).tech_parm_rec.pack_mode = 0 AND nt_main_doc (gv_cnt).tech_parm_rec.run_operation) THEN
            IF gv_cnt = 1                                                         --определеяется ID пакета при заполнении первого (или единственного) документа
                         THEN
                SELECT usr_payment_packs_seq.NEXTVAL INTO nt_main_doc (gv_cnt).tech_parm_rec.pack_id FROM DUAL;
            ELSIF gv_cnt > 1 THEN
                nt_main_doc (gv_cnt).tech_parm_rec.pack_id     := nt_main_doc (gv_cnt - 1).tech_parm_rec.pack_id;
            END IF;
        ELSIF nt_main_doc (gv_cnt).tech_parm_rec.pack_mode = 0 THEN
            nt_main_doc (gv_cnt).tech_parm_rec.pack_id     := 0;
        END IF;

        complete_params (nt_main_doc (gv_cnt));

        -- KS 23.05.2011 Если включен дебаг-режим
        IF c_mode_debug THEN
            DUMP (nt_main_doc (gv_cnt));
        END IF;

        IF nt_main_doc (gv_cnt).tech_parm_rec.check_exists AND write_log (nt_main_doc (gv_cnt)) = c_log_doc_exists THEN
            --документ дублируется
            --Gurin S. 09.08.2013 C-22197 
            IF nt_main_doc (gv_cnt).origin = 2100 THEN
                make_error_text (c_err_doc_exists || '. Существует документ: № ' || nt_main_doc (gv_cnt).num_doc
                                                  || ', плательщик: ' || nt_main_doc (gv_cnt).payer_pi_rec.account
                                                  || ', сумма: ' || nt_main_doc (gv_cnt).debet_sum
                                                  || ', операционист: ' || nt_main_doc (gv_cnt).oper
                                                  || ', дата документа: ' || to_char(nt_main_doc (gv_cnt).doc_date,'dd.mm.yyyy'),
                nt_main_doc (gv_cnt).tech_parm_rec.ERROR_TEXT);
            ELSE
                make_error_text (c_err_doc_exists, nt_main_doc (gv_cnt).tech_parm_rec.ERROR_TEXT);
            END IF;
        END IF;

        p_error := nt_main_doc (gv_cnt).tech_parm_rec.ERROR_TEXT;

        IF (p_error != usr_common.c_err_success)                                                                             --обработка ошибок в составе пакета
                                                THEN
            IF nt_main_doc (gv_cnt).tech_parm_rec.pack_mode = 0 THEN
                RAISE e_error_due_single;
            ELSIF nt_main_doc (gv_cnt).tech_parm_rec.pack_mode IN (1, 2) THEN
                --если ошибка появилась впервые, устанавливается флаг наличия ошибки в пакете
                IF NOT v_err_in_pack THEN
                    v_err_in_pack     := TRUE;

                    IF NOT nt_main_doc (gv_cnt).tech_parm_rec.run_operation THEN
                        --для режима с запуском операции исключение не вызывается
                        -- т.к. в процедуре запуска операции есть свой обработчик ошибок в пакете
                        --если конец пакета, то сбрасывется флаг ошибки
                        IF nt_main_doc (gv_cnt).tech_parm_rec.pack_mode = 2 THEN
                            v_err_in_pack     := FALSE;
                        END IF;

                        RAISE e_error_due_pack_first;
                    END IF;
                ELSE
                    --если в пакете уже есть ошибка, то очередной документ не обрабатывается
                    IF NOT nt_main_doc (gv_cnt).tech_parm_rec.run_operation THEN
                        --если конец пакета, то сбрасывется флаг ошибки
                        IF nt_main_doc (gv_cnt).tech_parm_rec.pack_mode = 2 THEN
                            v_err_in_pack     := FALSE;
                        END IF;

                        RAISE e_error_due_pack_next;
                    END IF;
                END IF;
            END IF;
        ELSE
            IF nt_main_doc (gv_cnt).tech_parm_rec.pack_mode IN (1, 2) THEN
                --если в пакете уже есть ошибка но текущий документ нормальный
                --, то очередной документ не обрабатывается
                IF NOT nt_main_doc (gv_cnt).tech_parm_rec.run_operation AND v_err_in_pack THEN
                    --если конец пакета, то сбрасывется флаг ошибки
                    IF nt_main_doc (gv_cnt).tech_parm_rec.pack_mode = 2 THEN
                        v_err_in_pack     := FALSE;
                    END IF;

                    RAISE e_error_due_pack_next;
                END IF;
            END IF;
        END IF;


        p_payment_id                                                   := NVL (nt_main_doc (gv_cnt).payment_id, 0);
        fill_nt_tables (nt_main_doc (gv_cnt));

        IF nt_main_doc (gv_cnt).tech_parm_rec.ERROR_TEXT != usr_common.c_err_success THEN
            RAISE e_error_due_single;
        END IF;

        IF nt_main_doc (gv_cnt).tech_parm_rec.pack_mode = 0 OR (nt_main_doc (gv_cnt).tech_parm_rec.pack_mode = 2 AND NOT v_err_in_pack) THEN
            IF NOT nt_main_doc (gv_cnt).tech_parm_rec.run_operation THEN
                create_payments (p_run_operation => FALSE, p_in_transact => nt_main_doc (gv_cnt).tech_parm_rec.in_transaction);
            ELSIF (nt_main_doc (gv_cnt).tech_parm_rec.autorun_operation) THEN
                IF nt_main_doc (gv_cnt).tech_parm_rec.pack_mode = 0 THEN
                    run_operation (v_pack_id, v_err_cnt, p_error);
                ELSE
                    make_error_text (c_err_notsingle, nt_main_doc (gv_cnt).tech_parm_rec.ERROR_TEXT);
                END IF;
            ELSE
                ready_to_run_operation := TRUE;    
            END IF;
        ELSIF nt_main_doc (gv_cnt).tech_parm_rec.pack_mode = 2 AND v_err_in_pack THEN
            IF NOT nt_main_doc (gv_cnt).tech_parm_rec.run_operation THEN
                delete_pack;                                                                                                --удаляется пакет, содержащий ошибку
            END IF;

            v_err_in_pack     := FALSE;                                                                                      --сбрасывается флаг ошибки в пакете
        ELSIF nt_main_doc (gv_cnt).tech_parm_rec.pack_mode = 1 THEN
            --если режим работы - накопление пакета, то увеличивается счетчик
            gv_cnt     := gv_cnt + 1;
        END IF;
    EXCEPTION
        WHEN e_error_due_single THEN
            p_error          := 'ошибка создания документа: ' || CHR (10) || nt_main_doc (gv_cnt).tech_parm_rec.ERROR_TEXT;
            p_payment_id     := 0;
            rollback_trn (nt_main_doc (gv_cnt).tech_parm_rec.in_transaction, p_error);
        WHEN e_error_due_pack_first THEN
            p_error          :=
                'ошибка создания документа: ' || CHR (10) || nt_main_doc (gv_cnt).tech_parm_rec.ERROR_TEXT || CHR (10) ||
                'обработка пакета прервана';
            p_payment_id     := 0;
            rollback_trn (nt_main_doc (gv_cnt).tech_parm_rec.in_transaction, p_error);
        WHEN e_error_due_pack_next THEN
            p_error          := 'обработка пакета была прервана';
            p_payment_id     := 0;
            rollback_trn (nt_main_doc (gv_cnt).tech_parm_rec.in_transaction, p_error);
        WHEN OTHERS THEN
            p_error          :=
                'ошибка создания документа: ' || CHR (10) || DBMS_UTILITY.format_error_stack || DBMS_UTILITY.format_error_backtrace;

            p_payment_id     := 0;
            rollback_trn (nt_main_doc (gv_cnt).tech_parm_rec.in_transaction, p_error);
    END;

    PROCEDURE start_operation (p_dockind NUMBER, p_oper NUMBER) IS
        lv_stat                                      NUMBER;
    BEGIN
        lv_stat     := rsbemoperation.opr_startoperation ();

        IF lv_stat <> 0 THEN
            v_last_error     := 'ошибка при старте операции, код' || lv_stat;
            RAISE e_error_start_oper;
        END IF;

        --установка статусов первичкм
        IF p_dockind = c_dockind_memorder THEN
            lv_stat      :=
                bb_memorder.changememorderstatus (0,
                                                  bb_memorder.cb_doc_state_working,
                                                  0,
                                                  0);
        ELSIF p_dockind IN (c_dockind_cash_in, c_dockind_cash_out, c_dockind_cash_inout, c_dockind_client_cash_in, c_dockind_client_cash_out) THEN
            lv_stat      :=
                rsb_cashord.changecashordstatus (0,
                                                 rsb_cashord.stat_cash_order_open,
                                                 0,
                                                 0);
        ELSIF p_dockind = c_dockind_multycarry THEN
            lv_stat      :=
                bb_multydoc.changemultydocstatus (0,
                                                  bb_multydoc.mcdoc_status_open,
                                                  0,
                                                  0);
        ELSIF p_dockind = c_dockind_bank_paym THEN
            lv_stat      :=
                bb_bankpaym.changebankpaymstatus (0,
                                                  bb_bankpaym.memorder_status_open,
                                                  0,
                                                  0);
        END IF;

        IF lv_stat <> 0 THEN
            v_last_error     := 'ошибка при смене статуса документа, код' || lv_stat;
            RAISE e_error_start_oper;
        END IF;

        --установка статусов платежа
        IF p_dockind != c_dockind_external_in THEN                                                            -- KS 08.06.2011 Для внешних входящих оставим 2990
            lv_stat      :=
                pm_common.changepaymstatus (0,
                                            1000,
                                            0,
                                            0,
                                            p_oper);

            IF lv_stat != 0 THEN
                v_last_error     := 'ошибка при изменении статуса платежа, код ' || lv_stat;
                RAISE e_error_start_oper;
            END IF;
        END IF;

        lv_stat      :=
            pm_common.changepmpropstatus (0,
                                          NULL,
                                          pm_common.pm_finished,
                                          NULL);

        IF lv_stat != 0 THEN
            v_last_error     := 'ошибка при изменении внешнего статуса платежа, код ' || lv_stat;
            RAISE e_error_start_oper;
        END IF;

        --установка статусов операции
        lv_stat     := rsbemoperation.opr_setoprstatusvalue (291, 2);                                                                 --Состояние платежа=Открыт

        IF lv_stat != 0 THEN
            v_last_error     := 'ошибка при установке статуса операции, код ' || lv_stat;
            RAISE e_error_start_oper;
        END IF;
    END;

    PROCEDURE reg_carry_ex (p_payment_id                               NUMBER,
                            p_operation_id                             NUMBER,
                            p_carrynum                                 NUMBER,
                            -- KS 10.12.2013 Адаптация под 31ю сборку 
                            --p_fiid                                     NUMBER,
                            p_fiid_payer                               NUMBER,
                            p_fiid_receiver                            NUMBER,
                            p_chapter                                  NUMBER,
                            p_payer_account                            VARCHAR2,
                            p_receiver_account                         VARCHAR2,
                            p_sum                                      NUMBER,
                            p_sum_payer                                NUMBER,
                            p_sum_receiver                             NUMBER,
                            p_date_carry                               DATE,
                            p_oper                                     NUMBER,
                            p_pack                                     NUMBER,
                            p_num_doc                                  VARCHAR2,
                            p_ground                                   VARCHAR2,
                            p_department                               NUMBER,
                            p_vsp                                      NUMBER,
                            p_kind_oper                                VARCHAR2,
                            p_shifr_oper                               VARCHAR2,
                            p_error_text                               VARCHAR2
                            --p_typedoc                               IN VARCHAR2 DEFAULT NULL,
                            --p_usertypedoc                           IN VARCHAR2 DEFAULT NULL
                            ) IS
    BEGIN
        INSERT INTO usr_pmdocs (acctrnid,
                                paymentid,
                                operationid,
                                carrynum,
                                -- KS 10.12.2013 Адаптация под 31ю сборку 
                                --fiid, 
                                fiid_payer, 
                                fiid_receiver,
                                chapter,
                                payer_account,
                                receiver_account,
                                sum,
                                -- KS 11.12.2013 Адаптация под 31ю сборку
                                sum_payer,
                                sum_receiver,
                                date_carry,
                                oper,
                                pack,
                                num_doc,
                                ground,
                                department,
                                vsp,
                                kind_oper,
                                shifr_oper,
                                ERROR_TEXT)
             VALUES (0,
                     p_payment_id,
                     p_operation_id,
                     p_carrynum,
                     -- KS 10.12.2013 Адаптация под 31ю сборку
                     --p_fiid,
                     p_fiid_payer,
                     p_fiid_receiver,
                     p_chapter,
                     p_payer_account,
                     p_receiver_account,
                     p_sum,
                     -- KS 11.12.2013 Адаптация под 31ю сборку
                     p_sum_payer,
                     p_sum_receiver,
                     p_date_carry,
                     p_oper,
                     p_pack,
                     p_num_doc,
                     p_ground,
                     p_department,
                     p_vsp,
                     p_kind_oper,
                     p_shifr_oper,
                     p_error_text);

        COMMIT;
    END;

    PROCEDURE add_deffered_carry (p_payment_id                                NUMBER,
                                  p_carrynum                                  NUMBER,
                                  p_payer_account                             VARCHAR2,
                                  p_receiver_account                          VARCHAR2,
                                  p_sum                                       NUMBER,
                                  p_date_carry                                DATE,
                                  p_oper                                      NUMBER,
                                  p_pack                                      NUMBER,
                                  p_num_doc                                   VARCHAR2,
                                  p_ground                                    VARCHAR2,
                                  p_kind_oper                                 VARCHAR2,
                                  p_shifr_oper                                VARCHAR2,
                                  p_department                                NUMBER DEFAULT NULL,
                                  p_branch                                    NUMBER DEFAULT NULL,
                                  p_typedoc                                   VARCHAR2 DEFAULT NULL,
                                  p_usertypedoc                               VARCHAR2 DEFAULT NULL,
                                  p_error                                 OUT VARCHAR2,
                                  -- KS 11.12.2013 Адаптация под 31ю сборку 
                                  p_sum_payer                                 NUMBER DEFAULT NULL,
                                  p_sum_receiver                              NUMBER DEFAULT NULL) IS
        v_operdprt                                   NUMBER;
        v_stepCarryExists                            NUMBER := 0;
        e_stepCarryExists                            EXCEPTION;
    BEGIN
        usr_interface_logging.save_arguments (UPPER ('usr_payments'),
                                              UPPER ('add_deffered_carry'),
                                              ku$_vcnt (p_payment_id,
                                                        p_carrynum,
                                                        p_payer_account,
                                                        p_receiver_account,
                                                        p_sum,
                                                        p_date_carry,
                                                        p_oper,
                                                        p_pack,
                                                        p_num_doc,
                                                        p_ground,
                                                        p_kind_oper,
                                                        p_shifr_oper,
                                                        p_department,
                                                        p_branch,
                                                        p_typedoc,
                                                        p_usertypedoc,
                                                        p_error,
                                                        p_sum_payer,
                                                        p_sum_receiver));

        usr_common.init;
        p_error     := usr_common.c_err_success;

        -- 13.08.2013 Golovkin R-230736 проверка на шаг Зачисление (инициатор-Фронт)
        BEGIN
            SELECT   1
              INTO   v_stepCarryExists
              FROM   doprstep_dbt st, doproper_dbt op, dpmpaym_dbt pm
             WHERE       op.t_documentid = LPAD (pm.t_paymentid, 34, '0')
                     AND st.t_id_operation = op.t_id_operation
                     AND op.t_dockind = pm.t_dockind
                     AND pm.t_paymentid = p_payment_id
                     AND st.t_blockid = 11000120
                     AND st.t_symbol = 'n'
                     AND st.t_isexecute = 'X'
                     AND NOT EXISTS -- 19.08.2013 Golovkin R-232947 Ошибку возвращаем только в случае, если шаг закрыт без проводок
                           (SELECT   *
                              FROM   doprdocs_dbt opdoc
                             WHERE       opdoc.t_id_operation = op.t_id_operation
                                     AND opdoc.t_dockind      = 1);
        EXCEPTION WHEN OTHERS THEN NULL;
        END;

        IF v_stepCarryExists = 1 THEN
            RAISE e_stepCarryExists;
        END IF; 

        IF p_carrynum = 1 THEN
            --если приходит первая проводка, удаляется весь предыдущий набор
            DELETE FROM usr_pmdocs
                  WHERE paymentid = p_payment_id;
        END IF;

        IF p_department IS NULL THEN
            --если подразделение не опеределено - ищется по операционисту
            SELECT t_codedepart
              INTO v_operdprt
              FROM dperson_dbt
             WHERE t_oper = p_oper;
        END IF;

        reg_carry_ex (p_payment_id,
                      0,
                      p_carrynum,
                      -- KS 10.12.2013 Адаптация под 31ю сборку 
                      --get_carry_fiid (p_payer_account, p_receiver_account),
                      usr_common.get_fiid (p_payer_account),
                      usr_common.get_fiid (p_receiver_account),
                      usr_common.get_chapter (p_payer_account),
                      p_payer_account,
                      p_receiver_account,
                      p_sum,
                      -- KS 11.12.2013 Адаптация под 31ю сборку 
                      nvl(p_sum_payer,    case usr_common.get_fiid (p_payer_account) when usr_common.get_fiid (p_receiver_account) then p_sum else 0 end),
                      nvl(p_sum_receiver, case usr_common.get_fiid (p_payer_account) when usr_common.get_fiid (p_receiver_account) then p_sum else 0 end),
                      p_date_carry,
                      p_oper,
                      p_pack,
                      p_num_doc,
                      p_ground,
                      NVL (p_branch, NVL (p_department, v_operdprt)),
                      NVL (p_department, v_operdprt),
                      p_kind_oper,
                      p_shifr_oper,
                      'проводка ожидает выполнения');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_error     := 'операционист ' || p_oper || ' не найден в справочнике';
        WHEN DUP_VAL_ON_INDEX THEN
            p_error     := 'проводка с номером ' || p_carrynum || ' уже существует';
        WHEN e_stepCarryExists THEN             
            p_error     := 'Документ уже подтвержден. Проводки не выгружены';        
        WHEN OTHERS THEN
            p_error     := 'ошибка регистрации проводки ' || DBMS_UTILITY.format_error_stack || DBMS_UTILITY.format_error_backtrace;
    END;

    PROCEDURE add_carry (p_payment_id                                NUMBER,
                         p_payer_account                             VARCHAR2 DEFAULT NULL,
                         p_receiver_account                          VARCHAR2 DEFAULT NULL,
                         p_ground                                    VARCHAR2 DEFAULT NULL,
                         p_sum                                       NUMBER DEFAULT NULL,
                         p_pack                                      NUMBER DEFAULT NULL,
                         p_num_doc                                   VARCHAR2 DEFAULT NULL,
                         p_error                                 OUT VARCHAR2,
                         -- KS 11.12.2013 Адаптация под 31ю сборку 
                         p_sum_payer                                 NUMBER DEFAULT NULL,
                         p_sum_receiver                              NUMBER DEFAULT NULL) IS
        v_carry_num                                  PLS_INTEGER;
        v_carry_added                                BOOLEAN;
        v_pay_fiid                                   NUMBER;
        v_rec_fiid                                   NUMBER;
        v_current_sum                                NUMBER;
    BEGIN
        usr_interface_logging.save_arguments (UPPER ('usr_payments'),
                                              UPPER ('add_carry'),
                                              ku$_vcnt (p_payment_id,
                                                        p_payer_account,
                                                        p_receiver_account,
                                                        p_ground,
                                                        p_sum,
                                                        p_pack,
                                                        p_num_doc,
                                                        p_error,
                                                        p_sum_payer,
                                                        p_sum_receiver));

        p_error           := usr_common.c_err_success;
        v_carry_added     := FALSE;

        IF nt_main_doc.COUNT > 0 THEN
            FOR i IN nt_main_doc.FIRST .. nt_main_doc.LAST LOOP
                IF p_payment_id = nt_main_doc (i).payment_id AND NOT nt_main_doc (i).tech_parm_rec.make_carry_from_payment THEN
                    v_carry_added     := TRUE;
                    --добавляется еще одна проводка
                    --но сначала проверка на превышение суммы платежа
                    v_current_sum     := 0;

                    IF nt_main_doc (i).carry_nt.COUNT > 0 THEN
                        FOR x IN nt_main_doc (i).carry_nt.FIRST .. nt_main_doc (i).carry_nt.LAST LOOP
                            IF nt_main_doc (i).carry_nt (x).chapter = 1 AND usr_common.get_chapter (p_payer_account) = 1 THEN
                                --подсчитывается только баланс
                                v_current_sum     := v_current_sum + nt_main_doc (i).carry_nt (x).SUM + p_sum;
                            END IF;
                        END LOOP;
                    ELSE                                                                                                                       --первая проводка
                        IF usr_common.get_chapter (p_payer_account) = 1 THEN
                            v_current_sum     := p_sum;
                        END IF;
                    END IF;

                    IF v_current_sum > nt_main_doc (i).debet_sum AND nt_main_doc (i).doc_kind <> c_dockind_multycarry AND nt_main_doc (i).chapter = 1 THEN
                        p_error     := 'сумма проводок превышает сумму документа';
                        --удаляется ошибочный документ
                        nt_main_doc.delete (i);
                        EXIT;
                    ELSE
                        v_carry_num                                                 := nt_main_doc (i).carry_nt.COUNT + 1;
                        nt_main_doc (i).carry_nt.EXTEND (1);
                        nt_main_doc (i).carry_nt (v_carry_num).department           := nt_main_doc (i).department;
                        nt_main_doc (i).carry_nt (v_carry_num).payer_account        := NVL (p_payer_account, nt_main_doc (i).payer_pi_rec.account);
                        nt_main_doc (i).carry_nt (v_carry_num).receiver_account     := NVL (p_receiver_account, nt_main_doc (i).receiver_pi_rec.account);
                        nt_main_doc (i).carry_nt (v_carry_num).chapter              :=
                            usr_common.get_chapter (nt_main_doc (i).carry_nt (v_carry_num).payer_account);
                        -- KS 10.12.2013 Адаптация под 31ю сборку 
                        --nt_main_doc (i).carry_nt (v_carry_num).fiid                 := get_carry_fiid (p_payer_account, p_receiver_account);
                        nt_main_doc (i).carry_nt (v_carry_num).fiid_payer           := usr_common.get_fiid (p_payer_account);
                        nt_main_doc (i).carry_nt (v_carry_num).fiid_receiver        := usr_common.get_fiid (p_receiver_account);
                        nt_main_doc (i).carry_nt (v_carry_num).ground               := NVL (p_ground, nt_main_doc (i).ground);
                        nt_main_doc (i).carry_nt (v_carry_num).SUM                  := NVL (p_sum, nt_main_doc (i).debet_sum);
                        -- KS 10.12.2013 Адаптация под 31ю сборку 
                        nt_main_doc (i).carry_nt (v_carry_num).sum_payer            := NVL (p_sum_payer, nt_main_doc (i).debet_sum);
                        nt_main_doc (i).carry_nt (v_carry_num).sum_receiver         := NVL (p_sum_receiver, nt_main_doc (i).kredit_sum);
                        nt_main_doc (i).carry_nt (v_carry_num).pack                 := NVL (p_pack, nt_main_doc (i).pack);
                        nt_main_doc (i).carry_nt (v_carry_num).num_doc              := NVL (p_num_doc, nt_main_doc (i).num_doc);
                        nt_main_doc (i).carry_nt (v_carry_num).error                := 'проводка ожидает выполнения';
                        EXIT;
                    END IF;
                END IF;
            END LOOP;

            IF NOT v_carry_added THEN
                p_error     := 'не найден платеж PaymentID=' || p_payment_id;
            END IF;
        ELSE
            p_error     := 'нет платежей для исполнения';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_error      :=
                'ошибка при добавления проводки: ' || DBMS_UTILITY.format_error_stack || DBMS_UTILITY.format_error_backtrace;
    END;

    PROCEDURE run_operation (p_pack_id OUT NUMBER, p_error_count OUT NUMBER, p_error OUT VARCHAR2) IS
        v_log_stat                                   PLS_INTEGER;
        v_dockind                                    NUMBER;
        v_oper                                       NUMBER;
        v_msg                                        VARCHAR2 (4000);
        v_stat                                       NUMBER;
        v_ret_pipe                                   VARCHAR2 (64);
        v_message                                    VARCHAR2 (4000);
        v_errtext                                    VARCHAR2 (1024);
        v_carry_count                                PLS_INTEGER := 0;
        v_doc_sum                                    NUMBER;
        v_is_our_receiver                            BOOLEAN;
        v_is_schem                                   BOOLEAN;
        v_paymentid                                  NUMBER;
        v_carrynum                                   NUMBER;

        PROCEDURE reg_carry (doc main_doc_rec, carry tp_carry_rec, carrynum NUMBER) IS
            lv_kindop                                    VARCHAR2 (2);
        BEGIN
            IF INSTR (doc.shifr, '/') = 0 THEN
                lv_kindop     := ' 6';
            ELSE
                lv_kindop     := SUBSTR (doc.shifr, INSTR (doc.shifr, '/') + 1);
            END IF;

            reg_carry_ex (doc.payment_id,
                          doc.operation_id,
                          carrynum,
                          -- KS 10.12.2013 Адаптация под 31ю сборку 
                          --carry.fiid,
                          carry.fiid_payer,
                          carry.fiid_receiver,
                          carry.chapter,
                          carry.payer_account,
                          carry.receiver_account,
                          carry.SUM, 
                          -- KS 10.12.2013 Адаптация под 31ю сборку 
                          carry.sum_payer, 
                          carry.sum_receiver,
                          doc.value_date,
                          doc.oper,
                          carry.pack,
                          carry.num_doc,
                          carry.ground,
                          get_parent_department_code (doc.department),
                          doc.department,
                          lv_kindop,
                          NVL (SUBSTR (doc.shifr, 1, INSTR (doc.shifr, '/') - 1), doc.shifr),
                          'проводка ожидает выполнения');
        END;

        PROCEDURE reg_carry_err (p_payment_id NUMBER, p_carry_num PLS_INTEGER, p_err_text VARCHAR2) IS
        BEGIN
            --теперь ошибки записыват макрос.
            DELETE FROM doprtemp_tmp
                  WHERE t_orderid = p_payment_id;
        END;

    BEGIN
        p_error_count     := 0;
        p_error           := usr_common.c_err_success;

        ready_to_run_operation := FALSE;
        
        --проверка наличия сервиса со стороны RS-Bank
        -- 21.05.2013 Golovkin Убрал проверку
        /*v_msg             := '';
        usr_common.make_msg (v_msg, c_check_type);                                                                                          --режим = тест связи
        usr_common.make_msg (v_msg, '0');                                                                         --вид обработки = отсутствует для этого режима
        usr_common.make_msg (v_msg, 'are you ready?');
        v_stat            := usr_send_message (usr_common.m_pipename, v_msg);
        v_stat            :=
            usr_get_message (DBMS_PIPE.unique_session_name,
                             v_ret_pipe,
                             v_message,
                             c_service_timeout);

        IF v_stat <> 0 THEN
            RAISE e_error_service_not_ready;
        END IF;*/

        IF nt_main_doc.COUNT > 0 THEN       
            FOR i IN nt_main_doc.FIRST .. nt_main_doc.LAST LOOP
                v_is_schem            := FALSE;

                IF     (gv_igb_pack IS NOT NULL)
                   AND (gv_igb_bic IS NOT NULL)
                   AND                                                                                                        -- KS Адаптация патч 30 04.07.2011
                       (rsi_rsb_mask.comparestringwithmask (gv_igb_pack, nt_main_doc (i).pack) = 1)
                   AND (rsi_rsb_mask.comparestringwithmask (gv_igb_bic, nt_main_doc (i).receiver_pi_rec.bank_code) = 1) THEN
                    v_is_schem     := TRUE;
                END IF;

                v_is_our_receiver     := nt_main_doc (i).tech_parm_rec.is_our_receiver;
                v_dockind             := nt_main_doc (i).doc_kind;
                v_oper                := nt_main_doc (i).oper;

                IF nt_main_doc.EXISTS (i - 1) AND v_dockind <> nt_main_doc (i - 1).doc_kind THEN
                    --вид документа в пакетном режиме должен быть одинаковым
                    make_error_text (c_err_dockind_mismatch, nt_main_doc (gv_cnt).tech_parm_rec.ERROR_TEXT);
                END IF;

                IF nt_main_doc.EXISTS (i - 1) AND v_dockind = c_dockind_bank_paym AND v_is_our_receiver <> nt_main_doc (i - 1).tech_parm_rec.is_our_receiver THEN
                    --направление платежа в пакетном режиме должно быть одинаковым
                    make_error_text (c_err_dock_direct_mismatch, nt_main_doc (gv_cnt).tech_parm_rec.ERROR_TEXT);
                END IF;

                IF nt_main_doc.EXISTS (i - 1) AND v_oper <> nt_main_doc (i - 1).oper THEN
                    --номер операциониста а пакетном режиме должен быть одинаковым для всех документов
                    make_error_text (c_err_oper_mismatch, nt_main_doc (gv_cnt).tech_parm_rec.ERROR_TEXT);
                END IF;

                p_pack_id             := nt_main_doc (i).tech_parm_rec.pack_id;

                IF c_mode_debug THEN
                    DUMP (nt_main_doc (i));
                END IF;

                --в режиме вставки с запуском операции, в любом случае производится запись в журнал
                --для фиксации ID пакета и ошибок по каждому документу,
                --но ошибка дублирования не обрабатывается т.к. она если надо обработана при создании платежа
                IF NOT nt_main_doc (i).tech_parm_rec.check_exists THEN
                    v_log_stat     := write_log (nt_main_doc (i));
                END IF;

                IF nt_main_doc (i).tech_parm_rec.ERROR_TEXT != usr_common.c_err_success THEN
                    p_error_count     := p_error_count + 1;
                END IF;
            END LOOP;

            IF p_error_count = 0 THEN
                --вставка документов пакета в таблицы
                create_payments (p_run_operation => TRUE, p_in_transact => nt_main_doc (gv_cnt).tech_parm_rec.in_transaction);
                --старт операции
                start_operation (v_dockind, v_oper);
                COMMIT;

                --выполнение проводок
                FOR i IN nt_main_doc.FIRST .. nt_main_doc.LAST LOOP
                    --проводок может и не быть - документ просто создается открытым
                    IF nt_main_doc (i).carry_nt.COUNT > 0 THEN
                        v_doc_sum         := 0;

                        FOR j IN nt_main_doc (i).carry_nt.FIRST .. nt_main_doc (i).carry_nt.LAST LOOP
                            IF nt_main_doc (i).carry_nt (j).chapter = 1 THEN
                                v_doc_sum     := v_doc_sum + nt_main_doc (i).carry_nt (j).SUM;
                            END IF;

                            --перенес в add_carry
                            /*if     j = nt_main_doc (i).carry_nt.count
                               and v_doc_sum <> nt_main_doc (i).debet_sum
                               and nt_main_doc (i).doc_kind <> c_dockind_multycarry
                               and nt_main_doc (i).chapter = 1
                            --проверка на совпадения суммы по проводкам и суммы документа
                            --для мультивалютных не производится
                            then
                               p_error_count := p_error_count + 1;
                               reg_carry_err (nt_main_doc (i).payment_id, j, 'не совпадает сумма проводок и документа');
                               exit;
                            end if;*/

                            /*v_msg := '';
                            usr_common.make_msg (v_msg, c_service_type);
                            --режим = проводка
                            usr_common.make_msg (v_msg, '1');
                            usr_common.make_msg (v_msg, nt_main_doc (i).doc_kind);
                            usr_common.make_msg (v_msg, nt_main_doc (i).payment_id);
                            usr_common.make_msg (v_msg, nt_main_doc (i).operation_id);
                            usr_common.make_msg (v_msg, nt_main_doc (i).oper);
                            usr_common.make_msg (v_msg, get_parent_department_code (nt_main_doc (i).department));
                            usr_common.make_msg (v_msg, nt_main_doc (i).department);
                            usr_common.make_msg (v_msg, nt_main_doc (i).carry_nt (j).fiid);
                            usr_common.make_msg (v_msg, to_char (nt_main_doc (i).value_date, 'DD.MM.YYYY'));
                            usr_common.make_msg (v_msg, nt_main_doc (i).carry_nt (j).chapter);
                            usr_common.make_msg (v_msg, nt_main_doc (i).carry_nt (j).payer_account);
                            usr_common.make_msg (v_msg, nt_main_doc (i).carry_nt (j).receiver_account);
                            usr_common.make_msg (v_msg, nt_main_doc (i).carry_nt (j).ground);
                            usr_common.make_msg (v_msg, to_char (nt_main_doc (i).carry_nt (j).sum, '99999999999999.99'));
                            usr_common.make_msg (v_msg, nt_main_doc (i).carry_nt (j).pack);
                            usr_common.make_msg (v_msg, nt_main_doc (i).carry_nt (j).num_doc);
                            usr_common.make_msg (v_msg, j); --номер проводки
                            usr_common.make_msg (v_msg, nvl(substr(nt_main_doc (i).shifr, instr(nt_main_doc (i).shifr, '/')+1),' 4'));  -- вид операции
                            usr_common.make_msg (v_msg, nvl(substr(nt_main_doc (i).shifr, 1, instr(nt_main_doc (i).shifr, '/')-1),nt_main_doc(i).shifr)); --шифр операции*/
                            IF NOT nt_main_doc (i).tech_parm_rec.make_carry_from_payment --если проводка создана по платежу, она была зарегестрирована при создании платежа
                                                                                        THEN
                                reg_carry (nt_main_doc (i), nt_main_doc (i).carry_nt (j), j);
                            END IF;
                        --зарегистрируем проводку
                        --при выполнении шага зачисления вручную из RS-Bank,
                        ---проводки должны быть сформированы из таблицы usr_pmdocs
                        --v_carry_count := v_carry_count + 1;
                        --dbms_output.put_line(v_msg);
                        --v_stat := usr_send_message (usr_common.m_pipename, v_msg);
                        END LOOP;

                        v_msg             := '';
                        usr_common.make_msg (v_msg, c_service_type);
                        --режим = проводка
                        usr_common.make_msg (v_msg, '1');
                        usr_common.make_msg (v_msg, nt_main_doc (i).doc_kind);
                        usr_common.make_msg (v_msg, nt_main_doc (i).payment_id);
                        v_carry_count     := v_carry_count + 1;
                        v_stat            := usr_send_message (usr_common.m_pipename, v_msg);
                    END IF;
                END LOOP;

                --собираются результаты
                FOR i IN 1 .. v_carry_count LOOP
                    v_stat          := usr_get_message (DBMS_PIPE.unique_session_name, v_ret_pipe, v_message);
                    --разбирается строка сообщения - первым параметром приходит ID платежа, затем номер проводки и результат
                    v_paymentid     := SUBSTR (v_message, 1, INSTR (v_message, c_msg_delim) - 1);
                    v_carrynum      :=
                        SUBSTR (v_message,
                                  INSTR (v_message,
                                         c_msg_delim,
                                         1,
                                         1)
                                + 1,
                                  INSTR (v_message,
                                         c_msg_delim,
                                         1,
                                         2)
                                - INSTR (v_message,
                                         c_msg_delim,
                                         1,
                                         1)
                                - 1);
                    v_errtext       :=
                        NVL (SUBSTR (v_message,
                                       INSTR (v_message,
                                              c_msg_delim,
                                              1,
                                              2)
                                     + 1),
                             'неизвестная ошибка');
                    DBMS_APPLICATION_INFO.set_session_longops (rindex                                    => gv_rindex,
                                                               slno                                      => gv_slno,
                                                               op_name                                   => 'Выполнение проводок',
                                                               sofar                                     => i,
                                                               totalwork                                 => v_carry_count,
                                                               target_desc                               => 'PackID=' || p_pack_id,
                                                               units                                     => 'проводка(ок)');

                    IF v_errtext != usr_common.c_err_success THEN
                        p_error_count     := p_error_count + 1;

                        --регестрируется ошибка - производится запись в журнал
                        --и платеж удаляется из таблицы
                        reg_carry_err (v_paymentid, v_carrynum, v_errtext);
                    END IF;
                END LOOP;

                --еще один цикл по документам - нужно расставить кассовые символы на проводки
                FOR i IN nt_main_doc.FIRST .. nt_main_doc.LAST LOOP
                    IF     (nt_main_doc (i).doc_kind IN (c_dockind_memorder, c_dockind_multycarry, c_dockind_memorder_bank_order)) -- KS 29.07.2011 Банковский ордер
                       AND nt_main_doc (i).cash_symbols_nt.COUNT > 0
                       AND v_errtext = usr_common.c_err_success THEN
                        FOR x IN nt_main_doc (i).cash_symbols_nt.FIRST .. nt_main_doc (i).cash_symbols_nt.LAST LOOP
                            --считаем, что кассовая проводка по документу может быть только одна
                            -- KS 27.11.2013 Адаптация под 31ю сборку
                            
                            INSERT INTO dsymbcash_dbt (t_dockind,
                                                       t_kind,
                                                       t_applicationkey,
                                                       t_symbol,
                                                       t_sum,
                                                       t_date,
                                                       t_acctrnid, -- Новый ключ
                                                       t_reserved)
                                SELECT 1,
                                       nt_main_doc (i).cash_symbols_nt (x).symb_type,
                                       --'0000' || t_iapplicationkind || t_applicationkey,
                                       chr(1),
                                       ' ' || nt_main_doc (i).cash_symbols_nt (x).cash_symbol,
                                       nt_main_doc (i).cash_symbols_nt (x).cash_sum,
                                       usr_common.c_nulldate,
                                       t_acctrnid, -- Новый ключ
                                       pm_common.rsb_empty_string
                                  FROM usr_pmdocs, --darhdoc_dbt
                                       dacctrn_dbt
                                 WHERE acctrnid = t_acctrnid -- t_autokey
                                   AND paymentid = v_paymentid AND SUM = nt_main_doc (i).cash_symbols_nt (x).cash_sum;
                            -- KS end 27.11.2013 Адаптация под 31ю сборку
                        END LOOP;
                    END IF;
                END LOOP;

                IF p_error_count <> v_carry_count THEN
                    -- устанавливается номер шага, который должен выполнится
                    UPDATE doprtemp_tmp
                       SET t_id_step     = 1;

                    -- выполняется шаг операции по платежам, к которым проводки прошли без ошибок
                    -- и в случае, если есть такие платежи
                    IF v_dockind = c_dockind_memorder THEN
                        v_stat      :=
                            bb_memorder.changememorderstatus (0,
                                                              bb_memorder.cb_doc_state_closed,
                                                              0,
                                                              0);
                    ELSIF v_dockind IN (c_dockind_cash_in, c_dockind_cash_out, c_dockind_cash_inout, c_dockind_client_cash_in, c_dockind_client_cash_out) THEN
                        v_stat      :=
                            rsb_cashord.changecashordstatus (0,
                                                             rsb_cashord.stat_cash_order_close,
                                                             0,
                                                             0);
                    ELSIF v_dockind = c_dockind_multycarry THEN
                        v_stat      :=
                            bb_multydoc.changemultydocstatus (0,
                                                              bb_multydoc.mcdoc_status_close,
                                                              0,
                                                              0);
                    ELSIF v_dockind = c_dockind_bank_paym AND (v_is_our_receiver OR v_is_schem) THEN
                        v_stat      :=
                            bb_bankpaym.changebankpaymstatus (0,
                                                              bb_bankpaym.memorder_status_close,
                                                              0,
                                                              0);
                    END IF;

                    IF (v_is_our_receiver OR v_is_schem) THEN
                        v_stat      :=
                            pm_common.changepaymstatus (0,
                                                        pm_common.pm_finished,
                                                        0,
                                                        0,
                                                        v_oper);

                        -- KS 03.08.2011 Адаптация Патч 30
                        UPDATE dpmpaym_dbt pm
                           SET pm.t_closedate     = rsbsessiondata.m_curdate
                         WHERE pm.t_paymentid IN (SELECT tmp.t_orderid
                                                    FROM doprtemp_tmp tmp
                                                   WHERE tmp.t_errorstatus = 0 AND tmp.t_skipdocument = 0);
                    ELSE
                        v_stat      :=
                            pm_common.changepaymstatus (0,
                                                        pm_common.pm_ready_to_send,
                                                        0,
                                                        0,
                                                        v_oper);
                    END IF;

                    IF v_stat != 0 THEN
                        v_last_error     := 'ошибка при изменении статуса платежа, код ' || v_stat;
                        RAISE e_error_run_operation;
                    END IF;

                    IF (v_is_our_receiver OR v_is_schem) THEN
                        v_stat      :=
                            pm_common.changepmpropstatus (0,
                                                          NULL,
                                                          pm_common.pm_finished,
                                                          NULL);
                    END IF;

                    IF v_stat != 0 THEN
                        v_last_error     := 'ошибка при изменении внешнего статуса документа, код ' || v_stat;
                        RAISE e_error_run_operation;
                    END IF;

                    IF (v_is_our_receiver OR v_is_schem) THEN
                        --Состояние платежа=Закрыт
                        v_stat     := rsbemoperation.opr_setoprstatusvalue (291, 3);
                    ELSE
                        --Документооборот = Выгрузка
                        v_stat     := rsbemoperation.opr_setoprstatusvalue (292, 2);
                        --Направление=Исходящий
                        v_stat     := rsbemoperation.opr_setoprstatusvalue (295, 3);
                    END IF;

                    IF v_stat != 0 THEN
                        v_last_error     := 'ошибка при установке статуса операции, код ' || v_stat;
                        RAISE e_error_run_operation;
                    END IF;

                    v_stat     := rsbemoperation.opr_massexecutestep (NULL);

                    IF v_stat != 0 THEN
                        v_last_error     := 'ошибка при выполнения шага, код ' || v_stat;
                        RAISE e_error_run_operation;
                    END IF;
                END IF;

                COMMIT;
            END IF;
        ELSE
            p_error     := 'не документов для исполнения';
        END IF;

        delete_pack;
    EXCEPTION
        WHEN e_error_start_oper THEN
            p_error     := v_last_error;
            delete_pack;
            ROLLBACK;
        WHEN e_error_run_operation THEN
            p_error     := v_last_error;
            delete_pack;
            ROLLBACK;
        WHEN e_error_service_not_ready THEN
            p_error     := 'сервис RS-Bank не готов';
            delete_pack;
            ROLLBACK;
        WHEN OTHERS THEN
            p_error     := 'ошибка выполнения операции: ' || DBMS_UTILITY.format_error_stack || DBMS_UTILITY.format_error_backtrace;
            delete_pack;
            ROLLBACK;
    END;

    PROCEDURE delete_payment (p_payment_id IN NUMBER, p_error OUT VARCHAR2, p_oper IN NUMBER DEFAULT 0) IS
        v_msg                                        VARCHAR2 (4000);
        v_ret_pipe                                   VARCHAR2 (64);
        v_message                                    VARCHAR2 (4000);
        v_stat                                       NUMBER;
        v_unique_pipe                                VARCHAR2 (60);                                                                            --уникальный pipe
        v_timeout                                    PLS_INTEGER;                                                         --время ожидания ответа от обработчика
        v_payment_id                                 NUMBER;                                                                                      --для проверки
        v_use_unique_pipe                            BOOLEAN;
    BEGIN
        --25.12.2012 Golovkin запись параметров в лог
        usr_interface_logging.save_arguments (UPPER ('usr_payments'), UPPER ('delete_payment'), ku$_vcnt (p_payment_id, p_error, p_oper));
        --сначала откатываем проводки по платежу

        v_msg                 := '';
        usr_common.make_msg (v_msg, c_service_type);
        --режим = откат проводки
        usr_common.make_msg (v_msg, '2');
        usr_common.make_msg (v_msg, p_payment_id);
        usr_common.make_msg (v_msg, p_oper);

        v_use_unique_pipe     := NVL (rsb_common.getregboolvalue ('PRBB\ИНТЕРФЕЙСЫ\ИСПОЛЬЗОВАТЬ_ГЕНЕРАЦИЮ_PIPE', 0), FALSE);

        IF (v_use_unique_pipe) THEN                                                                                                 --генерируем уникальный pipe
            v_timeout     := NVL (rsb_common.getregintvalue ('PRBB\ИНТЕРФЕЙСЫ\TIMEOUT', 0), 30);
            v_stat        := usr_send_message_uniq (usr_common.m_pipename, v_msg, v_unique_pipe);                             --send message and get unique pipe
            v_stat        :=
                usr_get_message (v_unique_pipe,
                                 v_ret_pipe,
                                 v_message,
                                 v_timeout);                                                                                                   --use unique pipe
        ELSE
            v_stat     := usr_send_message (usr_common.m_pipename, v_msg);
            v_stat     := usr_get_message (DBMS_PIPE.unique_session_name, v_ret_pipe, v_message);
        END IF;

        IF (v_stat = 1) THEN                                                                                          --не получили ответ по истечению тайм аута
            BEGIN
                SELECT t_paymentid
                  INTO v_payment_id
                  FROM dpmpaym_dbt
                 WHERE t_paymentid = p_payment_id;

                v_message      :=
                    'Превышено время ожидания отклика от БД, попробуйте удалить платеж через некоторое время';
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_message     := usr_common.c_err_success;
            END;
        END IF;

        IF v_message != usr_common.c_err_success THEN
            RAISE e_error_carry_backout;
        END IF;

        p_error               := usr_common.c_err_success;
    EXCEPTION
        WHEN e_error_carry_backout THEN
            p_error     := v_message;
            ROLLBACK;
        WHEN OTHERS THEN
            p_error     := 'ошибка при удалении: ' || DBMS_UTILITY.format_error_stack || DBMS_UTILITY.format_error_backtrace;
            ROLLBACK;
    END;

    PROCEDURE delete_payment_callback (p_payment_id IN NUMBER, p_error OUT VARCHAR2) IS
        v_operation_id                               NUMBER (10);
        v_document_id                                NUMBER (10);
        v_dockind                                    NUMBER (5);
    BEGIN
        SELECT op.t_id_operation, pm.t_documentid, pm.t_dockind
          INTO v_operation_id, v_document_id, v_dockind
          FROM dpmpaym_dbt pm, doproper_dbt op
         WHERE op.t_dockind(+) = pm.t_dockind AND op.t_documentid(+) = LPAD (pm.t_documentid, 34, '0') AND pm.t_paymentid = p_payment_id;

        IF v_operation_id IS NOT NULL THEN
            DELETE FROM doprdocs_dbt
                  WHERE t_id_operation = v_operation_id;

            DELETE FROM doprstep_dbt
                  WHERE t_id_operation = v_operation_id;

            DELETE FROM doprdates_dbt
                  WHERE t_id_operation = v_operation_id;

            DELETE FROM doprcurst_dbt cascade
                  WHERE t_id_operation = v_operation_id;

            DELETE FROM doprsthist_dbt
                  WHERE t_id_operation = v_operation_id;

            DELETE FROM doproper_dbt
                  WHERE t_id_operation = v_operation_id;
        END IF;

        IF v_dockind = c_dockind_memorder THEN
            DELETE FROM dcb_doc_dbt
                  WHERE t_documentid = v_document_id;
        ELSIF v_dockind = 201 THEN
            DELETE FROM dpspayord_dbt
                  WHERE t_orderid = v_document_id;

            DELETE FROM dpspaydem_dbt
                  WHERE t_orderid = v_document_id;

            DELETE FROM dpspohist_dbt
                  WHERE t_orderid = v_document_id;
        ELSIF v_dockind IN (c_dockind_bank_order, c_dockind_bank_paym) THEN
            DELETE FROM dmemorder_dbt
                  WHERE t_orderid = v_document_id;
        ELSIF v_dockind IN (c_dockind_cash_in, c_dockind_cash_out, c_dockind_cash_inout) THEN
            DELETE FROM dpscshdoc_dbt
                  WHERE t_autokey = v_document_id;
        ELSIF v_dockind = c_dockind_multycarry THEN
            DELETE FROM dmultydoc_dbt
                  WHERE t_autokey = v_document_id;
        ELSIF v_dockind = c_dockind_bank_paym_val THEN -- 19.08.2013 Golovkin I-00414903 удаление валютного платежа банка
            DELETE FROM dbbcpord_dbt
                  WHERE t_orderid = v_document_id;           
        ELSIF v_dockind != c_dockind_memorder_bank_order THEN
            make_error_text (c_err_dockind_not_supp, p_error);
            RAISE e_error_del_payment;
        END IF;

        DELETE FROM dpmhist_dbt
              WHERE t_paymentid = p_payment_id;

        DELETE FROM dpmdocs_dbt
              WHERE t_paymentid = p_payment_id;

        DELETE FROM dpmrmprop_dbt
              WHERE t_paymentid = p_payment_id;

        DELETE FROM dpmprop_dbt
              WHERE t_paymentid = p_payment_id;

        DELETE FROM dpmpaym_dbt
              WHERE t_paymentid = p_payment_id;

        DELETE FROM dpmco_dbt
              WHERE t_paymentid = p_payment_id;

        DELETE FROM dpmcurtr_dbt                                                                              -- KS Адаптация патч 30 05.09.2011 co2029_2030.sql
              WHERE t_paymentid = p_payment_id;

        --RR 28.11.2012 Записываем информацию о том кто и когда удалил документ
        UPDATE usr_payments_log
           SET log_data     = TO_CHAR (TO_CHAR (SYSDATE, 'dd.mm.yyyy-hh:mi:ss') || ' ' || 'EXT_SYSTEM')
         WHERE paymentid = p_payment_id;

        DELETE FROM usr_pmdocs
              WHERE paymentid = p_payment_id;



        p_error     := usr_common.c_err_success;
    EXCEPTION
        WHEN e_error_del_payment THEN
            p_error     := 'ошибка при удалении документа: ' || p_error;
            ROLLBACK;
        WHEN NO_DATA_FOUND THEN
            p_error     := 'платеж с ID=' || p_payment_id || ' не найден';
            ROLLBACK;
        WHEN OTHERS THEN
            p_error      :=
                'ошибка при удалении документа: ' || DBMS_UTILITY.format_error_stack || DBMS_UTILITY.format_error_backtrace;
            ROLLBACK;
    END;
END; 
/
