--# description: this script create primary key for payparms table
--# tables list: payparms
--# author: ericv
--# date: 2020-03-25
--# Ticket # : 	
--# dependencies:
--# more comments:

create unique index pk_payparms on payparms(cmpy_code) ;
alter table "informix".payparms add constraint primary key (cmpy_code) constraint "informix".pk_payparms  ;
