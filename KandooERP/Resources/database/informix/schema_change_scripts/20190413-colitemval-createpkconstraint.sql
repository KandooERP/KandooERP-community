--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: colitemval
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE colitemval ADD CONSTRAINT PRIMARY KEY (
rpt_id,
col_uid,
seq_num,
cmpy_code
) CONSTRAINT pk_colitemval;
