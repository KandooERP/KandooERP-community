--# description: this script create the table that will manage incrementing numbers such as invoice numbers, batch number, voucher numbers etc ....
--# dependencies: 
--# tables list:  increment_numbers
--# author: Eric Vercelletto
--# date: 2021-03-01
--# Ticket: 
--# more comments:

create table increment_numbers (
    cmpy_code CHAR(2),
    business_module CHAR(2),
    number_name CHAR(18),
    last_value INTEGER,
    last_modif_ts DATETIME YEAR TO SECOND
) ;

create unique index pk_increment ON increment_numbers (number_name,business_module,cmpy_code);
alter table increment_numbers add constraint primary key (number_name,business_module,cmpy_code);
