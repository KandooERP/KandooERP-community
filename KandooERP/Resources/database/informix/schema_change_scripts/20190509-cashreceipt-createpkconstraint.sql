--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: cashreceipt
--# author: ericv
--# date: 2019-05-08
--# Ticket # :  4
--# more comments:
create unique index u_cashreceipt on cashreceipt(cash_num,cmpy_code);
alter table cashreceipt add constraint primary key (cash_num,cmpy_code) constraint pk_cashreceipt;
