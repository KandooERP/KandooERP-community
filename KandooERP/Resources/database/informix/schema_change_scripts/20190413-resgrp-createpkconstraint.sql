--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: resgrp
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE resgrp ADD CONSTRAINT PRIMARY KEY (
resgrp_code,
cmpy_code
) CONSTRAINT pk_resgrp;
