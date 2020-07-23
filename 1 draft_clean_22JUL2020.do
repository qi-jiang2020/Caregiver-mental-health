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

//imput the date
use "$datadir/0_baseline_hf_mom_only.dta", clear

//drop pregnant women and keep the newborns
keep if type==2

//merge the child anemia data
merge 1:1 Family_code using "/Users/jiangqi/Desktop/papers/34_2020_HF_mental_health_paper/1 codebook/Baseline V1/3.Data/Exam/BASE_EXAM_L2_1.dta"
keep if _merge==3 //444 not merged (401 from using data, 43 from master data), 837 merged
drop _merge

merge 1:1 Family_code using "/Users/jiangqi/Desktop/papers/34_2020_HF_mental_health_paper/1 codebook/Baseline V1/3.Data/Exam/BASE_EXAM_HEAD_1.dta"
keep if _merge==3 
drop _merge

*==1.1 feeding practice

//correct two labels
la var C1_2a "How soon after birth did the baby suckle at the breast for the first time?(hour)"
la var C1_2b "How soon after birth did the baby suckle at the breast for the first time?(day)"

gen baby_Feeding = .
order baby_Feeding, before(Family_code)
codebook C1_1
*br if C1_1 == 2
replace C1_1 = 1 in 418 //更正一个错填为人工喂养的个案
replace baby_Feeding = 3 if C1_1 ==2
codebook baby_Feeding //共有49个人工喂养的个案

codebook C1_8 C1_10 C1_11 C1_17 C1_19 C1_20 C1_21 C1_22 C1_23 C1_24 C1_25
*br if C1_25 == 999
   replace C1_25 = 888 in 324
   replace C1_25 = 888 in 49 //更正两个错填辅食添加的个案

 replace C1_11 = 2 in 47
 replace C1_11 = 2 in 136
 replace C1_11 = 2 in 577
 replace C1_11 = 1 in 268
 replace C1_11 = 1 in 208
 replace C1_19 = 2 in 329
 replace C1_20 = 2 in 804 //更正喂养方式判断中的逻辑问题
 replace C1_8 = 1 in 136
 replace C1_10 = 2 in 136 //对于_n=136个案，将“母亲不知道昨天喂的食物”私自改入“母乳喂养组”

replace baby_Feeding = 2 if (C1_1 == 1 & C1_8 == 1 & C1_10 == 2 & C1_11 == 2 & C1_17 == 2 & C1_19 == 2 & C1_20 == 2 & C1_21 == 2 & C1_22 == 2 & C1_23 == 2 & C1_24 == 2 & C1_25 == 888)
replace baby_Feeding = 1 if (C1_1 == 1 & (C1_8 == 2 | C1_10 == 1 | C1_11 == 1 | C1_17 == 1 | C1_19 == 1 | C1_20 == 1 | C1_21 == 1 | C1_22 == 1 | C1_23 == 1 | C1_24 == 1 | C1_25 != 888))
count if baby_Feeding == 0
*br if baby_Feeding == 0

label define Feeding 1 "breastfeeding" 2 "exclusive breastfeeding" 3 "non-breastfeeding"
label values baby_Feeding Feeding
codebook baby_Feeding
tab baby_Feeding


*======================= clean control variables ==============================*
*==1 child gender 
tab B1_6,m
recode B1_6 (2=0)

rename B1_6 child_male 
label var child_male "baby male (1=yes)"

tab child_male,m

*==2 child age 

/////baby age

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

/*
*=2.1 generate the investage date

gen inv_date_year=substr(Inv_date,1,4)
gen inv_date_mon=substr(Inv_date,6,2)
gen inv_date_day=substr(Inv_date,9,2)
gen inv_date=inv_date_year+inv_date_mon+inv_date_day
tab inv_date,m

drop if B1_1 ==201906010|B1_1 ==202191208 // clean abnormal values
 
*=2.2 formate the investage date
tab inv_date,m
gen inv_datee = date(inv_date, "YMD")
format inv_datee %dCY_N_D

*=2.3 formate the birth date
tostring B1_1,replace
gen birth_date=date(B1_1, "YMD")
format birth_date %dCY_N_D
tab birth_date,m

*=2.4 generate the child age in days
gen child_age=inv_datee-birth_date
tab child_age,m

/*
*=2.5 generate the child age in months
replace child_age = child_age/30
tab child_age,m

*=2.6 clean abnormal data
replace child_age=. if child_age>100

*=2.7 generate dummy - whether the age of children is above the mean
codebook child_age //m=1.85
gen child_age_ave=0
replace child_age_ave=1 if child_age>=1.85
*/
*/
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


*==10 father migration status
tab B1_11,m

gen dad_at_home=.
replace dad_at_home=1 if B1_11==1
replace dad_at_home=0 if B1_11==2

label var dad_at_home "father_migrants(1=yes)"
tab dad_at_home,m



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


*==12 whether mom is from the village
gen mom_village =.

replace mom_village = 1 if B2_1 == 1
replace mom_village = 0 if B2_1 == 2

label var mom_village "is mom from the village(1=yes)"

