create or replace package "USR_VIEWS"
is

   type view_payment_rec is record (
      PAYMENTID        NUMBER(10)     ,
      DOCKIND          NUMBER(5)      ,
      AMOUNT           NUMBER(32,12)  ,
      PAYMENTNUMBER    VARCHAR2(25)   ,
      PAYERACCOUNT     VARCHAR2(35)   ,
      PAYERCODENAME    VARCHAR2(80)   ,
      PAYERCODE        VARCHAR2(35)   ,
      PAYERNAME        VARCHAR2(320)  ,
      RECEIVERACCOUNT  VARCHAR2(35)   ,
      RECEIVERCODENAME VARCHAR2(80)   ,
      RECEIVERCODE     VARCHAR2(35)   ,
      RECEIVERNAME     VARCHAR2(320)  ,
      DEPARTMENT       NUMBER(5)      ,
      VALUEDATE        DATE           ,
      GROUND           VARCHAR2(600)  ,
      NUMPACK          NUMBER(5)      ,
      USERFIELD1       VARCHAR2(4000) ,
      USERFIELD2       VARCHAR2(4000) ,
      USERFIELD3       VARCHAR2(4000) ,
      USERFIELD4       VARCHAR2(4000)
   );

   type view_payment_nt is table of view_payment_rec;
   
   function get_view_payment(p_SqlText varchar2) return sys_refcursor;

end;
/
CREATE OR REPLACE PACKAGE BODY "USR_VIEWS"
/*
Пакет для работы с представлениями в Интерфейсах
совместим с RS-Bank V.6.00.029
Автор Котов С.
*/

as

   function get_view_payment_old(p_SqlText varchar2) return view_payment_nt pipelined as
     TYPE t_view_payment_cur IS REF CURSOR;
     view_payment_cur t_view_payment_cur;
     payment_rec view_payment_rec;
   begin

     open view_payment_cur for 'SELECT * FROM VIEW_PAYMENT WHERE ' || p_SqlText;

     loop
        FETCH view_payment_cur INTO
              payment_rec.paymentid,
              payment_rec.dockind,
              payment_rec.amount,
              payment_rec.paymentnumber,
              payment_rec.payeraccount,
              payment_rec.payercodename,
              payment_rec.payercode,
              payment_rec.payername,
              payment_rec.receiveraccount,
              payment_rec.receivercodename,
              payment_rec.receivercode,
              payment_rec.receivername,
              payment_rec.department,
              payment_rec.valuedate,
              payment_rec.ground,
              payment_rec.numpack,
              payment_rec.userfield1,
              payment_rec.userfield2,
              payment_rec.userfield3,
              payment_rec.userfield4;
        EXIT WHEN view_payment_cur%NOTFOUND;
        pipe row(payment_rec);
     end loop;

     close view_payment_cur;

   end;

   function get_view_payment(p_SqlText varchar2) return sys_refcursor as
     view_payment_cur         sys_refcursor;
   begin

     open view_payment_cur for 'SELECT * FROM VIEW_PAYMENT WHERE ' || p_SqlText;

     return view_payment_cur;

   end;
end;
/
