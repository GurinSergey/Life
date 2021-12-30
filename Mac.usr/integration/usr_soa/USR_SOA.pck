CREATE OR REPLACE PACKAGE USR_SOA
IS
   -- преобразование текста
   FUNCTION converttext (text IN VARCHAR2)
      RETURN VARCHAR2;

   --отправка сообщения outrs6
   PROCEDURE outrs6 (p_DocType               NUMBER,
                     p_rule_id               NUMBER,
                     p_paymentid             NUMBER,
                     p_ResultProvod          NUMBER,
                     p_comment               VARCHAR2,
                     p_oper                  NUMBER,
                     p_ErrCode           OUT NUMBER,
                     p_ErrMsg            OUT VARCHAR2,
                     p_BizErrCode        OUT NUMBER,
                     p_BizErrMsg         OUT VARCHAR2,
                     p_KonsolidAccount   OUT VARCHAR2,
                     p_ClientFIO         OUT VARCHAR2,
                     p_PayCode           OUT NUMBER,
                     p_error_count       OUT NUMBER,
                     p_error             OUT VARCHAR2);

   --отправка сообщения outrs6ib
   PROCEDURE outrs6ib (p_DocType               NUMBER,
                       p_rule_id               NUMBER,
                       p_paymentid             NUMBER,
                       p_ResultProvod          NUMBER,
                       p_comment               VARCHAR2,
                       p_oper                  NUMBER,
                       p_ErrCode           OUT NUMBER,
                       p_ErrMsg            OUT VARCHAR2,
                       p_BizErrCode        OUT NUMBER,
                       p_BizErrMsg         OUT VARCHAR2,
                       p_KonsolidAccount   OUT VARCHAR2,
                       p_ClientFIO         OUT VARCHAR2,
                       p_PayCode           OUT NUMBER,
                       p_error_count       OUT NUMBER,
                       p_error             OUT VARCHAR2);

   --отправка сообщения outrs6DelDoc
   PROCEDURE outrs6DelDoc (p_DocType               NUMBER,
                           p_rule_id               NUMBER,
                           p_paymentid             NUMBER,
                           p_ResultProvod          NUMBER,
                           p_comment               VARCHAR2,
                           p_oper                  NUMBER,
                           p_ErrCode           OUT NUMBER,
                           p_ErrMsg            OUT VARCHAR2,
                           p_BizErrCode        OUT NUMBER,
                           p_BizErrMsg         OUT VARCHAR2,
                           p_KonsolidAccount   OUT VARCHAR2,
                           p_ClientFIO         OUT VARCHAR2,
                           p_PayCode           OUT NUMBER,
                           p_error_count       OUT NUMBER,
                           p_error             OUT VARCHAR2);

   --передача сводного счета
   PROCEDURE send_account (p_paymentid             NUMBER,
                           p_KonsolidAccount       VARCHAR2,
                           p_PayCode               NUMBER,
                           p_ReasonUnk             VARCHAR2 DEFAULT NULL ,
                           p_error_count       OUT NUMBER,
                           p_error             OUT VARCHAR2);
END; 
/
CREATE OR REPLACE PACKAGE BODY USR_SOA
is

   c_mode_debug boolean := false;

   c_postfix_request  constant varchar2(10)  := 'request';
   c_postfix_response constant varchar2(10)  := 'response';
   c_xmlns_soap       constant varchar2(100) := 'xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"';
   c_xmlns_env        constant varchar2(100) := 'xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"';
   c_xmlns            constant varchar2(100) := 'http://Interfacers6';
   gv_postfix_time             varchar2(100) := 'T00:00:00+04:00';
   c_bad_sybols       constant varchar2(10)  := '<>&';
   
   -- преобразование текста
   function converttext(text in varchar2)
     return varchar2
   is
   begin
     return translate(text,c_bad_sybols,lpad(' ',length(c_bad_sybols),' '));
   end;

   -- получение ответа
   function resp_extract_number(
      p_resp        XMLType,
      p_soap_node   varchar2,
      p_field       varchar2
   )return number
   is
      v_tresp       XMLType;
   begin
      if(p_resp.Extract(p_soap_node||'_'||c_postfix_response||'/AnsInfo/'||p_field||'/text()','xmlns="'||c_xmlns||'"') is not null) then
        v_tresp := p_resp.extract(p_soap_node||'_'||c_postfix_response||'/AnsInfo/'||p_field||'/text()','xmlns="'||c_xmlns||'"');
        return v_tresp.getnumberval();
      end if;
      return 0;
    exception
       when others then
            return 0;
   end;

   function resp_extract_varchar(
      p_resp        XMLType,
      p_soap_node   varchar2,
      p_field       varchar2
   )return varchar2
   is
      v_tresp       XMLType;
   begin
