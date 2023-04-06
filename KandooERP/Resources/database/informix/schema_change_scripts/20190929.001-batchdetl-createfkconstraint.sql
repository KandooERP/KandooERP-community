--# description: this script create indexes and constraints on batchdetl
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: batchdetl
--# author: eric vercelletto
--# date: 2019-09-29
--# Ticket # :
--# more comments: 1) handle foreign key to coa  2) handle foreign key to batchhead
-- select acct_code||cmpy_code from batchdetl where acct_code||cmpy_code not in ( select acct_code||cmpy_code from coa ) 
drop index if exists "informix".batchdetl2_key;
create index "informix".batchdetl2_key on "informix".batchdetl (acct_code,cmpy_code) using btree ;
alter table batchdetl add constraint foreign key (acct_code,cmpy_code) references coa(acct_code,cmpy_code) constraint fk_batchdetl_coa;

drop index if exists d_batchdetl_01;
create index d_batchdetl_01 on batchdetl(jour_code,jour_num,cmpy_code);
alter table batchdetl add constraint foreign key (jour_code,jour_num,cmpy_code) references batchhead(jour_code,jour_num,cmpy_code) constraint fk_batchdetl_batchhead;
