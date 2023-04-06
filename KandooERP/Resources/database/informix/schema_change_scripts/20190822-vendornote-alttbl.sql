--# description: this script makes changes in vendornote (more modern schema)
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: vendornote
--# author: eric vercelletto	
--# date: 2019-08-22
--# Ticket # : 	KD-926
--# more comments:
alter table vendornote modify note_date datetime year to second ;
alter table vendornote drop note_num;
alter table vendornote modify note_text lvarchar(1024);
