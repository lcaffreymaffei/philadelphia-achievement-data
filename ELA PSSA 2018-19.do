//importing PSSA file & keeping only ELA data
	import excel "C:\Users\Lucy Caffrey Maffei\Downloads\2019 PSSA School Level Data.xlsx", sheet("PSSA website") firstrow case(lower)
	rename schoolnumber pacode
	drop districtname
	drop if grade == "Total"
	replace group = "_all" if group == "All Students"
	replace group = "_hu" if group == "Historically Underperforming"
	keep if subject == "English Language Arts"
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
	tempfile elapssa
	save `elapssa'
	clear

//formatting GPS record of schools to merge with PSSA file
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
	drop if grade == 0 | grade == 1 | grade == 2 | grade == 9 | grade == 10 | grade == 11 | grade == 12 | grade == 13
	drop grade_
	gen group1 = "_all"
	gen group2 = "_hu"
	gen achievementname = "18-19 Achiev. - "+schoolname
	reshape long group, i( pspid pacode aun schoolname achievementname accountid unpublishedid gradesserved grade) j(l)
	drop l
	tempfile sfelapssa
	save `sfelapssa'

//merging GPS records with ELA PSSA and reshaping it wide
	merge m:1 pacode grade group using `elapssa'
	list schoolname grade if _merge ==1
	drop if _merge ==2 | _merge ==1
	drop county _merge
	reshape wide numberscored numberadv numberprof numberbasic numberbb, i(pspid pacode aun schoolname achievementname accountid unpublishedid gradesserved year group) j(grade)
	reshape wide numberscored3-numberbb8 , i(pspid pacode aun schoolname achievementname year accountid unpublishedid gradesserved) j(group)s

//creating weighted percentages of the performance bands based on number of kids tested in each grade. we do this because we split some schools differently (by grade level) than the state
// does so in order to accurately reflect the performance of the grades served in a particular school building, we be able to group performance at our defined levels
	gen pctadv3 = numberadv3_all/ numberscored3_all*100
	gen pctadv4 = numberadv4_all/ numberscored4_all*100
	gen pctadv5 = numberadv5_all/ numberscored5_all*100
	gen pctadv6 = numberadv6_all/ numberscored6_all*100
	gen pctadv7 = numberadv7_all/ numberscored7_all*100
	gen pctadv8 = numberadv8_all/ numberscored8_all*100
	gen pctprof3 = numberprof3_all/ numberscored3_all*100
	gen pctprof4 = numberprof4_all/ numberscored4_all*100
	gen pctprof5 = numberprof5_all/ numberscored5_all*100
	gen pctprof6 = numberprof6_all/ numberscored6_all*100
	gen pctprof7 = numberprof7_all/ numberscored7_all*100
	gen pctprof8 = numberprof8_all/ numberscored8_all*100
	gen pctbasic3 = numberbasic3_all/ numberscored3_all*100
	gen pctbasic4 = numberbasic4_all/ numberscored4_all*100
	gen pctbasic5 = numberbasic5_all/ numberscored5_all*100
	gen pctbasic6 = numberbasic6_all/ numberscored6_all*100
	gen pctbasic7 = numberbasic7_all/ numberscored7_all*100
	gen pctbasic8 = numberbasic8_all/ numberscored8_all*100
	gen pctbb3 = numberbb3_all/ numberscored3_all*100
	gen pctbb4 = numberbb4_all/ numberscored4_all*100
	gen pctbb5 = numberbb5_all/ numberscored5_all*100
	gen pctbb6 = numberbb6_all/ numberscored6_all*100
	gen pctbb7 = numberbb7_all/ numberscored7_all*100
	gen pctbb8 = numberbb8_all/ numberscored8_all*100


// generating the total number of students scored in each grouping and then the percentage of students scoring in each of the performance bands
	egen numberscored_all = rowtotal( numberscored3_all numberscored4_all numberscored5_all numberscored6_all numberscored7_all numberscored8_all)
	egen numberscored_hu = rowtotal(numberscored3_hu numberscored4_hu numberscored5_hu numberscored6_hu numberscored7_hu numberscored8_hu)
	egen pctprofadv3 = rowtotal( pctadv3 pctprof3)
	egen numberadv_all = rowtotal(numberadv3_all numberadv4_all numberadv5_all numberadv6_all numberadv7_all numberadv8_all)
	gen pctadv_all = numberadv_all/numberscored_all*100
	drop numberadv_all
	egen numberprof_all = rowtotal( numberprof3_all numberprof4_all numberprof5_all numberprof6_all numberprof7_all numberprof8_all)
	gen pctprof_all = numberprof_all/numberscored_all *100
	drop numberprof_all
	egen numberbasic_all = rowtotal( numberbasic3_all numberbasic4_all numberbasic5_all numberbasic6_all numberbasic7_all numberbasic8_all)
	gen pctbasic_all = numberbasic_all/numberscored_all*100
	drop numberbasic_all
	egen numberbb_all=rowtotal( numberbb3_all numberbb4_all numberbb5_all numberbb6_all numberbb7_all numberbb8_all)
	gen pctbb_all = numberbb_all/numberscored_all*100
	drop numberbb_all
	egen numberadv_hu = rowtotal( numberadv3_hu numberadv4_hu numberadv5_hu numberadv6_hu numberadv7_hu numberadv8_hu)
	gen pctadv_hu = numberadv_hu/numberscored_hu*100
	drop numberadv_hu
	egen numberprof_hu = rowtotal( numberprof3_hu numberprof4_hu numberprof5_hu numberprof6_hu numberprof7_hu numberprof8_hu)
	gen pctprof_hu = numberprof_hu/numberscored_hu*100
	drop numberprof_hu
	egen numberbasic_hu = rowtotal (numberbasic3_hu numberbasic4_hu numberbasic5_hu numberbasic6_hu numberbasic7_hu numberbasic8_hu)
	gen pctbasic_hu = numberbasic_hu/numberscored_hu*100
	drop numberbasic_hu
	egen numberbb_hu = rowtotal( numberbb3_hu numberbb4_hu numberbb5_hu numberbb6_hu numberbb7_hu numberbb8_hu)
	gen pctbb_hu = numberbb_hu/numberscored_hu*100
	drop numberbb_hu
	
//checking to see if any calculation errors
	tab schoolname if pctadv3==0 & numberadv3_all !=0
	tab schoolname if pctadv4==0 & numberadv4_all !=0
	tab schoolname if pctadv5==0 & numberadv5_all !=0
	tab schoolname if pctadv6==0 & numberadv6_all !=0
	tab schoolname if pctadv7==0 & numberadv7_all !=0
	tab schoolname if pctadv8==0 & numberadv8_all !=0
	tab schoolname if pctprof3 ==0 & numberprof3_all !=0
	tab schoolname if pctprof4 ==0 & numberprof4_all !=0
	tab schoolname if pctprof5 ==0 & numberprof5_all !=0
	tab schoolname if pctprof6 ==0 & numberprof6_all !=0
	tab schoolname if pctprof7 ==0 & numberprof7_all !=0
	tab schoolname if pctprof8 ==0 & numberprof8_all !=0
	tab schoolname if pctbasic3 ==0 & numberbasic3_all !=0
	tab schoolname if pctbasic4 ==0 & numberbasic4_all !=0
	tab schoolname if pctbasic5 ==0 & numberbasic5_all !=0
	tab schoolname if pctbasic6 ==0 & numberbasic6_all !=0
	tab schoolname if pctbasic7 ==0 & numberbasic7_all !=0
	tab schoolname if pctbasic8 ==0 & numberbasic8_all !=0
	tab schoolname if pctbb3  ==0 & numberbb3_all !=0
	tab schoolname if pctbb4 ==0 & numberbb4_all !=0
	tab schoolname if pctbb5 ==0 & numberbb5_all !=0
	tab schoolname if pctbb6 ==0 & numberbb6_all !=0
	tab schoolname if pctbb7 ==0 & numberbb7_all !=0
	tab schoolname if pctbb8 ==0 & numberbb8_all !=0

//egen function creates 0s where values should be missing. replacing those zeros with missing values
	replace pctprofadv3 = . if pctadv3 ==. & pctprof3==.
	replace pctadv_all = . if numberadv3_all == . & numberadv4_all == . & numberadv5_all ==. & numberadv6_all ==. & numberadv7_all ==. & numberadv8_all ==.
	replace pctprof_all = . if numberprof3_all == . & numberprof4_all == . & numberprof5_all ==. & numberprof6_all ==. & numberprof7_all ==. & numberprof8_all ==.
	replace pctbasic_all = . if numberbasic3_all == . & numberbasic4_all == . & numberbasic5_all ==. & numberbasic6_all ==. & numberbasic7_all ==. & numberbasic8_all ==.
	replace pctbb_all = . if numberbb3_all == . & numberbb4_all == . & numberbb5_all ==. & numberbb6_all ==. & numberbb7_all ==. & numberbb8_all ==.
	replace pctadv_hu = . if numberadv3_hu == . & numberadv4_hu == . & numberadv5_hu ==. & numberadv6_hu ==. & numberadv7_hu ==. & numberadv8_hu ==.
	replace pctprof_hu = . if numberprof3_hu == . & numberprof4_hu == . & numberprof5_hu ==. & numberprof6_hu ==. & numberprof7_hu ==. & numberprof8_hu ==.
	replace pctbasic_hu = . if numberbasic3_hu == . & numberbasic4_hu == . & numberbasic5_hu ==. & numberbasic6_hu ==. & numberbasic7_hu ==. & numberbasic8_hu ==.
	replace pctbb_hu = . if numberbb3_hu == . & numberbb4_hu == . & numberbb5_hu ==. & numberbb6_hu ==. & numberbb7_hu ==. & numberbb8_hu ==.


//replacing float variables with string to get formatting of only one decimal place
	gen pctadv3_new = string(pctadv3, "%2.1f")
	gen pctadv4_new = string(pctadv4, "%2.1f")
	gen pctadv5_new = string(pctadv5, "%2.1f")
	gen pctadv6_new = string(pctadv6, "%2.1f")
	gen pctadv7_new = string(pctadv7, "%2.1f")
	gen pctadv8_new = string(pctadv8, "%2.1f")
	gen pctprof3_new = string(pctprof3, "%2.1f")
	gen pctprof4_new = string(pctprof4, "%2.1f")
	gen pctprof5_new = string(pctprof5, "%2.1f")
	gen pctprof6_new = string(pctprof6, "%2.1f")
	gen pctprof7_new = string(pctprof7, "%2.1f")
	gen pctprof8_new = string(pctprof8, "%2.1f")
	gen pctbasic3_new = string(pctbasic3, "%2.1f")
	gen pctbasic4_new = string(pctbasic4, "%2.1f")
	gen pctbasic5_new = string(pctbasic5, "%2.1f")
	gen pctbasic6_new = string(pctbasic6, "%2.1f")
	gen pctbasic7_new = string(pctbasic7, "%2.1f")
	gen pctbasic8_new = string(pctbasic8, "%2.1f")
	gen pctbb3_new = string(pctbb3, "%2.1f")
	gen pctbb4_new = string(pctbb4, "%2.1f")
	gen pctbb5_new = string(pctbb5, "%2.1f")
	gen pctbb6_new = string(pctbb6, "%2.1f")
	gen pctbb7_new = string(pctbb7, "%2.1f")
	gen pctbb8_new = string(pctbb8, "%2.1f")
	gen pctprofadv3_new = string( pctprofadv3, "%2.1f")
	gen pctadv_all_new = string( pctadv_all, "%2.1f")
	gen pctprof_all_new = string( pctprof_all, "%2.1f")
	gen pctbasic_all_new = string( pctbasic_all, "%2.1f")
	gen pctbb_all_new = string( pctbb_all, "%2.1f")
	gen pctadv_hu_new = string( pctadv_hu, "%2.1f")
	gen pctprof_hu_new = string( pctprof_hu, "%2.1f")
	gen pctbasic_hu_new = string( pctbasic_hu, "%2.1f")
	gen pctbb_hu_new = string( pctbb_hu, "%2.1f")

//dropping float variables andr renaming string variables
	drop pctadv3-pctbb8 pctprofadv3-pctbb_hu
	rename *_new *
	gen stateprofadv = "60.9" if pctadv_all!= "." & pctprof_all!="."



	export delimited using "Y:\Data and Analytics\GPS Data Uploads\2019\Public Schools\18-19 ELA PSSA.csv", replace





