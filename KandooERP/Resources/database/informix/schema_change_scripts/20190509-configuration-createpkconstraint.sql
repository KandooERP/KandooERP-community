--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: configuration
--# author: ericv
--# date: 2019-05-08
--# Ticket # :  4
--# more comments:
create unique index u_configuration on configuration(generic_part_code,specific_part_code,cmpy_code );
alter table configuration add constraint primary key (generic_part_code,specific_part_code,cmpy_code) constraint pk_configuration;
