# labor-market-outcomes.csv.R
# Observable Framework data loader
# Reads teacher workforce transitions data, computes labor force outcome
# percentages by school year, and writes CSV to stdout.
#
# Output columns:
#   schoolyear  - e.g. "2014-15"
#   category    - Stayer, Mover - Same District, Mover - New District, Switcher, Exiter, Retired # nolint
#   value       - proportion (0-1)
#   label       - formatted percentage string e.g. "79.0"

library(data.table)
library(dplyr)
library(tidyr)
library(stringr)

# --- Configuration ---
# When running locally, this should point to Box/OneDrive copy.
# TODO: Update this path to wherever the data lives in your environment.
# OPEN QUESTION: how to set this with environment variable? Or do we need to?
data_path <- Sys.getenv(
  "TEACHER_LM_DATA",
  unset = "/Users/roymckenzie/Library/CloudStorage/Box-Box/0 - Arkansas Projects/Projects/Teacher Pipeline/Teacher Retention/0_data/Classroom and Inclusion SPED Teachers/teacher_workforce_transitions_classroom and inclusion SPED_12-18-25.csv" # nolint
)

# --- Helper ---
clean_names <- function(df) {
  df %>% setNames(tolower(gsub("[ _.\\\\/]", "", names(.)))) # nolint
}

# --- Load and prep data ---
teacher_lm <- fread(data_path,
  colClasses = "character",
  na.strings = c("", "NA")
) |>
  clean_names() |>
  mutate(fiscalyear = as.integer(fiscalyear))

# --- Compute labor force outcomes for prior-year teachers ---
graph_data <- teacher_lm %>%
  filter(fiscalyear > 2014) %>%
  filter(lagteacher == TRUE) %>%
  mutate(
    lfexiterretired = (lfoutcome == "Exiter" & lfexiterretired == 1),
    lfexiterother = (lfoutcome == "Exiter" & lfexiterretired == 0),
    lfmovernewdistrict = (lfoutcome == "Mover" & lfmovernewdistrict == 1),
    lfmoversamedistrict = (lfoutcome == "Mover" & lfmovernewdistrict == 0),
    lfswitcher = (lfoutcome == "Switcher"),
    lfstayer = (lfoutcome == "Stayer")
  ) %>%
  group_by(fiscalyear) %>%
  summarise(
    Retired = mean(lfexiterretired, na.rm = TRUE),
    Exiter = mean(lfexiterother, na.rm = TRUE),
    Switcher = mean(lfswitcher, na.rm = TRUE),
    `Mover - New District` = mean(lfmovernewdistrict, na.rm = TRUE),
    `Mover - Same District` = mean(lfmoversamedistrict, na.rm = TRUE),
    Stayer = mean(lfstayer, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    schoolyear = paste0(fiscalyear - 1, "-", substr(fiscalyear, 3, 4))
  ) %>%
  select(-fiscalyear) %>%
  pivot_longer(
    cols = c(
      Retired, Exiter, Switcher,
      `Mover - New District`, `Mover - Same District`, Stayer
    ),
    names_to = "category",
    values_to = "value"
  ) %>%
  mutate(
    value = value * 100,
    label = sprintf("%.1f", value)
  ) %>%
  arrange(schoolyear, category)

# --- Write to stdout as CSV ---
write.csv(graph_data, stdout(), row.names = FALSE)

# graph_data %>%
#   mutate(
#     era = case_when(
#       schoolyear %in% c("2014-15", "2015-16", "2016-17", "2017-18", "2018-19", "2019-20") ~ "pre",
#       schoolyear == "2025-26" ~ "2025-26",
#       TRUE ~ "post"
#     )
#   ) %>%
#   group_by(era, category) %>%
#   summarize(avg = mean(value))
