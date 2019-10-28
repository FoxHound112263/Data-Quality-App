library(shiny)
library(data.table)
library(openxlsx)
library(reticulate)
library(RSocrata)
library(shinydashboard)
library(shinyjs)


# Fucking user interface

Ui <- fluidPage(
  useShinyjs(),
  # App title ----
  titlePanel("Calidad de datos"),
  p("Esta aplicación calcula métricas de calidad para el Portal de Datos Abiertos de Colombia: https://www.datos.gov.co/"),
  p("Los datos son descargados..."),
  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    
    # Sidebar panel for inputs ----
    sidebarPanel(
      
      textInput("text", label = h3("Ingrese el api_id"), value = ""),
      actionButton(inputId = "button0",label = "Cargar base escogida"),
      
      
      # Input: Select a file ----
      fileInput("file1",
                label="Subir datos",
                multiple = TRUE,accept = c('text/csv',
                                           'text/comma-separated-values,text/plain',
                                           '.csv',
                                           '.xlsx')),
      # Horizontal line ----
      tags$hr(),
      
      # Input: Checkbox if file has header ----
      #checkboxInput("header", "Encabezado", TRUE),
      
      # Línea horizontal ----
      tags$hr(),
      
      # # Input: Select number of rows to display ----
      # radioButtons("disp", "Mostrar",
      #              choices = c(Primeras = "head",
      #                          Todas = "all"),
      #              selected = "head"),
      
      # Botón para calcular métricas de calidad
      actionButton(inputId = "button",label = "Calcular métricas de calidad"),
      
      #actionButton(inputId = "button2",label = "Generar reporte")
      
      
    # Termina sidebar panel
    ),
    
    # Main panel for displaying outputs ----
    mainPanel(
      
      #u_data,
      # Output: Data file ----
      dataTableOutput("contents"),
      #verbatimTextOutput("marki")
      # Test primera métrica
      #tableOutput("resumen")
      
    )
    
  # Termina sidebar layout
  ),
  
  # Tabs
  tabsetPanel(type = "tabs",
              #tabPanel("Resumen", verbatimTextOutput("resumen")),
              tabPanel("Resumen", tableOutput("resumen")),
              tabPanel("Descripción", verbatimTextOutput("desc")),
              tabPanel("Completitud", verbatimTextOutput("missing")),
              tabPanel("Veracidad", verbatimTextOutput("vera")),
              tabPanel("Matching", verbatimTextOutput("matching")),
              tabPanel("Consistencia", verbatimTextOutput("consis")),
              tabPanel("Valores únicos", verbatimTextOutput("val_unic")),
              tabPanel("Metadatos", verbatimTextOutput("meta"))
              
  )
  
  
  # Termina fuild page
  )


# Lógica del fucking servidor

