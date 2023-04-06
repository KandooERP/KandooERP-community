--# description: this script set a constraints from maingrp to proddept
--# dependencies: 
--# tables list:  maingrp
--# author: Eric Vercelletto
--# date: 2020-10-05
--# Ticket: 
--# more comments: First step of consistent hierarchy design of inventory/maingrps

alter table maingrp add constraint foreign key (dept_code,cmpy_code) references proddept (dept_code,cmpy_code) constraint fk_maingrp_proddept;