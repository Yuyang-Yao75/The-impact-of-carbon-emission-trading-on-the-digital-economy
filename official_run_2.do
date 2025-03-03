use "/Users/yaoyuyang/Desktop/保研相关/科研日记/数据/处理数据/official_run_2/official_run_2.dta", clear

encode prov_name,gen(prov)
xtset prov year

xtline digeco

xtline digeco, overlay
* 标记干预前后
gen ppost = year >= 2014

* 创建处理与时间的交互项
gen did = Policy * ppost

*基准回归
*不考虑控制变量考虑省级固定效应
reg digeco did i.prov, r
*不考虑控制变量考虑双固定效应
reg digeco did i.prov i.year, r
*考虑控制变量考虑省级固定效应
reg digeco did lnedu lnfdi lnpgdp lnpwage gov i.prov, r
*考虑控制变量考虑双固定效应
reg digeco did lnedu lnfdi lnpgdp lnpwage gov i.prov i.year, r

*平行趋势检验
gen event = year - 2014

forvalues i=4(-1)1{
  gen pre`i'=(event==-`i'& Policy==1)
}
 
gen current=(event==0 & Policy==1)
 
forvalues i=1(1)7{
  gen post`i'=(event==`i'& Policy==1)
}

drop pre1 

reg digeco  pre* current post*  i.year i.prov ,r

coefplot, baselevels vertical keep(pre* current post*) omitted order(pre* current post*) level(95) yline(0,lcolor(edkblue*0.8)) xline(3, lwidth(vthin) lpattern(dash) lcolor(teal))ylabel(,labsize(*0.75)) xlabel(,labsize(*0.75)) ytitle("政策动态效应", size(small)) xtitle("政策时点", size(small)) addplot(line @b @at) ciopts(lpattern(dash) recast(rcap) msize(medium)) msymbol(circle_hollow) 
scheme(s1mono)


*安慰剂检验（简单方法+交互项随机抽取）
use "/Users/yaoyuyang/Desktop/保研相关/科研日记/数据/处理数据/official_run/official_run.dta", clear
encode prov_name,gen(prov)
xtset prov year
* 标记干预前后
gen ppost = year >= 2014
* 创建处理与时间的交互项
gen did = Policy * ppost
reghdfe digeco did, absorb(prov year) vce(robust)
 
cap erase "simulations.dta"
permute did beta = _b[did] se = _se[did] df = e(df_m), ///
 reps(500) seed(123) saving("simulations.dta"): ///
  reghdfe digeco did, absorb(prov year) vce(robust)


// 回归系数
use "simulations.dta",clear
gen t_value = beta / se
gen p_value = 2 * ttail(df, abs(beta/se))

#delimit ;
dpplot beta, 
 xline( 0.068, lc(black*0.5) lp(dash))
 xline(0, lc(black*0.5) lp(solid))
 xlabel(-0.03(0.01)0.03)
    xtitle("Estimator", size(*0.8)) xlabel(, format(%4.2f) labsize(small))
    ytitle("Density", size(*0.8)) ylabel(, nogrid format(%4.2f) labsize(small)) 
    note("") caption("") graphregion(fcolor(white)) ;
#delimit cr
 
  // t 值
#delimit ;
dpplot t_value, 
 xline(-1.960, lc(black*0.5) lp(dash))
 xline(0, lc(black*0.5) lp(solid))
    xtitle("T Value", size(*0.8)) xlabel(, format(%4.2f) labsize(small))
    ytitle("Density", size(*0.8)) ylabel(, nogrid format(%4.2f) labsize(small)) 
    note("") caption("") graphregion(fcolor(white)) ;
#delimit cr
 // p 值 根据基准结果调整p值，小数点保留位数
#delimit ;
dpplot p_value, 
 xline(0.068, lc(black*0.5) lp(dash))
    xtitle("P Value", size(*0.8)) xlabel(, format(%4.1f) labsize(small))
    ytitle("Density", size(*0.8)) ylabel(, nogrid format(%4.1f) labsize(small)) 
    note("") caption("") graphregion(fcolor(white)) ;
#delimit cr

 // 系数和 p 值结合
#delimit ;
twoway (scatter p_value beta)(kdensity beta, yaxis(2)), 
 xline( 0.068, lc(black*0.5) lp(dash))
 xline(0, lc(black*0.5) lp(solid)) 
 yline(0.0001, lc(black*0.5) lp(dash))
 xlabel(-0.08(0.02)0.08)
 ylabel(0(0.2)1)
 xtitle("Estimator", size(*0.8)) xlabel(, format(%4.2f) labsize(small))
 ytitle("Density", size(*0.8)) ylabel(, nogrid format(%4.1f) labsize(small)) 
 ytitle("P Value", size(*0.8) axis(2)) ylabel(, nogrid format(%4.1f) labsize(small) axis(2))
 legend(r(1) order(1 "P Value" 2 "Estimator"))
 graphregion(color(white)) ;
#delimit cr

  
*中介效应检验1：技术创新
reg digeco did lnedu lnfdi lnpgdp lnpwage gov i.prov i.year, r
reg tec did lnedu lnfdi lnpgdp lnpwage gov i.prov i.year, r
reg digeco did tec lnedu lnfdi lnpgdp lnpwage gov i.prov i.year, r
bootstrap r(ind_eff) r(dir_eff), reps(1000): sgmediation digeco, mv(tec) iv(did) cv(lnedu lnfdi lnpgdp lnpwage gov)

