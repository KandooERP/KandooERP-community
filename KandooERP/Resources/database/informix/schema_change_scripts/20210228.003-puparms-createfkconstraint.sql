--# description: this script foreign keys on puparms to coa
--# dependencies: 
--# tables list:  puparms,coa
--# author: Eric Vercelletto
--# date: 2021-22-28
--# Ticket: KD-2686
--# more comments:

alter table puparms add constraint foreign key (commit_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_puparms_coa_commit;
alter table puparms add constraint foreign key (goodsin_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_puparms_coa_goodsin;
alter table puparms add constraint foreign key (accrued_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_puparms_coa_accrued;
alter table puparms add constraint foreign key (clear_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_puparms_coa_clear;