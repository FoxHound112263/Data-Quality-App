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
    dashboardHeader(title = "Calidad de datos abiertos - Colombia"),
    ## Sidebar content
    dashboardSidebar(
        sidebarMenu(
            menuItem("Info", tabName = "dashboard", icon = icon("dashboard")),
            textInput(inputId = "text",
                      label = "Copie y pegue el api_id"),
            verbatimTextOutput("value"),
            menuItem("Métricas de calidad", tabName = "widgets", icon = icon("th")),
            actionButton(inputId = "button",label = "Calcular métricas de calidad")
            
            
            
        )
    ),
    ## Body content
    dashboardBody(
        tabItems(
            # First tab content
            tabItem(tabName = "dashboard",
                    DTOutput("contents"),style = "height:600px; overflow-y: scroll;overflow-x: scroll;",

 
            ),
            
            # Second tab content
            tabItem(tabName = "widgets",
                    h2("Pilares de calidad"),
                    verbatimTextOutput("text"),
                    
                    fluidRow(
                        box("Resumen", tableOutput("resumen")),
                        box("Descripción", tableOutput("desc")),
                        box("Completitud", verbatimTextOutput("missing")),
                        box("Veracidad", verbatimTextOutput("vera")),
                        box("Matching", verbatimTextOutput("matching")),
                        box("Consistencia", verbatimTextOutput("consis")),
                        box("Valores únicos", tableOutput("val_unic"))
                        #box("Metadatos", tableOutput("meta"))
                        
                    )
                    
            )
        )
    )
)



server <- function(input, output) {

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
        
        
        py_run_string('base_original = pd.read_csv("base_original.csv")  ')
        
        # Final
        #py_run_string("base_original = pd.read_csv('https://dl.dropboxusercontent.com/s/kc4ucgg9unptd0p/df_conj_pegados.txt?dl=1')")
        
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
        objeto_prueba_4 <- outliers_porc_2$outliers_porc_p
        v$consis <- py_to_r(objeto_prueba_4)
        #------------------------------------------------
        
        # Valores únicos
        valor_unico_texto <-  py_run_string("valor_unico_texto_p = valor_unico_texto(base_original)")
        valor_unico_texto_2 <- py_to_r(valor_unico_texto)
        objeto_prueba_5 <- valor_unico_texto_2$valor_unico_texto_p
        v$val_unic <-  py_to_r(objeto_prueba_5)
        
        # Meta datos
        # metadatos <- py_run_string('metadatos_p = traer_tabla_scrapeada()')
        # metadatos_2 <- py_to_r(metadatos)
        # objeto_prueba_6 <- metadatos_2$metadatos_p
        # v$meta <- py_to_r(objeto_prueba_6)
        
    })
    
    options(shiny.maxRequestSize=30*1024^2)
    py_run_string("import numpy as np")
    py_run_string("import pandas as pd")
    py_run_string("import pickle")
    py_run_string("import sys")
    py_run_string("import codecs")
    py_run_string("sys.setrecursionlimit(10000)")
    # DNP
    #py_run_file("C:/Users/LcmayorquinL/OneDrive - Departamento Nacional de Planeacion/DIDE/2019/Data Science Projects/Data-Quality-App/code/funciones.py")
    # casa
    py_run_file("C:\\Users\\User\\OneDrive - Departamento Nacional de Planeacion\\DIDE\\2019\\Data Science Projects\\Data-Quality-App\\code\\funciones.py")
    
    
    v <- reactiveValues(data = NULL)
    
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
    
    
    
    

    #text <- reactive({text=input$text})
    
    #py_run_string("token =")
    py_run_file("C:\\Users\\User\\OneDrive - Departamento Nacional de Planeacion\\DIDE\\2019\\Data Science Projects\\Data-Quality-App\\code\\sodapy.py")
    
    output$contents <- renderDataTable({
        
        # DNP
        #u_data <- fread("C:/Users/LcmayorquinL/OneDrive - Departamento Nacional de Planeacion/DIDE/2019/Data Science Projects/Data-Quality-App/data/datos_conj.txt",encoding = "UTF-8",header = T)
        # CASA
        #u_data <-  fread("https://dl.dropboxusercontent.com/s/kc4ucgg9unptd0p/df_conj_pegados.txt?dl=1",encoding = 'UTF-8',header = T)
        
        

        if(input$text==''){
            u_data <- py_run_string("base_original_2 = pd.read_csv('https://dl.dropboxusercontent.com/s/kc4ucgg9unptd0p/df_conj_pegados.txt?dl=1')")
            u_data2 <- py_to_r(u_data)
            u_data3 <-  u_data2$base_original_2
            u_data4 <- py_to_r(u_data3)
            u_data4 <- u_data4 %>% select(api_id, everything())
            u_data4[-c(2,3)]
           
            
        }
        else {
            
            #f8x9-azny
            #v$text
            df <- read.socrata(paste0("https://www.datos.gov.co/resource/",v$text,".json"),app_token = "WnkJhtSI1mjrtpymw0gVNZEcl",stringsAsFactors = F)
            df
            
        }

    
},filter = "top")
    


    # Resumen
    output$resumen <- renderTable({
        if(is.null(v$resumen)){return ()}
        as.data.frame.table(v$resumen) 
        
        
    })
    
    # Descripción
    output$desc <- renderTable({
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
    output$val_unic <- renderTable({
        v$val_unic
    })
    
    # Meta datos
    # output$meta <- renderTable({
    #     v$meta
    # })
}
shinyApp(ui, server)