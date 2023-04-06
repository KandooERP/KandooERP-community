--# description: this script create indexes and constraints on account
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: account
--# author: eric vercelletto
--# date: 2019-09-29
--# Ticket # :
--# more comments: 
create index d_account_01 on account(acct_code,cmpy_code) ;
alter table account add constraint foreign key (acct_code,cmpy_code) references coa(acct_code,cmpy_code) constraint fk_account_coa;
