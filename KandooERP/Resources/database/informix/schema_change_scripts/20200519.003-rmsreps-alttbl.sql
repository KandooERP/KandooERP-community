--# description: this script create primary key for rmsreps table
--# tables list: rmsreps
--# author: ericv
--# date: 2020-05-19
--# Ticket # : 	KD-2034
--# dependencies:
--# more comments:

create unique index pk_rmsreps on rmsreps(report_code,cmpy_code) ;
alter table rmsreps add constraint primary key (report_code,cmpy_code) constraint "informix".pk_rmsreps  ;
