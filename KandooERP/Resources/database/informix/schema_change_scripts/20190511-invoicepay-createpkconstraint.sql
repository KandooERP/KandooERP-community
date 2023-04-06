--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: invoicepay
--# author: ericv
--# date: 2019-05-11
--# Ticket # :  4
--# more comments:
create unique index u_invoicepay on invoicepay(inv_num,cust_code,pay_date,cmpy_code);
alter table invoicepay add constraint primary key (inv_num,cust_code,pay_date,cmpy_code) constraint pk_invoicepay;
