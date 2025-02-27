suppressMessages(library("gprofiler2"))
suppressMessages(library("BSgenome"))

args <- commandArgs(TRUE)

f_genelist <- args[1]
assembly_ver <- args[2]
out <- args[3]
threshold <- 0.05

## read gene list
genelist <- tryCatch({
  read.table(f_genelist, header = FALSE)
}, error = function(e) {
  print(paste("Error reading gene list file:", e$message))
  data.frame()
})

# Add a check if the gene list is empty, skip the analysis
if (nrow(genelist) == 0) {
  print("Gene list is empty, skipping the analysis")
} else {
  ## convert ucsc name -> organism name
  av_gen <- available.genomes(splitNameParts = TRUE)
  spc <- av_gen[av_gen[, 4] == assembly_ver, 2][1]
  spc <- tolower(as.character(spc))

  ## gost
  tryCatch({
    go_result <- gost(query = as.vector(genelist$V1),
                      organism = spc, user_threshold = threshold,
                      evcodes = TRUE, significant = FALSE)
  }, error = function(e) {
    print(paste("Error in gost function:", e$message))
    go_result <- NULL
  })

  if (!is.null(go_result)) {
    df_go_result <- apply(go_result$result, 2, as.character)
    write.table(df_go_result, file = paste0(out, ".GOresult.txt"),
                quote = FALSE, sep = "\t")

    res_pdf <- gostplot(go_result, capped = FALSE, interactive = FALSE)
    pdf(paste0(out, ".GOresult.pdf"))
    res_pdf
    dev.off()
  } else {
    print("Skipping GO result processing due to error in gost function")
  }
}
