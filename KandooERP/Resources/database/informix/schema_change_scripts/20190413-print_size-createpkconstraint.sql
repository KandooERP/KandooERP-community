--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: print_size
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE print_size ADD CONSTRAINT PRIMARY KEY (
print_size_code
) CONSTRAINT pk_print_size;
