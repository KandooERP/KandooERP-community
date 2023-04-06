--# description: this script create foreign key for invoicepay table
--# tables list: invoicepay
--# author: ericv
--# date: 2020-02-11
--# Ticket # : 	
--# more comments:

drop index  if exists d1_invoicepay ;
create index if not exists d1_invoicepay on invoicepay (inv_num,cmpy_code) using btree ;
alter table invoicepay add constraint foreign key (inv_num , cmpy_code) references invoicehead constraint fk_invoicepay_invoicehead  ;
create index d2_invoicepay on invoicepay (cust_code,cmpy_code) using btree ;
