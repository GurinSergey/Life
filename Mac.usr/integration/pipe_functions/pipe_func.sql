create or replace function usr_get_message (
   pipename in varchar2,
   returnpipe out varchar2,
   message out varchar2,
   timeout in integer default dbms_pipe.maxwait
)
   return number
is
   s number;
begin
   s := dbms_pipe.receive_message (pipename, timeout);

   if s = 0
   then
      dbms_pipe.unpack_message (returnpipe);
      dbms_pipe.unpack_message (message);
   end if;

   return s;
end;
/

create or replace function usr_send_message (
   pipename in varchar2,
   message in varchar2
)
   return number
is
   s number;
begin
   dbms_pipe.pack_message (dbms_pipe.unique_session_name);
   dbms_pipe.pack_message (message);
   s := dbms_pipe.send_message (pipename => pipename, maxpipesize => 2000000);
   return s;
end;
/

CREATE OR REPLACE FUNCTION USR_SEND_MESSAGE_IB (
   pipename in varchar2,
   message in varchar2,
   timeout in integer default dbms_pipe.maxwait,
   returnpipe out varchar2
)
   return number  
is   
   s number;      --usr_send_message usr_get_message
   unique_pipe  VARCHAR2 (60) := dbms_pipe.unique_session_name;
begin
   /*Формируем сразу уник. канал*/
   unique_pipe:=unique_pipe|| to_char(sysdate, 'DDMMYYYYHH24MISS');
   dbms_pipe.pack_message (unique_pipe);
   dbms_pipe.pack_message (message);
   s := dbms_pipe.send_message (pipename => pipename, maxpipesize => 2000000);
  
   s := dbms_pipe.receive_message (unique_pipe, timeout);

   return s;
end; 
/

create or replace function USR_SEND_MESSAGE_UNIQ (
   pipename in varchar2,
   message in varchar2,
   returnpipe out varchar2
)
   return number
is
   s number;
   unique_pipe  VARCHAR2 (60) := dbms_pipe.unique_session_name||to_char(sysdate, 'DDMMYYYYHH24MISS');
begin
   dbms_pipe.pack_message (unique_pipe);
   dbms_pipe.pack_message (message);
   s := dbms_pipe.send_message (pipename => pipename, maxpipesize => 2000000);
   returnpipe := unique_pipe;
   return s;
end; 
/

CREATE OR REPLACE FUNCTION IS_ENABLE_PIPE (p_pipe VARCHAR2)
   RETURN VARCHAR2
IS
   v_pipe              VARCHAR2 (200);
   c_check_type        CHAR (1) := '7';
   v_msg               VARCHAR2 (4000) := '';
   v_ret_pipe          VARCHAR2 (64);
   v_message           VARCHAR2 (4000);
   c_service_timeout   PLS_INTEGER := 30;
   v_stat              NUMBER;
BEGIN
   v_pipe := p_pipe;

   IF (v_pipe IS NOT NULL)
   THEN
      set_pipe_server (v_pipe);
      usr_common.make_msg (v_msg, c_check_type);
      usr_common.make_msg (v_msg, '0');
      usr_common.make_msg (v_msg, 'are you ready?');

      v_stat :=
         USR_SEND_MESSAGE_IB (usr_common.m_pipename,
                              v_msg,
                              c_service_timeout,
                              v_ret_pipe);

      IF (v_stat = 0)
      THEN
         RETURN ('0');
      ELSE
         RETURN ('Нет сервиса');
      END IF;
   ELSE
      RETURN ('Не определена настройка');
   END IF;

   RETURN v_pipe;
END; 
/

CREATE OR REPLACE FUNCTION IS_PIPE_ENABLE_IB
   RETURN VARCHAR2
IS
   v_pipe              VARCHAR2 (200);
   c_check_type        CHAR (1) := '7';
   v_msg               VARCHAR2 (4000) := '';
   v_ret_pipe          VARCHAR2 (64);
   v_message           VARCHAR2 (4000);
   c_service_timeout   PLS_INTEGER := 30;
   v_stat              NUMBER;
BEGIN
   v_pipe :=
      rsb_common.GetRegStrValue ('COMMON\PIPELISTENER\PIPENAME_INTERBANK', 0);

   IF (v_pipe IS NOT NULL)
   THEN
      set_pipe_server (v_pipe);
      usr_common.make_msg (v_msg, c_check_type);
      usr_common.make_msg (v_msg, '0');
      usr_common.make_msg (v_msg, 'are you ready?');
     
      v_stat :=USR_SEND_MESSAGE_IB(usr_common.m_pipename, v_msg,c_service_timeout, v_ret_pipe); /*17.07.2012 Объединил отправку-получение  LAO */

      IF (v_stat = 0)
      THEN
         RETURN ('0');
      ELSE
         RETURN ('Нет сервиса');
      END IF;
   ELSE
      RETURN ('Не определена настройка реестра COMMON\PIPELISTENER\PIPENAME_INTERBANK');
   END IF;

   RETURN v_pipe;
END; 
/

CREATE OR REPLACE FUNCTION IS_PIPE_ENABLE_IK
   RETURN VARCHAR2
IS
   v_pipe              VARCHAR2 (200);
   c_check_type        CHAR (1) := '7';
   v_msg               VARCHAR2 (4000) := '';
   v_ret_pipe          VARCHAR2 (64);
   v_message           VARCHAR2 (4000);
   c_service_timeout   PLS_INTEGER := 30;
   v_stat              NUMBER;
BEGIN
   v_pipe :=
      rsb_common.GetRegStrValue ('COMMON\PIPELISTENER\PIPENAME_INTERBANK', 0);

   IF (v_pipe IS NOT NULL)
   THEN
      set_pipe_server (v_pipe);
      usr_common.make_msg (v_msg, c_check_type);
      usr_common.make_msg (v_msg, '0');
      usr_common.make_msg (v_msg, 'are you ready?');
     
      v_stat :=USR_SEND_MESSAGE_IB(usr_common.m_pipename, v_msg,c_service_timeout, v_ret_pipe); /*17.07.2012 Объединил отправку-получение  LAO */

      IF (v_stat = 0)
      THEN
         RETURN ('0');
      ELSE
         RETURN ('Нет сервиса');
      END IF;
   ELSE
      RETURN ('Не определена настройка реестра COMMON\PIPELISTENER\PIPENAME_INTERBANK');
   END IF;

   RETURN v_pipe;
END; 
/
