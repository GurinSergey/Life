declare
   v_error       varchar2 (4000);--выходные параметры
   v_paymentid   number;
begin
   usr_payments.insert_payment  (p_payer_account         => '40802810267350101235',
                                 p_receiver_account      => '40702810300060084846',
                                 p_num_doc               => '1100',
                                 p_oper                  => 10184,
                                 p_pack                  => 777,
                                 p_debet_sum             => 55.21,
                                 p_payer_bic             => '047102651',
                                 p_payer_name            => 'ИП Овсепян Сероп Владимирович',
                                 p_payer_inn             => '860223456358',
                                 p_payer_kpp             => '0',
                                 p_ground                => 'test ',
                                 p_shifr                 => '01',
                                 p_priority              => 6,
                                 p_doc_kind              => usr_payments.c_dockind_external_in,
                                 p_origin                => 1000,
                                 p_pack_mode             => 0,
                                 p_error                 => v_error,
                                 p_payment_id            => v_paymentid,
                                 p_run_operation         => 0,
                                 p_transfer_date         => to_date('07062011','DDMMYYYY')--,
--                                      p_corschem              => -1
                               );
   dbms_output.put_line ('v_error = ' || v_error);
   dbms_output.put_line ('v_paymentid = ' || v_paymentid);
end;
