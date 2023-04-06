--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: offerauto
--# author: ericv
--# date: 2019-05-11
--# Ticket # :  4
--# more comments:
create unique index u_offerauto on offerauto(part_code,offer_code,cmpy_code);
alter table offerauto add constraint primary key (part_code,offer_code,cmpy_code) constraint pk_offerauto;
