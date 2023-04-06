--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: accountcur
--# author: ericv
--# date: 2019-05-13
--# Ticket # :  4
--# more comments:
drop index if exists acctcurr_key ;
create unique index u_accountcur on accountcur(acct_code,year_num,currency_code,cmpy_code);
alter table accountcur add constraint primary key (acct_code,year_num,currency_code,cmpy_code) constraint pk_accountcur;
