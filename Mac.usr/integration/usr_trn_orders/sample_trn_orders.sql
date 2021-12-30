declare
   v_error   varchar2 (4000);
begin
   usr_trn_orders.create_trn_order (p_number           => 129,
                                    p_notify_num       => 32746,
                                    p_date             => sysdate,
                                    p_sell_sum         => 100,
                                    p_sell_account     => '40702810300000010016',
                                    p_sell_rate        => 34.52,
                                    --p_sell_scale  =>,
                                    --p_sell_bik      => ,
                                    p_transf_sum       => 75,
                                    p_transf_account   => '40702840800001010161',
                                    p_error            => v_error);
   dbms_output.put_line ('p_error = ' || v_error);
end;