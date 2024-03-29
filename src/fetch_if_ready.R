fetch_if_ready <- function(
  db.con, fetcher.name,
  fetcher.fun,
  ...,
  cooldown = c('daily', 'weekly', 'monthly')
) {
  
  require(dplyr)
  require(dbplyr)
  
  res <- 0
  
  message(glue::glue('Current fetcher: {fetcher.name}.'))
  
  if(!DBI::dbExistsTable(db_con, 'symbols')) {
    
    message('No symbols table found, creating new table.')
    
    new_symbols <- fetcher.fun(...)
    
    # Always include VOO, benchmark of choice
    new_symbols <- c(new_symbols, 'VOO')
    
    new_df <- data.frame(
      symbol = new_symbols,
      fetcher_name = fetcher.name,
      update_timestamp = Sys.time()
    )
    
    message('Data fetched.')
    
    new_df %>%
      DBI::dbCreateTable(
        conn = db.con,
        name = 'symbols',
        fields = .
      )
    
    message('Table created.')
    
    new_df %>%
      DBI::dbAppendTable(
        conn = db.con,
        name = 'symbols',
        value = .
      )
    
    res <- nrow(new_df)
    
    message('Records appended.')
    
  }
  
  last_update <- db.con %>% 
    tbl('symbols') %>% 
    filter(fetcher_name == !!fetcher.name) %>% 
    collect() %>% 
    pull('update_timestamp')
  
  if(length(last_update) < 1) {
    message('Table exists, but not this fetcher.')
    last_update <- lubridate::make_datetime() # Jan 1 1970 00:00
  } else {
    last_update <- max(last_update)
  }
  
  if(cooldown == 'daily') {
    cd_check <- Sys.time() - last_update >= lubridate::hours(12)
    time_of_day_check <- lubridate::hour(Sys.time()) <= 6
  } else if(cooldown == 'weekly') {
    cd_check <- Sys.time() - last_update >= lubridate::days(4)
    time_of_day_check <- lubridate::wday(Sys.time()) <= 2
  } else if(cooldown == 'monthly') {
    cd_check <- Sys.time() - last_update >= lubridate::days(15)
    time_of_day_check <- lubridate::day(Sys.time()) <= 8
  }
  
  if(cd_check & time_of_day_check) {
    
    message('Fetcher is off cooldown.')
    
    update_symbols <- fetcher.fun(...)
    
    # Always include VOO, benchmark of choice
    update_symbols <- c(update_symbols, 'VOO')
    
    update_df <- data.frame(
      symbol = update_symbols,
      fetcher_name = fetcher.name,
      update_timestamp = Sys.time()
    )
    
    message('Data fetched.')
    
    update_df %>%
      DBI::dbAppendTable(
        conn = db.con,
        name = 'symbols',
        value = .
      )

    res <- nrow(update_df)
    
    message('Records appended.')
    
  } else {
    
    if(!cd_check) message('Fetcher is on cooldown.')
    if(!time_of_day_check) message('Fetcher is waiting for hour/day.')
    
  }
  
  return(res)
  
}
