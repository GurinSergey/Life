CREATE OR REPLACE PACKAGE USR_INTERFACE_LOGGING
IS
   PROCEDURE save_arguments (p_package        VARCHAR2 DEFAULT NULL ,
                             p_object_name    VARCHAR2 DEFAULT NULL ,
                             p_values         sys.ku$_vcnt);

   FUNCTION get_arguments (p_xmlarguments XMLTYPE)
      RETURN CLOB;

   FUNCTION get_arguments (p_id PLS_INTEGER)
      RETURN CLOB;

   FUNCTION get_value (p_xmlarguments XMLTYPE, p_argument VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION get_value (p_id PLS_INTEGER, p_argument VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION existsargument (p_xmlarguments XMLTYPE, p_argument VARCHAR2)
      RETURN BOOLEAN;

   FUNCTION existsargument (p_id PLS_INTEGER, p_argument VARCHAR2)
      RETURN BOOLEAN;
END; 
/
CREATE OR REPLACE PACKAGE BODY USR_INTERFACE_LOGGING
IS
   -- убираем недопустимые символы
   FUNCTION erase_chr (p_value VARCHAR2)
      RETURN VARCHAR2
   AS
      v_str   VARCHAR2 (4000);
   BEGIN
      IF p_value IS NULL
      THEN
         RETURN 'NULL';
      END IF;

      v_str := p_value;
      v_str := REPLACE (v_str, CHR (0), ' ');
      v_str := REPLACE (v_str, CHR (1), ' ');
      v_str := REPLACE (v_str, CHR (2), ' ');
      v_str := REPLACE (v_str, CHR (3), ' ');
      v_str := REPLACE (v_str, CHR (4), ' ');
      v_str := REPLACE (v_str, CHR (5), ' ');
      v_str := REPLACE (v_str, CHR (6), ' ');
      v_str := REPLACE (v_str, CHR (7), ' ');
      v_str := REPLACE (v_str, CHR (8), ' ');
      v_str := REPLACE (v_str, CHR (9), ' ');
      v_str := REPLACE (v_str, CHR (10), ' ');
      v_str := REPLACE (v_str, CHR (11), ' ');
      v_str := REPLACE (v_str, CHR (12), ' ');
      v_str := REPLACE (v_str, CHR (13), ' ');
      v_str := REPLACE (v_str, CHR (14), ' ');
      v_str := REPLACE (v_str, CHR (15), ' ');
      v_str := REPLACE (v_str, CHR (16), ' ');
      v_str := REPLACE (v_str, CHR (17), ' ');
      v_str := REPLACE (v_str, CHR (18), ' ');
      v_str := REPLACE (v_str, CHR (19), ' ');
      v_str := REPLACE (v_str, CHR (20), ' ');
      v_str := REPLACE (v_str, CHR (21), ' ');
      v_str := REPLACE (v_str, CHR (22), ' ');
      v_str := REPLACE (v_str, CHR (23), ' ');
      v_str := REPLACE (v_str, CHR (24), ' ');
      v_str := REPLACE (v_str, CHR (25), ' ');
      v_str := REPLACE (v_str, CHR (26), ' ');
      v_str := REPLACE (v_str, CHR (27), ' ');
      v_str := REPLACE (v_str, CHR (28), ' ');
      v_str := REPLACE (v_str, CHR (29), ' ');
      v_str := REPLACE (v_str, CHR (30), ' ');
      v_str := REPLACE (v_str, CHR (31), ' ');
      RETURN v_str;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN ('EraseChr::SQLError: ' || SQLERRM);
   END;

   PROCEDURE save_arguments (p_package        VARCHAR2 DEFAULT NULL ,
                             p_object_name    VARCHAR2 DEFAULT NULL ,
                             p_values         sys.ku$_vcnt)
   AS
      PRAGMA AUTONOMOUS_TRANSACTION;
      v_owner               VARCHAR2 (100);
      v_name                VARCHAR2 (100);
      v_object_name         VARCHAR2 (100);
      v_package             VARCHAR2 (100);
      v_lineno              INT;
      v_caller_t            VARCHAR2 (100);
      v_xmltext             XMLTYPE;
      XML_document          DBMS_XMLDOM.DOMDocument;
      XML_rootElement       DBMS_XMLDOM.DOMElement;
      XML_argumentElement   DBMS_XMLDOM.DOMElement;
      XML_node              DBMS_XMLDOM.DOMNode;
      XML_nodetext          DBMS_XMLDOM.DOMText;
   BEGIN
      OWA_UTIL.who_called_me (owner      => v_owner,
                              name       => v_name,
                              lineno     => v_lineno,
                              caller_t   => v_caller_t);
      v_object_name := NVL (p_object_name, v_name);
      XML_document :=
         DBMS_XMLDOM.createDocument ('http://www.w3.org/2001/XMLSchema',
                                     NULL,
                                     NULL);
      DBMS_XMLDOM.setVersion (XML_document, '1.0');
      -- DBMS_XMLDOM.setcharset (XML_document, 'cp866'); -- не работает :(
      XML_rootElement :=
         DBMS_XMLDOM.createElement (XML_document, v_object_name);
      XML_node :=
         DBMS_XMLDOM.appendChild (DBMS_XMLDOM.makeNode (XML_document),
                                  DBMS_XMLDOM.makeNode (XML_rootElement));

      FOR params
      IN (  SELECT   a.POSITION,
                     a.ARGUMENT_NAME,
                     a.PLS_TYPE,
                     a.IN_OUT
              FROM   all_arguments a
             WHERE       a.OWNER = v_owner
                     AND a.OBJECT_NAME = v_object_name
                     AND a.POSITION > 0
                     AND (1 = CASE
                                 WHEN p_package IS NULL THEN 1
                                 WHEN a.package_name = p_package THEN 1
                                 ELSE 0
                              END)
          ORDER BY   a.POSITION)
      LOOP
         XML_argumentElement :=
            DBMS_XMLDOM.createElement (XML_document, 'ARGUMENT');

         XML_node :=
            DBMS_XMLDOM.appendChild (
               DBMS_XMLDOM.makeNode (XML_rootElement),
               DBMS_XMLDOM.makeNode (XML_argumentElement)
            );

         DBMS_XMLDOM.setAttribute (XML_argumentElement,
                                   'name',
                                   params.argument_name);
         DBMS_XMLDOM.setAttribute (XML_argumentElement,
                                   'pls_type',
                                   params.pls_type);
         DBMS_XMLDOM.setAttribute (XML_argumentElement,
                                   'in_out',
                                   params.in_out);
         DBMS_XMLDOM.setAttribute (XML_argumentElement,
                                   'value',
                                   erase_chr (p_values (params.position)));
      END LOOP;

      v_xmltext := DBMS_XMLDOM.getxmltype (XML_document);
      DBMS_XMLDOM.freeDocument (XML_document);

      INSERT INTO USR_ARGUMENTS_LOG
        VALUES   (0,
                  SYSDATE,
                  v_object_name,
                  v_xmltext,
                  v_caller_t || ' ' || v_name);

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
   END;

   -- получить параметры и значения
   FUNCTION get_arguments (p_xmlarguments XMLTYPE)
      RETURN CLOB
   IS
      v_xmltext            XMLTYPE;
      v_clob_text          CLOB;
      v_eol                VARCHAR2 (2) := CONCAT (CHR (13), CHR (10)); -- CR LF
      v_quote              VARCHAR2 (2);
      XML_document         DBMS_XMLDOM.domdocument;
      XML_arguments_list   DBMS_XMLDOM.domnodelist;
      XML_element          DBMS_XMLDOM.domelement;
   BEGIN
      XML_document := DBMS_XMLDOM.newDOMDocument (p_xmlarguments);
      XML_arguments_list :=
         DBMS_XMLDOM.getelementsbytagname (XML_document, 'ARGUMENT');

      FOR i IN 0 .. DBMS_XMLDOM.getlength (XML_arguments_list) - 1
      LOOP
         XML_element :=
            DBMS_XMLDOM.makeelement (
               DBMS_XMLDOM.item (XML_arguments_list, i)
            );

         -- заключаем в ковычки строковые значения
         IF DBMS_XMLDOM.getattribute (XML_element, 'pls_type') = 'VARCHAR2'
            AND DBMS_XMLDOM.getattribute (XML_element, 'value') != 'NULL'
         THEN
            v_quote := '''';
         ELSE
            v_quote := '';
         END IF;

         -- формируем строку вида: [название _параметра] => [значение],
         v_clob_text :=
               v_clob_text
            || DBMS_XMLDOM.getattribute (XML_element, 'name')
            || ' => '
            || v_quote
            || DBMS_XMLDOM.getattribute (XML_element, 'value')
            || v_quote;

         -- в последней строке запятую не ставим
         IF i != (DBMS_XMLDOM.getlength (XML_arguments_list) - 1)
         THEN
            v_clob_text := v_clob_text || ',' || v_eol;
         END IF;
      -- вставляем символ переноса строки
      --v_clob_text := v_clob_text || v_eol;
      END LOOP;

      DBMS_XMLDOM.freeDocument (XML_document);
      RETURN v_clob_text;
   END;

   -- перегружаем get_arguments
   FUNCTION get_arguments (p_id PLS_INTEGER)
      RETURN CLOB
   IS
      v_xmltext   XMLTYPE;
   BEGIN
      SELECT   t_xmlarguments
        INTO   v_xmltext
        FROM   USR_ARGUMENTS_LOG
       WHERE   t_id = p_id;

      RETURN get_arguments (v_xmltext);
   END;

   -- получить значение параметра
   FUNCTION get_value (p_xmlarguments XMLTYPE, p_argument VARCHAR2)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN p_xmlarguments.EXTRACT (
                '//ARGUMENT[@name="' || UPPER (p_argument) || '"]/@value'
             ).getstringval ();
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END;

   -- тоже перегружаем
   FUNCTION get_value (p_id PLS_INTEGER, p_argument VARCHAR2)
      RETURN VARCHAR2
   IS
      v_xmltext   XMLTYPE;
   BEGIN
      SELECT   t_xmlarguments
        INTO   v_xmltext
        FROM   USR_ARGUMENTS_LOG
       WHERE   t_id = p_id;

      RETURN get_value (v_xmltext, p_argument);
   END;

   -- на всякий случай, функция, проверяющая наличие параметра
   FUNCTION existsargument (p_xmlarguments XMLTYPE, p_argument VARCHAR2)
      RETURN BOOLEAN
   IS
   BEGIN
      IF p_xmlarguments.EXISTSNODE (
            '//ARGUMENT[@name="' || UPPER (p_argument) || '"]'
         ) > 0
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END;

   FUNCTION existsargument (p_id PLS_INTEGER, p_argument VARCHAR2)
      RETURN BOOLEAN
   IS
      v_xmltext   XMLTYPE;
   BEGIN
      SELECT   t_xmlarguments
        INTO   v_xmltext
        FROM   USR_ARGUMENTS_LOG
       WHERE   t_id = p_id;

      RETURN existsargument (v_xmltext, p_argument);
   END;
END; 
/
