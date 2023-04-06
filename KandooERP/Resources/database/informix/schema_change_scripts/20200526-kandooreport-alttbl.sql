--# description: this script modifies the length of menupath_text
--# tables list: kandooreport
--# author: ericv
--# date: 2020-05-26
--# Ticket # : 	KD-2135
--# dependencies:
--# more comments:

ALTER TABLE kandooreport modify menupath_text  NCHAR(5) ;