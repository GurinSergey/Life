CREATE OR REPLACE PACKAGE "USR_FS"
AS

FUNCTION GET_SOURCE( PaymentID in number, Dat in date) RETURN NUMBER;
function Get_last_source( paymid in number, dat in date ) return number;

function Get_Cc ( acc varchar2, carrydate date, inputcc dacctrn_dbt.t_sum_natcur%TYPE ) RETURN dacctrn_dbt.t_sum_natcur%TYPE;

function Get_Cred ( acc varchar2, carrydate date, inputcred dacctrn_dbt.t_sum_natcur%TYPE ) RETURN dacctrn_dbt.t_sum_natcur%TYPE;

FUNCTION substr_in_ground (p_paymentID IN NUMBER) RETURN number;

FUNCTION IsLoanPaym ( p_receiveracc IN VARCHAR2) RETURN number;

procedure Set_source(p_paymID in number, p_date in date, p_oper in number, p_source in number);

function Get_Oper ( PaymentID in number, Dat in date) RETURN NUMBER;

function HasLoanAcc(v_account in varchar2) return number;

function HasLoanPaym(v_account in varchar2, startdate in date, enddate in date) return number;

end USR_FS; 
 
/
CREATE OR REPLACE PACKAGE BODY USR_FS
IS

function HasLoanPaym(v_account in varchar2, startdate in date, enddate in date) return number
AS
  i number :=0;
begin

                                                    
  select 1 into i from dacctrn_dbt arh where ARH.T_ACCOUNT_RECEIVER = v_account
                                      and arh.t_chapter = 1
                                      and REGEXP_LIKE (arh.t_account_payer, '^4[4-5][0-4]0[1-9]|^4560[1-9]')
                                      and ARH.T_DATE_CARRY between STARTDATE and ENDDATE;

  Return i;
          EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        RETURN 1;      
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
end;

--поиск слов (заданных в настройке 'PRBB\ЦЕЛЕВОЕ ИСПОЛЬЗОВАНИЕ\ОСНОВАНИЕ ПЛАТЕЖА') в основании платежа
FUNCTION substr_in_ground (p_paymentID IN number) RETURN number
AS
   i   PLS_INTEGER := 1;
   p_ground varchar2(300) := '';
BEGIN

                                                      
   select t_ground into p_ground from dpmrmprop_dbt where t_paymentID = p_paymentID; 
   WHILE i = 1
     OR INSTR
           (rsb_common.getregstrvalue
                              ('PRBB\ЦЕЛЕВОЕ ИСПОЛЬЗОВАНИЕ\ОСНОВАНИЕ ПЛАТЕЖА',
                               0
                              ),
            ',',
            i
           ) > 0
   LOOP
      IF (INSTR
             (replace(UPPER (p_ground),' ','_'),
                 trim(UPPER(SUBSTR
                     (rsb_common.getregstrvalue
                              ('PRBB\ЦЕЛЕВОЕ ИСПОЛЬЗОВАНИЕ\ОСНОВАНИЕ ПЛАТЕЖА',
                               0
                              ),
                      i,
                      (INSTR
                         (rsb_common.getregstrvalue
                              ('PRBB\ЦЕЛЕВОЕ ИСПОЛЬЗОВАНИЕ\ОСНОВАНИЕ ПЛАТЕЖА',
                               0
                              ),
                          ',',
                          i
                         ) - i)
                     )
                 )
            )) > 0 
         )
      THEN
         RETURN 1;
      END IF;

      i :=
           INSTR
              (rsb_common.getregstrvalue
                              ('PRBB\ЦЕЛЕВОЕ ИСПОЛЬЗОВАНИЕ\ОСНОВАНИЕ ПЛАТЕЖА',
                               0
                              ),
               ',',
               i
              )
         + 1;
   END LOOP;
   
         IF (INSTR
             (replace(UPPER (p_ground),' ','_'),
                 (UPPER(SUBSTR
                     (rsb_common.getregstrvalue
                              ('PRBB\ЦЕЛЕВОЕ ИСПОЛЬЗОВАНИЕ\ОСНОВАНИЕ ПЛАТЕЖА',
                               0
                              ),
                      i
                     )
                 )
            )) > 0 
         )
      THEN
         RETURN 1;
      END IF;

   RETURN 0;
END;

