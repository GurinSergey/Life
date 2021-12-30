declare
   n number;
   err varchar2 (128);
begin
   usr_rscode.get_rscode (usr_rscode.c_person_type_artificial, n, err);
   dbms_output.put_line ('юрлицо резидент ' || n);
   usr_rscode.get_rscode (usr_rscode.c_person_type_artificial + usr_rscode.c_person_type_foreign, n, err);
   dbms_output.put_line ('юрлицо нерезидент ' || n);
   usr_rscode.get_rscode (0, n, err);
   dbms_output.put_line ('физлицо резидент ' || n);
   usr_rscode.get_rscode (usr_rscode.c_person_type_foreign, n, err);
   dbms_output.put_line ('физлицо нерезидент ' || n);
   usr_rscode.get_rscode (usr_rscode.c_person_type_bank, n, err);
   dbms_output.put_line ('банк ' || n);
   commit;
end;

select * from dobjcode_dbt where t_code = '010000018099'