*==13 have mother migranted before?
gen mom_migrant_b =.

replace mom_migrant_b = 1 if B2_2==1
replace mom_migrant_b = 0 if B2_2==2

label var mom_migrant_b "has mom migranted before(1=yes)"

*==14 does mother plan to migrant?
gen mom_migrant_a=.

replace mom_migrant_a=1 if B2_6==1
replace mom_migrant_a=0 if B2_6==2|B2_6==3

label var mom_migrant_a "does mom plan to migrant(1=yes)"

*==15 number of illness

foreach num of numlist 1(1)15 {
	gen ill_`num'=0
	replace ill_`num' =1 if E2_`num' == 1
	}

egen illness=rowtotal(ill_1-ill_15)
tab illness,m

label var illness "number of illness"

drop ill_1-ill_15

gen illness_yes = .
replace illness_yes = 0 if illness ==0
replace illness_yes = 1 if illness >0 & illness<999

label var illness "does the child have illness? 1=yes"

gen illness_twice=.
replace illness_twice = 0 if illness<2
replace illness_twice = 1 if illness>=2 & illness<999
label var illness_twice "has the child been ill at least twice?1=yes"


*==16 number of doctor visits for illness symptoms
tab E2_16,m
 
gen visit_dr=E2_16
replace visit_dr=. if visit_dr>100
replace visit_dr=0 if illness==0

tab visit_dr,m //300+ missing values, need to be checked


gen visit_dr_yes=.
replace visit_dr_yes=1 if visit_dr>0 & visit_dr<999
replace visit_dr_yes=0 if visit_dr==0

label var visit_dr_yes "did the child visit doctor? 1=yes"

*==19 delivery method
tab E1_5,m

gen is_shunchan =.
replace is_shunchan=1 if E1_5==1 | E1_5==2
replace is_shunchan=0 if E1_5==3

tab is_shunchan,m

label var is_shunchan "vaginal birth (natural or assisted)(1=yes)"

*==20 first pregnancy
tab F7_1,m

gen first_pregnancy=.
replace first_pregnancy=1 if F7_1==0
replace first_pregnancy=0 if F7_1>0 & F7_1<100


*==21 previous miscarriage
replace F7_2=0 if F7_1==0
gen miscarriage=F7_1-F7_2
tab miscarriage,m
replace miscarriage=. if miscarriage==50
replace miscarriage=. if miscarriage==-1

gen miscarriage_yes=.
replace miscarriage_yes=0 if miscarriage==0
replace miscarriage_yes=1 if miscarriage>0 & miscarriage<999

label var miscarriage "has mother miscarriage before? 1=yes"


*======================= clean mental health variables ========================*
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

*= dummy score
gen depression_yes=.
replace depression_yes=1 if depression_score>9 & depression_score<9999
replace depression_yes=0 if depression_score<=9
tab depression_yes,m

gen anxiety_yes=.
replace anxiety_yes=1 if anxiety_score>7 & anxiety_score<999
replace anxiety_yes=0 if anxiety_score<=7
tab anxiety_yes,m

gen stress_yes=.
replace stress_yes=1 if stress_score>14 & stress_score<999
replace stress_yes=0 if stress_score<=14
tab stress_yes,m

gen any_yes = depression_yes==1 | anxiety_yes==1 | stress_yes==1


*======================= clean child-outcome variables ========================*
*1. anemia
/*
*==1.1 drop the missing valules
codebook Baby_1

drop if Baby_1==2 //558 obs left
drop if child_age<1.4

drop if child_age>7


*/


/////baby hemoglobin concentration——结局变量的处理
codebook Baby_1 Baby_2 Baby_2_P Baby_3 T3_1

count if Baby_1 != 1 & baby_age < 42 & baby_age != . //187个小于42天未测血个案

count if Baby_1 == 1 & baby_age < 42 & baby_age != . //23个小于42天但已测血个案
codebook baby_age 
replace baby_age = 60 if baby_age == . //对7个不明原因缺失值进行处理

gen baby_hgb = .
order baby_hgb, before(baby_AGE)
replace baby_hgb = Baby_3 if Baby_3 != . & baby_age >= 42 //共有586个大于42天已测血个案
count if baby_age < 42 //共有210个小于42天个案，故测血率为80.49%
codebook baby_hgb
count if baby_hgb != . & type == 2 //共有549个符合条件；一看为母亲，大于42天，且已完成测血的个案

//对海拔的处理
codebook T3_1
tab T3_1,m
replace T3_1 = "353.57" in 759
replace T3_1 = "357.18" in 19 //对两个海拔异常值进行处理

gen altitude = real(T3_1) //将海拔转换为数值型变量
codebook altitude
tab altitude,m
order altitude , after(T3_1)
replace altitude = 409 if altitude  == 4409
replace altitude = 500 if altitude  == 5
replace altitude = . if altitude  == 0
replace altitude = . if altitude  == 999
*br if altitude <  100
replace altitude = 366.599998 in 69
count if baby_hgb ==1 & altitude == . //没有空值，也就是说测了血的个案都填了海拔

