--# description: this script extends column prodgrp_code to nchar(6) and adds dept_code (subdept_code get deprecated)
--# dependencies: 
--# tables list:  prodgrp
--# author: Eric Vercelletto
--# date: 2020-10-05
--# Ticket: 
--# more comments: char(3) really too small

alter table prodgrp modify (prodgrp_code nchar(6));
alter table prodgrp add (dept_code nchar(3));