--# description: this script drops a too restrictive constraint on batchead  
--# dependencies:
--# tables list: batchhead 
--# author: eric
--# date: 2020-12-09
--# Ticket # : KD-2499
--# Next step is create a conditional trigger on update "batchhead.post_flag=Y" and store procedure doing the check 

alter table batchhead drop constraint ck_batchhead_02;