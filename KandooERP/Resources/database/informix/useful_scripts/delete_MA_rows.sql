begin work;
set constraints all deferred;
DELETE FROM accounthist where cmpy_code != "KA";
DELETE FROM cancelcheq where cmpy_code != "KA";
DELETE FROM jmresource where cmpy_code != "KA";
DELETE FROM puparms where cmpy_code != "KA";
DELETE FROM purchhead where cmpy_code != "KA";
DELETE FROM debitdist where cmpy_code != "KA";
DELETE FROM purchdetl where cmpy_code != "KA";
DELETE FROM jobtype where cmpy_code != "KA";
DELETE FROM account where cmpy_code != "KA";
DELETE FROM quotenote where cmpy_code != "KA";
DELETE FROM orderdetl where cmpy_code != "KA";
DELETE FROM quotelead where cmpy_code != "KA";
DELETE FROM stktake where cmpy_code != "KA";
DELETE FROM voucherdist where cmpy_code != "KA";
DELETE FROM costledg where cmpy_code != "KA";
DELETE FROM backorder where cmpy_code != "KA";
DELETE FROM kandoomenu where cmpy_code != "KA";
DELETE FROM credithead where cmpy_code != "KA";
DELETE FROM contributor where cmpy_code != "KA";
DELETE FROM jmparms where cmpy_code != "KA";
DELETE FROM prodquote where cmpy_code != "KA";
DELETE FROM tariff where cmpy_code != "KA";
DELETE FROM job where cmpy_code != "KA";
DELETE FROM saleshistory where cmpy_code != "KA";
DELETE FROM ts_detail where cmpy_code != "KA";
DELETE FROM tentpays where cmpy_code != "KA";
DELETE FROM purchrcpdet where cmpy_code != "KA";
DELETE FROM accumulator where cmpy_code != "KA";
DELETE FROM calchead where cmpy_code != "KA";
DELETE FROM calcline where cmpy_code != "KA";
DELETE FROM colaccum where cmpy_code != "KA";
DELETE FROM colitem where cmpy_code != "KA";
DELETE FROM colitemcolid where cmpy_code != "KA";
DELETE FROM colitemdetl where cmpy_code != "KA";
DELETE FROM colitemval where cmpy_code != "KA";
DELETE FROM descline where cmpy_code != "KA";
DELETE FROM extline where cmpy_code != "KA";
DELETE FROM glline where cmpy_code != "KA";
DELETE FROM gllinedetl where cmpy_code != "KA";
DELETE FROM rptcol where cmpy_code != "KA";
DELETE FROM rptline where cmpy_code != "KA";
DELETE FROM rptcoldesc where cmpy_code != "KA";
DELETE FROM rpthead where cmpy_code != "KA";
DELETE FROM segline where cmpy_code != "KA";
DELETE FROM saveline where cmpy_code != "KA";
DELETE FROM accountledger where cmpy_code != "KA";
DELETE FROM txtline where cmpy_code != "KA";
DELETE FROM glsumdiv where cmpy_code != "KA";
DELETE FROM glsummary where cmpy_code != "KA";
DELETE FROM glsumblock where cmpy_code != "KA";
DELETE FROM bankdetails where cmpy_code != "KA";
DELETE FROM reqhead where cmpy_code != "KA";
DELETE FROM activity where cmpy_code != "KA";
DELETE FROM reqaudit where cmpy_code != "KA";
DELETE FROM reqbackord where cmpy_code != "KA";
DELETE FROM contact where cmpy_code != "KA";
DELETE FROM pendhead where cmpy_code != "KA";
DELETE FROM penddetl where cmpy_code != "KA";
DELETE FROM quotedetl where cmpy_code != "KA";
DELETE FROM cbaudit where cmpy_code != "KA";
DELETE FROM apaudit where cmpy_code != "KA";
DELETE FROM delhead where cmpy_code != "KA";
DELETE FROM deldetl where cmpy_code != "KA";
DELETE FROM batchhead where cmpy_code != "KA";
DELETE FROM batchdetl where cmpy_code != "KA";
DELETE FROM quotehead where cmpy_code != "KA";
DELETE FROM fabook where cmpy_code != "KA";
DELETE FROM facat where cmpy_code != "KA";
DELETE FROM falocation where cmpy_code != "KA";
DELETE FROM voucher where cmpy_code != "KA";
DELETE FROM poaudit where cmpy_code != "KA";
DELETE FROM cashrcphdr where cmpy_code != "KA";
DELETE FROM faauth where cmpy_code != "KA";
DELETE FROM fadepmethod where cmpy_code != "KA";
DELETE FROM cont_mail where cmpy_code != "KA";
DELETE FROM cont_stats where cmpy_code != "KA";
DELETE FROM rptcolaa where cmpy_code != "KA";
DELETE FROM stktakedetl where cmpy_code != "KA";
DELETE FROM faresp where cmpy_code != "KA";
DELETE FROM shiphead where cmpy_code != "KA";
DELETE FROM glasset where cmpy_code != "KA";
DELETE FROM faperiod where cmpy_code != "KA";
DELETE FROM fabookdep where cmpy_code != "KA";
DELETE FROM faparms where cmpy_code != "KA";
DELETE FROM fastocklocn where cmpy_code != "KA";
DELETE FROM salesanly where cmpy_code != "KA";
DELETE FROM syslocks where cmpy_code != "KA";
DELETE FROM kandoooption where cmpy_code != "KA";
DELETE FROM exchangevar where cmpy_code != "KA";
DELETE FROM accountcur where cmpy_code != "KA";
DELETE FROM accounthistcur where cmpy_code != "KA";
DELETE FROM confirm where cmpy_code != "KA";
DELETE FROM faaudit where cmpy_code != "KA";
DELETE FROM fabatch where cmpy_code != "KA";
DELETE FROM falease where cmpy_code != "KA";
DELETE FROM fainsure where cmpy_code != "KA";
DELETE FROM fastatus where cmpy_code != "KA";
DELETE FROM userref where cmpy_code != "KA";
DELETE FROM carriercost where cmpy_code != "KA";
DELETE FROM offersale where cmpy_code != "KA";
DELETE FROM offerprod where cmpy_code != "KA";
DELETE FROM shipnote where cmpy_code != "KA";
DELETE FROM shiptype where cmpy_code != "KA";
DELETE FROM shipdist where cmpy_code != "KA";
DELETE FROM shipdebit where cmpy_code != "KA";
DELETE FROM shipcost where cmpy_code != "KA";
DELETE FROM saleshare where cmpy_code != "KA";
DELETE FROM smparms where cmpy_code != "KA";
DELETE FROM shiprec where cmpy_code != "KA";
DELETE FROM shipdetl where cmpy_code != "KA";
DELETE FROM despatchhead where cmpy_code != "KA";
DELETE FROM salestrct where cmpy_code != "KA";
DELETE FROM delivmsg where cmpy_code != "KA";
DELETE FROM kandoomask where cmpy_code != "KA";
DELETE FROM postprodledg where cmpy_code != "KA";
DELETE FROM poststatus where cmpy_code != "KA";
DELETE FROM postpoaudit where cmpy_code != "KA";
DELETE FROM postfabatch where cmpy_code != "KA";
DELETE FROM postjobledger where cmpy_code != "KA";
DELETE FROM department where cmpy_code != "KA";
DELETE FROM taskperiod where cmpy_code != "KA";
DELETE FROM postcredhead where cmpy_code != "KA";
DELETE FROM tel_ects_int where cmpy_code != "KA";
DELETE FROM item_master where cmpy_code != "KA";
DELETE FROM uom_convert where cmpy_code != "KA";
DELETE FROM bor_text where cmpy_code != "KA";
DELETE FROM shop_ordhead where cmpy_code != "KA";
DELETE FROM shop_orddetl where cmpy_code != "KA";
DELETE FROM rough_demand where cmpy_code != "KA";
DELETE FROM work_center where cmpy_code != "KA";
DELETE FROM work_ctr_rate where cmpy_code != "KA";
DELETE FROM analysis where cmpy_code != "KA";
DELETE FROM bankstatement where cmpy_code != "KA";
DELETE FROM famast where cmpy_code != "KA";
DELETE FROM orderoffer where cmpy_code != "KA";
DELETE FROM statorder where cmpy_code != "KA";
DELETE FROM offerauto where cmpy_code != "KA";
DELETE FROM mtopvmst where cmpy_code != "KA";
DELETE FROM mtopterm where cmpy_code != "KA";
DELETE FROM ledgerreln where cmpy_code != "KA";
DELETE FROM consolhead where cmpy_code != "KA";
DELETE FROM consoldetl where cmpy_code != "KA";
DELETE FROM disbhead where cmpy_code != "KA";
DELETE FROM recurdetl where cmpy_code != "KA";
DELETE FROM disbdetl where cmpy_code != "KA";
DELETE FROM shipstatus where cmpy_code != "KA";
DELETE FROM termdetl where cmpy_code != "KA";
DELETE FROM postexchvar where cmpy_code != "KA";
DELETE FROM postvoucher where cmpy_code != "KA";
DELETE FROM wholdtax where cmpy_code != "KA";
DELETE FROM postwhtax where cmpy_code != "KA";
DELETE FROM tentinvhead where cmpy_code != "KA";
DELETE FROM stathead where cmpy_code != "KA";
DELETE FROM statparms where cmpy_code != "KA";
DELETE FROM stattrig where cmpy_code != "KA";
DELETE FROM statint where cmpy_code != "KA";
DELETE FROM statcond where cmpy_code != "KA";
DELETE FROM statcust where cmpy_code != "KA";
DELETE FROM statoffer where cmpy_code != "KA";
DELETE FROM statsper where cmpy_code != "KA";
DELETE FROM stattarget where cmpy_code != "KA";
DELETE FROM statterr where cmpy_code != "KA";
DELETE FROM backreas where cmpy_code != "KA";
DELETE FROM statprod where cmpy_code != "KA";
DELETE FROM statsale where cmpy_code != "KA";
DELETE FROM distterr where cmpy_code != "KA";
DELETE FROM distsper where cmpy_code != "KA";
DELETE FROM inproduction where cmpy_code != "KA";
DELETE FROM custstmnt where cmpy_code != "KA";
DELETE FROM posactlog where cmpy_code != "KA";
DELETE FROM poscacust where cmpy_code != "KA";
DELETE FROM poschqdefs where cmpy_code != "KA";
DELETE FROM poscondition where cmpy_code != "KA";
DELETE FROM posdebtmess where cmpy_code != "KA";
DELETE FROM posdocoffers where cmpy_code != "KA";
DELETE FROM poseoddetl where cmpy_code != "KA";
DELETE FROM poseodhead where cmpy_code != "KA";
DELETE FROM posmatprice where cmpy_code != "KA";
DELETE FROM posmesstext where cmpy_code != "KA";
DELETE FROM posordseq where cmpy_code != "KA";
DELETE FROM pospmnttype where cmpy_code != "KA";
DELETE FROM posscruom where cmpy_code != "KA";
DELETE FROM possegment where cmpy_code != "KA";
DELETE FROM posspoffdef where cmpy_code != "KA";
DELETE FROM posstatdev where cmpy_code != "KA";
DELETE FROM possysmess where cmpy_code != "KA";
DELETE FROM posudfdata where cmpy_code != "KA";
DELETE FROM badccnum where cmpy_code != "KA";
DELETE FROM badacnum where cmpy_code != "KA";
DELETE FROM custcond where cmpy_code != "KA";
DELETE FROM custdocket where cmpy_code != "KA";
DELETE FROM ordrateaudit where cmpy_code != "KA";
DELETE FROM prodstructure where cmpy_code != "KA";
DELETE FROM prodflex where cmpy_code != "KA";
DELETE FROM supply where cmpy_code != "KA";
DELETE FROM street where cmpy_code != "KA";
DELETE FROM orderinst where cmpy_code != "KA";
DELETE FROM orderledg where cmpy_code != "KA";
DELETE FROM ordercancel where cmpy_code != "KA";
DELETE FROM ordrates where cmpy_code != "KA";
DELETE FROM drivertype where cmpy_code != "KA";
DELETE FROM drivernote where cmpy_code != "KA";
DELETE FROM loadinst where cmpy_code != "KA";
DELETE FROM delinst where cmpy_code != "KA";
DELETE FROM rates where cmpy_code != "KA";
DELETE FROM invinst where cmpy_code != "KA";
DELETE FROM driver where cmpy_code != "KA";
DELETE FROM tranadjtype where cmpy_code != "KA";
DELETE FROM custpallet where cmpy_code != "KA";
DELETE FROM extrarates where cmpy_code != "KA";
DELETE FROM vehicle where cmpy_code != "KA";
DELETE FROM ibtload where cmpy_code != "KA";
DELETE FROM delivdetl where cmpy_code != "KA";
DELETE FROM mincartage where cmpy_code != "KA";
DELETE FROM cancelreas where cmpy_code != "KA";
DELETE FROM jmj_glacct where cmpy_code != "KA";
DELETE FROM jmj_truedebtor where cmpy_code != "KA";
DELETE FROM addcharge where cmpy_code != "KA";
DELETE FROM creditrates where cmpy_code != "KA";
DELETE FROM ordertrig where cmpy_code != "KA";
DELETE FROM prodsurcharge where cmpy_code != "KA";
DELETE FROM pospmntdet where cmpy_code != "KA";
DELETE FROM pallet where cmpy_code != "KA";
DELETE FROM tentrefund where cmpy_code != "KA";
DELETE FROM posparms where cmpy_code != "KA";
DELETE FROM posporide where cmpy_code != "KA";
DELETE FROM posscrpad where cmpy_code != "KA";
DELETE FROM poscdraw where cmpy_code != "KA";
DELETE FROM exphead where cmpy_code != "KA";
DELETE FROM expdetl where cmpy_code != "KA";
DELETE FROM poslocation where cmpy_code != "KA";
DELETE FROM cfwdaudit where cmpy_code != "KA";
DELETE FROM tentarbal where cmpy_code != "KA";
DELETE FROM orderterr where cmpy_code != "KA";
DELETE FROM uomconv where cmpy_code != "KA";
DELETE FROM labourer where cmpy_code != "KA";
DELETE FROM labourextras where cmpy_code != "KA";
DELETE FROM labourtype where cmpy_code != "KA";
DELETE FROM supervisor where cmpy_code != "KA";
DELETE FROM labournote where cmpy_code != "KA";
DELETE FROM labourtrans where cmpy_code != "KA";
DELETE FROM labouralloc where cmpy_code != "KA";
DELETE FROM suburb where cmpy_code != "KA";
DELETE FROM suburbarea where cmpy_code != "KA";
DELETE FROM labourdetl where cmpy_code != "KA";
DELETE FROM labourpays where cmpy_code != "KA";
DELETE FROM linetrig where cmpy_code != "KA";
DELETE FROM kithead where cmpy_code != "KA";
DELETE FROM kitdetl where cmpy_code != "KA";
DELETE FROM prodstatlog where cmpy_code != "KA";
DELETE FROM subdates where cmpy_code != "KA";
DELETE FROM substype where cmpy_code != "KA";
DELETE FROM subproduct where cmpy_code != "KA";
DELETE FROM ssparms where cmpy_code != "KA";
DELETE FROM subissues where cmpy_code != "KA";
DELETE FROM subdetl where cmpy_code != "KA";
DELETE FROM subschedule where cmpy_code != "KA";
DELETE FROM subcustomer where cmpy_code != "KA";
DELETE FROM tentinvdetl where cmpy_code != "KA";
DELETE FROM tentsubdetl where cmpy_code != "KA";
DELETE FROM tentsubschd where cmpy_code != "KA";
DELETE FROM subaudit where cmpy_code != "KA";
DELETE FROM dangerline where cmpy_code != "KA";
DELETE FROM creditlog where cmpy_code != "KA";
DELETE FROM bp_glreports where cmpy_code != "KA";
DELETE FROM glrephead where cmpy_code != "KA";
DELETE FROM glrepdetl where cmpy_code != "KA";
DELETE FROM glrepgroup where cmpy_code != "KA";
DELETE FROM glrepmaingrp where cmpy_code != "KA";
DELETE FROM glrepsubgrp where cmpy_code != "KA";
DELETE FROM glrepdata where cmpy_code != "KA";
DELETE FROM orderlog where cmpy_code != "KA";
DELETE FROM subhead where cmpy_code != "KA";
DELETE FROM resgrp where cmpy_code != "KA";
DELETE FROM pricepend where cmpy_code != "KA";
DELETE FROM ordohstat where cmpy_code != "KA";
DELETE FROM credheadaddr where cmpy_code != "KA";
DELETE FROM tentsubhead where cmpy_code != "KA";
DELETE FROM labourates where cmpy_code != "KA";
DELETE FROM labourline where cmpy_code != "KA";
DELETE FROM labourhead where cmpy_code != "KA";
DELETE FROM transprates where cmpy_code != "KA";
DELETE FROM transpextras where cmpy_code != "KA";
DELETE FROM vehicletype where cmpy_code != "KA";
DELETE FROM cartrates where cmpy_code != "KA";
DELETE FROM driverledger where cmpy_code != "KA";
DELETE FROM labour where cmpy_code != "KA";
DELETE FROM labourclass where cmpy_code != "KA";
DELETE FROM resbdgt where cmpy_code != "KA";
DELETE FROM postranhead where cmpy_code != "KA";
DELETE FROM postrandetl where cmpy_code != "KA";
DELETE FROM jmj_impresttran where cmpy_code != "KA";
DELETE FROM poscustprice where cmpy_code != "KA";
DELETE FROM saleshist where cmpy_code != "KA";
DELETE FROM salestrans where cmpy_code != "KA";
DELETE FROM ar1384head where cmpy_code != "KA";
DELETE FROM prochead where cmpy_code != "KA";
DELETE FROM procdetl where cmpy_code != "KA";
DELETE FROM ordlinerate where cmpy_code != "KA";
DELETE FROM invrates where cmpy_code != "KA";
DELETE FROM transitware where cmpy_code != "KA";
DELETE FROM csfgroup where cmpy_code != "KA";
DELETE FROM csfcodes where cmpy_code != "KA";
DELETE FROM salesstat where cmpy_code != "KA";
DELETE FROM pickdetl where cmpy_code != "KA";
DELETE FROM despatchdetl where cmpy_code != "KA";
DELETE FROM ordquotext where cmpy_code != "KA";
DELETE FROM quotelinerate where cmpy_code != "KA";
DELETE FROM quotecancel where cmpy_code != "KA";
DELETE FROM quotelabour where cmpy_code != "KA";
DELETE FROM csfhead where cmpy_code != "KA";
DELETE FROM csfnote where cmpy_code != "KA";
DELETE FROM stattype where cmpy_code != "KA";
DELETE FROM statware where cmpy_code != "KA";
DELETE FROM statdetl where cmpy_code != "KA";
DELETE FROM csfnote2 where cmpy_code != "KA";
DELETE FROM samtrig where cmpy_code != "KA";
DELETE FROM acctxlate where cmpy_code != "KA";
DELETE FROM asg_vouchcheq where cmpy_code != "KA";
DELETE FROM asg_invcash where cmpy_code != "KA";
DELETE FROM loadhead where cmpy_code != "KA";
DELETE FROM payparms where cmpy_code != "KA";
DELETE FROM shipcosttype where cmpy_code != "KA";
DELETE FROM ordhead where cmpy_code != "KA";
DELETE FROM ordcallfwd where cmpy_code != "KA";
DELETE FROM loadline where cmpy_code != "KA";
DELETE FROM delivhead where cmpy_code != "KA";
DELETE FROM ordquote where cmpy_code != "KA";
DELETE FROM orderstat where cmpy_code != "KA";
DELETE FROM tmpbal where cmpy_code != "KA";
DELETE FROM invheadext where cmpy_code != "KA";
DELETE FROM creditheadext where cmpy_code != "KA";
DELETE FROM quadrant where cmpy_code != "KA";
DELETE FROM custcard where cmpy_code != "KA";
DELETE FROM loaddetl where cmpy_code != "KA";
DELETE FROM contracthead where cmpy_code != "KA";
DELETE FROM orderline where cmpy_code != "KA";
DELETE FROM ordlineaudit where cmpy_code != "KA";
DELETE FROM quoteline where cmpy_code != "KA";
DELETE FROM ibthead where cmpy_code != "KA";
DELETE FROM bri_salesanalysis where cmpy_code != "KA";
DELETE FROM bri_orderanalysis where cmpy_code != "KA";
DELETE FROM reqperson where cmpy_code != "KA";
DELETE FROM orderdetlog where cmpy_code != "KA";
DELETE FROM pickhead where cmpy_code != "KA";
DELETE FROM ibtdetl where cmpy_code != "KA";
DELETE FROM reqparms where cmpy_code != "KA";
DELETE FROM postdebithead where cmpy_code != "KA";
DELETE FROM postcheque where cmpy_code != "KA";
DELETE FROM tenthead where cmpy_code != "KA";
DELETE FROM postaptrans where cmpy_code != "KA";
DELETE FROM reqdetl where cmpy_code != "KA";
DELETE FROM addrates where cmpy_code != "KA";
DELETE FROM notionrates where cmpy_code != "KA";
DELETE FROM groupstat where cmpy_code != "KA";
DELETE FROM postcashrcpt where cmpy_code != "KA";
DELETE FROM pospmnts where cmpy_code != "KA";
DELETE FROM contractdate where cmpy_code != "KA";
DELETE FROM services where cmpy_code != "KA";
DELETE FROM contractdetl where cmpy_code != "KA";
DELETE FROM postinvhead where cmpy_code != "KA";
DELETE FROM cont_trans where cmpy_code != "KA";
DELETE FROM depositor where cmpy_code != "KA";
DELETE FROM jrb_movement where cmpy_code != "KA";
DELETE FROM serialinfo where cmpy_code != "KA";
DELETE FROM batch where cmpy_code != "KA";
DELETE FROM orderaccounts where cmpy_code != "KA";
DELETE FROM slaccruals where cmpy_code != "KA";
DELETE FROM extrastext where cmpy_code != "KA";
DELETE FROM orderaudit where cmpy_code != "KA";
DELETE FROM loadxref where cmpy_code != "KA";
DELETE FROM loadstatus where cmpy_code != "KA";
DELETE FROM prodinfo where cmpy_code != "KA";
DELETE FROM driverdetl where cmpy_code != "KA";
DELETE FROM kandoomemo where cmpy_code != "KA";
DELETE FROM vouchpayee where cmpy_code != "KA";
DELETE FROM rate where cmpy_code != "KA";
DELETE FROM jmpo_description where cmpy_code != "KA";
DELETE FROM productapn where cmpy_code != "KA";
DELETE FROM productkey where cmpy_code != "KA";
DELETE FROM postcontra where cmpy_code != "KA";
DELETE FROM postreceipt where cmpy_code != "KA";
DELETE FROM postpayment where cmpy_code != "KA";
DELETE FROM postcredit where cmpy_code != "KA";
DELETE FROM postdebit where cmpy_code != "KA";
DELETE FROM postexchange where cmpy_code != "KA";
DELETE FROM postasset where cmpy_code != "KA";
DELETE FROM postinvoice where cmpy_code != "KA";
DELETE FROM postjobledg where cmpy_code != "KA";
DELETE FROM postpurchase where cmpy_code != "KA";
DELETE FROM postinventory where cmpy_code != "KA";
DELETE FROM postvouch where cmpy_code != "KA";
DELETE FROM posttaxwh where cmpy_code != "KA";
DELETE FROM wwwparms where cmpy_code != "KA";
DELETE FROM stnd_inv where cmpy_code != "KA";
DELETE FROM stnd_parms where cmpy_code != "KA";
DELETE FROM creditdetl where cmpy_code != "KA";
DELETE FROM kitserial where cmpy_code != "KA";
DELETE FROM mbparms where cmpy_code != "KA";
DELETE FROM rptargs where cmpy_code != "KA";
DELETE FROM rptcolgrp where cmpy_code != "KA";
DELETE FROM rptlinegrp where cmpy_code != "KA";
DELETE FROM exthead where cmpy_code != "KA";
DELETE FROM orderhead where cmpy_code != "KA";
DELETE FROM notes where cmpy_code != "KA";
DELETE FROM voucherpays where cmpy_code != "KA";
DELETE FROM backup where cmpy_code != "KA";
DELETE FROM invstory where cmpy_code != "KA";
DELETE FROM customerhist where cmpy_code != "KA";
DELETE FROM specialprice where cmpy_code != "KA";
DELETE FROM invoicenote where cmpy_code != "KA";
DELETE FROM postrun where cmpy_code != "KA";
DELETE FROM reportdetl where cmpy_code != "KA";
DELETE FROM validflex where cmpy_code != "KA";
DELETE FROM assets where cmpy_code != "KA";
DELETE FROM reporthead where cmpy_code != "KA";
DELETE FROM vendorinvs where cmpy_code != "KA";
DELETE FROM deprhead where cmpy_code != "KA";
DELETE FROM deprdetl where cmpy_code != "KA";
DELETE FROM prodnote where cmpy_code != "KA";
DELETE FROM ordernote where cmpy_code != "KA";
DELETE FROM vendorhist where cmpy_code != "KA";
DELETE FROM jobledger where cmpy_code != "KA";
DELETE FROM vouchernote where cmpy_code != "KA";
DELETE FROM purchnote where cmpy_code != "KA";
DELETE FROM job_desc where cmpy_code != "KA";
DELETE FROM act_desc where cmpy_code != "KA";
DELETE FROM responsible where cmpy_code != "KA";
DELETE FROM actiunit where cmpy_code != "KA";
DELETE FROM jobvars where cmpy_code != "KA";
DELETE FROM ts_head where cmpy_code != "KA";
DELETE FROM person where cmpy_code != "KA";
DELETE FROM prodhist where cmpy_code != "KA";
DELETE FROM bankdraft where cmpy_code != "KA";
DELETE FROM vouchporcphdr where cmpy_code != "KA";
DELETE FROM purchrcphdr where cmpy_code != "KA";
DELETE FROM prodmfg where cmpy_code != "KA";
DELETE FROM bor where cmpy_code != "KA";
DELETE FROM configuration where cmpy_code != "KA";
DELETE FROM mnparms where cmpy_code != "KA";
DELETE FROM mfgdept where cmpy_code != "KA";
DELETE FROM workcentre where cmpy_code != "KA";
DELETE FROM workctrrate where cmpy_code != "KA";
DELETE FROM uomconvert where cmpy_code != "KA";
DELETE FROM shopordhead where cmpy_code != "KA";
DELETE FROM shoporddetl where cmpy_code != "KA";
DELETE FROM mps where cmpy_code != "KA";
DELETE FROM mrp where cmpy_code != "KA";
DELETE FROM mpsdemand where cmpy_code != "KA";
DELETE FROM calendar where cmpy_code != "KA";
DELETE FROM wipreceipt where cmpy_code != "KA";
DELETE FROM recshorddetl where cmpy_code != "KA";
DELETE FROM recshordhead where cmpy_code != "KA";
DELETE FROM acctgrp where cmpy_code != "KA";
DELETE FROM acctgrpdetl where cmpy_code != "KA";
DELETE FROM rpthead_group where cmpy_code != "KA";
DELETE FROM supported_products where cmpy_code != "KA";
DELETE FROM prodgrp where cmpy_code != "KA";
DELETE FROM tentbankhead where cmpy_code != "KA";
DELETE FROM cartarea where cmpy_code != "KA";
DELETE FROM class where cmpy_code != "KA";
--DELETE FROM prodattribute where cmpy_code != "KA";
DELETE FROM conddisc where cmpy_code != "KA";
DELETE FROM condsale where cmpy_code != "KA";
DELETE FROM credreas where cmpy_code != "KA";
DELETE FROM grant_deny_access where cmpy_code != "KA";
DELETE FROM holdpay where cmpy_code != "KA";
DELETE FROM holdreas where cmpy_code != "KA";
DELETE FROM htmlparms where cmpy_code != "KA";
DELETE FROM inparms where cmpy_code != "KA";
DELETE FROM ipparms where cmpy_code != "KA";
DELETE FROM jmj_debttype where cmpy_code != "KA";
DELETE FROM journal where cmpy_code != "KA";
DELETE FROM company where cmpy_code != "KA";
DELETE FROM kandoouser where cmpy_code != "KA";
DELETE FROM kandoousercmpy where cmpy_code != "KA";
DELETE FROM labeldetl where cmpy_code != "KA";
DELETE FROM labelhead where cmpy_code != "KA";
DELETE FROM loadparms where cmpy_code != "KA";
DELETE FROM maingrp where cmpy_code != "KA";
DELETE FROM opparms where cmpy_code != "KA";
DELETE FROM period where cmpy_code != "KA";
DELETE FROM proddept where cmpy_code != "KA";
DELETE FROM tax where cmpy_code != "KA";
DELETE FROM purchtype where cmpy_code != "KA";
DELETE FROM qpparms where cmpy_code != "KA";
DELETE FROM rate_exchange where cmpy_code != "KA";
DELETE FROM rmsparm where cmpy_code != "KA";
--DELETE FROM prodstatusnew where cmpy_code != "KA";
DELETE FROM salearea where cmpy_code != "KA";
DELETE FROM stateinfo where cmpy_code != "KA";
DELETE FROM stnd_grp where cmpy_code != "KA";
DELETE FROM term where cmpy_code != "KA";
DELETE FROM transptype where cmpy_code != "KA";
DELETE FROM user_cmpy where cmpy_code != "KA";
DELETE FROM userlimits where cmpy_code != "KA";
DELETE FROM userlocn where cmpy_code != "KA";
DELETE FROM usermsg where cmpy_code != "KA";
DELETE FROM proddanger where cmpy_code != "KA";
DELETE FROM ingroup where cmpy_code != "KA";
DELETE FROM service_request where cmpy_code != "KA";
DELETE FROM structure where cmpy_code != "KA";
DELETE FROM uom where cmpy_code != "KA";
DELETE FROM customeraudit where cmpy_code != "KA";
DELETE FROM contractor where cmpy_code != "KA";
DELETE FROM debithead where cmpy_code != "KA";
DELETE FROM vendorgrp where cmpy_code != "KA";
DELETE FROM arparms where cmpy_code != "KA";
DELETE FROM bank where cmpy_code != "KA";
DELETE FROM bestsells where cmpy_code != "KA";
DELETE FROM cartage where cmpy_code != "KA";
DELETE FROM cashreceipt where cmpy_code != "KA";
DELETE FROM cheque where cmpy_code != "KA";
DELETE FROM custoffer where cmpy_code != "KA";
DELETE FROM customer where cmpy_code != "KA";
DELETE FROM customership where cmpy_code != "KA";
DELETE FROM customertype where cmpy_code != "KA";
DELETE FROM fundaudit where cmpy_code != "KA";
DELETE FROM fundsapproved where cmpy_code != "KA";
DELETE FROM invoicehead where cmpy_code != "KA";
DELETE FROM invoicepay where cmpy_code != "KA";
DELETE FROM kandooprofile where cmpy_code != "KA";
DELETE FROM location where cmpy_code != "KA";
DELETE FROM stnd_custgrp where cmpy_code != "KA";
DELETE FROM tentbankdetl where cmpy_code != "KA";
DELETE FROM territory where cmpy_code != "KA";
DELETE FROM vendor where cmpy_code != "KA";
DELETE FROM apparms where cmpy_code != "KA";
DELETE FROM araudit where cmpy_code != "KA";
DELETE FROM arparmext where cmpy_code != "KA";
DELETE FROM carrier where cmpy_code != "KA";
DELETE FROM category where cmpy_code != "KA";
DELETE FROM customerpart where cmpy_code != "KA";
DELETE FROM glparms where cmpy_code != "KA";
DELETE FROM invoicedetl where cmpy_code != "KA";
DELETE FROM jmj_trantype where cmpy_code != "KA";
DELETE FROM kandoomodule where cmpy_code != "KA";
DELETE FROM nextnumber where cmpy_code != "KA";
DELETE FROM posstation where cmpy_code != "KA";
DELETE FROM pricing where cmpy_code != "KA";
DELETE FROM proddisc where cmpy_code != "KA";
DELETE FROM prodledg where cmpy_code != "KA";
DELETE FROM prodstatus where cmpy_code != "KA";
DELETE FROM product where cmpy_code != "KA";
DELETE FROM recurhead where cmpy_code != "KA";
DELETE FROM resbill where cmpy_code != "KA";
DELETE FROM salesmgr where cmpy_code != "KA";
DELETE FROM salesperson where cmpy_code != "KA";
DELETE FROM vendortype where cmpy_code != "KA";
DELETE FROM waregrp where cmpy_code != "KA";
DELETE FROM warehouse where cmpy_code != "KA";
DELETE FROM customernote where cmpy_code != "KA";
DELETE FROM t_batchdetl where cmpy_code != "KA";
DELETE FROM vendornote where cmpy_code != "KA";
DELETE FROM prodadjtype where cmpy_code != "KA";
DELETE FROM rmsreps where cmpy_code != "KA";
DELETE FROM groupinfo where cmpy_code != "KA";
--DELETE FROM coa_new where cmpy_code != "KA";
DELETE FROM vendoraudit where cmpy_code != "KA";
DELETE FROM coa where cmpy_code != "KA";
delete from invoicedetl where line_acct_code||cmpy_code  in (select  line_acct_code||cmpy_code from invoicedetl where line_acct_code||cmpy_code not in ( select  acct_code||cmpy_code from coa ));
delete from prodledg where  acct_code||year_num||cmpy_code in (
select acct_code||year_num||cmpy_code from prodledg where acct_code||year_num||cmpy_code not in ( select acct_code||year_num||cmpy_code from account ));
