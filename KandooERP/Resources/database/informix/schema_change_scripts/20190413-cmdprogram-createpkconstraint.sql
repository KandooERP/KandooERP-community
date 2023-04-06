--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: cmdprogram
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE cmdprogram ADD CONSTRAINT PRIMARY KEY (
language_code,
progname_code,
menu_num,
cmd_num
) CONSTRAINT pk_cmdprogram;
