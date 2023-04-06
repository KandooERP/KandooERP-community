--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: rptcolgrp
--# author: ericv
--# date: 2019-05-11
--# Ticket # :  4
--# more comments:
create unique index u_rptcolgrp on rptcolgrp(col_code,cmpy_code);
alter table rptcolgrp add constraint primary key (col_code,cmpy_code) constraint pk_rptcolgrp;
