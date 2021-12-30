create or replace package usr_trn_orders
is
   procedure create_trn_order (p_number               number, --����� ������������
                               p_notify_num           number, --����� ��������� � ����� �� ������� ���������� ������������
                               p_date                 date, -- ���� ������������
                               p_sell_sum             number default 0 , --����� ������� � ������
                               p_sell_account         varchar2 default null , --�������� ���� ��� ���������� ��������� �������
                               p_sell_rate            number default null , --���� �������
                               p_sell_scale           number default 1 , -- ������� �����
                               p_sell_bik             varchar2 default null , --��� ����� ����������, ��-��������� "��� ����"
                               p_transf_sum           number default 0 , -- ����� �������� �� ������� ����
                               p_transf_account       varchar2 default null , -- ������� ����
                               p_error            out varchar2); --����� ������ ��� no_error � ������ ��������� ����������
end;
/
CREATE OR REPLACE PACKAGE BODY usr_trn_orders
is
   procedure create_trn_order (p_number               number,
                               p_notify_num           number,
                               p_date                 date,
                               p_sell_sum             number default 0 ,
                               p_sell_account         varchar2 default null ,
                               p_sell_rate            number default null ,
                               p_sell_scale           number default 1 ,
                               p_sell_bik             varchar2 default null ,
                               p_transf_sum           number default 0 ,
                               p_transf_account       varchar2 default null ,
                               p_error            out varchar2)
   is
      v_rate       number;
      v_scale      number;
      v_fiid       number;
      v_totalsum   number;
      v_paymsum    number;
   begin
   
      USR_INTERFACE_LOGGING.save_arguments (UPPER ('usr_trn_orders'),
                                            UPPER ('create_trn_order'),
                                            ku$_vcnt (p_number,
                                                      p_notify_num,
                                                      p_date,
                                                      p_sell_sum,
                                                      p_sell_account,
                                                      p_sell_rate,
                                                      p_sell_scale,
                                                      p_sell_bik,
                                                      p_transf_sum,
                                                      p_transf_account,
                                                      p_error));   
   
      p_error := usr_common.c_err_success;

      begin
         select   t_payfiid, t_payamount
           into   v_fiid, v_paymsum
           from   usr_trnsf_notify, dpmpaym_dbt
          where   notify_num = p_notify_num and t_paymentid = payment_id;
      exception
         when no_data_found
         then
            p_error := '�� ������ ������ �� ��������� ' || p_notify_num;
            return;
      end;

      select   sum (sell_sum + transf_sum)
        into   v_totalsum
        from   usr_trnsf_order
       where   notify_num = p_notify_num;

      if v_totalsum + p_sell_sum + p_transf_sum > v_paymsum
      then
         p_error := '����� ������������ ��������� ����� ������� (� ������ ����� ������ ������������)';
         return;
      end if;

      if p_sell_rate is null
      then
         begin
            select   t_rate / (decode (t_point, 0, 1, t_point) * 1000), t_scale
              into   v_rate, v_scale
              from   dratedef_dbt
             where   t_fiid = 0 and t_otherfi = v_fiid and t_type = 7;
         exception
            when no_data_found
            then
               p_error := '�� ������ ���� ��� ������ ID=' || v_fiid;
               return;
         end;
      else
         v_rate := p_sell_rate;
         v_scale := p_sell_scale;
      end if;

      insert into usr_trnsf_order (order_num,
                                   notify_num,
                                   date_value,
                                   sell_sum,
                                   sell_rate,
                                   sell_scale,
                                   sell_account,
                                   sell_bik,
                                   transf_sum,
                                   transf_account,
                                   origin)
        values   (p_number,
                  p_notify_num,
                  p_date,
                  p_sell_sum,
                  v_rate,
                  v_scale,
                  p_sell_account,
                  p_sell_bik,
                  p_transf_sum,
                  p_transf_account,
                  1);

      commit;
   exception
      when dup_val_on_index
      then
         p_error := '������������ � ������� ' || p_number || ' ��� ����������';
      when others
      then
         rollback;
         p_error :=
               '������ �������� ������������: '
            || chr (10)
            || dbms_utility.format_error_stack
            || dbms_utility.format_error_backtrace;
   end;
end usr_trn_orders; 
/
