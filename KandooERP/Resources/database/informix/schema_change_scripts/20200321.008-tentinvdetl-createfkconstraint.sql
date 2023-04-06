--# description: this script creates a foreign key constraint from tentinvdetl to invoicehead
--# dependencies: n/a
--# tables list: tentinvdetl
--# author: ericv
--# date: 2020-03-21
--# Ticket # : 
--# 

ALTER TABLE tentinvdetl ADD CONSTRAINT FOREIGN KEY (inv_num, cmpy_code) references invoicehead CONSTRAINT fk_tentinvdetl_invoicehead;