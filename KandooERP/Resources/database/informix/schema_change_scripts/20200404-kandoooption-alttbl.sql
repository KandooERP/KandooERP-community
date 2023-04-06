--# description: this script modifies the size of feature_text column
--# dependencies: 
--# tables list:  kandoooption
--# author: Eric V
--# date: 2020-04-04
--# Ticket: 
--# more comments: 
ALTER TABLE kandoooption MODIFY (feature_text NCHAR(60));
