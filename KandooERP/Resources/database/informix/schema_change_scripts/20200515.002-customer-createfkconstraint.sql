--# description: this script creates a foreign key constraint from customer to company
--# dependencies: n/a
--# tables list: customer
--# author: ericv
--# date: 2020-05-15
--# Ticket # : 
--# Comments: please try the following command if you get a constraint violation, and DELETE those rows if any shows up
--# SELECT cmpy_code from customer WHERE cmpy_code NOT IN (SELECT cmpy_code FROM company )

create index d01_customer on customer (cmpy_code) using btree;
ALTER TABLE customer ADD CONSTRAINT FOREIGN KEY (cmpy_code) references company CONSTRAINT fk_customer_company;
