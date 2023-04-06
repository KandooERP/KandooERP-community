--# description: this script create indexes and constraints on accountcur
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: accountcur
--# author: eric vercelletto
--# date: 2019-09-29
--# Ticket # :
--# more comments: 
create index d_accountcur_01 on accountcur(acct_code,cmpy_code) ;
alter table accountcur add constraint foreign key (acct_code,cmpy_code) references coa(acct_code,cmpy_code) constraint fk_accountcur_coa;
