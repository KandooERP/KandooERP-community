--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: fundsapproved
--# author: ericv
--# date: 2019-05-13
--# Ticket # :  4
--# more comments:
create unique index u_fundsapproved on fundsapproved(acct_code,fund_type_ind,cmpy_code);
-- alter table fundsapproved add constraint primary key (acct_code,fund_type_ind,cmpy_code) constraint pk_fundsapproved;  fund_type has null values
