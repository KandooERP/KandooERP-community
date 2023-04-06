# perl ffg.pl -database leres -project BegoodenLIMS_Lycia -program p_parametres -modulegen parametres -moduletemplate standalone_standard.mtplt  -formuse f_param.fm2 ' generates one program parsing one form
# perl ffg.pl -database leres -project BegoodenLIMS_Lycia -formtable parametre -formtemplate CoordPanelStandaloneForm.ftplt -formgen f_param.fm2 -program p_parametres -modulegen parametres -moduletemplate standalone_standard.mtplt -formlookup  # generates one form then the relevant program
# perl ffg.pl -database leres -project BegoodenLIMS_Lycia  -formuse f_param.fm2 -program p_parametres -modulegen parametres -moduletemplate standalone_standard.mtplt -formlookup
# perl ffg.pl -database stores_demo -project fgldemo -program orders -modulegen orders -moduletemplate parent_standard.mtplt  -formuse orderform.fm2 ' generates one program parsing one form
# perl -d ffg.pl -database maxdev -project MaiaERP -program COA -modulegen z_tb_coa  -moduletemplate standalone_standard.mtplt  -formuse f_coa_g.fm2 -primaryk "cmpy_code,acct_code"
-database maxdev -project MaiaERP -program SRVRQ -modulegen srvrq  -moduletemplate standalone_standard.mtplt  -formuse f_service_request.fm2 

perl -d ffg.pl -database kandoodb -project KandooERP -program test -modulegen z_test  -moduletemplate standalone_standard.mtplt  -formuse f_coa_g.fm2 -primaryk "cmpy_code,acct_code"

perl I:\Users\BeGooden-IT\git\KandooERP\KandooERP\Resources\Utilities\Perl\Ffg\ffg.pl -database kandoodb -project kandoo_with_ffg  -formuse f_service_request.fm2 -maintemplate standalone-form-basic.mtplt  -program test_SR -modulegen test_sr

perl I:\Users\BeGooden-IT\git\KandooERP\KandooERP\Resources\Utilities\Perl\Ffg\ffg.pl -database kandoodb -project kandoo_with_ffg  -formtemplate GridPanelStandaloneForm.ftplt -maintemplate standalone-form-basic.mtplt  -formtable coa