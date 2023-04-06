--# description: this script creates the foreign key from warehouse to company
--# tables list: warehouse
--# author: ericv
--# date: 2020-05-22
--# Ticket # : 	
--# dependencies:
--# more comments: in case of error -297, check the data with the following query, and delete accordingly
--# select  cmpy_code from warehouse where cmpy_code not in ( select cmpy_code from company )

create index if not exists fk1_warehouse on warehouse (cmpy_code);
alter table warehouse add constraint foreign key (cmpy_code) references company (cmpy_code) constraint fk_warehouse_company ;

