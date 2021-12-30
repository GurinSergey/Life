CREATE OR REPLACE PACKAGE USR_ACCREST IS
    -- 2012-07-07 zip_z. Пакет переписан на использование дистрибутивных RSI_RSBAccTransaction и RSI_RSB_AcClaim
    -- @desc   : Доступный остаток на дату с учетом претензий, лимита и планового остатка
    FUNCTION get_rest_current (
        p_account    VARCHAR2,               -- Лицевой счет
        p_date       DATE,                   -- Дата
        p_priority   NUMBER DEFAULT 6,       -- Очередность платежа
        p_limit      NUMBER DEFAULT 1        -- 0 - без оверадрафта, !0 - с овердрафтом
    )
        RETURN NUMBER;

    -- @desc   : Доступный остаток на дату с учетом претензий
    FUNCTION get_rest_claims (
        p_account    VARCHAR2,               -- Лицевой счет
        p_date       DATE,                   -- Дата
        p_priority   NUMBER DEFAULT 6        -- Очередность платежа
    )
        RETURN NUMBER;

    -- @desc   : Возвращает сумму претензий на дату
    FUNCTION get_claims (
        p_account    VARCHAR2,               -- Лицевой счет 
        p_date       DATE,                   -- Дата
        p_priority   NUMBER DEFAULT 6        -- Очередность платежа
    )
        RETURN NUMBER;

    -- @desc   : Возвращает фактический остаток по счету на дату
    FUNCTION get_rest (p_account VARCHAR2, p_date DATE)
        RETURN NUMBER;

    -- @desc   : Возвращает остаток на картотеке 2 к счету на дату
    FUNCTION get_restk2 (p_account VARCHAR2, p_date DATE)
        RETURN NUMBER;
