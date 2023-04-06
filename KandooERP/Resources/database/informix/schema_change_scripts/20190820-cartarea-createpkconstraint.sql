--# description: this script create indexes and constraints on cartarea
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: cartarea
--# author: eric vercelletto
--# date: 2019-08-20
--# Ticket # :
--# more comments:
create unique index u_cartarea on cartarea(cart_area_code,cmpy_code);
alter table cartarea add constraint primary key (cart_area_code,cmpy_code) constraint pk_cartarea ;

