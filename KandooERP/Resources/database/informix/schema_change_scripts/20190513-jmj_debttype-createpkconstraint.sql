--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: jmj_debttype
--# author: ericv
--# date: 2019-05-13
--# Ticket # :  4
--# more comments:
create unique index u_jmj_debttype on jmj_debttype(debt_type_code,cmpy_code);
alter table jmj_debttype add constraint primary key (debt_type_code,cmpy_code) constraint pk_jmj_debttype;
