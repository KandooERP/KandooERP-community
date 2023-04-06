--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: ibtload
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE ibtload ADD CONSTRAINT PRIMARY KEY (
trans_num,
line_num,
pick_num,
cmpy_code
) CONSTRAINT pk_ibtload;
