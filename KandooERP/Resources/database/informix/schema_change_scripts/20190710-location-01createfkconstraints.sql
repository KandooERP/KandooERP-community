--# description: this script creates foreign keys in location
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: location
--# author: eric vercelletto
--# date: 2019-07-14
--# Ticket # :
--# more comments:
create index i_location_fk1 on location(ware_code,cmpy_code);
alter table location add constraint foreign key (ware_code,cmpy_code) references warehouse (ware_code,cmpy_code) constraint fk_location_warehouse;
create index i_location_fk2 on location (bank_code,cmpy_code) ;
alter table location add constraint foreign key (bank_code,cmpy_code) references bank  (bank_code,cmpy_code);
