--# description: this script creates a foreign key constraint from postinvhead to invoicehead
--# dependencies: n/a
--# tables list: postinvhead
--# author: ericv
--# date: 2020-03-21
--# Ticket # : 
--# more comments: this is a one to one relationship, based on unique index

rename index post_inv1_key to d01_postinvhead;
ALTER TABLE postinvhead ADD CONSTRAINT FOREIGN KEY (inv_num, cmpy_code) references invoicehead CONSTRAINT fk_postinvhead_invoicehead;