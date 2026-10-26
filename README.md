# Climate Menu

Climate Menu is an R/Shiny workflow designed to help researchers translate
climate and health research questions into reproducible climate-data analyses.

## Current demonstration version

Version: 2026-10-27 demonstration build

The current build includes:

- Shiny research-question workflow
- Australian study-area selection
- ABS ASGS Edition 3 (2021) geography integration
- NARCliM2 climate-data configuration and remote acquisition framework
- historical and future climate-period configuration
- climate-model and emissions-scenario selection
- targets-based reproducible backend
- historical, future and change result workflow
- downloadable analysis outputs

The demonstration build is under active development. Not every possible
combination of geography, climate metric, model, scenario and analysis has
yet undergone end-to-end validation.

## Requirements

R must already be installed.

Climate Menu also requires a number of R packages. The launcher checks these
when it starts and reports any packages that are missing.

## Start Climate Menu

1. Extract the ZIP file.
2. Open R or RStudio.
3. Set the working directory to the extracted Climate_Menu_Demo_20261027
   directory.
4. Run:

   source("RUN_CLIMATE_MENU.R")

The Climate Menu interface should open in your web browser.

## Demonstration workflow

For the most reliable demonstration, begin with:

- a named Australian geography
- maximum temperature
- mean maximum temperature
- AUS-18
- bias-adjusted NARCliM data
- one historical and one future period
- SSP2-4.5
- an individual model configuration

This demonstrates the intended workflow from a climate-health research
question through study-area definition, climate-data selection and
reproducible analysis.

## Study areas

Named Australian geographies are obtained from official Australian Bureau
of Statistics geography services.

The current interface supports the study-area hierarchy used by Climate
Menu, including State/Territory, Greater Capital City Statistical Area,
SA4, SA3, SA2, SA1 and Local Government Area options. Some very large
selectors, particularly SA1, remain under interface development.

ABS geography selection does not change the underlying resolution of the
climate model.

## Important scientific principle

Climate Menu does not create finer-resolution climate information by
selecting a fine-resolution administrative boundary. Climate values retain
the spatial resolution and support of the selected climate dataset.

## Reproducibility

The analysis backend uses the targets R workflow. User selections are
translated into an analysis request and processed through the reproducible
backend.

Large NARCliM climate datasets are not bundled with this distribution.
Climate Menu is designed to discover and access the required climate data
remotely.

## Development status

This is a demonstration/research build rather than a final production
release. Validated functionality and functionality still undergoing
integration should be distinguished when interpreting or demonstrating
results.
