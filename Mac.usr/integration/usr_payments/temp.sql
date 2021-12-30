declare
   type stats_rec is record (statid   number, statvalue number);

   type nt_stats is table of stats_rec;

   type oprstat_rec is record (opr_id number, carry_step_id number, statvalues_2carry nt_stats, statvalues_2deff
      nt_stats);

   type oprstat_nt is table of oprstat_rec;

   nt_oprstat   oprstat_nt := oprstat_nt ();

   cursor opr_values(operblockid number, kind_operation number, is2carry number
      /*1 = для выполнение шага зачисления 0 = для отложенных*/)
   is
      select t_statuskindid, t_numvalue from doprinist_dbt where t_kind_operation = kind_operation
         union
      select t_statuskindid, t_numvalue from doprcblck_dbt where t_operblockid = operblockid and t_condition = 0 and
      is2carry = 1;


      procedure modify_oprstatval(oprid number, statid   number, statvalue number, is2deff boolean)
   is
   lv_found boolean:=false;
   begin

   for i in nt_oprstat.first..nt_oprstat.last loop
      if nt_oprstat(i).opr_id = oprid then
         for j in nt_oprstat(i).statvalues_2carry.first..nt_oprstat(i).statvalues_2carry.last loop

            if nt_oprstat(i).statvalues_2carry(j).statid = statid then
               nt_oprstat(i).statvalues_2carry(j).statvalue := statvalue;
               lv_found :=true;
               exit;
            end if;
         end loop;

         if not lv_found then
         nt_oprstat(i).statvalues_2carry.extend(1);
         nt_oprstat(i).statvalues_2carry(nt_oprstat(i).statvalues_2carry.count).statid := statid;
         nt_oprstat(i).statvalues_2carry(nt_oprstat(i).statvalues_2carry.count).statvalue := statvalue;
         end if;

         lv_found := false;

         for j in nt_oprstat(i).statvalues_2deff.first..nt_oprstat(i).statvalues_2deff.last loop

            if nt_oprstat(i).statvalues_2deff(j).statid = statid then
               nt_oprstat(i).statvalues_2deff(j).statvalue := statvalue;
               lv_found :=true;
               exit;
            end if;
         end loop;

         if not lv_found then
         nt_oprstat(i).statvalues_2deff.extend(1);
         nt_oprstat(i).statvalues_2deff(nt_oprstat(i).statvalues_2deff.count).statid := statid;
         nt_oprstat(i).statvalues_2deff(nt_oprstat(i).statvalues_2deff.count).statvalue := statvalue;
         end if;


      end if;

   end loop;

   end;
begin



   for i in (select rownum num, o.t_kind_operation, opb.t_operblockid
  from   doproblck_dbt opb, doprblock_dbt bl, doprkoper_dbt o
 where       opb.t_kind_operation = o.t_kind_operation
         and opb.t_blockid = bl.t_blockid
         and upper (bl.t_name) like 'ЗАЧИСЛЕНИЕ'
         and o.t_dockind = 29
         and o.t_notinuse <> chr (88)
         and o.t_kind_operation > 0) loop
       nt_oprstat.extend (1);
       nt_oprstat(i.num).opr_id := i.t_kind_operation;

       open opr_values (i.t_operblockid, i.t_kind_operation, 0);
       fetch opr_values bulk collect into  nt_oprstat(i.num).statvalues_2deff;

       close opr_values;

       open opr_values (i.t_operblockid, i.t_kind_operation, 1);
       fetch opr_values bulk collect into  nt_oprstat(i.num).statvalues_2carry;

       close opr_values;


       end loop;


       for i in nt_oprstat.first..nt_oprstat.last loop

       for j in nt_oprstat(i).statvalues_2carry.first..nt_oprstat(i).statvalues_2carry.last loop
       dbms_output.put_line ( 'statvalues_2carry('||nt_oprstat(i).opr_id||') stat='||
                                       nt_oprstat(i).statvalues_2carry(j).statid||' val='||
                                       nt_oprstat(i).statvalues_2carry(j).statvalue );

       end loop;

       dbms_output.put_line(' ');
       for j in nt_oprstat(i).statvalues_2deff.first..nt_oprstat(i).statvalues_2deff.last loop
       dbms_output.put_line ( 'statvalues_2carry('||nt_oprstat(i).opr_id||') stat='||
                                       nt_oprstat(i).statvalues_2deff(j).statid||' val='||
                                       nt_oprstat(i).statvalues_2deff(j).statvalue );

       end loop;
       dbms_output.put_line(' ');
       end loop;

end;