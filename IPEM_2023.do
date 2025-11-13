********************************************************************************
* IMPE – Pobreza energética multidimensional Bolivia EH 2023
********************************************************************************

clear all
set more off

*--------------------------------------------------------------
* 0. DEFINICIÓN DE RUTAS (GLOBALES)
*--------------------------------------------------------------
global ruta     "C:\Users\Paolo\Desktop\EH_2023"
global base_unida "${ruta}\EH2023_unida.dta"
global base_salida "${ruta}\IMPE_2023_final.dta"

*--------------------------------------------------------------
* 1. CARGAR BASE
*--------------------------------------------------------------
use "$base_unida", clear

********************************************************************************
* NOTA METODOLÓGICA – VARIABLES Y PREGUNTAS USADAS
*
* DIMENSIONES ENERGÉTICAS (6):
*   Iluminación: s06a_12 (1=Sí tiene electricidad; 2=No)
*   Cocción: s06a_15 (1–2 biomasa)
*   Refrigeración: bienes_hg==4 y s08b_1==1
*   Info/entretenimiento: bienes_hg in 9,10,11,12,13
*   Internet: s06a_19 (1=Sí; 2=No)
*   Climatización: bienes_hg==5 y s08b_1==1
*
* VULNERABILIDADES (V1–V8):
*   V1 Tenencia vivienda: s06a_02
*   V2 Drenaje: s06a_10
*   V3 Basura: s06a_13
*   V4 Educación jefe: aestudio (<12 = sin secundaria)
*   V5 Jefatura femenina: s01a_02
*   V6 Jefe sin seguro: s02a_01a==6
*   V7 Etnia: s01a_09 (1=IOC)
*   V8 Desocupación jefe: condact
********************************************************************************


********************************************************************************
* 2. VARIABLES A NIVEL PERSONA (PARA LUEGO PASAR A HOGAR)
********************************************************************************

* Marcar jefe del hogar
gen byte es_jefe = (s01a_05 == 1)

* Sexo del jefe
gen byte sexo_jefe_p = s01a_02 if es_jefe

* Años de estudio del jefe
gen byte aestudio_jefe_p = aestudio if es_jefe

* Seguro del jefe
gen byte salud_jefe_p = s02a_01a if es_jefe

* Identidad indígena del jefe
gen byte indig_jefe_p = s01a_09 if es_jefe

* Condición de actividad del jefe
gen byte condact_jefe_p = condact if es_jefe

* Bienes del hogar (filas del módulo equipamiento)
gen byte refri_row  = (bienes_hg == 4  & s08b_1 == 1)
gen byte entinfo_row = (inlist(bienes_hg,9,10,11,12,13) & s08b_1 == 1)
gen byte clima_row = (bienes_hg == 5 & s08b_1 == 1)

********************************************************************************
* 3. COLAPSAR A NIVEL HOGAR
********************************************************************************

collapse ///
    (firstnm) depto area totper s06a_02 s06a_10 s06a_13 s06a_12 s06a_15 s06a_19 yhogpc factor ///
    (max)     refri_row entinfo_row clima_row ///
    (max)     sexo_jefe_p aestudio_jefe_p salud_jefe_p indig_jefe_p condact_jefe_p es_jefe ///
    , by(folio)

rename sexo_jefe_p     sexo_jefe
rename aestudio_jefe_p aestudio_jefe
rename salud_jefe_p    salud_jefe
rename indig_jefe_p    indig_jefe
rename condact_jefe_p  condact_jefe

********************************************************************************
* 4. CONSTRUIR VULNERABILIDADES V1–V8 (CRITERIOS BID)
********************************************************************************

* V1 – Tenencia de vivienda: 1 si NO es propia
gen byte V1 = .
replace V1 = 1 if inlist(s06a_02,3,4,5,6,7,8)
replace V1 = 0 if inlist(s06a_02,1,2)

* V2 – Drenaje inadecuado
gen byte V2 = .
replace V2 = 1 if s06a_10 == 4
replace V2 = 0 if inlist(s06a_10,1,2,3)

* V3 – Gestión inadecuada de residuos
gen byte V3 = .
replace V3 = 1 if inlist(s06a_13,1,2,3,4)
replace V3 = 0 if inlist(s06a_13,5,6)

* V4 – Jefe sin secundaria completa (<12 años)
gen byte V4 = .
replace V4 = 1 if aestudio_jefe < 12 & aestudio_jefe != .
replace V4 = 0 if aestudio_jefe >= 12

