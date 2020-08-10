********************************************************************************
*   Goal: explore the effects of maternal mental health problems               *
*   Authors: Mommy Whisperers team                                             *
*   Create date: July 23, 2020                                                 *
********************************************************************************

*======================   OUTLINE   ===========================================*
*······················ 0 create personal directories ·························* 
*                                                                              *
*······················ 1 clean baseline data ·································*
*                                                                              *
*······················ 2 clean follow-up data ································*
*                                                                              *
*······················ 3 append two waves of data and clean up ···············*
*                                                                              *
*----------------------  start to analyze -------------------------------------*
*                                                                              *
*······················ 5                             ·························*
*······················ 6                             ·························*
*==============================================================================*


* Section 0. create personal input and output routes

/* note: everyone can difine your own directors like me, and define where you input 
the data to Stata. And when you are on the Stata, run your own set of directories 
*/

*==0.1 Jiang Qi
global datadir   "/Users/jiangqi/Desktop/papers/37_2020_HF_mh_and_ecd/1_data"
global tablesdir "/Users/jiangqi/Desktop/papers/37_2020_HF_mh_and_ecd/3_tables"

cd "/Users/jiangqi/Desktop/papers/37_2020_HF_mh_and_ecd/3_tables"


*==0.2 TBD
*------------------------------------------------------------------------------*


*Section 1. clean baseline data

*imput the date
use "$datadir/0_baseline_hf_mom_only.dta", clear

*drop pregnant women and keep the newborns
keep if type==2

***********************
*--Control Variables--*
***********************

*==1 child gender 
tab B1_6,m
recode B1_6 (2=0)

rename B1_6 child_male 
label var child_male "baby male (1=yes)"

tab child_male,m

*==2 child age 

*出生日期的清理
codebook B1_1	
tostring B1_1,replace

gen baby_year = substr(B1_1,1,4)
order baby_year, after(B1_1)
gen baby_month = substr(B1_1,5,2)
order baby_month, after(B1_1)
gen baby_day = substr(B1_1,7,2)
order baby_day, after(B1_1)
codebook baby_year baby_month baby_day

tab B1_1 if baby_year == "2018"
replace B1_1 = "20190813" if baby_year == "2018"
replace baby_year = substr(B1_1,1,4)

tab B1_1 if baby_month == "01" | baby_month == "" | baby_month == "04" 
replace B1_1 = "" if baby_month == "01" | baby_month == ""
replace baby_month = substr(B1_1,5,2)

replace baby_day = substr(B1_1,7,2)

destring baby_year baby_month baby_day,replace
codebook baby_year baby_month baby_day
tostring baby_year baby_month baby_day,replace

tab B1_1
replace B1_1 = "20190515" if B1_1 == "201905"
replace B1_1 = "20190610" if B1_1 == "201906010"
replace B1_1 = "20190925" if B1_1 == "2019092"
replace B1_1 = "20191025" if B1_1 == "2019102"
drop baby_year baby_month baby_day
tab B1_1,m
codebook B1_1
////字符型出生日期B1_1已清理完成

*调查日期的清理
gen survey_year = substr(Inv_date,1,4)
order survey_year, after (Inv_date)
gen survey_month = substr(Inv_date,6,2)
order survey_month, after (Inv_date)
gen survey_day = substr(Inv_date,9,2)
order survey_day, after (Inv_date)
gen survey_date = survey_year + survey_month + survey_day
order survey_date, after (Inv_date)
tab survey_date
codebook survey_date
////字符型调查日期survey_date已清理完成

*相隔月数的计算：
tab B1_1 survey_date if B1_1 > survey_date
replace B1_1 = "20191031" if B1_1 > survey_date
codebook B1_1 survey_date

