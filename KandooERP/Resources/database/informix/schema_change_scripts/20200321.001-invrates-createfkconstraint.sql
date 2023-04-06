--# description: this script creates a foreign key constraint from invrates to invoicedetl
--# dependencies: n/a
--# tables list: invrates
--# author: ericv
--# date: 2020-03-21
--# Ticket # : 
--# 

create index if not exists d01_invrates on invrates (inv_num,line_num, cmpy_code) using btree;
ALTER TABLE invrates ADD CONSTRAINT FOREIGN KEY (inv_num,line_num, cmpy_code) references invoicedetl CONSTRAINT fk_invrates_invoicedetl;