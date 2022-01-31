import delimited "Y:\Data and Analytics\GPS Data Uploads\2019\Public Schools\Raw Data\2018-19 Public Schools - GPS Records.csv", bindquote(strict) varnames(1)
replace gradesserved = subinstr( gradesserved,"Pre-K (3-4 years old)","0",.)
gen em = 1 if strpos(gradesserved ,"4") | strpos(gradesserved ,"5") | strpos(gradesserved ,"6") | strpos(gradesserved ,"7") | strpos(gradesserved ,"8")
gen hs = 1 if strpos(gradesserved ,"9") | strpos(gradesserved ,"10") | strpos(gradesserved ,"11") | strpos(gradesserved ,"12")
gen emhs = 1 if !mi(em) & !mi(hs)
tempfile publicschools
save `publicschools'
clear

import excel "Y:\Data and Analytics\Assessments\PVAAS\2019-1yr-3yr-PVAAS-AGIs-w-GrMeasure-School.xlsx", sheet("2019-1yr-3yr-PVAAS-AGIs-w-GrMea") firstrow case(lower)
keep if gradespan == "4-8" | subject =="Science" | gradespan =="N/A"
keep if schoolyear =="2018-2019 Three-Year-Average"
drop agicolor districtname districtaun iunumber
rename averagegrowthindexagi agi
rename schoolnumber pacode
rename stderrorofgrowthmeasure stde
destring pacode, force replace
replace subject ="_ela" if subject=="English Language Arts"
replace subject ="_math" if subject=="Math"
replace subject ="_science" if subject=="Science"
replace subject ="_alg" if subject=="Algebra I"
replace subject ="_bio" if subject=="Biology"
replace subject ="_lit" if subject=="Literature"
replace gradespan = "4_8" if gradespan =="4-8"
replace gradespan = "_"+gradespan
replace gradespan="" if gradespan =="_N/A"
gen subjectgrade = subject+gradespan
drop subject gradespan schoolyear test
reshape wide agi growthmeasure stde ,i(pacode schoolname) j(subjectgrade )s
tempfile agi
save `agi'
clear

use `publicschools'
merge m:1 pacode using `agi'
keep if _merge==3
drop _merge
sort schoolname pacode
replace agi_alg =. if mi(hs)
replace growthmeasure_alg =. if mi(hs)
replace stde_alg =. if mi(hs)

replace agi_bio =. if mi(hs)
replace growthmeasure_bio =. if mi(hs)
replace stde_bio =. if mi(hs)

replace agi_lit =. if mi(hs)
replace growthmeasure_lit =. if mi(hs)
replace stde_lit =. if mi(hs)

replace agi_ela_4_8 =. if mi(em)
replace growthmeasure_ela_4_8 =. if mi(em)
replace stde_ela_4_8 =. if mi(em)
replace agi_math_4_8 =. if mi(em)
replace growthmeasure_math_4_8 =. if mi(em)
replace stde_math_4_8 =. if mi(em)
replace agi_science_4 =. if mi(em)
replace growthmeasure_science_4 =. if mi(em)
replace stde_science_4 =. if mi(em)
replace agi_science_8 =. if mi(em)
replace growthmeasure_science_8 =. if mi(em)
replace stde_science_8 =. if mi(em)

gen compgain_english=(0.5* growthmeasure_ela)+ (0.5* growthmeasure_lit)
gen mrmse_english = sqrt( (((1/2)^2)* (stde_ela^2)) +(((1/2)^2)* ( stde_lit ^2)))
gen aggregateagi_english = compgain_english /mrmse_english
gen compgain_math=(0.5* growthmeasure_alg )+ (0.5* growthmeasure_math )
gen mrmse_math = sqrt( (((1/2)^2)* ( stde_math ^2)) +(((1/2)^2)* ( stde_alg ^2)))
gen aggregateagi_math = compgain_math /mrmse_math

gen highgrowth = 1 if mi(emhs) & !mi(agi_ela_4_8) & !mi( agi_math_4_8) & agi_ela_4_8 >=2 & agi_math_4_8 >=2
replace highgrowth = 1 if mi(emhs) & !mi( agi_alg ) & !mi( agi_lit ) & agi_alg >=2 & agi_lit >=2
replace highgrowth = 1 if aggregateagi_english >=2 & aggregateagi_math >=2 & !mi(aggregateagi_english ) & !mi(aggregateagi_math )
