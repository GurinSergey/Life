--проводка 100 разных мемордеров

declare
   v_error       varchar2 (4000);   --выходные параметры
   v_paymentid   number;
   v_pack_id     pls_integer;
   v_err_cnt     pls_integer;
begin
   for i in (select rownum, debet, kredit
               from acc where rownum < 999)
   loop
      usr_payments.insert_payment (p_payer_account                => i.debet,
                                   p_receiver_account             => i.kredit,
                                   p_num_doc                      => i.rownum,
                                   p_oper                         => 9999,
                                   p_pack                         => 7770,
                                   p_debet_sum                    => 1 + i.rownum,
                                   p_ground                       => 'test ' || systimestamp,
                                   p_shifr                        => '09',
                                   p_doc_kind                     => usr_payments.c_dockind_memorder,
                                   p_origin                       => 10,
                                   p_pack_mode                    => 1,
                                   p_error                        => v_error,
                                   p_payment_id                   => v_paymentid,
                                   p_run_operation                => 1,
                                   p_make_carry_from_payment      => 1
                                  );
   end loop;

   usr_payments.insert_payment (p_payer_account                => '40702810300000001986',
                                p_receiver_account             => '70601810200001102000',
                                p_num_doc                      => 1100,
                                p_oper                         => 9999,
                                p_pack                         => 7770,
                                p_debet_sum                    => 55.21,
                                p_ground                       => 'test ' || systimestamp,
                                p_shifr                        => '09',
                                p_doc_kind                     => usr_payments.c_dockind_memorder,
                                p_origin                       => 10,
                                p_pack_mode                    => 2,
                                p_error                        => v_error,
                                p_payment_id                   => v_paymentid,
                                p_run_operation                => 1,
                                p_make_carry_from_payment      => 1
                               );
   usr_payments.run_operation (v_pack_id, v_err_cnt, v_error);
   dbms_output.put_line ('v_pack_id = ' || v_pack_id || ' v_err_cnt = ' || v_err_cnt || ' v_error = ' || v_error);
end;


--проводка 100 одинаковых мемордеров
declare
   v_error       varchar2 (4000);   --выходные параметры
   v_paymentid   number;
   v_pack_id     pls_integer;
   v_err_cnt     pls_integer;
begin
   for i in 1 .. 999
   loop
      usr_payments.insert_payment (p_payer_account                => '40702810300000001986',
                                p_receiver_account             => '70601810200001102000',
                                   p_num_doc                      => 1100 + i,
                                   p_oper                         => 9999,
                                   p_pack                         => 7770,
                                   p_debet_sum                    => 1 + i,
                                   p_ground                       => 'test ' || systimestamp,
                                   p_shifr                        => '09',
                                   p_doc_kind                     => usr_payments.c_dockind_memorder,
                                   p_origin                       => 10,
                                   p_pack_mode                    => 1,
                                   p_error                        => v_error,
                                   p_payment_id                   => v_paymentid,
                                   p_run_operation                => 1,
                                   p_make_carry_from_payment      => 1
                                  );
   end loop;

   usr_payments.insert_payment (p_payer_account                => '40702810300000001986',
                                p_receiver_account             => '70601810200001102000',
                                p_num_doc                      => 1100,
                                p_oper                         => 9999,
                                p_pack                         => 7770,
                                p_debet_sum                    => 55.21,
                                p_ground                       => 'test ' || systimestamp,
                                p_shifr                        => '09',
                                p_doc_kind                     => usr_payments.c_dockind_memorder,
                                p_origin                       => 10,
                                p_pack_mode                    => 2,
                                p_error                        => v_error,
                                p_payment_id                   => v_paymentid,
                                p_run_operation                => 1,
                                p_make_carry_from_payment      => 1
                               );
   usr_payments.run_operation (v_pack_id, v_err_cnt, v_error);
   dbms_output.put_line ('v_pack_id = ' || v_pack_id || ' v_err_cnt = ' || v_err_cnt || ' v_error = ' || v_error);
end;
