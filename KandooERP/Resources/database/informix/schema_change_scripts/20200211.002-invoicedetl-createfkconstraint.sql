--# description: this script create foreign key for invoicedetl table
--# tables list: invoicedetl
--# author: ericv
--# date: 2020-02-11
--# Ticket # : 	
--# more comments: in case or error -525, please run the following query and delete matching results
--# delete    ( or select inv_num,cmpy_code if you want to check first )
--# from invoicedetl
--# where inv_num||cmpy_code not in (select inv_num||cmpy_code from invoicehead );
--# alter table invoicedetl drop constraint fk_invoicedetl_invoicehead ;
--# and execute the patches again
drop index if exists d1_invoicedetl;
create index if not exists d1_invoicedetl  on invoicedetl (inv_num,cmpy_code) using btree ;
alter table invoicedetl add constraint foreign key (inv_num , cmpy_code) references invoicehead constraint fk_invoicedetl_invoicehead  ;
drop index if exists d2_invoicedetl;
create index if not exists d2_invoicedetl on invoicedetl (cust_code,cmpy_code) using btree ;
