CREATE OR REPLACE PACKAGE USR_COMMON
is
   --�������� pipe ������ ������� RS-Bank ������������� ��-���������
   c_pipename      varchar (64)            := 'rsbank.service';
   --��� ��������� ��������
   c_err_success   constant varchar2 (10)  := 'no_error';
   -- ������-����������� ��� ������ ��������� � ������� RS-Bank
   c_delimiter     constant char           := chr (3);
   --������� ����
   c_nulldate      constant date           := to_date ('01010001', 'DDMMYYYY');
   --�������� ����������� ��������� � ����� �� ��������� �������������� FineReader
   c_fr_comment             varchar2 (128) := '���������� �� ��������� � ��������� FineReader';
   --
   c_setchar       constant char           := chr (88);
   c_unsetchar     constant char           := chr (0);

   -- KS 11.05.2011 �������������� null'��, �.�. � m_pipename null ����� ����������
   gv_pipename     varchar (64)            := null;--c_pipename;


--��������� ������������� ������
--��� ������������� ������������ �������: get_fiid ������!
   procedure init;

--������� ����������� ID ������ �� ISO ����
   function get_fiid (acc in varchar2)
      return number;

-- ������� ���������� ����� ����� ��� ��������� � ��
   function get_chapter (acc in varchar2)
      return number;

   procedure make_msg (p_msg in out nocopy varchar2, p_param varchar2);

   function m_pipename
      return varchar2;

   function getcurdate(p_branch number)
      return date;

end; 
/
CREATE OR REPLACE PACKAGE BODY USR_COMMON
is
   cursor cr_init_currencies
   --������ ��� ����������� �����
   is
      select   t_fiid fiid, t_codeinaccount codeinaccount
        from   dfininstr_dbt
       where   t_fi_kind = 1;

   type currencies_nt is table of cr_init_currencies%rowtype;

   nt_currencies   currencies_nt;

   procedure init
   is
   begin
      if nt_currencies.exists (1)
      then
         return;
      end if;

      open cr_init_currencies;

      fetch cr_init_currencies bulk collect into   nt_currencies;

      close cr_init_currencies;
   end;

   function m_pipename
   return varchar2
   is
   begin
      return nvl(gv_pipename, c_pipename);
   end;

   function get_fiid (acc in varchar2)
      return number
   is
      v_fiid number;
   begin

      if not nt_currencies.exists(1) then
         init;
      end if;
      for i in nt_currencies.first .. nt_currencies.last
      loop
         if substr (acc, 6, 3) = nt_currencies (i).codeinaccount
         then
            return nt_currencies (i).fiid;
         end if;
      end loop;

      -- KS 27.11.2013 ��������� ��� 31� ������
      /*
      select t_code_currency into v_fiid from daccount$_dbt where t_account = acc
      union
      select 0 from daccount_dbt where t_account = acc order by 1 desc;*/
      select t_code_currency into v_fiid from daccount_dbt where t_account = acc order by 1 desc;

      return v_fiid;
      exception when others
         then
         return -1;
   end;

   function get_chapter (acc in varchar2)
      return number
   is
      balacc    number;
      chapter   number;
   begin
      balacc := (to_number (substr (acc, 1, 5)));

      if ( (balacc >= 98000) and (balacc <= 98090))
      then
         chapter := 5;
      elsif ( ( (balacc >= 93001) and (balacc <= 97105)) or (balacc = 99996) or (balacc = 99997))
      then
         chapter := 4;
      elsif ( ( (balacc >= 90601) and (balacc <= 91904)) or (balacc = 99999) or (balacc = 99998))
      then
         chapter := 3;
      elsif ( (balacc >= 80101) and (balacc <= 85501))
      then
         chapter := 2;
      elsif (balacc <= 1)
      then
         chapter := 4;
      else
         chapter := 1;
      end if;

      return chapter;

   exception when others
   then return 1;
   end get_chapter;

   procedure make_msg (p_msg in out nocopy varchar2, p_param varchar2)
   is
   begin
      p_msg := p_msg || p_param || usr_common.c_delimiter;
   end;

   function getcurdate(p_branch number)
      return date
   IS
      curdate   DATE;
   BEGIN
     -- KS 13.02.2014 ����� ������ ������� ���� �������
     begin
       select max(d.t_curdate) into curdate
         from ddp_dep_dbt f, dcurdate_dbt d
        where d.t_branch = p_branch
          and d.t_isclosed <> 'X'
          and d.t_ismain = 'X';
       return curdate;          
     exception
       when others then null;
     end;
     select max(d.t_curdate) into curdate
       from ddp_dep_dbt f, dcurdate_dbt d
      where d.t_branch = p_branch
        and d.t_isclosed <> 'X';
     return curdate;
   exception
     when others then null;
   END getcurdate;

begin
  -- KS 11.05.2011 ������ ��� ���������� �� ���������
  c_pipename := nvl(rsb_common.GetRegStrValue('COMMON\PIPELISTENER\PIPENAME_DEFAULT',0),c_pipename);
end; 
/
