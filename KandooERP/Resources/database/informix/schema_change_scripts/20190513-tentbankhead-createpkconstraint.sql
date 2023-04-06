--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: tentbankhead
--# author: ericv
--# date: 2019-05-13
--# Ticket # :  4
--# more comments:
drop index if exists tentbankh_key;
create unique index u_tentbankhead on tentbankhead(bank_code,bank_dep_num,cmpy_code);
alter table tentbankhead add constraint primary key (bank_code,bank_dep_num,cmpy_code) constraint pk_tentbankhead;
