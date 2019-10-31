# Shiny dashboard attempt
options(encoding="UTF-8")
library(shiny)
library(data.table)
library(openxlsx)
library(reticulate)
library(RSocrata)
library(shinydashboard)
library(shinyjs)
library(DT)
library(dplyr)
library(shinybusy)
library(shinycssloaders)
library(shinythemes)


moveme <- function (invec, movecommand) {
    movecommand <- lapply(strsplit(strsplit(movecommand, ";")[[1]], 
                                   ",|\\s+"), function(x) x[x != ""])
    movelist <- lapply(movecommand, function(x) {
        Where <- x[which(x %in% c("before", "after", "first", 
                                  "last")):length(x)]
        ToMove <- setdiff(x, Where)
        list(ToMove, Where)
    })
    myVec <- invec
    for (i in seq_along(movelist)) {
        temp <- setdiff(myVec, movelist[[i]][[1]])
        A <- movelist[[i]][[2]][1]
        if (A %in% c("before", "after")) {
            ba <- movelist[[i]][[2]][2]
            if (A == "before") {
                after <- match(ba, temp) - 1
            }
            else if (A == "after") {
                after <- match(ba, temp)
            }
        }
        else if (A == "first") {
            after <- 0
        }
        else if (A == "last") {
            after <- length(myVec)
        }
        myVec <- append(temp, values = movelist[[i]][[1]], after = after)
    }
    myVec
}


ui <- dashboardPage(
    dashboardHeader(title = "Calidad de datos abiertos - Colombia"),skin = 'black',
    ## Sidebar content
    dashboardSidebar(
        sidebarMenu(
            menuItem("Portal de Datos Abiertos", tabName = "base_grande", icon = icon("dashboard")),
            
            
            textInput(inputId = "text",
                      label = "Copie y pegue el api_id"),
            
            
            tags$hr(),
            verbatimTextOutput("value"),
            #actionButton(inputId = "button1",label = "Cargar base"),
            menuItem("Cargar base de datos escogida", tabName = "truco", icon = icon("th")),
            menuItem('Base escogida', tabName = 'escogida', icon = icon('cog')),
            menuItem("Métricas de calidad", tabName = "pilares", icon = icon("th")),
            actionButton(inputId = "button",label = "Calcular métricas de calidad")
            
            
            
        )
    ),
    ## Body content
    dashboardBody(
        tabItems(
            # Base scrapeada
            tabItem(tabName = "base_grande",
                    h2("Bases de datos del Portal de Datos Abiertos de Colombia"),
                    p('Esta tabla fue construída a través de un procedimiento de Web Scraping.'),
                    DTOutput("contents") %>% withSpinner(color="#0dc5c1") ,style = "height:600px; overflow-y: scroll;overflow-x: scroll;",
                    
                    
            ),
            
            # Truco para cargar base
            tabItem(tabName = "truco",
                    #DTOutput("contents2"),style = "height:600px; overflow-y: scroll;overflow-x: scroll;",
                    h2('Base de datos escogida:'),
                    verbatimTextOutput('text'),
                    
            ),
            
            # Truco para cargar base
            tabItem(tabName = "escogida",
                    DTOutput("contents2")%>% withSpinner(color="#0dc5c1") ,style = "height:600px; overflow-y: scroll;overflow-x: scroll;",
                    
            ),
            
            # Pilares de calidad
            tabItem(tabName = "pilares",
                    h2("Pilares de calidad"),
                    p('Esta sección contiene métricas de calidad objetivas para evaluar la calidad de la base de datos escogida.'),
                    #verbatimTextOutput("text"),
                    
                    fluidRow(
                        #box("Resumen", tableOutput("resumen"))
                        # box("Descripción", tableOutput("desc")),
                        # box("Completitud", verbatimTextOutput("missing")),
                        # box("Veracidad", verbatimTextOutput("vera")),
                        # box("Matching", verbatimTextOutput("matching")),
                        # box("Consistencia", verbatimTextOutput("consis")),
                        # box("Valores únicos", tableOutput("val_unic"))
                        #box("Metadatos", tableOutput("meta"))
                        
                        tabsetPanel(type = "tabs",
                                    #tabPanel("Resumen", verbatimTextOutput("resumen")),
                                    
                                    tabPanel("Resumen", dataTableOutput("resumen") %>% withSpinner(color="#0dc5c1"),
                                             p('Información básica de la base de datos seleccionada'),
                                    ),
                                    
                                    tabPanel("Descripción", dataTableOutput("desc") %>% withSpinner(color="#0dc5c1") ,
                                             p('Estadísticas descriptivas por cada columna numérica'),
                                    ),
                                    
                                    
                                    tabPanel("Completitud", dataTableOutput("missing") %>% withSpinner(color="#0dc5c1"),
                                             p('Porcentaje de valores faltantes por cada columna'),
                                    ),
                                    
                                    
                                    # Varias funciones
                                    tabPanel("Veracidad", #, verbatimTextOutput("vera"),
                                             box('Porcentaje de filas no únicas',verbatimTextOutput("vera1")),
                                             box('Porcentaje de columnas no únicas',verbatimTextOutput("vera2")),
                                             box('Número de filas no únicas',verbatimTextOutput("vera3")),
                                             box('Número de columnas',verbatimTextOutput("vera4")),
                                             ),
                                    
                                    
                                    
                                    tabPanel("Matching", #, verbatimTextOutput("matching")),
                                             box('Matching de columnas duplicadas', verbatimTextOutput('match1')),
                                             box('Matching de filas duplicadas', verbatimTextOutput('match2'))
                                    ),
                                    
                                    
                                    tabPanel("Consistencia", verbatimTextOutput("consis")),
                                    
                                    
                                    tabPanel("Valores únicos", dataTableOutput("val_unic") %>% withSpinner(color="#0dc5c1"),
                                             p('Tabla de valores únicos en cada columna'),
                                             
                                    ),
                                    
                                    tabPanel("Metadatos", dataTableOutput("meta"))
                                    
                        )
                        
                    )
                    
                    
            )
        )
    )
)



