--# description: this script create primary key for ipparms table
--# tables list: ipparms
--# author: ericv
--# date: 2020-03-25
--# Ticket # : 	
--# dependencies:
--# more comments:

create unique index pk_ipparms on ipparms(key_num,cmpy_code) ;
alter table "informix".ipparms add constraint primary key (key_num , cmpy_code) constraint "informix" .pk_ipparms  ;
