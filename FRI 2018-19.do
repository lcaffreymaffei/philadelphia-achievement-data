//importing raw datafile and appending the second sheet (schools L-Z) to the first sheet (schools A-L)
	import excel "C:\Users\Lucy Caffrey Maffei\Downloads\Datafile_20182019.xlsx", sheet("Schools A to L") firstrow case(lower)
	tempfile sheet1
	save `sheet1'
	clear
	import excel "C:\Users\Lucy Caffrey Maffei\Downloads\Datafile_20182019.xlsx", sheet("Schools L to Y") firstrow case(lower)
	tempfile sheet2
	save `sheet2'
	clear
	use `sheet1'
	append using `sheet2'
	tempfile fri
	save `fri'

//keeping only fields needed for demographic data upload
	replace dataelement =trim(dataelement)
	gen keep=1 if inlist( dataelement, "White", "2 or More Races", "American Indian/Alaskan Native", "Asian" ,"Special Education")
	replace keep=1 if inlist( dataelement,  "Black/African American", "Native Hawaiian or other Pacific Islander", "Hispanic", "Economically Disadvantaged", "English Learner", "Percent of Gifted Students", "School Enrollment" )
	replace keep=1 if inlist( dataelement, "Female (School)", "Male (School)", "School Address (City)")
	tab dataelement if keep==1
	keep if keep==1

//renaming categories to make compatible with reshape
	replace dataelement ="race_2_or_more" if dataelement=="2 or More Races"
	replace dataelement ="native" if dataelement=="American Indian/Alaskan Native"
	replace dataelement ="asian" if dataelement=="Asian"
	replace dataelement ="black" if dataelement=="Black/African American"
	replace dataelement ="econ" if dataelement=="Economically Disadvantaged"
	replace dataelement ="hispanic" if dataelement=="Hispanic"
	replace dataelement ="islander" if dataelement=="Native Hawaiian or other Pacific Islander"
	replace dataelement ="white" if dataelement=="White"
	replace dataelement ="ell" if dataelement=="English Learner"
	replace dataelement ="gifted" if dataelement=="Percent of Gifted Students"
	replace dataelement ="sped" if dataelement=="Special Education"
	replace dataelement ="enrollment" if dataelement=="School Enrollment"
	replace dataelement ="county" if dataelement=="School Address (City)"
	replace dataelement ="female" if dataelement =="Female (School)"
	replace dataelement ="male" if dataelement =="Male (School)"

//formatting cleaned FRI data to match for merge with list of GPS schools that need data
	format displayvalue %20s
	rename displayvalue d_
	rename schl pacode
	reshape wide d_ , i( districtname name aun pacode) j( dataelement )s
	rename d_* *
	destring pacode aun, force replace
	tempfile fri_cleaned
	save `fri_cleaned'
	clear

//merging FRI with GPS schools
	import excel "Y:\Data and Analytics\GPS Data Uploads\2019\Public Schools\Raw Data\2018-19 Public Schools - GPS Records.xlsx", sheet("Sheet1") firstrow case(lower)
	tempfile gps
	save `gps'
	merge m:1 pacode using `fri_cleaned'
	drop if _merge ==2
	drop _merge county name enrollment districtname
	order pspid-districtname native  asian black islander white race_2_or_more hispanic ell sped gifted