gen baby_age = date(survey_date,"YMD") - date(B1_1,"YMD") 
order baby_age,before(B1_1)
codebook baby_age
gen baby_AGE = int(baby_age / 30)
order baby_AGE,before(Family_code)
codebook baby_AGE
replace baby_AGE = 6 if baby_AGE == 7 //将12个不足7月龄的婴儿归入6月龄婴儿一类
codebook baby_AGE
egen baby_AGE_m = mean(baby_AGE)
replace baby_AGE = int(baby_AGE_m) if baby_AGE == . //用均值对7个缺失值进行填补
codebook baby_AGE
drop baby_AGE_m //得到了没有缺失值的baby_AGE

sum baby_AGE,detail
tabulate baby_AGE


*==3 premature
tab E1_4,m

gen premature = .
replace premature =1 if E1_4<37
replace premature = 0 if E1_4>=37 & E1_4<50

tab premature,m

label var premature "premature(1=yes)"

*==4 low birth weight (<2500g)
tab E1_1,m

gen low_birth_weight = .
replace low_birth_weight=1 if E1_1<2500
replace low_birth_weight=0 if E1_1>=2500 & E1_1<9999 

tab low_birth_weight,m

*==6 mother age
gen age_mom=.

foreach num of numlist 0(1)11 {
	destring A_2_1_`num', replace
	replace age_mom = A_2_2`num' if A_2_1_`num' == 2
	}

tab age_mom,m


*==7 mother education level
gen edu_mom=.

foreach num of numlist 0(1)11 {
	replace edu_mom = A_2_3`num' if A_2_1_`num' == 2
	}

tab edu_mom,m

*=7.1 whether mom has graduated from high school
gen mom_hs_grad=.
replace mom_hs_grad = 1 if edu_mom>=4 & edu_mom<1000
replace mom_hs_grad = 0 if edu_mom<4

tab mom_hs_grad,m

label var mom_hs_grad "does mother graduate from high school(1=yes)"

*==9 father education level
gen edu_dad=.

foreach num of numlist 0(1)11 {
	replace edu_dad = A_2_3`num' if A_2_1_`num' == 1
	}

tab edu_dad,m

*=9.1 whether father has graduated from high school
gen dad_hs_grad=.
replace dad_hs_grad = 1 if edu_dad>=4 & edu_dad<1000
replace dad_hs_grad = 0 if edu_dad<4

tab dad_hs_grad,m

label var dad_hs_grad "does dad graduate from high school(1=yes)"


*==11 family asset index
*=11.1 抽水马桶
gen choushui = .

replace choushui=1 if B1_25 ==2
replace choushui=0 if B1_25 !=2 
tab choushui,m

