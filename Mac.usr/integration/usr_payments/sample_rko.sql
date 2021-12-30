--1. вставка платежа РКО внутреннего, единичная 

declare
   v_error       varchar2 (4000);                                                                                      --выходные параметры
   v_paymentid   number;
begin
   usr_payments.insert_payment (p_payer_account         => '40702810500000013981',
                                p_receiver_account      => '42301810500001103000',
                                p_num_doc               => '1100',
                                p_payer_bic             => '044525986', 
                                p_receiver_bic          => '044525986',                               
                                p_oper                  => 10000,
                                p_pack                  => 777,                                
                                p_debet_sum             => 55.21,
                                p_ground                => 'test ' || systimestamp,
                                p_shifr                 => '01',
                                p_priority              => 6,
                                p_doc_kind              => usr_payments.c_dockind_client_paym,
                                p_origin                => 5,
                                p_pack_mode             => 0,
                                p_error                 => v_error,
                                p_payment_id            => v_paymentid,
                                p_run_operation         => 0,
                                p_skip_check_mask => 4
                               );
   dbms_output.put_line ('v_error = ' || v_error);
   dbms_output.put_line ('v_paymentid = ' || v_paymentid);
end;

--2. вставка платежа РКО внешнего, единичная 

declare
   v_error       varchar2 (4000);                                                                                      --выходные параметры
   v_paymentid   number;
begin
   usr_payments.insert_payment (p_payer_account         => '40702810100000012489',
                                p_receiver_account      => '40702810700000000000',
                                p_num_doc               => '1100',
                                p_oper                  => 9999,
                                p_pack                  => 777,
                                p_debet_sum             => 55.21,
                                p_receiver_bic          => '046015761',
                                p_receiver_name         => 'receiver name',
                                p_receiver_inn          => '1234560000',
                                p_ground                => 'test ' || systimestamp,
                                p_shifr                 => '01',
                                p_priority              => 6,
                                p_doc_kind              => usr_payments.c_dockind_client_paym,
                                p_origin                => 5,
                                p_pack_mode             => 0,
                                p_error                 => v_error,
                                p_payment_id            => v_paymentid,
                                p_run_operation         => 0,
                                p_transfer_date => '17-03-2010'
                               );
   dbms_output.put_line ('v_error = ' || v_error);
   dbms_output.put_line ('v_paymentid = ' || v_paymentid);
end;

--3. вставка клиентского требования с акцептом, единичная 

declare
   v_error       varchar2 (4000);                                                                                      --выходные параметры
   v_paymentid   number;
begin
   usr_payments.insert_payment (p_payer_account         => '40702810300000000000',
                                p_receiver_account      => '40702810700000000000',
                                p_num_doc               => '1100',
                                p_oper                  => 9999,
                                p_pack                  => 777,
                                p_debet_sum             => 55.21,
                                p_corschem              => 1,
                                p_receiver_bic          => '044525256',
                                p_receiver_name         => 'receiver name',
                                p_receiver_inn          => '1236547890',
                                p_ground                => 'test ' || systimestamp,
                                p_shifr                 => '02',
                                p_priority              => 6,
                                p_doc_kind              => usr_payments.c_dockind_client_order,
                                p_accept_term           => 0,                                                                   --с акцептом
                                p_accept_date           => to_date ('10.01.2008', 'DD.MM.YYYY'),
                                p_origin                => 5,
                                p_pack_mode             => 0,
                                p_error                 => v_error,
                                p_payment_id            => v_paymentid,
                                p_run_operation         => 0
                               );
   dbms_output.put_line ('v_error = ' || v_error);
   dbms_output.put_line ('v_paymentid = ' || v_paymentid);
end;

--4. вставка клиентского требования без акцепта, единичная 

declare
   v_error       varchar2 (4000);
   v_paymentid   number;
begin
   usr_payments.insert_payment (p_payer_account         => '40702810300000000000',
                                p_receiver_account      => '40702810700000000000',
                                p_num_doc               => '1100',
                                p_oper                  => 9999,
                                p_pack                  => 777,
                                p_debet_sum             => 55.21,
                                p_corschem              => 1,
                                p_receiver_bic          => '044525256',
                                p_receiver_name         => 'receiver name',
                                p_receiver_inn          => '1236547890',
                                p_ground                => 'test ' || systimestamp,
                                p_shifr                 => '02',
                                p_priority              => 6,
                                p_doc_kind              => usr_payments.c_dockind_client_order,
                                p_accept_term           => 1,                                                                  --без акцепта
                                p_pay_condition         => 'test',
                                --p_accept_date           => to_date('10.01.2008','DD.MM.YYYY'),
                                p_origin                => 5,
                                p_pack_mode             => 0,
                                p_error                 => v_error,
                                p_payment_id            => v_paymentid,
                                p_run_operation         => 0
                               );
   dbms_output.put_line ('v_error = ' || v_error);
   dbms_output.put_line ('v_paymentid = ' || v_paymentid);
end;

--5 ставка валютного платежа РКО внутреннего, единичная 
declare
   v_error       varchar2 (4000);                                                                                      --выходные параметры
   v_paymentid   number;
begin
   usr_payments.insert_payment (p_payer_account         => '40702826000000013323',
                                p_receiver_account      => '40702826800000015615',
                                p_num_doc               => '1100',
                                p_oper                  => 9999,
                                p_pack                  => 777,
                                p_debet_sum             => 55.21,
                                p_ground                => 'test ' || systimestamp,
                                p_shifr                 => '01',
                                p_priority              => 6,
                                p_doc_kind              => usr_payments.c_dockind_client_paym_val,
                                p_origin                => 1,
                                p_pack_mode             => 0,
                                p_error                 => v_error,
                                p_payment_id            => v_paymentid,
                                p_run_operation         => 0
                               );
   dbms_output.put_line ('v_error = ' || v_error);
   dbms_output.put_line ('v_paymentid = ' || v_paymentid);
end;

--5 ставка валютного платежа РКО внешнего, единичная 
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



