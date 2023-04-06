--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: mfgdept
--# author: ericv
--# date: 2019-05-13
--# Ticket # :  4
--# more comments:
create unique index u_mfgdept on mfgdept(dept_code,cmpy_code);
alter table mfgdept add constraint primary key (dept_code,cmpy_code) constraint pk_mfgdept;

