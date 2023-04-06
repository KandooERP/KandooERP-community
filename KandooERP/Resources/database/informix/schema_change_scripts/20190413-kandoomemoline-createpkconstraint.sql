--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: kandoomemoline
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE kandoomemoline ADD CONSTRAINT PRIMARY KEY (
memo_num,
line_num
) CONSTRAINT pk_kandoomemoline;
