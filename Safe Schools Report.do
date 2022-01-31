//importing Safe Schools report and cleaning to merge with GPS records
	import excel "Y:\Data and Analytics\GPS Data Uploads\2019\Public Schools\2018-2019 Safe Schools Report.xlsx", sheet("2017-2018") firstrow case(lower)
	rename schoolnumber pacode
	replace truancyrate = truancyrate *100
	drop ce
	rename pacode pacode
	drop leaname leatype county
	rename aunbr aun
	destring aun, force replace
	tempfile safeschools
	save `safeschools'
	clear

//importing gps records of all accounts with their PSP ID and AUN to merge AUN onto list of active GPS schools
	import delimited "C:\Users\Lucy Caffrey Maffei\Downloads\report1572016904445.csv", bindquote(strict) varnames(1) 
	keep childprofilenamepspid childprofilenameaun
	rename childprofilenameaun aun
	rename childprofilenamepspid pspid
	unique pspid
	tempfile aun
	save `aun'
	clear

//merging aun onto GPS record of active public schools
	import excel "Y:\Data and Analytics\GPS Data Uploads\2019\Public Schools\2018-19 Public Schools - GPS Records.xlsx", sheet("Sheet1") firstrow case(lower)
	tostring pspid, force replace
	merge 1:1 pspid using `aun'
	drop if _merge ==2
	drop _merge gradesserved
	destring pspid, force replace

//merging safe schools onto GPS record of active schools, first by PA Code (for district schools), then by AUN (for charter schools)
	merge m:m pacode using `safeschools'
	drop if _merge ==2
	replace aun = aun+10000000000 if _merge == 3
	drop _merge
	merge m:m aun using `safeschools', replace update
	drop if _merge == 2
	drop _merge incidentmisconductsacademicor offenderallothermisconducts academicdishonesty schoolcodeofconduct
	rename incidentallothermisconducts incidents

//generating OSS, expulsion, and incident totals and rates. we do not generate incident totals because the report already has that number. the number might be lower than if you were to add
// up numbeers in each misconduct category because one incident could count in multiple misconduct categories.
	egen totaloss = rowtotal(*oss)
	egen totalexpulsion = rowtotal(*expulsion)
	gen incidentrate = (incidents/enrollment)*100
	gen ossrate = (totaloss/enrollment)*100
	gen expulsionrate = (totalexpulsion/enrollment)*100

//converting rates to one decimal place
	gen ossrate_new = string(ossrate, "%2.1f")
	gen expulsionrate_new = string(expulsionrate, "%2.1f")
	gen incidentrate_new = string(incidentrate, "%2.1f")
	drop incidentrate expulsionrate ossrate
	rename incidentrate_new incidentrate
	rename expulsionrate_new expulsionrate
	rename ossrate_new ossrate

	export delimited using "Y:\Data and Analytics\GPS Data Uploads\2019\Public Schools\2018-19 School Incidents.csv", replace
