--# description: this script set a constraints from proddept to company
--# dependencies: 
--# tables list:  proddept
--# author: Eric Vercelletto
--# date: 2020-10-05
--# Ticket: 
--# more comments: First step of consistent hierarchy design of inventory/proddepts

alter table proddept add constraint foreign key (cmpy_code) references company (cmpy_code) constraint fk_proddept_company;