--# description: this script create primary key for opparms table
--# tables list: opparms
--# author: ericv
--# date: 2020-03-25
--# Ticket # : 	
--# dependencies:
--# more comments:

create unique index pk_opparms on opparms(key_num,cmpy_code) ;
alter table "informix".opparms add constraint primary key (key_num , cmpy_code) constraint "informix".pk_opparms  ;
