--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: acctgrp
--# author: ericv
--# date: 2019-05-13
--# Ticket # :  4
--# more comments:
create unique index u_acctgrp on acctgrp(group_code,cmpy_code);
alter table acctgrp add constraint primary key (group_code,cmpy_code) constraint pk_acctgrp;
