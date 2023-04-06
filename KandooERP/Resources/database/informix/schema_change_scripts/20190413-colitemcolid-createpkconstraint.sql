--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: colitemcolid
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE colitemcolid ADD CONSTRAINT PRIMARY KEY (
rpt_id,
col_uid,
seq_num,
cmpy_code
) CONSTRAINT pk_colitemcolid;