FUNCTION IsLoanPaym ( p_receiveracc IN VARCHAR2) RETURN number
AS
begin

  
                                          
-- KS Адаптация патч 30 04.07.2011
if((RSI_RSB_MASK.CompareStringWithMask('441-457' ,substr(p_receiveracc, 1, 3))>0) or (RSI_RSB_MASK.CompareStringWithMask('47422810100000060154' ,p_receiveracc)>0) /*or (substr(p_receiveracc,1,5)='70601')*/) then
   RETURN 1;
end if;

RETURN 0;   

end;

-- Посчитать величину СОБСТВЕННЫХ СРЕДСТВ по счету за дату carrydate
function Get_Cc ( acc varchar2, carrydate date, inputcc dacctrn_dbt.t_sum_natcur%TYPE ) RETURN dacctrn_dbt.t_sum_natcur%TYPE
AS
Sk dacctrn_dbt.t_sum_natcur%TYPE :=0;
Sc dacctrn_dbt.t_sum_natcur%TYPE :=0;
Amount dacctrn_dbt.t_sum_natcur%TYPE :=0;

begin

  
                                                    
--все приходы кроме кредитных
SELECT NVL(SUM (arh.t_sum_natcur),0)
  INTO sk
  FROM dacctrn_dbt arh
 WHERE arh.t_account_receiver = acc
   AND arh.t_chapter = 1
   AND arh.t_date_carry = carrydate
   AND NOT REGEXP_LIKE (arh.t_account_payer, '^4[4-5][0-4]0[1-9]|^4560[1-9]');
      
--Нецелевые расходы за счет собственных средств
SELECT NVL(SUM (t_sum_natcur),0)
  INTO sc
  FROM 
  (select distinct arh.*
 from  dacctrn_dbt arh,
       dpmdocs_dbt doc
 WHERE arh.t_account_payer = acc
   AND arh.t_chapter = 1
   AND arh.t_date_carry = carrydate
   AND arh.t_Acctrnid = doc.t_Acctrnid
   and usr_FS.Get_Source (doc.t_paymentid, carrydate) = 1);
   
Amount := inputcc + Sk - Sc;
 RETURN Amount;
      
        EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        RETURN NULL;
    WHEN NO_DATA_FOUND THEN
        RETURN Amount;
    WHEN OTHERS THEN
        rsi_errors.err_msg := 'Get_Cc' || SQLERRM (SQLCODE);
        RETURN Amount;
end; 

--считаем остаток кредитных средств на счете за день carrydate
function Get_Cred ( acc varchar2, carrydate date, inputcred dacctrn_dbt.t_sum_natcur%TYPE ) RETURN dacctrn_dbt.t_sum_natcur%TYPE
AS
Sk dacctrn_dbt.t_sum_natcur%TYPE :=0;
Sc dacctrn_dbt.t_sum_natcur%TYPE :=0;
Amount dacctrn_dbt.t_sum_natcur%TYPE :=0;

begin

   
--Остаток кредитных средств по счету
--Приходные обороты с ссудного счета (т е полученные ссуды)
SELECT NVL(SUM (arh.t_sum_natcur),0)
  INTO sk
  FROM dacctrn_dbt arh
 WHERE arh.t_account_receiver = acc
   AND arh.t_chapter = 1
   AND arh.t_date_carry = carrydate
   AND REGEXP_LIKE (arh.t_account_payer, '^4[4-5][0-4]0[1-9]|^4560[1-9]');
   
--Нецелевые расходы за счет КРЕДИТНЫХ СРЕДСТВ + целевые расходы
SELECT NVL(SUM (t_sum_natcur),0)
   INTO sc 
  FROM 
  (select distinct arh.*
 from  dacctrn_dbt arh,
       dpmdocs_dbt doc
 WHERE arh.t_account_payer = acc
   AND arh.t_chapter = 1
   AND arh.t_date_carry = carrydate
   AND arh.t_acctrnid = doc.t_acctrnid
   and usr_FS.Get_Source (doc.t_paymentid, carrydate) != 1);
   
 Amount := inputcred + Sk - Sc;
 RETURN Amount;
      
        EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        RETURN NULL;
    WHEN NO_DATA_FOUND THEN
        RETURN Amount;
    WHEN OTHERS THEN
        rsi_errors.err_msg := 'Get_Cred' || SQLERRM (SQLCODE);
        RETURN Amount;
