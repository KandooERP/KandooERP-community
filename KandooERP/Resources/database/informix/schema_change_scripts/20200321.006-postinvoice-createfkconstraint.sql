--# description: this script creates a foreign key constraint from postinvoice to invoicehead
--# dependencies: n/a
--# tables list: postinvoice
--# author: ericv
--# date: 2020-03-21
--# Ticket # : 
--# 

ALTER TABLE postinvoice ADD CONSTRAINT FOREIGN KEY (inv_num, cmpy_code) references invoicehead CONSTRAINT fk_postinvoice_invoicehead;