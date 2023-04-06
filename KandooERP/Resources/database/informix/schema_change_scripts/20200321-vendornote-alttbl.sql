--# description: this script makes changes in vendornote (more modern schema)
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: vendornote
--# author: eric vercelletto	
--# date: 2020-03-21
--# Ticket # : 	KD-926
--# more comments: extended to 4096
alter table vendornote modify note_text lvarchar(4096);
