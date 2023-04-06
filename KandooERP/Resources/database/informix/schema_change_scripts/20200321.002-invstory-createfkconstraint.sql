--# description: this script creates a foreign key constraint from invstory to invoicehead
--# dependencies: n/a
--# tables list: invstory
--# author: ericv
--# date: 2020-03-21
--# Ticket # : 
--# 

create index d01_invstory on invstory (inv_num, cmpy_code) using btree;
ALTER TABLE invstory ADD CONSTRAINT FOREIGN KEY (inv_num, cmpy_code) references invoicehead CONSTRAINT fk_invstory_invoicehead;
