
<p align="center">
	<img src="https://github.com/worldbank/brazil-pip-education/raw/master/img/WB_logo.png?raw=true")>
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	<img src="https://github.com/worldbank/brazil-pip-education/raw/master/img/i2i.png?raw=true")
</p>

# Replication Code for "Supporting Teacher Autonomy to Improve Education Outcomes: Experimental Evidence from Brazil"
<span>&#x1f1e7;&#x1f1f7;</span> :school: :school_satchel: :book: :bulb: :six: :arrow_upper_right: :heavy_check_mark: :mortar_board: :money_with_wings:

&nbsp;

This repository contains the codes that replicate the figures and tables presented in the World Bank Policy Research Working Paper "Supporting Teacher Autonomy to Improve Education Outcomes: Experimental Evidence from Brazil" (2020) by Rafael Dantas, Andre Loureiro, Caio Piza, Matteo Ruzzante, and Astrid Zwager.


## Read First
The whole analysis in the paper can be rerun by using the master script `PIP-Master.do`. It is only necessary to add your computer's username and path to the downloaded replication folder in line 131-133 of such do-file in *PART 1*.
You can select which sections to run by editing the locals in the preamble of the do-file. Make sure to run the *packages* section &ndash; *PART 0* to install all necessary packages before running the other sections.

The master script will take up to one week on a reasonable cluster. Without considering the do-files using randomization inference procedures (see section *Code Process* below), it would take around 6 minutes.

The individual do-files with their respective inputs and outputs are explained below.
The do-files employ finalized datasets, which are constructed from various data sources, listed and described below.
The project data have not been posted yet for proprietary reasons.