--      if(p_resp.Extract('outrs6_response/AnsInfo/BizErrMsg/text()','xmlns="http://Interfacers6"') is not null) then
      if(p_resp.Extract(p_soap_node||'_'||c_postfix_response||'/AnsInfo/'||p_field||'/text()','xmlns="'||c_xmlns||'"') is not null) then
        v_tresp := p_resp.extract(p_soap_node||'_'||c_postfix_response||'/AnsInfo/'||p_field||'/text()','xmlns="'||c_xmlns||'"');
        return v_tresp.getStringVal();
      end if;
      return null;
    exception
       when others then
            return null;
   end;

  -- Получение параметров соединения
  procedure get_soa_parameters(
     p_rule_id     in     number,
     v_url         in out varchar2,
     v_soap_node   in out varchar2,
     p_error_count in out number,
     p_error       in out varchar2)
  is
  begin
      select p.connstring,
             substr(p.extprocname||'(',1,instr(p.extprocname||'(','(')-1) extprocname
        into v_url, v_soap_node
        from usr_route_parm p
       where p.rule_id = p_rule_id;
      --v_url:= 'http://172.16.3.196:8001/soa-infra/services/rs6/rs6_out/rs6_opersProcess_ep';
      --v_soap_node   := 'outrs6';
    exception
       when others then
               p_error_count := 1;
               p_error := 'Ошибка выполнения: Правило маршрутизации '||p_rule_id||' не найдено';
  end get_soa_parameters;

  -- Отправка запроса и получение результата
  procedure extract_answer(
     v_soap_request  in     clob,
     v_url           in     varchar2,
     v_soap_action   in     varchar2,
     v_resp          in out XMLType,
      p_error_count  in out number,
      p_error        in out varchar2)
  is
    v_soap_respond        clob;
    v_http_req            utl_http.req;
    v_http_resp           utl_http.resp;
  begin
      v_http_req:= utl_http.begin_request(v_url, 'POST', 'HTTP/1.1');
      utl_http.set_header(v_http_req, 'Content-Type', 'text/xml; charset=Cp866');
      utl_http.set_header(v_http_req, 'Content-Length', length(v_soap_request));
      utl_http.set_header(v_http_req, 'SOAPAction', v_soap_action);
      utl_http.write_text(v_http_req, v_soap_request);

