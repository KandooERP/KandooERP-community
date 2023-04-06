--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: inparms
--# author: ericv
--# date: 2019-05-11
--# Ticket # :  4
--# more comments:
create unique index u_inparms on inparms(parm_code,cmpy_code);
alter table inparms add constraint primary key (parm_code,cmpy_code) constraint pk_inparms;
