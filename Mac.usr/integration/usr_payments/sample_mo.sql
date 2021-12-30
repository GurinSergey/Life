--1. вставка мемордера, единичная без выполнения операции

declare
   v_error       varchar2 (4000); --выходные параметры
   v_paymentid   number;
begin
   usr_payments.insert_payment (p_payer_account      => '30601810200000041319',
                                p_receiver_account   => '70601810200001102000',
                                p_num_doc            => 1100,
                                p_receiver_name      => 'aaa',
                                p_num_operation      => 24001,
                                p_oper               => 10000,
                                p_pack               => 777,
                                p_debet_sum          => 55.21,
                                p_ground             => 'test' || systimestamp,
                                p_shifr              => '09',
                                p_doc_kind           => usr_payments.c_dockind_memorder,
                                p_origin             => 10,
                                p_pack_mode          => 0,
                                p_error              => v_error,
                                p_payment_id         => v_paymentid,
                                p_run_operation      => 0,
                                p_check_exists       => 1,  p_transaction_mode   => 1
                                );
   dbms_output.put_line ('v_error = ' || v_error);
   dbms_output.put_line ('v_paymentid = ' || v_paymentid);
end;

--2. вставка мемордера, пакетная без выполнения операции

declare
   v_error       varchar2 (4000); --выходные параметры
   v_paymentid   number;
begin
   for i in 1 .. 10
   loop
      usr_payments.insert_payment (p_payer_account      => '30601810200000041319',
                                   p_receiver_account   => '70601810200001102000',
                                   p_num_doc            => 1100 + i,
                                   p_oper               => 9999,
                                   p_pack               => 777,
                                   p_debet_sum          => 55.21 + i,
                                   p_ground             => 'test ' || systimestamp,
                                   p_shifr              => '09',
                                   p_doc_kind           => usr_payments.c_dockind_memorder,
                                   p_origin             => 10,
                                   p_pack_mode          => 1,
                                   p_error              => v_error,
                                   p_payment_id         => v_paymentid,
                                   p_run_operation      => 0);
   --dbms_output.put_line ('v_error = ' || v_error);
   --dbms_output.put_line ('v_paymentid = ' || v_paymentid);
   end loop;

   usr_payments.insert_payment ('40702810300000001986',
                                p_receiver_account   => '70601810200001102000',
                                p_num_doc            => 1100,
                                p_oper               => 9999,
                                p_pack               => 777,
                                p_debet_sum          => 55.21,
                                p_ground             => 'test' || systimestamp,
                                p_shifr              => '09',
                                p_doc_kind           => usr_payments.c_dockind_memorder,
                                p_origin             => 10,
                                p_pack_mode          => 2,
                                p_error              => v_error,
                                p_payment_id         => v_paymentid,
                                p_run_operation      => 0);
   dbms_output.put_line ('v_error = ' || v_error);
   dbms_output.put_line ('v_paymentid = ' || v_paymentid);
end;

--3. вставка мемордера, единичная с выполнением операции (проводка создается по документу)

declare
   v_error       varchar2 (4000);
   v_paymentid   number;
   v_pack_id     pls_integer;
   v_err_cnt     pls_integer;
begin
   usr_payments.insert_payment (p_payer_account             => '42306810903120060310', --daccount_dbt
                                p_receiver_account          => '30601810200000041319',
                                --p_value_date                   => '20-08-2008',
                                p_num_doc                   => '100',
                                p_oper                      => 9999,
                                p_num_operation => 24001,
                                p_debet_sum                 => 11,
                                p_ground                    => 'test0' || systimestamp,
                                p_doc_kind                  => usr_payments.c_dockind_memorder,
                                p_origin                    => 10,
                                p_pack_mode                 => 0,
                                p_error                     => v_error,
                                p_payment_id                => v_paymentid,
                                p_run_operation             => 1,
                                p_check_exists              => 1,
                                p_make_carry_from_payment   => 1,
                                p_transaction_mode   => 1);
   dbms_output.put_line ('v_paymentid = ' || v_paymentid);
   dbms_output.put_line ('v_error = ' || v_error);
   usr_payments.run_operation (v_pack_id, v_err_cnt, v_error);
   dbms_output.put_line ('v_pack_id = ' || v_pack_id || ' v_err_cnt = ' || v_err_cnt || ' v_error = ' || v_error);
end;

--4. вставка мемордера, пакетная с выполнением операции

declare
   v_error       varchar2 (4000); --выходные параметры
   v_paymentid   number;
   v_pack_id     pls_integer;
   v_err_cnt     pls_integer;
begin
   for i in 1 .. 999
   loop
      usr_payments.insert_payment (p_payer_account             => '40702810300000001986',
                                   p_receiver_account          => '70601810200001102000',
                                   p_num_doc                   => 1100 + i,
                                   p_num_operation             => 24001,
                                   p_oper                      => 9999,
                                   p_pack                      => 7770,
                                   p_debet_sum                 => 1 + i,
                                   p_ground                    => 'test ' || systimestamp,
                                   p_shifr                     => '09',
                                   p_doc_kind                  => usr_payments.c_dockind_memorder,
                                   p_origin                    => 10,
                                   p_pack_mode                 => 1,
                                   p_error                     => v_error,
                                   p_payment_id                => v_paymentid,
                                   p_run_operation             => 1,
                                   p_make_carry_from_payment   => 1);
   end loop;

   usr_payments.insert_payment (p_payer_account             => '40702810300000001986',
                                p_receiver_account          => '70601810200001102000',
                                p_num_doc                   => 1100,
                                p_num_operation             => 24001,
                                p_oper                      => 9999,
                                p_pack                      => 7770,
                                p_debet_sum                 => 55.21,
                                p_ground                    => 'test ' || systimestamp,
                                p_shifr                     => '09',
                                p_doc_kind                  => usr_payments.c_dockind_memorder,
                                p_origin                    => 10,
                                p_pack_mode                 => 2,
                                p_error                     => v_error,
                                p_payment_id                => v_paymentid,
                                p_run_operation             => 1,
                                p_make_carry_from_payment   => 1);
   usr_payments.run_operation (v_pack_id, v_err_cnt, v_error);
   dbms_output.put_line ('v_pack_id = ' || v_pack_id || ' v_err_cnt = ' || v_err_cnt || ' v_error = ' || v_error);
