--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: vendorgrp
--# author: ericv
--# date: 2019-05-07
--# Ticket # : 4
--# 

create unique index u_vendorgrp on vendorgrp(mast_vend_code,cmpy_code);
ALTER TABLE vendorgrp ADD CONSTRAINT PRIMARY KEY ( mast_vend_code,cmpy_code)
CONSTRAINT pk_vendorgrp;
