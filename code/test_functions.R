trace(utils:::unpackPkgZip, edit=TRUE)

# Correr c√≥digo de Python
library(reticulate)
library(openxlsx)
#use_python("/usr/bin/python3")

## install.packages("RSocrata")

library(RSocrata)



df <- read.socrata(
  "https://www.datos.gov.co/resource/whri-jckt.json",
  app_token = "WnkJhtSI1mjrtpymw0gVNZEcl"
)

py_run_string("import numpy as np")
py_run_string("import pandas as pd")
py_run_string("import sys")
py_run_string("sys.setrecursionlimit(10000)")

# Puse la de test aquÌ arriba por weÛn, pero en teorÌa solo deberÌa ir esto y nada m·s
base_original <-  py_run_string("base_original=pd.read_excel('C:/Users/LcmayorquinL/OneDrive - Departamento Nacional de Planeacion/DIDE/2019/Data Science Projects/Data-Quality-App/data/test.xlsx')")
base_original <- base_original$base_original

py_run_file("C:/Users/LcmayorquinL/OneDrive - Departamento Nacional de Planeacion/DIDE/2019/Data Science Projects/Data-Quality-App/code/funciones.py")

# Array
tabla_resumen <- py_run_string("tabla_resumen_o = tabla_resumen(base_original)")
que_es <- tabla_resumen$tabla_resumen_o
#-------------
# TEST
openxlsx::read.xlsx()
prueba <- read.xlsx("C:/Users/LcmayorquinL/OneDrive - Departamento Nacional de Planeacion/DIDE/2019/Data Science Projects/Data-Quality-App/data/test.xlsx")
# Write the csv file into a xlsx one so it can be read easily with pandas
write.xlsx(prueba, 'test.xlsx')
py_run_string("base_original = pd.read_excel('C:/Users/LcmayorquinL/OneDrive - Departamento Nacional de Planeacion/DIDE/2019/Data Science Projects/Data-Quality-App/data/test.xlsx')")


tabla_resumen_prueba <- py_run_string("tabla_resumen_p = tabla_resumen(base_original)")
tabla_resumen_r <- py_to_r(tabla_resumen_prueba)
tabla_resumen_r$tabla_resumen_p
class(tabla_resumen_prueba$tabla_resumen_p)

#-------------
# Tabla - Tipo de columna: toca hacer esto con R porque arroja los objetos de Python en una notaciÛn extraÒa
tipo <- py_run_string("tipo = pd.DataFrame(tipo_col(base_original))")
tipo$tipo

# Tabla
missing <- py_run_string("missing_p = pd.DataFrame(missing_porc(base_original))")
missing$missing_p
class(missing$missing_p)

# Veracidad ------------------------
# Valor
filas_no_unic_porc <- py_run_string("filas_no_unic_porc = filas_no_unic_porc(base_original)")
filas_no_unic_porc$filas_no_unic_porc

# Valor - necesita max recursion
col_no_unic_porc <-  py_run_string("col_no_unic_porc = col_no_unic_porc(base_original)")
col_no_unic_porc$col_no_unic_porc

# Valor - Solo se puede correr una vez por alg√∫n motivo
filas_no_unic_num <- py_run_string("filas_no_unic_num = filas_no_unic_num(base_original)")
filas_no_unic_num$filas_no_unic_num

# Valor
col_no_unic_num <- py_run_string("col_no_unic_num = col_no_unic_num(base_original)")
col_no_unic_num$col_no_unic_num


#--------------------------------------

# Tabla
duplicados_col <- py_run_string("duplicados_col = duplicados_col(base_original)")
duplicados_col$duplicados_col

# Tabla
duplicados_fila <- py_run_string("duplicados_fila = duplicados_fila(base_original)")
duplicados_fila$duplicados_fila

# Array
val_unicos_col <- py_run_string("val_unicos_col = val_unicos_col(base_original)")
val_unicos_col$val_unicos_col

# Tabla
valor_unico_texto <-  py_run_string("valor_unico_texto = valor_unico_texto(base_original)")
valor_unico_texto$valor_unico_texto

# Tabla
descripcion <- py_run_string("descripcion_p = descripcion(base_original)")
descripcion$descripcion_p

# Tabla
outliers_porc <-  py_run_string("outliers_porc_p = outliers_porc(base_original)")
outliers_porc$outliers_porc_p

##################### BASE DE PROCOLOMBIA
#os.chdir('D:\OneDrive - Departamento Nacional de Planeacion\Datos abiertos\Otros insumos')
#base_original=pd.read_excel("Reporte DFI 2019 Julio v4 DNP.xlsx")
