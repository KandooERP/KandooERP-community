--# description: this script create foreign key for invoicehead table
--# tables list: invoicehead
--# author: ericv
--# date: 2020-03-05
--# Ticket # : 	
--# more comments: in case or error -525, please run the following query and delete matching results
--# delete    ( or select inv_num,cmpy_code if you want to check first )
--# from invoicehead
--# where inv_num||cmpy_code not in (select inv_num||cmpy_code from invoicehead );
--# alter table invoicehead drop constraint fk_invoicehead_invoicehead ;
--# and execute the patches again
create index if not exists d1_invoicehead  on invoicehead (cust_code,cmpy_code) using btree ;
alter table invoicehead add constraint foreign key (cust_code , cmpy_code) references customer constraint fk_invoicehead_customer  ;