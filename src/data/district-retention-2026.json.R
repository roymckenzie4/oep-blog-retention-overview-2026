# district-retention-2026.json.R
# Observable Framework data loader
#
# Outputs per-district 2025-26 teacher retention breakdown for the
# district map + card interactive tool.
#
# Output columns:
#   districtlea          - ADE LEA code
#   geoid                - NCES GEOID for joining with geojson
#   district_name        - District name
#   county_name          - County name
#   teachers_before      - Teacher headcount in 2024-25
#   teachers_current     - Teacher headcount in 2025-26 (incl. new entrants)
#   stayers              - Stayed in same district (incl. within-district movers)
#   movers_new_district  - Moved to a different district
#   switchers            - Moved to non-teaching role
#   exiters              - Exited workforce (non-retirement)
#   retirees             - Retired
#   retention_rate       - stayers / teachers_before (proportion 0-1)

library(data.table)
library(dplyr)
library(janitor)
library(readr)
library(sf)
library(jsonlite)

# --- Configuration ---
data_path <- Sys.getenv(
  "TEACHER_LM_DATA",
  unset = "/Users/roymckenzie/Library/CloudStorage/Box-Box/0 - Arkansas Projects/Projects/Teacher Pipeline/Teacher Retention/0_data/Classroom and Inclusion SPED Teachers/teacher_workforce_transitions_Classroom and Inclusion SPED Teachers_04-20-26.csv" # nolint
)

# --- Load and prep data ---
teacher_lm <- fread(
  data_path,
  colClasses = "character",
  na.strings = c("", "NA")
) |>
  janitor::clean_names() |>
  mutate(fiscal_year = as.integer(fiscal_year))

# --- Compute 2025-26 per-district retention breakdown ---
# teachers_before = those who were teaching in 2024-25 in each district
# stayers         = stayed in the same district (same school OR different school
#                   within same district — both count as "retained" at district level)
# movers_new_district = moved to a different district
year <- 2026

teachers_year_before <- teacher_lm |>
  filter(teacher == TRUE, fiscal_year == year - 1) |>
  select(research_id, districtlea_before = districtlea)

teachers_year <- teacher_lm |>
  filter(fiscal_year == year) |>
  left_join(teachers_year_before, by = "research_id")

district_2026 <- teachers_year |>
  filter(lf_outcome != "New") |>
  group_by(districtlea_before) |>
  summarise(
    teachers_before = n(),
    stayers = sum(
      lf_outcome == "Stayer" |
        (lf_outcome == "Mover" & lf_mover_same_district == 1),
      na.rm = TRUE
    ),
    movers_new_district = sum(
      lf_outcome == "Mover" & lf_mover_new_district == 1,
      na.rm = TRUE
    ),
    switchers = sum(lf_outcome == "Switcher", na.rm = TRUE),
    exiters = sum(
      lf_outcome == "Exiter" & lf_exiter_not_retired == 1,
      na.rm = TRUE
    ),
    retirees = sum(
      lf_outcome == "Exiter" & lf_exiter_retired == 1,
      na.rm = TRUE
    ),
    .groups = "drop"
  ) |>
  rename(districtlea = districtlea_before) |>
  mutate(retention_rate = stayers / teachers_before)

# --- 2025-26 headcount (includes new entrants and movers-in from other districts) ---
teachers_2026 <- teacher_lm |>
  filter(teacher == TRUE, fiscal_year == 2026) |>
  group_by(districtlea) |>
  summarise(teachers_current = n(), .groups = "drop")

district_2026 <- district_2026 |>
  left_join(teachers_2026, by = "districtlea")

# --- Load CCD crosswalk for county names only ---
cxwalk <- read_csv(
  "src/data/educationdata_arkansas_2023.csv",
  col_types = cols(leaid = col_character()),
  show_col_types = FALSE
) |>
  select(
    geoid        = leaid,
    district_lea = state_leaid,
    county_name
  ) |>
  mutate(district_lea = as.numeric(gsub("AR-", "", district_lea)))

# --- Load GeoJSON for correctly-cased district names and GEOID filter ---
geojson_names <- sf::read_sf("src/data/ar-school-districts.geojson") |>
  sf::st_drop_geometry() |>
  select(geoid = GEOID, district_name = NAME)

# --- Join and write output ---
output <- district_2026 |>
  mutate(districtlea_num = as.numeric(districtlea)) |>
  left_join(cxwalk, by = c("districtlea_num" = "district_lea")) |>
  inner_join(geojson_names, by = "geoid") |>
  filter(!is.na(retention_rate)) |>
  select(
    districtlea,
    geoid,
    district_name,
    county_name,
    teachers_before,
    teachers_current,
    stayers,
    movers_new_district,
    switchers,
    exiters,
    retirees,
    retention_rate
  )

cat(jsonlite::toJSON(output, dataframe = "rows", na = "null"))
