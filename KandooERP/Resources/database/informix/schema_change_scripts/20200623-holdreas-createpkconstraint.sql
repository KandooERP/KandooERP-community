--# description: this script creates primary key for holdreas table
--# tables list: holdreas
--# author: albo
--# date: 2020-06-23
--# Ticket # KD-2151 
--# Comments: delete from holdreas where hold_code is null; 	

create unique index if not exists u_holdreas on holdreas (hold_code,cmpy_code);
alter table holdreas add constraint primary key (hold_code,cmpy_code) constraint pk_holdreas;	
