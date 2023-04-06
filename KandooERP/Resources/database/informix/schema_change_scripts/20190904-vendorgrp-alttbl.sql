--# description: this script re-create primary key for vendorgrp table 
--# tables list: vendorgrp
--# author: albo
--# date: 2019-09-04
--# Ticket # : 	
--# more comments:

begin work;
   drop index if exists u_vendorgrp;
   alter table vendorgrp drop constraint pk_vendorgrp;
   create unique index u_vendorgrp on vendorgrp (mast_vend_code,vend_code,cmpy_code) ;
   alter table vendorgrp add constraint primary key (mast_vend_code,vend_code,cmpy_code) constraint pk_vendorgrp;
commit work;

