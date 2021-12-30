create or replace package usr_notes
is
   c_set_func    constant number (5) := 1;
   c_del_func    constant number (5) := 2;
   c_note_type   constant number (5) := 3;

   procedure set_note (
      p_objecttype      in       number,
      p_objectid        in       varchar2,
      p_notekind        in       number,
      p_notevalue       in       varchar2,
      p_error_message   out      varchar2
   );

   procedure del_note (
      p_objecttype      in       number,
      p_objectid        in       varchar2,
      p_notekind        in       number,
      p_error_message   out      varchar2
   );
end usr_notes;
/
CREATE OR REPLACE PACKAGE BODY usr_notes
is
   procedure set_note (
      p_objecttype      in       number,
      p_objectid        in       varchar2,
      p_notekind        in       number,
      p_notevalue       in       varchar2,
      p_error_message   out      varchar2
   )
   is
      v_stat         number;
      v_ret_string   varchar2 (2048);
      v_ret_pipe     varchar2 (64);
   begin
   
      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_notes'),
                                            UPPER ('set_note'),
                                            ku$_vcnt (p_objecttype,
                                                      p_objectid,
                                                      p_notekind,
                                                      p_notevalue,
                                                      p_error_message));
                                                      
      usr_common.make_msg (v_ret_string, c_note_type);
      usr_common.make_msg (v_ret_string, c_set_func);
      usr_common.make_msg (v_ret_string, p_objecttype);
      usr_common.make_msg (v_ret_string, p_objectid);
      usr_common.make_msg (v_ret_string, p_notekind);
      usr_common.make_msg (v_ret_string, p_notevalue);
      v_stat := usr_send_message (usr_common.m_pipename, v_ret_string);
      v_stat := usr_get_message (dbms_pipe.unique_session_name, v_ret_pipe, p_error_message);
   end;

   procedure del_note (p_objecttype in number, p_objectid in varchar2, p_notekind in number, p_error_message out varchar2)
   is
      v_ret_string   varchar2 (2048);
      v_ret_pipe     varchar2 (64);
      v_stat         number;
   begin
   
      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_notes'),
                                            UPPER ('del_note'),
                                            ku$_vcnt (p_objecttype,
                                                      p_objectid,
                                                      p_notekind,
                                                      p_error_message)); 
   
      usr_common.make_msg (v_ret_string, c_note_type);
      usr_common.make_msg (v_ret_string, c_del_func);
      usr_common.make_msg (v_ret_string, p_objecttype);
      usr_common.make_msg (v_ret_string, p_objectid);
      usr_common.make_msg (v_ret_string, p_notekind);
      v_stat := usr_send_message (usr_common.m_pipename, v_ret_string);
      v_stat := usr_get_message (dbms_pipe.unique_session_name, v_ret_pipe, p_error_message);
   end;
end usr_notes; 
/