--      utl_http.set_transfer_timeout(60); -- выставление time out в секундах, по факту время ожидания выполнения вебсервиса. default 60 сек

      v_http_resp:= utl_http.get_response(v_http_req);
      utl_http.read_text(v_http_resp, v_soap_respond);
      utl_http.end_response(v_http_resp);

      v_resp:= XMLType.createXML(v_soap_respond);
      v_resp:= v_resp.extract('/env:Envelope/env:Body/child::node()',
                              c_xmlns_env
                              );

   exception
      when others then
              p_error_count := 1;
               --LAO Пишем лог ошибки в нормальном виде
              p_error:=SQLERRM;
              DELETE FROM usr_debug_dump WHERE   paymentid = TO_CHAR (SYSDATE, 'ddmmyyhh24mi');
              INSERT INTO usr_debug_dump VALUES   (TO_CHAR (SYSDATE, 'ddmmyyhh24mi'),p_error );
              p_error := 'Недоступна шина SOA';
          
  end extract_answer;

  -- get_outrs6_request
  procedure get_outrs6_request(
      p_paymentid    in     number,
      p_DocType      in     number,
      p_soap_action  in     varchar2,
      p_soap_request in out clob,
      p_error_count  in out number,
      p_error        in out varchar2)
  is
  begin
      select         '<?xml version="1.0" encoding="Cp866" ?>
                      <soap:Envelope '||c_xmlns_soap||'>
                              <soap:Body xmlns:ns1="'||c_xmlns||'">
                                  <ns1:'||p_soap_action||'>
                                      <ns1:Payment>
                                          <ns1:PaymentID>'||p_paymentid||'</ns1:PaymentID>
                                          <ns1:PayerFIO>'||converttext(pmrm.t_payername)||'</ns1:PayerFIO>
                                          <ns1:PayerBankBIC>'||prd.t_bankcode||'</ns1:PayerBankBIC>
                                          <ns1:PayerAccount>'||pm.t_payeraccount||'</ns1:PayerAccount>
                                          <ns1:PayerINN>'||case instr(pmrm.t_payerinn,'/')
                                                             when 0 then pmrm.t_payerinn
                                                             else substr(pmrm.t_payerinn,1,instr(pmrm.t_payerinn,'/')-1)
                                                           end||'</ns1:PayerINN>
                                          <ns1:PayerKPP>'||case instr(pmrm.t_payerinn,'/')
                                                             when 0 then null
                                                             else substr(pmrm.t_payerinn,instr(pmrm.t_payerinn,'/')+1)
                                                           end||'</ns1:PayerKPP>
                                          <ns1:PayerBankName>'||converttext(pmrm.t_payerbankname)||'</ns1:PayerBankName>
                                          <ns1:ReceiverFIO>'||converttext(pmrm.t_receivername)||'</ns1:ReceiverFIO>
                                          <ns1:ReceiverBankBIC>'||prd.t_bankcode||'</ns1:ReceiverBankBIC>
                                          <ns1:ReceiverAccount>'||pm.t_receiveraccount||'</ns1:ReceiverAccount>
                                          <ns1:ReceiverINN>'||case instr(pmrm.t_receiverinn,'/')
                                                            when 0 then pmrm.t_receiverinn
                                                            else substr(pmrm.t_receiverinn,1,instr(pmrm.t_receiverinn,'/')-1)
                                                          end||'</ns1:ReceiverINN>
                                          <ns1:ReceiverKPP>'||case instr(pmrm.t_receiverinn,'/')
                                                            when 0 then null
                                                            else substr(pmrm.t_receiverinn,instr(pmrm.t_receiverinn,'/')+1)
                                                          end||'</ns1:ReceiverKPP>
                                          <ns1:PayerCorrAcc>'||pmrm.t_payercorraccnostro||'</ns1:PayerCorrAcc>
                                          <ns1:ReceiverCorrAcc>'||pmrm.t_receivercorraccnostro||'</ns1:ReceiverCorrAcc>
                                          <ns1:Amount>'||pm.t_amount||'</ns1:Amount>
                                          <ns1:AmountCurrISO>'||pm.t_baseamount||'</ns1:AmountCurrISO>
                                          <ns1:DocNum>'||pmrm.t_number||'</ns1:DocNum>
                                          <ns1:DocDate>'||to_char(pm.t_valuedate, 'YYYY-MM-DD')||gv_postfix_time||'</ns1:DocDate>
                                          <ns1:Ground>'||converttext(pmrm.t_ground)||'</ns1:Ground>
                                          <ns1:DocType>'||p_DocType||'</ns1:DocType>
                                      </ns1:Payment>
                                      <ns1:AuthInfo>
                                          <ns1:userName>34534534</ns1:userName>
                                          <ns1:passWord>534534534</ns1:passWord>
                                      </ns1:AuthInfo>
                                  </ns1:'||p_soap_action||'>
                              </soap:Body>
                          </soap:Envelope>' into p_soap_request
        from dpmpaym_dbt pm,
             dpmrmprop_dbt pmrm,
             dpmprop_dbt prd,
             dpmprop_dbt prc
       where pm.t_paymentid = p_paymentid
         and pm.t_paymentid = pmrm.t_paymentid
         and pm.t_paymentid = prd.t_paymentid
         and pm.t_paymentid = prc.t_paymentid
         and prd.t_debetcredit = 0
         and prc.t_debetcredit = 1;
      p_soap_request := replace(p_soap_request,chr(1),null);
