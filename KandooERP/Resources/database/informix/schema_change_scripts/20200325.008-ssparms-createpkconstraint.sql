--# description: this script create primary key for ssparms table
--# tables list: ssparms
--# author: ericv
--# date: 2020-03-25
--# Ticket # : 	
--# dependencies:
--# more comments:

create unique index pk_ssparms on ssparms(cmpy_code) ;
alter table "informix".ssparms add constraint primary key (cmpy_code) constraint "informix".pk_ssparms  ;
