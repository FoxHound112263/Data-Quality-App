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
              tabPanel("Completitud", tableOutput("missing")),
              tabPanel("Veracidad", tableOutput("table"))
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
  py_run_file("C:/Users/cmayorquin/Desktop/CALIDAD/funciones.py")
  
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
    py_run_string("base_original = pd.read_excel('C:/Users/cmayorquin/Desktop/CALIDAD/appCalidad/test.xlsx')")
    tabla_resumen <- py_run_string("tabla_resumen_o = tabla_resumen(base_original)")
    tabla_resumen_2 <- py_to_r(tabla_resumen)
    v$data <- tabla_resumen_2$tabla_resumen_o
    
    # Completitud
    missing <- py_run_string("missing_p = pd.DataFrame(missing_porc(base_original))")
    missing_2 <- py_to_r(missing)
    v$missing <- missing_2$missing_p
    
    
    
    
  })


  output$resumen <- renderPrint({
    v$data
  })
  
  output$missing <- renderTable({
    v$missing
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