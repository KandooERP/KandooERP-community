--# description: this script loads additional data to kandoooption
--# tables list: kandoooption
--# author: alch
--# date: 2020-04-14
--# Ticket # : KD-1887: Testing - AR - A11 Throws an Internal DB Data Error by clicking apply to save a new customer (blocked)
--# dependencies:
--# more comments:

DELETE FROM kandoooption WHERE cmpy_code = '99' AND module_code = 'AR' AND feature_code = 'GI';
INSERT INTO kandoooption values('99', 'AR', 'GI', 'Customer Groups', 'Y');