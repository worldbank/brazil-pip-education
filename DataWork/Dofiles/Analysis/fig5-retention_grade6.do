	
/*******************************************************************************
*  Project:				PIP													   *
*																 			   *
*  PURPOSE:  			Estimate effect of retention in 6th grade	   	   	   *
*  WRITTEN BY:  	  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  Last time modified:  July 2020										   	   *
*																			   *
********************************************************************************

	** REQUIRES:   		"${master_dt_fin}/RN_students_panel.dta"
	
	** CREATES:	   		Figure 5: 6th Grade Retention and Student Attainment
						
						(a) Percentage of 2011 6th Graders Enrolled in Subsequent Years
						"${master_fig}/fig5a-retention_grade6_dropout.png"
						
						(b) Years of Completed Schooling of 2011 6th Graders
						"${master_fig}/fig5b-retention_grade6_education.png"

* ---------------------------------------------------------------------------- */
	
	* Load full panel
	use 	"${master_dt_fin}/RN_students_panel"	, clear
	
	* Keep only 6th graders in 2011
	sort	inep_student 							  year
	by 		inep_student: keep if student_grade[1] == 6
			
	* Count year of completed schooling (not considering 2017 as we don't know where they ended up in 2018)
	egen	schooling   = max(student_grade) if inrange(year, 2011, 2016), by(inep_student)
	
	* Subtract one year if student dropped out in that grade
	replace schooling   = schooling - 1  	 if dropped_once == 1
	
	* Define dummy for retained in 2011	
	gen		retained_in_2011 = 1 if retained == 1 & year == 2011
	replace retained_in_2011 = 0 if promoted == 1 & year == 2011 
		
	tab 	retained_in_2011 	 if year 	 == 2011 , mi //missing are drop-outs
	by 		inep_student: 		 ///
			carryforward  		 ///
			retained_in_2011   , replace	
	tab		retained_in_2011 	 year
	
	* Sum number of students who promoted, retained, or dropped out by year and group
	egen 	promoted_sum  = sum(promoted), by(year retained_in_2011)
	egen 	retained_sum  = sum(retained), by(year retained_in_2011)
	egen 	 dropped_sum  = sum( dropped), by(year retained_in_2011)
	
	* Generate total number of students
	gen 	   total  = 	promoted_sum    ///
					  +		retained_sum 	///
					  + 	 dropped_sum
	
	* Fill-in years of education when student drops out
	by 		inep_student: 		 ///
				carryforward  	 ///
				student_grade  , replace	
	
	* Line plot starting at year 2011 with 100 and dividing in two groups
	* (those who were retained and those who were promoted in 2011)
	* - and see where they are in the following years
	* -----------------------------------------------
		
	* Collapse variables of interest by year and retention
	collapse promoted_sum retained_sum dropped_sum total ///
			 student_grade, by(year retained_in_2011)
	
	* Drop missing observations and last year
	drop if  mi(retained_in_2011)
	drop if  year == 2017
	
	* Generate string for grade label
	gen	     student_gradeStr = string(round(student_grade,.01), "%9.0g")
	
	* Plot lines
	#d	;
		gr tw ( connected student_grade year if  retained_in_2011
			  , mlab(student_gradeStr) mlabpos(12) mlabgap(1)
				mlabcolor(${controlColor}) color(${controlColor}) lpattern(dash)
			  )
			  ( connected student_grade year if !retained_in_2011
			  , mlab(student_gradeStr) mlabpos(12) mlabgap(1) msymbol(triangle)
				mlabcolor(${treatmentColor}) color(${treatmentColor}) 
				
			  )
			  ,
				legend(lab(1 "Retained in 2011") lab(2 "Promoted in 2011"))
				ytitle("Years completed")
				xtitle("Year")
				xlab(2011/2016)
				${graphOptions} xscale(nofextend titlegap(1)) yscale(nofextend)
		;
	#d	cr
	
	* Export graph
	gr export "${master_fig}/fig5b-retention_grade6_education.png", as(png) replace width(5000)
	
* ---------------------------------------------------------------------------- *		
	
	sort year
	gen	  	  total_2011_aux  	 = total if year == 2011
	egen	  total_2011	  	 = max(total_2011_aux), by(retained_in_2011)
	drop	  total_2011_aux
			
	forv 	  year			 	 = 2012/2016 {		
		gen	  dropped_`year'_aux = dropped_sum  if year == `year'
		egen  dropped_`year'	 = max(dropped_`year'_aux), by(retained_in_2011)
		drop  dropped_`year'_aux 
	}
	
	gen 	  dropped_cumulate   = 0
	replace   dropped_cumulate   = dropped_cumulate + dropped_2012 																if year == 2012
	replace   dropped_cumulate   = dropped_cumulate + dropped_2012 + dropped_2013 												if year == 2013
	replace   dropped_cumulate   = dropped_cumulate + dropped_2012 + dropped_2013 + dropped_2014 								if year == 2014
	replace   dropped_cumulate   = dropped_cumulate + dropped_2012 + dropped_2013 + dropped_2014 + dropped_2015					if year == 2015
	replace   dropped_cumulate   = dropped_cumulate + dropped_2012 + dropped_2013 + dropped_2014 + dropped_2015	+ dropped_2015  if year == 2016
	
	gen 	  pct_promoted 		 = 100 - promoted_sum     / total * 100
	gen 	  pct_retained 		 = 100 - retained_sum     / total * 100

	gen 	  pct_dropped  		 = 100 - dropped_cumulate / total_2011 * 100
	
	gen		  pct_droppedStr = string(round(pct_dropped  ,.01), "%9.0g")
			
	#d	;
		gr tw ( connected pct_dropped year if  retained_in_2011
			  , mlab(pct_droppedStr) mlabpos(12) mlabgap(1)
				mlabcolor(${controlColor}) color(${controlColor}) lpattern(dash)
			  )
			  ( connected pct_dropped year if !retained_in_2011
			  , mlab(pct_droppedStr) mlabpos(12) mlabgap(1) msymbol(triangle)
				mlabcolor(${treatmentColor}) color(${treatmentColor}) 
			  )
				  ,
				  /*title("Drop-out rate of 6-th graders in 2011")*/
				  legend(lab(1 "Retained in 2011") lab(2 "Promoted in 2011"))
				  ytitle("%", orientation(horizontal))
				  xtitle("Year")
				  ${graphOptions} xscale(nofextend titlegap(1)) yscale(nofextend)
				  /*note("{bf:Data source:} Rio Grande do Norte 2011-2017 censuses.")*/
		;
	#d	cr
	
	gr export "${master_fig}/fig5a-retention_grade6_dropout.png", as(png) replace width(5000)
	
	
******************************** End of do-file ********************************
