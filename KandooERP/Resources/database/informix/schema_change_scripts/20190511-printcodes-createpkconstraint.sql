--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: printcodes
--# author: ericv
--# date: 2019-05-11
--# Ticket # :  4
--# more comments:
create unique index u_printcodes on printcodes(print_code);
alter table printcodes add constraint primary key (print_code) constraint pk_printcodes;
