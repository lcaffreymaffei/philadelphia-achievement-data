import excel "Y:\Data and Analytics\GPS Data Uploads\2019\Public Schools\2019 Keystone Exams School Level Data.xlsx", sheet("Sheet1") firstrow case(lower)
rename schoolnumber pacode
destring pacode, force replace
keep if subject == "Literature"
drop subject
drop grade
replace group = "_all" if group == "All Students"
replace group = "_hu" if group == "Historically Underperforming"
tempfile keystonelit
save `keystonelit'
clear

import excel "Y:\Data and Analytics\GPS Data Uploads\2019\Public Schools\2018-19 Public Schools - GPS Records.xlsx", sheet("Sheet1") firstrow case(lower)
gen group1 = "_all"
gen group2 = "_hu"
gen achievementname = "18-19 Achiev. - "+schoolname
reshape long group, i( pspid pacode aun schoolname achievementname accountid unpublishedid gradesserved) j(l)
drop l
gen keep = 0
replace keep = 1 if strpos(gradesserved, "9") | strpos(gradesserved, "10;") | strpos(gradesserved, "11;") | strpos(gradesserved, "12;")
keep if keep == 1
drop keep
tempfile salesforcekeystonelit
save `salesforcekeystonelit'

merge m:1 pacode group using `keystonelit'
list schoolname grade if _merge ==1
drop if _merge == 1 | _merge == 2
drop county districtname _merge
reshape wide numberscored percentadvanced percentproficient percentbasic percentbelowbasic , i(pspid pacode aun schoolname achievementname accountid unpublishedid gradesserved) j(group)s
gen keystoneupdated = "10/24/2019"
gen stateprofadv = 71.5
gen stateprofadv_new = string(stateprofadv, "%2.1f")
drop stateprofadv
rename stateprofadv_new stateprofadv
drop if schoolname == "Northeast Medical, Engineering, & Aerospace Magnet"
