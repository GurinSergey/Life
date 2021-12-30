create or replace package usr_clients
is
   c_createclient_func constant       number (5) := 1;
   c_updateclient_func constant       number (5) := 2;
   c_deleteclient_func constant       number (5) := 3;
   c_setclientservice_func constant   number (5) := 4;
   c_delclientservice_func constant   number (5) := 5;
   c_setclientcode_func constant      number (5) := 6;
   c_delclientcode_func constant      number (5) := 7;
   c_setclientaddress_func constant   number (5) := 8;
   c_delclientaddress_func constant   number (5) := 9;
   c_setclientregdoc_func constant    number (5) := 10;
   c_delclientregdoc_func constant    number (5) := 11;
   c_setclientofficer_func constant   number (5) := 12;
   c_delclientofficer_func constant   number (5) := 13;
   c_setclientpaper_func constant     number (5) := 14;
   c_delclientpaper_func constant     number (5) := 15;
   c_client_type constant             number (5) := 5;

   procedure create_client (p_legalform        in     varchar2,
                            p_shortname        in     varchar2 default null ,
                            p_fullname         in     varchar2 default null ,
                            p_addname          in     varchar2 default null ,
                            p_lastname         in     varchar2 default null ,
                            p_firstname        in     varchar2 default null ,
                            p_secondname       in     varchar2 default null ,
                            p_birthdate        in     date default null ,
                            p_birthplace       in     varchar2 default null ,
                            p_ismale           in     char default null ,
                            p_nationality      in     varchar2 default null ,
                            p_isemployer       in     char default null ,
                            p_workplace        in     varchar2 default null ,
                            p_okpo             in     varchar2 default null ,
                            p_country          in     varchar2 default null ,
                            p_superiorid       in     number default -1 ,
                            p_partyid             out number,
                            p_error_message       out varchar2,
                            p_charterdate      in     date default null ,
                            p_capitalfi_iso    in     varchar2 default null ,
                            p_declarecapital   in     number default null ,
                            p_realcapital      in     number default null ,
                            p_latname          in     varchar2 default null );

   procedure update_client (p_partyid          in     number,
                            p_shortname        in     varchar2 default null ,
                            p_fullname         in     varchar2 default null ,
                            p_addname          in     varchar2 default null ,
                            p_lastname         in     varchar2 default null ,
                            p_firstname        in     varchar2 default null ,
                            p_secondname       in     varchar2 default null ,
                            p_birthdate        in     date default null ,
                            p_birthplace       in     varchar2 default null ,
                            p_ismale           in     char default null ,
                            p_nationality      in     varchar2 default null ,
                            p_isemployer       in     char default null ,
                            p_workplace        in     varchar2 default null ,
                            p_okpo             in     varchar2 default null ,
                            p_country          in     varchar2 default null ,
                            p_superiorid       in     number default null ,
                            p_error_message       out varchar2,
                            p_charterdate      in     date default null ,
                            p_capitalfi_iso    in     varchar2 default null ,
                            p_declarecapital   in     number default null ,
                            p_realcapital      in     number default null ,
                            p_latname          in     varchar2 default null );

   procedure delete_client (p_partyid in number, p_error_message out varchar2);

   procedure set_client_service (p_partyid         in     number,
                                 p_servkind        in     number,
                                 p_oper            in     number default null ,
                                 p_startdate       in     date default null ,
                                 p_department      in     number default null ,
                                 p_branch          in     number,
                                 p_error_message      out varchar2);

   procedure del_client_service (p_partyid in number, p_servkind in number, p_error_message out varchar2);

   procedure set_client_code (p_partyid         in     number,
                              p_codekind        in     number,
                              p_codevalue       in out varchar2,
                              p_error_message      out varchar2);

   procedure del_client_code (p_partyid in number, p_codekind in number, p_error_message out varchar2);

   procedure set_client_address (p_partyid         in     number,
                                 p_addresstype     in     number,
                                 p_country         in     varchar2 default null ,
                                 p_address         in     varchar2,
                                 p_phonenumber     in     varchar2 default null ,
                                 p_phonenumberad   in     varchar2 default null ,
                                 p_faxnumber       in     varchar2 default null ,
                                 p_email           in     varchar2 default null ,
                                 p_error_message      out varchar2,
                                 p_mobilephone     in     varchar2 default null ,
                                 p_CodeDistrict    in     varchar2 default null ,
                                 p_CodePlace       in     varchar2 default null ,
                                 p_CodeProvince    in     varchar2 default null ,
                                 p_CodeRegion      in     varchar2 default null ,
                                 p_CodeStreet      in     varchar2 default null ,
                                 p_District        in     varchar2 default null ,
                                 p_Flat            in     varchar2 default null ,
                                 p_House           in     varchar2 default null ,
                                 p_MobileProvider  in     varchar2 default null ,
                                 p_NumCorps        in     varchar2 default null ,
                                 p_Place           in     varchar2 default null ,
                                 p_PostIndex       in     varchar2 default null ,
                                 p_Province        in     varchar2 default null ,
                                 p_Region          in     varchar2 default null ,
                                 p_RegionNumber    in     varchar2 default null ,
                                 p_RS_Mail_Country in     number default null ,
                                 p_RS_Mail_Node    in     number default null ,
                                 p_RS_Mail_Region  in     number default null ,
                                 p_Street          in     varchar2 default null ,
                                 p_Telegraph       in     varchar2 default null ,
                                 p_TelexNumber     in     varchar2 default null ,
                                 p_Territory       in     varchar2 default null);

   procedure del_client_address (p_partyid in number, p_addresstype in number, p_error_message out varchar2);

   procedure set_client_regdoc (p_partyid         in     number,
                                p_regpartykind    in     number,
                                p_regdockind      in     number,
                                p_regpartyid      in     number default null ,
                                p_regcode         in     varchar2 default null ,
                                p_startdate       in     date,
                                p_series          in     varchar2 default null ,
                                p_number          in     varchar2 default null ,
                                p_docdate         in     date default null ,
                                p_ismain          in     char default null ,
                                p_error_message      out varchar2);

   procedure del_client_regdoc (p_partyid         in     number,
                                p_regpartykind    in     number,
                                p_regdockind      in     number,
                                p_error_message      out varchar2);

   procedure set_client_officer (p_partyid          in     number,
                                 p_personid         in     number,
                                 p_isfirstperson    in     char default null ,
                                 p_issecondperson   in     char default null ,
                                 p_post             in     varchar2 default null ,
                                 p_error_message       out varchar,
                                 p_datefrom         in     date default null,
                                 p_dateto           in     date default null);

   procedure del_client_officer (p_partyid in number, p_personid in number, p_error_message out varchar);

   procedure set_client_paper (p_partyid         in     number,
                               p_paperkind       in     number,
                               p_series          in     varchar2 default null ,
                               p_number          in     varchar2,
                               p_issueddate      in     date default null ,
                               p_issuer          in     varchar2 default null ,
                               p_issuercode      in     varchar2 default null ,
                               p_error_message      out varchar2,
                               p_is_main in char default null);

   procedure del_client_paper (p_partyid in number, p_paperkind in number, p_error_message out varchar2);

   procedure get_partyid (p_code           varchar2,
                          p_codekind       number default 1 ,
                          p_partyid    out number,
                          p_error      out varchar2);
