--# description: this script creates a foreign key constraint from invinst to invoicehead
--# dependencies: n/a
--# tables list: invinst
--# author: ericv
--# date: 2020-03-21
--# Ticket # : 
--# 

create index if not exists d01_invinst on invinst (inv_num, cmpy_code) using btree;
ALTER TABLE invinst ADD CONSTRAINT FOREIGN KEY (inv_num, cmpy_code) references invoicehead CONSTRAINT fk_invinst_invoicehead;