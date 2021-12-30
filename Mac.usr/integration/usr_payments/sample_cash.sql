--1. вставка приходного кассового ордера, единичная без выполнения операции

declare
   v_error       varchar2 (4000);                                                                                      --выходные параметры
   v_paymentid   number;
begin
   usr_payments.insert_payment (p_payer_account         => '40702810800000015294',
                                p_receiver_account      => '20202810200000000002',
                                p_num_doc               => '1100',
                                p_oper                  => 9999,
                                p_pack                  => 777,
                                p_debet_sum             => 55.21,
                                p_cash_symbs            => '02:55.0;12:0.21',
                                p_ground                => 'test ' || systimestamp,
                                p_shifr                 => '01',
                                p_doc_kind              => usr_payments.c_dockind_cash_in,
                                p_origin                => 0,
                                p_pack_mode             => 0,
                                p_error                 => v_error,
                                p_payment_id            => v_paymentid,
                                p_run_operation         => 0
                               );
   dbms_output.put_line ('v_error = ' || v_error);
   dbms_output.put_line ('v_paymentid = ' || v_paymentid);
end;

--2. вставка расходного кассового ордера, единичная без выполнения операции

declare
   v_error       varchar2 (4000);                                                                                      --выходные параметры
   v_paymentid   number;
begin
   usr_payments.insert_payment (p_payer_account         => '20202810600000000000',
                                p_receiver_account      => '40702810100000000022',
                                p_num_doc               => '1100',
                                p_oper                  => 9999,
                                p_pack                  => 777,
                                p_debet_sum             => 55.21,
                                p_cash_symbs            => '40:55.21',
                                p_ground                => 'test ' || systimestamp,
                                p_shifr                 => '01',
                                p_doc_kind              => usr_payments.c_dockind_cash_out,
                                p_origin                => 0,
                                p_pack_mode             => 0,
                                p_error                 => v_error,
                                p_payment_id            => v_paymentid,
                                p_run_operation         => 0
                               );
   dbms_output.put_line ('v_error = ' || v_error);
   dbms_output.put_line ('v_paymentid = ' || v_paymentid);
end;

--3. вставка ордера подкрепления, единичная без выполнения операции

declare
   v_error       varchar2 (4000);                                                                                      --выходные параметры
   v_paymentid   number;
begin
   usr_payments.insert_payment (p_payer_account         => '20202810900000000001',
                                p_receiver_account      => '20202810600000000000',
                                p_num_doc               => '1100',
                                p_oper                  => 100,
                                p_pack                  => 777,
                                p_debet_sum             => 55.21,
                                --p_cash_symbs            => '40:55;41:0.21',
                                p_cash_symbs            => '40:54.21;12:1',
                                p_ground                => 'test ' || systimestamp,
                                p_shifr                 => '01',
                                p_doc_kind              => usr_payments.c_dockind_cash_inout,
                                p_origin                => 0,
                                p_pack_mode             => 0,
                                p_error                 => v_error,
                                p_payment_id            => v_paymentid,
                                p_run_operation         => 0
                               );
   dbms_output.put_line ('v_error = ' || v_error);
   dbms_output.put_line ('v_paymentid = ' || v_paymentid);
end;

--4. вставка приходного кассового ордера, единичная с выполнением операции

declare
   v_error       varchar2 (4000);                                                                                      --выходные параметры
   v_paymentid   number;
   v_pack_id     pls_integer;
   v_err_cnt     pls_integer;
begin
   usr_payments.insert_payment (p_payer_account         => '20202810300000000001',
                                p_receiver_account      => '40702810800000000023',
                                p_num_doc                      => '1100',
                                p_oper                         => 100,
                                p_pack                         => 777,
                                --p_value_date                   => to_date('04-01-2008','DD-MM-YYYY'),
                                p_debet_sum                    => 99.99,
                                p_cash_symbs                   => '02:99;12:0.99',
                                p_ground                       => 'test ' || systimestamp,
                                p_shifr                        => '01',
                                p_doc_kind                     => usr_payments.c_dockind_cash_in,
                                p_origin                       => 0,
                                p_pack_mode                    => 0,
                                p_error                        => v_error,
                                p_payment_id                   => v_paymentid,
                                p_make_carry_from_payment      => 1,
                                p_run_operation                => 1
                               );
   dbms_output.put_line ('v_error = ' || v_error);
   dbms_output.put_line ('v_paymentid = ' || v_paymentid);
   usr_payments.run_operation (v_pack_id, v_err_cnt, v_error);
   dbms_output.put_line ('v_pack_id, v_err_cnt, v_error = ' || v_pack_id || ' ' || v_err_cnt || ' ' || v_error);
end;

--4. вставка приходного кассового ордера, единичная с выполнением операции и двумя проводками

declare
   v_error       varchar2 (4000);                                                                                      --выходные параметры
   v_paymentid   number;
   v_pack_id     pls_integer;
   v_err_cnt     pls_integer;
begin
   usr_payments.insert_payment (p_payer_account                => '40702810500000019590',
                                p_receiver_account             => '20202810600000000000',
                                p_num_doc                      => '1100',
                                p_oper                         => 100,
                                p_pack                         => 777,
                                --p_value_date                   => to_date('04-01-2008','DD-MM-YYYY'),
                                p_debet_sum                    => 99.99,
                                p_cash_symbs                   => '02:99;12:0.99',
                                p_ground                       => 'test ' || systimestamp,
                                p_shifr                        => '01',
                                p_doc_kind                     => usr_payments.c_dockind_cash_in,
                                p_origin                       => 0,
                                p_pack_mode                    => 0,
                                p_error                        => v_error,
                                p_payment_id                   => v_paymentid,
                                p_make_carry_from_payment      => 0,
                                p_run_operation                => 1
                               );
   usr_payments.add_carry (p_payment_id            => v_paymentid,                           
                           p_sum                   => 94.99,
                           p_payer_account         => '40702810500000019590',
                           p_receiver_account      => '20202810600000000000',
                           p_error                 => v_error
                          );
   usr_payments.add_carry (p_payment_id            => v_paymentid,
                           p_sum                   => 5,
                           p_payer_account         => '40702810500000019590',
                           p_receiver_account      => '70603810759861510200',
                           p_error                 => v_error,
                           p_ground                => 'комиссия'
                          );
   usr_payments.run_operation (v_pack_id, v_err_cnt, v_error);
   dbms_output.put_line ('v_pack_id, v_err_cnt, v_error = ' || v_pack_id || ' ' || v_err_cnt || ' ' || v_error);
end;



