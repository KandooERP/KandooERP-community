--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: assets
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE assets ADD CONSTRAINT PRIMARY KEY (
asset_code,
cmpy_code
) CONSTRAINT pk_assets;
