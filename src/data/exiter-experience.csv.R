# exiter-experience.csv.R
# Observable Framework data loader
# Computes the experience-level breakdown of non-retiree exiters by school year.
#
# Output columns:
#   schoolyear  - e.g. "2024-25"
#   category    - "0-3 years", "4-10 years", "11-20 years", "20+ years"
#   value       - percentage of exiters in this experience bucket (0-100)
#   label       - formatted percentage string e.g. "34.2"

library(data.table)
library(dplyr)
library(tidyr)

# --- Configuration ---
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
  mutate(
    fiscal_year = as.integer(fiscal_year),
    exp_numeric = as.numeric(totalyearsofexperience_corrected)
  )

# --- Filter to non-retiree exiters who were teachers the prior year ---
exiters <- teacher_lm %>%
  filter(lag_teacher == TRUE) %>%
  filter(lf_outcome == "Exiter" & lf_exiter_retired == 0) %>%
  filter(!is.na(exp_numeric)) %>%
  mutate(
    category = case_when(
      exp_numeric <= 3 ~ "0-3 years",
      exp_numeric <= 10 ~ "4-10 years",
      exp_numeric <= 20 ~ "11-20 years",
      exp_numeric > 20 ~ "20+ years"
    ),
    category = factor(category, levels = c("0-3 years", "4-10 years", "11-20 years", "20+ years"))
  )

# --- Compute percentage within each year ---
exiter_experience <- exiters %>%
  group_by(fiscal_year, category) %>%
  summarise(count = n(), .groups = "drop") %>%
  group_by(fiscal_year) %>%
  mutate(
    value = count / sum(count) * 100,
    label = sprintf("%.1f", value),
    schoolyear = paste0(fiscal_year - 1, "-", substr(as.character(fiscal_year), 3, 4))
  ) %>%
  ungroup() %>%
  select(schoolyear, category, value, label) %>%
  arrange(schoolyear, category)

# --- Write to stdout as CSV ---
write.csv(exiter_experience, stdout(), row.names = FALSE)