foreach var of varlist B1_15-B1_23{
recode `var' (2=0)
}


polychoricpca B1_15-B1_23 choushui, score(asset_index) nscore(1)

rename asset_index1 family_asset

*****************************
*--Caregiver mental health--*
*****************************

*==1 DASS 

*=1.1 clean variables one by one
rename G1_1 S1
rename G1_2 A2
rename G1_3 D3
rename G1_4 A4
rename G1_5 D5
rename G1_6 S6
rename G1_7 A7
rename G1_8 S8
rename G1_9 A9
rename G1_10 D10
rename G1_11 S11
rename G1_12 S12
rename G1_13 D13
rename G1_14 S14
rename G1_15 A15
rename G1_16 D16
rename G1_17 D17
rename G1_18 S18
rename G1_19 A19
rename G1_20 A20
rename G1_21 D21

gen depression_score=(D3+D5+D10+D13+D16+D17+D21)*2
gen anxiety_score=(A2+A4+A7+A9+A15+A19+A20)*2
gen stress_score=(S1+S6+S8+S11+S12+S14+S18)*2

label var depression_score "Depression Score"
label var anxiety_score "Anxiety Score"
label var stress_score "Stress Score"

*==1.2 generate mental health problem variables
*=1.2.1 mild mental health problems
gen depression_mild=.
replace depression_mild=1 if depression_score>9 & depression_score<9999
replace depression_mild=0 if depression_score<=9
tab depression_mild,m

gen anxiety_mild=.
replace anxiety_mild=1 if anxiety_score>7 & anxiety_score<999
replace anxiety_mild=0 if anxiety_score<=7
tab anxiety_mild,m

gen stress_mild=.
replace stress_mild=1 if stress_score>14 & stress_score<999
replace stress_mild=0 if stress_score<=14
tab stress_mild,m

gen any_mild = depression_mild==1 | anxiety_mild==1 | stress_mild==1

*=1.2.2 moderate mental health problems
gen depression_moderate=.
replace depression_moderate=1 if depression_score>13 & depression_score<9999
replace depression_moderate=0 if depression_score<=13
tab depression_moderate,m

gen anxiety_moderate=.
replace anxiety_moderate=1 if anxiety_score>9 & anxiety_score<999
replace anxiety_moderate=0 if anxiety_score<=9
tab anxiety_moderate,m

gen stress_moderate=.
replace stress_moderate=1 if stress_score>18 & stress_score<999
replace stress_moderate=0 if stress_score<=18
tab stress_moderate,m

gen any_moderate = depression_moderate==1 | anxiety_moderate==1 | stress_moderate==1


************************
*-- Feeding Practice --*
************************

*==1 clean variables
*correct two labels
la var C1_2a "How soon after birth did the baby suckle at the breast for the first time?(hour)"
la var C1_2b "How soon after birth did the baby suckle at the breast for the first time?(day)"

codebook C1_1
*br if C1_1 == 2
replace C1_1 = 1 if Family_code== 2100304 //replace C1_1 = 1 in 418 //更正一个错填为人工喂养的个案 


codebook C1_8 C1_10 C1_11 C1_17 C1_19 C1_20 C1_21 C1_22 C1_23 C1_24 C1_25
*br if C1_25 == 999
   replace C1_25 = 888 if Family_code== 2030109 //replace C1_25 = 888 in 324
   replace C1_25 = 888 if Family_code== 1030108 //replace C1_25 = 888 in 49 //更正两个错填辅食添加的个案

 replace C1_11 = 2 if Family_code== 1030106 // replace C1_11 = 2 in 47
 replace C1_11 = 2 if Family_code== 1090201 //replace C1_11 = 2 in 136
 replace C1_11 = 2 if Family_code== 3010102 //replace C1_11 = 2 in 577
 replace C1_11 = 1 if Family_code== 1190501 // replace C1_11 = 1 in 268
 replace C1_11 = 1 if Family_code== 1130201 // replace C1_11 = 1 in 208
 replace C1_19 = 2 if Family_code== 2030114 // replace C1_19 = 2 in 329
 replace C1_20 = 2 if Family_code== 3190102 // replace C1_20 = 2 in 804 //更正喂养方式判断中的逻辑问题
 replace C1_8 = 1 if Family_code== 1090201 // replace C1_8 = 1 in 136
 replace C1_10 = 2 if Family_code== 1090201 // replace C1_10 = 2 in 136 //对于_n=136个案，将“母亲不知道昨天喂的食物”私自改入“母乳喂养组”

*==2 gen breasfeeding styles
gen baby_Feeding = .
order baby_Feeding, before(Family_code)
replace baby_Feeding = 3 if C1_1 ==2  // children never breastfed
replace baby_Feeding = 2 if (C1_1 == 1 & C1_8 == 1 & C1_10 == 2 & C1_11 == 2 & C1_17 == 2 & C1_19 == 2 & C1_20 == 2 & C1_21 == 2 & C1_22 == 2 & C1_23 == 2 & C1_24 == 2 & C1_25 == 888)
replace baby_Feeding = 1 if (C1_1 == 1 & (C1_8 == 2 | C1_10 == 1 | C1_11 == 1 | C1_17 == 1 | C1_19 == 1 | C1_20 == 1 | C1_21 == 1 | C1_22 == 1 | C1_23 == 1 | C1_24 == 1 | C1_25 != 888))

label define Feeding 1 "breastfeeding" 2 "exclusive breastfeeding" 3 "non-breastfeeding"
label values baby_Feeding Feeding
codebook baby_Feeding
tab baby_Feeding

*==3. breastfeeding
*=3.1 ever breastfeeding
gen ever_bf=0
replace ever_bf =1 if baby_Feeding==1
tab ever_bf,m

*=3.2 exclusive breastfeeding
gen exclusive_bf=0
replace exclusive_bf =1 if baby_Feeding==2
tab exclusive_bf,m


*************************
*-- Hygiene practices --*
*************************


*==1 handwashing times yesterday
egen handwashing=rowtotal(E3_1__1-E3_1__14)


*==2 handwashing when feed baby

rename E3_10 hw_feed


*==3 handwashing when cleaning your baby's bottom

rename E3_11 hw_clean


******************************
*-- breastfeeding attitude --*
******************************

recode D3_1 (1=5)(2=4)(3=3)(4=2)(5=1)
recode D3_2 (1=5)(2=4)(3=3)(4=2)(5=1)
recode D3_4 (1=5)(2=4)(3=3)(4=2)(5=1)
recode D3_6 (1=5)(2=4)(3=3)(4=2)(5=1)
recode D3_8 (1=5)(2=4)(3=3)(4=2)(5=1)
recode D3_10 (1=5)(2=4)(3=3)(4=2)(5=1)
recode D3_11 (1=5)(2=4)(3=3)(4=2)(5=1)
recode D3_14 (1=5)(2=4)(3=3)(4=2)(5=1)
recode D3_17 (1=5)(2=4)(3=3)(4=2)(5=1)


tab D3_1,m
 foreach num of numlist 1(1)18 {
  replace D3_`num' =. if D3_`num' ==.a
 }
 gen bfatt = .
 replace bfatt = D3_1 + D3_2 + D3_3 + D3_4 + D3_5 + D3_6 + D3_7 + D3_8 + D3_9 + D3_10 + D3_11 + D3_12 + D3_13 + D3_14 + D3_15 + D3_16 + D3_17 + D3_18
 tab bfatt
 codebook bfatt

