--# description: this script creates a foreign key for contractor
--# dependencies: 
--# tables list:  contractor
--# author: Eric Vercelletto
--# date: 2020-12-29
--# Ticket: 
--# more comments:

alter table contractor add constraint foreign key (vend_code,cmpy_code) references vendor(vend_code,cmpy_code) constraint fk_contractor_vendor ;