--insert into usr_debug_dump values (p_paymentid,p_soap_request);--убрать
    exception
       when others then
               p_error_count := 1;
               p_error := 'Ошибка выполнения: Платёж '||p_paymentid||' не найден';
  end get_outrs6_request;

  -- get_outrs6_request
  procedure get_outrs6ib_request(
      p_paymentid    in     number,
      p_ResultProvod in     number,
      p_Comment      in     varchar2,
      p_soap_action  in     varchar2,
      p_soap_request in out clob,
      p_error_count  in out number,
      p_error        in out varchar2)
  is
  begin
      p_soap_request :=  '<?xml version="1.0" encoding="Cp866" ?>
                          <soap:Envelope '||c_xmlns_soap||'>
                              <soap:Body xmlns:ns1="'||c_xmlns||'">
                                  <ns1:'||p_soap_action||'>
                                      <ns1:PaymentID>'||p_paymentid||'</ns1:PaymentID>
                                      <ns1:ResultProvod>'||p_ResultProvod||'</ns1:ResultProvod>
                                      <ns1:Comment>'||converttext(p_Comment)||'</ns1:Comment>
                                  </ns1:'||p_soap_action||'>
                              </soap:Body>
                          </soap:Envelope>';
      p_soap_request := replace(p_soap_request,chr(1),null);
    exception
       when others then
               p_error_count := 1;
               p_error := 'Ошибка выполнения';
  end get_outrs6ib_request;

  -- get_outrs6DelDoc_request
  procedure get_outrs6DelDoc_request(
      p_paymentid    in     number,
      p_comment      in     varchar2,
      p_oper         in     number,
      p_soap_action  in     varchar2,
      p_soap_request in out clob,
      p_error_count  in out number,
      p_error        in out varchar2)
  is
  begin
      p_soap_request :=  '<?xml version="1.0" encoding="Cp866" ?>
                          <soap:Envelope '||c_xmlns_soap||'>
                              <soap:Body xmlns:ns1="'||c_xmlns||'">
                                  <ns1:'||p_soap_action||'>
                                      <ns1:PaymentID>'||p_paymentid||'</ns1:PaymentID>
                                      <ns1:DelDocMessage>'||converttext(p_comment)||'</ns1:DelDocMessage>
                                      <ns1:OperID>'||p_oper||'</ns1:OperID>
                                  </ns1:'||p_soap_action||'>
                              </soap:Body>
                          </soap:Envelope>';
      p_soap_request := replace(p_soap_request,chr(1),null);
    exception
       when others then
               p_error_count := 1;
               p_error := 'Ошибка выполнения';
  end get_outrs6DelDoc_request;

   --отправка сообщения outrs6
   procedure outrs6 (
      p_DocType             number,
      p_rule_id             number,
      p_paymentid           number,
      p_ResultProvod        number,
      p_comment             varchar2,
      p_oper                number,
      p_ErrCode         out number,
      p_ErrMsg          out varchar2,
      p_BizErrCode      out number,
      p_BizErrMsg       out varchar2,
      p_KonsolidAccount out varchar2,
      p_ClientFIO       out varchar2,
      p_PayCode         out number,
      p_error_count     out number,
      p_error           out varchar2
   )
   is
      v_soap_request        clob;
      v_resp                XMLType;
      v_url                 varchar2(500);
      v_soap_node           varchar2(100);
      v_soap_action         varchar2(100);
   begin

      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_soa'),
                                            UPPER ('outrs6'),
                                            ku$_vcnt (p_DocType,
                                                      p_rule_id,
                                                      p_paymentid,
                                                      p_ResultProvod,
                                                      p_comment,
                                                      p_oper,
                                                      p_ErrCode,
                                                      p_ErrMsg,
                                                      p_BizErrCode,
                                                      p_BizErrMsg,
                                                      p_KonsolidAccount,
                                                      p_ClientFIO,
                                                      p_PayCode,
                                                      p_error_count,
                                                      p_error));

      p_error_count := 0;
      p_error := usr_common.c_err_success;

      -- Следующие 2 настройки ситаются из таблицы маршрутизации
      get_soa_parameters(p_rule_id, v_url, v_soap_node, p_error_count, p_error);

      if p_error_count=0 then

        v_soap_action := v_soap_node||'_'||c_postfix_request; -- метод

        get_outrs6_request(p_paymentid, p_DocType, v_soap_action, v_soap_request, p_error_count, p_error);

        if p_error_count=0 then

          if c_mode_debug then
            delete from usr_debug_dump d where d.paymentid=p_paymentid;
            insert into usr_debug_dump values (p_paymentid,v_soap_request);
          end if;

          extract_answer(v_soap_request, v_url, v_soap_action, v_resp, p_error_count, p_error);

          if p_error_count=0 then

            p_ErrMsg          := resp_extract_varchar(v_resp,v_soap_node,'ErrMsg');
            p_ErrCode         := resp_extract_number (v_resp,v_soap_node,'ErrCode');
            p_BizErrMsg       := resp_extract_varchar(v_resp,v_soap_node,'BizErrMsg');
            p_BizErrCode      := resp_extract_number (v_resp,v_soap_node,'BizErrCode');
            p_KonsolidAccount := resp_extract_varchar(v_resp,v_soap_node,'KonsolidAccount');
            p_ClientFIO       := resp_extract_varchar(v_resp,v_soap_node,'ClientFIO');
            p_PayCode         := resp_extract_number (v_resp,v_soap_node,'PayCode');

          end if;

        end if;

      end if;

   exception
      when others then
              p_error_count := 1;
              p_error := 'Ошибка выполнения';
   end;

   --отправка сообщения outrs6ib
   procedure outrs6ib (
      p_DocType             number,
      p_rule_id             number,
      p_paymentid           number,
      p_ResultProvod        number,
      p_comment             varchar2,
      p_oper                number,
      p_ErrCode         out number,
      p_ErrMsg          out varchar2,
      p_BizErrCode      out number,
      p_BizErrMsg       out varchar2,
      p_KonsolidAccount out varchar2,
      p_ClientFIO       out varchar2,
      p_PayCode         out number,
      p_error_count     out number,
      p_error           out varchar2
   )
   is
      v_soap_request        clob;
      v_resp                XMLType;
      v_url                 varchar2(500);
      v_soap_node           varchar2(100);
      v_soap_action         varchar2(100);
   begin

      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_soa'),
                                            UPPER ('outrs6ib'),
                                            ku$_vcnt (p_DocType,
                                                      p_rule_id,
                                                      p_paymentid,
                                                      p_ResultProvod,
                                                      p_comment,
                                                      p_oper,
                                                      p_ErrCode,
                                                      p_ErrMsg,
                                                      p_BizErrCode,
                                                      p_BizErrMsg,
                                                      p_KonsolidAccount,
                                                      p_ClientFIO,
                                                      p_PayCode,
                                                      p_error_count,
                                                      p_error));

      p_error_count := 0;
      p_error := usr_common.c_err_success;

      -- Следующие 2 настройки ситаются из таблицы маршрутизации
      get_soa_parameters(p_rule_id, v_url, v_soap_node, p_error_count, p_error);

      if p_error_count=0 then

        v_soap_action := v_soap_node||'_'||c_postfix_request; -- метод

        get_outrs6ib_request(p_paymentid, p_ResultProvod, p_Comment, v_soap_action, v_soap_request, p_error_count, p_error);

        if p_error_count=0 then

          if c_mode_debug then
            delete from usr_debug_dump d where d.paymentid=p_paymentid;
            insert into usr_debug_dump values (p_paymentid,v_soap_request);
          end if;

          extract_answer(v_soap_request, v_url, v_soap_action, v_resp, p_error_count, p_error);

          if p_error_count=0 then

            p_ErrMsg          := resp_extract_varchar(v_resp,v_soap_node,'ErrMsg');
            p_ErrCode         := resp_extract_number (v_resp,v_soap_node,'ErrCode');
            p_BizErrMsg       := resp_extract_varchar(v_resp,v_soap_node,'BizErrMsg');
            p_BizErrCode      := resp_extract_number (v_resp,v_soap_node,'BizErrCode');
            p_KonsolidAccount := resp_extract_varchar(v_resp,v_soap_node,'KonsolidAccount');
            p_ClientFIO       := resp_extract_varchar(v_resp,v_soap_node,'ClientFIO');
            p_PayCode         := resp_extract_number (v_resp,v_soap_node,'PayCode');

          end if;

        end if;

      end if;

   exception
      when others then
              p_error_count := 1;
              p_error := 'Ошибка выполнения';
   end;


   --отправка сообщения outrs6DelDoc
   procedure outrs6DelDoc (
      p_DocType             number,
      p_rule_id             number,
      p_paymentid           number,
      p_ResultProvod        number,
      p_comment             varchar2,
      p_oper                number,
      p_ErrCode         out number,
      p_ErrMsg          out varchar2,
      p_BizErrCode      out number,
      p_BizErrMsg       out varchar2,
      p_KonsolidAccount out varchar2,
      p_ClientFIO       out varchar2,
      p_PayCode         out number,
      p_error_count     out number,
      p_error           out varchar2
   )is
      v_soap_request        clob;
      v_resp                XMLType;
      v_url                 varchar2(500);
      v_soap_node           varchar2(100);
      v_soap_action         varchar2(100);
   begin

      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_soa'),
                                            UPPER ('outrs6DelDoc'),
                                            ku$_vcnt (p_DocType,
                                                      p_rule_id,
                                                      p_paymentid,
                                                      p_ResultProvod,
                                                      p_comment,
                                                      p_oper,
                                                      p_ErrCode,
                                                      p_ErrMsg,
                                                      p_BizErrCode,
                                                      p_BizErrMsg,
                                                      p_KonsolidAccount,
                                                      p_ClientFIO,
                                                      p_PayCode,
                                                      p_error_count,
                                                      p_error));

      p_error_count := 0;
      p_error := usr_common.c_err_success;

      -- Следующие 2 настройки ситаются из таблицы маршрутизации
      get_soa_parameters(p_rule_id, v_url, v_soap_node, p_error_count, p_error);

      if p_error_count=0 then

        v_soap_node:=v_soap_node||'DelDoc';

        v_soap_action := v_soap_node||'_'||c_postfix_request; -- метод

        get_outrs6DelDoc_request(p_paymentid, p_comment, p_oper, v_soap_action, v_soap_request, p_error_count, p_error);

        if p_error_count=0 then

          if c_mode_debug then
            delete from usr_debug_dump d where d.paymentid=p_paymentid;
            insert into usr_debug_dump values (p_paymentid,v_soap_request);
          end if;

          extract_answer(v_soap_request, v_url, v_soap_action, v_resp, p_error_count, p_error);

          if p_error_count=0 then

            p_ErrMsg          := resp_extract_varchar(v_resp,v_soap_node,'ErrMsg');
            p_ErrCode         := resp_extract_number (v_resp,v_soap_node,'ErrCode');
            p_BizErrMsg       := resp_extract_varchar(v_resp,v_soap_node,'BizErrMsg');
            p_BizErrCode      := resp_extract_number (v_resp,v_soap_node,'BizErrCode');
            p_KonsolidAccount := resp_extract_varchar(v_resp,v_soap_node,'KonsolidAccount');
            p_ClientFIO       := resp_extract_varchar(v_resp,v_soap_node,'ClientFIO');
            p_PayCode         := resp_extract_number (v_resp,v_soap_node,'PayCode');
            p_KonsolidAccount := resp_extract_varchar(v_resp,v_soap_node,'KonsolidAccount');
            p_ClientFIO       := resp_extract_varchar(v_resp,v_soap_node,'ClientFIO');
            p_PayCode         := resp_extract_number (v_resp,v_soap_node,'PayCode');

          end if;

        end if;

      end if;
   exception
      when others then
              p_error_count := 1;
              p_error := 'Ошибка выполнения';
   end;

   --передача сводного счета
   procedure send_account (
      p_paymentid           number,
      p_KonsolidAccount     varchar2,
      p_PayCode             number,
      p_ReasonUnk           varchar2 default null,
      p_error_count     out number,
      p_error           out varchar2
   )
   is
      v_dockind       number;
      v_payer_account varchar2(35);
      v_sum           number;
      v_oper          number;
      v_pack          number;
      v_department    number;
      v_branch        number;
      v_num_doc       varchar2(25);
      v_ground        varchar2(600);
      v_pack_id       number;
      v_pipename      varchar2(64);
      v_KonsolidAccount  varchar2(35);
   begin

      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_soa'),
                                            UPPER ('send_account'),
                                            ku$_vcnt (p_paymentid,
                                                      p_KonsolidAccount,
                                                      p_PayCode,
                                                      p_ReasonUnk,
                                                      p_error_count,
                                                      p_error));

      p_error_count := 0;
      p_error := usr_common.c_err_success;
      
      if (p_KonsolidAccount is null)and(p_PayCode>0) then
        p_error_count := 1;
        p_error := 'Не передан сводный счет!';
      else

        v_pipename := rsb_common.GetRegStrValue('COMMON\PIPELISTENER\PIPENAME_SOA',0);
        if (v_pipename is not null) then
          set_pipe_server(v_pipename);
        end if;

        -- Определяем параметры платежа
        select t_dockind, t_futurepayeraccount, t_amount, t_oper, t_numberpack, t_department, t_opernode
          into v_dockind, v_payer_account,      v_sum,    v_oper, v_pack,       v_department, v_branch
          from dpmpaym_dbt p
         where p.t_paymentid = p_paymentid;

        rsbsessiondata.m_curdate:=usr_common.getcurdate(nvl(v_branch,1));

        if p_PayCode=-1 then

           if p_ReasonUnk is not null then -- Причина помещения платежа в невыясненные
             MERGE INTO dnotetext_dbt d
                   USING (SELECT 1 FROM dual) o
                   ON ((d.t_documentid = lpad(p_paymentid, 10, '0'))and(d.t_notekind = 130))
                   WHEN MATCHED THEN
                       UPDATE SET d.t_oper = v_oper,
                                  d.t_date = rsbsessiondata.m_curdate,
                                  d.t_text = RPAD(UTL_RAW.cast_to_raw(p_ReasonUnk), 3000, '0')
                   WHEN NOT MATCHED THEN
                       INSERT (d.t_id,d.t_objecttype,d.t_documentid,d.t_notekind,d.t_oper,d.t_date,d.t_time,d.t_text,d.t_validtodate,d.t_branch,d.t_numsession)
                       VALUES (0,
                               501,
                               lpad(p_paymentid, 10, '0'),--t_documentid
                               130,--t_notekind
                               v_oper,--t_oper
                               rsbsessiondata.m_curdate,--t_date
                               sysdate,
                               RPAD(UTL_RAW.cast_to_raw(p_ReasonUnk), 3000, '0'),--t_text
                               to_date('31129999', 'DDMMYYYY'),
                               1,
                               0);
          end if;

          v_KonsolidAccount := '47416';

       else

          v_KonsolidAccount := p_KonsolidAccount;

       end if;

          select t_number,  t_ground
            into v_num_doc, v_ground
            from dpmrmprop_dbt r
           where r.t_paymentid = p_paymentid;

          -- Вставляем проводку
          usr_payments.add_deffered_carry(p_payment_id => p_paymentid,
                                          p_carrynum => 1,
                                          p_payer_account => v_payer_account,
                                          p_receiver_account => v_KonsolidAccount,
                                          p_sum => v_sum,
                                          p_date_carry => rsbsessiondata.m_curdate,
                                          p_oper => v_oper,
                                          p_pack => v_pack,
                                          p_num_doc => v_num_doc,
                                          p_ground => v_ground,
                                          p_kind_oper => ' 6',
                                          p_shifr_oper => '09',
                                          p_department => v_department,
                                          p_branch => v_branch,
                                          p_error => p_error);

       if (p_error = usr_common.c_err_success) then
          -- Запускаем операцию
          --/*Временно убрано
          usr_operations.rsb_execute_step(p_paymentid => p_paymentid,
                                          p_dockind => v_dockind,
                                          p_packmode => 0,
                                          p_pack_id => v_pack_id,
                                          p_error_count => p_error_count,
                                          p_error => p_error);--*/null;
       end if;
       
      end if;


   exception
      when no_data_found then
              p_error_count := 1;
              p_error := 'Ошибка выполнения: Платёж '||p_paymentid||' не найден';
      when others then
              p_error_count := 1;
              p_error := 'Ошибка выполнения: Платёж '||p_paymentid;
   end;

begin
   select 'T00:00:00'||sessiontimezone into gv_postfix_time from dual;
   -- KS 11.10.2011 Включить дебаг-режим
   c_mode_debug := nvl(rsb_common.GetRegBoolValue('PRBB\ИНТЕРФЕЙСЫ\MODE_DEBUG',0),c_mode_debug);
end; 
/
