/* Formatted on 2008/07/17 16:27 (Formatter Plus v4.8.8) */

-- [1. Задание значения категории для клиента]
DECLARE
   v_error   VARCHAR2 (4000);
   v_attrid   dobjattr_dbt.t_attrid%type;
BEGIN
   v_attrid := 1;
   usr_categories.set_category (p_objecttype         => 3,
                                p_objectid           => 4514,
                                p_groupid            => 36,
                                p_attrid             => v_attrid,
                                p_error_message      => v_error
                               );
   DBMS_OUTPUT.put_line ('Результат : ' || v_error);
END;

-- [2. Удаление значения категории для клиента]
DECLARE
   v_error   VARCHAR2 (4000);
BEGIN
   usr_categories.del_category (p_objecttype         => 3,
                                p_objectid           => 4514,
                                p_groupid            => 36,
                                p_error_message      => v_error
                               );
   DBMS_OUTPUT.put_line ('????????? : ' || v_error);
END;


-- [3. Создание значения категории для счета]
DECLARE
   v_error   VARCHAR2 (4000);
   v_attrid  dobjattr_dbt.t_attrid%type;
BEGIN
   v_attrid := 3;
   usr_categories.set_category (p_objecttype         => 4,
                                p_objectid           => '20202840900000000000',
                                p_groupid            => 13,
                                p_attrid             => v_attrid,
                                p_error_message      => v_error
                               );
   DBMS_OUTPUT.put_line ('Результат : ' || v_error);
END;


-- [4. Удаление значения категории для счета]
DECLARE
   v_error   VARCHAR2 (4000);
BEGIN
   usr_categories.del_category (p_objecttype         => 4,
                                p_objectid           => '20202840900000000000',
                                p_groupid            => 13,
                                p_error_message      => v_error
                               );
   DBMS_OUTPUT.put_line ('Результат : ' || v_error);
END;