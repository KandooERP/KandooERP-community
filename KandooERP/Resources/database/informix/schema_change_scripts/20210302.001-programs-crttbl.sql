--# description: this script create the table programs and objects that contains objects to translate
--# dependencies: 
--# tables list:  increment_numbers
--# author: Eric Vercelletto
--# date: 2021-03-02
--# Ticket: 
--# more comments: KD-2657

create table fgltarget (
    program_name CHAR(10),
    container VARCHAR(28,6)
) ;

create unique index pk_fgltarget ON fgltarget (program_name,container);
alter table fgltarget add constraint primary key (program_name,container) constraint pk_fgltarget;
