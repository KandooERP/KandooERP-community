--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: statparms
--# author: ericv
--# date: 2019-05-08
--# Ticket # :
--# more comments:
create unique index u_statparms on statparms(parm_code,cmpy_code);
alter table statparms add constraint primary key (parm_code,cmpy_code) constraint pk_statparms;