******************************
*-- breastfeeding efficacy --*
******************************

egen be=rowtotal(D1_1-D1_16)

******************************
*-- breastfeeding knowlege --*
******************************
gen bk_1=0
replace bk_1=1 if D6_1==0

gen bk_2=0
replace bk_2=1 if D6_2==0

gen bk_3=0
replace bk_3=1 if D6_3==0

gen bk_4=0
replace bk_4=1 if D6_4==1

gen bk_5=0
replace bk_5=1 if D6_5==3

gen bk_6=0
replace bk_6=1 if D6_6==3

gen bk_7=0
replace bk_7=1 if D6_7==4

gen bk_8=0
replace bk_8=1 if D6_8==2

gen bk_9=0
replace bk_9=1 if D6_9==1

gen bk_10=0
replace bk_10=1 if D6_10==3

gen bk_11=0
replace bk_11=1 if D6_11__2==1

gen bk_12=0
replace bk_12=1 if D6_12__1==1

egen bf_knowledge_5=rowtotal(bk_1-bk_5)

egen bf_knowledge_7=rowtotal(bk_1-bk_7)

******************************
*----- hygiene knowlege -----*
******************************

gen hygiene_knowledge = bk_12



*======================= some preliminary results  ===========================*

global control child_male baby_AGE premature low_birth_weight age_mom mom_hs_grad dad_hs_grad family_asset
global mh depression_mild anxiety_mild stress_mild any_mild depression_moderate anxiety_moderate stress_moderate any_moderate

global feeding_practice ever_bf exclusive_bf
global hygiene_practice handwashing hw_feed hw_clean

global bf_knowledge bf_knowledge_7
global hy_knowledge bk_12

global bf_att bfatt
global bf_efficacy be

*==1. table 1 demographic info
eststo t1: estpost tabstat $control, stat (mean sd) col(stat) 
	esttab t1 using "table1_demographic.csv", replace unstack label cells(mean(fmt(2)) sd(par fmt(2))) 


*==2. table 2 prevalence of mental health issues 
eststo t1: estpost tabstat $mh, stat (mean sd) col(stat) 
	esttab t1 using "table1_demographic.csv", replace unstack label cells(mean(fmt(2)) sd(par fmt(2))) 

