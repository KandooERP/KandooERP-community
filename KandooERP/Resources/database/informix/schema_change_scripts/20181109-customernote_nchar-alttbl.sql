--# description:  this script alter the notes field to nchar
--# dependencies: 
--# tables list: customernote
--# author: ericv
--# date: 2018-11-09
--# Ticket #: https://querix.atlassian.net/browse/KD-445
--# more comments:
alter table customernote modify note_text nchar(200);
