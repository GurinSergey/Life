prompt delete_usr_log

create or replace trigger delete_usr_log
   before delete
   on dpmpaym_dbt
   referencing new as new old as old
   for each row
begin

 --RR 28.11.2012 Записываем информацию о том кто и когда удалил документ
 
   update usr_payments_log set log_data = (to_char(sysdate, 'dd.mm.yyyy-hh:mi:ss' ) || ' '|| rsbsessiondata.oper)
         where paymentid = :old.t_paymentid;

   delete from usr_pmdocs
         where paymentid = :old.t_paymentid;
         
   exception when no_data_found then null;
   
 end;
/
