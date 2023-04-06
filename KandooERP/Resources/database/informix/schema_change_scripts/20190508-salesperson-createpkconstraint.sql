--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: salesperson
--# author: ericv
--# date: 2019-05-08
--# Ticket # :
--# more comments:
create unique index u_salesperson on salesperson(sale_code,cmpy_code);
alter table salesperson add constraint primary key (sale_code,cmpy_code) constraint pk_salesperson;
