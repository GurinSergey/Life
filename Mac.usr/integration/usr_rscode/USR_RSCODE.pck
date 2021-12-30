create or replace package usr_rscode
is
   --константы для задания типа клиента
   c_person_type_artificial constant pls_integer := 1;
   c_person_type_foreign constant pls_integer := 2;
   c_person_type_bank constant pls_integer := 4;

   --получение кода в транзакции!
   --вызывающему сеансу нужно завершать транзакцию
   --в случае ошибки транзакция откатывается
   procedure get_rscode (
      p_person_mask     number,
      p_code        out varchar2,
      p_error       out varchar2
   );
end; 
/
CREATE OR REPLACE PACKAGE BODY usr_rscode
is
   e_rangeid_notfound exception;

   type person_type_rec is record (
      is_artificial_person boolean,
      is_foreign_person boolean,
      is_bank boolean
   );

   person_type person_type_rec;

   function get_rangeid
      return number
   is
      lv_sqltext varchar2 (256);
      ret_val number (3);

      function get_char (
         flag boolean
      )
         return char
      is
      begin
         if flag
         then
            return 'Y';
         end if;

         return 'N';
      end;
   begin
      lv_sqltext :=
            'select range_id from usr_rscode_range'
         || ' where is_artificial_person = :1'
         || ' and is_foreign_person = :2'
         || ' and is_bank = :3';

      execute immediate lv_sqltext
                   into ret_val
                  using get_char (person_type.is_artificial_person),
                        get_char (person_type.is_foreign_person),
                        get_char (person_type.is_bank);

      return ret_val;
   exception
      when no_data_found
      then
         raise e_rangeid_notfound;
   end;

   procedure parse_person_mask (
      p_person_mask number
   )
   is
   begin
      person_type.is_artificial_person := bitand (p_person_mask, c_person_type_artificial) = c_person_type_artificial;
      person_type.is_foreign_person := bitand (p_person_mask, c_person_type_foreign) = c_person_type_foreign;
      person_type.is_bank := bitand (p_person_mask, c_person_type_bank) = c_person_type_bank;
   end;

   procedure get_rscode (
      p_person_mask     number,
      p_code        out varchar2,
      p_error       out varchar2
   )
   is
      lv_rangeid number;
      lv_sqltext varchar2 (32000);
      lv_lastcode number;
      lv_minvalue number;
      lv_maxvalue number;
      lv_mask_chapter1 varchar2 (2048);
      lv_mask_chapter3 varchar2 (2048);
      lv_len_code number := 0;
      lv_code varchar2 (64);
   begin
   
      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_rscode'),
                                            UPPER ('get_rscode'),
                                            ku$_vcnt (p_person_mask,
                                                      p_code,
                                                      p_error));   
   
      p_error := usr_common.c_err_success;
      parse_person_mask (p_person_mask);
      lv_rangeid := get_rangeid;

      select     low_limit, high_limit, last_code
            into lv_minvalue, lv_maxvalue, lv_lastcode
            from usr_rscode_range
           where range_id = lv_rangeid
      for update;
      
      -- KS Режим совместимости с другими банками группы.
      --    Если максимальный код имеет длину 6 символов, то работает механизм ПРББ, (lv_len_code = 6)
      --    иначе старый алгоритм (lv_len_code != 6)
      --select length(to_char(max(high_limit)))
      --  into lv_len_code
      --  from usr_rscode_range
      -- where is_artificial_person = 'Y'
      --   and is_foreign_person = 'N'
      --   and is_bank = 'N';

      -- CDS Закомментировал за Котопсом
      --     Определяем длинну кода в соответствии с переданной маской,
      --     а не по длинне юрлиц. резидентов

      select length(to_char(max(high_limit)))
        into lv_len_code
        from usr_rscode_range
       where range_id = lv_rangeid;

         
      if lv_len_code = 6 then
        lv_code := '^010000[1-9][0-9][0-9][0-9][0-9][0-9]'; -- KS C-12242
      else
        lv_code := '^0100000[1-9][0-9][0-9][0-9][0-9]';
      end if;

      --если нужно искать свободный код от последнего значения - раскомменарить
      lv_minvalue := nvl (lv_lastcode, lv_minvalue); -- если наоборот, то закомменарить
      lv_sqltext :=
            'select min (freecode) '
         || ' from (with allcode as '
         || ' (select     rownum freecode '
         || '    from dual'
         || '  connect by level <= :high)'
         || ' select freecode'
         || '   from allcode'
         || '  where freecode > :low'
         || ' minus'
         || ' ('
         || '  select to_number (regexp_replace (substr (t_code, 7), ''[^[:digit:]]''))' -- KS оставлю 7, т.к. в 5ти значных кодах 7й символ - ноль
         || '    from dobjcode_dbt code'
         || '   where t_objecttype = 3'
         || '     and t_codekind = 1'
         || '     and regexp_like (t_code, '''||lv_code||''')' -- KS C-12242
         || '     and to_number (regexp_replace (substr (t_code, 7), ''[^[:digit:]]'')) between :low and :high';
      if (lv_len_code = 6) then -- KS Если включен 6значный режим

        -- KS C-12266 Маски счетов-исключений по первой главе
        lv_mask_chapter1 := rsb_common.GetRegStrValue('PRBB\ИНТЕРФЕЙСЫ\ГЕНЕРАЦИЯ_КОДА\МАСКИ 1 ГЛАВЫ СЧЕТОВ',0);
        -- KS C-12266 Маски счетов-исключений по третьей главе
        lv_mask_chapter3 := rsb_common.GetRegStrValue('PRBB\ИНТЕРФЕЙСЫ\ГЕНЕРАЦИЯ_КОДА\МАСКИ 3 ГЛАВЫ СЧЕТОВ',0);

        lv_sqltext := lv_sqltext
           || '  union' -- KS C-12242 Добавлю отсечение уже занятых кодов в таблице счетов (старых)
           || '  select to_number (regexp_replace (substr (acc.t_account, -6), ''[^[:digit:]]''))'
           || '    from daccount_dbt acc'
           || '   where substr(acc.t_account,1,5) between ''40101'' and ''40807'''
           || '     and t_chapter = 1'
           || '     and to_number (regexp_replace (substr (acc.t_account, -6), ''[^[:digit:]]'')) between :low and :high'
           || '  union' -- KS C-12266 Добавлю отсечение уже занятых кодов в таблице счетов (новых глава 1)
           || '  select to_number (regexp_replace (CONCAT(SUBSTR(acc.t_account,12,1), substr(acc.t_account, -5)), ''[^[:digit:]]''))'
           || '    from daccount_dbt acc'
           || '   where ('||rep_account.convertmaskstosqlformat(lv_mask_chapter1,'acc.t_account')||')'
           || '     and t_chapter = 1'
           || '     and to_number (regexp_replace (CONCAT(SUBSTR(acc.t_account,12,1), substr(acc.t_account, -5)), ''[^[:digit:]]'')) between :low and :high'
           || '  union' -- KS C-12266 Добавлю отсечение уже занятых кодов в таблице счетов (новых глава 3)
           || '  select to_number (regexp_replace (CONCAT(SUBSTR(acc.t_account,12,1), substr(acc.t_account, -5)), ''[^[:digit:]]''))'
           || '    from daccount_dbt acc'
           || '   where ('||rep_account.convertmaskstosqlformat(lv_mask_chapter3,'acc.t_account')||')'
           || '     and t_chapter = 3'
           || '     and to_number (regexp_replace (CONCAT(SUBSTR(acc.t_account,12,1), substr(acc.t_account, -5)), ''[^[:digit:]]'')) between :low and :high';
      end if;
      lv_sqltext := lv_sqltext
         || ' )'
         || ')';
--dbms_output.put_line(lv_sqltext);

      if (lv_len_code = 6) then -- KS Если включен 6значный режим
        execute immediate lv_sqltext
                     into p_code
                    using lv_maxvalue, lv_minvalue,
                          lv_minvalue, lv_maxvalue,
                          lv_minvalue, lv_maxvalue,
                          lv_minvalue, lv_maxvalue,
                          lv_minvalue, lv_maxvalue;
      else
        execute immediate lv_sqltext
                     into p_code
                    using lv_maxvalue, lv_minvalue,
                          lv_minvalue, lv_maxvalue;
      end if;

      update usr_rscode_range
         set last_code = p_code
       where range_id = lv_rangeid;

      if p_code is null
      then
         rollback;
         p_error := 'в диапазоне ' || lv_minvalue || '-' || lv_maxvalue || ' нет свободных кодов';
      end if;
   exception
      when e_rangeid_notfound
      then
         p_error := 'не определен диапазон кодов';
      when others
      then
         rollback;
         p_error :=
               'ошибка получения кода: '
            || chr (10)
            || dbms_utility.format_error_stack
            || dbms_utility.format_error_backtrace;
   end;
end; 
/
