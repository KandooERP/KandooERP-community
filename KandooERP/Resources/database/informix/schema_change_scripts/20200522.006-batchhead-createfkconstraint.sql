--# description: this script creates the foreign key from batchhead to journal
--# tables list: batchhead
--# author: ericv
--# date: 2020-05-22
--# Ticket # : 	
--# dependencies:
--# more comments: in case of error -297, check the data with the following query, and delete accordingly
--# select  jour_code||cmpy_code from batchhead where jour_code||cmpy_code not in ( select  jour_code||cmpy_code from journal )
--# if pointing to journal, we should add year_num and period to batchhead

create index if not exists fk2_batchhead on batchhead (jour_code,cmpy_code);
alter table batchhead add constraint foreign key (jour_code,cmpy_code) references journal (jour_code,cmpy_code) constraint fk_batchhead_journal ;
--ALTER TABLE batchhead DROP CONSTRAINT fk_batchhead_company;

