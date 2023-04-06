--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: country
--# author: ericv
--# date: 2019-05-11
--# Ticket # :  4
--# more comments:
create unique index u_country on country(country_code);
alter table country add constraint primary key (country_code) constraint pk_country;