END; 
/
CREATE OR REPLACE PACKAGE BODY usr_accrest IS
    --------------------------------------------------------------------------------------------------------------------
    -- @desc   : Сумма претензий к счету на дату
    -- @changes: 2012-07-07 zip_z. Переписал на дистрибутивный вариант
    -- @scope  : private (невидима извне пакета)
    --------------------------------------------------------------------------------------------------------------------
    FUNCTION get_claimsum (
        p_Account    VARCHAR2,
        p_Date       DATE,
        p_FIID       NUMBER,
        p_Chapter    NUMBER,
        p_Priority   NUMBER DEFAULT 6
    )
        RETURN NUMBER 
    IS
    BEGIN
        RETURN RSI_RSB_AcClaim.CalcClaimAmount (p_Account,
                                                p_Chapter,
                                                p_FIID,
                                                p_Priority,
                                                p_Date
                                               );
    END;

    --------------------------------------------------------------------------------------------------------------------
    -- @desc   : Есть ли на счете полный арест? (true - есть)
    -- @changes: 2012-07-07 zip_z. Переписал на дистрибутивный вариант
    -- @scope  : private (невидима извне пакета)
    --------------------------------------------------------------------------------------------------------------------
    FUNCTION is_full_arrest (
        p_Account   VARCHAR2,
        p_Date      DATE,
        p_FIID      NUMBER,
        p_Chapter   NUMBER
    )
        RETURN BOOLEAN 
    IS
    BEGIN
        RETURN (RSI_RSB_AcClaim.FindFullArrest (p_Account,
                                                p_Chapter,
                                                p_FIID,
                                                p_Date
                                               ) > 0
               );
    END;

    --------------------------------------------------------------------------------------------------------------------
    -- @desc   : Есть ли на счете частичный арест? (true - есть)
    -- @changes: 2012-07-07 zip_z. Переписал на дистрибутивный вариант
    -- @scope  : private (невидима извне пакета)
    --------------------------------------------------------------------------------------------------------------------
    FUNCTION is_partial_arrest (
        p_Account    VARCHAR2,
        p_Date       DATE,
        p_FIID       NUMBER,
        p_Chapter    NUMBER,
        p_Priority   NUMBER DEFAULT 6
    )
        RETURN BOOLEAN 
    IS
    BEGIN
        RETURN (RSI_RSB_AcClaim.FindPartialArrestLessPriority (p_Account,
                                                               p_Chapter,
                                                               p_FIID,
                                                               p_Priority,
                                                               p_Date
                                                              ) > 0
               );
    END;

    --------------------------------------------------------------------------------------------------------------------
    -- @desc   : Доступный остаток на дату с учетом претензий, лимита и планового остатка
    -- @changes: 2012-07-07 zip_z. Переписал на дистрибутивный вариант
    -- @changes: 2013-05-21 Chesnokov D.S. Добавил параметр p_limit 0 - без оверадрафта, !0 - с овердрафтом
    -- @scope  : public (функция видима извне пакета)
    --------------------------------------------------------------------------------------------------------------------
    FUNCTION get_rest_current (
        p_Account    VARCHAR2,
        p_Date       DATE,
        p_Priority   NUMBER DEFAULT 6,
        p_Limit      NUMBER DEFAULT 1
    )
        RETURN NUMBER 
    IS
        v_FIID              NUMBER := USR_Common.Get_FIID (p_account);
        v_Chapter           NUMBER := USR_Common.get_chapter (p_account);

        v_FreeAmount        NUMBER := 0; -- свободный остаток БЕЗ лимитов овердрафта по счету
        v_FreeLimitAmount   NUMBER := 0; -- свободный остаток с учетом лимитов овердрафта по счету
        v_ReasonID          NUMBER := 0; -- ID претензии, которая обнулила остаток
    BEGIN
        USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_accrest'),
                                              UPPER ('get_rest_current'),
                                              ku$_vcnt (p_Account,
                                                        p_Date,
                                                        p_Priority, 
                                                        p_Limit));
                                                        
        RSI_RSBAccTransaction.AccGetFreeAmount (v_FreeAmount,
                                                v_FreeLimitAmount,
                                                p_Account,
                                                v_Chapter,
                                                v_FIID,
                                                p_Date,
                                                p_Priority,
                                                0,
                                                0,
                                                v_ReasonID
                                               );
        IF p_Limit IS NULL THEN
          RETURN v_FreeLimitAmount;
        ELSIF p_Limit <> 0 THEN                                       
          RETURN v_FreeLimitAmount;
        ELSE
          RETURN v_FreeAmount;
        END IF;    
    END;

    --------------------------------------------------------------------------------------------------------------------
    -- @desc   : Доступный остаток на дату с учетом претензий
    -- @changes: 2012-07-07 zip_z. Переписал на дистрибутивный вариант
    -- @scope  : public (функция видима извне пакета)
    --------------------------------------------------------------------------------------------------------------------
    FUNCTION get_rest_claims (
        p_Account    VARCHAR2,
        p_Date       DATE,
        p_Priority   NUMBER DEFAULT 6
    )
        RETURN NUMBER IS
        v_FIID              NUMBER := USR_Common.Get_FIID    (p_account);
        v_Chapter           NUMBER := USR_Common.Get_Chapter (p_account);
        
        p_FreeAmount        NUMBER := 0; -- Свободный остаток БЕЗ лимитов овердрафта по счету
        p_FreeLimitAmount   NUMBER := 0; -- Свободный остаток с учетом лимитов овердрафта по счету
        p_ReasonID          NUMBER := 0; -- ID претензии, которая обнулила остаток
    BEGIN
        USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_accrest'),
                                              UPPER ('get_rest_claims'),
                                              ku$_vcnt (p_Account,
                                                        p_Date,
                                                        p_Priority));
                                                        
        RSI_RSBAccTransaction.AccGetFreeAmount (p_FreeAmount,
                                                p_FreeLimitAmount,
                                                p_Account,
                                                v_Chapter,
                                                v_FIID,
                                                p_Date,
                                                p_Priority,
                                                0, -- ID связанной претензии
                                                0, -- Признак отсутствия проверок ареста
                                                p_ReasonID
                                               );
        RETURN p_FreeAmount;
    END;

    --------------------------------------------------------------------------------------------------------------------
    -- @desc   : Возвращает сумму претензий на дату
    -- @changes: 2012-07-07 zip_z. Переписал на дистрибутивный вариант
    -- @scope  : public (функция видима извне пакета)
    --------------------------------------------------------------------------------------------------------------------
    FUNCTION get_claims (
        p_Account    VARCHAR2,
        p_Date       DATE,
        p_Priority   NUMBER DEFAULT 6
    )
        RETURN NUMBER 
    IS
        v_FIID      NUMBER := USR_Common.Get_FIID (p_account);
        v_Chapter   NUMBER := USR_Common.get_chapter (p_account);
    BEGIN
        USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_accrest'),
                                              UPPER ('get_claims'),
                                              ku$_vcnt (p_Account,
                                                        p_Date,
                                                        p_Priority));
                                                        
        RETURN RSI_RSB_AcClaim.CalcClaimAmount (p_Account,
                                                v_Chapter,
                                                v_FIID,
                                                p_Priority,
                                                p_Date
                                               );
    END;

    --------------------------------------------------------------------------------------------------------------------
    -- @desc   : Возвращает фактический остаток по счету на дату
    -- @changes: 2012-07-07 zip_z. Переписал на дистрибутивный вариант
    -- @scope  : public (функция видима извне пакета)
    --------------------------------------------------------------------------------------------------------------------
    FUNCTION get_rest (
        p_Account VARCHAR2, 
        p_Date DATE
    )
        RETURN NUMBER 
    IS
        v_FIID      NUMBER := USR_Common.Get_FIID (p_Account);
        v_Chapter   NUMBER := USR_Common.Get_Chapter (p_Account);
    BEGIN
        USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_accrest'),
                                              UPPER ('get_rest'),
                                              ku$_vcnt (p_Account,
                                                        p_Date));
                                                        
        RETURN RSI_RSB_Account.RestAll (p_account, v_chapter, v_FIID, p_Date);
    END;

    --------------------------------------------------------------------------------------------------------------------
    -- @desc   : Возвращает остаток неоплаченных документов К2 к счёту на дату
    -- @changes: 2012-07-07 zip_z. Научил учитывать банковские ордера (в 2030 они умеют становиться на К2)
    --           2012-07-10 zip_z. Переписал запрос на более простой без ненужной привязки к операциям и шагам
    -- @scope  : public (функция видима извне пакета)
    --------------------------------------------------------------------------------------------------------------------
    FUNCTION get_restk2 (p_account IN VARCHAR2, p_date IN DATE)
        RETURN NUMBER 
    IS
        v_rest    NUMBER := 0;
    BEGIN
    
    USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_accrest'),
                                          UPPER ('get_restk2'),
                                          ku$_vcnt (p_Account,
                                                    p_Date));
                                                        
    SELECT NVL (ROUND (SUM (t_futurePayerAmount), 2), 0) INTO v_Rest
      FROM dpmpaym_dbt pm
     WHERE pm.t_paymstatus = 2000 AND pm.t_dockind IN (201, 286)
       AND pm.t_i2placedate <= p_Date
       AND pm.t_payeraccount = p_Account
       AND pm.t_fiid = USR_Common.Get_FIID (p_Account);
  
    RETURN v_rest;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END;
END; 
/
