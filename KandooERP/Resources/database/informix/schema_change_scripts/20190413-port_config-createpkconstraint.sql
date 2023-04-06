--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: port_config
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE port_config ADD CONSTRAINT PRIMARY KEY (
port_id
) CONSTRAINT pk_port_config;
