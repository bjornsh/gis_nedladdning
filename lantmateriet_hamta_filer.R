library(httr)
library(rvest)
# library(devtools)

# För att komma förbi proxyn
set_config(use_proxy(url = "http://mwg.ltdalarna.se", port = 9090, username = Sys.getenv("userid"), password = Sys.getenv("pwd")))
set_config(config(ssl_verifypeer = 0L))

#source_url("https://raw.githubusercontent.com/FaluPeppe/func/main/func_API.R")
source("G:/skript/func/func_API.R", encoding = "utf-8", echo = FALSE)

# ======================================== inställningar =============================================================
output_mapp <- "G:/Samhällsanalys/GIS/Grundkartor/"
tabortzipfil <- TRUE
hamta_oversiktskartan <- FALSE
hamta_terrangkartan <- FALSE
hamta_distrikt <- TRUE
lanskod_terrangkartan <- "20"

# ======================================================================================================================

lansnamn_terrangkartan <- hamtaregion_kod_namn(lanskod_terrangkartan) %>% select(region) %>% skapa_kortnamn_lan()  # hämta länsnamnet

# skapa kartvektor för att uppdatera kartor från Lantmäteriet
df_kartor <- data.frame(namn =character(), aktiv=logical(), url_adress=character(), fil=character(), outputmapp=character(), nymapp=character(), undermapp=character())
df_kartor <- df_kartor %>% 
  add_row(namn = "Översiktskartan", aktiv = hamta_oversiktskartan, 
          url_adress = "ftp://download-opendata.lantmateriet.se/GSD-Oversiktskartan_vektor/Sverige/Sweref_99_TM/shape/", 
          fil = "ok_riks_Sweref_99_TM_shape.zip",
          nymapp = "Oversiktskartan") %>% 
  add_row(namn = "Distrikt", aktiv = hamta_distrikt, 
          url_adress = "ftp://download-opendata.lantmateriet.se/GSD-Distriktsindelning/Sverige/Sweref_99_TM/Shape/", 
          fil = "di_riks_Sweref_99_TM_shape.zip",
          nymapp = "Distrikt") %>% 
  add_row(namn = "Terrängkartan", aktiv = hamta_terrangkartan, 
          url_adress = paste0("ftp://download-opendata.lantmateriet.se/GSD-Terrangkartan_vektor/", lansnamn_terrangkartan, "/Sweref_99_TM/shape/"), 
          fil = paste0("tk_", lanskod_terrangkartan, "_Sweref_99_TM_shape.zip"),
          nymapp = "Terrangkartan",
          undermapp = lansnamn_terrangkartan)

df_kartor$outputmapp[is.na(df_kartor$outputmapp)] <- output_mapp     # tilldela outputmapp om det inte finns något värde tilldelat ovan


# funktion för att ladda hem filer från Lantmäteriet =================================
ladda_hem_filer <- function(url_adress, fil, output_mapp, nymapp_namn, undermapp_namn = NA){
  # tilldela rätt värden
  url_nedladd <- url_adress
  fil_nedladd <- fil
  full_neladd <- paste0(url_nedladd, fil)
  output_nedladd <- paste0(output_mapp, fil_nedladd)
  nymapp_nedladd <- paste0(output_mapp, nymapp_namn)
  if (!is.na(undermapp_namn)) {
    undermapp_nedladd <- paste0(nymapp_nedladd,"/", undermapp_namn)
  } else {
    undermapp_nedladd <- NA
  }
  
  # här gör vi själva nedladdningen - den kan ta ganska lång tid
  GET(url = full_neladd, authenticate(user = Sys.getenv("lantmateriet_user"),
                                      password = Sys.getenv("lantmateriet_pwd")),
      write_disk(output_nedladd, overwrite = TRUE), progress())
  
  # och så packar vi upp filerna och lägger i den mapp vi ställt in att de ska läggas, alla tempfiler tas bort samt även zip-filen om vi inte valt annorlunda
  temp_mapp <- paste0(output_mapp, "temp")                                         # skapa en temporär mapp
  unzip(output_nedladd, exdir = temp_mapp)                                         # packa upp zip-fil i temp-mapp
  fillista <- list.files(path = temp_mapp, full.names = TRUE, recursive = TRUE)    # lägg alla filer i temp-mappen inkl. undermappar i en lista
  if (!dir.exists(nymapp_nedladd)) dir.create(nymapp_nedladd)                      # skapa ny mapp om den inte finns
  if (!is.na(undermapp_nedladd) & !dir.exists(undermapp_nedladd)) dir.create(undermapp_nedladd)   # om undermapp används och den inte existerar så skapas den
  kopieramapp <- ifelse(is.na(undermapp), nymapp_nedladd, undermapp_nedladd)
  for (f in fillista) file.copy(from = f, to = kopieramapp, overwrite = TRUE)                     # kopiera filerna till den nya mappen
  unlink(temp_mapp, recursive = TRUE)                                              # ta bort temp-mappen
  if (tabortzipfil) file.remove(output_nedladd)                                    # ta bort zip fil om vi ställt in det så
}

# loopa igenom kartvektor och hämta de kartor som har aktiv == TRUE
for (karta in 1:nrow(df_kartor)){
  if (df_kartor[karta, "aktiv"] == TRUE) {
    ladda_hem_filer(url = df_kartor[karta, "url"],
                    fil = df_kartor[karta, "fil"],
                    output_mapp = df_kartor[karta, "outputmapp"],
                    nymapp_namn = df_kartor[karta, "nymapp"],
                    undermapp_namn = df_kartor[karta, "undermapp"])
  }
}
