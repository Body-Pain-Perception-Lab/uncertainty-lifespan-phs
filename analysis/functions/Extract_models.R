get_models <- function(osftoken){
  # get the preanalyzed data from osf:
  if (!dir.exists(here::here("saved_stanmodels"))) {
    osfr::osf_auth(token = osf_token)
    
    PHS <- osfr::osf_retrieve_node("https://osf.io/wxhcq")
    
    downloaded = PHS %>%
      osfr::osf_ls_files(pattern = "saved_stanmodels") %>%
      osfr::osf_download(path = here::here(""), recurse = TRUE, conflicts = "overwrite", progress = TRUE)
    

       
  }
  
}
