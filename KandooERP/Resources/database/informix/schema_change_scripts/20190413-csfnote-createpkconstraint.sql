--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: csfnote
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE csfnote ADD CONSTRAINT PRIMARY KEY (
complaint_code,
type_ind,
seq_num,
cmpy_code
) CONSTRAINT pk_csfnote;
