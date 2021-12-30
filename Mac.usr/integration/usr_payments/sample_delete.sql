--1. Удаление одного платежа
declare
   v_error varchar2 (4000);
begin
   usr_payments.delete_payment (7321, v_error);
   dbms_output.put_line ('v_error = ' || v_error);
end;

--2. удаление платежей по диапазону
declare
   v_err   varchar2 (4000);
begin
   for i in (select t_documentid from dcb_doc_dbt where t_origin=10)
   loop
      usr_payments.delete_payment (i.t_documentid, v_err);

      if v_err <> 'no_error'
      then
         dbms_output.put_line ('v_err = ' || v_err);
      end if;
   end loop;
end;




