--# description: this script handles loads new messages in kandoomsg
--# dependencies: 
--# tables list:  kandoomsg
--# author: Eric V
--# date: 2020-11-23
--# Ticket: KD-2464
--# more comments: 
--# 
insert into kandoomsg (source_ind,msg_num,language_code,msg_ind,format_ind,msg1_text) 
VALUES ("G",9701,"ENG",'9','5',"Analysis is applied to this account which requires a corresponding Analysis Text");
insert into kandoomsg (source_ind,msg_num,language_code,msg_ind,format_ind,msg1_text)
VALUES ("G",9702,"ENG",'9','5',"Analysis is applied to this account which requires a valid UOM-Quantity value");