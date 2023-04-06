--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: subissues
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE subissues ADD CONSTRAINT PRIMARY KEY (
part_code,
type_code,
start_date,
end_date,
issue_num,
cmpy_code
) CONSTRAINT pk_subissues;
