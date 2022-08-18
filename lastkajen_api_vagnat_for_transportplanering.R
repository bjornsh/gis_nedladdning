##################################################################################
### Syfte
##################################################################################

# Automatisera nedladdning av Trafikverkets NVDB länsdata, dvs en länsdatabas
# nedladdat data skriver över tidigare nedladdning



##################################################################################
### Clean start
##################################################################################

rm(list = ls())
gc()


##################################################################################
### Libraries etc
##################################################################################

if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse,
               httr, jsonlite)


# avoid scientific notation
options(scipen=999)



##################################################################################
### Define paths and create data directories (if not already exist)
##################################################################################

# create directories
dir.create(paste0(getwd(), "/output/"))
dir.create(paste0(getwd(), "/shapefile"))

# define paths
folder_github = "https://github.com/bjornsh/gis_data/raw/main/" 

# Read keys 
api_fil = read_file("Z:/api")
UserName = gsub('^.*lastkajen_id: \\s*|\\s*\r.*$', "", api_fil)
Password = gsub('^.*lastkajen_key: \\s*|\\s*\r.*$', "", api_fil)




##################################################################################
### Define variables
##################################################################################

# Vilket län 
lan = "Uppsala län"

# inställningar 
sparafilmapp <- paste0(getwd(), "/shapefile/")
tabortzipfil <- TRUE                  # ta bort zipfilen när alla filer är uppackade


##################################################################################
### Load data
##################################################################################

path <- "https://lastkajen.trafikverket.se/api/Identity/Login"
query <- list(UserName = UserName,
              Password = Password)

inlogg <- POST(url = path, body = query, encode = "json")

if (inlogg$status_code == 200){
  
  resp_inlogg <- fromJSON(content(inlogg, as = "text"), flatten = TRUE)
  
  token <- resp_inlogg$access_token
  
  # ==== hitta rätt mapp för transportplanering
  path_mappar <- "https://lastkajen.trafikverket.se/api/DataPackage/GetDataPackages"
  mappar <- GET(url = path_mappar)
  resp_mappar <- fromJSON(content(mappar, as = "text"), flatten = TRUE)
  transp_plan_id <- as.character(resp_mappar %>% filter(str_detect(sourceFolder, "Länsfiler NVDB-data") &
                                                          str_detect(sourceFolder, lan)) %>%  
                                   select(id))
  
  # ==== hitta filer i vald mapp (vägnät för transportplanering)
  path_fillista <- "https://lastkajen.trafikverket.se/api/DataPackage/GetDataPackageFiles"
  fillista <- GET(url = paste0(path_fillista, "/", transp_plan_id))
  resp_fillista <- fromJSON(content(fillista, as = "text"), flatten = TRUE)
  transp_plan_namn <- resp_fillista[grepl("zip", resp_fillista$name) & 
                                      grepl("geopackage", tolower(resp_fillista$name)),"name"] # tolower (stavning skiljer sig mellan olika dataprodukter)
  transp_plan_url <- resp_fillista[grepl("zip", resp_fillista$name) & 
                                     grepl("geopackage", tolower(resp_fillista$name)),"links"]
  url_token <- transp_plan_url[[1]]$href[[2]]
  
  # här hämtar vi en token för att kunna ladda ner filen vi vill ha - den är giltig i 1 min
  token_nedl <- GET(url = url_token)
  nedl_token <- fromJSON(content(token_nedl, as = "text"), flatten = TRUE)
  
  # här sker själva nedladdningen
  nedl_fil_path <- paste0("https://lastkajen.trafikverket.se/api/File/GetDataPackageFile?token=", nedl_token)
  nedl_fil_full <- paste0(sparafilmapp, transp_plan_namn)
  GET(url = nedl_fil_path, write_disk(nedl_fil_full, overwrite = TRUE), progress())
  
  # packa upp zip-fil och spara filer
  unzip(nedl_fil_full, exdir = sparafilmapp)

  # ta bort zip fil
  if (tabortzipfil) file.remove(nedl_fil_full)                 
  
}