end usr_clients;
/
CREATE OR REPLACE PACKAGE BODY usr_clients
is
   function datetostring (p_date in date)
      return varchar2
   is
      v_ret_string   varchar2 (10);
   begin
      if p_date is null
      then
         v_ret_string := '00.00.0000';
      else
         v_ret_string := to_char (p_date, 'DD.MM.YYYY');
      end if;

      return v_ret_string;
   end;

   procedure create_client (p_legalform        in     varchar2,
                            p_shortname        in     varchar2 default null ,
                            p_fullname         in     varchar2 default null ,
                            p_addname          in     varchar2 default null ,
                            p_lastname         in     varchar2 default null ,
                            p_firstname        in     varchar2 default null ,
                            p_secondname       in     varchar2 default null ,
                            p_birthdate        in     date default null ,
                            p_birthplace       in     varchar2 default null ,
                            p_ismale           in     char default null ,
                            p_nationality      in     varchar2 default null ,
                            p_isemployer       in     char default null ,
                            p_workplace        in     varchar2 default null ,
                            p_okpo             in     varchar2 default null ,
                            p_country          in     varchar2 default null ,
                            p_superiorid       in     number default -1 ,
                            p_partyid             out number,
                            p_error_message       out varchar2,
                            p_charterdate      in     date default null ,
                            p_capitalfi_iso    in     varchar2 default null ,
                            p_declarecapital   in     number default null ,
                            p_realcapital      in     number default null ,
                            p_latname          in     varchar2 default null )
   is
      v_stat         number;
      v_ret_string   varchar2 (2048);
      v_ret_pipe     varchar2 (64);
   begin
   
      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_clients'),
                                            UPPER ('create_client'),
                                            ku$_vcnt (p_legalform,
                                                      p_shortname,
                                                      p_fullname,
                                                      p_addname,
                                                      p_lastname,
                                                      p_firstname,
                                                      p_secondname,
                                                      p_birthdate,
                                                      p_birthplace,
                                                      p_ismale,
                                                      p_nationality,
                                                      p_isemployer,
                                                      p_workplace,
                                                      p_okpo,
                                                      p_country,
                                                      p_superiorid,
                                                      p_partyid,
                                                      p_error_message,
                                                      p_charterdate,
                                                      p_capitalfi_iso,
                                                      p_declarecapital,
                                                      p_realcapital,
                                                      p_latname));
      if p_legalform = 1
      then
         if p_shortname is null
         then
            p_error_message := 'Не задано сокращенное наименование клиента';
            return;
         end if;

         if p_fullname is null
         then
            p_error_message := 'Не задано полное наименование клиента';
            return;
         end if;
      elsif p_legalform = 2
      then
         if p_lastname is null
         then
            p_error_message := 'Не задана фамилия клиента';
            return;
         end if;

         if p_firstname is null
         then
            p_error_message := 'Не задано имя клиента';
            return;
         end if;

         if p_secondname is null
         then
            p_error_message := 'Не задано отчество клиента';
            return;
         end if;
      else
         p_error_message := 'Неверно задан вид клиента';
         return;
      end if;

      usr_common.make_msg (v_ret_string, c_client_type);
      usr_common.make_msg (v_ret_string, c_createclient_func);
      usr_common.make_msg (v_ret_string, p_legalform);
      usr_common.make_msg (v_ret_string, p_shortname);
      usr_common.make_msg (v_ret_string, p_fullname);
      usr_common.make_msg (v_ret_string, p_addname);
      usr_common.make_msg (v_ret_string, p_lastname);
      usr_common.make_msg (v_ret_string, p_firstname);
      usr_common.make_msg (v_ret_string, p_secondname);
      usr_common.make_msg (v_ret_string, datetostring (p_birthdate));
      usr_common.make_msg (v_ret_string, p_birthplace);
      usr_common.make_msg (v_ret_string, p_ismale);
      usr_common.make_msg (v_ret_string, p_nationality);
      usr_common.make_msg (v_ret_string, p_isemployer);
      usr_common.make_msg (v_ret_string, p_workplace);
      usr_common.make_msg (v_ret_string, p_okpo);
      usr_common.make_msg (v_ret_string, p_country);
      usr_common.make_msg (v_ret_string, p_superiorid);
      usr_common.make_msg (v_ret_string, to_char (p_charterdate, 'DD.MM.YYYY'));
      usr_common.make_msg (v_ret_string, usr_common.get_fiid ('00000' || p_capitalfi_iso));
      usr_common.make_msg (v_ret_string, p_declarecapital);
      usr_common.make_msg (v_ret_string, p_realcapital);
      usr_common.make_msg (v_ret_string, p_latname);
      --dbms_output.put_line (v_ret_string);
      v_stat := usr_send_message (usr_common.m_pipename, v_ret_string);
      v_stat := usr_get_message (dbms_pipe.unique_session_name, v_ret_pipe, p_error_message);
      p_partyid := substr (p_error_message, 0, instr (p_error_message, usr_common.c_delimiter) - 1);
      p_error_message := substr (p_error_message, instr (p_error_message, usr_common.c_delimiter) + 1);
   end;

   procedure update_client (p_partyid          in     number,
                            p_shortname        in     varchar2 default null ,
                            p_fullname         in     varchar2 default null ,
                            p_addname          in     varchar2 default null ,
                            p_lastname         in     varchar2 default null ,
                            p_firstname        in     varchar2 default null ,
                            p_secondname       in     varchar2 default null ,
                            p_birthdate        in     date default null ,
                            p_birthplace       in     varchar2 default null ,
                            p_ismale           in     char default null ,
                            p_nationality      in     varchar2 default null ,
                            p_isemployer       in     char default null ,
                            p_workplace        in     varchar2 default null ,
                            p_okpo             in     varchar2 default null ,
                            p_country          in     varchar2 default null ,
                            p_superiorid       in     number default null ,
                            p_error_message       out varchar2,
                            p_charterdate      in     date default null ,
                            p_capitalfi_iso    in     varchar2 default null ,
                            p_declarecapital   in     number default null ,
                            p_realcapital      in     number default null ,
                            p_latname          in     varchar2 default null )
   is
      v_stat         number;
      v_ret_string   varchar2 (2048);
      v_ret_pipe     varchar2 (64);
   begin
   
      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_clients'),
                                            UPPER ('update_client'),
                                            ku$_vcnt (p_partyid,
                                                      p_shortname,
                                                      p_fullname,
                                                      p_addname,
                                                      p_lastname,
                                                      p_firstname,
                                                      p_secondname,
                                                      p_birthdate,
                                                      p_birthplace,
                                                      p_ismale,
                                                      p_nationality,
                                                      p_isemployer,
                                                      p_workplace,
                                                      p_okpo,
                                                      p_country,
                                                      p_superiorid,
                                                      p_error_message,
                                                      p_charterdate,
                                                      p_capitalfi_iso,
                                                      p_declarecapital,
                                                      p_realcapital,
                                                      p_latname));
                                                      
      usr_common.make_msg (v_ret_string, c_client_type);
      usr_common.make_msg (v_ret_string, c_updateclient_func);
      usr_common.make_msg (v_ret_string, p_partyid);
      usr_common.make_msg (v_ret_string, p_shortname);
      usr_common.make_msg (v_ret_string, p_fullname);
      usr_common.make_msg (v_ret_string, p_addname);
      usr_common.make_msg (v_ret_string, p_lastname);
      usr_common.make_msg (v_ret_string, p_firstname);
      usr_common.make_msg (v_ret_string, p_secondname);
      usr_common.make_msg (v_ret_string, to_char (p_birthdate, 'DD.MM.YYYY'));
      usr_common.make_msg (v_ret_string, p_birthplace);
      usr_common.make_msg (v_ret_string, p_ismale);
      usr_common.make_msg (v_ret_string, p_nationality);
      usr_common.make_msg (v_ret_string, p_isemployer);
      usr_common.make_msg (v_ret_string, p_workplace);
      usr_common.make_msg (v_ret_string, p_okpo);
      usr_common.make_msg (v_ret_string, p_country);
      usr_common.make_msg (v_ret_string, p_superiorid);
      usr_common.make_msg (v_ret_string, to_char (p_charterdate, 'DD.MM.YYYY'));
      if p_capitalfi_iso is not null
      then
         usr_common.make_msg (v_ret_string, usr_common.get_fiid ('00000' || p_capitalfi_iso));
      else
         usr_common.make_msg (v_ret_string, '');
      end if;
      usr_common.make_msg (v_ret_string, p_declarecapital);
      usr_common.make_msg (v_ret_string, p_realcapital);
      usr_common.make_msg (v_ret_string, p_latname);
      --dbms_output.put_line (v_ret_string);
      v_stat := usr_send_message (usr_common.m_pipename, v_ret_string);
      v_stat := usr_get_message (dbms_pipe.unique_session_name, v_ret_pipe, p_error_message);
   end;

   procedure delete_client (p_partyid in number, p_error_message out varchar2)
   is
      v_stat         number;
      v_ret_string   varchar2 (2048);
      v_ret_pipe     varchar2 (64);
   begin
   
      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_clients'),
                                            UPPER ('delete_client'),
                                            ku$_vcnt (p_partyid,
                                                      p_error_message));
                                                      
      usr_common.make_msg (v_ret_string, c_client_type);
      usr_common.make_msg (v_ret_string, c_deleteclient_func);
      usr_common.make_msg (v_ret_string, p_partyid);
      --dbms_output.put_line (v_ret_string);
      v_stat := usr_send_message (usr_common.m_pipename, v_ret_string);
      v_stat := usr_get_message (dbms_pipe.unique_session_name, v_ret_pipe, p_error_message);
   end;

   procedure set_client_service (p_partyid         in     number,
                                 p_servkind        in     number,
                                 p_oper            in     number default null ,
                                 p_startdate       in     date default null ,
                                 p_department      in     number default null ,
                                 p_branch          in     number,
                                 p_error_message      out varchar2)
   is
      v_stat         number;
      v_ret_string   varchar2 (2048);
      v_ret_pipe     varchar2 (64);
   begin
   
      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_clients'),
                                            UPPER ('set_client_service'),
                                            ku$_vcnt (p_partyid,
                                                      p_servkind,
                                                      p_oper,
                                                      p_startdate,
                                                      p_department,
                                                      p_branch,
                                                      p_error_message));
                                                      
      usr_common.make_msg (v_ret_string, c_client_type);
      usr_common.make_msg (v_ret_string, c_setclientservice_func);
      usr_common.make_msg (v_ret_string, p_partyid);
      usr_common.make_msg (v_ret_string, p_servkind);
      usr_common.make_msg (v_ret_string, p_oper);
      usr_common.make_msg (v_ret_string, datetostring (p_startdate));
      usr_common.make_msg (v_ret_string, p_department);
      usr_common.make_msg (v_ret_string, p_branch);
      --dbms_output.put_line (v_ret_string);
      v_stat := usr_send_message (usr_common.m_pipename, v_ret_string);
      v_stat := usr_get_message (dbms_pipe.unique_session_name, v_ret_pipe, p_error_message);
   end;

   procedure del_client_service (p_partyid in number, p_servkind in number, p_error_message out varchar2)
   is
      v_stat         number;
      v_ret_string   varchar2 (2048);
      v_ret_pipe     varchar2 (64);
   begin
      
      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_clients'),
                                            UPPER ('del_client_service'),
                                            ku$_vcnt (p_partyid,
                                                      p_servkind,
                                                      p_error_message));
   
      usr_common.make_msg (v_ret_string, c_client_type);
      usr_common.make_msg (v_ret_string, c_delclientservice_func);
      usr_common.make_msg (v_ret_string, p_partyid);
      usr_common.make_msg (v_ret_string, p_servkind);
      --dbms_output.put_line (v_ret_string);
      v_stat := usr_send_message (usr_common.m_pipename, v_ret_string);
      v_stat := usr_get_message (dbms_pipe.unique_session_name, v_ret_pipe, p_error_message);
   end;

   procedure set_client_code (p_partyid         in     number,
                              p_codekind        in     number,
                              p_codevalue       in out varchar2,
                              p_error_message      out varchar2)
   is
      v_stat         number;
      v_ret_string   varchar2 (2048);
      v_ret_pipe     varchar2 (64);
   begin
   
      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_clients'),
                                            UPPER ('set_client_code'),
                                            ku$_vcnt (p_partyid,
                                                      p_codekind,
                                                      p_codevalue,
                                                      p_error_message));
                                                      
      usr_common.make_msg (v_ret_string, c_client_type);
      usr_common.make_msg (v_ret_string, c_setclientcode_func);
      usr_common.make_msg (v_ret_string, p_partyid);
      usr_common.make_msg (v_ret_string, p_codekind);
      usr_common.make_msg (v_ret_string, trim (p_codevalue));
      --dbms_output.put_line (v_ret_string);
      v_stat := usr_send_message (usr_common.m_pipename, v_ret_string);
      v_stat := usr_get_message (dbms_pipe.unique_session_name, v_ret_pipe, p_error_message);

      if trim (p_codevalue) is null
      then
         p_codevalue := substr (p_error_message, instr (p_error_message, usr_common.c_delimiter) + 1);
         p_error_message := substr (p_error_message, 1, instr (p_error_message, usr_common.c_delimiter) - 1);
      end if;
   end;

   procedure del_client_code (p_partyid in number, p_codekind in number, p_error_message out varchar2)
   is
      v_stat         number;
      v_ret_string   varchar2 (2048);
      v_ret_pipe     varchar2 (64);
   begin
   
      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_clients'),
                                            UPPER ('del_client_code'),
                                            ku$_vcnt (p_partyid,
                                                      p_codekind,
                                                      p_error_message));
                                                      
      usr_common.make_msg (v_ret_string, c_client_type);
      usr_common.make_msg (v_ret_string, c_delclientcode_func);
      usr_common.make_msg (v_ret_string, p_partyid);
      usr_common.make_msg (v_ret_string, p_codekind);
      --dbms_output.put_line (v_ret_string);
      v_stat := usr_send_message (usr_common.m_pipename, v_ret_string);
      v_stat := usr_get_message (dbms_pipe.unique_session_name, v_ret_pipe, p_error_message);
   end;

   procedure set_client_address (p_partyid         in     number,
                                 p_addresstype     in     number,
                                 p_country         in     varchar2 default null ,
                                 p_address         in     varchar2,
                                 p_phonenumber     in     varchar2 default null ,
                                 p_phonenumberad   in     varchar2 default null ,
                                 p_faxnumber       in     varchar2 default null ,
                                 p_email           in     varchar2 default null ,
                                 p_error_message      out varchar2,
                                 p_mobilephone     in     varchar2 default null ,
                                 p_CodeDistrict    in     varchar2 default null ,
                                 p_CodePlace       in     varchar2 default null ,
                                 p_CodeProvince    in     varchar2 default null ,
                                 p_CodeRegion      in     varchar2 default null ,
                                 p_CodeStreet      in     varchar2 default null ,
                                 p_District        in     varchar2 default null ,
                                 p_Flat            in     varchar2 default null ,
                                 p_House           in     varchar2 default null ,
                                 p_MobileProvider  in     varchar2 default null ,
                                 p_NumCorps        in     varchar2 default null ,
                                 p_Place           in     varchar2 default null ,
                                 p_PostIndex       in     varchar2 default null ,
                                 p_Province        in     varchar2 default null ,
                                 p_Region          in     varchar2 default null ,
                                 p_RegionNumber    in     varchar2 default null ,
                                 p_RS_Mail_Country in     number default null ,
                                 p_RS_Mail_Node    in     number default null ,
                                 p_RS_Mail_Region  in     number default null ,
                                 p_Street          in     varchar2 default null ,
                                 p_Telegraph       in     varchar2 default null ,
                                 p_TelexNumber     in     varchar2 default null ,
                                 p_Territory       in     varchar2 default null)
   is
      v_stat         number;
      v_ret_string   varchar2 (2048);
      v_ret_pipe     varchar2 (64);
   begin
   
      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_clients'),
                                            UPPER ('set_client_address'),
                                            ku$_vcnt (p_partyid,
                                                      p_addresstype,
                                                      p_country,
                                                      p_address,
                                                      p_phonenumber,
                                                      p_phonenumberad,
                                                      p_faxnumber,
                                                      p_email,
                                                      p_error_message,
                                                      p_mobilephone,
                                                      p_CodeDistrict,
                                                      p_CodePlace,
                                                      p_CodeProvince,
                                                      p_CodeRegion,
                                                      p_CodeStreet,
                                                      p_District,
                                                      p_Flat,
                                                      p_House,
                                                      p_MobileProvider,
                                                      p_NumCorps,
                                                      p_Place,
                                                      p_PostIndex,
                                                      p_Province,
                                                      p_Region,
                                                      p_RegionNumber,
                                                      p_RS_Mail_Country,
                                                      p_RS_Mail_Node,
                                                      p_RS_Mail_Region,
                                                      p_Street,
                                                      p_Telegraph,
                                                      p_TelexNumber,
                                                      p_Territory));
                                                      
      usr_common.make_msg (v_ret_string, c_client_type);
      usr_common.make_msg (v_ret_string, c_setclientaddress_func);
      usr_common.make_msg (v_ret_string, p_partyid);
      usr_common.make_msg (v_ret_string, p_addresstype);
      usr_common.make_msg (v_ret_string, p_country);
      usr_common.make_msg (v_ret_string, p_address);
      usr_common.make_msg (v_ret_string, p_phonenumber);
      usr_common.make_msg (v_ret_string, p_phonenumberad);
      usr_common.make_msg (v_ret_string, p_faxnumber);
      usr_common.make_msg (v_ret_string, p_email);
      usr_common.make_msg (v_ret_string, p_mobilephone);
      usr_common.make_msg (v_ret_string, p_CodeDistrict);
      usr_common.make_msg (v_ret_string, p_CodePlace);
      usr_common.make_msg (v_ret_string, p_CodeProvince);
      usr_common.make_msg (v_ret_string, p_CodeRegion);
      usr_common.make_msg (v_ret_string, p_CodeStreet);
      usr_common.make_msg (v_ret_string, p_District);
      usr_common.make_msg (v_ret_string, p_Flat);
      usr_common.make_msg (v_ret_string, p_House);
      usr_common.make_msg (v_ret_string, p_MobileProvider);
      usr_common.make_msg (v_ret_string, p_NumCorps);
      usr_common.make_msg (v_ret_string, p_Place);
      usr_common.make_msg (v_ret_string, p_PostIndex);
      usr_common.make_msg (v_ret_string, p_Province);
      usr_common.make_msg (v_ret_string, p_Region);
      usr_common.make_msg (v_ret_string, p_RegionNumber);
      usr_common.make_msg (v_ret_string, p_RS_Mail_Country);
      usr_common.make_msg (v_ret_string, p_RS_Mail_Node);
      usr_common.make_msg (v_ret_string, p_RS_Mail_Region);
      usr_common.make_msg (v_ret_string, p_Street);
      usr_common.make_msg (v_ret_string, p_Telegraph);
      usr_common.make_msg (v_ret_string, p_TelexNumber);
      usr_common.make_msg (v_ret_string, p_Territory);

      --dbms_output.put_line (v_ret_string);
      v_stat := usr_send_message (usr_common.m_pipename, v_ret_string);
      v_stat := usr_get_message (dbms_pipe.unique_session_name, v_ret_pipe, p_error_message);
   end;

   procedure del_client_address (p_partyid in number, p_addresstype in number, p_error_message out varchar2)
   is
      v_stat         number;
      v_ret_string   varchar2 (2048);
      v_ret_pipe     varchar2 (64);
   begin
   
      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_clients'),
                                            UPPER ('del_client_address'),
                                            ku$_vcnt (p_partyid,
                                                      p_addresstype,
                                                      p_error_message));
                                                      
      usr_common.make_msg (v_ret_string, c_client_type);
      usr_common.make_msg (v_ret_string, c_delclientaddress_func);
      usr_common.make_msg (v_ret_string, p_partyid);
      usr_common.make_msg (v_ret_string, p_addresstype);
      --dbms_output.put_line (v_ret_string);
      v_stat := usr_send_message (usr_common.m_pipename, v_ret_string);
      v_stat := usr_get_message (dbms_pipe.unique_session_name, v_ret_pipe, p_error_message);
   end;

   procedure set_client_regdoc (p_partyid         in     number,
                                p_regpartykind    in     number,
                                p_regdockind      in     number,
                                p_regpartyid      in     number default null ,
                                p_regcode         in     varchar2 default null ,
                                p_startdate       in     date,
                                p_series          in     varchar2 default null ,
                                p_number          in     varchar2 default null ,
                                p_docdate         in     date default null ,
                                p_ismain          in     char default null ,
                                p_error_message      out varchar2)
   is
      v_stat         number;
      v_ret_string   varchar2 (2048);
      v_ret_pipe     varchar2 (64);
      v_regpartyid   number;
   begin
   
      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_clients'),
                                            UPPER ('set_client_regdoc'),
                                            ku$_vcnt (p_partyid,
                                                      p_regpartykind,
                                                      p_regdockind,
                                                      p_regpartyid,
                                                      p_regcode,
                                                      p_startdate,
                                                      p_series,
                                                      p_number,
                                                      p_docdate,
                                                      p_ismain,
                                                      p_error_message));
                                                      
      if p_regpartyid is null
      then
         select   code.t_objectid
           into   v_regpartyid
           from   dpartyown_dbt ptown, dobjcode_dbt code
          where       code.t_objectid = ptown.t_partyid
                  and ptown.t_partykind = 6
                  and code.t_objecttype = 3
                  and code.t_codekind = 28
                  and t_code = p_regcode;
      else
         v_regpartyid := p_regpartyid;
      end if;

      usr_common.make_msg (v_ret_string, c_client_type);
      usr_common.make_msg (v_ret_string, c_setclientregdoc_func);
      usr_common.make_msg (v_ret_string, p_partyid);
      usr_common.make_msg (v_ret_string, p_regpartykind);
      usr_common.make_msg (v_ret_string, p_regdockind);
      usr_common.make_msg (v_ret_string, v_regpartyid);
      usr_common.make_msg (v_ret_string, datetostring (p_startdate));
      usr_common.make_msg (v_ret_string, p_series);
      usr_common.make_msg (v_ret_string, p_number);
      usr_common.make_msg (v_ret_string, datetostring (p_docdate));
      usr_common.make_msg (v_ret_string, p_ismain);
      --dbms_output.put_line (v_ret_string);
      v_stat := usr_send_message (usr_common.m_pipename, v_ret_string);
      v_stat := usr_get_message (dbms_pipe.unique_session_name, v_ret_pipe, p_error_message);
   exception
      when no_data_found
      then
         p_error_message := 'не найден регистрирующий орган по коду ' || p_regcode;
   end;

   procedure del_client_regdoc (p_partyid         in     number,
                                p_regpartykind    in     number,
                                p_regdockind      in     number,
                                p_error_message      out varchar2)
   is
      v_stat         number;
      v_ret_string   varchar2 (2048);
      v_ret_pipe     varchar2 (64);
   begin
   
      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_clients'),
                                            UPPER ('del_client_regdoc'),
                                            ku$_vcnt (p_partyid,
                                                      p_regpartykind,
                                                      p_regdockind,
                                                      p_error_message));
                                                      
      usr_common.make_msg (v_ret_string, c_client_type);
      usr_common.make_msg (v_ret_string, c_delclientregdoc_func);
      usr_common.make_msg (v_ret_string, p_partyid);
      usr_common.make_msg (v_ret_string, p_regpartykind);
      usr_common.make_msg (v_ret_string, p_regdockind);
      --dbms_output.put_line (v_ret_string);
      v_stat := usr_send_message (usr_common.m_pipename, v_ret_string);
      v_stat := usr_get_message (dbms_pipe.unique_session_name, v_ret_pipe, p_error_message);
   end;

   procedure set_client_officer (p_partyid          in     number,
                                 p_personid         in     number,
                                 p_isfirstperson    in     char default null ,
                                 p_issecondperson   in     char default null ,
                                 p_post             in     varchar2 default null ,
                                 p_error_message       out varchar,
                                 p_datefrom         in     date,
                                 p_dateto           in     date)
   is
      v_stat         number;
      v_ret_string   varchar2 (2048);
      v_ret_pipe     varchar2 (64);
   begin
   
      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_clients'),
                                            UPPER ('set_client_officer'),
                                            ku$_vcnt (p_partyid,
                                                      p_personid,
                                                      p_isfirstperson,
                                                      p_issecondperson,
                                                      p_post,
                                                      p_error_message,
                                                      p_datefrom,
                                                      p_dateto));
   
      usr_common.make_msg (v_ret_string, c_client_type);
      usr_common.make_msg (v_ret_string, c_setclientofficer_func);
      usr_common.make_msg (v_ret_string, p_partyid);
      usr_common.make_msg (v_ret_string, p_personid);
      usr_common.make_msg (v_ret_string, p_isfirstperson);
      usr_common.make_msg (v_ret_string, p_issecondperson);
      usr_common.make_msg (v_ret_string, p_post);
      usr_common.make_msg (v_ret_string, datetostring (p_datefrom));
      usr_common.make_msg (v_ret_string, datetostring (p_dateto));
      --dbms_output.put_line (v_ret_string);
      v_stat := usr_send_message (usr_common.m_pipename, v_ret_string);
      v_stat := usr_get_message (dbms_pipe.unique_session_name, v_ret_pipe, p_error_message);
   end;

   procedure del_client_officer (p_partyid in number, p_personid in number, p_error_message out varchar)
   is
      v_stat         number;
      v_ret_string   varchar2 (2048);
      v_ret_pipe     varchar2 (64);
   begin
   
      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_clients'),
                                            UPPER ('del_client_officer'),
                                            ku$_vcnt (p_partyid,
                                                      p_personid,
                                                      p_error_message));
                                                      
      usr_common.make_msg (v_ret_string, c_client_type);
      usr_common.make_msg (v_ret_string, c_delclientofficer_func);
      usr_common.make_msg (v_ret_string, p_partyid);
      usr_common.make_msg (v_ret_string, p_personid);
      --dbms_output.put_line (v_ret_string);
      v_stat := usr_send_message (usr_common.m_pipename, v_ret_string);
      v_stat := usr_get_message (dbms_pipe.unique_session_name, v_ret_pipe, p_error_message);
   end;

   procedure set_client_paper (p_partyid         in     number,
                               p_paperkind       in     number,
                               p_series          in     varchar2 default null ,
                               p_number          in     varchar2,
                               p_issueddate      in     date default null ,
                               p_issuer          in     varchar2 default null ,
                               p_issuercode      in     varchar2 default null ,
                               p_error_message      out varchar2,
                               p_is_main in char default null)
   is
      v_stat         number;
      v_ret_string   varchar2 (2048);
      v_ret_pipe     varchar2 (64);
   begin
   
      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_clients'),
                                            UPPER ('set_client_paper'),
                                            ku$_vcnt (p_partyid,
                                                      p_paperkind,
                                                      p_series,
                                                      p_number,
                                                      p_issueddate,
                                                      p_issuer,
                                                      p_issuercode,
                                                      p_error_message,
                                                      p_is_main));
                                                      
      usr_common.make_msg (v_ret_string, c_client_type);
      usr_common.make_msg (v_ret_string, c_setclientpaper_func);
      usr_common.make_msg (v_ret_string, p_partyid);
      usr_common.make_msg (v_ret_string, p_paperkind);
      usr_common.make_msg (v_ret_string, p_series);
      usr_common.make_msg (v_ret_string, p_number);
      usr_common.make_msg (v_ret_string, datetostring (p_issueddate));
      usr_common.make_msg (v_ret_string, p_issuer);
      usr_common.make_msg (v_ret_string, p_issuercode);
      usr_common.make_msg (v_ret_string, p_is_main);
      --dbms_output.put_line (v_ret_string);
      v_stat := usr_send_message (usr_common.m_pipename, v_ret_string);
      v_stat := usr_get_message (dbms_pipe.unique_session_name, v_ret_pipe, p_error_message);
   end;

   procedure del_client_paper (p_partyid in number, p_paperkind in number, p_error_message out varchar2)
   is
      v_stat         number;
      v_ret_string   varchar2 (2048);
      v_ret_pipe     varchar2 (64);
   begin
   
      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_clients'),
                                            UPPER ('del_client_paper'),
                                            ku$_vcnt (p_partyid,
                                                      p_paperkind,
                                                      p_error_message));    
   
      usr_common.make_msg (v_ret_string, c_client_type);
      usr_common.make_msg (v_ret_string, c_delclientpaper_func);
      usr_common.make_msg (v_ret_string, p_partyid);
      usr_common.make_msg (v_ret_string, p_paperkind);
      --dbms_output.put_line (v_ret_string);
      v_stat := usr_send_message (usr_common.m_pipename, v_ret_string);
      v_stat := usr_get_message (dbms_pipe.unique_session_name, v_ret_pipe, p_error_message);
   end;

   procedure get_partyid (p_code           varchar2,
                          p_codekind       number default 1 ,
                          p_partyid    out number,
                          p_error      out varchar2)
   is
   begin
   
      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_clients'),
                                            UPPER ('get_partyid'),
                                            ku$_vcnt (p_code,
                                                      p_codekind,
                                                      p_partyid,
                                                      p_error));
                                                      
      p_error := usr_common.c_err_success;

      select   t_objectid
        into   p_partyid
        from   dobjcode_dbt
       where   t_objecttype = 3 and t_codekind = p_codekind and t_code = p_code;
   exception
      when no_data_found
      then
         p_error := 'Не найден клиент с кодом "' || p_code || '" вида "' || p_codekind;
      when others
      then
         p_error := 'Ошибка при выполнении процедуры ' || dbms_utility.format_error_stack || dbms_utility.format_error_backtrace;
   end;
end usr_clients; 
/
