--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: pricing
--# author: ericv
--# date: 2019-05-11
--# Ticket # :  4
--# more comments:
create unique index u_pricing on pricing(offer_code,cmpy_code);
alter table pricing add constraint primary key (offer_code,cmpy_code) constraint pk_pricing;
