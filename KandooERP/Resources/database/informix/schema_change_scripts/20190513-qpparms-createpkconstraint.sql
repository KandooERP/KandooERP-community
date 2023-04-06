--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: qpparms
--# author: ericv
--# date: 2019-05-13
--# Ticket # :  4
--# more comments:
create unique index u_qpparms on qpparms(key_num,cmpy_code);
alter table qpparms add constraint primary key (key_num,cmpy_code) constraint pk_qpparms;
