library(shiny)
library(data.table)
library(openxlsx)
library(reticulate)
library(RSocrata)
library(shinydashboard)


# Fucking user interface

ui <- fluidPage(
  # App title ----
  titlePanel("Calidad de datos"),
  
  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    
    # Sidebar panel for inputs ----
    sidebarPanel(
      
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
      checkboxInput("header", "Encabezado", TRUE),
      
      # Horizontal line ----
      tags$hr(),
      
      # Input: Select number of rows to display ----
      radioButtons("disp", "Mostrar",
                   choices = c(Primeras = "head",
                               Todas = "all"),
                   selected = "head"),
      
      # Botón para calcular métricas de calidad
      actionButton(inputId = "button",label = "Calcular métricas de calidad")
      
    # Termina sidebar panel
    ),
    
    # Main panel for displaying outputs ----
    mainPanel(
      
      # Output: Data file ----
      dataTableOutput("contents")#,
      
      # Test primera métrica
      #tableOutput("resumen")
      
    )
    
  # Termina sidebar layout
  ),
  
  # Tabs
  tabsetPanel(type = "tabs",
              tabPanel("Resumen", verbatimTextOutput("resumen")),
              tabPanel("Completitud", verbatimTextOutput("missing")),
              tabPanel("Veracidad", verbatimTextOutput("vera")),
              tabPanel("Matching", verbatimTextOutput("matching")),
              tabPanel("Consistencia", verbatimTextOutput("consis"))
  )
  
  
  # Termina fuild page
  )


# Lógica del fucking servidor

server <- function(input, output) {
  options(shiny.maxRequestSize=30*1024^2)
  py_run_string("import numpy as np")
  py_run_string("import pandas as pd")
  py_run_string("import sys")
  py_run_string("import codecs")
  py_run_string("sys.setrecursionlimit(10000)")
  py_run_file("C:/Users/LcmayorquinL/OneDrive - Departamento Nacional de Planeacion/DIDE/2019/Data Science Projects/Data-Quality-App/code/funciones.py")
  
  v <- reactiveValues(data = NULL)

  output$contents <- renderDataTable({
    
    # input$file1 will be NULL initially. After the user selects
    # and uploads a file, head of that data file by default,
    # or all rows if selected, will be shown.
    
    req(input$file1)
    
    # Para archivo sepearado por comas
    #df <- read.csv(input$file1$datapath,header = TRUE, stringsAsFactors = FALSE,encoding = 'UTF-8')
    # Para archivo de Excel
    df <- read.xlsx(input$file1$datapath,sheet = 1,colNames = T)
    write.xlsx(df, 'test.xlsx')
    
    
    if(input$disp == "head") {
      return(head(df))
    }
    else {
      return(df)
    }
    
    
    
    #df_py <- r_to_py(df,convert = T)
    
    
  })
  
  observeEvent(input$button, {
    # Resumen
    py_run_string("base_original = pd.read_excel('C:/Users/LcmayorquinL/OneDrive - Departamento Nacional de Planeacion/DIDE/2019/Data Science Projects/Data-Quality-App/data/test.xlsx')")
    tabla_resumen <- py_run_string("tabla_resumen_o = tabla_resumen(base_original)")
    tabla_resumen_2 <- py_to_r(tabla_resumen)
    v$data <- tabla_resumen_2$tabla_resumen_o
    
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
    # Porcentaje de outliers
    outliers_porc <-  py_run_string("outliers_porc_p = outliers_porc(base_original)")
    outliers_porc_2 <- py_to_r(outliers_porc)
    v$consis <- outliers_porc_2$outliers_porc_p
    
    
  })

  # Resumen
  output$resumen <- renderPrint({
    v$data
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
  
# END  
}

shinyApp(ui = ui, server = server)


# shinyServer(function(input, output,session) {
#   
#   dataframe<-reactive({
#     if (is.null(input$datafile))
#       return(NULL)                
#     data<-read.csv(input$datafile$datapath)
#     data<- data %>% group_by(C) %>% mutate(A) %>% 
#       mutate(B) %>% mutate(add = (A+B)) %>% mutate(sub = (A-B))
#     data
#   })
#   output$table <- renderTable({
#     dataframe()
#   })
#   output$plot <- renderPlot({
#     if(!is.null(dataframe()))
#       ggplot(dataframe(),aes(x=X,y=add))+geom_point()
#   })
# })


# Por si acaso
# read.xlsx(inFile$datapath,
#           header = TRUE,sheetIndex = 1,
#           stringsAsFactors = FALSE)



# Servidor original que funciona más o menos
# Get the upload file
# get_item_list <- reactive({
#   inFile <- input$file1
#   
#   if (is.null(inFile)) {
#     return(NULL) }
#   
#   if (input$fileType_Input == 1) {
#     datos <-  read.csv(inFile$datapath,
#                        header = TRUE,
#                        stringsAsFactors = FALSE,encoding = 'UTF-8')
#   } else {
#     datos <- openxlsx::read.xlsx(inFile$datapath,
#                                  colNames=T,sheet=1)  
#     datos
#     
#   }
# })