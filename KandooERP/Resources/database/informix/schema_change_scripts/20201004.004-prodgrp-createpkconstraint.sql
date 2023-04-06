--# description: this script redefines the primary key constraint from a unique index
--# dependencies: n/a
--# tables list: prodgrp
--# author: spokey/eric
--# date: 2020-10-04
--# Ticket # : 4
--# 
on exception -623 status=OKE;
alter table prodgrp drop constraint pk_prodgrp;
drop index if exists pk_prodgrp;
create unique index pk_prodgrp on prodgrp (prodgrp_code,maingrp_code,dept_code,cmpy_code);
ALTER TABLE prodgrp ADD CONSTRAINT PRIMARY KEY (prodgrp_code,maingrp_code,dept_code,cmpy_code) CONSTRAINT pk_prodgrp;
