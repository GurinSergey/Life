declare
   v_error     varchar2 (4000);
   v_partyid   number (10);
begin
   usr_clients.create_client (p_legalform       => 2,
                              p_shortname       => 'ShortName',
                              p_fullname        => 'FullName',
                              p_addname         => 'AddName',
                              p_lastname        => 'LastName',
                              p_firstname       => 'FirstName',
                              p_secondname      => 'SecondName',
                              p_birthdate       => to_date ('01.01.2001', 'DD.MM.YYYY'),
                              p_birthplace      => 'BirthPlace',
                              p_ismale          => 'X',
                              p_nationality     => 'Русский',
                              p_isemployer      => 'X',
                              p_workplace       => 'WorkPlace',
                              p_okpo            => 'OKPO',
                              p_country         => 'RUS',
                              p_superiorid      => null,
                              p_partyid         => v_partyid,
                              p_error_message   => v_error);
   dbms_output.put_line ('Идентификатор : ' || v_partyid);
   dbms_output.put_line ('Результат : ' || v_error);
end;

declare
   v_error   varchar2 (4000);
begin
   usr_clients.update_client (p_partyid         => 119120105,
                              p_shortname       => null,
                              p_fullname        => null,
                              p_addname         => 'Additional Name',
                              p_lastname        => null,
                              p_firstname       => null,
                              p_secondname      => ' ',
                              p_birthdate       => null,
                              p_birthplace      => null,
                              p_ismale          => ' ',
                              p_nationality     => null,
                              p_isemployer      => null,
                              p_workplace       => null,
                              p_okpo            => null,
                              p_country         => null,
                              p_superiorid      => 1,
                              p_error_message   => v_error);
   dbms_output.put_line ('Результат : ' || v_error);
end;

declare
   v_error   varchar2 (4000);
begin
   usr_clients.delete_client (p_partyid => 119120105, p_error_message => v_error);
   dbms_output.put_line ('Результат : ' || v_error);
end;

declare
   v_error   varchar2 (4000);
begin
   usr_clients.set_client_service (p_partyid         => 66015,
                                   p_servkind        => 3,
                                   p_oper            => 8000,
                                   p_startdate       => to_date ('11.07.2008', 'DD.MM.YYYY'),
                                   p_department      => 1,
                                   p_branch          => 1,
                                   p_error_message   => v_error);
   dbms_output.put_line ('Результат : ' || v_error);
end;

declare
   v_error   varchar2 (4000);
begin
   usr_clients.del_client_service (p_partyid => 119120105, p_servkind => 3, p_error_message => v_error);
   dbms_output.put_line ('Результат : ' || v_error);
end;

declare
   v_error       varchar2 (4000);
   v_codevalue   varchar2 (40) := '000';
begin
   usr_clients.set_client_code (p_partyid         => 519723, --dobjcode_dbt
                                p_codekind        => 1,
                                p_codevalue       => v_codevalue,
                                p_error_message   => v_error);
   dbms_output.put_line ('Результат : ' || v_error );
end;
--вариант с генерацией кода


declare
   v_error       varchar2 (4000);
   v_codevalue   varchar2 (40);
begin
   usr_clients.set_client_code (p_partyid         => 26,
                                p_codekind        => 1,
                                p_codevalue       => v_codevalue,
                                p_error_message   => v_error);
   dbms_output.put_line ('Результат : ' || v_error || '    p_codevalue = ' || v_codevalue);
end;

declare
   v_error   varchar2 (4000);
begin
   usr_clients.del_client_code (p_partyid => 119120105, p_codekind => 16, p_error_message => v_error);
   dbms_output.put_line ('Результат : ' || v_error);
end;

declare
   v_error   varchar2 (4000);
begin
   usr_clients.set_client_address (p_partyid         => 119120105,
                                   p_addresstype     => 1,
                                   p_country         => 'RUS',
                                   p_address         => 'Адрес субъекта',
                                   p_phonenumber     => '111-11-11',
                                   p_phonenumberad   => '222-22-22',
                                   p_faxnumber       => '333-33-33',
                                   p_email           => 'email@mail.ru',
                                   p_error_message   => v_error);
   dbms_output.put_line ('Результат : ' || v_error);
end;

declare
   v_error   varchar2 (4000);
begin
   usr_clients.del_client_address (p_partyid => 119120105, p_addresstype => 2, p_error_message => v_error);
   dbms_output.put_line ('Результат : ' || v_error);
end;

declare
   v_error   varchar2 (4000);
begin
   usr_clients.set_client_regdoc (p_partyid         => 119120105,
                                  p_regpartykind    => 7,
                                  p_regdockind      => 4,
                                  p_regpartyid      => 100102598,
                                  p_startdate       => to_date ('02.01.2008', 'DD.MM.YYYY'),
                                  p_series          => 'XYZ',
                                  p_number          => '123',
                                  p_docdate         => to_date ('01.01.2008', 'DD.MM.YYYY'),
                                  p_ismain          => 'X',
                                  p_error_message   => v_error);
   dbms_output.put_line ('Результат : ' || v_error);
end;

declare
   v_error   varchar2 (4000);
begin
   usr_clients.del_client_regdoc (p_partyid         => 119120105,
                                  p_regpartykind    => 7,
                                  p_regdockind      => 14,
                                  p_error_message   => v_error);
   dbms_output.put_line ('Результат : ' || v_error);
end;

declare
   v_error   varchar2 (4000);
begin
   usr_clients.set_client_officer (p_partyid          => 66015,
                                   p_personid         => 58072,
                                   p_isfirstperson    => null,
                                   p_issecondperson   => null,
                                   p_post             => 'работник',
                                   p_error_message    => v_error);
   dbms_output.put_line ('Результат : ' || v_error);
end;

declare
   v_error   varchar2 (4000);
begin
   usr_clients.del_client_officer (p_partyid => 66015, p_personid => 58072, p_error_message => v_error);
   dbms_output.put_line ('Результат : ' || v_error);
end;

declare
   v_error   varchar2 (4000);
begin
   usr_clients.set_client_paper (p_partyid         => 58073,
                                 p_paperkind       => 0,
                                 p_series          => '46 05',
                                 p_number          => '555555',
                                 p_issueddate      => to_date ('10.07.2003', 'DD.MM.YYYY'),
                                 p_issuer          => 'Паспортный стол',
                                 p_issuercode      => '4245',
                                 p_error_message   => v_error, p_is_main => '');
   dbms_output.put_line ('Результат : ' || v_error);
end;

declare
   v_error   varchar2 (4000);
begin
   usr_clients.del_client_paper (p_partyid => 58073, p_paperkind => 0, p_error_message => v_error);
   dbms_output.put_line ('Результат : ' || v_error);
end;