Server <- function(input, output) {
  options(shiny.maxRequestSize=30*1024^2)
  py_run_string("import numpy as np")
  py_run_string("import pandas as pd")
  py_run_string("import sys")
  py_run_string("import codecs")
  py_run_string("sys.setrecursionlimit(10000)")
  # DNP
  #py_run_file("C:/Users/LcmayorquinL/OneDrive - Departamento Nacional de Planeacion/DIDE/2019/Data Science Projects/Data-Quality-App/code/funciones.py")
  # casa
  py_run_file("C:\\Users\\User\\OneDrive - Departamento Nacional de Planeacion\\DIDE\\2019\\Data Science Projects\\Data-Quality-App\\code\\funciones.py")
    
  v <- reactiveValues(data = NULL)

  output$contents <- renderDataTable({
    
    # input$file1 will be NULL initially. After the user selects
    # and uploads a file, head of that data file by default,
    # or all rows if selected, will be shown.
    # if(is.null(input$text)) u_data <- fread("C:/Users/LcmayorquinL/OneDrive - Departamento Nacional de Planeacion/DIDE/2019/Data Science Projects/Data-Quality-App/data/datos_conj.txt",encoding = "UTF-8",header = T)
    #   else u_data <- read.socrata(paste0("https://www.datos.gov.co/resource/",str(input$text),".json"),app_token = "WnkJhtSI1mjrtpymw0gVNZEcl")
    # 
    #   u_data
    # 
    

    # DNP
    #u_data <- fread("C:/Users/LcmayorquinL/OneDrive - Departamento Nacional de Planeacion/DIDE/2019/Data Science Projects/Data-Quality-App/data/datos_conj.txt",encoding = "UTF-8",header = T)
    # CASA
    #u_data <-  fread("https://dl.dropboxusercontent.com/s/kc4ucgg9unptd0p/df_conj_pegados.txt?dl=1",encoding = 'UTF-8',header = T)
    u_data <- py_run_string("base_original = pd.read_csv('https://dl.dropboxusercontent.com/s/kc4ucgg9unptd0p/df_conj_pegados.txt?dl=1')")
    u_data2 <- py_to_r(u_data)
    u_data3 <-  u_data2$base_original
    u_data4 <- py_to_r(u_data3)
    
    if(is.null(input$text)){
      return (u_data4)
      }
    
    # req(input$file1)
    # 
    # # Para archivo sepearado por comas
    # #df <- read.csv(input$file1$datapath,header = TRUE, stringsAsFactors = FALSE,encoding = 'UTF-8')
    # # Para archivo de Excel
    # df <- read.xlsx(input$file1$datapath,sheet = 1,colNames = T)
    # write.xlsx(df, 'test.xlsx')
    # 
    # 
    # if(input$disp == "head") {
    #   return(head(df))
    # }
    # else {
    #   return(df)
    # }
    
    
    
    
    
    
  })
  
  observeEvent(input$button, {
    
    # test data -DNP
    #py_run_string("base_original = pd.read_excel('C:/Users/LcmayorquinL/OneDrive - Departamento Nacional de Planeacion/DIDE/2019/Data Science Projects/Data-Quality-App/data/test.xlsx')")
    # test data -DNP
    py_run_string("base_original = pd.read_excel(r'C:\\Users\\User\\OneDrive - Departamento Nacional de Planeacion\\DIDE\\2019\\Data Science Projects\\Data-Quality-App\\data\\test.xlsx')")
    
    # Final
    #py_run_string("base_original = pd.read_csv('https://dl.dropboxusercontent.com/s/kc4ucgg9unptd0p/df_conj_pegados.txt?dl=1')")
    
    # Resumen
    tabla_resumen <- py_run_string("tabla_resumen_o = tabla_resumen(base_original)")
    tabla_resumen_2 <- py_to_r(tabla_resumen)
    #v$data <- tabla_resumen_2$tabla_resumen_o
    objeto_prueba_1 <- tabla_resumen_2$tabla_resumen_o
    v$resumen <- py_to_r(objeto_prueba_1) 
    
    # CREO QUE ESTO NO ES NECESARIO
    
    #DNP
    #save(objeto_1,file = "C:/Users/LcmayorquinL/OneDrive - Departamento Nacional de Planeacion/DIDE/2019/Data Science Projects/Data-Quality-App/saved objects/objetos.RData")
    # CASA
    #save(objeto_1,file = "C:\\Users\\User\\OneDrive - Departamento Nacional de Planeacion\\DIDE\\2019\\Data Science Projects\\Data-Quality-App\\saved objects\\objetos.RData")
    
    
    # Descripción
    descripcion <- py_run_string("descripcion_p = descripcion(base_original)")
    descripcion_2 <- py_to_r(descripcion)
    v$desc <- descripcion_2$descripcion_p
    
    # Completitud
    missing <- py_run_string("missing_p = pd.DataFrame(missing_porc(base_original))")
    missing_2 <- py_to_r(missing)
    v$missing <- missing_2$missing_p
    
    # Veracidad
    #-----------------------------------------------
    # parte 1
    filas_no_unic_porc <- py_run_string("filas_no_unic_porc_p = filas_no_unic_porc(base_original)")
    filas_no_unic_porc_2 <- py_to_r(filas_no_unic_porc)
    
    # parte 2
    col_no_unic_porc <-  py_run_string("col_no_unic_porc_p = col_no_unic_porc(base_original)")
    col_no_unic_porc_2 <-  py_to_r(col_no_unic_porc)
    
    # parte 3
    filas_no_unic_num <- py_run_string("filas_no_unic_num_p = filas_no_unic_num(base_original)")
    filas_no_unic_num_2 <- py_to_r(filas_no_unic_num)
    
    # parte 4
    col_no_unic_num <- py_run_string("col_no_unic_num_p = col_no_unic_num(base_original)")
    col_no_unic_num_2 <- py_to_r(col_no_unic_num)
    
    # unión
    union <- c(filas_no_unic_porc_2$filas_no_unic_porc_p, col_no_unic_porc_2$col_no_unic_porc_p,
              filas_no_unic_num_2$filas_no_unic_num_p, col_no_unic_num_2$col_no_unic_num_p)
    names(union) <- c('Porcentaje de filas no únicas:',
                     'Porcentaje de columnas no únicas:',
                     'Número de filas no únicas:',
                     'Número de columnas no únicas:')
    v$vera <- union
    #------------------------------------------------
    
    
    # Matching de filas y columnas no únicas
    #-----------------------------------------------
    # Columnas
    duplicados_col <- py_run_string("duplicados_col_p = duplicados_col(base_original)")
    duplicados_col_2 <- py_to_r(duplicados_col)
    
    
    # Filas
    duplicados_fila <- py_run_string("duplicados_fila_p = duplicados_fila(base_original)")
    duplicados_fila_2 <- py_to_r(duplicados_fila)
    
    # union_2
    union_2 <- c(duplicados_col_2$duplicados_col_p, duplicados_fila_2$duplicados_fila_p)
    names(union_2) <- c('Matching de columnas duplicadas:',
                        'Matching de filas duplicadas:')
    
    v$matching <- union_2
    #------------------------------------------------
    
    
    # Consistencia
    #------------------------------------------------
    # Porcentaje de outliers
    outliers_porc <-  py_run_string("outliers_porc_p = outliers_porc(base_original)")
    outliers_porc_2 <- py_to_r(outliers_porc)
    v$consis <- outliers_porc_2$outliers_porc_p
    #------------------------------------------------
    
    # Valores únicos
    valor_unico_texto <-  py_run_string("valor_unico_texto_p = valor_unico_texto(base_original)")
    valor_unico_texto_2 <- py_to_r(valor_unico_texto)
    v$val_unic <-  valor_unico_texto_2$valor_unico_texto_p
    
    
  })

  # Resumen
  output$resumen <- renderTable({
    if(is.null(v$resumen)){return ()}
    as.data.frame.table(v$resumen) 

    
  })
  
  # Descripción
  output$desc <- renderPrint({
    v$desc
  })
  
  # Completitud 
  output$missing <- renderPrint({
    v$missing
  })
  
  # Veracidad
  output$vera <- renderPrint({
    v$vera
  })
  
  # Matching
  output$matching <- renderPrint({
    v$matching
  })

  # Consistencia
  output$consis <- renderPrint({
    v$consis
  })
  
  # Valores únicos
  output$val_unic <- renderPrint({
    v$val_unic
  })
  
  # RepORTE - PABLO LO HARÁ EN PYTHON
  # # Al presionar el botón de generar reporte, do this
  # observeEvent(input$button2, {
  #   # Markdown section
  #   output$marki <- renderText({
  #     rmarkdown::render("C:/Users/LcmayorquinL/OneDrive - Departamento Nacional de Planeacion/DIDE/2019/Data Science Projects/Data-Quality-App/markdown/reporte.Rmd", encoding = "UTF-8",clean = T)
  #     fil <- "C:/Users/LcmayorquinL/OneDrive - Departamento Nacional de Planeacion/DIDE/2019/Data Science Projects/Data-Quality-App/markdown/reporte.html"
  #     if (file.exists(fil)) mensaje <- "Reporte terminado"
  #     mensaje
  #     
  #   })
  #   
  # })
  

  
  
# END  
}

shinyApp(ui = Ui, server = Server)
