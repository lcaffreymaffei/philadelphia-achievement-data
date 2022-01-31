//importing PSSA file, keeping only science data, converting percentages into decimal format, calculating number scored per grade
	doedit "Y:\Data and Analytics\GPS Data Uploads\2019\Public Schools\ELA PSSA 2018-19.do" 
	import excel "C:\Users\Lucy Caffrey Maffei\Downloads\2019 PSSA School Level Data.xlsx", sheet("PSSA website") firstrow case(lower)
	rename schoolnumber pacode
	drop districtname
	drop if grade == "Total"
	replace group = "_all" if group == "All Students"
	replace group = "_hu" if group == "Historically Underperforming"
	keep if subject == "Science"
	drop subject
	destring grade, force replace
	replace percentadvanced = percentadvanced/100
	replace percentproficient = percentproficient/100
	replace percentbasic = percentbasic/100
	replace percentbelowbasic = percentbelowbasic/100
	gen numberadv = percentadvanced *numberscored
	gen numberprof = percentproficient *numberscored
	gen numberbasic = percentbasic *numberscored
	gen numberbb = percentbelowbasic *numberscored
	drop percentadvanced percentproficient percentbasic percentbelowbasic
	destring pacode, force replace
	tempfile sciencepssa
	save `sciencepssa'
	clear

//importing GPS record of public schools, reshaping and cleaning to be compatible with pssa file
	import excel "Y:\Data and Analytics\GPS Data Uploads\2019\Public Schools\2018-19 Public Schools - GPS Records.xlsx", sheet("Sheet1") firstrow case(lower)
	replace gradesserved = subinstr(gradesserved, "Pre-K (3-4 years old)", "13",.)
	replace gradesserved = subinstr(gradesserved, "K", "0",.)
	split gradesserved, p(";")
	destring gradesserved1-gradesserved13, force replace
	forvalues i = 0/13 {
	gen grade_`i'=.
	}
	forvalues i = 0/13{
	foreach v of varlist gradesserved1-gradesserved13{
	replace grade_`i' = 1 if `v' == `i'
	}
	}
	drop gradesserved1-gradesserved13
	reshape long grade_, i( pspid-gradesserved) j(gradeserved)
	drop if missing(grade_)
	rename gradeserved grade
	keep if grade == 4 | grade == 8
	drop grade_
	gen group1 = "_all"
	gen group2 = "_hu"
	reshape long group, i( pspid pacode aun schoolname  accountid unpublishedid gradesserved grade) j(l)
	drop l

