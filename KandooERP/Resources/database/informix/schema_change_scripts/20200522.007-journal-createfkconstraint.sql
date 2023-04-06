--# description: this script creates the foreign key from journal to company
--# tables list: journal
--# author: ericv
--# date: 2020-05-22
--# Ticket # : 	
--# dependencies:
--# more comments: in case of error -297, check the data with the following query, and delete accordingly
--# select  cmpy_code from journal where cmpy_code not in ( select  cmpy_code from company )
--# if pointing to company, we should add year_num and period to journal

create index if not exists fk2_journal on journal (cmpy_code);
alter table journal add constraint foreign key (cmpy_code) references company (cmpy_code) constraint fk_journal_company ;

