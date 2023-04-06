--# description: this script creates a foreign key for prodadjtype to account
--# tables list: prodadjtype
--# author: ericv
--# date: 2020-05-30
--# Ticket # : 	
--# dependencies:
--# more comments:
set constraints all deferred;
drop index if exists d01_prodadjtype ;
alter table prodadjtype modify (adj_acct_code NCHAR(18));
create index if not exists d01_prodadjtype on prodadjtype (adj_acct_code,cmpy_code);
alter table prodadjtype add constraint foreign key(adj_acct_code,cmpy_code) references coa(acct_code,cmpy_code) constraint fk_prodadjtype_coa;