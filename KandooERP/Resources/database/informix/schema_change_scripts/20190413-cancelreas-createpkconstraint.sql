--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: cancelreas
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE cancelreas ADD CONSTRAINT PRIMARY KEY (
hold_code,
cmpy_code
) CONSTRAINT pk_cancelreas;
