root_dir <- "~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/"

# Find all R scripts recursively
r_scripts <- list.files(
  path = root_dir,
  pattern = "\\.[Rr]$",
  recursive = TRUE,
  full.names = TRUE
)

cat("Found", length(r_scripts), "R scripts\n")

results <- data.frame(
  script = character(),
  status = character(),
  error = character(),
  stringsAsFactors = FALSE
)

for (script in r_scripts) {
  
  cat("\n=====================================\n")
  cat("Running:", script, "\n")
  cat("=====================================\n")
  
  tryCatch({
    
    source(script, echo = FALSE, chdir = TRUE)
    
    results <- rbind(
      results,
      data.frame(
        script = script,
        status = "SUCCESS",
        error = "",
        stringsAsFactors = FALSE
      )
    )
    
    cat("SUCCESS\n")
    
  }, error = function(e) {
    
    msg <- conditionMessage(e)
    
    cat("FAILED\n")
    cat(msg, "\n")
    
    results <- rbind(
      results,
      data.frame(
        script = script,
        status = "FAILED",
        error = msg,
        stringsAsFactors = FALSE
      )
    )
    
  })
}

write.csv(
  results,
  file.path(root_dir, "script_execution_log.csv"),
  row.names = FALSE
)

cat("\nFinished.\n")
cat(sum(results$status == "SUCCESS"), "successful\n")
cat(sum(results$status == "FAILED"), "failed\n")