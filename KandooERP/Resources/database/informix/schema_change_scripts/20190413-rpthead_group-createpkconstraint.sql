--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: rpthead_group
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE rpthead_group ADD CONSTRAINT PRIMARY KEY (
rptgrp_id,
cmpy_code
) CONSTRAINT pk_rpthead_group;
