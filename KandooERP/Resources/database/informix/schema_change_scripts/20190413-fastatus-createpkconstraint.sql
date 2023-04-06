--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: fastatus
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE fastatus ADD CONSTRAINT PRIMARY KEY (
asset_code,
add_on_code,
book_code,
seq_num,
cmpy_code
) CONSTRAINT pk_fastatus;
