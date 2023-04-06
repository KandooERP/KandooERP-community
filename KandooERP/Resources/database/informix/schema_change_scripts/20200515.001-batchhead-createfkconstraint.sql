--# description: this script creates a foreign key constraint from batchhead to company
--# dependencies: n/a
--# tables list: batchhead
--# author: ericv
--# date: 2020-05-15
--# Ticket # : 
--# Comments: please try the following command if you get a constraint violation, and DELETE those rows if any shows up
--# SELECT cmpy_code from batchhead WHERE cmpy_code NOT IN (SELECT cmpy_code FROM company )
--# SELECT cmpy_code from company WHERE cmpy_code NOT IN (SELECT cmpy_code FROM batchhead )

create index d01_batchhead on batchhead (cmpy_code) using btree;
ALTER TABLE batchhead ADD CONSTRAINT FOREIGN KEY (cmpy_code) references company CONSTRAINT fk_batchhead_company;
