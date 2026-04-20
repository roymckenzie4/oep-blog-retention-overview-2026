# district-retention.csv.R
# Observable Framework data loader
#
# Computes district-level teacher retention rates. One row per district with
# pre-pandemic (2014-15 to 2019-20) vs. recent (2023-24 to 2025-26) averages.
# Includes GEOID and district attributes for the scatter plot.
#
# Output columns:
#   districtlea              - ADE LEA code (string, e.g. "0101000")
#   geoid                    - NCES GEOID for joining with Census geometry
#   district_name            - District name (from GeoJSON)
#   county_name              - County name
#   urban_centric_locale     - NCES locale code
#   retention_prepandemic_pct - Mean retention rate 2014-15 to 2019-20 (percent, rounded to 1 decimal)
#   retention_recent_pct      - Mean retention rate 2023-24 to 2025-26 (percent, rounded to 1 decimal)
#   retention_change_pp       - Change from pre-pandemic to recent (percentage points, rounded to 1 decimal)
#   shortage_status           - "Shortage" or "Not Shortage" (2025-26 state designation)

library(data.table)
library(dplyr)
library(tidyr)
library(purrr)
library(janitor)
library(readr)
library(sf)

# --- Configuration ---
# Pre-pandemic fiscal years (school years 2014-15 through 2019-20).
# 2019-20 is included: teachers made their decisions before COVID.
PRE_PANDEMIC_YEARS <- c(2015, 2016, 2017, 2018, 2019, 2020)
RECENT_YEARS <- c(2024, 2025, 2026)
# Minimum pre-pandemic years required per district (out of 6 possible)
MIN_PREPANDEMIC_YEARS <- 4

data_path <- Sys.getenv(
  "TEACHER_LM_DATA",
  unset = "/Users/roymckenzie/Library/CloudStorage/Box-Box/0 - Arkansas Projects/Projects/Teacher Pipeline/Teacher Retention/0_data/Classroom and Inclusion SPED Teachers/teacher_workforce_transitions_classroom and inclusion SPED_12-18-25.csv" # nolint
)

# --- Load and prep data ---
teacher_lm <- fread(
  data_path,
  colClasses = "character",
  na.strings = c("", "NA")
) |>
  janitor::clean_names() |>
  mutate(fiscal_year = as.integer(fiscal_year))

# --- Compute district-level retention rates by year ---
calculate_retention_rates <- function(year, teacher_lm) {
  teachers_year_before <- teacher_lm |>
    filter(teacher == TRUE, fiscal_year == year - 1) |>
    select(research_id, districtlea_before = districtlea)

  teachers_year <- teacher_lm |>
    filter(fiscal_year == year) |>
    left_join(teachers_year_before, by = "research_id")

  teachers_year |>
    filter(lf_outcome != "New") |>
    group_by(districtlea_before) |>
    summarise(
      teachers_before = n(),
      stayers = sum(
        lf_outcome == "Stayer" |
          (lf_outcome == "Mover" & lf_mover_same_district == 1),
        na.rm = TRUE
      ),
      movers_out = sum(
        lf_outcome == "Mover" & lf_mover_new_district == 1,
        na.rm = TRUE
      ),
      switchers = sum(lf_outcome == "Switcher", na.rm = TRUE),
      exiters = sum(
        lf_outcome == "Exiter" & lf_exiter_not_retired == 1,
        na.rm = TRUE
      ),
      retirements = sum(
        lf_outcome == "Exiter" & lf_exiter_retired == 1,
        na.rm = TRUE
      ),
      .groups = "drop"
    ) |>
    mutate(
      fiscal_year = year,
      n_retained = teachers_before - exiters - retirements - movers_out - switchers, # nolint
      retention_rate = n_retained / teachers_before
    ) |>
    rename(districtlea = districtlea_before)
}

all_years <- c(PRE_PANDEMIC_YEARS, RECENT_YEARS)

district_retention_all <- map(
  all_years,
  ~ calculate_retention_rates(.x, teacher_lm)
) |>
  list_rbind()

# --- Aggregate into pre-pandemic vs. recent periods ---
# Require all 3 recent years and at least MIN_PREPANDEMIC_YEARS pre-pandemic years.
district_scatter <- district_retention_all |>
  mutate(
    period = case_when(
      fiscal_year %in% PRE_PANDEMIC_YEARS ~ "prepandemic",
      fiscal_year %in% RECENT_YEARS ~ "recent"
    )
  ) |>
  group_by(districtlea) |>
  filter(
    sum(fiscal_year %in% RECENT_YEARS) == length(RECENT_YEARS),
    sum(fiscal_year %in% PRE_PANDEMIC_YEARS) >= MIN_PREPANDEMIC_YEARS
  ) |>
  ungroup() |>
  group_by(districtlea, period) |>
  summarise(
    avg_retention = mean(retention_rate),
    n_teachers_avg = mean(teachers_before),
    .groups = "drop"
  ) |>
  pivot_wider(
    names_from  = period,
    values_from = c(avg_retention, n_teachers_avg)
  ) |>
  mutate(districtlea_num = as.numeric(districtlea))

# --- Tag shortage districts (2025-26 state designation) ---
shortage_2025 <- read_csv(
  "src/data/shortage-districts-2025-26.csv",
  col_types = cols(lea = col_character()),
  show_col_types = FALSE
) |>
  filter(shortage == 1) |>
  mutate(lea_num = as.numeric(lea))

district_scatter <- district_scatter |>
  mutate(
    shortage_status = if_else(
      districtlea_num %in% shortage_2025$lea_num,
      "Shortage",
      "Not Shortage"
    )
  )

# --- Load CCD crosswalk for county/locale metadata ---
cxwalk <- read_csv(
  "src/data/educationdata_arkansas_2023.csv",
  col_types = cols(leaid = col_character()),
  show_col_types = FALSE
) |>
  select(
    geoid             = leaid,
    district_lea      = state_leaid,
    urban_centric_locale,
    county_name
  ) |>
  mutate(
    district_lea = as.numeric(gsub("AR-", "", district_lea))
  )

# --- Load GeoJSON for correctly-cased district names ---
geojson_names <- sf::read_sf("src/data/ar-school-districts.geojson") |>
  sf::st_drop_geometry() |>
  select(geoid = GEOID, district_name = NAME)

# --- Join and write output ---
output <- district_scatter |>
  left_join(cxwalk, by = c("districtlea_num" = "district_lea")) |>
  inner_join(geojson_names, by = "geoid") |>
  mutate(
    retention_prepandemic_pct = round(avg_retention_prepandemic * 100, 1),
    retention_recent_pct      = round(avg_retention_recent * 100, 1),
    retention_change_pp       = round((avg_retention_recent - avg_retention_prepandemic) * 100, 1)
  ) |>
  select(
    districtlea,
    district_name,
    county_name,
    shortage_status,
    retention_prepandemic_pct,
    retention_recent_pct,
    retention_change_pp
  )

write.csv(output, stdout(), row.names = FALSE)
