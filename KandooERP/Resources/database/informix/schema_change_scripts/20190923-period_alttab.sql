--# description: this script modifies the structure of 'period' table
--# dependencies: none
--# tables list:  period
--# author: Alex Bondar
--# date: 2019-09-23
--# Ticket # KD-1226
--# more comments: 

alter table period add (desc_text nchar(60));
