--# description: this script creates primary key for kandoouser table
--# tables list: kandoouser
--# author: ericv
--# date: 2020-01-20
--# Ticket # : 	
--# more comments:
create unique index if not exists pk_kandoouser 
on kandoouser (sign_on_code,cmpy_code) using btree ;
alter table kandoouser drop constraint pk_kandoouser  ;
alter table kandoouser add constraint primary key (sign_on_code,cmpy_code) constraint pk_kandoouser  ;
