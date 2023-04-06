--# description: This script is the dependency for mobile-email alter tables 20200317.001-mobile_email-alttbl and 20200317.002-mobile_email-alttbl
--# dependencies: 
--# tables list: many tables
--# author: ericv
--# date: 2020-03-17
--# Ticket # : KD-1965
--# This script must report OK to trigger the execution of the depending scripts
--# More comments: the script is created intentionally with one syntax error: this will prevent the consecutive depending scripts to execute, until the syntax error is fixed

create table if not exists kandoo_dependency ( dep_date date);
insert into kandoo_dependency VALUES (current);
drop table if exists kandoo_dependency;
