--# description: this script create primary key for stnd_parms table
--# tables list: stnd_parms
--# author: ericv
--# date: 2020-03-25
--# Ticket # : 	
--# dependencies:
--# more comments:

create unique index pk_stnd_parms on stnd_parms(cmpy_code) ;
alter table "informix".stnd_parms add constraint primary key (cmpy_code) constraint "informix".pk_stnd_parms  ;
