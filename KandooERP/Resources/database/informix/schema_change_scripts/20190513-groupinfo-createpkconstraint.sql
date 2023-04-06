--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: groupinfo
--# author: ericv
--# date: 2019-05-13
--# Ticket # :  4
--# more comments:
create unique index u_groupinfo on groupinfo(group_code,cmpy_code);
alter table groupinfo add constraint primary key (group_code,cmpy_code) constraint pk_groupinfo;
