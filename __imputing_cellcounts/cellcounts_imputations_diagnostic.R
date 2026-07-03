setwd("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/")

# Impute missing cell-count data
# Q. What data should be included/excluded when doing an imputation?

library(naniar)
library(DataExplorer)
library(misty)
library(mice)
library(psych)
library(tidyverse)

out_dir <- "./__imputing_cellcounts"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

cellcounts_wide <- read.csv("./__merging_cellcounts/cellcounts_wide.csv")

pdf(file.path(out_dir, "diagnostic_plots.pdf"))

# Diagnostic plots -------------------------------------------------------------

vis_miss(cellcounts_wide)

data_trimmed <- cellcounts_wide[, colMeans(!is.na(cellcounts_wide)) > 0.35]
vis_miss(data_trimmed)

# Eliminate ratios which are redundant
# Microglia ratio is not redundant, so left in
drop_cols <- c(
  "Cerebellum_N.p.mg", "Cerebellum_O.p.N", "Cerebellum_O.p.mg",
  "CerebralCortex_N.p.mg", "CerebralCortex_O.p.N", "CerebralCortex_O.p.mg",
  "RoB_O.p.N", "RoB_O.p.mg", "OlfactoryBulb_O.p.N",
  "OlfactoryBulb_N.p.mg", "RoB_N.p.mg"
)

data_trimmed <- data_trimmed[, !names(data_trimmed) %in% drop_cols]
vis_miss(data_trimmed)

# Check whether missingness patterns are correlated
data_trimmed %>%
  mutate(across(
    everything(),
    ~ as.integer(is.na(.x)),
    .names = "{.col}_na"
  )) %>%
  DataExplorer::plot_correlation(
    type = "continuous",
    cor_args = list(use = "pairwise.complete.obs")
  )

# Scale log-transformed numeric data before imputation -------------------------

id_col <- data_trimmed[, 1, drop = FALSE]
x <- data_trimmed[, -1]

log_x <- log(x)

scale_center <- sapply(log_x, mean, na.rm = TRUE)
scale_scale  <- sapply(log_x, sd, na.rm = TRUE)

s <- as.data.frame(scale(log_x, center = scale_center, scale = scale_scale))

# MCAR test -------------------------------------------------------------------

mcar_result <- tryCatch(
  na.test(s),
  error = function(e) {
    warning(
      "na.test(s) failed, likely because of degenerate/zero-variance covariance patterns: ",
      conditionMessage(e),
      call. = FALSE
    )
    NULL
  }
)

# Histograms ------------------------------------------------------------------

multi.hist(s[, sapply(s, is.numeric)], global = FALSE)

# Imputation ------------------------------------------------------------------

# Tried: pmm, midas.touch, cart, rf, norm, norm.predict, lasso.norm, lasso.select.norm
# cart and rf were OK

pred <- quickpred(s, minpuc = 0.3)

imp <- mice(
  s,
  m = 30,
  maxit = 10,
  seed = 777,
  method = "rf",
  predictorMatrix = pred
)

imp_file <- file.path(out_dir, "imp30x10.RData")
save(imp, file = imp_file)

# Diagnostic plots for imputation
plot(imp)
densityplot(imp)
stripplot(imp, pch = 20, cex = 1.2)

dev.off()

# Export completed datasets ---------------------------------------------------

for (i in seq_len(imp$m)) {
  
  completed_scaled <- complete(imp, i)
  
  # Back-transform: scaled log values -> log values -> original scale
  completed_log <- sweep(completed_scaled, 2, scale_scale, `*`)
  completed_log <- sweep(completed_log, 2, scale_center, `+`)
  completed_original <- as.data.frame(exp(completed_log))
  
  completed_original <- bind_cols(id_col, completed_original)
  
  write.csv(
    completed_original,
    file = file.path(out_dir, paste0("cellcounts_imputed_", i, ".csv")),
    row.names = FALSE
  )
}

# Also save first completed dataset separately for quick inspection ------------

set_1_scaled <- complete(imp, 1)

set_1_log <- sweep(set_1_scaled, 2, scale_scale, `*`)
set_1_log <- sweep(set_1_log, 2, scale_center, `+`)
set_1 <- bind_cols(id_col, as.data.frame(exp(set_1_log)))

write.csv(
  set_1,
  file = file.path(out_dir, "cellcounts_imputed_set_1.csv"),
  row.names = FALSE
)
