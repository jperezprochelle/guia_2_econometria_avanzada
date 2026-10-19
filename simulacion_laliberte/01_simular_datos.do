*******************************************************
* SIMULACIÓN - LALIBERTÉ (2021)
* 01_simular_datos.do
*
* Objetivo:
* Crear datos simulados para estudiar el efecto causal
* de la calidad escolar mediante un Spatial RD-IV.
*******************************************************

clear all
set more off

* Fijamos semilla para que los resultados sean replicables
set seed 2026

*******************************************************
* 1. CREAR ESTUDIANTES
*******************************************************

* Número de estudiantes
set obs 50000

* Identificador individual
gen id = _n


*******************************************************
* 2. CARACTERÍSTICAS FAMILIARES
*******************************************************

* Capital educativo familiar no observado
* Esta variable afectará tanto selección escolar como
* resultados educativos -> genera endogeneidad
gen family_ability = rnormal(0,1)

* Características observables
gen female = runiform() < 0.5
gen immigrant = runiform() < 0.20


*******************************************************
* 3. UBICACIÓN RESPECTO DE LA FRONTERA ESCOLAR
*******************************************************

* Distancia a la frontera escolar.
* Valores negativos = lado izquierdo
* Valores positivos = lado derecho
gen distance = runiform(-1,1)

* Instrumento:
* HighSide = 1 si vive del lado asociado
* a la escuela de mayor calidad
gen highside = (distance >= 0)
gen distance_high = distance*highside

label variable distance "Distancia relativa a la frontera"
label variable highside "Lado de escuela asignada de mayor calidad"


*******************************************************
* 4. CALIDAD DE LA ESCUELA EFECTIVAMENTE ASISTIDA
*******************************************************

* La frontera cambia la probabilidad de asistir
* a una escuela de mayor calidad, pero NO la determina
* perfectamente -> Fuzzy RD.

gen latent_school = ///
      -0.8 ///
    + 1.5*highside ///
    + 0.55*family_ability ///
    + rnormal(0,1)

gen high_quality_school = (latent_school > 0)

label variable high_quality_school ///
    "Asiste a escuela de alta calidad"


*******************************************************
* 5. OUTCOME EDUCACIONAL
*******************************************************

* Verdadero efecto causal de asistir a una mejor escuela
scalar beta_school_true = 0.60

* Años de educación
*
* family_ability afecta tanto escuela como outcome.
* Por eso OLS sufrirá sesgo de selección.

gen years_education = ///
      12 ///
    + beta_school_true*high_quality_school ///
    + 0.8*family_ability ///
    + 0.15*female ///
    + rnormal(0,1)


*******************************************************
* 6. VARIABLES AUXILIARES
*******************************************************

label variable years_education "Años de educación"

compress

*******************************************************
* 7. GUARDAR BASE
*******************************************************

capture mkdir "data"

save "data/datos_simulados.dta", replace

*******************************************************
* RESUMEN
*******************************************************

summarize years_education high_quality_school ///
          distance family_ability

tab highside high_quality_school, row

display "Verdadero efecto causal de escuela = " ///
        beta_school_true
