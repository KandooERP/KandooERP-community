--# description: this script adds column country_code to the kandoouser table
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: kandoouser
--# author: eric vercelletto	
--# date: 2019-09-14
--# Ticket # : 	
--# more comments:
alter table kandoouser add country_code nchar(3) before cmpy_code;	
