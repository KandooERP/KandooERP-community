--# description: this script changes the size of type_text
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: vendortype
--# author: eric vercelletto	
--# date: 2019-08-22
--# Ticket # : 	KD-903
--# more comments:
alter table vendortype modify type_text nvarchar(30,0);
