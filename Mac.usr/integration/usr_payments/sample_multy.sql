--1. вставка мультивалютки единичная без выполнения операции

declare
   v_error       varchar2 (4000); --выходные параметры
   v_paymentid   number;
begin
   usr_payments.insert_payment (p_payer_account      => '47405826320002027054',
                                p_receiver_account   => '40817810809000060164',
                                p_oper               => 9999,
                                p_num_doc            => '100',
                                p_debet_sum          => 2500,
                                p_kredit_sum         => 102.88,
                                p_rate               => 24.30,
                                p_num_operation      => 24001,
                                p_ground             => 'test' || systimestamp,
                                p_doc_kind           => usr_payments.c_dockind_multycarry,
                                p_origin             => 1,
                                p_pack_mode          => 0,
                                p_error              => v_error,
                                p_payment_id         => v_paymentid,
                                p_run_operation      => 0);
   dbms_output.put_line (v_error || ' ' || v_paymentid);
end;

--2. вставка мультивалютки единичная без выполнения операции, но с кассой

declare
   v_error       varchar2 (4000); --выходные параметры
   v_paymentid   number;
begin
   usr_payments.insert_payment (p_payer_account      => '40702840600000000000',
                                p_receiver_account   => '20202810600000000000',
                                p_num_doc            => '100',
                                p_debet_sum          => 300,
                                p_oper               => 9999,
                                p_kredit_sum         => 7260.00,
                                p_rate               => 24.30,
                                p_ground             => 'test' || systimestamp,
                                p_doc_kind           => usr_payments.c_dockind_multycarry,
                                p_cash_symbs         => '02:7260.00',
                                p_origin             => 1,
                                p_pack_mode          => 0,
                                p_error              => v_error,
                                p_payment_id         => v_paymentid,
                                p_run_operation      => 0);
   dbms_output.put_line (v_error || ' ' || v_paymentid);
end;

--2. вставка мультивалютки с выполнением операции

declare
   v_error       varchar2 (4000); --выходные параметры
   v_paymentid   number;
   v_pack_id     pls_integer;
   v_err_cnt     pls_integer;
begin
   usr_payments.insert_payment (p_payer_account      => '40702840600000000000',
                                p_receiver_account   => '70601810400000000000',
                                p_num_doc            => '999',
                                p_debet_sum          => 10000.00,
                                p_kredit_sum         => 225000.00,
                                p_rate               => 22.5000,
                                p_oper               => 9999,
                                p_ground             => 'test' || systimestamp,
                                p_doc_kind           => usr_payments.c_dockind_multycarry,
                                p_origin             => 1,
                                p_pack_mode          => 0,
                                p_error              => v_error,
                                p_payment_id         => v_paymentid,
                                p_run_operation      => 1);
   usr_payments.add_carry (p_payment_id         => v_paymentid,
                           p_sum                => 10000.00,
                           p_payer_account      => '40702840600000000000',
                           p_receiver_account   => 'ОВП01840959860000000',
                           p_error              => v_error);
   usr_payments.add_carry (p_payment_id         => v_paymentid,
                           p_sum                => 225000.00,
                           p_payer_account      => '40702840600000000000',
                           p_receiver_account   => '70601810400000000000',
                           p_error              => v_error);
   usr_payments.add_carry (p_payment_id         => v_paymentid,
                           p_sum                => 225000.00,
                           p_payer_account      => '40702840600000000000',
                           p_receiver_account   => '70603810759861510200',
                           p_error              => v_error);
   usr_payments.run_operation (v_pack_id, v_err_cnt, v_error);
   dbms_output.put_line ('v_pack_id = ' || v_pack_id || ' v_err_cnt = ' || v_err_cnt || ' v_error = ' || v_error);
end;