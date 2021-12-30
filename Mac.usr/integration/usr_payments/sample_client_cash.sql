--1. вставка клиентского чека, единичная без выполнения операции

declare
   v_error varchar2 (4000);   --выходные параметры
   v_paymentid number;
begin
   usr_payments.insert_payment (p_payer_account         => '20202810300000000001',
                                p_receiver_account      => '40702810800000000023',
                                p_num_doc               => '1100',
                                p_oper                  => 9995,
                                p_pack                  => 777,
                                p_debet_sum             => 500,
                                p_cash_symbs            => '41:200;42:300',
                                p_ground                => 'test ' || systimestamp,
                                p_shifr                 => '01',
                                p_doc_kind              => usr_payments.c_dockind_client_cash_out,
                                p_origin                => 0,
                                p_pack_mode             => 0,
                                p_error                 => v_error,
                                p_payment_id            => v_paymentid,
                                p_run_operation         => 0
                               );
   dbms_output.put_line ('v_error = ' || v_error);
   dbms_output.put_line ('v_paymentid = ' || v_paymentid);
end;

--2. вставка клиентского чека, пакетная без выполнения операции

declare
   v_error varchar2 (4000);   --выходные параметры
   v_paymentid number;
begin
   usr_payments.insert_payment (p_payer_account         => '20202810300000000001',
                                p_receiver_account      => '40702810800000000023',
                                p_num_doc               => '1100',
                                p_oper                  => 9995,
                                p_pack                  => 777,
                                p_debet_sum             => 500,
                                p_cash_symbs            => '41:200;42:300',
                                p_ground                => 'test ' || systimestamp,
                                p_shifr                 => '01',
                                p_doc_kind              => usr_payments.c_dockind_client_cash_out,
                                p_origin                => 0,
                                p_pack_mode             => 1,
                                p_error                 => v_error,
                                p_payment_id            => v_paymentid,
                                p_run_operation         => 0
                               );
   dbms_output.put_line ('v_error = ' || v_error);
   dbms_output.put_line ('v_paymentid = ' || v_paymentid);
   usr_payments.insert_payment (p_payer_account         => '20202810300000000001',
                                p_receiver_account      => '40702810800000000023',
                                p_num_doc               => '1100',
                                p_oper                  => 9995,
                                p_pack                  => 777,
                                p_debet_sum             => 500,
                                p_cash_symbs            => '41:200;42:300',
                                p_ground                => 'test2 ' || systimestamp,
                                p_shifr                 => '01',
                                p_doc_kind              => usr_payments.c_dockind_client_cash_out,
                                p_origin                => 0,
                                p_pack_mode             => 2,
                                p_error                 => v_error,
                                p_payment_id            => v_paymentid,
                                p_run_operation         => 0
                               );
   dbms_output.put_line ('v_error = ' || v_error);
   dbms_output.put_line ('v_paymentid = ' || v_paymentid);
end;

--3. Вставка клиентского чека единичная с выполнения операции, проводки создаются по платежу

declare
   v_error varchar2 (4000);
   v_paymentid number;
   v_pack_id pls_integer;
   v_err_cnt pls_integer;
begin
   usr_payments.insert_payment (p_payer_account                => '40702810800000000023',
                                p_receiver_account             => '20202810300000000001',
                                p_num_doc                      => '1100',
                                p_oper                         => 9995,
                                p_pack                         => 777,
                                p_debet_sum                    => 500,
                                p_cash_symbs                   => '41:200;42:300',
                                p_ground                       => 'test ' || systimestamp,
                                p_shifr                        => '01',
                                p_doc_kind                     => usr_payments.c_dockind_client_cash_out,
                                p_origin                       => 0,
                                p_pack_mode                    => 0,
                                p_error                        => v_error,
                                p_payment_id                   => v_paymentid,
                                p_run_operation                => 1,
                                p_make_carry_from_payment      => 1
                               );
   dbms_output.put_line ('v_paymentid = ' || v_paymentid);
   dbms_output.put_line ('v_error = ' || v_error);
   usr_payments.run_operation (v_pack_id, v_err_cnt, v_error);
   dbms_output.put_line ('v_pack_id = ' || v_pack_id || ' v_err_cnt = ' || v_err_cnt || ' v_error = ' || v_error);
