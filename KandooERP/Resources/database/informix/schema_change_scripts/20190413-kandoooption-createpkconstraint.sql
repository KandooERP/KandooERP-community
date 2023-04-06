--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: kandoooption
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE kandoooption ADD CONSTRAINT PRIMARY KEY (
module_code,
feature_code,
cmpy_code
) CONSTRAINT pk_kandoooption;
