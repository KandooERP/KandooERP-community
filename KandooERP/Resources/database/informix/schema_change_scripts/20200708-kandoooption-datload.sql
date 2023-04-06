--# description: this script loads data to kandoooption
--# tables list: kandoooption
--# dependencies: 
--# author: ericv
--# date: 2020-07-08
--# Ticket #  KD-2236

on exception -691 status=OKE;
INSERT INTO kandoooption values ('DE','EO','BA','EO - Backordering enabled', 'N');
on exception -691 status=OKE;
INSERT INTO kandoooption values ('KA','EO','BA','EO - Backordering enabled', 'N');
