/* Formatted on 2008/08/21 13:12 (Formatter Plus v4.8.8) */
-- [1. C������� ������ �����] 

DECLARE
   v_error     VARCHAR2 (4000);
   v_partyid   NUMBER;
BEGIN     
   usr_accounts.create_account (p_account            => '40702810200000000068',
                                p_chapter            => 1,
                                p_department         => 1,
                                p_branch             => 1,
                                p_client             => 100016124,
                                p_oper               => 100,
                                p_acc_type           => '�',
                                p_acc_name           => 'Test',
                                p_pack_mode          => 0,
                                p_error_message      => v_error
                               );
   DBMS_OUTPUT.put_line ('��������� : ' || v_error);
END;

-- [2. �������� ����� ������]

DECLARE
   v_error   VARCHAR2 (4000);
BEGIN
   usr_accounts.create_account (p_account            => '40702810200000000065',
                                p_chapter            => 1,
                                p_department         => 1,
                                p_branch             => 1,
                                p_client             => 100016124,
                                p_oper               => 100,
                                p_acc_type           => '�',
                                p_acc_name           => 'Test',
                                p_pack_mode          => 1,
                                p_error_message      => v_error
                               );
   DBMS_OUTPUT.put_line ('��������� : ' || v_error);
   usr_accounts.create_account (p_account            => '40702810200000000066',
                                p_chapter            => 1,
                                p_department         => 1,
                                p_branch             => 1,
                                p_client             => 100016124,
                                p_oper               => 100,
                                p_acc_type           => '�',
                                p_acc_name           => 'Test',
                                p_pack_mode          => 1,
                                p_error_message      => v_error
                               );
   DBMS_OUTPUT.put_line ('��������� : ' || v_error);
   usr_accounts.create_account (p_account            => '40702810200000000067',
                                p_chapter            => 1,
                                p_department         => 1,
                                p_branch             => 1,
                                p_client             => 100016124,
                                p_oper               => 100,
                                p_acc_type           => '�',
                                p_acc_name           => 'Test',
                                p_pack_mode          => 2,
                                p_error_message      => v_error
                               );
   DBMS_OUTPUT.put_line ('��������� : ' || v_error);
END;

-- [3.���������� �����]

DECLARE
   v_error   VARCHAR2 (4000);
BEGIN
   usr_accounts.update_account (p_account            => '40702810200000000052',
                                p_chapter            => 1,
                                p_overdraft          => 'set',
                                p_limit              => 15,
                                p_error_message      => v_error
                               );
   DBMS_OUTPUT.put_line ('��������� : ' || v_error);
END;

-- [4. �������� �����]

DECLARE
   v_error   VARCHAR2 (4000);
BEGIN
   usr_accounts.close_account (p_account            => '40702810200000000053',
                               p_chapter            => 1,
                               p_close_date         => TO_DATE ('04.01.2008',
                                                                'DD.MM.YYYY'
                                                               ),
                               p_error_message      => v_error
                              );
   DBMS_OUTPUT.put_line ('��������� : ' || v_error);
   
--�������� ������ ������   
   declare
   v_error   varchar2 (4000);
begin
   usr_accounts.create_account_link (p_account_1       => '10205810000000000002',
                                     p_account_2       => '10205810600000000004',
                                     p_linktype        => 1,
                                     p_error_message   => v_error);
   dbms_output.put_line ('v_error = ' || v_error);
end;
END;