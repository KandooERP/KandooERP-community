--# description: this script create a PK constraints on accountcur
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: accountcur
--# author: eric vercelletto
--# date: 2019-10-01
--# Ticket # :
--# more comments: 
--alter table accountcur add constraint primary key (acct_code,year_num,cmpy_code) constraint pk_accountcur;
