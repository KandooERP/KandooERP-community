--# description: this script creates a foreign key constraint from product to company
--# dependencies: n/a
--# tables list: product
--# author: ericv
--# date: 2020-05-15
--# Ticket # : 
--# Comments: please try the following command if you get a constraint violation, and DELETE those rows if any shows up
--# SELECT cmpy_code from product WHERE cmpy_code NOT IN (SELECT cmpy_code FROM company )

create index d01_product on product (cmpy_code) using btree;
ALTER TABLE product ADD CONSTRAINT FOREIGN KEY (cmpy_code) references company CONSTRAINT fk_product_company;
