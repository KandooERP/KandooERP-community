--# description: this script creates a table that will manage list of batches to post during a batch post. 
--# dependencies: 
--# tables list: list_of_batches_to_post 
--# author: eric
--# date: 2020-12-15
--# Ticket # : 
--# This table is permanent: if a batch post crashes, the batches remaining to post are still in the table.
--# on batch list per company/sign_on_code 

CREATE TABLE IF NOT EXISTS list_of_batches_to_post (cmpy_code NCHAR(2),sign_on_code NCHAR(8),jour_code NCHAR(3),jour_num INTEGER);
CREATE UNIQUE INDEX u_list_of_batches_to_post on list_of_batches_to_post (cmpy_code,jour_code,jour_num);
CREATE INDEX d_list_of_batches_to_post_01 on list_of_batches_to_post (cmpy_code,sign_on_code);