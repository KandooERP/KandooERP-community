--# description: this script foreign keys on glparms to coa
--# dependencies: 
--# tables list:  glparms,coa
--# author: Eric Vercelletto
--# date: 2021-22-28
--# Ticket: 
--# more comments:

alter table glparms modify (unexch_acct_code nchar(18));
alter table glparms add constraint foreign key (exch_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_glparms_coa_exch;
alter table glparms add constraint foreign key (unexch_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_glparms_coa_unexch;
alter table glparms add constraint foreign key (susp_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_glparms_coa_susp;
alter table glparms add constraint foreign key (clear_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_glparms_coa_clear;