end; 

--Получить значение категории "Источник финансирования" за дату      
function Get_Source ( PaymentID in number, Dat in date) RETURN NUMBER
AS
 Sourc NUMBER := 0; 
begin

   

  select t_source into Sourc from USR_FINANC_SOURCE_DBT where t_paymentid = PaymentID 
  and t_systime = (select max(t_systime) from USR_financ_source_dbt 
                       where t_date <= Dat and t_Paymentid = PaymentID)
  and t_date <= Dat;
RETURN Sourc;

           EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        RETURN 0;
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        rsi_errors.err_msg := 'Get_Source' || SQLERRM (SQLCODE);
        RETURN 0;

end;

--Получить опера, сменившего значение категории "Источник финансирования" за дату      
function Get_Oper ( PaymentID in number, Dat in date) RETURN NUMBER
AS
 Oper NUMBER := 0; 
begin

   

  select t_oper into Oper from USR_FINANC_SOURCE_DBT where t_paymentid = PaymentID 
  and t_systime = (select max(t_systime) from USR_financ_source_dbt 
                       where t_date <= Dat and t_Paymentid = PaymentID)
  and t_date <= Dat;
RETURN Oper;

           EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        RETURN 0;
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        rsi_errors.err_msg := 'Get_Oper' || SQLERRM (SQLCODE);
        RETURN 0;

end;     


function Get_last_source( paymid in number, dat in date ) return number
AS 
v_sourc number(2) := 0;
begin
    
   

SELECT t_source
  INTO v_sourc
  FROM usr_financ_source_dbt
 WHERE t_paymentid = paymid
   AND t_date <= dat
   AND t_systime =
          (SELECT MAX (t_systime)
           FROM usr_financ_source_dbt
           WHERE t_paymentid = paymid
           AND t_date <= dat
           AND t_systime < (SELECT MAX (t_systime)
                             FROM usr_financ_source_dbt
                            WHERE t_paymentid = paymid AND t_date <= dat));
return v_sourc;

           EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        RETURN 0;
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        rsi_errors.err_msg := 'Get_last_source' || SQLERRM (SQLCODE);
        RETURN 0;
                            
end;

function HasLoanAcc(v_account in varchar2) return number
AS
a number:=0;
begin
    
    

SELECT COUNT (1)
  INTO a
  FROM (SELECT t_account
          FROM daccount_dbt
         WHERE t_client = (SELECT t_client
                             FROM daccount_dbt
                            WHERE t_account = v_account AND t_chapter = 1)
           AND REGEXP_LIKE (t_account, '^4[4-5][0-4]0[1-9]|^4560[1-9]')
           AND t_chapter = 1
           AND t_type_account NOT LIKE '%П%'
           AND t_type_account NOT LIKE '%U%'
           AND t_type_account NOT LIKE '%Н%'
           AND t_open_close = CHR (0)
        UNION
        SELECT acc.t_account
          FROM daccount_dbt acc,
               dacctrn_dbt arh,
               doprdocs_dbt docs,
               doproper_dbt opr
         WHERE acc.t_client = (SELECT t_client
                                 FROM daccount_dbt
                                WHERE t_account = v_account AND t_chapter = 1)
           AND acc.t_chapter = 1
           AND acc.t_code_currency != 0
           AND arh.t_chapter = 1
           AND docs.t_dockind = 8
           AND docs.t_id_operation = opr.t_id_operation
           AND opr.t_kind_operation = 24001
           AND arh.t_date_carry BETWEEN (pm_common.curdate - 10)--TO_DATE ('10.08.2010', 'dd.mm.yyyy')
                              AND pm_common.curdate--TO_DATE ('20.08.2010', 'dd.mm.yyyy')
           AND opr.t_dockind IN (202, 15)
           AND arh.t_account_payer = acc.t_account
           AND docs.t_acctrnid = arh.t_acctrnid
           AND get_category (501,
                             LTRIM (opr.t_documentid, '0'),
                             1000,
                             pm_common.curdate
                            ) = 2);
RETURN a;                            
end;

procedure Set_source(p_paymID in number, p_date in date, p_oper in number, p_source in number) 
IS
begin

   

  insert into usr_financ_source_dbt (T_PAYMENTID, T_SOURCE, T_OPER, T_DATE) values (p_paymID, p_source, p_oper, p_date);
end;

end; 
/