//merging pssa file onto gps record, calculating % of students in each grade that tested in each proficiency band
	merge m:1 pacode grade group using `sciencepssa'
	list schoolname grade if _merge ==1
	drop if _merge ==2 | _merge ==1
	drop county _merge
	reshape wide numberscored numberadv numberprof numberbasic numberbb, i(pspid pacode aun schoolname accountid unpublishedid gradesserved year group) j(grade)
	reshape wide numberscored4-numberbb8 , i(pspid pacode aun schoolname year accountid unpublishedid gradesserved) j(group)s
	gen pctadv4 = numberadv4_all/ numberscored4_all*100
	gen pctadv8 = numberadv8_all/ numberscored8_all*100
	gen pctprof4 = numberprof4_all/ numberscored4_all*100
	gen pctprof8 = numberprof8_all/ numberscored8_all*100
	gen pctbasic4 = numberbasic4_all/ numberscored4_all*100
	gen pctbasic8 = numberbasic8_all/ numberscored8_all*100
	gen pctbb4 = numberbb4_all/ numberscored4_all*100
	gen pctbb8 = numberbb8_all/ numberscored8_all*100

//generating % of students at school level that tested into each proficiency band (both groups of students -- all and historically underperforming)
	egen numberscored_all = rowtotal( numberscored4_all numberscored8_all)
	egen numberscored_hu = rowtotal( numberscored4_hu numberscored8_hu)
	egen numberadv_all = rowtotal(numberadv4_all numberadv8_all)
	gen pctadv_all = numberadv_all/numberscored_all*100
	drop numberadv_all
	egen numberprof_all = rowtotal(numberprof4_all numberprof8_all)
	gen pctprof_all = numberprof_all/numberscored_all *100
	drop numberprof_all
	egen numberbasic_all = rowtotal(numberbasic4_all numberbasic8_all)
	gen pctbasic_all = numberbasic_all/numberscored_all*100
	drop numberbasic_all
	egen numberbb_all=rowtotal(numberbb4_all numberbb8_all)
	gen pctbb_all = numberbb_all/numberscored_all*100
	drop numberbb_all
	egen numberadv_hu = rowtotal(  numberadv4_hu numberadv8_hu)
	gen pctadv_hu = numberadv_hu/numberscored_hu*100
	drop numberadv_hu
	egen numberprof_hu = rowtotal(numberprof4_hu numberprof8_hu)
	gen pctprof_hu = numberprof_hu/numberscored_hu*100
	drop numberprof_hu
	egen numberbasic_hu = rowtotal ( numberbasic4_hu numberbasic8_hu)
	gen pctbasic_hu = numberbasic_hu/numberscored_hu*100
	drop numberbasic_hu
	egen numberbb_hu = rowtotal( numberbb4_hu  numberbb8_hu)
	gen pctbb_hu = numberbb_hu/numberscored_hu*100
	drop numberbb_hu

//double checking no calculation error
	tab schoolname if pctadv4==0 & numberadv4_all !=0
	tab schoolname if pctadv8==0 & numberadv8_all !=0
	tab schoolname if pctprof4 ==0 & numberprof4_all !=0
	tab schoolname if pctprof8 ==0 & numberprof8_all !=0
	tab schoolname if pctbasic4 ==0 & numberbasic4_all !=0
	tab schoolname if pctbasic8 ==0 & numberbasic8_all !=0
	tab schoolname if pctbb4 ==0 & numberbb4_all !=0
	tab schoolname if pctbb8 ==0 & numberbb8_all !=0

//replacing any zeros with missing values where zeros were inappropriately placed because of egen function
	replace pctadv_all = . if  numberadv4_all == . &  numberadv8_all ==.
	replace pctprof_all = . if numberprof4_all == . & numberprof8_all ==.
	replace pctbasic_all = . if numberbasic4_all == . & numberbasic8_all ==.
	replace pctbb_all = . if  numberbb4_all == . & numberbb8_all ==.
	replace pctadv_hu = . if numberadv4_hu == . & numberadv8_hu ==.
	replace pctprof_hu = . if numberprof4_hu == . & numberprof8_hu==.
	replace pctbasic_hu = . if numberbasic4_hu == . & numberbasic8_hu ==.
	replace pctbb_hu = . if  numberbb4_hu == . & numberbb8_hu ==.

//creating string variables with one decimal place for each of the upload fields. generating state advanced/proficient average
	gen pctadv4_new = string(pctadv4, "%2.1f")
	gen pctadv8_new = string(pctadv8, "%2.1f")
	gen pctprof4_new = string(pctprof4, "%2.1f")
	gen pctprof8_new = string(pctprof8, "%2.1f")
	gen pctbasic4_new = string(pctbasic4, "%2.1f")
	gen pctbasic8_new = string(pctbasic8, "%2.1f")
	gen pctbb4_new = string(pctbb4, "%2.1f")
	gen pctbb8_new = string(pctbb8, "%2.1f")
	gen pctadv_all_new = string( pctadv_all, "%2.1f")
	gen pctprof_all_new = string( pctprof_all, "%2.1f")
	gen pctbasic_all_new = string( pctbasic_all, "%2.1f")
	gen pctbb_all_new = string( pctbb_all, "%2.1f")
	gen pctadv_hu_new = string( pctadv_hu, "%2.1f")
	gen pctprof_hu_new = string( pctprof_hu, "%2.1f")
	gen pctbasic_hu_new = string( pctbasic_hu, "%2.1f")
	gen pctbb_hu_new = string( pctbb_hu, "%2.1f")
	drop pctadv4-pctbb8 pctadv_all-pctbb_hu
	rename *_new *
	gen stateprofadv = "68" if pctadv_all!= "." & pctprof_all!="."
