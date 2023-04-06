--# description: this script adds columns to rmsreps
--# tables list: rmsreps
--# author: ericv
--# date: 2020-05-19
--# Ticket # : 	KD-2034
--# dependencies:
--# more comments:

alter table rmsreps add (
select_option1 NVARCHAR(150),
select_option2 NVARCHAR(150)
);
alter table rmsreps modify sel_text LVARCHAR(1024);