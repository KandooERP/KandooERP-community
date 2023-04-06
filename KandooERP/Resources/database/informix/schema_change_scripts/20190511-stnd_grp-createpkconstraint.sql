--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: stnd_grp
--# author: ericv
--# date: 2019-05-11
--# Ticket # :  4
--# more comments:
create unique index u_stnd_grp on stnd_grp(group_code,cmpy_code);
alter table stnd_grp add constraint primary key (group_code,cmpy_code) constraint pk_stnd_grp;
