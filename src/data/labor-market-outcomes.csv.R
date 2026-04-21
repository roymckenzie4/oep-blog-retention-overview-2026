# labor-market-outcomes.csv.R
# Observable Framework data loader
# Reads teacher workforce transitions data, computes labor force outcome
# percentages by school year, and writes CSV to stdout.
#
# Output columns:
#   schoolyear  - e.g. "2014-15"
#   category    - Stayer, Mover - Same District, Mover - New District, Switcher, Exiter, Retired # nolint
#   value       - percentage (0-100)
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
  unset = "/Users/roymckenzie/Library/CloudStorage/Box-Box/0 - Arkansas Projects/Projects/Teacher Pipeline/Teacher Retention/0_data/Classroom and Inclusion SPED Teachers/teacher_workforce_transitions_Classroom and Inclusion SPED Teachers_04-20-26.csv" # nolint
)

# --- Load and prep data ---
teacher_lm <- fread(data_path,
  colClasses = "character",
  na.strings = c("", "NA")
) |>
  janitor::clean_names() |>
  mutate(fiscal_year = as.integer(fiscal_year))

# --- Compute labor force outcomes for prior-year teachers ---
graph_data <- teacher_lm %>%
  filter(fiscal_year > 2014) %>%
  filter(lag_teacher == TRUE) %>%
  mutate(
    lf_exiter_retired = (lf_outcome == "Exiter" & lf_exiter_retired == 1),
    lf_exiter_other = (lf_outcome == "Exiter" & lf_exiter_retired == 0),
    lf_mover_new_district = (lf_outcome == "Mover" & lf_mover_new_district == 1),
    lf_mover_same_district = (lf_outcome == "Mover" & lf_mover_new_district == 0),
    lf_switcher = (lf_outcome == "Switcher"),
    lf_stayer = (lf_outcome == "Stayer")
  ) %>%
  group_by(fiscal_year) %>%
  summarise(
    Retired = mean(lf_exiter_retired, na.rm = TRUE),
    Exiter = mean(lf_exiter_other, na.rm = TRUE),
    Switcher = mean(lf_switcher, na.rm = TRUE),
    `Mover - New District` = mean(lf_mover_new_district, na.rm = TRUE),
    `Mover - Same District` = mean(lf_mover_same_district, na.rm = TRUE),
    Stayer = mean(lf_stayer, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    schoolyear = paste0(fiscal_year - 1, "-", substr(fiscal_year, 3, 4))
  ) %>%
  select(-fiscal_year) %>%
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
