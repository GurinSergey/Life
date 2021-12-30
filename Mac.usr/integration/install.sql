clear screen

Prompt creating tables:
@tables.sql

Prompt creating views:
@views.sql

Prompt ib
@ib\daccounts_view.sql
@ib\ib_func.sql
@ib\RSB_DINFCACH30.pck
sho err

Prompt pipe_func
@pipe_functions\pipe_func.sql
sho err
Prompt usr_common
@usr_common\usr_common.pck
sho err
Prompt usr_accounts
@usr_accounts\usr_accounts.pck
sho err
Prompt usr_accrest
@usr_accrest\usr_accrest.pck
sho err
Prompt usr_categories
@usr_categories\usr_categories.pck
sho err
Prompt usr_claims
@usr_claims\usr_claims.pck
sho err
Prompt usr_clients
@usr_clients\usr_clients.pck
sho err
Prompt usr_interface_logging
@usr_interface_logging\usr_interface_logging.pck
sho err
Prompt usr_notes
@usr_notes\usr_notes.pck
sho err
Prompt usr_payments
@usr_payments\paym_func.sql
@usr_payments\usr_payments.pck
sho err
Prompt usr_operations
@usr_operations\usr_operations.pck
sho err
Prompt usr_operations_proc
@usr_operations_proc\usr_operations_proc.pck
sho err
Prompt usr_rscode
@usr_rscode\usr_rscode.pck
sho err
Prompt usr_views
@usr_views\usr_views.pck
sho err
Prompt usr_fs
@usr_fs\GET_CATEGORY.sql
@usr_fs\usr_fs.pck
sho err
Prompt usr_trn_orders
@usr_trn_orders\usr_trn_orders.pck
sho err
Prompt usr_soa
@usr_soa\usr_soa.pck
sho err
Prompt usr_soa_report
@usr_soa\usr_soa_report.pck
sho err
Prompt creating triggers:
@triggers.sql
sho err

alter package usr_common compile debug;
alter package usr_accounts compile debug;
alter package usr_accrest compile debug;
alter package usr_categories compile debug;
alter package usr_claims compile debug;
alter package usr_clients compile debug;
alter package usr_interface_logging compile debug;
alter package usr_notes compile debug;
alter package usr_payments compile debug;
alter package usr_operations compile debug;
alter package usr_operations_proc compile debug;
alter package usr_rscode compile debug;
alter package usr_views compile debug;
alter package usr_fs compile debug;
alter package usr_trn_orders compile debug;
alter package usr_soa compile debug;
alter package usr_soa_report compile debug;

Prompt creating procedures and more:

create or replace procedure prepare_debug
is
   dbg_id   varchar2 (1024);
begin
   execute immediate 'ALTER SESSION SET PLSQL_DEBUG=TRUE';

   dbg_id := dbms_debug.initialize ('RSBANK');
   dbms_debug.debug_on;
end;
/

create or replace procedure set_pipe_server (p_serv_name in varchar2)
is
begin
   usr_common.gv_pipename := p_serv_name;
end;
/

--функция и 4 триггера для блокировки платежей ФМ
create or replace function usr_checkfmlock (p_paymentid number)
   return boolean
is
   v_cnt   number;
begin
   select   count (1)
     into   v_cnt
     from   dopcontr_dbt
    where   t_documentid = p_paymentid and t_primdockind = 29 and t_department = 1;

   return v_cnt > 0;
end;
/

create or replace trigger opcontr_lockfld_by_fm
   before delete
   on dopcontr_dbt
   referencing new as new old as old
   for each row
begin
   if :old.t_status = 1 --на контроль
   then
      raise_application_error (
         -20001,
         'Operation removal in the Financial Control in the status "on control" is not permitted'
      );
   end if;
end;
/

create or replace trigger pmpaym_lockfld_by_fm
   before update or delete
   on dpmpaym_dbt
   referencing new as new old as old
   for each row
begin
   case
      when updating
      then
         if usr_checkfmlock (:old.t_paymentid)
            and (   :new.t_amount <> :old.t_amount
                 or:new.t_payamount <> :old.t_payamount
                 or:new.t_receiveraccount <> :old.t_receiveraccount
                 or:new.t_payeraccount <> :old.t_payeraccount)
         then
            raise_application_error (-20001, 'Payment is locked by Financial Monitoring');
         end if;
      when deleting
      then
         if usr_checkfmlock (:old.t_paymentid)
         then
            raise_application_error (-20001, 'Payment is locked by Financial Monitoring');
         end if;
   end case;
end;
/

create or replace trigger pmprop_lockfld_by_fm
   before update or delete
   on dpmprop_dbt
   referencing new as new old as old
   for each row
begin
   case
      when updating
      then
         if usr_checkfmlock (:old.t_paymentid) and :new.t_bankcode <> :old.t_bankcode
         then
            raise_application_error (-20001, 'Payment is locked by Financial Monitoring');
         end if;
      when deleting
      then
         if usr_checkfmlock (:old.t_paymentid)
         then
            raise_application_error (-20001, 'Payment is locked by Financial Monitoring');
         end if;
   end case;
end;
/

create or replace trigger pmrmprop_lockfld_by_fm
   before update or delete
   on dpmrmprop_dbt
   referencing new as new old as old
   for each row
begin
   case
      when updating
      then
         if usr_checkfmlock (:old.t_paymentid)
            and (   :new.t_payername <> :old.t_payername
                 or:new.t_receivername <> :old.t_receivername
                 or:new.t_payerinn <> :old.t_payerinn
                 or:new.t_receiverinn <> :old.t_receiverinn
                 or:new.t_ground <> :old.t_ground
                 or:new.t_date <> :old.t_date)
         then
            raise_application_error (-20001, 'Payment is locked by Financial Monitoring');
         end if;
      when deleting
      then
         if usr_checkfmlock (:old.t_paymentid)
         then
            raise_application_error (-20001, 'Payment is locked by Financial Monitoring');
         end if;
   end case;
end;
/

create or replace function usr_cut_acc (p_text varchar2)
   return varchar2
as
   function is_digit_ch (p_chr char)
      return boolean
   is
   begin
      return instr ('1234567890', p_chr) > 0;
   end;

   function is_digit_str (p_str varchar2)
      return boolean
   is
   begin
      for i in 1 .. length (p_str)
      loop
         if not is_digit_ch (substr (p_str, i, 1))
         then
            return false;
         end if;
      end loop;

      return true;
   end;
begin
   for i in 1 .. length (p_text)
   loop
      if is_digit_ch (substr (p_text, i, 1))
      then
         if is_digit_str (substr (p_text, i, 20))
         then
            return substr (p_text, i, 20);
         end if;
      end if;
   end loop;

   return null;
end;
/
