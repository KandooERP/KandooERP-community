--# description: this script create primary key for kandooreport table
--# tables list: kandooreport
--# author: ericv
--# date: 2020-04-28
--# Ticket # : 	
--# dependencies:
--# more comments:

SET CONSTRAINTS ALL DEFERRED;
UPDATE kandooreport SET language_code = "ENG" WHERE report_code = "E99";
create unique index pk_kandooreport on kandooreport(report_code,language_code) ;
alter table "informix".kandooreport add constraint primary key (report_code,language_code) constraint "informix".pk_kandooreport  ;
SET CONSTRAINTS ALL IMMEDIATE;