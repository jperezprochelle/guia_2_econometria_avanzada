*******************************************************
* SIMULACIÓN - LALIBERTÉ (2021)
* 03_movers.do
*
* Objetivo:
* Simular un movers design y recuperar la tasa causal
* de convergencia hacia el barrio de destino.
*******************************************************

clear all
set more off
set seed 2027

*******************************************************
* 1. CREAR MUESTRA DE MOVERS
*******************************************************

set obs 30000

gen id = _n


*******************************************************
* 2. BARRIOS DE ORIGEN Y DESTINO
*******************************************************

* 20 barrios posibles
gen origin = ceil(runiform()*20)
gen destination = ceil(runiform()*20)

* Evitar que origen = destino
replace destination = mod(destination,20)+1 ///
    if destination == origin

* Calidad estructural de cada barrio
* Creamos una relación ordenada entre barrio y outcome
gen origin_quality = (origin-10.5)/5
gen destination_quality = (destination-10.5)/5


*******************************************************
* 3. DIFERENCIA ENTRE DESTINO Y ORIGEN
*******************************************************

gen delta_quality = destination_quality - origin_quality

label variable delta_quality ///
    "Diferencia de calidad entre destino y origen"


*******************************************************
* 4. EDAD DE MUDANZA
*******************************************************

* Edad entre 7 y 15 años
gen age_move = floor(7 + 9*runiform())

* Años de exposición al destino hasta los 15
gen years_exposure = 16 - age_move

label variable age_move "Edad al momento de mudanza"
label variable years_exposure "Años expuesto al destino"


*******************************************************
* 5. CARACTERÍSTICAS INDIVIDUALES
*******************************************************

gen move_interaction = age_move * delta_quality

gen female = runiform() < 0.5
gen immigrant = runiform() < 0.20

* Habilidad familiar no observada
gen family_ability = rnormal(0,1)


*******************************************************
* 6. EFECTO CAUSAL VERDADERO DE EXPOSICIÓN
*******************************************************

scalar beta_movers_true = 0.05

* Efecto acumulativo:
* cada año adicional en el destino multiplica
* la diferencia entre destino y origen

gen exposure_effect = ///
    beta_movers_true * years_exposure * delta_quality


*******************************************************
* 7. OUTCOME
*******************************************************

gen years_education = ///
      12 ///
    + 0.5*origin_quality ///
    + exposure_effect ///
    + 0.7*family_ability ///
    + 0.15*female ///
    + rnormal(0,1)


*******************************************************
* 8. ORIGIN x DESTINATION FIXED EFFECT
*******************************************************

egen od_pair = group(origin destination)

label variable od_pair "Par origen-destino"


*******************************************************
* 9. GUARDAR BASE
*******************************************************

capture mkdir "data"

save "data/movers_simulados.dta", replace


*******************************************************
* 10. RESUMEN
*******************************************************

summarize years_education age_move ///
          years_exposure delta_quality

display "Tasa verdadera de convergencia = " ///
        beta_movers_true
