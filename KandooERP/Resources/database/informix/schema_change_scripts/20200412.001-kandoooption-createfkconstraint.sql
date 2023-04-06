--# description: this script creates a foreign key constraint from kandoooption to company
--# dependencies: n/a
--# tables list: kandoooption
--# author: ericv
--# date: 2020-04-12
--# Ticket # : 
--# Comments: please try the following command if you get a constraint violation, and DELETE those rows if any shows up
--# SELECT cmpy_code from kandoooption WHERE cmpy_code NOT IN (SELECT cmpy_code FROM company )
--# SELECT cmpy_code from company WHERE cmpy_code NOT IN (SELECT cmpy_code FROM kandoooption )

create index d01_kandoooption on kandoooption (cmpy_code) using btree;
ALTER TABLE kandoooption ADD CONSTRAINT FOREIGN KEY (cmpy_code) references company CONSTRAINT fk_kandoooption_company;
