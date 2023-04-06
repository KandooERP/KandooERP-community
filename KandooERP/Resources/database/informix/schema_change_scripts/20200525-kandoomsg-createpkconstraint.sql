--# description: this script create primary key for kandoomsg table
--# tables list: kandoomsg
--# author: ericv
--# date: 2020-05-25
--# Ticket # : 	
--# dependencies:
--# more comments:

create unique index u_kandoomsg on kandoomsg( msg_num,source_ind,language_code);
alter table kandoomsg add constraint primary key (msg_num,source_ind,language_code) constraint "informix".pk_kandoomsg  ;
