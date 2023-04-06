--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: postinvhead
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE postinvhead ADD CONSTRAINT PRIMARY KEY (
inv_num,
cmpy_code
) CONSTRAINT pk_postinvhead;
