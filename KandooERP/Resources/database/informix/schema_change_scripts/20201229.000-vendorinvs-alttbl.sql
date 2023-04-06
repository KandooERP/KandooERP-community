--# description: this script adds the column year_num to vendoinvs for unicity purpose
--# dependencies: 
--# tables list:  vendorinvs
--# author: Eric Vercelletto
--# date: 2020-12-29
--# Ticket: 
--# more comments:

alter table vendorinvs add (year_num integer);