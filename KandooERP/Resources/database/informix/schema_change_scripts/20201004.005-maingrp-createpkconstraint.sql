--# description: this script redefines the primary key constraint from a unique index
--# dependencies: n/a
--# tables list: maingrp
--# author: spokey/eric
--# date: 2020-10-04
--# Ticket # : 4
--# 
alter table maingrp drop constraint pk_maingrp;
drop index if exists pk_maingrp;
create unique index pk_maingrp on maingrp (maingrp_code,dept_code,cmpy_code);
ALTER TABLE maingrp ADD CONSTRAINT PRIMARY KEY (maingrp_code,dept_code,cmpy_code) CONSTRAINT pk_maingrp;