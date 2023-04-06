--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: arparms
--# author: ericv
--# date: 2019-05-08
--# Ticket # :  4
--# more comments:
create unique index u_arparms on arparms(parm_code,cmpy_code);
alter table arparms add constraint primary key (parm_code,cmpy_code) constraint pk_arparms;
