CREATE OR REPLACE FUNCTION public.bacula_status(varchar
	)
    RETURNS TABLE(name character varying, itembf numeric, itembi numeric, itembd numeric, itemdf numeric, itemdi numeric, itemdd numeric, itemff numeric, itemfi numeric, itemfd numeric, itemle integer, itemst char ) 
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    ROWS 1000
AS $BODY$

  declare
    job record;
    item integer;
    itemle integer;
    itembf numeric;
    itembi numeric;
    itembd numeric;
    itemdf numeric;
    itemdi numeric;
    itemdd numeric;
    itemff numeric;
    itemfi numeric;
    itemfd numeric;
	itemst char;
    ht ALIAS FOR $1 ;
    hid integer;
	sb varchar = 'Bacula%Status';
	query text;
  
  begin
    select h.hostid into hid from hosts h where h.name like ht;
	query := 
	   'select it.name from items it where it.hostid = '
		||quote_literal(hid)
		||' and it.templateid is null and it.name like '
		||quote_literal(sb)
		||';';

	for job in execute query loop
      job.name = substring(job.name from 'Bacula Job (.*) Status');
      execute 'select itemid from items where name like ''%' ||job.name|| ' Last Execution'';' into item;
      execute 'select value from history_uint where itemid = ' ||item|| 'order by clock desc limit 1;' into itemle;
      execute 'select itemid from items where name like ''%' ||job.name|| ' Bytes FULL'';' into item;
      execute 'select value from history_uint where itemid = ' ||item|| 'order by clock desc limit 1;' into itembf;
      execute 'select itemid from items where name like ''%' ||job.name|| ' Bytes INCREMENTAL'';' into item;
      execute 'select value from history_uint where itemid = ' ||item|| 'order by clock desc limit 1;' into itembi;
      execute 'select itemid from items where name like ''%' ||job.name|| ' Bytes DIFFERENTIAL'';' into item;
      execute 'select value from history_uint where itemid = ' ||item|| 'order by clock desc limit 1;' into itembd;
      execute 'select itemid from items where name like ''%' ||job.name|| ' Duration FULL'';' into item;
      execute 'select value from history_uint where itemid = ' ||item|| 'order by clock desc limit 1;' into itemdf;
      execute 'select itemid from items where name like ''%' ||job.name|| ' Duration INCREMENTAL'';' into item;
      execute 'select value from history_uint where itemid = ' ||item|| 'order by clock desc limit 1;' into itemdi;
      execute 'select itemid from items where name like ''%' ||job.name|| ' Duration DIFFERENTIAL'';' into item;
      execute 'select value from history_uint where itemid = ' ||item|| 'order by clock desc limit 1;' into itemdd;
      execute 'select itemid from items where name like ''%' ||job.name|| ' Files FULL'';' into item;
      execute 'select value from history_uint where itemid = ' ||item|| 'order by clock desc limit 1;' into itemff;
      execute 'select itemid from items where name like ''%' ||job.name|| ' Files INCREMENTAL'';' into item;
      execute 'select value from history_uint where itemid = ' ||item|| 'order by clock desc limit 1;' into itemfi;
      execute 'select itemid from items where name like ''%' ||job.name|| ' Files DIFFERENTIAL'';' into item;
      execute 'select value from history_uint where itemid = ' ||item|| 'order by clock desc limit 1;' into itemfd;
      execute 'select itemid from items where name like ''%' ||job.name|| ' Status'';' into item;
      execute 'select value from history_str where itemid = ' ||item|| 'order by clock desc limit 1;' into itemst;



      return query select job.name as "Job",
	                      itembf as "Bytes F", 
						  itembi as "Bytes I", 
						  itembd as "Bytes D",
	                      itemdf as "Duration F", 
						  itemdi as "Duration I", 
						  itemdd as "Duration D",
	                      itemff as "Files F", 
						  itemfi as "Files I", 
						  itemfd as "Files D",
						  itemle as "LastExecution",
						  itemst as "Status";
    end loop;
    return;
  end;
  

$BODY$;