create or replace package usr_categories
is
   c_set_func constant        number (5) := 1;
   c_del_func constant        number (5) := 2;
   c_category_type constant   number (5) := 2;

   procedure set_category (p_objecttype      in     number,
                           p_objectid        in     varchar2,
                           p_groupid         in     number,
                           p_attrid          in out number,
                           p_attrcode        in     varchar2 default null ,
                           p_error_message      out varchar2);

   procedure del_category (p_objecttype      in     number,
                           p_objectid        in     varchar2,
                           p_attrid          in out number,
                           p_attrcode        in     varchar2 default null ,
                           p_groupid         in     number,
                           p_error_message      out varchar2);
end usr_categories;
/
CREATE OR REPLACE PACKAGE BODY usr_categories
is
   function search_attrid (attrcode varchar2, groupid number, objtype number)
      return number
   is
      v_attrid   number;
   begin
      select   t_attrid
        into   v_attrid
        from   dobjattr_dbt
       where   t_objecttype = objtype and t_groupid = groupid and t_nameobject = attrcode;

      return v_attrid;
   exception
      when no_data_found
      then
         return 0;
   end;

   procedure set_category (p_objecttype      in     number,
                           p_objectid        in     varchar2,
                           p_groupid         in     number,
                           p_attrid          in out number,
                           p_attrcode        in     varchar2 default null ,
                           p_error_message      out varchar2)
   is
      v_stat         number;
      v_ret_string   varchar2 (2048);
      v_ret_pipe     varchar2 (64);
   begin
   
      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_categories'),
                                            UPPER ('set_category'),
                                            ku$_vcnt (p_objecttype,
                                                      p_objectid,
                                                      p_groupid,
                                                      p_attrid,
                                                      p_attrcode,
                                                      p_error_message));
      if p_attrcode is not null
      then
         p_attrid := search_attrid (p_attrcode, p_groupid, p_objecttype);

         if p_attrid = 0
         then
            p_error_message := 'не найдена категория по значению ' || p_attrcode;
            return;
         end if;
      end if;

      usr_common.make_msg (v_ret_string, c_category_type);
      usr_common.make_msg (v_ret_string, c_set_func);
      usr_common.make_msg (v_ret_string, p_objecttype);
      usr_common.make_msg (v_ret_string, p_objectid);
      usr_common.make_msg (v_ret_string, p_groupid);
      usr_common.make_msg (v_ret_string, p_attrid);
      v_stat := usr_send_message (usr_common.m_pipename, v_ret_string);
      v_stat := usr_get_message (dbms_pipe.unique_session_name, v_ret_pipe, p_error_message);
   end;

   procedure del_category (p_objecttype      in     number,
                           p_objectid        in     varchar2,
                           p_attrid          in out number,
                           p_attrcode        in     varchar2 default null ,
                           p_groupid         in     number,
                           p_error_message      out varchar2)
   is
      v_ret_string   varchar2 (2048);
      v_ret_pipe     varchar2 (64);
      v_stat         number;
   begin
   
      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_categories'),
                                            UPPER ('del_category'),
                                            ku$_vcnt (p_objecttype,
                                                      p_objectid,
                                                      p_attrid,
                                                      p_attrcode,
                                                      p_groupid,
                                                      p_error_message));
                                                      
      if p_attrcode is not null
      then
         p_attrid := search_attrid (p_attrcode, p_groupid, p_objecttype);

         if p_attrid = 0
         then
            p_error_message := 'не найдена категория по значению ' || p_attrcode;
            return;
         end if;
      end if;

      usr_common.make_msg (v_ret_string, c_category_type);
      usr_common.make_msg (v_ret_string, c_del_func);
      usr_common.make_msg (v_ret_string, p_objecttype);
      usr_common.make_msg (v_ret_string, p_objectid);
      usr_common.make_msg (v_ret_string, p_groupid);
      usr_common.make_msg (v_ret_string, p_attrid);
      v_stat := usr_send_message (usr_common.m_pipename, v_ret_string);
      v_stat := usr_get_message (dbms_pipe.unique_session_name, v_ret_pipe, p_error_message);
   end;
end usr_categories; 
/
