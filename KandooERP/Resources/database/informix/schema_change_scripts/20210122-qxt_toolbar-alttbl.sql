--# description: this script adds the tb_place column in qxt_toolbar means place where toolbar button will be displayed on toolbar or drop-down menu
--# dependencies: 
--# tables list: qxt_toolbar 
--# author: alch
--# date: 2021-01-22
--# Ticket # : KD-1413
--# 

ALTER TABLE qxt_toolbar ADD tb_place VARCHAR(16);