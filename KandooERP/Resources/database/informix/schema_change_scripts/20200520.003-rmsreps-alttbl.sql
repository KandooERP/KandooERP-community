--# description: this script modifies the order of some columns
--# tables list: rmsreps
--# author: ericv
--# date: 2020-05-20
--# Ticket # : 	KD-2034
--# dependencies:
--# more comments:

rename column rmsreps.select_option1 to sel_option1;
rename column rmsreps.select_option2 to sel_option2;
