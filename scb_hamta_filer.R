

source("G:/skript/func/func_filer.R", encoding = "utf-8", echo = FALSE)

# hämta deso
ladda_ned_fil(output_mapp = "G:/Samhällsanalys/GIS/grundkartor/deso/",
              gis_url <- "https://www.scb.se/contentassets/923c3627a8a042a5b9215e8ff3bde0a3/deso_2018_2021-10-21.zip")

ladda_ned_fil(output_mapp = "G:/Samhällsanalys/GIS/grundkartor/deso/",
              gis_url <- "https://www.scb.se/contentassets/e3b2f06da62046ba93ff58af1b845c7e/kopplingstabell-deso_regso_20211004.xlsx")

# hämta regso
ladda_ned_fil(output_mapp = "G:/Samhällsanalys/GIS/grundkartor/regso/",
              gis_url <- "https://www.scb.se/contentassets/e3b2f06da62046ba93ff58af1b845c7e/regso_2018_v1_20211103.zip")

ladda_ned_fil(output_mapp = "G:/Samhällsanalys/GIS/grundkartor/regso/",
              gis_url <- "https://www.scb.se/contentassets/e3b2f06da62046ba93ff58af1b845c7e/kopplingstabell-deso_regso_20211004.xlsx")

# hämta tätorter
ladda_ned_fil(output_mapp = "G:/Samhällsanalys/GIS/grundkartor/tatorter/",
              gis_url <- "https://www.scb.se/contentassets/3ee03ca6db1e48ff808b3c8d2c87d470/tatorter_1980_2020_2011-11-24.zip")

# hämta småorter
ladda_ned_fil(output_mapp = "G:/Samhällsanalys/GIS/grundkartor/smaorter/",
              gis_url <- "https://www.scb.se/contentassets/9a5e6d1c1b61467b80d7d5bb7803e28d/so2015_sr99tm.zip")

# hämta fritidshusområden
ladda_ned_fil(output_mapp = "G:/Samhällsanalys/GIS/grundkartor/fritidshusomraden/",
              gis_url <- "https://www.scb.se/contentassets/bd0b3646d3df4251ab8ddb113cf62271/fo2015_swe99tm_shape.zip")

# hämta handelsområden
ladda_ned_fil(output_mapp = "G:/Samhällsanalys/GIS/grundkartor/handelsomraden/",
              gis_url <- "https://www.scb.se/contentassets/d97aa0b8c63f4877a0d23cff7e9cce9c/arcview-shape.zip")
