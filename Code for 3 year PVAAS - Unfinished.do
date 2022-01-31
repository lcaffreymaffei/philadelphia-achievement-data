import excel "Z:\Data and Analytics\GPS Data Uploads\2019\Public Schools\Raw Data\2018-19 Public Schools - GPS Records.xlsx", sheet("Sheet1") firstrow case(lower)
rename schoolname schoolname_master
tempfile master_file
save `master_file'


import excel "Z:\Data and Analytics\Assessments\PVAAS\2019-1yr-3yr-PVAAS-AGIs-w-GrMeasure-School.xlsx", sheet("2019-1yr-3yr-PVAAS-AGIs-w-GrMea") firstrow case(lower) clear
keep if grade=="4-8" | grade=="N/A"
drop if schoolyear =="2018-2019"
drop averagegrowthindexagi agicolor
drop iunumber districtaun districtname schoolyear
drop if subject=="Biology"
replace subject="Alg_1" if subject=="Algebra I"
replace subject="ela" if subject=="English Language Arts"
drop gradespan
drop test
rename stderrorofgrowthmeasure sde
rename growthmeasure measure
reshape wide measure sde, i( schoolnumber schoolname) j( subject)s
destring schoolnumber, force replace
rename schoolnumber pacode
merge 1:m pacode using `master_file'

keep if _merge==3
drop _merge
unique pacode
gen high="yes" if strpos(gradesserved, "9")
replace high="yes" if strpos(gradesserved, "10")
replace high="yes" if strpos(gradesserved, "11")
replace high="yes" if strpos(gradesserved, "12")
gen elm="yes" if strpos(gradesserved, "8")
replace elm="yes" if strpos(gradesserved, "7")
replace elm="yes" if strpos(gradesserved, "6")
replace elm="yes" if strpos(gradesserved, "5")
replace elm="yes" if strpos(gradesserved, "4")
replace elm="yes" if strpos(gradesserved, "3")
replace measureAlg_1=. if mi( high)
replace sdeAlg_1 =. if mi( high)
replace measureLiterature=. if mi( high)
replace sdeLiterature=. if mi( high)

replace measureMath=. if mi( elm)
replace sdeMath=. if mi( elm)
replace measureela=. if mi( elm)
replace sdeela=. if mi( elm)

*drop nothereast HS
drop if pspid ==13304
gen simple_math=(( measureAlg_1/ sdeMath)+ (measureAlg_1/ sdeMath))/2
gen math_se_combo=sqrt((.25*( sdeAlg_1^2))+(.25*( sdeMath^2)))
gen math_mean_pvaas=(( measureMath +measureAlg_1)/2)/ math_se_combo
gen read_se_combo=sqrt((.25*( sdeela^2))+(.25*( sdeLiterature^2)))
gen read_mean_pvaas=(( measureela +measureLiterature)/2)/ read_se_combo
gen simple_read=(( measureLiterature/ sdeLiterature)+ (measureela/ sdeela))/2
gen in_with_simple="Yes" if simple_math >=2 & simple_read >=2
gen in_with_eq="Yes" if math_mean_pvaas>=2 & read_mean_pvaas>=2
gen pssa_read=(measureela/ sdeela)
gen Lit_read=( measureLiterature/ sdeLiterature)
gen pssa_math=(measureMath/ sdeMath)
gen keystone_math=(measureAlg_1 / sdeAlg_1 )
gen HG="Yes" if keystone_math >=2 & !mi(keystone_math)& Lit_read >=2 & !mi(Lit_read)& mi( math_mean_pvaas)
replace HG="Yes" if pssa_math>=2 & !mi(pssa_math) & pssa_read>=2 &!mi(pssa_read) & mi( math_mean_pvaas)
replace HG=in_with_eq if !mi( math_mean_pvaas)