--1. ���������� �������
declare
   v_error   varchar2 (4000);
begin
   usr_claims.insert_claim (p_account => '40702810200000000003', p_oper => 9999, p_comment => 'test', p_sum => 1, p_error => v_error);
   dbms_output.put_line ('v_error = ' || v_error);
end;

--2. ������ ���������� 
declare
   v_error   varchar2 (4000);
begin
   usr_claims.delete_claim (p_account => '40702810200000000003', p_comment => 'test', p_sum => 1, p_error => v_error);
   dbms_output.put_line ('v_error = ' || v_error);
end;

