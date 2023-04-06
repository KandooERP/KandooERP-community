--# description: This script is the dependency for 20200416.001-company-alttbl,20200416.002-manytables-delete_trashdata,20200416.003-manytables-compy_code_update,20200416.004-manytables-alttbl
--# dependencies: 
--# tables list: company
--# author: ericv
--# date: 2020-04-16
--# Ticket # : KD-1965
--# This script must report OK to trigger the execution of the depending scripts
--# More comments: the script is created intentionally with one syntax error: this will prevent the consecutive depending scripts to execute, until the syntax error is fixed

create table if not exists kandoo_dependency ( dep_date date);
insert into kandoo_dependency VALUES (current);
drop table if exists kandoo_dependency;