*==3. table 3 childcare
eststo t1: estpost tabstat $feeding_practice $hygiene_practice $bf_knowledge $hy_knowledge $bf_att $bf_efficacy, stat (mean sd) col(stat) 
	esttab t1 using "table1_demographic.csv", replace unstack label cells(mean(fmt(2)) sd(par fmt(2))) 

*==4. regression for breastfeeding practices

eststo clear 
foreach y of varlist $feeding_practice $hygiene_practice $bf_knowledge $hy_knowledge $bf_att $bf_efficacy{
	eststo `y': reg `y' depression_mild $control $feeding_practice
	}
esttab ever_bf exclusive_bf handwashing hw_feed hw_clean bf_knowledge_7 bk_12 bfatt be using "own_all.csv",  ///
ar2 se(3) b(3) replace margin mtitles


eststo clear 
foreach y of varlist $feeding_practice $hygiene_practice $bf_knowledge $hy_knowledge $bf_att $bf_efficacy{
	eststo `y': reg `y' anxiety_mild $control 
	}
esttab ever_bf exclusive_bf handwashing hw_feed hw_clean bf_knowledge_7 bk_12 bfatt be using "own_all.csv",  ///
ar2 se(3) b(3) replace margin mtitles 

 
eststo clear 
foreach y of varlist $feeding_practice $hygiene_practice $bf_knowledge $hy_knowledge $bf_att $bf_efficacy{
	eststo `y': reg `y' stress_mild $control
	}
esttab ever_bf exclusive_bf handwashing hw_feed hw_clean bf_knowledge_7 bk_12 bfatt be using "own_all.csv",  ///
ar2 se(3) b(3) replace margin mtitles 

**control practices for believes

eststo clear 
foreach y of varlist $feeding_practice $hygiene_practice $bf_knowledge $hy_knowledge $bf_att $bf_efficacy{
	eststo `y': reg `y' any_mild $control
	}
esttab ever_bf exclusive_bf handwashing hw_feed hw_clean bf_knowledge_7 bk_12 bfatt be using "own_all.csv",  ///
ar2 se(3) b(3) replace margin mtitles


eststo clear 
foreach y of varlist depression_mild anxiety_mild stress_mild any_mild{
	eststo `y': reg be `y' $control $feeding_practice
	}
esttab depression_mild anxiety_mild stress_mild any_mild using "own_all.csv",  ///
ar2 se(3) b(3) replace margin mtitles


*==5. regression for breastfeeding practices














