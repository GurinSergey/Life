/* Formatted on 2008/07/17 15:20 (Formatter Plus v4.8.8) */

-- [1. Создание примечания для клиента]
DECLARE
   v_error   VARCHAR2 (4000);
BEGIN
   usr_notes.set_note (p_objecttype         => 3,
                       p_objectid           => 4514,
                       p_notekind           => 1,
                       p_notevalue          => '08.08.2008',
                       p_error_message      => v_error
                      );
   DBMS_OUTPUT.put_line ('Результат : ' || v_error);
END;

-- [2. Удаление примечания для клиента]
DECLARE
   v_error   VARCHAR2 (4000);
BEGIN
   usr_notes.del_note (p_objecttype         => 3,
                       p_objectid           => 4514,
                       p_notekind           => 1,                       
                       p_error_message      => v_error
                      );
   DBMS_OUTPUT.put_line ('Результат : ' || v_error);
END;

-- [3. Создание примечания для счета]
DECLARE
   v_error   VARCHAR2 (4000);
BEGIN
   usr_notes.set_note (p_objecttype         => 4,
                       p_objectid           => '20202840900000000000',
                       p_notekind           => 6,
                       p_notevalue          => '08.08.2008',
                       p_error_message      => v_error
                      );
   DBMS_OUTPUT.put_line ('Результат : ' || v_error);
END;

-- [4. Удаление примечания для счета]
DECLARE
   v_error   VARCHAR2 (4000);
BEGIN
   usr_notes.del_note (p_objecttype         => 4,
                       p_objectid           => '20202840900000000000',
                       p_notekind           => 6,                       
                       p_error_message      => v_error
                      );
   DBMS_OUTPUT.put_line ('Результат : ' || v_error);
END;