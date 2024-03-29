# List of symbols from TradingView
# Accepts url 
fetch_tv_list <- function(stock.list) {
  
  require(dplyr)
  require(httr2)
  require(xml2)
  
  if(!is.character(stock.list)) stop('`list` param must be a character.')

  req <- httr2::request('https://www.tradingview.com') %>%
    httr2::req_url_path_append(
      'markets',
      'stocks-usa',
      stock.list
    )
  
  res <- req_perform(req) %>% 
    resp_body_html()
  
  found <- res %>%
    xml2::xml_find_all('//tbody/tr') %>% 
    xml2::as_list()
    
  symbols <- purrr::map(
    found, 
    purrr::pluck, 
    1, 
    1, 
    'a'
  ) %>% 
    unlist()
  
  return(symbols)
  
}
