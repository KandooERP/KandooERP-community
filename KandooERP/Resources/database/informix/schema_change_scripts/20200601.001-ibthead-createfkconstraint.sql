--# description: this script creates 2 foreign keys for ibthead to warehouse
--# tables list: ibthead
--# author: ericv
--# date: 2020-06-01
--# Ticket # : 	
--# dependencies:
--# more comments:

create index if not exists d01_ibthead on ibthead (from_ware_code,cmpy_code);
alter table ibthead add constraint foreign key(from_ware_code,cmpy_code) references warehouse(ware_code,cmpy_code) constraint fk1_ibthead_warehouse;
create index if not exists d02_ibthead on ibthead (to_ware_code,cmpy_code);
alter table ibthead add constraint foreign key(to_ware_code,cmpy_code) references warehouse(ware_code,cmpy_code) constraint fk2_ibthead_warehouse;
