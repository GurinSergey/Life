CREATE OR REPLACE FUNCTION USR_GETSWIFTNOTE (objectid in number)
   return varchar2
is
   retval   varchar2 (1500);
begin
   select   utl_raw.cast_to_varchar2 (t_text)
     into   retval
     from   dnotetext_dbt
    where   t_objecttype = 501 and t_notekind in (150, 151) and t_documentid = lpad (to_char (objectid), 10, '0') and rownum = 1;

   return retval;
exception
   when no_data_found
   then
      return null;
end; 
/