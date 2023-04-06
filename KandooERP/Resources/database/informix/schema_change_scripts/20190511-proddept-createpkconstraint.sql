--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: proddept
--# author: ericv
--# date: 2019-05-11
--# Ticket # :  4
--# more comments:
create unique index u_proddept on proddept(dept_code,dept_ind,cmpy_code);
alter table proddept add constraint primary key (dept_code,dept_ind,cmpy_code) constraint pk_proddept;