//生成baby_HGB，即标准化后的血红蛋白浓度
gen baby_HGB = baby_hgb/(1.04^((altitude-72.26)/1000)) 
format baby_HGB %9.2f
order baby_HGB, before(baby_AGE)
codebook baby_HGB
count if baby_hgb != . & baby_HGB ==. //没有缺失值产生
tab baby_HGB

*histogram baby_HGB,percent by(county,total)

*twoway lfit baby_HGB baby_age || scatter baby_HGB baby_age
*twoway lfit baby_HGB baby_AGE || scatter baby_HGB baby_AGE

*graph box baby_HGB, over(baby_AGE)

*graph box baby_HGB,marker(1,mlabel(Family_code)) //有6个特异值

sktest baby_HGB //对结局变量做正态性检验（偏态-峰态检验），发现服从正态分布
swilk baby_HGB //对结局变量做正态性检验（Shapiro-Wilk检验），发现服从正态分布

lv baby_HGB //结局变量中有6个轻度特异值，暂不予处理

gen baby_Anemia = .
order baby_Anemia, before(baby_AGE)
replace baby_Anemia = 1 if ( baby_HGB < 90 & baby_AGE < 4 & baby_HGB != . )
replace baby_Anemia = 1 if ( baby_HGB < 100 & baby_AGE >= 4 & baby_HGB != . )
replace baby_Anemia = 0 if ( baby_HGB >= 90 & baby_AGE < 4 & baby_HGB != . )
replace baby_Anemia = 0 if ( baby_HGB >= 100 & baby_AGE >= 4 & baby_HGB != . )
la values baby_Anemia choose
codebook baby_Anemia 
// 586例个案中，共有121例贫血，贫血检出率为20.65%
*---

drop if baby_Anemia==.
tab baby_Anemia,m

*========================== perinatal depression ==============================*
recode G2_1 (0=3)(1=2)(2=1)(3=0)
recode G2_2 (0=3)(1=2)(2=1)(3=0)

egen perinatal_depression=rowtotal(G2_1-G2_10)

tab perinatal_depression,m













*======================= some preliminary results  ===========================*
* anemia and mental health


global ses age_mom mom_hs_grad mom_village mom_migrant_b mom_migrant_a first_pregnancy miscarriage_yes dad_hs_grad family_asset
global child child_male baby_AGE is_shunchan premature low_birth_weight
global mh depression_yes anxiety_yes stress_yes any_yes

*is_shunchan premature low_birth_weight
est clear
foreach var of varlist $mh{
logit baby_Anemia `var' $ses $child, or 
eststo `var'_full
}

outreg2 [depression_yes_full anxiety_yes_full stress_yes_full any_yes_full] using "ses_all.xls", ///
ci eform excel dec(3) label title ("regression table") pde(4) replace alpha(0.001, 0.01, 0.05)




* breastfeeding and mental health

gen ever_bf=0
replace ever_bf =1 if baby_Feeding==1
tab ever_bf,m

est clear
foreach var of varlist $mh{
logit ever_bf `var' $ses $child, or 
eststo `var'_full
}

outreg2 [depression_yes_full anxiety_yes_full stress_yes_full any_yes_full] using "ses_all.xls", ///
ci eform excel dec(3) label title ("regression table") pde(4) replace alpha(0.001, 0.01, 0.05)



* exclusive breastfeeding and mental health

gen exclusive_bf=0
replace exclusive_bf =1 if baby_Feeding==2
tab exclusive_bf,m

est clear
foreach var of varlist $mh{
logit exclusive_bf `var' $ses $child, or 
eststo `var'_full
}

outreg2 [depression_yes_full anxiety_yes_full stress_yes_full any_yes_full] using "ses_all.xls", ///
ci eform excel dec(3) label title ("regression table") pde(4) replace alpha(0.001, 0.01, 0.05)


est clear
logit baby_Anemia exclusive_bf  $ses $child, or 
eststo exclusive_bf

logit baby_Anemia ever_bf  $ses $child, or 
eststo ever_bf

outreg2 [exclusive_bf ever_bf] using "ses_all.xls", ///
ci eform excel dec(3) label title ("regression table") pde(4) replace alpha(0.001, 0.01, 0.05)


est clear
logit baby_Anemia exclusive_bf $child, or 
eststo exclusive_bf

logit baby_Anemia ever_bf $child, or 
eststo ever_bf

outreg2 [exclusive_bf ever_bf] using "ses_all.xls", ///
ci eform excel dec(3) label title ("regression table") pde(4) replace alpha(0.001, 0.01, 0.05)



* some prevalence


*Table 1. 
eststo t1: estpost tabstat $mh ever_bf exclusive_bf baby_Anemia, stat (mean sd) col(stat) 
	esttab t1 using "table1_demographic.csv", replace unstack label cells(mean(fmt(2)) sd(par fmt(2))) 


* perinatal depression

reg baby_Anemia perinatal_depression $ses $child

reg ever_bf perinatal_depression $ses $child
reg exclusive_bf perinatal_depression $ses $child



,