end;

--4. Вставка объявления на взнос наличными единичная без выполнения операции

declare
   v_error varchar2 (4000);   --выходные параметры
   v_paymentid number;
begin
   usr_payments.insert_payment (p_payer_account         => '20202810300000000001',
                                p_receiver_account      => '40702810800000000023',
                                p_num_doc               => '1100',
                                p_oper                  => 9995,
                                p_pack                  => 777,
                                p_debet_sum             => 500,
                                p_cash_symbs            => '02:200;03:300',
                                p_ground                => 'test ' || systimestamp,
                                p_shifr                 => '01',
                                p_doc_kind              => usr_payments.c_dockind_client_cash_in,
                                p_origin                => 0,
                                p_pack_mode             => 0,
                                p_error                 => v_error,
                                p_payment_id            => v_paymentid,
                                p_run_operation         => 0
                               );
   dbms_output.put_line ('v_error = ' || v_error);
   dbms_output.put_line ('v_paymentid = ' || v_paymentid);
end;

--5. Вставка объявления на взнос наличными пакетная без выполнения операции

declare
   v_error varchar2 (4000);   --выходные параметры
   v_paymentid number;
begin
   usr_payments.insert_payment (p_payer_account         => '20202810300000000001',
                                p_receiver_account      => '40702810800000000023',
                                p_num_doc               => '1100',
                                p_oper                  => 9995,
                                p_pack                  => 777,
                                p_debet_sum             => 500,
                                p_cash_symbs            => '02:200;03:300',
                                p_ground                => 'test ' || systimestamp,
                                p_shifr                 => '01',
                                p_doc_kind              => usr_payments.c_dockind_client_cash_in,
                                p_origin                => 0,
                                p_pack_mode             => 1,
                                p_error                 => v_error,
                                p_payment_id            => v_paymentid,
                                p_run_operation         => 0
                               );
   dbms_output.put_line ('v_error = ' || v_error);
   dbms_output.put_line ('v_paymentid = ' || v_paymentid);
   usr_payments.insert_payment (p_payer_account         => '20202810300000000001',
                                p_receiver_account      => '40702810800000000023',
                                p_num_doc               => '1100',
                                p_oper                  => 9995,
                                p_pack                  => 777,
                                p_debet_sum             => 500,
                                p_cash_symbs            => '02:200;03:300',
                                p_ground                => 'test ' || systimestamp,
                                p_shifr                 => '01',
                                p_doc_kind              => usr_payments.c_dockind_client_cash_in,
                                p_origin                => 0,
                                p_pack_mode             => 2,
                                p_error                 => v_error,
                                p_payment_id            => v_paymentid,
                                p_run_operation         => 0
                               );
   dbms_output.put_line ('v_error = ' || v_error);
   dbms_output.put_line ('v_paymentid = ' || v_paymentid);
end;

--6. Вставка объявления на взнос наличными единичная с выполнения операции, проводки создаются по платежу

declare
   v_error varchar2 (4000);
   v_paymentid number;
   v_pack_id pls_integer;
   v_err_cnt pls_integer;
begin
   usr_payments.insert_payment (p_payer_account                => '20202810300000000001',
                                p_receiver_account             => '40702810800000000023',
                                p_num_doc                      => '1100',
                                p_oper                         => 9995,
                                p_pack                         => 777,
                                p_debet_sum                    => 500,
                                p_cash_symbs                   => '02:200;03:300',
                                p_ground                       => 'test ' || systimestamp,
                                p_shifr                        => '01',
                                p_doc_kind                     => usr_payments.c_dockind_client_cash_in,
                                p_origin                       => 0,
                                p_pack_mode                    => 0,
                                p_error                        => v_error,
                                p_payment_id                   => v_paymentid,
                                p_run_operation                => 1,
                                p_make_carry_from_payment      => 1
                               );
   dbms_output.put_line ('v_paymentid = ' || v_paymentid);
   dbms_output.put_line ('v_error = ' || v_error);
   usr_payments.run_operation (v_pack_id, v_err_cnt, v_error);
   dbms_output.put_line ('v_pack_id = ' || v_pack_id || ' v_err_cnt = ' || v_err_cnt || ' v_error = ' || v_error);
end;