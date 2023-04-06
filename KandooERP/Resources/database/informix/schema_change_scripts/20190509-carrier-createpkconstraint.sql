--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: carrier
--# author: ericv
--# date: 2019-05-08
--# Ticket # :  4
--# more comments:
create unique index u_carrier on carrier(carrier_code,cmpy_code);
alter table carrier add constraint primary key (carrier_code,cmpy_code) constraint pk_carrier;
