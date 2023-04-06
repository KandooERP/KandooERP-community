--# description: this script creates the foreign key from prodstatus to product
--# tables list: prodstatus
--# author: ericv
--# date: 2020-05-22
--# Ticket # : 	
--# dependencies:
--# more comments: in case of error -297, check the data with the following query, and delete accordingly
--# select  part_code||cmpy_code from prodstatus where part_code||cmpy_code not in ( select  part_code||cmpy_code from product )

create index if not exists fk1_prodstatus on prodstatus (part_code,cmpy_code);
alter table prodstatus add constraint foreign key (part_code,cmpy_code) references product (part_code,cmpy_code) constraint fk_prodstatus_product ;

