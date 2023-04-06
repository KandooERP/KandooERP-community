--# description: this script creates a foreign key constraint from vendor to company
--# dependencies: n/a
--# tables list: vendor
--# author: ericv
--# date: 2020-05-15
--# Ticket # : 
--# Comments: please try the following command if you get a constraint violation, and DELETE those rows if any shows up
--# SELECT cmpy_code from vendor WHERE cmpy_code NOT IN (SELECT cmpy_code FROM company )

create index d01_vendor on vendor (cmpy_code) using btree;
ALTER TABLE vendor ADD CONSTRAINT FOREIGN KEY (cmpy_code) references company CONSTRAINT fk_vendor_company;
