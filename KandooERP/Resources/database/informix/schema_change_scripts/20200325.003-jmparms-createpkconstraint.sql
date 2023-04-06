--# description: this script create primary key for jmparms table
--# tables list: jmparms
--# author: ericv
--# date: 2020-03-25
--# Ticket # : 	
--# dependencies:
--# more comments:

create unique index pk_jmparms on jmparms(key_code,cmpy_code) ;
alter table "informix".jmparms add constraint primary key (key_code , cmpy_code) constraint "informix".pk_jmparms  ;
