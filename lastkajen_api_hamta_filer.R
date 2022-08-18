library(httr)
library(jsonlite)
library(tidyverse)
library(svDialogs)

source("G:/skript/func/func_filer.R", encoding = "utf-8", echo = FALSE)

# För att komma förbi proxyn
set_config(use_proxy(url = "http://mwg.ltdalarna.se", port = 9090, username = Sys.getenv("userid"), password = Sys.getenv("pwd")))
set_config(config(ssl_verifypeer = 0L))

# inställningar 
sparafilmapp <- "G:/Samhällsanalys/GIS/grundkartor/nvdb/"
tabortzipfil <- TRUE                  # ta bort zipfilen när alla filer är uppackade

path <- "https://lastkajen.trafikverket.se/api/Identity/Login"

inlogg <- POST(url = path, body = list(UserName = Sys.getenv("lastkajen_user"),
                                       Password = Sys.getenv("lastkajen_pwd")), encode = "json")

if (inlogg$status_code == 200){
  
  resp_inlogg <- fromJSON(content(inlogg, as = "text"), flatten = TRUE)
  
  #token <- resp_inlogg$access_token
  
  # ==== hitta rätt mapp för transportplanering
  path_mappar <- "https://lastkajen.trafikverket.se/api/DataPackage/GetDataPackages"
  mappar <- GET(url = path_mappar)
  resp_mappar <- fromJSON(content(mappar, as = "text"), flatten = TRUE)
  repeat {
    mapp_val <- dlg_list(resp_mappar$sourceFolder, title = "Välj mapp")
    mapp_val_id <- as.character(resp_mappar[resp_mappar$sourceFolder == mapp_val$res,"id"])
    if (rlang::is_empty(mapp_val$res)) break
      # ==== hitta filer i vald mapp (vägnät för transportplanering)
      path_fillista <- "https://lastkajen.trafikverket.se/api/DataPackage/GetDataPackageFiles"
      fillista <- GET(url = paste0(path_fillista, "/", mapp_val_id))
      resp_fillista <- fromJSON(content(fillista, as = "text"), flatten = TRUE)
      resp_fillista$namn_stlk <- paste0(resp_fillista$name, " (", resp_fillista$size, ")")
      fil_val <- dlg_list(resp_fillista$namn_stlk[str_detect(resp_fillista$name,"zip")], title = "Välj fil")
      if (!rlang::is_empty(fil_val$res)) {
        vald_fil_namn <- as.character(resp_fillista[resp_fillista$namn_stlk == fil_val$res,"name"])  # här hämtar vi namnet på filen, används för att döpa filen nedan
        vald_fil_url <- resp_fillista[resp_fillista$namn_stlk == fil_val$res,"links"]  # här hämtar vi en korrekt url för att hämta en token
        url_token_path <- vald_fil_url[[1]]$href[[2]]          # vi behöver extrahera självaste url:en ur en lista. Första listan, finns bara en och andra raden är för token. Borde vara så i alla listor
          
        # här hämtar vi en token för att kunna ladda ner filen vi vill ha - den är giltig i 1 min
        #token_path <- paste0("https://lastkajen.trafikverket.se/services/api/file/GetDataPackageDownloadToken?id=", 
        #mapp_val_id, "&fileName=", vald_fil_namn)
        token_nedl <- GET(url = url_token_path)
        nedl_token <- fromJSON(content(token_nedl, as = "text"), flatten = TRUE)
        
        # här sker själva nedladdningen
        send_token_path <- paste0("https://lastkajen.trafikverket.se/api/File/GetDataPackageFile?token=", nedl_token)
        nedl_fil_full <- paste0(sparafilmapp, vald_fil_namn)
        fil <- GET(url = send_token_path, write_disk(nedl_fil_full, overwrite = TRUE))
        
        #fil <- download.file(send_token_path, destfile = nedl_fil_full)
        
        # ladda upp filen(filerna) i zip-filen, gör bakcup av filer med samma namn i samma mapp om sådana finns
        filer_i_zipfil <- unzip(nedl_fil_full, list = TRUE)$Name
        for (zip_filnamn in 1:length(filer_i_zipfil)){
          sparafil_en_backup_nvdb(paste0(sparafilmapp, filer_i_zipfil[[zip_filnamn]]))
        }
        zipmapp <- substr(sparafilmapp, 1, nchar(sparafilmapp)-1)    # skapa mapp-variabel för zipuppackning
        unzip(nedl_fil_full, exdir = zipmapp)                        # packa upp zip-fil
        if (tabortzipfil) file.remove(nedl_fil_full)                                   # ta bort zip fil
      }  # if-sats för om man valt fil eller inte
      if (!rlang::is_empty(mapp_val$res) & !rlang::is_empty(fil_val$res)) break
    } # repeat
} # if-sats för felkod eller ok

rm(inlogg)              # ta bort inlogg-listan som innehåller användrnamn och lösenord
