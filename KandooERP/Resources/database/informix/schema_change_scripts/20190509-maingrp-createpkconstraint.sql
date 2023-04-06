--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: maingrp
--# author: ericv
--# date: 2019-05-08
--# Ticket # :  4
--# more comments:
create unique index u_maingrp on maingrp(maingrp_code,cmpy_code);
alter table maingrp add constraint primary key (maingrp_code,cmpy_code) constraint pk_maingrp;