*中介效应检验2：产业结构
reg digeco did lnedu lnfdi lnpgdp lnpwage gov i.prov i.year, r
reg str did lnedu lnfdi lnpgdp lnpwage gov i.prov i.year, r
reg digeco did str lnedu lnfdi lnpgdp lnpwage gov i.prov i.year, r
bootstrap r(ind_eff) r(dir_eff), reps(1000): sgmediation digeco, mv(str) iv(did) cv(lnedu lnfdi lnpgdp lnpwage gov )

*异质性检验：中西部
reg digeco did lnedu lnfdi lnpgdp lnpwage gov i.prov i.year if middle == 1 | west == 1, robust
*异质性检验：东部
reg digeco did lnedu lnfdi lnpgdp lnpwage gov i.prov i.year if east == 1 , robust
*异质性检验：中部
reg digeco did lnedu lnfdi lnpgdp lnpwage gov i.prov i.year if middle == 1, robust
*异质性检验：西部
reg digeco did lnedu lnfdi lnpgdp lnpwage gov i.prov i.year if west == 1, robust
*异质性检验：南部
reg digeco did lnedu lnfdi lnpgdp lnpwage gov i.prov i.year if south == 1, robust
*异质性检验：北部
reg digeco did lnedu lnfdi lnpgdp lnpwage gov i.prov i.year if north == 1, robust

*更换时间使ok的
reg digeco did lnedu lnfdi lnpgdp lnpwage gov i.prov i.year if year == 2011|year == 2012|year == 2013|year == 2014|year == 2015|year == 2016|year == 2017, robust

*调节效应
gen lntrans=ln(trans)
gen lnpri=ln(pri)
gen lnliq=ln(liq)

gen lntransdid=lntrans*did
gen lnpridid=lnpri*did
gen liqdid=liq*did

reg digeco did lntransdid lnedu lnfdi lnpgdp lnpwage gov i.prov i.year, r
reg digeco did lnpridid lnedu lnfdi lnpgdp lnpwage gov i.prov i.year, r
reg digeco did liqdid lnedu lnfdi lnpgdp lnpwage gov i.prov i.year, r



*更换被解释变量：效果不太好这个
use "/Users/yaoyuyang/Desktop/保研相关/科研日记/数据/处理数据/official_run_2/diguf.dta", clear

egen min_digeco = min(digeco)
egen max_digeco = max(digeco)
generate minmax_digeco = (digeco - min_digeco) / (max_digeco - min_digeco)

encode prov_name,gen(prov)
xtset prov year

xtline digeco

xtline digeco, overlay
* 标记干预前后
gen ppost = year >= 2014

* 创建处理与时间的交互项
gen did = Policy * ppost

reg minmax_digeco did i.prov, r
reg minmax_digeco did i.prov i.year, r
reg minmax_digeco did lnedu lnfdi lnpgdp lnpwage gov i.prov, r
reg minmax_digeco did lnedu lnfdi lnpgdp lnpwage gov i.prov i.year, r





*PSM-DID
set  seed 0000
gen  norvar_1 = rnormal()
sort norvar_1

psmatch2 Policy  lnedu lnfdi lnpgdp lnpwage gov, outcome(digeco) logit neighbor(2) ties common    ///
                          ate caliper(0.05)
save csdata.dta, replace

pstest, both graph saving(balancing_assumption, replace)
graph export "balancing_assumption.emf", replace

psgraph, saving(common_support, replace)
graph export "common_support.emf", replace

sum _pscore if Policy == 1, detail  // 
sum _pscore if Policy == 0, detail
twoway(kdensity _pscore if Policy == 1, lpattern(solid)                     ///
              lcolor(black)                                                  ///
              lwidth(thin)                                                   ///
              scheme(qleanmono)                                              ///
              ytitle("{stSans:核}""{stSans:密}""{stSans:度}",                ///
                     size(medlarge) orientation(h))                          ///
              xtitle("{stSans:匹配前的倾向得分值}",                          ///
                     size(medlarge))                                         ///
              xline(0.4746616   , lpattern(solid) lcolor(black))                ///
              xline(`r(mean)', lpattern(dash)  lcolor(black))                ///
              saving(kensity_cs_before, replace))                            ///
      (kdensity _pscore if Policy == 0, lpattern(dash)),                    ///
      xlabel(     , labsize(medlarge) format(%02.1f))                        ///
      ylabel(0(1)4, labsize(medlarge))                                       ///
      legend(label(1 "{stSans:处理组}")                                      ///
             label(2 "{stSans:控制组}")                                      ///
             size(medlarge) position(1) symxsize(10))

sum _pscore if Policy == 0 & _weight != ., detail

twoway(kdensity _pscore if Policy == 1, lpattern(solid)                     ///
              lcolor(black)                                                  ///
              lwidth(thin)                                                   ///
              scheme(qleanmono)                                              ///
              ytitle("{stSans:核}""{stSans:密}""{stSans:度}",                ///
                     size(medlarge) orientation(h))                          ///
              xtitle("{stSans:匹配后的倾向得分值}",                          ///
                     size(medlarge))                                         ///
              xline(0.4746616   , lpattern(solid) lcolor(black))                ///
              xline(`r(mean)', lpattern(dash)  lcolor(black))                ///
              saving(kensity_cs_after, replace))                             ///
      (kdensity _pscore if Policy == 0 & _weight != ., lpattern(dash)),     ///
      xlabel(     , labsize(medlarge) format(%02.1f))                        ///
      ylabel(0(1)4, labsize(medlarge))                                       ///
      legend(label(1 "{stSans:处理组}")                                      ///
             label(2 "{stSans:控制组}")                                      ///
             size(medlarge) position(1) symxsize(10))
use csdata.dta, clear


