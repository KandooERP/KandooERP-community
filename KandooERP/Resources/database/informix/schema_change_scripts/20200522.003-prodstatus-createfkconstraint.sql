--# description: this script creates the foreign key from prodstatus to warehouse
--# tables list: prodstatus
--# author: ericv
--# date: 2020-05-22
--# Ticket # : 	
--# dependencies:
--# more comments: in case of error -297, check the data with the following query, and delete accordingly
--# select  ware_code||cmpy_code from prodstatus where ware_code||cmpy_code not in ( select  ware_code||cmpy_code from warehouse )

create index if not exists fk2_prodstatus on prodstatus (ware_code,cmpy_code);
alter table prodstatus add constraint foreign key (ware_code,cmpy_code) references warehouse (ware_code,cmpy_code) constraint fk_prodstatus_warehouse ;

