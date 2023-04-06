--# description: this script creates the foreign key from invoicedetl to coa
--# tables list: invoicedetl
--# author: ericv
--# date: 2020-05-22
--# Ticket # : 	
--# dependencies:
--# more comments: in case of error -297, check the data with the following query, and delete accordingly
--# select  line_acct_code||cmpy_code from invoicedetl where line_acct_code||cmpy_code not in ( select  acct_code||cmpy_code from coa )
--# if pointing to coa, we should add year_num and period to invoicedetl

create index if not exists fk2_invoicedetl on invoicedetl (line_acct_code,cmpy_code);
alter table invoicedetl add constraint foreign key (line_acct_code,cmpy_code) references coa (acct_code,cmpy_code) constraint fk_invoicedetl_coa ;