--# description: this script creates a foreign key constraint from tentinvhead to invoicehead
--# dependencies: n/a
--# tables list: tentinvhead
--# author: ericv
--# date: 2020-03-21
--# Ticket # : 
--# 

ALTER TABLE tentinvhead ADD CONSTRAINT FOREIGN KEY (inv_num, cmpy_code) references invoicehead CONSTRAINT fk_tentinvhead_invoicehead;