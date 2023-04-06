--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: kandoomask
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE kandoomask ADD CONSTRAINT PRIMARY KEY (
user_code,
module_code,
access_type_code,
acct_mask_code,
cmpy_code
) CONSTRAINT pk_kandoomask;
