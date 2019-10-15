# Shiny dashboard attempt
options(encoding="UTF-8")
library(shinydashboard)
library(data.table)
library(RSocrata)

# Dejar que el usuario escoja el id de la api
api_id <- "dbbm-6p3q"

df <- read.socrata(
    paste0("https://www.datos.gov.co/resource/",api_id,".json"),
    app_token = "WnkJhtSI1mjrtpymw0gVNZEcl"
)


data <- fread("C:/Users/LcmayorquinL/OneDrive - Departamento Nacional de Planeacion/DIDE/2019/Data Science Projects/Data-Quality-App/data/datos_conj.txt",encoding = "UTF-8",header = T) 



ui <- dashboardPage(
    dashboardHeader(title = "Calidad de datos abiertos - Colombia"),
    ## Sidebar content
    dashboardSidebar(
        sidebarMenu(
            menuItem("Info", tabName = "dashboard", icon = icon("dashboard")),
            menuItem("Métricas", tabName = "widgets", icon = icon("th"))
        )
    ),
    ## Body content
    dashboardBody(
        tabItems(
            # First tab content
            tabItem(tabName = "dashboard",
                    fluidRow(
                        box(plotOutput("plot1", height = 250)),
                        
                        box(
                            title = "Controls",
                            sliderInput("slider", "Number of observations:", 1, 100, 50)
                        )
                    )
            ),
            
            # Second tab content
            tabItem(tabName = "widgets",
                    h2("contenido")
            )
        )
    )
)

server <- function(input, output) {
    set.seed(122)
    histdata <- rnorm(500)
    
    output$plot1 <- renderPlot({
        data <- histdata[seq_len(input$slider)]
        hist(data)
    })
}

shinyApp(ui, server)