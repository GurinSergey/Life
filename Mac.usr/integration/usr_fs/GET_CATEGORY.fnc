CREATE OR REPLACE FUNCTION GET_CATEGORY ( v_OBJECTTYPE in number, v_ObjectID in number, v_GroupID in NUMBER, v_Date in date) RETURN NUMBER
AS
 p_Category NUMBER := 0; 
begin

SELECT t_attrid
  INTO p_category
  FROM dobjatcor_dbt
 WHERE t_objecttype = v_objecttype
   AND t_object = lpad(v_objectid, 10, 0)
   AND t_groupid = v_groupid
   AND (TO_DATE (   TO_CHAR (t_sysdate, 'dd.mm.yyyy')
                                || TO_CHAR (t_systime, 'ss:mi:hh24'),
                                'dd.mm.yyyy ss:mi:hh24'
                               )
                      )  =
          (SELECT MAX (TO_DATE (   TO_CHAR (t_sysdate, 'dd.mm.yyyy')
                                || TO_CHAR (t_systime, 'ss:mi:hh24'),
                                'dd.mm.yyyy ss:mi:hh24'
                               )
                      ) 
             FROM dobjatcor_dbt
            WHERE t_objecttype = v_objecttype
              AND t_object = lpad(v_objectid, 10, 0)
              AND t_groupid = v_groupid
              AND t_validfromdate <= v_date
              AND t_validtodate >= v_date
              and t_general = 'X')
   AND t_validfromdate <= v_date
   AND t_validtodate >= v_date
   and t_general = 'X';
RETURN p_Category;

           EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        RETURN 0;
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        rsi_errors.err_msg := 'Get_Category'|| SQLERRM (SQLCODE);
        RETURN 0;

end; 
 
/
