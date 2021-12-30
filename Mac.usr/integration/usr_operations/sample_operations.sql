declare
   v_packid   number (10);
   v_error    varchar2 (4000);
   v_errcnt   number (5);
begin
   usr_operations.rsb_execute_step (p_paymentid     => 6929,
                                    p_dockind       => 16,
                                    p_packmode      => 0,
                                    p_pack_id       => v_packid,
                                    p_error_count   => v_errcnt,
                                    p_error         => v_error);
   dbms_output.put_line ('p_pack_id = ' || v_packid);
   dbms_output.put_line ('p_error_count = ' || v_errcnt);
   dbms_output.put_line ('p_error = ' || v_error);
end;


declare
   v_packid   number (10);
   v_error    varchar2 (4000);
   v_errcnt   number (5);
begin
   for i in 8442..9490 loop
   usr_operations.rsb_execute_step (p_paymentid     => i,
                                    p_dockind       => 70,
                                    p_packmode      => 1,
                                    p_pack_id       => v_packid,
                                    p_error_count   => v_errcnt,
                                    p_error         => v_error);
    end loop;
    usr_operations.rsb_execute_step (p_paymentid     => 9491,
                                    p_dockind       => 70,
                                    p_packmode      => 2,
                                    p_pack_id       => v_packid,
                                    p_error_count   => v_errcnt,
                                    p_error         => v_error);
   dbms_output.put_line ('p_pack_id = ' || v_packid);
   dbms_output.put_line ('p_error_count = ' || v_errcnt);
   dbms_output.put_line ('p_error = ' || v_error);
end;



