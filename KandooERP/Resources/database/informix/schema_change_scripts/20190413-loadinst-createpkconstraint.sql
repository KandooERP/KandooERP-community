--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: loadinst
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE loadinst ADD CONSTRAINT PRIMARY KEY (
load_num,
load_line_num,
call_fwd_code,
instr_num,
cmpy_code
) CONSTRAINT pk_loadinst;
