--# description: this script changes the fields country_text to country_code (nchar(3) 
--# tables list: customership
--# dependencies: 20200314-country_text-dependencies 
--# author: ericv
--# date: 2020-03-15
--# Ticket # : 	KD-1761
--# more comments:
rename column customership.state_text to state_code;
alter table customership modify state_code nchar(6);
