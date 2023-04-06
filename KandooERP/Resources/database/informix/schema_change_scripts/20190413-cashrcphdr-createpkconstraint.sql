--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: cashrcphdr
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE cashrcphdr ADD CONSTRAINT PRIMARY KEY (
cmpy_code,
batch_no
) CONSTRAINT pk_cashrcphdr;
