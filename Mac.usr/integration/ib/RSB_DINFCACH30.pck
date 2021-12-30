CREATE OR REPLACE PACKAGE RSB_DINFCACH30 AS
 m_usehistory PLS_INTEGER := 1;

 PROCEDURE getnameclnt (
 p_chapter IN PLS_INTEGER
 ,p_code_currency IN PLS_INTEGER
 ,p_account IN VARCHAR2
 ,p_name OUT VARCHAR2
 ,p_inn_kpp OUT VARCHAR2
 ,p_inn OUT VARCHAR2
 ,p_requireddate IN DATE DEFAULT NULL
 );

 PROCEDURE init (
 p_docquery IN VARCHAR2
 ,p_nameclntkind IN PLS_INTEGER
 ,p_codekind IN PLS_INTEGER
 ,p_getflddoc IN PLS_INTEGER
 ,p_instanceid IN PLS_INTEGER
 );

 FUNCTION count_doc (paymentid IN INTEGER)
 RETURN INTEGER;

 -- Создать таблицу
 PROCEDURE fill;
END RSB_DINFCACH30; 
/
CREATE OR REPLACE PACKAGE BODY RSB_DINFCACH30
AS
   -- Внутренние функции и процедуры

   -- Структура, которую мы и должны заполнить
   ddinfcach           ddinfcach1_tmp%ROWTYPE;
   -- Глобальные переменные
   lv_ourbank          PLS_INTEGER;
   lv_nameclntkind     PLS_INTEGER;
   lv_codekind         PLS_INTEGER;
   lv_getflddoc        PLS_INTEGER;
   --lv_instanceid       PLS_INTEGER;
   lv_instanceid       NUMBER(20);

   -- Обнулить инф.структуру ddinfcach
   PROCEDURE clear_docinf
   AS
   BEGIN
      ddinfcach.t_payeraccount :=         NULL;
      ddinfcach.t_payername :=            NULL;
      ddinfcach.t_payerinn :=             NULL;
      ddinfcach.t_payerinn_kpp :=         NULL;
      ddinfcach.t_payerbankname :=        NULL;
      ddinfcach.t_payercorracc :=         NULL;
      ddinfcach.t_payerbankcode :=        NULL;
      ddinfcach.t_payercodekind :=        NULL;
      ddinfcach.t_payerfiid :=            NULL;
      ddinfcach.t_payeramount :=          NULL;
      ddinfcach.t_payerbic :=             NULL;
      ddinfcach.t_payerswift :=           NULL;
      ddinfcach.t_receiveraccount :=      NULL;
      ddinfcach.t_receivername :=         NULL;
      ddinfcach.t_receiverinn :=          NULL;
      ddinfcach.t_receiverinn_kpp :=      NULL;
      ddinfcach.t_receiverbankname :=     NULL;
      ddinfcach.t_receivercorracc :=      NULL;
      ddinfcach.t_receiverbankcode :=     NULL;
      ddinfcach.t_receivercodekind :=     NULL;
      ddinfcach.t_receiverfiid :=         NULL;
      ddinfcach.t_receiveramount :=       NULL;
      ddinfcach.t_receiverbic :=          NULL;
      ddinfcach.t_receiverswift :=        NULL;
      ddinfcach.t_paymentid :=            NULL;
      ddinfcach.t_carryid :=              NULL;
      ddinfcach.t_fiid :=                 NULL;
      ddinfcach.t_amount :=               NULL;
      ddinfcach.t_date :=                 cnst.mindate;
      ddinfcach.t_paydate :=              cnst.mindate;
      ddinfcach.t_date_carry :=           cnst.mindate;
      ddinfcach.t_priority :=             NULL;
      ddinfcach.t_number_pack :=          NULL;
      ddinfcach.t_numb_document :=        NULL;
      ddinfcach.t_shifr_oper :=           NULL;
      ddinfcach.t_ground :=               NULL;
      ddinfcach.t_corrbankname :=         NULL;
      ddinfcach.t_corrbankacc :=          NULL;
      ddinfcach.t_payerchargeoffdate :=   cnst.mindate;
      ddinfcach.t_taxauthorstate :=       NULL;
      ddinfcach.t_bttticode :=            NULL;
      ddinfcach.t_okatocode :=            NULL;
      ddinfcach.t_taxpmground :=          NULL;
      ddinfcach.t_taxpmperiod :=          NULL;
      ddinfcach.t_taxpmnumber :=          NULL;
      ddinfcach.t_taxpmdate :=            NULL;
      ddinfcach.t_taxpmtype :=            NULL;
      ddinfcach.t_purpose :=              NULL;
      ddinfcach.t_paymentkind :=          NULL;
      ddinfcach.t_department :=           NULL;
      ddinfcach.t_instanceid :=           lv_instanceid;
      ddinfcach.t_payeraccount_a :=       NULL;
      ddinfcach.t_receiveraccount_a :=    NULL;
      ddinfcach.t_mt103 :=                NULL; -- zip_z. C-11289
   END clear_docinf;

   PROCEDURE splitfullinn (fullinn IN VARCHAR2, inn OUT VARCHAR2, kpp OUT VARCHAR2)
   AS
      fullinnlength     PLS_INTEGER;
   BEGIN
      fullinnlength :=   INSTR (fullinn, cnst.inn_delimiter);

      IF (fullinnlength = 0)
      THEN
         fullinnlength :=   15;
      ELSE
         fullinnlength :=   fullinnlength - 1;
      END IF;

      inn :=             SUBSTR (fullinn, 1, fullinnlength);
      kpp :=             SUBSTR (fullinn, fullinnlength + 1);
   END splitfullinn;

   FUNCTION getinn (fullinn IN VARCHAR2)
      RETURN VARCHAR2
   AS
      inn     VARCHAR2 (15);
      kpp     VARCHAR2 (15);
   BEGIN
      splitfullinn (fullinn, inn, kpp);
      RETURN inn;
   END getinn;

   FUNCTION getkpp (fullinn IN VARCHAR2)
      RETURN VARCHAR2
   AS
      inn     VARCHAR2 (15);
      kpp     VARCHAR2 (15);
   BEGIN
      splitfullinn (fullinn, inn, kpp);
      RETURN kpp;
   END getkpp;

   -- zmp 31.05.2012 Ищем платеж по проводке
   FUNCTION getpaymentid (autokey IN VARCHAR2)
      RETURN INTEGER
   AS
      paymentid     INTEGER;
   BEGIN
      SELECT   paym.t_paymentid
        INTO   paymentid
        FROM   doprdocs_dbt doc, doproper_dbt ooper, dpmpaym_dbt paym
       WHERE       doc.t_acctrnid = autokey -- KS 29.11.2013 Адаптация под 31ю сборку
               AND ooper.t_id_operation = doc.t_id_operation
               AND paym.t_dockind = ooper.t_dockind
               AND paym.t_documentid = ooper.t_documentid;

      RETURN paymentid;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN 0;
   END getpaymentid;

   FUNCTION getcoracc (ppartyid IN PLS_INTEGER)
      RETURN VARCHAR2
   AS
      v_coracc     ddinfcach1_tmp.t_payercorracc%TYPE DEFAULT NULL ;
   BEGIN
      IF (ppartyid > 0)
      THEN
         SELECT   t_coracc
           INTO   v_coracc
           FROM   dbankdprt_dbt
          WHERE   t_partyid = ppartyid AND ROWNUM = 1;
      END IF;

      RETURN v_coracc;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_coracc :=   NULL;
         RETURN v_coracc;
   END getcoracc;

   -- Внешние функции и процедуры

   -- Заполнить поля плательщика
   PROCEDURE getnameclnt (p_chapter         IN     PLS_INTEGER,
                          p_code_currency   IN     PLS_INTEGER,
                          p_account         IN     VARCHAR2,
                          p_name               OUT VARCHAR2,
                          p_inn_kpp            OUT VARCHAR2,
                          p_inn                OUT VARCHAR2,
                          p_requireddate    IN     DATE DEFAULT NULL )
   AS
      v_nameaccount          daccount_dbt.t_nameaccount%TYPE;
      v_shortname            dparty_dbt.t_shortname%TYPE;
      v_name                 dparty_dbt.t_name%TYPE;
      v_partyid              dparty_dbt.t_partyid%TYPE;
      v_namelen CONSTANT     PLS_INTEGER := 160;
      v_moresym              PLS_INTEGER;
   BEGIN
      BEGIN
         -- KS 29.11.2013 Апаптация под 31ю сборку
         /*IF (p_code_currency = 0)
         THEN
            SELECT   a.t_nameaccount, p.t_shortname, p.t_name, p.t_partyid
              INTO   v_nameaccount, v_shortname, v_name, v_partyid
              FROM   daccount_dbt a, dparty_dbt p
             WHERE   a.t_chapter = p_chapter AND a.t_account = p_account AND a.t_client = p.t_partyid;
         ELSE*/
            SELECT   a.t_nameaccount, p.t_shortname, p.t_name, p.t_partyid
              INTO   v_nameaccount, v_shortname, v_name, v_partyid
              FROM   daccount_dbt/*daccount$_dbt*/ a, dparty_dbt p
             WHERE       a.t_chapter = p_chapter
                     AND a.t_code_currency = p_code_currency
                     AND a.t_account = p_account
                     AND a.t_client = p.t_partyid;
         --END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            NULL;
      END;

      IF (lv_nameclntkind = -1)
      THEN
         IF (NVL (LENGTH (v_name), 0) > v_namelen)
         THEN
            p_name :=   SUBSTR (v_name, 1, v_namelen);
         ELSE
            p_name :=   v_name;
         END IF;
      ELSIF (lv_nameclntkind = 0)
      THEN
         IF (NVL (LENGTH (v_name), 0) > v_namelen)
         THEN
            p_name :=   SUBSTR (v_name, 1, v_namelen);
         ELSE
            p_name :=   v_name;
         END IF;
      ELSIF (lv_nameclntkind = 1)
      THEN
         IF (NVL (LENGTH (v_name), 0) > v_namelen)
         THEN
            p_name :=   SUBSTR (v_nameaccount, 1, v_namelen);
         ELSE
            p_name :=   v_nameaccount;
         END IF;
      ELSIF (lv_nameclntkind = 2)
      THEN
         IF (NVL (LENGTH (v_name), 0) > v_namelen)
         THEN
            p_name :=   SUBSTR (v_name, 1, v_namelen);
         ELSE
            p_name :=   v_name;
         END IF;

         v_moresym :=   v_namelen - NVL (LENGTH (p_name), 0) - 3;

         IF (v_moresym > 0)
         THEN
            p_name :=   p_name || ' (' || SUBSTR (v_nameaccount, 1, v_moresym - 3) || ')';
         END IF;
      ELSIF (lv_nameclntkind = 3)
      THEN
         IF (NVL (LENGTH (v_name), 0) > v_namelen)
         THEN
            p_name :=   SUBSTR (v_shortname, 1, v_namelen);
         ELSE
            p_name :=   v_shortname;
         END IF;

         v_moresym :=   v_namelen - NVL (LENGTH (p_name), 0) - 3;

         IF (v_moresym > 0)
         THEN
            p_name :=   p_name || ' (' || SUBSTR (v_nameaccount, 1, v_moresym - 3) || ')';
         END IF;
      END IF;

      p_inn_kpp :=   rsb_rep_pt.get_partyinn (v_partyid, 1, p_requireddate, 0);
      p_inn :=       getinn (p_inn_kpp);
   END getnameclnt;

   -- Инициализация процедуры
   PROCEDURE init (p_docquery       IN VARCHAR2,
                   p_nameclntkind   IN PLS_INTEGER,
                   p_codekind       IN PLS_INTEGER,
                   p_getflddoc      IN PLS_INTEGER,
                   p_instanceid     IN PLS_INTEGER)
   AS
   BEGIN
      lv_ourbank :=        rsbsessiondata.ourbank ();
      lv_nameclntkind :=   p_nameclntkind;
      lv_codekind :=       p_codekind;
      lv_getflddoc :=      p_getflddoc;
      lv_instanceid :=     p_instanceid;
   END;

   FUNCTION count_doc (paymentid IN INTEGER)
      RETURN INTEGER
   IS
      v_countdoc     INTEGER;
      v_dockind      INTEGER;
   BEGIN
      v_countdoc :=   0;
      v_dockind :=    0;

      SELECT   t_dockind
        INTO   v_dockind
        FROM   dpmpaym_dbt
       WHERE   t_paymentid = paymentid;

      SELECT   COUNT (lnk.t_documentid)
        INTO   v_countdoc
        FROM   doprdocs_dbt lnk, doproper_dbt opr
       WHERE   opr.t_documentid = LPAD (paymentid, 34, '0') /* ID анализируемого ПД, совпадает с ID платежа */
               AND opr.t_dockind = v_dockind /* Теоретически это должны быть только клиентские платежи */
               AND opr.t_id_operation = lnk.t_id_operation /* Связка по ID операции */
               AND lnk.t_dockind = 1; /* Проводка в операции*/

      RETURN v_countdoc;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN 0;
   END;

   -- Заполнение таблицы информацией по документу
   PROCEDURE fill
   AS
   -- KS 29.11.2013 Апаптация под 31ю сборку
   /*
      TYPE flds_rec_type
      IS
         RECORD (
            document_autokey                   darhdoc_dbt.t_autokey%TYPE,
            document_applicationkind           darhdoc_dbt.t_iapplicationkind%TYPE,
            document_applicationkey            darhdoc_dbt.t_applicationkey%TYPE,
            document_account_payer             darhdoc_dbt.t_account_payer%TYPE,
            document_account_receiver          darhdoc_dbt.t_account_receiver%TYPE,
            document_sum                       darhdoc_dbt.t_sum%TYPE,
            document_code_currency             darhdoc_dbt.t_code_currency%TYPE,
            document_chapter                   darhdoc_dbt.t_chapter%TYPE,
            document_date_carry                darhdoc_dbt.t_date_carry%TYPE,
            document_number_pack               darhdoc_dbt.t_number_pack%TYPE,
            document_numb_document             darhdoc_dbt.t_numb_document%TYPE,
            document_shifr_oper                darhdoc_dbt.t_shifr_oper%TYPE,
            document_ground                    darhdoc_dbt.t_ground%TYPE,
            document_department                darhdoc_dbt.t_department%TYPE,
            multycar_carryid                   dmultycar_dbt.t_carryid%TYPE,
            pmpaym_paymentid                   dpmpaym_dbt.t_paymentid%TYPE,
            pmpaym_dockind                     dpmpaym_dbt.t_dockind%TYPE,
            pmpaym_origin                      dpmpaym_dbt.t_origin%TYPE,
            pmpaym_amount                      dpmpaym_dbt.t_amount%TYPE,
            pmpaym_fiid                        dpmpaym_dbt.t_fiid%TYPE,
            pmpaym_payamount                   dpmpaym_dbt.t_payamount%TYPE,
            pmpaym_payfiid                     dpmpaym_dbt.t_payfiid%TYPE,
            pmpaym_payeraccount                dpmpaym_dbt.t_payeraccount%TYPE,
            pmpaym_receiveraccount             dpmpaym_dbt.t_receiveraccount%TYPE,
            pmpaym_numberpack                  dpmpaym_dbt.t_numberpack%TYPE,
            pmpaym_payerbankid                 dpmpaym_dbt.t_payerbankid%TYPE,
            pmpaym_receiverbankid              dpmpaym_dbt.t_receiverbankid%TYPE,
            pmpaym_valuedate                   dpmpaym_dbt.t_valuedate%TYPE,
            pmpaym_department                  dpmpaym_dbt.t_startdepartment%TYPE,
            pmpaym_chapter                     dpmpaym_dbt.t_chapter%TYPE,
            pmrmprop_payercorraccnostro        dpmrmprop_dbt.t_payercorraccnostro%TYPE,
            pmrmprop_payerbankname             dpmrmprop_dbt.t_payerbankname%TYPE,
            pmrmprop_receivercorraccnostro     dpmrmprop_dbt.t_receivercorraccnostro%TYPE,
            pmrmprop_receiverbankname          dpmrmprop_dbt.t_receiverbankname%TYPE,
            pmrmprop_payername                 dpmrmprop_dbt.t_payername%TYPE,
            pmrmprop_payerinn                  dpmrmprop_dbt.t_payerinn%TYPE,
            pmrmprop_receivername              dpmrmprop_dbt.t_receivername%TYPE,
            pmrmprop_receiverinn               dpmrmprop_dbt.t_receiverinn%TYPE,
            pmrmprop_date                      dpmrmprop_dbt.t_date%TYPE,
            pmrmprop_number                    dpmrmprop_dbt.t_number%TYPE,
            pmrmprop_shifroper                 dpmrmprop_dbt.t_shifroper%TYPE,
            pmrmprop_ground                    dpmrmprop_dbt.t_ground%TYPE,
            pmrmprop_paydate                   dpmrmprop_dbt.t_paydate%TYPE,
            pmrmprop_priority                  dpmrmprop_dbt.t_priority%TYPE,
            pmprop_d_codekind                  dpmprop_dbt.t_codekind%TYPE,
            pmprop_d_bankcode                  dpmprop_dbt.t_bankcode%TYPE,
            pmprop_c_codekind                  dpmprop_dbt.t_codekind%TYPE,
            pmprop_c_bankcode                  dpmprop_dbt.t_bankcode%TYPE,
            ptynam_d_partyid                   dparty_dbt.t_partyid%TYPE,
            ptynam_d_name                      dparty_dbt.t_name%TYPE,
            ptynam_d_addname                   dparty_dbt.t_addname%TYPE,
            ptynam_c_partyid                   dparty_dbt.t_partyid%TYPE,
            ptynam_c_name                      dparty_dbt.t_name%TYPE,
            ptynam_c_addname                   dparty_dbt.t_addname%TYPE,
            ptycor_d_partyid                   dparty_dbt.t_partyid%TYPE,
            ptycor_d_name                      dparty_dbt.t_name%TYPE,
            ptycor_c_partyid                   dparty_dbt.t_partyid%TYPE,
            ptycor_c_name                      dparty_dbt.t_name%TYPE,
            bnkdpr_d_partyid                   dbankdprt_dbt.t_partyid%TYPE,
            bnkdpr_d_coracc                    dbankdprt_dbt.t_coracc%TYPE,
            bnkdpr_c_partyid                   dbankdprt_dbt.t_partyid%TYPE,
            bnkdpr_c_coracc                    dbankdprt_dbt.t_coracc%TYPE,
            corsch_d_number                    dcorschem_dbt.t_number%TYPE,
            corsch_d_coraccount                dcorschem_dbt.t_coraccount%TYPE,
            corsch_c_number                    dcorschem_dbt.t_number%TYPE,
            corsch_c_coraccount                dcorschem_dbt.t_coraccount%TYPE,
            pmpurp_purpose                     dpmpurp_dbt.t_name%TYPE,
            pmpokind_paymentkind               dpmpopknd_dbt.t_name%TYPE,
            pmrmprop_taxauthorstate            dpmrmprop_dbt.t_taxauthorstate%TYPE,
            pmrmprop_okatocode                 dpmrmprop_dbt.t_okatocode%TYPE,
            pmrmprop_payerchargeoffdate        dpmrmprop_dbt.t_payerchargeoffdate%TYPE,
            pmrmprop_taxpmperiod               dpmrmprop_dbt.t_taxpmperiod%TYPE,
            pmrmprop_taxpmnumber               dpmrmprop_dbt.t_taxpmnumber%TYPE,
            pmrmprop_taxpmtype                 dpmrmprop_dbt.t_taxpmtype%TYPE,
            pmrmprop_taxpmdate                 dpmrmprop_dbt.t_taxpmdate%TYPE,
            pmrmprop_bttticode                 dpmrmprop_dbt.t_bttticode%TYPE,
            pmrmprop_taxpmground               dpmrmprop_dbt.t_taxpmground%TYPE
         );
*/
    TYPE flds_rec_type IS RECORD
    (
        document_AutoKey                  dacctrn_dbt.t_accTrnId                %TYPE,
        document_applicationkey           varchar2(29),
        document_Account_Payer            dacctrn_dbt.t_Account_Payer           %TYPE,
        document_Account_Receiver         dacctrn_dbt.t_Account_Receiver        %TYPE,
--        document_fiId_payer               dacctrn_dbt.t_fiId_payer              %TYPE,
--        document_fiId_receiver            dacctrn_dbt.t_fiId_receiver           %TYPE,
--        document_sum_payer                dacctrn_dbt.t_sum_payer               %TYPE,
--        document_sum_receiver             dacctrn_dbt.t_sum_receiver            %TYPE,
        document_sum                      dacctrn_dbt.t_sum_natcur              %TYPE,
        document_code_currency            dacctrn_dbt.t_fiId_payer              %TYPE,
        document_Chapter                  dacctrn_dbt.t_Chapter                 %TYPE,
        document_Date_Carry               dacctrn_dbt.t_Date_Carry              %TYPE,
        document_Number_Pack              dacctrn_dbt.t_Number_Pack             %TYPE,
        document_Numb_Document            dacctrn_dbt.t_Numb_Document           %TYPE,
        document_Shifr_Oper               dacctrn_dbt.t_Shifr_Oper              %TYPE,
        document_Ground                   dacctrn_dbt.t_Ground                  %TYPE,
        document_Department               dacctrn_dbt.t_Department              %TYPE,
        multycar_CarryID                  dacctrn_dbt.t_accTrnId                %TYPE,
        pmpaym_PaymentID                  dpmpaym_dbt.t_PaymentID               %TYPE,
        pmpaym_Amount                     dpmpaym_dbt.t_Amount                  %TYPE,
        pmpaym_FIID                       dpmpaym_dbt.t_FIID                    %TYPE,
        pmpaym_PayAmount                  dpmpaym_dbt.t_PayAmount               %TYPE,
        pmpaym_PayFIID                    dpmpaym_dbt.t_PayFIID                 %TYPE,
        pmpaym_PayerAccount               dpmpaym_dbt.t_PayerAccount            %TYPE,
        pmpaym_ReceiverAccount            dpmpaym_dbt.t_ReceiverAccount         %TYPE,
        pmpaym_NumberPack                 dpmpaym_dbt.t_NumberPack              %TYPE,
        pmpaym_PayerBankID                dpmpaym_dbt.t_PayerBankID             %TYPE,
        pmpaym_ReceiverBankID             dpmpaym_dbt.t_ReceiverBankID          %TYPE,
        pmpaym_ValueDate                  dpmpaym_dbt.t_ValueDate               %TYPE,
        pmpaym_Department                 dpmpaym_dbt.t_StartDepartment         %TYPE,
        pmpaym_dockind                    dpmpaym_dbt.t_dockind                 %TYPE, -- KS Адаптация патч 31
        pmpaym_chapter                    dpmpaym_dbt.t_chapter                 %TYPE,
        pmpaym_origin                     dpmpaym_dbt.t_origin                  %TYPE,
        pmrmprop_PayerCorrAccNostro       dpmrmprop_dbt.t_PayerCorrAccNostro    %TYPE,
        pmrmprop_PayerBankName            dpmrmprop_dbt.t_PayerBankName         %TYPE,
        pmrmprop_ReceiverCorrAccNostro    dpmrmprop_dbt.t_ReceiverCorrAccNostro %TYPE,
        pmrmprop_ReceiverBankName         dpmrmprop_dbt.t_ReceiverBankName      %TYPE,
        pmrmprop_PayerName                dpmrmprop_dbt.t_PayerName             %TYPE,
        pmrmprop_PayerINN                 dpmrmprop_dbt.t_PayerINN              %TYPE,
        pmrmprop_ReceiverName             dpmrmprop_dbt.t_ReceiverName          %TYPE,
        pmrmprop_ReceiverINN              dpmrmprop_dbt.t_ReceiverINN           %TYPE,
        pmrmprop_Date                     dpmrmprop_dbt.t_Date                  %TYPE,
        pmrmprop_Number                   dpmrmprop_dbt.t_Number                %TYPE,
        pmrmprop_ShifrOper                dpmrmprop_dbt.t_ShifrOper             %TYPE,
        pmrmprop_Ground                   dpmrmprop_dbt.t_Ground                %TYPE,
        pmrmprop_PayDate                  dpmrmprop_dbt.t_PayDate               %TYPE,
        pmrmprop_Priority                 dpmrmprop_dbt.t_Priority              %TYPE,
        pmprop_d_CodeKind                 dpmprop_dbt.t_CodeKind                %TYPE,
        pmprop_d_BankCode                 dpmprop_dbt.t_BankCode                %TYPE,
        pmprop_c_CodeKind                 dpmprop_dbt.t_CodeKind                %TYPE,
        pmprop_c_BankCode                 dpmprop_dbt.t_BankCode                %TYPE,
        ptynam_d_PartyID                  dparty_dbt.t_PartyID                  %TYPE,
        ptynam_d_Name                     dparty_dbt.t_Name                     %TYPE,
        ptynam_d_AddName                  dparty_dbt.t_AddName                  %TYPE,
        ptynam_c_PartyID                  dparty_dbt.t_PartyID                  %TYPE,
        ptynam_c_Name                     dparty_dbt.t_Name                     %TYPE,
        ptynam_c_AddName                  dparty_dbt.t_AddName                  %TYPE,
        ptycor_d_PartyID                  dparty_dbt.t_PartyID                  %TYPE,
        ptycor_d_Name                     dparty_dbt.t_Name                     %TYPE,
        ptycor_c_PartyID                  dparty_dbt.t_PartyID                  %TYPE,
        ptycor_c_Name                     dparty_dbt.t_Name                     %TYPE,
        bnkdpr_d_PartyID                  dbankdprt_dbt.t_PartyID               %TYPE,
        bnkdpr_d_CorAcc                   dbankdprt_dbt.t_CorAcc                %TYPE,
        bnkdpr_c_PartyID                  dbankdprt_dbt.t_PartyID               %TYPE,
        bnkdpr_c_CorAcc                   dbankdprt_dbt.t_CorAcc                %TYPE,
        corsch_d_Number                   dcorschem_dbt.t_Number                %TYPE,
        corsch_d_CorAccount               dcorschem_dbt.t_CorAccount            %TYPE,
        corsch_c_Number                   dcorschem_dbt.t_Number                %TYPE,
        corsch_c_CorAccount               dcorschem_dbt.t_CorAccount            %TYPE,

        pmpurp_Purpose                    dpmpurp_dbt.t_Name                    %TYPE,
        pmpokind_PaymentKind              dpmpopknd_dbt.t_Name                  %TYPE,
        pmrmprop_TaxAuthorState           dpmrmprop_dbt.t_TaxAuthorState        %TYPE,
        pmrmprop_OkatoCode                dpmrmprop_dbt.t_OkatoCode             %TYPE,
        pmrmprop_PayerChargeOffDate       dpmrmprop_dbt.t_PayerChargeOffDate    %TYPE,
        pmrmprop_TaxPmPeriod              dpmrmprop_dbt.t_TaxPmPeriod           %TYPE,
        pmrmprop_TaxPmNumber              dpmrmprop_dbt.t_TaxPmNumber           %TYPE,
        pmrmprop_TaxPmType                dpmrmprop_dbt.t_TaxPmType             %TYPE,
        pmrmprop_TaxPmDate                dpmrmprop_dbt.t_TaxPmDate             %TYPE,
        pmrmprop_BttTiCode                dpmrmprop_dbt.t_BttTiCode             %TYPE,
        pmrmprop_TaxPmGround              dpmrmprop_dbt.t_TaxPmGround           %TYPE,
        document_Time_Carry               dacctrn_dbt.t_systemtime              %TYPE
    );
      --zmp 31.05.2012 Объявил основную структуру полей
      TYPE baseflds_rec_type
      IS
         RECORD (
            pmrmprop_payerbankname             dpmrmprop_dbt.t_payerbankname%TYPE,
            pmrmprop_receiverbankname          dpmrmprop_dbt.t_receiverbankname%TYPE,
            pmrmprop_payerchargeoffdate        dpmrmprop_dbt.t_payerchargeoffdate%TYPE,
            pmrmprop_paydate                   dpmrmprop_dbt.t_paydate%TYPE,
            pmrmprop_priority                  dpmrmprop_dbt.t_priority%TYPE,
            pmpokind_paymentkind               dpmpopknd_dbt.t_name%TYPE,
            pmpurp_purpose                     dpmpurp_dbt.t_name%TYPE,
            pmrmprop_payercorraccnostro        dpmrmprop_dbt.t_payercorraccnostro%TYPE,
            pmrmprop_receivercorraccnostro     dpmrmprop_dbt.t_receivercorraccnostro%TYPE,
            pmpaym_payerbankid                 dpmpaym_dbt.t_payerbankid%TYPE,
            pmpaym_receiverbankid              dpmpaym_dbt.t_receiverbankid%TYPE,
            pmprop_d_bankcode                  dpmprop_dbt.t_bankcode%TYPE,
            pmprop_c_bankcode                  dpmprop_dbt.t_bankcode%TYPE
         );

      flds_rec                flds_rec_type;
      baseflds_rec            baseflds_rec_type;
      paymentid               INTEGER;

      TYPE tcacherecordsarray
      IS
         TABLE OF ddinfcach1_tmp%ROWTYPE
            INDEX BY PLS_INTEGER;

      m_cacherecordsarray     tcacherecordsarray;
      i                       PLS_INTEGER DEFAULT 0 ;
      -- Переменные "нашего" банка
      v_nameour               VARCHAR2 (320);
      v_addnameour            VARCHAR2 (320);
      v_coraccour             VARCHAR2 (25);
      v_bicour                VARCHAR2 (35);
      v_swiftour              VARCHAR2 (35);
      requireddate            DATE;
      dummy_value             NUMBER := NULL;

      saverThreshold CONSTANT PLS_INTEGER := 500000; -- KS 29.11.2013 Апаптация под 31ю сборку
      recordsCount PLS_INTEGER := 0;                 -- KS 29.11.2013 Апаптация под 31ю сборку

   BEGIN
      BEGIN
         SELECT   t_name, DECODE (t_addname, CHR (1), NULL, t_addname)
           INTO   v_nameour, v_addnameour
           FROM   dparty_dbt
          WHERE   t_partyid = lv_ourbank;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_nameour :=      CHR (1);
            v_addnameour :=   NULL;
      END;

      BEGIN
         SELECT   t_coracc
           INTO   v_coraccour
           FROM   dbankdprt_dbt
          WHERE   t_partyid = lv_ourbank;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_coraccour :=   ' ';
      END;

      FOR flds_rec
      -- KS 29.11.2013 Апаптация под 31ю сборку
      IN (SELECT   document.t_autokey AS document_autokey, -- KS Адаптация патч 31
                   case
                     when acctrn.t_fiid_payer = 0 or acctrn.t_fiid_receiver = 0
                       then 0
                     when acctrn.t_fiid_payer != 0 and acctrn.t_fiid_receiver != 0
                       then 1
                   end document_applicationkind,
                   lpad(document.t_autokey,24,'0') document_applicationkey,
                   document.t_Account_Payer AS document_Account_Payer,
                   document.t_Account_Receiver AS document_Account_Receiver,
                   document.t_sum AS document_sum,
                   document.t_code_currency AS document_code_currency,
                   acctrn.t_fiid_payer as document_fiid_payer,
                   acctrn.t_fiid_receiver as document_fiid_receiver,
                   document.t_Chapter AS document_Chapter,
                   document.t_date_carry AS document_date_carry,
                   document.t_number_pack AS document_number_pack,
                   document.t_numb_document AS document_numb_document,
                   document.t_shifr_oper AS document_shifr_oper,
                   document.t_ground AS document_ground,
                   document.t_department AS document_department,
                   CASE
                       WHEN multycar.t_fiId_payer != multycar.t_fiId_receiver
                       THEN multycar.t_acctrnid
                       WHEN document.t_result_carry = 83
                       THEN (SELECT mcarry.t_accTrnId
                               FROM dacctrn_dbt mcarry
                              WHERE mcarry.t_exRateAccTrnId = document.t_autokey
                                AND ROWNUM < 2
                            )
                       ELSE NULL
                   END AS multycar_carryid, -- KS Адаптация патч 31
                   pmpaym.t_paymentid AS pmpaym_paymentid,
                   -- KS Адаптация патч 31
                   CASE
                       WHEN pmaddpi_c.t_pmaddpiId IS NULL
                        AND pmaddpi_d.t_pmaddpiId IS NULL
                       THEN pmpaym.t_amount
                       WHEN pmaddpi_d.t_pmaddpiId IS NOT NULL
                       THEN pmaddpi_d.t_amount
                       ELSE pmaddpi_c.t_pmamount
                   END                                                             AS pmpaym_Amount,
                   CASE
                       WHEN pmaddpi_c.t_pmaddpiId IS NULL
                        AND pmaddpi_d.t_pmaddpiId IS NULL
                       THEN pmpaym.t_fiId
                       WHEN pmaddpi_d.t_pmaddpiId IS NOT NULL
                       THEN pmaddpi_d.t_fiId
                       ELSE pmaddpi_c.t_pmfiId
                   END                                                             AS pmpaym_FIID,
                   CASE
                       WHEN pmaddpi_c.t_pmaddpiId IS NULL
                        AND pmaddpi_d.t_pmaddpiId IS NULL
                       THEN pmpaym.t_payAmount
                       WHEN pmaddpi_d.t_pmaddpiId IS NOT NULL
                       THEN pmaddpi_d.t_pmamount
                       ELSE pmaddpi_c.t_amount
                   END                                                             AS pmpaym_PayAmount,
                   CASE
                       WHEN pmaddpi_c.t_pmaddpiId IS NULL
                        AND pmaddpi_d.t_pmaddpiId IS NULL
                       THEN pmpaym.t_payFiId
                       WHEN pmaddpi_d.t_pmaddpiId IS NOT NULL
                       THEN pmaddpi_d.t_pmfiId
                       ELSE pmaddpi_c.t_fiId
                   END                                                             AS pmpaym_PayFIID,
                   -- KS End
                   CASE
                      WHEN NOT EXISTS (SELECT   1
                                         FROM   dpmaddpi_dbt
                                        WHERE   pmpaym.t_paymentid = t_paymentid)
                      THEN
                         pmpaym.t_payeraccount
                      ELSE
                         document.t_account_payer
                   END
                      AS pmpaym_payeraccount,
                   CASE
                      WHEN NOT EXISTS (SELECT   1
                                         FROM   dpmaddpi_dbt
                                        WHERE   pmpaym.t_paymentid = t_paymentid)
                      THEN
                         pmpaym.t_receiveraccount
                      ELSE
                         document.t_account_receiver
                   END
                      AS pmpaym_receiveraccount,
                   pmpaym.t_numberpack AS pmpaym_numberpack,
                   DECODE (pmpaym.t_payerbankid, 0, -1, pmpaym.t_payerbankid) AS pmpaym_payerbankid,
                   DECODE (pmpaym.t_receiverbankid, 0, -1, pmpaym.t_receiverbankid) AS pmpaym_receiverbankid,
                   pmpaym.t_valuedate AS pmpaym_valuedate,
                   pmpaym.t_startdepartment AS pmpaym_department,
                   pmpaym.t_dockind AS pmpaym_dockind,
                   pmpaym.t_chapter AS pmpaym_chapter,
                   pmpaym.t_origin AS pmpaym_origin,
                   pmrmprop.t_payercorraccnostro AS pmrmprop_payercorraccnostro,
                   pmrmprop.t_payerbankname AS pmrmprop_payerbankname,
                   pmrmprop.t_receivercorraccnostro AS pmrmprop_receivercorraccnostro,
                   pmrmprop.t_receiverbankname AS pmrmprop_receiverbankname,
                   pmrmprop.t_payername AS pmrmprop_payername,
                   pmrmprop.t_payerinn AS pmrmprop_payerinn,
                   pmrmprop.t_receivername AS pmrmprop_receivername,
                   pmrmprop.t_receiverinn AS pmrmprop_receiverinn,
                   pmrmprop.t_date AS pmrmprop_date,
                   pmrmprop.t_number AS pmrmprop_number,
                   pmrmprop.t_shifroper AS pmrmprop_shifroper,
                   --Gurin S. 09.07.2013 R-204846-2 обрезаем назначение до 255 символов
                   SUBSTR(
                     CASE
                        WHEN NOT EXISTS (SELECT   1
                                           FROM   dpmaddpi_dbt
                                          WHERE   pmpaym.t_paymentid = t_paymentid)
                        THEN
                           pmrmprop.t_ground
                        ELSE
                           document.t_ground
                     END,
                   1,
                   255)
                      AS pmrmprop_ground,
                   pmrmprop.t_paydate AS pmrmprop_paydate,
                   pmrmprop.t_priority AS pmrmprop_priority,
                   pmprop_d.t_codekind AS pmprop_d_codekind,
                   pmprop_d.t_bankcode AS pmprop_d_bankcode,
                   pmprop_c.t_codekind AS pmprop_c_codekind,
                   pmprop_c.t_bankcode AS pmprop_c_bankcode,
                   ptynam_d.t_partyid AS ptynam_d_partyid,
                   ptynam_d.t_name AS ptynam_d_name,
                   DECODE (ptynam_d.t_addname, CHR (1), NULL, ptynam_d.t_addname) AS ptynam_d_addname,
                   ptynam_c.t_partyid AS ptynam_c_partyid,
                   ptynam_c.t_name AS ptynam_c_name,
                   DECODE (ptynam_c.t_addname, CHR (1), NULL, ptynam_c.t_addname) AS ptynam_c_addname,
                   ptycor_d.t_partyid AS ptycor_d_partyid,
                   ptycor_d.t_name AS ptycor_d_name,
                   ptycor_c.t_partyid AS ptycor_c_partyid,
                   ptycor_c.t_name AS ptycor_c_name,
                   bnkdpr_d.t_partyid AS bnkdpr_d_partyid,
                   bnkdpr_d.t_coracc AS bnkdpr_d_coracc,
                   bnkdpr_c.t_partyid AS bnkdpr_c_partyid,
                   bnkdpr_c.t_coracc AS bnkdpr_c_coracc,
                   corsch_d.t_number AS corsch_d_number,
                   corsch_d.t_coraccount AS corsch_d_coraccount,
                   corsch_c.t_number AS corsch_c_number,
                   corsch_c.t_coraccount AS corsch_c_coraccount,
                   pmpurp.t_name AS pmpurp_purpose,
                   pmpokind.t_name AS pmpokind_paymentkind,
                   pmrmprop.t_taxauthorstate AS pmrmprop_taxauthorstate,
                   pmrmprop.t_okatocode AS pmrmprop_okatocode,
                   pmrmprop.t_payerchargeoffdate AS pmrmprop_payerchargeoffdate,
                   pmrmprop.t_taxpmperiod AS pmrmprop_taxpmperiod,
                   pmrmprop.t_taxpmnumber AS pmrmprop_taxpmnumber,
                   pmrmprop.t_taxpmtype AS pmrmprop_taxpmtype,
                   pmrmprop.t_taxpmdate AS pmrmprop_taxpmdate,
                   pmrmprop.t_bttticode AS pmrmprop_bttticode,
                   pmrmprop.t_taxpmground AS pmrmprop_taxpmground,
                   to_date(to_char(document.t_systemdate,'DDMMYYYY')||' '||to_char(document.t_systemtime,'HH24MISS'),'DDMMYYYY HH24MISS') AS document_Time_Carry -- KS Адаптация 31 патч,
            FROM   --dmultycar_dbt multycar,
                   (select *
                      from dacctrn_dbt
                     where t_fiId_payer != t_fiId_receiver
                       and t_fiId_payer != 0
                       and t_fiId_receiver != 0
                   ) multycar, -- KS Адаптация 31 патч
                   dacctrn_dbt acctrn, -- KS Адаптация 31 патч
                   dpmprop_dbt pmprop_c,
                   dpmprop_dbt pmprop_d,
                   dpmaddpi_dbt pmaddpi_c, -- KS Адаптация 31 патч
                   dpmaddpi_dbt pmaddpi_d, -- KS Адаптация 31 патч
                   dpmdocs_dbt pmdocs,
                   dbankdprt_dbt bnkdpr_c,
                   dbankdprt_dbt bnkdpr_d,
                   dfininstr_dbt finins_c,
                   dfininstr_dbt finins_d,
                   dcorschem_dbt corsch_c,
                   dcorschem_dbt corsch_d,
                   dparty_dbt ptycor_c,
                   dparty_dbt ptycor_d,
                   dparty_dbt ptynam_c,
                   dparty_dbt ptynam_d,
                   dpmpaym_dbt pmpaym,
                   dpmrmprop_dbt pmrmprop,
                   dpmpurp_dbt pmpurp,
                   dpmpopknd_dbt pmpokind,
                   (SELECT   DISTINCT * FROM DDINFDOC1_TMP) document
           WHERE /* Привязка проводки к платежу */
                --document.t_iapplicationkind = pmdocs.t_applicationkind(+)
                 --  AND document.t_applicationkey = pmdocs.t_applicationkey(+)
                 --  AND /* Ищем мультивалютный документ */
                 --     document.t_connappkind = multycar.t_iapplicationkind(+)
                 --  AND document.t_connappkey = multycar.t_applicationkey(+)
                 document.t_autokey = pmdocs.t_accTrnId(+) -- KS Адаптация патч 31
                 AND document.t_autokey = multycar.t_accTrnId(+) -- KS Адаптация патч 31
                 AND document.t_autokey = acctrn.t_accTrnId(+) -- KS Адаптация патч 31
                   --AND /* По привязке ищем платеж */
                   --   pmdocs.t_linkkindid(+) = 1  -- KS Адаптация патч 31
                   AND pmdocs.t_paymentid = pmpaym.t_paymentid(+)
                   AND/* По платежу ищем реквизиты платежа, характерные для R-макета */
                      pmpaym.t_paymentid = pmrmprop.t_paymentid(+)
                   AND /* Для дебетового счета */
                   /* По привязке ищем уточняющую запись */
                       pmdocs.t_pmaddpiId         = pmaddpi_d.t_pmaddpiId(+) AND -- KS Адаптация патч 31
                       pmaddpi_d.t_debetCredit(+) = 0                        AND -- KS Адаптация патч 31
                      /* По платежу ищем свойства платежа */
                      pmpaym.t_paymentid = pmprop_d.t_paymentid(+)
                   AND pmprop_d.t_debetcredit(+) = 0
                   AND /* По свойству платежа находим ФИ */
                      pmprop_d.t_payfiid = finins_d.t_fiid(+)
                   AND /* По свойству платежа и ФИ находим схему корр. отношений */
                      pmprop_d.t_payfiid = corsch_d.t_fiid(+)
                   AND pmprop_d.t_corschem = corsch_d.t_number(+)
                   AND (finins_d.t_fi_kind = corsch_d.t_fi_kind OR corsch_d.t_number IS NULL)
                   AND/* По схеме корр. отношений находим корреспондирующего субъекта */
                      corsch_d.t_corrid = ptycor_d.t_partyid(+)
                   AND/* 17.02.2009 ABP По id банка плательщика соединяемся с субъектом */
                      pmpaym.t_payerbankid = ptynam_d.t_partyid(+)
                   AND /* По субъекту находим банк */
                      ptynam_d.t_partyid = bnkdpr_d.t_partyid(+)
                   AND /* Для кредитового счета */             /* По привязке ищем уточняющую запись */
                   pmdocs.t_pmaddpiId         = pmaddpi_c.t_pmaddpiId(+) AND -- KS Адаптация 31 патч
                   pmaddpi_c.t_debetCredit(+) = 1                        AND -- KS Адаптация 31 патч
                      /* По платежу ищем свойства платежа */
                      pmpaym.t_paymentid = pmprop_c.t_paymentid(+)
                   AND pmprop_c.t_debetcredit(+) = 1
                   AND /* По свойству платежа находим ФИ */
                      pmprop_c.t_payfiid = finins_c.t_fiid(+)
                   AND /* По свойству платежа и ФИ находим схему корр. отношений */
                      pmprop_c.t_payfiid = corsch_c.t_fiid(+)
                   AND pmprop_c.t_corschem = corsch_c.t_number(+)
                   AND (finins_c.t_fi_kind = corsch_c.t_fi_kind OR corsch_c.t_number IS NULL)
                   AND/* По схеме корр. отношений находим корреспондирующего субъекта */
                      corsch_c.t_corrid = ptycor_c.t_partyid(+)
                   AND/* 17.02.2009 ABP По id банка получателя соединяемся с субъектом */
                      pmpaym.t_receiverbankid = ptynam_c.t_partyid(+)
                   AND /* По субъекту находим банк */
                      ptynam_c.t_partyid = bnkdpr_c.t_partyid(+)
                   AND pmpaym.t_purpose = pmpurp.t_purpose(+)
                   AND pmrmprop.t_paymentkind = pmpokind.t_paymentkind(+))
      LOOP
         clear_docinf ();

         ddinfcach.t_mt103 :=               usr_getswiftnote (flds_rec.pmpaym_paymentid); -- zip_z. C-11287

         -- Поля, заполняемые данными из проводки
         ddinfcach.t_autokey :=             flds_rec.document_autokey;
         --ddinfcach.t_applicationkind :=     flds_rec.document_applicationkind;
         ddinfcach.t_applicationkind :=     flds_rec.document_applicationkind;
         ddinfcach.t_applicationkey :=      flds_rec.document_applicationkey;
         ddinfcach.t_code_currency :=       flds_rec.document_code_currency;
         --ddinfcach.t_code_currency :=       flds_rec.document_fiId_payer;
         ddinfcach.t_date_carry :=          flds_rec.document_date_carry;
         ddinfcach.t_time_carry :=          flds_rec.document_time_carry; -- KS 28.03.2014 Время зачисления
         ddinfcach.t_receiveraccount_a :=   flds_rec.document_account_receiver;
         ddinfcach.t_payeraccount_a :=      flds_rec.document_account_payer;
         -- данные из платежа - Дата документа
         ddinfcach.t_date :=                flds_rec.pmrmprop_date;
         -- Поля, заполняемые данными из МВП
         ddinfcach.t_carryid :=             flds_rec.multycar_carryid;

         IF (flds_rec.pmpaym_paymentid IS NOT NULL)
         THEN
            -- Поля, заполняемые данными из платежа
            ddinfcach.t_paymentid :=            flds_rec.pmpaym_paymentid;
            ddinfcach.t_purpose :=              flds_rec.pmpurp_purpose;
            ddinfcach.t_paymentkind :=          flds_rec.pmpokind_paymentkind;
            ddinfcach.t_paydate :=              flds_rec.pmrmprop_paydate;
            ddinfcach.t_priority :=             flds_rec.pmrmprop_priority;
            ddinfcach.t_payerchargeoffdate :=   flds_rec.pmrmprop_payerchargeoffdate;
            ddinfcach.t_taxauthorstate :=       flds_rec.pmrmprop_taxauthorstate;
            ddinfcach.t_bttticode :=            flds_rec.pmrmprop_bttticode;
            ddinfcach.t_okatocode :=            flds_rec.pmrmprop_okatocode;
            ddinfcach.t_taxpmground :=          flds_rec.pmrmprop_taxpmground;
            ddinfcach.t_taxpmperiod :=          flds_rec.pmrmprop_taxpmperiod;
            ddinfcach.t_taxpmnumber :=          flds_rec.pmrmprop_taxpmnumber;
            ddinfcach.t_taxpmdate :=            flds_rec.pmrmprop_taxpmdate;
            ddinfcach.t_taxpmtype :=            flds_rec.pmrmprop_taxpmtype;

            IF (flds_rec.pmrmprop_payercorraccnostro != CHR (1))
            THEN
               ddinfcach.t_payercorracc :=   flds_rec.pmrmprop_payercorraccnostro;
            ELSE
               ddinfcach.t_payercorracc :=   getcoracc (flds_rec.pmpaym_payerbankid);
            END IF;

            IF (flds_rec.pmrmprop_receivercorraccnostro != CHR (1))
            THEN
               ddinfcach.t_receivercorracc :=   flds_rec.pmrmprop_receivercorraccnostro;
            ELSE
               ddinfcach.t_receivercorracc :=   getcoracc (flds_rec.pmpaym_receiverbankid);
            END IF;

            IF (flds_rec.pmrmprop_payerbankname != CHR (1))
            THEN
               ddinfcach.t_payerbankname :=   flds_rec.pmrmprop_payerbankname;
            ELSE
               ddinfcach.t_payerbankname :=   flds_rec.ptynam_d_name || flds_rec.ptynam_d_addname;
            END IF;

            IF (flds_rec.pmrmprop_receiverbankname != CHR (1))
            THEN
               ddinfcach.t_receiverbankname :=   flds_rec.pmrmprop_receiverbankname;
            ELSE
               ddinfcach.t_receiverbankname :=   flds_rec.ptynam_c_name || flds_rec.ptynam_c_addname;
            END IF;

            IF (lv_codekind IN (cnst.ptck_all, flds_rec.pmprop_d_codekind))
            THEN
               ddinfcach.t_payercodekind :=   flds_rec.pmprop_d_codekind;
               ddinfcach.t_payerbankcode :=   flds_rec.pmprop_d_bankcode;
            END IF;

            IF (lv_codekind IN (cnst.ptck_all, flds_rec.pmprop_c_codekind))
            THEN
               ddinfcach.t_receivercodekind :=   flds_rec.pmprop_c_codekind;
               ddinfcach.t_receiverbankcode :=   flds_rec.pmprop_c_bankcode;
            END IF;

            -- Поля, заполняемые в зависимости от источника данных (платеж/проводка)
            IF (lv_getflddoc = 0)
            THEN
               -- данные из платежа
               --RR Рахмедов Руслан 05.03.2012 передаем не дату значения а дату документа
               ddinfcach.t_date :=              flds_rec.pmrmprop_date;
               ddinfcach.t_department :=        flds_rec.pmpaym_department;

               IF (flds_rec.pmpaym_dockind = 15)
               THEN
                  ddinfcach.t_amount :=   flds_rec.document_sum;
               ELSE
                  ddinfcach.t_amount :=   flds_rec.pmpaym_amount;
               END IF;

               ddinfcach.t_payeramount :=       flds_rec.pmpaym_amount;
               ddinfcach.t_receiveramount :=    flds_rec.pmpaym_payamount;

               --zmp 17.07.2012 I-00200473 для рублевых платежей берем сумму по проводке.
               IF (flds_rec.pmpaym_dockind = 201)
               THEN
                  ddinfcach.t_amount :=           flds_rec.document_sum;
                  ddinfcach.t_payeramount :=      flds_rec.document_sum;
                  ddinfcach.t_receiveramount :=   flds_rec.document_sum;
               END IF;

               ddinfcach.t_fiid :=              flds_rec.pmpaym_fiid;
               ddinfcach.t_payerfiid :=         flds_rec.pmpaym_fiid;
               ddinfcach.t_receiverfiid :=      flds_rec.pmpaym_payfiid;
               ddinfcach.t_payeraccount :=      flds_rec.pmpaym_payeraccount;
               ddinfcach.t_receiveraccount :=   flds_rec.pmpaym_receiveraccount;
               ddinfcach.t_number_pack :=       flds_rec.pmpaym_numberpack;
               ddinfcach.t_numb_document :=     flds_rec.pmrmprop_number;
               ddinfcach.t_shifr_oper :=        flds_rec.pmrmprop_shifroper;
               ddinfcach.t_ground :=            flds_rec.pmrmprop_ground;

               IF ( (flds_rec.pmrmprop_payerinn != CHR (1)) AND (flds_rec.pmrmprop_payername != CHR (1)))
               THEN
                  ddinfcach.t_payerinn_kpp :=   flds_rec.pmrmprop_payerinn;
                  ddinfcach.t_payerinn :=       getinn (ddinfcach.t_payerinn_kpp);
                  ddinfcach.t_payername :=      flds_rec.pmrmprop_payername;
               ELSE
                  getnameclnt (flds_rec.pmpaym_chapter,
                               ddinfcach.t_payerfiid,
                               ddinfcach.t_payeraccount,
                               ddinfcach.t_payername,
                               ddinfcach.t_payerinn_kpp,
                               ddinfcach.t_payerinn,
                               ddinfcach.t_date);

                  IF (flds_rec.pmrmprop_payerinn != CHR (1))
                  THEN
                     ddinfcach.t_payerinn_kpp :=   flds_rec.pmrmprop_payerinn;
                     ddinfcach.t_payerinn :=       getinn (ddinfcach.t_payerinn_kpp);
                  END IF;

                  IF (flds_rec.pmrmprop_payername != CHR (1))
                  THEN
                     ddinfcach.t_payername :=   flds_rec.pmrmprop_payername;
                  END IF;
               END IF;

               IF ( (flds_rec.pmrmprop_receiverinn != CHR (1)) AND (flds_rec.pmrmprop_receivername != CHR (1)))
               THEN
                  ddinfcach.t_receiverinn_kpp :=   flds_rec.pmrmprop_receiverinn;
                  ddinfcach.t_receiverinn :=       getinn (ddinfcach.t_receiverinn_kpp);
                  ddinfcach.t_receivername :=      flds_rec.pmrmprop_receivername;
               ELSE
                  getnameclnt (flds_rec.pmpaym_chapter,
                               ddinfcach.t_receiverfiid,
                               ddinfcach.t_receiveraccount,
                               ddinfcach.t_receivername,
                               ddinfcach.t_receiverinn_kpp,
                               ddinfcach.t_receiverinn,
                               ddinfcach.t_date);

                  IF (flds_rec.pmrmprop_receiverinn != CHR (1))
                  THEN
                     ddinfcach.t_receiverinn_kpp :=   flds_rec.pmrmprop_receiverinn;
                     ddinfcach.t_receiverinn :=       getinn (ddinfcach.t_receiverinn_kpp);
                  END IF;

                  IF (flds_rec.pmrmprop_receivername != CHR (1))
                  THEN
                     ddinfcach.t_receivername :=   flds_rec.pmrmprop_receivername;
                  END IF;
               END IF;
            ELSE
               -- данные из проводки
               ddinfcach.t_date :=              flds_rec.document_date_carry;
               ddinfcach.t_department :=        flds_rec.document_department;
               ddinfcach.t_amount :=            flds_rec.document_sum;
               ddinfcach.t_payeramount :=       flds_rec.document_sum;
               ddinfcach.t_receiveramount :=    flds_rec.document_sum;
               ddinfcach.t_fiid :=              flds_rec.document_code_currency;
               ddinfcach.t_payerfiid :=         flds_rec.document_fiid_payer;
               ddinfcach.t_receiverfiid :=      flds_rec.document_fiid_receiver;
               ddinfcach.t_payeraccount :=      flds_rec.document_account_payer;
               ddinfcach.t_receiveraccount :=   flds_rec.document_account_receiver;
               ddinfcach.t_number_pack :=       flds_rec.document_number_pack;
               ddinfcach.t_numb_document :=     flds_rec.document_numb_document;
               ddinfcach.t_shifr_oper :=        flds_rec.document_shifr_oper;
               ddinfcach.t_ground :=            flds_rec.document_ground;
               getnameclnt (flds_rec.document_chapter,
                            ddinfcach.t_payerfiid,
                            ddinfcach.t_payeraccount,
                            ddinfcach.t_payername,
                            ddinfcach.t_payerinn_kpp,
                            ddinfcach.t_payerinn,
                            ddinfcach.t_date);
               getnameclnt (flds_rec.document_chapter,
                            ddinfcach.t_receiverfiid,
                            ddinfcach.t_receiveraccount,
                            ddinfcach.t_receivername,
                            ddinfcach.t_receiverinn_kpp,
                            ddinfcach.t_receiverinn,
                            ddinfcach.t_date);
            END IF;

            -- Поля, заполняемые информацией из справочников
            IF (m_usehistory = 0)
            THEN
               requireddate :=   NULL;
            ELSE
               requireddate :=   ddinfcach.t_date;
            END IF;

            IF (flds_rec.pmpaym_payerbankid = -1)
            THEN
               ddinfcach.t_payerbic :=     CHR (1);
               ddinfcach.t_payerswift :=   CHR (1);
            ELSE
               ddinfcach.t_payerbic :=     rsb_rep_pt.get_partycode (cnst.ptck_bic, flds_rec.pmpaym_payerbankid, requireddate, 1);
               ddinfcach.t_payerswift :=   rsb_rep_pt.get_partycode (cnst.ptck_swift, flds_rec.pmpaym_payerbankid, requireddate, 1);
            END IF;

            IF (flds_rec.pmpaym_receiverbankid = -1)
            THEN
               ddinfcach.t_receiverbic :=     CHR (1);
               ddinfcach.t_receiverswift :=   CHR (1);
            ELSE
               ddinfcach.t_receiverbic :=     rsb_rep_pt.get_partycode (cnst.ptck_bic, flds_rec.pmpaym_receiverbankid, requireddate, 1);
               ddinfcach.t_receiverswift :=   rsb_rep_pt.get_partycode (cnst.ptck_swift, flds_rec.pmpaym_receiverbankid, requireddate, 1);
            END IF;

            IF (flds_rec.corsch_d_number IS NOT NULL)
            THEN
               ddinfcach.t_corrbankacc :=   flds_rec.corsch_d_coraccount;

               IF (flds_rec.ptycor_d_partyid IS NOT NULL)
               THEN
                  ddinfcach.t_corrbankname :=   flds_rec.ptycor_d_name;
               END IF;
            END IF;

            IF (flds_rec.corsch_c_number IS NOT NULL)
            THEN
               ddinfcach.t_corrbankacc :=   flds_rec.corsch_c_coraccount;

               IF (flds_rec.ptycor_c_partyid IS NOT NULL)
               THEN
                  ddinfcach.t_corrbankname :=   flds_rec.ptycor_c_name;
               END IF;
            END IF;
         ELSE
            -- Поля, заполняемые данными из платежа
            ddinfcach.t_paymentid :=            NULL;
            ddinfcach.t_payerchargeoffdate :=   NULL;
            ddinfcach.t_taxauthorstate :=       NULL;
            ddinfcach.t_bttticode :=            NULL;
            ddinfcach.t_okatocode :=            NULL;
            ddinfcach.t_taxpmground :=          NULL;
            ddinfcach.t_taxpmperiod :=          NULL;
            ddinfcach.t_taxpmnumber :=          NULL;
            ddinfcach.t_taxpmdate :=            NULL;
            ddinfcach.t_taxpmtype :=            NULL;
            ddinfcach.t_purpose :=              NULL;
            ddinfcach.t_paymentkind :=          NULL;
            ddinfcach.t_paydate :=              NULL;
            ddinfcach.t_priority :=             NULL;
            -- Поля, заполняемые данными из проводки
            ddinfcach.t_date :=                 flds_rec.document_date_carry;
            ddinfcach.t_department :=           flds_rec.document_department;
            ddinfcach.t_amount :=               flds_rec.document_sum;
            ddinfcach.t_payeramount :=          flds_rec.document_sum;
            ddinfcach.t_receiveramount :=       flds_rec.document_sum;
            ddinfcach.t_fiid :=                 flds_rec.document_code_currency;
            ddinfcach.t_payerfiid :=            flds_rec.document_fiid_payer;
            ddinfcach.t_receiverfiid :=         flds_rec.document_fiid_receiver;
            ddinfcach.t_payeraccount :=         flds_rec.document_account_payer;
            ddinfcach.t_receiveraccount :=      flds_rec.document_account_receiver;
            ddinfcach.t_number_pack :=          flds_rec.document_number_pack;
            ddinfcach.t_numb_document :=        flds_rec.document_numb_document;
            ddinfcach.t_shifr_oper :=           flds_rec.document_shifr_oper;
            ddinfcach.t_ground :=               flds_rec.document_ground;
            -- Поля, заполняемые информацией из справочников
            ddinfcach.t_payercorracc :=         v_coraccour;
            ddinfcach.t_payerbankname :=        v_nameour || v_addnameour;
            ddinfcach.t_receivercorracc :=      v_coraccour;
            ddinfcach.t_receiverbankname :=     v_nameour || v_addnameour;

            IF (m_usehistory = 0)
            THEN
               requireddate :=   NULL;
            ELSE
               requireddate :=   ddinfcach.t_date;
            END IF;

            v_bicour :=                         rsb_rep_pt.get_partycode (cnst.ptck_bic, lv_ourbank, requireddate, 1);
            v_swiftour :=                       rsb_rep_pt.get_partycode (cnst.ptck_swift, lv_ourbank, requireddate, 1);
            ddinfcach.t_payerbic :=             v_bicour;
            ddinfcach.t_payerswift :=           v_swiftour;
            ddinfcach.t_receiverbic :=          v_bicour;
            ddinfcach.t_receiverswift :=        v_swiftour;
            ddinfcach.t_payercodekind :=        cnst.ptck_bic;
            ddinfcach.t_payerbankcode :=        v_bicour;
            ddinfcach.t_receivercodekind :=     cnst.ptck_bic;
            ddinfcach.t_receiverbankcode :=     v_bicour;
            getnameclnt (flds_rec.document_chapter,
                         ddinfcach.t_payerfiid,
                         ddinfcach.t_payeraccount,
                         ddinfcach.t_payername,
                         ddinfcach.t_payerinn_kpp,
                         ddinfcach.t_payerinn,
                         ddinfcach.t_date);
            getnameclnt (flds_rec.document_chapter,
                         ddinfcach.t_receiverfiid,
                         ddinfcach.t_receiveraccount,
                         ddinfcach.t_receivername,
                         ddinfcach.t_receiverinn_kpp,
                         ddinfcach.t_receiverinn,
                         ddinfcach.t_date);
            ddinfcach.t_corrbankacc :=          NULL;
            ddinfcach.t_corrbankname :=         NULL;
         END IF;

         IF (flds_rec.pmpaym_origin >= 1000) -- 21.02.2012 Chesnokov D.S Документы ABBYY(2100) и документы 365-П(3300)
                                             -- собираются по платежу I - 00156372
            AND (flds_rec.pmpaym_origin NOT IN (2100, 3300)) AND (count_doc (flds_rec.pmpaym_paymentid) > 1)
         THEN
            -- данные из проводки
            ddinfcach.t_paymentid :=         NULL;
            ddinfcach.t_date :=              flds_rec.document_date_carry;
            ddinfcach.t_department :=        flds_rec.document_department;
            ddinfcach.t_amount :=            flds_rec.document_sum;
            ddinfcach.t_payeramount :=       flds_rec.document_sum;
            ddinfcach.t_receiveramount :=    flds_rec.document_sum;
            ddinfcach.t_fiid :=              flds_rec.document_code_currency;
            ddinfcach.t_payerfiid :=         flds_rec.document_fiid_payer;
            ddinfcach.t_receiverfiid :=      flds_rec.document_fiid_receiver;

            -- begin >
            -- UDA 17.08.2012 по запросу I-00221335-2
            -- Для документов с происхождением 9999 данные о счете плательщика в ИК отбираются из платежа
            -- ddinfcach.t_payeraccount := flds_rec.document_account_payer;
            IF (flds_rec.pmpaym_origin = 9999) --
            THEN
               ddinfcach.t_payeraccount :=   flds_rec.pmpaym_payeraccount; --
            ELSE
               ddinfcach.t_payeraccount :=   flds_rec.document_account_payer; --
            END IF;

            -- < end
            ddinfcach.t_receiveraccount :=   flds_rec.document_account_receiver;
            ddinfcach.t_number_pack :=       flds_rec.document_number_pack;
            ddinfcach.t_numb_document :=     flds_rec.document_numb_document;
            ddinfcach.t_shifr_oper :=        flds_rec.document_shifr_oper;
            ddinfcach.t_ground :=            flds_rec.document_ground;

            -- begin >
            -- UDA 22.08.12 по запросу I-00221335-2
            -- В некоторых случаях данные о плательщике отсутствуют в базе, поэтому отбираются из платежа.
            IF (flds_rec.pmpaym_origin = 9999)
            THEN
               ddinfcach.t_payername :=      flds_rec.pmrmprop_payername;
               ddinfcach.t_payerinn_kpp :=   flds_rec.pmrmprop_payerinn;
               ddinfcach.t_payerinn :=       getinn (ddinfcach.t_payerinn_kpp);
            ELSE
               getnameclnt (flds_rec.document_chapter,
                            ddinfcach.t_payerfiid,
                            ddinfcach.t_payeraccount,
                            ddinfcach.t_payername,
                            ddinfcach.t_payerinn_kpp,
                            ddinfcach.t_payerinn,
                            ddinfcach.t_date);
            END IF;

            -- < end
            getnameclnt (flds_rec.document_chapter,
                         ddinfcach.t_receiverfiid,
                         ddinfcach.t_receiveraccount,
                         ddinfcach.t_receivername,
                         ddinfcach.t_receiverinn_kpp,
                         ddinfcach.t_receiverinn,
                         ddinfcach.t_date);
         END IF;

         -- zmp 31.05.2012 вытягиваем основные поля для ИК
         IF ( (flds_rec.pmpaym_paymentid IS NULL) AND (getpaymentid (flds_rec.document_autokey) > 0))
         THEN
            paymentid :=   getpaymentid (flds_rec.document_autokey);

            BEGIN
               SELECT   pmrmprop.t_payerbankname AS pmrmprop_payerbankname,
                        pmrmprop.t_receiverbankname AS pmrmprop_receiverbankname,
                        pmrmprop.t_payerchargeoffdate AS pmrmprop_payerchargeoffdate,
                        pmrmprop.t_paydate AS pmrmprop_paydate,
                        pmrmprop.t_priority AS pmrmprop_priority,
                        pmpokind.t_name AS pmpokind_paymentkind,
                        pmpurp.t_name AS pmpurp_purpose,
                        pmrmprop.t_payercorraccnostro AS pmrmprop_payercorraccnostro,
                        pmrmprop.t_receivercorraccnostro AS pmrmprop_receivercorraccnostro,
                        pmpaym.t_payerbankid AS pmpaym_payerbankid,
                        pmpaym.t_receiverbankid AS pmpaym_receiverbankid,
                        (SELECT   pr.t_bankcode
                           FROM   dpmprop_dbt pr
                          WHERE   pr.t_debetcredit = 0 AND pr.t_paymentid = pmpaym.t_paymentid)
                           AS pmprop_d_bankcode,
                        (SELECT   pr.t_bankcode
                           FROM   dpmprop_dbt pr
                          WHERE   pr.t_debetcredit = 1 AND pr.t_paymentid = pmpaym.t_paymentid)
                           AS pmprop_c_bankcode
                 INTO   baseflds_rec
                 FROM   dpmpaym_dbt pmpaym, dpmrmprop_dbt pmrmprop, dpmpopknd_dbt pmpokind, dpmpurp_dbt pmpurp
                WHERE       pmpaym.t_paymentid = paymentid
                        AND pmrmprop.t_paymentid = pmpaym.t_paymentid
                        AND pmpokind.t_paymentkind = pmrmprop.t_paymentkind
                        AND pmpaym.t_purpose = pmpurp.t_purpose;

               ddinfcach.t_payerbankname :=        baseflds_rec.pmrmprop_payerbankname;
               ddinfcach.t_receiverbankname :=     baseflds_rec.pmrmprop_receiverbankname;
               ddinfcach.t_payerchargeoffdate :=   baseflds_rec.pmrmprop_payerchargeoffdate;
               ddinfcach.t_paydate :=              baseflds_rec.pmrmprop_paydate;
               ddinfcach.t_priority :=             baseflds_rec.pmrmprop_priority;
               ddinfcach.t_paymentkind :=          baseflds_rec.pmpokind_paymentkind;
               ddinfcach.t_purpose :=              baseflds_rec.pmpurp_purpose;
               ddinfcach.t_paymentid :=            paymentid;
               ddinfcach.t_payerbankcode :=        baseflds_rec.pmprop_d_bankcode;
               ddinfcach.t_receiverbankcode :=     baseflds_rec.pmprop_c_bankcode;

               IF (flds_rec.pmrmprop_payercorraccnostro != CHR (1))
               THEN
                  ddinfcach.t_payercorracc :=   baseflds_rec.pmrmprop_payercorraccnostro;
               ELSE
                  ddinfcach.t_payercorracc :=   getcoracc (baseflds_rec.pmpaym_payerbankid);
               END IF;

               IF (flds_rec.pmrmprop_receivercorraccnostro != CHR (1))
               THEN
                  ddinfcach.t_receivercorracc :=   baseflds_rec.pmrmprop_receivercorraccnostro;
               ELSE
                  ddinfcach.t_receivercorracc :=   getcoracc (baseflds_rec.pmpaym_receiverbankid);
               END IF;

               IF (flds_rec.pmpaym_payerbankid = -1)
               THEN
                  ddinfcach.t_payerbic :=     CHR (1);
                  ddinfcach.t_payerswift :=   CHR (1);
               ELSE
                  ddinfcach.t_payerbic :=     rsb_rep_pt.get_partycode (cnst.ptck_bic, baseflds_rec.pmpaym_payerbankid, requireddate, 1);
                  ddinfcach.t_payerswift :=   rsb_rep_pt.get_partycode (cnst.ptck_swift, baseflds_rec.pmpaym_payerbankid, requireddate, 1);
               END IF;

               IF (flds_rec.pmpaym_receiverbankid = -1)
               THEN
                  ddinfcach.t_receiverbic :=     CHR (1);
                  ddinfcach.t_receiverswift :=   CHR (1);
               ELSE
                  ddinfcach.t_receiverbic :=
                     rsb_rep_pt.get_partycode (cnst.ptck_bic, baseflds_rec.pmpaym_receiverbankid, requireddate, 1);
                  ddinfcach.t_receiverswift :=
                     rsb_rep_pt.get_partycode (cnst.ptck_swift, baseflds_rec.pmpaym_receiverbankid, requireddate, 1);
               END IF;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  NULL;
            END;
         END IF;

         --zmp 31.05.2012 Конец!
         dummy_value :=                     NULL;

         BEGIN
            SELECT   1
              INTO   dummy_value
              FROM   dpmaddpi_dbt
             WHERE   t_paymentid = ddinfcach.t_paymentid AND ROWNUM < 2;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
         END;

         IF (dummy_value IS NOT NULL)
         THEN
            ddinfcach.t_paymentid :=   NULL;
         END IF;

         -- KS Адаптация патч 31
         recordsCount := recordsCount + 1;
         m_cacheRecordsArray(recordsCount) := ddinfcach;

         IF (recordsCount = saverThreshold)
         THEN
             FORALL i IN m_cacheRecordsArray.FIRST..m_cacheRecordsArray.LAST
                 INSERT INTO ddinfcach1_tmp VALUES m_cacheRecordsArray(i);

             recordsCount := 0;
             m_cacheRecordsArray.DELETE;
         END IF;
         -- KS End

         i :=                               i + 1;
      END LOOP;

      -- KS Адаптация патч 31
      IF (m_cacheRecordsArray.COUNT > 0)
      THEN
         FORALL i IN m_cacheRecordsArray.FIRST..m_cacheRecordsArray.LAST
            INSERT INTO ddinfcach1_tmp VALUES m_cacheRecordsArray(i);
      END IF;
      -- KS End

      COMMIT;
   END fill;
END RSB_DINFCACH30; 
/
