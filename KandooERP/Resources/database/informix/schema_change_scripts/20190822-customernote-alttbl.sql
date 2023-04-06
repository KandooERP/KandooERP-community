--# description:  this script alter the notes field to nchar 260
--# dependencies: 
--# tables list: customernote
--# author: ericv
--# date: 2019-08-22
--# Ticket #: https://querix.atlassian.net/browse/KD-365
--# more comments:
alter table customernote modify note_text nchar(260);
