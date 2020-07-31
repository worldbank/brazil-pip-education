
/*******************************************************************************
*  Project:				PIP													   *												   
*																 			   *
*  PURPOSE:  			Predict implementation degree 						   *		  
*  WRITTEN BY:  	  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  Last time modified:  July 2020											   *
*																			   *
********************************************************************************

	** REQUIRES:   		"${master_dt_fin}/master_schoollevel.dta"
						
	** CREATES:	   		Table A8: Drivers of Implementation
						"${master_tab}/tabA8-predict_implementation.tex"
	
* ---------------------------------------------------------------------------- *
*								Prepare data								   *
* ---------------------------------------------------------------------------- */

	* Load master data at the school level
	use		 "${master_dt_fin}/master_schoollevel.dta" , clear 
	
	* Construct principal component analysis (PCA) index 
	local 	 pcaVars school_internet school_library school_science_lab school_location
	
	pca     `pcaVars'
	predict  school_infrastructure , score
	kdensity school_infrastructure , ${graphOptions}
				
	* Define dummy for schools in Natal
	gen 	 natal_munic = school_municipality == "NATAL"
	gen 	 natal_direc = school_directorade  == "01ª DIRED - Natal"
	
	tab 	 natal*
	
	* Replace distance if school is in Natal
	replace  haversine_dist_km = 0 if natal_munic == 1
	
	* Define set of regressors
	local	 schoolVars	school_N_students   school_score school_infrastructure haversine_dist_km
	local      rateVars	promotion_rate_2015 dropout_rate_2015
	
	* Generate dummy variable
	gen		school_implementation70 = school_implementation > 0.70 if !mi(school_implementation)
	
* ---------------------------------------------------------------------------- *
*						Estimate linear probability model					   *
* ---------------------------------------------------------------------------- *

	* Store estimates with different control vars	
	eststo	school70	   : reghdfe school_implementation70 					 					///
							`schoolVars'															///
						  if school_treated == 1													///
						   , abs(strata)  vce(rob)
	sum      				 		 school_implementation if e(sample) == 1
	estadd  scalar 	  mean = r(mean)
	estadd  scalar 	  sd   = r(sd)
	
	eststo	rate70  	   : reghdfe school_implementation70 					 					///
							`schoolVars' `rateVars'													///
						  if school_treated == 1													///
						   , abs(strata)  vce(rob)
	sum      				 		 school_implementation if e(sample) == 1
	estadd  scalar 	  mean = r(mean)
	estadd  scalar 	  sd   = r(sd)
	
	eststo	clearance70    : reghdfe school_implementation70 					 					///
							`schoolVars' `rateVars' school_clearance_certificate					///
						  if school_treated == 1													///
						   , abs(strata)  vce(rob)
	sum      				 		 school_implementation if e(sample) == 1
	estadd  scalar 	  mean = r(mean)
	estadd  scalar 	  sd   = r(sd)
	
	* Export table directly to LaTeX
	#d	;
		esttab 	school70 rate70 clearance70
				using "${master_tab}/predict_implementation.tex", replace tex
				se nocons fragment
				nodepvars nonumbers nomtitles nolines
				noobs nonotes alignment(c)
				coeflabel(school_N_students 	   	   "\addlinespace[0.75em] Number of enrolled students in PIP grades"
						  school_score			   	   "Quality score of expression of interest"
						  school_infrastructure    	   "School infrastucture index"
						 
						  haversine_dist_km		   	   "Distance to Natal (km)"

						  promotion_rate_2015 	   	   "Passing rate in 2015"
						  dropout_rate_2015		   	   "Dropout rate in 2015"
						  
						  school_clearance_certificate "School has clearance certificate"
						 )
				stats(	  N r2_a mean sd, lab(	  	   "\addlinespace[0.5em] Number of observations"
													   "Adjusted R-squared"
													   "\addlinespace[0.5em] Mean dep.\ var."
													   "SD dep.\ var.")
										  fmt(0 %9.3f %9.3f %9.3f )
					 )
				star(* 0.10 ** 0.05 *** 0.01)
				b(%9.3f) se(%9.3f)
				
				 prehead("&(1) &(2) &(3) \\ \hline")
				postfoot("[0.25em] \hline \hline \\ [-1.8ex]")	
		;
	#d	cr
	
	filefilter  "${master_tab}/predict_implementation.tex"	  		///
				"${master_tab}/tabA8-predict_implementation.tex", 	///
				from("[1em]") to("") replace	
	sleep  		 ${sleep}
	erase 		"${master_tab}/predict_implementation.tex"
	
	di as text `"Open final file in LaTeX here: {browse "${master_tab}/tabA8-predict_implementation.tex":"${master_tab}/tabA8-predict_implementation.tex"}"'

	
******************************** End of do-file ********************************
