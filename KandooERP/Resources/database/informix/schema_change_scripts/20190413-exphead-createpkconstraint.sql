--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: exphead
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE exphead ADD CONSTRAINT PRIMARY KEY (
pick_num,
order_num,
export_num,
cmpy_code
) CONSTRAINT pk_exphead;
