declare
   v_error           varchar2 (4000);
   v_paymentid       number;
   v_pack_id         pls_integer;
   v_err_cnt         pls_integer;
   v_err_cnt_total   pls_integer     := 0;
   v_cnt             pls_integer     := 0;
   v_packmode        number          := 1;
   v_sum             number :=0;

   cursor cr_debet (cnt number)
   is
      select a1.t_account
        from daccount_dbt a1
       where a1.t_chapter = 1
         and a1.t_open_close = chr (0)
         and a1.t_department = 1
         and a1.t_kind_account = 'А'
         and a1.t_type_account not like '%П%'
         and a1.t_type_account not like '%Т%'
         and a1.t_type_account not like '%У%'
         and a1.t_type_account not like '%А%'
         and t_account not like '20%'
         and rownum <= cnt;

   cursor cr_kredit (cnt number)
   is
      select a1.t_account
        from daccount_dbt a1
       where a1.t_chapter = 1
         and a1.t_open_close = chr (0)
         and a1.t_department = 1
         and a1.t_kind_account = 'П'
         and a1.t_type_account not like '%П%'
         and a1.t_type_account not like '%Т%'
         and a1.t_type_account not like '%У%'
         and a1.t_type_account not like '%А%'
         and rownum <= cnt;

   type debet_nt is table of cr_debet%rowtype;

   type kredit_nt is table of cr_kredit%rowtype;

   nt_debet          debet_nt        := debet_nt ();
   nt_kredit         kredit_nt       := kredit_nt ();
begin
   open cr_debet (100000);

   fetch cr_debet
   bulk collect into nt_debet;

   close cr_debet;

   open cr_kredit (100000);

   fetch cr_kredit
   bulk collect into nt_kredit;

   close cr_kredit;

   for i in 1 .. nt_kredit.count
   loop
      if v_cnt = 4
      then
         v_packmode := 2;
         v_sum := 625000;
         v_cnt := 0;
      end if;

      usr_payments.insert_payment (p_payer_account                => nt_debet (i).t_account,
                                   p_receiver_account             => nt_kredit (i).t_account,
                                   p_num_doc                      => i,
                                   p_oper                         => 8000,
                                   p_pack                         => 17,
                                   p_debet_sum                    => v_sum+1,
                                   p_ground                       =>    'тестовое основание, время вставки:'|| systimestamp,
                                   p_shifr                        => '09',
                                   p_num_operation => 24001,
                                   p_doc_kind                     => usr_payments.c_dockind_memorder,
                                   p_origin                       => 10,
                                   p_pack_mode                    => v_packmode,
                                   p_error                        => v_error,
                                   p_payment_id                   => v_paymentid,
                                   p_run_operation                => 1,
                                   p_make_carry_from_payment      => 1
                                  );
      --dbms_output.put_line ('v_error = ' || v_error);

      v_cnt := v_cnt + 1;
       v_sum := v_cnt;

      if v_packmode = 2
      then
         usr_payments.run_operation (v_pack_id, v_err_cnt, v_error);
         v_err_cnt_total := v_err_cnt_total + v_err_cnt;
      end if;
      v_packmode := 1;



   end loop;

   dbms_output.put_line ('v_err_cnt_total = ' || v_err_cnt_total);
   dbms_output.put_line ('v_cnt = ' || v_cnt);
end;