* V5 – Jefatura femenina
gen byte V5 = .
replace V5 = 1 if sexo_jefe == 2
replace V5 = 0 if sexo_jefe == 1

* V6 – Jefe sin seguro de salud (6 = no tiene)
gen byte V6 = .
replace V6 = 1 if salud_jefe == 6
replace V6 = 0 if inlist(salud_jefe,1,2,3,4,5)

* V7 – Autoidentificación indígena
gen byte V7_indig = .
replace V7_indig = 1 if indig_jefe == 1
replace V7_indig = 0 if inlist(indig_jefe,2,3)

* Complementario
gen byte V7_noindig = .
replace V7_noindig = 1 if inlist(indig_jefe,2,3)
replace V7_noindig = 0 if indig_jefe == 1

* V8 – Jefe desocupado
gen byte V8 = .
replace V8 = 1 if inlist(condact_jefe,2,3)   // cesante, aspirante
replace V8 = 0 if inlist(condact_jefe,1,4,5)

********************************************************************************
* 5. CONTROLES: RURALIDAD E INGRESO PC (CUARTILES)
********************************************************************************

gen byte rural = .
replace rural = 1 if area == 2
replace rural = 0 if area == 1

xtile q_ing = yhogpc [pw=factor], n(4)
label define q_inglbl 1 "Q1 (más pobre)" 2 "Q2" 3 "Q3" 4 "Q4 (más rico)"
label values q_ing q_inglbl

********************************************************************************
* 6. DIMENSIONES DE ACCESO ENERGÉTICO
********************************************************************************

* Iluminación
gen byte d_ilum = .
replace d_ilum = 1 if s06a_12 == 2
replace d_ilum = 0 if s06a_12 == 1

* Cocción con biomasa
gen byte d_coccion = .
replace d_coccion = 1 if inlist(s06a_15,1,2)
replace d_coccion = 0 if inlist(s06a_15,3,4,6,7)

* Refrigeración
gen byte tiene_refri = .
replace tiene_refri = 1 if refri_row == 1
replace tiene_refri = 0 if refri_row == 0
gen byte d_refri = .
replace d_refri = 1 if tiene_refri == 0
replace d_refri = 0 if tiene_refri == 1

* Entretenimiento/información
gen byte tiene_entinfo = .
replace tiene_entinfo = 1 if entinfo_row == 1
replace tiene_entinfo = 0 if entinfo_row == 0
gen byte d_entinfo = .
replace d_entinfo = 1 if tiene_entinfo == 0
replace d_entinfo = 0 if tiene_entinfo == 1

* Internet
gen byte d_internet = .
replace d_internet = 1 if s06a_19 == 2
replace d_internet = 0 if s06a_19 == 1

* Climatización
gen byte tiene_clima = .
replace tiene_clima = 1 if clima_row == 1
replace tiene_clima = 0 if clima_row == 0
gen byte d_clima = .
replace d_clima = 1 if tiene_clima == 0
replace d_clima = 0 if tiene_clima == 1

********************************************************************************
* 7. POBREZA ENERGÉTICA & IMPE (BID)
********************************************************************************

egen byte n_priv = rowtotal(d_ilum d_coccion d_refri d_entinfo d_internet d_clima)

* Pobreza energética severa: TODAS las privaciones
gen byte pe_severa = .
replace pe_severa = 1 if n_priv == 6
replace pe_severa = 0 if n_priv < 6

* Índice IMPE: proporción de privaciones
gen double impe = .
replace impe = (d_ilum + d_coccion + d_refri + d_entinfo + d_internet + d_clima)/6 ///
    if d_ilum<. & d_coccion<. & d_refri<. & d_entinfo<. & d_internet<. & d_clima<.

* Pobreza energética (umbral 1/3)
gen byte pe = .
replace pe = 1 if impe >= 0.3333 & impe < .
replace pe = 0 if impe < 0.3333

********************************************************************************
* 8. GUARDAR BASE FINAL
********************************************************************************

keep folio depto area rural totper factor yhogpc q_ing ///
     V1 V2 V3 V4 V5 V6 V7_indig V7_noindig V8 ///
     d_ilum d_coccion d_refri d_entinfo d_internet d_clima ///
     n_priv pe pe_severa impe

order folio depto area rural yhogpc q_ing totper factor ///
      V1 V2 V3 V4 V5 V6 V7_indig V7_noindig V8 ///
      d_ilum d_coccion d_refri d_entinfo d_internet d_clima ///
      n_priv pe pe_severa impe

save "$base_salida", replace

display "----- BASE FINAL IMPE 2023 GUARDADA -----"
