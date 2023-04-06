--# description: this script create primary key for mnparms table
--# tables list: mnparms
--# author: ericv
--# date: 2020-03-25
--# Ticket # : 	
--# dependencies:
--# more comments:

drop index if exists i0_parameters ;
create unique index pk_mnparms on mnparms(param_code,cmpy_code) ;
alter table "informix".mnparms add constraint primary key (param_code , cmpy_code) constraint "informix".pk_mnparms  ;
