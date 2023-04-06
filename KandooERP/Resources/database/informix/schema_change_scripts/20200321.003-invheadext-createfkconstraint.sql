--# description: this script creates a foreign key constraint from invheadext to invoicehead
--# dependencies: n/a
--# tables list: invheadext
--# author: ericv
--# date: 2020-03-21
--# Ticket # : 
--# 

create index if not exists d01_invheadext on invheadext (inv_num, cmpy_code) using btree;
ALTER TABLE invheadext ADD CONSTRAINT FOREIGN KEY (inv_num, cmpy_code) references invoicehead CONSTRAINT fk_invheadext_invoicehead;
