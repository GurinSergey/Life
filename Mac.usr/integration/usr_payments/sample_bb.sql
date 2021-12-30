--1. вставка платежа ЅЅ внутреннего, единична€ без выполнени€ операции

declare
   v_error varchar2 (4000);   --выходные параметры
   v_paymentid number;
begin
   usr_payments.insert_payment (p_payer_account         => '40802810900000040205',
                                p_receiver_account      => '70601810400006203034',
                                p_num_doc               => '1100',
                                p_oper                  => 9999,
                                p_pack                  => 777,
                                p_num_operation         => 24001,
                                p_debet_sum             => 55.21,
                                p_ground                => 'test ' || systimestamp,
                                p_shifr                 => '01',
                                p_priority              => 6,
                                p_doc_kind              => usr_payments.c_dockind_bank_paym,
                                p_origin                => 0,
                                p_pack_mode             => 0,
                                p_error                 => v_error,
                                p_payment_id            => v_paymentid,
                                p_run_operation         => 0
                               );
   dbms_output.put_line ('v_error = ' || v_error);
   dbms_output.put_line ('v_paymentid = ' || v_paymentid);
end;

--2. вставка платежа ЅЅ внешнего, единична€ без выполнени€ операции

declare
   v_error varchar2 (4000);   --выходные параметры
   v_paymentid number;
begin
   usr_payments.insert_payment (p_payer_account         => '40802810900000040205',
                                p_receiver_account      => '40503810300001000001',
                                p_num_doc               => '1100',
                                p_oper                  => 9999,
                                p_pack                  => 777,
                                p_num_operation => 24001,
                                p_debet_sum             => 55.21,
                                p_ground                => 'test ' || systimestamp,
                                p_receiver_bic          => '045004821',
                                p_receiver_name         => 'receiver name',
                                p_receiver_inn          => '042520001',
                                p_shifr                 => '01',
                                p_corschem              => 1,
                                p_priority              => 6,
                                p_doc_kind              => usr_payments.c_dockind_bank_paym,
                                p_origin                => 2,
                                p_pack_mode             => 0,
                                p_error                 => v_error,
                                p_payment_id            => v_paymentid,
                                p_run_operation         => 0
                               );
   dbms_output.put_line ('v_error = ' || v_error);
   dbms_output.put_line ('v_paymentid = ' || v_paymentid);
end;

--3. вставка платежа ЅЅ внешнего, единична€ c выполнением операции
declare
   v_error varchar2 (4000);
   v_paymentid number;
   v_pack_id pls_integer;
   v_err_cnt pls_integer;
begin
   usr_payments.insert_payment (p_payer_account                => '40702810500000000006',
                                p_receiver_account             => '47401810000000000001',
                                p_num_doc                      => '1100',
                                p_oper                         => 9999,
                                p_pack                         => 777,
                                p_debet_sum                    => 55.21,
                                p_ground                       => 'test ' || systimestamp,
                                p_receiver_bic                 => '044525256',
                                p_receiver_name                => 'receiver name',
                                p_receiver_inn                 => '1236547890',
                                p_shifr                        => '01',
                                p_corschem                     => 1,
                                p_priority                     => 6,
                                p_doc_kind                     => usr_payments.c_dockind_bank_paym,
                                p_origin                       => 2,
                                p_pack_mode                    => 0,
                                p_error                        => v_error,
                                p_payment_id                   => v_paymentid,
                                p_run_operation                => 1,
                                p_make_carry_from_payment      => 1
                               );
   dbms_output.put_line ('v_error = ' || v_error);
   dbms_output.put_line ('v_paymentid = ' || v_paymentid);
   usr_payments.run_operation (v_pack_id, v_err_cnt, v_error);
   dbms_output.put_line ('v_pack_id = ' || v_pack_id || ' v_err_cnt = ' || v_err_cnt || ' v_error = ' || v_error);
end;

--4. вставка платежа ЅЅ внутреннего, единична€ c выполнением операции
declare
   v_error varchar2 (4000);
   v_paymentid number;
   v_pack_id pls_integer;
   v_err_cnt pls_integer;
begin
   usr_payments.insert_payment (p_payer_account                => '40702810000000011399',
                                p_receiver_account             => '70601810500002101001',
                                p_num_doc                      => '1100',
                                p_oper                         => 9999,
                                p_pack                         => 777,
                                p_debet_sum                    => 100,
                                p_ground                       => 'test ' || systimestamp,
                                p_shifr                        => '01',
                                p_corschem                     => 1,
                                p_priority                     => 6,
                                p_doc_kind                     => usr_payments.c_dockind_bank_paym,
                                p_origin                       => 2,
                                p_pack_mode                    => 0,
                                p_error                        => v_error,
                                p_payment_id                   => v_paymentid,
                                p_run_operation                => 1,
                                p_make_carry_from_payment      => 0
                               );
   dbms_output.put_line ('v_error = ' || v_error);
   dbms_output.put_line ('v_paymentid = ' || v_paymentid);
   usr_payments.add_carry (p_payment_id            => v_paymentid,
                           p_payer_account         => '40702810000000011399',
                           p_receiver_account      => '70601810500002101001',
                           p_sum                   => 90,
                           p_error                 => v_error
                          );
   usr_payments.add_carry (p_payment_id            => v_paymentid,
                           p_payer_account         => '40702810000000011399',
                           p_receiver_account      => '60309810500000000005',
                           p_sum                   => 10,
                           p_error                 => v_error
                          );
   
   usr_payments.run_operation (v_pack_id, v_err_cnt, v_error);
   dbms_output.put_line ('v_pack_id = ' || v_pack_id || ' v_err_cnt = ' || v_err_cnt || ' v_error = ' || v_error);
end;

--5. ¬ставка валютного платежа банка
declare
   v_error       varchar2 (4000);--выходные параметры
   v_paymentid   number;
begin
   usr_payments.insert_payment (
                                p_doc_cur_iso           => '840',
                                p_payer_account         => '40702978000000013323',
                                p_receiver_account      => 'CY69 0020 0385 0000 0041 1059 8806',                                
                                p_receiver_account_cur_iso      => '840',
                                p_num_doc               => '1100',
                                p_oper                  => 9999,
                                p_pack                  => 777,
                                p_vo_code               => '21010',
                                p_med_bic               => 'SABRRUMM',
                                p_med_bankname          => 'mediatory',
                                p_receiver_bic          => 'PNBPUS3NNYC',
                                p_receiver_name         => 'receiver name',
                                p_receiver_bankcoracc   => '37894',
                                p_receiver_bankname     => 'beneficiary',                           
                                p_debet_sum             => 55.21,
                                p_ground                => 'test ' || systimestamp,
                                p_shifr                 => '01',
                                p_priority              => 6,
                                p_ground_add            => 'p_ground_add',
                                p_doc_kind              => usr_payments.c_dockind_bank_paym_val,
                                p_origin                => 0,
                                p_pack_mode             => 0,
                                p_error                 => v_error,
                                p_payment_id            => v_paymentid,                                
                                p_comiss_acc            => '40702810900000010432',
                                p_expense_transfer      => 'SHA',
                                p_run_operation         => 0
                               );
   dbms_output.put_line ('v_error = ' || v_error);
   dbms_output.put_line ('v_paymentid = ' || v_paymentid);
end;