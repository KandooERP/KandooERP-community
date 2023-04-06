--# description: this script creates a foreign key for ibtdetl to product
--# tables list: ibtdetl
--# author: ericv
--# date: 2020-06-01
--# Ticket # : 	
--# dependencies:
--# more comments:

create index if not exists d03_ibtdetl on ibtdetl (part_code,cmpy_code);
alter table ibtdetl add constraint foreign key(part_code,cmpy_code) references product(part_code,cmpy_code) constraint fk1_ibtdetl_product;