Computational reproducibility was verified by [DIME Analytics](https://worldbank.github.io/dimeanalytics/code-review/). Details of the reproducibility checklist can be found in the online appendix of the paper.


## Abstract
Improving school quality is a public policy priority in most developing countries. We explore whether motivating teachers through increased autonomy can improve student outcomes, in a context of limited state capacity. We present experimental evidence of a program in Brazil that supports teachers to autonomously develop and implement a project aimed at engaging their students. We find substantial impacts of the program on learning and progression rates in 6th grade, a critical year of transition from primary to lower-secondary education. We show that the program reduced teacher turnover and positively impacted students' socio-emotional skills, which indicates that teacher motivation and student-teacher interactions are important drivers. The results suggest that increasing autonomy of local civil service providers coupled with technical assistance can deliver meaningful improvements in the quality of public service provision, at relatively low cost, even in a low capacity context.


## [Latest Version of the Paper](https://github.com/worldbank/brazil-pip-education/blob/master/pip.pdf)

## [Online Appendix](https://github.com/worldbank/brazil-pip-education/blob/master/pip_app.pdf)



## Final Dataset Description
Datasets used for analysis are aggregated at different levels, namely at the student, teacher and school level, and described below.
Master datasets contain records of all students, teachers and schools, in the experimental sample.
Other administrative datasets refer to the universe of schools or students in Rio Grande do Norte or Brazil.
*[NOTE: Data have not been posted yet in this repository for proprietary reasons.]*

<details>
	<summary>The datasets used in the do-files are the following:</summary>
	<ol>
		<li><code>original_sample.dta</code> contains the list of students and schools in the experimental sample. Source: project.</li>
		<li><code>master_studentlevel.dta</code> contains all the information at the student level. Sources: project, State Secretariat of Education (SEE) of Rio Grande do Norte (RN), <em>Instituto Nacional de Estudos e Pesquisas Educacionais Anísio Teixeira</em> (INEP) school census, <em>Sistema Integrado de Gestão da Educação</em> (SIGEduc) portal.</li>
		<li><code>master_schoollevel.dta</code>  contains all the information at the school level and the averages of numeric variables at the student level. Sources: project, SEE of RN, INEP school census, SIGEduc portal.</li>
		<li><code>master_teacherlevel.dta</code> contains all the information at the teacher level. Turnover dummies are in wide format at the teacher level. Sources: 2016 and 2017 INEP teacher censuses.</li>
		<li><code>scores_rescaled_ProvaBrasil.dta</code> contains test scores data rescaled by <em>Sistema de Avaliação da Educação Básica</em> (SAEB) or <em>Prova Brasil</em>. Source: SEE of RN.</li>
		<li><code>rates_panel.dta</code> is a panel of progression rates of schools in the experimental sample, containing also grades which were not targeted by the project, from 2015 to 2017. Source: SIGEduc.</li>
		<li><code>RN_students_panel.dta</code> is a panel of all students from RN created with census data from 2011 to 2017. Sources: 2011 to 2017 INEP school censuses. Raw data can be downloaded from <a href="http://portal.inep.gov.br/microdados" rel="nofollow">http://portal.inep.gov.br/microdados</a>.</li>
		<li><code>RN_salaries_2016.dta</code> contains data on 2016 salaries for RN. Source: <em>Relação Anual de Informações Sociais</em> (RAIS) from Ministry of Labour and Employment.</li>
		<li><code>Brazil_school_indicators.dta</code> contains school indicators, such as progression rates, age-grade distorsion and teacher permanence index, for all schools in Brazil from 2015 to 2017.  Source: INEP 2015-2017 school indicators. Raw data can be downloaded from <a href="http://portal.inep.gov.br/indicadores-educacionais" rel="nofollow">http://portal.inep.gov.br/indicadores-educacionais</a>.</li>
		<li><code>Brazil_rates.dta</code> contains progress rates by grade and state in Brazil. Source: INEP 2015 state indicators.</li>
		<li><code>Brazil_ProvaBrasil.dta</code> contains average SAEB scores for Brazil and RN by grade in 2013 and 2017. Source: INEP.</li>
		<li><code>Brazil_IDEB.dta</code> contains average state-school IDEBs by state in Brazil. Source: INEP. Raw data can be downloaded from <a href="http://ideb.inep.gov.br/" rel="nofollow">http://ideb.inep.gov.br/</a>.</li>
	</ol>
	<p>Datasets (1)-(6) are specific to the project evaluated in this paper, while (7)-(12) are information general to the school system and job market of RN and Brazil.</p>
</details>

##  Code Process
The name of the do-files corresponds to the `.tex` or `.png` files to be created in the output folder.
All tables and figures were included &ndash; without further editing &ndash; in the TeX document containing the current version of the paper and its online appendix.

The `PIP-Master.do` file executes the following codes:

<details title="figures">
	<summary>
		<font size="5">
			<strong><em>
				Figures
			</strong></em>
		</font>
	</summary>
	<ol>
		<li><code>fig1-grade_comparison.do</code> uses <code>RN_rates.dta</code> and plots Figure 1.</li>
		<li><code>fig2-IDEB_byState.do</code> uses <code>Brazil_IDEB.dta</code> and plots Figure 2.</li>
		<li><code>fig3-grant.do</code> uses <code>master_schoollevel.dta</code> and plots Figure 3.</li>
		<li>Figure 4 is produced by the R-script <code>Map with treament distribution.R</code>. This code uses identified data (which is not part of the final datasets) and requires you to have a Google API key to retrieve the base map. <em>[NOTE: The figure produced by R was then manually cropped and the clarity of the image adapted.]</em>.</li>
		<li><code>fig5-retention_grade6.do</code> uses <code>RN_students_panel.dta</code> and plots Figure 5 – Panels (a) and (b).</li>
		<li><code>fig6-implementation_byGrade.do</code> uses <code>master_schoollevel.dta</code> and plots Figure 6.</li>
		<li><code>figA1-predict_participation.do</code> uses <code>master_studentlevel.dta</code> and plots Figure A1.</li>
		<li><code>figA2-qreg_media_grade6.do</code> uses <code>master_studentlevel.dta</code>, estimates and plots Figure A2.</li>
		<li><code>figA3a-kdensity_grade6_byGender.do</code> uses <code>master_studentlevel.dta</code>, estimates and plots Figure A3 – Panel (a).</li>
		<li><code>figA3b-qreg_media_grade6_byGender.do</code> uses <code>master_studentlevel.dta</code>, estimates and plots Figure A3 – Panel (b).</li>
		<li><code>figA4-scatter_test_socio.do</code> uses <code>master_studentelevel.dta</code>, estimates and plots Figure A4 – Panels (a) and (b).</li>
		<li><code>figA5-itt_ProvaBrasil.do</code> uses <code>Brazil_ProvaBrasil.dta</code> and <code>scores_rescaled_ProvaBrasil.dta</code>, estimates and plots Figures A5 – Panels (a) and (b).</li>
		<li><code>figA6-itt_IDEB.do</code> uses <code>master_schoollevel.dta</code> and <code>Brazil_IDEB.dta</code>, estimates and plots Figure A6.</li>
		<li><code>figB1-kdensity_wage.do</code> uses <code>RN_salaries_2016.dta</code> and estimates and plots Figure B1.</li>
		<li><code>figC1-qreg_bySubject_grade6.do</code> uses <code>master_studentlevel.dta</code> estimates and plots Figure C1 – Panels (a), (b), (c), and (d).</li>
	</ol>
</details>

<details title="program">
	<summary>
		<font size="5">
			<strong><em>
				Programs
			</strong></em>
		</font>
	</summary>
	<ol>
	<li><code>blockdim.ado</code> defines a command to estimate block difference-in-means regressions. This is then employed in <code>tabC2-test_studentlevel_DIM.do</code> and <code>tabC7-socio_studentlevel_DIM.do</code>.</li>
	</ol>
</details>

<details title="tables">
	<summary>
		<font size="5">
			<strong><em>
				Tables
			</strong></em>
		</font>
	</summary>
	<ol>
		<li><code>tab1-sample.do</code> uses <code>original_sample.dta</code> and produces Table 1.</li>
		<li><code>tab2-baltab.do</code> uses <code>master_schoollevel.dta</code>, <code>master_teacherlevel.dta</code> and <code>master_studentlevel.dta</code>, estimates and produces Table 2 <em>[NOTE: This code may take a long time as it employs randomization inference techniques with 10,000 replications.]</em>.</li>
		<li><code>tab3-test_studentlevel.do</code> uses <code>master_studentlevel.dta</code>, estimates and produces Table 3.</li>
		<li><code>tab4-promotion.do</code> uses <code>master_schoollevel.dta</code>, estimates and produces Table 4.</li>
		<li><code>tab5-turnover_teacherlevel.do</code> uses <code>master_teacherlevel.dta</code>, estimates and produces Table 5.</li>
		<li><code>tab6-turnover.do</code> uses <code>master_studentlevel.dta</code>, <code>RN_students_panel.dta</code> and <code>master_teacherlevel.dta</code>, estimates and produces Table 6.</li>
		<li><code>tab7-spillover_other_grades.do</code> uses <code>RN_students_panel.dta</code> and <code>master_teacherlevel.dta</code>, estimates and produces Table 7.</li>
		<li><code>tab8-socio_studentlevel.do</code> uses <code>master_studentlevel.dta</code>, estimates and produces Table 8.</li>
		<li><code>tabA1-correlates_turnover.do</code> uses <code>Brazil_school_indicators.dta</code>, estimates and produces Table A1.</li>
		<li><code>tabA2-baltab_participation.do</code> uses <code>master_studentlevel.dta</code>, estimates and produces Table A2. <em>[NOTE: This code may take a long time as it employs randomization inference techniques with 10,000 replications.]</em>.</li>
		<li><code>tabA3,4-baltab_test_takers_schoollevel.do</code> uses uses <code>master_schoollevel.dta</code>, <code>master_teacherlevel.dta</code> and <code>master_studentlevel.dta</code>, estimates and produces Tables A3 and A4. <em>[NOTE: This code may take a long time as it employs randomization inference techniques with 10,000 replications.]</em>.</li>
		<li><code>tabA5-promotion_het_gender.do</code> uses <code>RN_students_panel.dta</code>, estimates and produces Table A5.</li>
		<li><code>tabA6-promotion_het.do</code> uses <code>master_schoollevel.dta</code>, estimates and produces Table A6.</li>
		<li><code>tabA7-retention_grade6_regs.do</code> estimates and produces Table A7.</li>
		<li><code>tabA8-predict_implementation.do</code> uses <code>master_schoollevel.dta</code>, estimates and produces Table A8.</li>
		<li><code>tabA9-clearance_certificate.do</code> uses <code>master_schoollevel.dta</code>, estimates and produces Table A9.</li>
		<li><code>tabB1-IDEB_schoollevel.do</code> uses <code>master_schoollevel.dta</code>, estimates and produces Table B1.</li>
		<li><code>tabC1-test_studentlevel_ctrl.do</code> uses <code>master_studentlevel.dta</code>, estimates and produces Table C1.</li>
		<li><code>tabC2-test_studentlevel_DIM.do</code> uses <code>master_studentlevel.dta</code>, estimates and produces Table C2.</li>
		<li><code>tabC3-test_studentlevel_IWE.do</code> uses <code>master_studentlevel.dta</code>, estimates and produces Table C3.</li>
		<li><code>tabC4-test_studentlevel_RWE.do</code> uses <code>master_studentlevel.dta</code>, estimates and produces Table C4.</li>
		<li><code>tabC5-test_schoollevel.do</code> uses <code>master_schoollevel.dta</code>, estimates and produces Table C5.</li>
		<li><code>tabC6-test_rescaled_studentlevel.do</code> uses <code>scores_rescaled_ProvaBrasil.dta</code>, estimates and produces Table C12.</li>
		<li><code>tabC7-promotion_other_grades.do</code> uses <code>rates_panel.dta</code>, <code>master_schoollevel.dta</code> and <code>RN_students_panel.dta</code>, estimates and produces Table C11.</li>
		<li><code>tabC8-socio_studentlevel_ctrl.do</code> uses <code>master_studentlevel.dta</code>, estimates and produces Table C6.</li>
		<li><code>tabC9-socio_studentlevel_DIM.do</code> uses <code>master_studentlevel.dta</code>, estimates and produces Table C7.</li>
		<li><code>tabC10-socio_studentlevel_IWE.do</code> uses <code>master_studentlevel.dta</code>, estimates and produces Table C8.</li>
		<li><code>tabC11-socio_studentlevel_RWE.do</code> uses <code>master_studentlevel.dta</code>, estimates and produces Table C9.</li>
		<li><code>tabC12-socio_schoollevel.do</code> uses <code>master_schoollevel.dta</code>, estimates and produces Table C10.</li>
	</ol>
</details>

## Main Contact
If you have any comment, suggestion or request for clarifications, you can contact Matteo Ruzzante at <a href="mailto:mruzzante@worldbank.org">mruzzante@worldbank.org</a> or directly open an issue or pull request in this GitHub repository.</p>