est clear //full sample 
foreach y of varlist $feeding $child{
	foreach var of varlist $mh{
	logit `y' `var', or
	eststo `y'_u
	logit `y' `var' $control sec_cg, or
	eststo `y'_c
	}
	}
// only illness and doctor visits are significant


est clear //mothers without an assistant
foreach y of varlist $feeding $child{
	foreach var of varlist $mh{
	logit `y' `var' if sec_cg==0, or
	eststo `y'_u
	logit `y' `var' $control if sec_cg==0, or
	eststo `y'_c
	}
	}
// only illness and doctor visits are significant

est clear //mothers with an assistant
foreach y of varlist $feeding $child{
	foreach var of varlist $mh{
	logit `y' `var' if sec_cg==1, or
	eststo `y'_u
	logit `y' `var' $control if sec_cg==1, or
	eststo `y'_c
	}
	}
// only illness and doctor visits are significant & mild depression is positively associated with ever breastfeeding.


* 2 onset of breastfeeding

gen btime=.
replace btime=C1_2a/24 if C1_2==1
replace btime=C1_2b if C1_2==2

est clear //full sample

	foreach var of varlist $mh{
	reg btime `var'
	eststo btime_u
	reg btime `var' $control 
	eststo btime_c
	}
//nothing significant


est clear //mother without an assistant

	foreach var of varlist $mh{
	reg btime `var' if sec_cg==0
	eststo btime_u
	reg btime `var' $control if sec_cg==0
	eststo btime_c
	}
//nothing significant

est clear //mother with an assistant

	foreach var of varlist $mh{
	reg btime `var' if sec_cg==1
	eststo btime_u
	reg btime `var' $control if sec_cg==1
	eststo btime_c
	}
//nothing significant


*3 whether have the formula from birth
gen formula=.
replace formula=1 if C1_14a==0
replace formula=0 if C1_14a!=0	
tab formula,m

est clear //full sample
	foreach var of varlist $mh{
	logit formula `var',or
	eststo formula
	logit formula `var' $control,or
	eststo formula
	}
//nothing significant

est clear //have no assistant
	foreach var of varlist $mh{
	logit formula `var' if sec_cg==0,or
	eststo formula
	logit formula `var' $control if sec_cg==0,or
	eststo formula
	}
//nothing significant


est clear //have asistants
	foreach var of varlist $mh{
	logit formula `var' if sec_cg==1,or
	eststo formula
	logit formula `var' $control if sec_cg==1,or
	eststo formula
	}
//nothing significant
 

*4 how often do you wash your baby's bottles?
// too few variations


*5 micronutrient supplements
gen iron=.
replace iron=1 if C3_1==1
replace iron=0 if C3_1==2


est clear //full sample
	foreach var of varlist $mh{
	logit iron `var',or
	eststo iron
	logit iron `var' $control,or
	eststo iron
	}
//mild stress will have more iron intake

est clear //have no assistant
	foreach var of varlist $mh{
	logit iron `var' if sec_cg==0,or
	eststo iron
	logit iron `var' $control if sec_cg==0,or
	eststo iron
	}
//nothing significant


est clear //have asistants
	foreach var of varlist $mh{
	logit iron `var' if sec_cg==1,or
	eststo iron
	logit iron `var' $control if sec_cg==1,or
	eststo iron
	}
//moderate stress will have more iron intake

*6 breastfeeding efficacy
egen be=rowtotal(D1_1-D1_16)

est clear //full sample

	foreach var of varlist $mh{
	reg be `var'
	eststo be
	reg be `var' $control ever_bf exclusive_bf
	eststo be
	}
//depression mild has lower be


est clear //mother without an assistant

	foreach var of varlist $mh{
	reg be `var' if sec_cg==0
	eststo be
	reg be `var' $control ever_bf exclusive_bf if sec_cg==0
	eststo be
	}
//ed_depression mild

est clear //mother with an assistant

	foreach var of varlist $mh{
	reg be `var' if sec_cg==1
	eststo be
	reg be `var' $control ever_bf exclusive_bf if sec_cg==1
	eststo be
	}
//no significant

*7 breastfeeding efficacy (breakdown)

est clear //full sample 
foreach y of varlist D1_1-D1_16{
	foreach var of varlist $mh{
	reg `y' `var' $control 
	eststo `y'_c
	}
    } // lots of significant findings


foreach var of varlist $mh{
bootstrap r(ind_eff) r(dir_eff), reps(100): sgmediation anemia, iv(`var') mv(be) cv($control)
}

//nothing significant

*8 handwashing times yesterday
egen handwashing=rowtotal(E3_1__1-E3_1__14)
est clear //full sample

	foreach var of varlist $mh{
	reg handwashing `var' $control
	eststo handwashing
	}


	foreach var of varlist $mh{
	reg illness_twice handwashing `var' c.handwashing#i.`var'  $control
	eststo handwashing
	} //not significant
	
	
*9 handwashing when feed baby
est clear //full sample

	foreach var of varlist $mh{
	reg E3_10 `var' $control
	eststo handwashing
	}


*10 handwashing when cleaning your baby's bottom
est clear //full sample

	foreach var of varlist $mh{
	reg E3_11 `var' $control
	eststo handwashing
	}

*11 how many times of breasfeeding yesterday
replace C1_9=. if C1_9==999

est clear //full sample

	foreach var of varlist $mh{
	reg C1_9 `var' $control if type==2
	eststo C1_9
	}
	
*** tables

	
	









	