server <- function(input, output) {
    
    options(shiny.maxRequestSize=30*1024^2)
    py_run_string("import numpy as np")
    py_run_string("import pandas as pd")
    py_run_string("import pickle")
    py_run_string("import sys")
    py_run_string("import codecs")
    py_run_string("sys.setrecursionlimit(100000000)")
    # DNP
    #py_run_file("C:/Users/LcmayorquinL/OneDrive - Departamento Nacional de Planeacion/DIDE/2019/Data Science Projects/Data-Quality-App/code/funciones.py")
    # casa
    py_run_file("C:\\Users\\User\\OneDrive - Departamento Nacional de Planeacion\\DIDE\\2019\\Data Science Projects\\Data-Quality-App\\code\\funciones.py")
    
    
    # Variable reactiva para guardar todos los objetos
    v <- reactiveValues(data = NULL)
    
    observeEvent(input$button, {
        
        # test data -DNP
        #py_run_string("base_original = pd.read_excel('C:/Users/LcmayorquinL/OneDrive - Departamento Nacional de Planeacion/DIDE/2019/Data Science Projects/Data-Quality-App/data/test.xlsx')")
        # test data -DNP
        
        
        #TEST
        #py_run_string("base_original = pd.read_excel(r'C:\\Users\\User\\OneDrive - Departamento Nacional de Planeacion\\DIDE\\2019\\Data Science Projects\\Data-Quality-App\\data\\test.xlsx')")
        
        py_save_object(v$text, 'base_original', pickle = "pickle")
        
        
        choice <- py_load_object('base_original', pickle = 'pickle')
        
        base_original <- read.socrata(paste0("https://www.datos.gov.co/resource/",choice,".json"),app_token = "WnkJhtSI1mjrtpymw0gVNZEcl",stringsAsFactors = F)
        write.csv(x = base_original,file = 'base_original.csv')
        
        
        py_run_string('base_original = pd.read_csv("base_original.csv")')
        
        # Final
        #py_run_string("base_original = pd.read_csv('"https://dl.dropboxusercontent.com/s/kc4ucgg9unptd0p/df_conj_pegados.txt?dl=0')"")
        
        # Resumen
        tabla_resumen <- py_run_string("tabla_resumen_o = tabla_resumen(base_original)")
        tabla_resumen_2 <- py_to_r(tabla_resumen)
        #v$data <- tabla_resumen_2$tabla_resumen_o
        objeto_prueba_1 <- tabla_resumen_2$tabla_resumen_o
        v$resumen <- py_to_r(objeto_prueba_1)
        
        # Descripción
        descripcion <- py_run_string("descripcion_p = descripcion(base_original)")
        descripcion_2 <- py_to_r(descripcion)
        objeto_prueba_2 <- descripcion_2$descripcion_p
        v$desc <- py_to_r(objeto_prueba_2)
        
        # Completitud
        missing <- py_run_string("missing_p = pd.DataFrame(missing_porc(base_original))")
        missing_2 <- py_to_r(missing)
        objeto_prueba_3 <- missing_2$missing_p
        v$missing <- py_to_r(objeto_prueba_3)
        
        # Veracidad
        #-----------------------------------------------
        # Función 1
        filas_no_unic_porc <- py_run_string("filas_no_unic_porc_p = filas_no_unic_porc(base_original)")
        filas_no_unic_porc_2 <- py_to_r(filas_no_unic_porc)
        objeto_vera_1 <- filas_no_unic_porc_2$filas_no_unic_por_p
        v$vera1 <- objeto_vera_1 
        
        # Función 2
        col_no_unic_porc <- py_run_string("col_no_unic_porc_p = col_no_unic_porc(base_original)")
        col_no_unic_porc_2 <- py_to_r
        objeto_vera_2 <- filas_no_unic_porc_2$col_no_unic_por_p
        v$vera2 <- objeto_vera_2
        
        # Función 3
        filas_no_unic_num <- py_run_string("filas_no_unic_num_p = filas_no_unic_num(base_original)")
        filas_no_unic_num_2 <- py_to_r(filas_no_unic_num)
        objeto_vera_3 <- filas_no_unic_porc_2$filas_no_unic_num_p
        v$vera3 <- objeto_vera_3
        
        # Función 4
        col_no_unic_num <- py_run_string("col_no_unic_num_p = col_no_unic_num(base_original)")
        col_no_unic_num_2 <- py_to_r(col_no_unic_num)
        objeto_vera_4 <- filas_no_unic_porc_2$col_no_unic_num_p
        v$vera4 <- objeto_vera_4
        
        
        # # unión
        # union <- c(filas_no_unic_porc_2$filas_no_unic_porc_p, col_no_unic_porc_2$col_no_unic_porc_p,
        #            filas_no_unic_num_2$filas_no_unic_num_p, col_no_unic_num_2$col_no_unic_num_p)
        # names(union) <- c('Porcentaje de filas no únicas:',
        #                   'Porcentaje de columnas no únicas:',
        #                   'Número de filas no únicas:',
        #                   'Número de columnas no únicas:')
        #v$vera <- union
        #------------------------------------------------
        
        
        # Matching de filas y columnas no únicas
        #-----------------------------------------------
        # Función columnas
        duplicados_col <- py_run_string("duplicados_col_p = duplicados_col(base_original)")
        duplicados_col_2 <- py_to_r(duplicados_col)
        objeto_match_1 <- duplicados_col_2$duplicados_col_p
        v$match1 <- objeto_match_1
        
        # Función filas
        duplicados_fila <- py_run_string("duplicados_fila_p = duplicados_fila(base_original)")
        duplicados_fila_2 <- py_to_r(duplicados_fila)
        objeto_match_2 <- duplicados_fila_2$duplicados_fila_p
        v$match2 <- objeto_match_2
        
        # # union_2
        # union_2 <- c(duplicados_col_2$duplicados_col_p, duplicados_fila_2$duplicados_fila_p)
        # names(union_2) <- c('Matching de columnas duplicadas:',
        #                     'Matching de filas duplicadas:')
        # 
        # v$matching <- union_2
        #------------------------------------------------
        
        
        # Consistencia
        #------------------------------------------------
        # Porcentaje de outliers
        outliers_porc <- py_run_string("outliers_porc_p = outliers_porc(base_original)")
        outliers_porc_2 <- py_to_r(outliers_porc)
        objeto_prueba_4 <- outliers_porc_2$outliers_porc_p
        v$consis <- py_to_r(objeto_prueba_4)
        #------------------------------------------------
        
        # Valores únicos
        valor_unico_texto <- py_run_string("valor_unico_texto_p = valor_unico_texto(base_original)")
        valor_unico_texto_2 <- py_to_r(valor_unico_texto)
        objeto_prueba_5 <- valor_unico_texto_2$valor_unico_texto_p
        v$val_unic <-  py_to_r(objeto_prueba_5)
        
        #Meta datos
        # metadatos <- py_run_string('metadatos_p = info_cols_meta(\'f8x9-azny\')')
        # metadatos_2 <- py_to_r(metadatos)
        # objeto_prueba_6 <- metadatos_2$metadatos_p
        # v$meta <- py_to_r(objeto_prueba_6)
        
    })
    
    
    
    
    
    texto <- reactive({
        if (input$text=='') {
            return()
            
        }
        else{
            api_id = input$text
            api_id
        }
        
        
    })
    
    output$text <- renderText({
        
        
        v$text <- input$text
        
        v$text
        
    })
    
    
    # Cuando el usuario orpime el botón de generar tabla
    # observeEvent(input$button1, {
    #     
    #     
    #     df <- read.socrata(paste0("https://www.datos.gov.co/resource/",v$text,".json"),app_token = "WnkJhtSI1mjrtpymw0gVNZEcl",stringsAsFactors = F)
    #     v$df
    #     
    # })
    
    
    
    #text <- reactive({text=input$text})
    
    #py_run_string("token =''")
    py_run_file("C:\\Users\\User\\OneDrive - Departamento Nacional de Planeacion\\DIDE\\2019\\Data Science Projects\\Data-Quality-App\\code\\sodapy.py")
    
    output$contents <- renderDataTable({
        
        # DNP
        #u_data <- fread("C:/Users/LcmayorquinL/OneDrive - Departamento Nacional de Planeacion/DIDE/2019/Data Science Projects/Data-Quality-App/data/datos_conj.txt",encoding = "UTF-8",header = T)
        # CASA
        #u_data <- fread("https://dl.dropboxusercontent.com/s/kc4ucgg9unptd0p/df_conj_pegados.txt?dl=1",encoding = 'UTF-8',header = T)
        
        
        u_data <- py_run_string("base_original_2 = pd.read_csv('https://dl.dropboxusercontent.com/s/kc4ucgg9unptd0p/df_conj_pegados.txt?dl=0')")
        u_data2 <- py_to_r(u_data)
        u_data3 <- u_data2$base_original_2
        u_data4 <- py_to_r(u_data3)
        u_data4 <- u_data4 %>% select(api_id, everything())
        u_data4[-c(2,3)] 
        
        
        
        
        #f8x9-azny
        #v$text
        
        # 
        # df <- read.socrata(paste0("https://www.datos.gov.co/resource/",v$text,".json"),app_token = "WnkJhtSI1mjrtpymw0gVNZEcl",stringsAsFactors = F)
        # df
        
        
    },filter = "top")
    
    
    output$contents2 <- renderDataTable({
        
        if (input$text=='') {
            return()
            
        }
        else{
            
            df <- read.socrata(paste0("https://www.datos.gov.co/resource/",v$text,".json"),app_token = "WnkJhtSI1mjrtpymw0gVNZEcl",stringsAsFactors = F)
            df
        }
        
        
        #as.data.frame(v$df)
        
        # if (input$text==''){
        #  return()
        # }
        # 
        # else if(input$button_1){
        #  
        # }
        # 
        # else{
        #  return()
        #  #df <- read.socrata(paste0("https://www.datos.gov.co/resource/",v$text,".json"),app_token = "WnkJhtSI1mjrtpymw0gVNZEcl",stringsAsFactors = F)
        #  #df
        # }
        
        
    })
    
    
    
    # Resumen
    output$resumen <- renderDataTable({
        if(is.null(v$resumen)){return ()}
        as.data.frame.table(v$resumen) 
        
        
    })
    
    # Descripción
    output$desc <- renderDataTable({
        as.data.frame(v$desc)
    })
    
    # Completitud 
    output$missing <- renderDataTable({
        if(is.null(v$missing)){return ()}
        v$missing
    })
    
    #-------------------------------------------
    # Veracidad
    output$vera1 <- renderPrint({
        v$vera1
    })
    
    output$vera2 <- renderPrint({
        v$vera2
    })
    
    output$vera3 <- renderPrint({
        v$vera3
    })
    
    output$vera4 <- renderPrint({
        v$vera4
    })
    #-------------------------------------------
    
    #-------------------------------------------
    # Matching
    output$match1 <- renderPrint({
        v$match1
    })
    
    output$match2 <- renderPrint({
        v$match2
    })
    #------------------------------------------
    
    
    # Consistencia
    output$consis <- renderText({
        v$consis
    })
    
    # Valores únicos
    output$val_unic <- renderDataTable({
        v$val_unic
    })
    
    #Meta datos
    # output$meta <- renderDataTable({
    # v$meta
    # })
}
shinyApp(ui, server)