end;

--5. Вставка мемордера, единичная с выполнением операции и двумя проводками

declare
   v_error       varchar2 (4000);
   v_paymentid   number;
   v_pack_id     pls_integer;
   v_err_cnt     pls_integer;
begin
   usr_payments.insert_payment (p_payer_account             => '30601810200000041319',
                                p_receiver_account          => '70601810200001102000',
                                p_num_doc                   => '100',
                                p_oper                      => 9999,
                                p_debet_sum                 => 5.11,
                                p_num_operation => 24001,
                                p_ground                    => 'test' || systimestamp,
                                p_doc_kind                  => usr_payments.c_dockind_memorder,
                                p_origin                    => 1000,
                                p_pack_mode                 => 0,
                                p_error                     => v_error,
                                p_payment_id                => v_paymentid,
                                p_run_operation             => 1,
                                p_make_carry_from_payment   => 0);
   dbms_output.put_line ('v_error = ' || v_error);
   dbms_output.put_line ('v_paymentid = ' || v_paymentid);
   usr_payments.add_carry (p_payment_id         => v_paymentid,
                           p_payer_account      => '30601810200000041319',
                           p_receiver_account   => '70601392900006203081',
                           p_sum                => 5.11,
                           p_error              => v_error);
                           dbms_output.put_line ('v_error = ' || v_error);
   usr_payments.add_carry (p_payment_id         => v_paymentid,
                           p_payer_account      => '99999810300000000000',
                           p_receiver_account   => '91302810500000145787',
                           p_sum                => 100,
                           p_error              => v_error);
                           dbms_output.put_line ('v_error = ' || v_error);
   usr_payments.run_operation (v_pack_id, v_err_cnt, v_error);
   dbms_output.put_line ('v_pack_id = ' || v_pack_id || ' v_err_cnt = ' || v_err_cnt || ' v_error = ' || v_error);
end;

--usr_pmdocs

--6. Вставка мемордеров массовая с выполнением операции и дополнением проводками

declare
   v_error       varchar2 (4000); --выходные параметры
   v_paymentid   number;
   v_pack_id     pls_integer;
   v_err_cnt     pls_integer;
begin
   usr_payments.insert_payment (p_payer_account             => '40702810500000019590',
                                p_receiver_account          => '70601810400000000000',
                                p_oper                      => 9999,
                                p_num_doc                   => '100',
                                p_debet_sum                 => 222.22,
                                p_ground                    => 'test' || systimestamp,
                                p_doc_kind                  => usr_payments.c_dockind_memorder,
                                p_origin                    => 1000,
                                p_pack_mode                 => 1,
                                p_error                     => v_error,
                                p_payment_id                => v_paymentid,
                                p_run_operation             => 1,
                                p_make_carry_from_payment   => 0);
   dbms_output.put_line ('v_paymentid = ' || v_paymentid);
   usr_payments.add_carry (p_payment_id         => v_paymentid,
                           p_payer_account      => '40702810300000000000',
                           p_receiver_account   => '70601810500002101001',
                           p_sum                => 222.22,
                           p_error              => v_error);
   usr_payments.add_carry (p_payment_id         => v_paymentid,
                           p_payer_account      => '90901810959860001001',
                           p_receiver_account   => '91313810000000000000',
                           p_sum                => 111.11,
                           p_error              => v_error);
   usr_payments.insert_payment (p_payer_account             => '40702810500000019590',
                                p_receiver_account          => '70601810400000000000',
                                p_num_doc                   => '200',
                                p_oper                      => 9999,
                                p_debet_sum                 => 333.33,
                                p_ground                    => 'test' || systimestamp,
                                p_doc_kind                  => usr_payments.c_dockind_memorder,
                                p_origin                    => 10,
                                p_pack_mode                 => 2,
                                p_error                     => v_error,
                                p_payment_id                => v_paymentid,
                                p_run_operation             => 1,
                                p_make_carry_from_payment   => 0);
   dbms_output.put_line ('v_paymentid = ' || v_paymentid);
   usr_payments.add_carry (p_payment_id         => v_paymentid,
                           p_payer_account      => '40702810300000000000',
                           p_receiver_account   => '70601810500002101001',
                           p_sum                => 333.33,
                           p_error              => v_error);
   usr_payments.add_carry (p_payment_id         => v_paymentid,
                           p_payer_account      => '90901810959860001001',
                           p_receiver_account   => '91313810000000000000',
                           p_sum                => 222.22,
                           p_error              => v_error);
   usr_payments.run_operation (v_pack_id, v_err_cnt, v_error);
   dbms_output.put_line ('v_pack_id = ' || v_pack_id || ' v_err_cnt = ' || v_err_cnt || ' v_error = ' || v_error);
end;