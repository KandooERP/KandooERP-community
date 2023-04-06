--# description: this script create primary key for puparms table
--# tables list: puparms
--# author: ericv
--# date: 2020-03-25
--# Ticket # : 	
--# dependencies:
--# more comments:

create unique index pk_puparms on puparms(key_code,cmpy_code) ;
alter table "informix".puparms add constraint primary key (key_code , cmpy_code) constraint "informix".pk_puparms  ;
