--# description: this script creates a new table fiscalyear, master of period 
--# dependencies: 
--# tables list: fiscalyear,period
--# author: eric
--# date: 2020-11-20
--# Ticket # : KD-2466
--# 

create table if not exists fiscalyear (cmpy_code NCHAR(2),
year_num SMALLINT ,			
start_date_fiscalyear DATE,	
end_date_fiscalyear DATE	
);
alter table fiscalyear add constraint check (year_num > 1900 and year_num < 2200 ) constraint ck_fiscalyear_yearnum ;
alter table fiscalyear add constraint check (start_date_fiscalyear >= "01/01/1900" and end_date_fiscalyear <= "31/12/2199") constraint ck_fiscalyear_dates1;
alter table fiscalyear add constraint check ( start_date_fiscalyear <  end_date_fiscalyear) constraint ck_fiscalyear_dates2;
create unique index u_fiscalyear on fiscalyear(year_num,cmpy_code);
alter table fiscalyear add constraint primary key(year_num,cmpy_code);