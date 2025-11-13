********************************************************************************
* PROXIS UNIDIMENSIONALES DE POBREZA ENERGÉTICA – EH 2023
********************************************************************************

clear all
set more off

global path "C:\Users\Paolo\Desktop\EH_2023"
use "$path\EH2023_unida.dta", clear


********************************************************************************
* 1. MARCO METODOLÓGICO 
********************************************************************************

* Dado que la EH2023 no proporciona gasto energético ni consumo efectivo,
* se opta a una estrategia de proxies basada en:
*   - Acceso a servicios energéticos esenciales
*   - Tipo de combustible utilizado para cocinar
*   - Existencia de equipamiento básico dependiente de energía
*   - Condición de pobreza por ingresos del hogar (p0)
*
* Este enfoque es consistente con:
*   • Boardman (1991): Energy Deprivation
*   • IEA/OMS (2016): Cooking Access Framework
*   • BID (2023): Servicios energéticos mínimos
*   • Moore (2012): Hidden Energy Poverty
*
***************************************************


********************************************************************************
* 2. VARIABLES ENERGÉTICAS 
********************************************************************************

*** Electricidad para alumbrado
* Pregunta: s06a_12 — ¿Usa energía eléctrica para alumbrar esta vivienda?

gen luz = (s06a_12 == 1)
gen no_luz = (s06a_12 == 2)

label var luz     "Tiene electricidad para alumbrar (s06a_12)"
label var no_luz  "No tiene electricidad (privación)"


*** Combustible para cocinar
* Pregunta: s06a_15 — tipo de energía utilizada para cocinar.

gen biomasa = inlist(s06a_15,1,2)
label var biomasa "Cocina con combustibles sólidos (leña o bosta)"


*** Equipamiento del hogar (bienes duraderos energéticos)
* Preguntas: bienes_hg (ítem 1–17) + s08b_1 (1=tiene)
* Utilizo:
*   item 4  = refrigerador
*   items 9–13 = radio/TV/sonido
*   item 5  = ventilador/aire/estufa

gen refri_row = (bienes_hg==4  & s08b_1==1)
gen info_row  = (inlist(bienes_hg,9,10,11,12,13) & s08b_1==1)
gen clima_row = (bienes_hg==5  & s08b_1==1)

label var refri_row "Tiene refrigerador (item 4)"
label var info_row  "Tiene radio/TV/sonido (items 9–13)"
label var clima_row "Tiene equipo de climatización/ventilación (item 5)"


********************************************************************************
* 3. PROXIS UNIDIMENSIONALES 
********************************************************************************

*** 1. Pobreza energética por biomasa

gen pe_biomasa = biomasa
label var pe_biomasa "PE unidim: cocina con biomasa"


*** 2. Pobreza energética por falta de electricidad

gen pe_sin_luz = no_luz
label var pe_sin_luz "PE unidim: sin electricidad para alumbrar"


*** 3. Deprivación energética mínima (sin refrigerador)

gen pe_sin_refri = (refri_row == 0)
label var pe_sin_refri "PE unidim: sin refrigerador"


*** 4. Deprivación informativa (sin radio/TV)

gen pe_sin_info = (info_row == 0)
label var pe_sin_info "PE unidim: sin TV/Radio"


*** 5. Vulnerabilidad energética: pobre + biomasa

capture confirm variable p0
if !_rc {
    gen pe_pobre_biomasa = (p0==1 & biomasa==1)
    label var pe_pobre_biomasa "PE unidim: pobre por ingresos + biomasa"
}


*** 6. Vulnerabilidad energética: pobre + sin electricidad

capture confirm variable p0
if !_rc {
    gen pe_pobre_sinluz = (p0==1 & no_luz==1)
    label var pe_pobre_sinluz "PE unidim: pobre por ingresos + sin electricidad"
}


*** 7. Hidden Energy Poverty (M/2 adaptado)
* En ausencia de datos de gasto, se adopta una adaptación del método M/2

* Servicios energéticos incluidos:
*   - Electricidad para alumbrado (luz)
*   - Cocina con energía moderna (gas o electricidad)
*   - Refrigeración
*   - Información/entretenimiento
*   - Climatización básica

gen energia_moderna = inlist(s06a_15,3,4,6)

egen energy_score = rowtotal(luz energia_moderna refri_row info_row clima_row)

summ energy_score, detail
local med = r(p50)
local umbral = `med'/2

gen pe_M2 = (energy_score < `umbral')
label var pe_M2 "PE unidim: Hidden Energy Poverty (M/2 adaptado)"


********************************************************************************
* 4. ORGANIZAR VARIABLES DE SALIDA
********************************************************************************

order folio depto area ///
      pe_biomasa pe_sin_luz pe_sin_refri pe_sin_info ///
      pe_pobre_biomasa pe_pobre_sinluz pe_M2 ///
      energy_score biomasa luz refri_row info_row clima_row

save "$path/IMPE_unidimensional_proxies_2023.dta", replace

