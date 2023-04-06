--# description: this script loads additional data to kandoooption
--# tables list: kandoooption
--# author: alch
--# date: 2020-04-15
--# Ticket # : KD-1779/KD-1889: Investigate the source of the incorrect behavior some programs of the P1 and P2 modules.
--# dependencies:
--# more comments:

DELETE FROM kandoooption WHERE cmpy_code = '99' AND module_code = 'AP' AND feature_code = 'DO';
INSERT INTO kandoooption values('99', 'AP', 'DO', 'Voucher Payment Order', '1');