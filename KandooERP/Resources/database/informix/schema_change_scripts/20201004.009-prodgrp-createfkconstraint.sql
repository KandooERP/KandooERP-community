--# description: this script set a constraints from prodgrp to maingrp
--# dependencies: 
--# tables list:  prodgrp
--# author: Eric Vercelletto
--# date: 2020-10-05
--# Ticket: 
--# more comments: First step of consistent hierarchy design of inventory/prodgrps

alter table prodgrp add constraint foreign key (maingrp_code,dept_code,cmpy_code) references maingrp (maingrp_code,dept_code,cmpy_code) constraint fk_prodgrp_maingrp;