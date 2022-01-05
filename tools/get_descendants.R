# Description: 
# Author: Haley Hunter-Zinck
# Date: 

# pre-setup  ---------------------------

library(optparse)

waitifnot <- function(cond, msg) {
  if (!cond) {
    
    for (str in msg) {
      message(str)
    }
    message("Press control-C to exit and try again.")
    
    while(T) {}
  }
}

# user input ----------------------------

option_list <- list( 
  make_option(c("-c", "--cui"), type = "character",
              help="UMLS Concept Unique Identifier (CUI)"),
  make_option(c("-s", "--vocab"), type = "character",
              help="UMLS vocabulary code"),
  make_option(c("-u", "--username"), type = "character",
              help="Synapse ID of input file"),
  make_option(c("-p", "--password"), type = "character",
              help="Synapse ID of input file"),
  make_option(c("-v", "--verbose"), action="store_true", default = FALSE, 
              help="Output script messages to the user.")
)
opt <- parse_args(OptionParser(option_list=option_list))
waitifnot(!is.null(opt$cui) && !is.null(opt$vocab) && !is.null(opt$username) && !is.null(opt$password),
          msg = "Rscript get_descendants.R -h")

cui <- opt$cui
vocab <- opt$vocabulary
username <- opt$username
password <- opt$password
verbose <- opt$verbose

# setup ----------------------------

tic = as.double(Sys.time())

library(glue)
library(DBI)

# db
my_server = 'localhost'
my_dbname = 'umls'
my_schema = 'meta2021aa'
my_sql_type = 'postgres'

# functions ----------------------------

setup_postgres = function(my_server, my_dbname, my_schema, my_sql_type, my_user, 
                          my_password) {
  assign("dbqc_server", my_server, envir = .GlobalEnv)
  assign("dbqc_dbname", my_dbname, envir = .GlobalEnv)
  assign("dbqc_schema", my_schema, envir = .GlobalEnv)
  assign("dbqc_sql_type", my_sql_type, envir = .GlobalEnv)
  assign("dbqc_user", my_user, envir = .GlobalEnv)
  assign("dbqc_password", my_password, envir = .GlobalEnv)
  
  return(T)
}

query_postgres = function(query) {
  
  # open database connection
  con <- dbConnect(RPostgres::Postgres(), dbname = dbqc_dbname, user = dbqc_user, 
                   password = dbqc_password)
  
  # fetch query result
  query = gsub(pattern = "[[:space:]]+", replacement = " ", x = query)
  res <- dbSendQuery(con, query)
  data <- dbFetch(res)
  
  # close database connection
  dbClearResult(res)
  dbDisconnect(con)
  
  # format output
  if(nrow(data) == 1 && ncol(data) == 1 && typeof(data[1,1]) == "double") {
    return(as.double(data[1,1]))
  }
  
  return(as.matrix(data))
}

get_descendants <- function(cui_root, vocab, verbose = F) {
  
  desc <- c()
  
  query <- glue("SELECT DISTINCT cui2 FROM {dbqc_schema}.mrrel WHERE cui1 = '{cui}' AND sab = '{vocab}' AND rel = 'CHD'")
  cui_children <- query_postgres(query)
  
  if (verbose) {
    print(glue("CUI '{cui_root}' has {length(cui_children)} children."))
  }
  
  if (!length(cui_children)) {
    return(cui_root)
  }
  
  for (cui_child in cui_children) {
    desc <- append(desc, get_descendants(cui_root = cui_child, 
                                  vocab = vocab, 
                                  verbose = verbose))
  }
  
  return(append(desc, cui_root))
}

# main ----------------------------

setup_postgres(my_server = my_server, 
               my_dbname = my_dbname, 
               my_schema = my_schema, 
               my_sql_type = my_sql_type, 
               my_user = username, 
               my_password = password)

desc <- get_descendants(cui = cui, vocab = vocab, verbose = verbose)

# close out ----------------------------

toc = as.double(Sys.time())
print(glue("Runtime: {round(toc - tic)} s"))
