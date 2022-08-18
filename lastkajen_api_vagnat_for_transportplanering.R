library(httr)
library(jsonlite)
library(tidyverse)

source("G:/skript/func/func_filer.R", encoding = "utf-8", echo = FALSE)

# För att komma förbi proxyn
set_config(use_proxy(url = "http://mwg.ltdalarna.se", port = 9090))
set_config(config(ssl_verifypeer = 0L))

# inställningar 
sparafilmapp <- "G:/Samhällsanalys/GIS/NVDB/"
tabortzipfil <- TRUE                  # ta bort zipfilen när alla filer är uppackade

path <- "https://lastkajen.trafikverket.se/api/Identity/Login"

inlogg <- POST(url = path, body = list(UserName = Sys.getenv("lastkajen_user"),
                                       Password = Sys.getenv("lastkajen_pwd")), encode = "json")

if (inlogg$status_code == 200){
  
  resp_inlogg <- fromJSON(content(inlogg, as = "text"), flatten = TRUE)
  
  token <- resp_inlogg$access_token
  
  # ==== hitta rätt mapp för transportplanering
  path_mappar <- "https://lastkajen.trafikverket.se/api/DataPackage/GetDataPackages"
  mappar <- GET(url = path_mappar)
  resp_mappar <- fromJSON(content(mappar, as = "text"), flatten = TRUE)
  transp_plan_id <- as.character(resp_mappar %>% filter(str_detect(name, "transportplanering")) %>% 
    select(id))
  
  # ==== hitta filer i vald mapp (vägnät för transportplanering)
  path_fillista <- "https://lastkajen.trafikverket.se/api/DataPackage/GetDataPackageFiles"
  fillista <- GET(url = paste0(path_fillista, "/", transp_plan_id))
  resp_fillista <- fromJSON(content(fillista, as = "text"), flatten = TRUE)
  transp_plan_namn <- resp_fillista[grepl("zip", resp_fillista$name) & grepl("Geopackage", resp_fillista$name),"name"]
  transp_plan_url <- resp_fillista[grepl("zip", resp_fillista$name) & grepl("Geopackage", resp_fillista$name),"links"]
  url_token <- transp_plan_url[[1]]$href[[2]]
  
  # här hämtar vi en token för att kunna ladda ner filen vi vill ha - den är giltig i 1 min
  token_nedl <- GET(url = url_token)
  nedl_token <- fromJSON(content(token_nedl, as = "text"), flatten = TRUE)
  
  # här sker själva nedladdningen
  nedl_fil_path <- paste0("https://lastkajen.trafikverket.se/api/File/GetDataPackageFile?token=", nedl_token)
  nedl_fil_full <- paste0(sparafilmapp, transp_plan_namn)
  GET(url = nedl_fil_path, write_disk(nedl_fil_full, overwrite = TRUE), progress())
  
  # ladda upp filen(filerna) i zip-filen, gör bakcup av filer med samma namn i samma mapp om sådana finns
  filer_i_zipfil <- unzip(nedl_fil_full, list = TRUE)$Name
  for (zip_filnamn in 1:length(filer_i_zipfil)){
    sparafil_en_backup_nvdb(paste0(sparafilmapp, filer_i_zipfil[[zip_filnamn]]))
  }
  zipmapp <- substr(sparafilmapp, 1, nchar(sparafilmapp)-1)    # skapa mapp-variabel för zipuppackning
  unzip(nedl_fil_full, exdir = zipmapp)                        # packa upp zip-fil
  if (tabortzipfil) file.remove(nedl_fil_full)                                   # ta bort zip fil
  
  rm(inlogg)               # ta bort inlogg som innehåller anvnamn och lösenord 
}