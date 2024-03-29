# This script loops over a process that:
# Sources specified symbol fetchers
# Checks cooldown of those fetchers
# Fetches symbols from various APIs if not on cooldown

library(dplyr)
library(dbplyr)

source('./src/fetch_if_ready.R')
source('./src/fetchers/fetch_tv_list.R')


# Must be in first 15 minutess of the hour
if(lubridate::minute(Sys.time()) > 15) {
  
  message('Not yet time for hourly symbol check, sleeping for 8-10 mins.')
  Sys.sleep(60 * runif(1,8,10))
  stop('Done sleeping. Stopping process.')
  
} else {
  
  message('Time for symbol fetcher process to run. Updating last_run.')
  last_run <- Sys.time()
  
  db_con <- tryCatch(
    expr = {
      DBI::dbConnect(
        drv = RPostgres::Postgres(),
        dbname = Sys.getenv('POSTGRES_DB'),
        host = Sys.getenv('POSTGRES_HOST'),
        port = Sys.getenv('POSTGRES_PORT'),
        user = Sys.getenv('POSTGRES_USER'),
        password = Sys.getenv('POSTGRES_PASSWORD')
      )
    },
    error = function(e) e
  )
  
  if(inherits(db_con, 'error')){
    message('Error connecting to database:', e,
            'Sleeping before trying again.')
    Sys.sleep(60)
    stop('Done sleeping. Stopping process.')
  }
  
  # Trading View Weekly
  trading_view_lists <- c(
    'market-movers-large-cap',
    'market-movers-largest-employers',
    'market-movers-highest-net-income',
    'market-movers-highest-cash',
    'market-movers-active', 
    'market-movers-highest-revenue'
  )
  
  picked <- sample(trading_view_lists, 1)
  
  tv_name <- paste0(
    'tv_',
    gsub('-', '_', picked)
  )
  
  new_rows <- fetch_if_ready(
    db.con = db_con,
    fetcher.name = tv_name,
    fetcher.fun = fetch_tv_list,
    stock.list = picked,
    cooldown = 'monthly'
  )
  
  DBI::dbDisconnect(db_con)
  
  if (new_rows > 0) {
    message('Process ran normally. Sleeping for 30 minutes.')
    Sys.sleep(60 * 30)  
  } else {
    message('Process picked fetcher on cooldown. Sleeping for 1 minute.')
    Sys.sleep(60)
  }
  
  stop('Done sleeping. Stopping process.')
  
} # End of symbol fetcher process that runs hourly
