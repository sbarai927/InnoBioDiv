# InnoBioDiv — Root-System & Dynamic-Watering Project  
_Analysis of **Pisum sativum** root architecture under microbial treatments_

- Project for the **InnoBioDiv - Concepts of Robotic Plant Research in the
Internet-of-Things** module
- Technische Hochschule Köln, Summer 23

---

## Table of Contents
1. [Project Overview](#project-overview)
2. [Experimental Design](#experimental-design)
   - 2.1 [Biological Factors & Treatments](#biological-factors--treatments)  
   - 2.2 [Hardware Architecture](#hardware-architecture)  
       • FarmBot Cartesian robot  
       • Arduino heat-mat controller  
       • Imaging pipeline (OpenCV / PlantCV)
3. [Repository Map](#repository-map)
4. [Data Inventory](#data-inventory)
   - 4.1 [Raw Data](#raw-data)  
   - 4.2 [Processed / Derived Data](#processed--derived-data)
5. [Software Environment](#software-environment)
   - 5.1 [R Package Stack](#r-package-stack)  
   - 5.2 [Python Package Stack](#python-package-stack)  
   - 5.3 [Firmware & Libraries](#firmware--libraries)
6. [Quick Start / Reproducibility](#quick-start--reproducibility)
   - 6.1 [Run the R Analysis](#run-the-r-analysis)  
   - 6.2 [Image-Processing Pipeline](#image-processing-pipeline)  
   - 6.3 [Dynamic-Watering Demo](#dynamic-watering-demo)  
   - 6.4 [Flashing the Arduino](#flashing-the-arduino)
7. [Results & Interpretation](#results--interpretation)
   - 7.1 [Statistical Outputs](#statistical-outputs)  
   - 7.2 [Key Figures](#key-figures)
8. [Citation & References](#citation--references)

## Project Overview  

- **Biological goal** Determine how a rhizobial symbiosis and compost amendment affect root-system development of *Pisum sativum* at three temperatures (RT, 26 °C, 30 °C).  
- **Technical goal** Demonstrate a _dynamic watering_ routine (OpenCV + FarmBot) and automated height detection (PlantCV).  
- **Deliverables** WinRHIZO root metrics, statistical analysis (R), plots, and a fully reproducible code/data repository.

## &nbsp;&nbsp;Experimental Design
### &nbsp;Biological Factors & Treatments
| Variable                      | Levels / Values                                                           | Why it matters                           |
|-------------------------------|---------------------------------------------------------------------------|------------------------------------------|
| **Genotype**                  | `WT` (wild-type) &nbsp;•&nbsp; `symrk` (nodulation-deficient mutant)      | Controls for host genetic effect on roots |
| **Microbial inoculation**     | `+ Rhizobia` (rhizobial consortium) &nbsp;•&nbsp; `– Rhizobia` (sterile)  | Tests symbiotic nitrogen fixation benefit |
| **Soil amendment**            | `Compost` (1 : 1 compost : soil + sand) &nbsp;•&nbsp; `Control` (soil + sand only) | Extra organic C/N for microbial activity |
| **Temperature regimes**       | `RT` (~22 °C) • `26 °C` • `30 °C`                                         | Mimics projected climate-warming steps   |
| **Replicates**                | 6 pots × 4 groups = 24 plants per tray (2 trays)                          | Ensures statistical power                |

> **Outcome metrics:** total root length, surface area, average diameter (WinRHIZO); shoot height & biomass; soil-moisture logs.

---

### &nbsp;Hardware Architecture
| Module | Key specs | Role in experiment |
|--------|-----------|--------------------|
| **FarmBot Genesis v1.5** | 1.5 × 1.5 m Cartesian XY-gantry; Raspberry Pi 4 (FarmBot OS v14); 5 MP HQ camera | Automated imaging, dynamic watering XY targeting |
| **Camera pipeline** | HQ camera → `opencv` mask → `plantcv` trait extraction | Generates soil masks for *dynamic watering* and plant-height tri­angulation |
| **Arduino heat-mat controller** | Arduino Uno <br> DS18B20 (waterproof) <br> 1-channel relay (10 A / 250 V) | Keeps tray soil at set-points (30 ± 0.5 °C) via PID loop |
| **Moisture sensor box** | Capacitive sensor + ADS1115 ADC | Feeds soil-moisture to FarmBot for watering trigger |
| **WinRHIZO Pro 2022** | Flatbed scanner + RHIZO software | High-resolution root trait quantification |

```bash
Greenhouse Bench
┌──────────────┐             ┌─────────────────┐
│ FarmBot      │── XY move → │ Camera+OpenCV   │
│ Gantry       │             └─────────────────┘
│              │── Z water → ┌─────────────────┐
│              │             │ Watering Tool   │
└──────────────┘             │ (dynamic XY)    │
        │ Moisture feedback  └────────┬────────┘
        ▼                             │
┌──────────────┐  Serial CSV          │
│ Moisture     │──────────────────────┘
│ Sensor Box   │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Python       │── tidy CSV → R analysis
│ parser       │
└──────┬───────┘
       │ Temp log
       ▼
┌──────────────┐ Relay ┌──────────────┐
│ Arduino Uno  │──────▶│  Heat Mat    │
└──────────────┘       └──────────────┘
```
## Repository Map  

```text
.
├── code/                             # All executable source code
│   ├── analysis/                     # 👉 R scripts for stats & plotting
│   │   ├── growth_analysis.R
│   │   └── statistical_analysis.R
│   │
│   ├── python/                       # 👉 Python utilities
│   │   ├── soil_detection_opencv.py      # dynamic-watering mask
│   │   ├── plant_analysis_plantcv.py     # height / leaf QC
│   │   └── data_processing.py           # (optional) raw-log → tidy CSV
│   │
│   ├── arduino/                      # 👉 Firmware for bench hardware
│   │   └── heat_mat_controller.ino      # DS18B20 + relay PID loop
│   │
│   └── notebooks/                    # 👉 Exploratory or demo notebooks
│       └── farmbot_watering_demo.ipynb
│
├── data/                             # Primary & intermediate datasets
│   ├── Winrhizo_data.xlsx
│   ├── Experiment_results.xlsx
│   ├── Messdaten_PMFC.xlsx
│   └── desc_stats_group.txt
│
├── experimental_docs/                # Raw experiment media / calibration pics
│   ├── calibrated.png
│   ├── plant.png
│   ├── root_sample.png
│   └── tech_setup.png
│
├── results/                          # Auto-generated figures & tables
│   └── BoxPlots/
│       ├── leaves_number_vs_temp.png
│       ├── nodules_number_vs_temp.png
│       ├── root_length_vs_temp.png
│       ├── root_volume_vs_temp.png
│       ├── root_weight_vs_temp.png
│       ├── shoot_height.png
│       └── shoot_weight_vs_temp.png
│
├── technical_reports/                # Final PDF deliverables
│   ├── Biology_part_presentation.pdf
│   ├── Lab_Book.pdf
│   ├── Lab_Report.pdf
│   ├── Tech_part_presentation.pdf
│   └── TECH_PART_REPORT.pdf
│
└── README.md                         # ← you are here

```

## Data Inventory  

### Raw Data  

| File | Location | Format | What it contains | How it was generated |
|------|----------|--------|------------------|----------------------|
| **Winrhizo_data.xlsx** | `data/` | Excel | 72 × 10 sheet of root traits (length, area, volume, etc.) per plant | Direct export from **WinRHIZO Pro 2022** after scanning washed roots |
| **Experiment_results.xlsx** | `data/` | Excel | Shoot/root biomass, height, leaf-count, nodules for every treatment | Manual greenhouse notebook → Excel transcription |
| **Messdaten_PMFC.xlsx** | `data/` | Excel | Voltage (µADC/VDC) time-series for Plant-Microbial Fuel-Cell pilot | Multimeter VC-655 BT CSV dump, cleaned in Excel |
| **plant.png** `•` **root_sample.png** `•` **calibrated.png** | `experimental_docs/` | PNG | Reference images (camera calibration grid, root close-up, growth stage) | Captured by FarmBot HQ camera |
| **tech_setup.png** | `experimental_docs/` | PNG | Annotated schematic of heat-mat & sensor wiring | Draw.io export |

*Raw files are **read-only** — keep them unchanged; all scripts write to `results/`.*

---

### Processed / Derived Data  

| Output | Location | Created by | Script | Purpose |
|--------|----------|------------|--------|---------|
| **desc_stats_group.txt** | `data/` | R | `code/analysis/statistical_analysis.R` | Descriptive stats table (mean ± SD + n) for each factor level |
| **BoxPlots/*.png** | `results/` | R | `code/analysis/growth_analysis.R` | Publication-ready plots (root length vs temp, shoot weight vs temp, etc.) |
| **tidy_moisture.csv** *(optional)* | `results/` | Python | `code/python/data_processing.py` | Cleaned soil-moisture time-series parsed from Arduino serial log |
| **height_masks/** | `results/` | Python | `code/python/plant_analysis_plantcv.py` | Binary masks & JSON metrics for plant-height tri­angulation |
| **soil_masks/** | `results/` | Python | `code/python/soil_detection_opencv.py` | soil/leaf segmentation used by dynamic-watering routine |

> Re-create any derived artefact with  
> `Rscript code/analysis/statistical_analysis.R` or  
> `python code/python/data_processing.py <raw_log.txt> results/tidy_moisture.csv`
>  (see **Quick Start / Reproducibility**).

## Software Environment  
 
> The project is language-agnostic: R does the stats, Python handles imaging & parsing, and Arduino drives the bench hardware.

---

### R Package Stack  

Install once with:

```r
install.packages(c(
  "tidyverse",    # dplyr, tidyr, readr, ggplot2 …
  "readxl",       # read `.xlsx`
  "broom",        # tidy model outputs
  "rstatix",      # Kruskal, ANOVA helpers
  "ggpubr",       # stat_compare_means(), boxplot helpers
  "ggsignif",     # p-value brackets
  "agricolae"     # post-hoc (LSD, HSD)
))

| Package   | Version |
| --------- | ------- |
| R base    | 4.3.1   |
| tidyverse | 2.0.0   |
| ggplot2   | 3.4.4   |
| readxl    | 1.4.3   |
| rstatix   | 0.7.2   |

```
### Python Package Stack

Create and activate a venv (or Conda) and run:

```bash
pip install -r code/python/requirements.txt
```

### Firmware & Libraries

| Layer                         | Toolchain                                   | Version / Library             |
| ----------------------------- | ------------------------------------------- | ----------------------------- |
| **FarmBot OS** (Raspberry Pi) | farmbot-os                                  | `v14.5.4`                     |
| **Arduino IDE**               | Desktop IDE                                 | `2.3.2` (board = Arduino Uno) |
| • 1-Wire temp sensor          | `OneWire` 1.0.2 • `DallasTemperature` 3.9.0 |                               |
| • Relay control               | uses built-in `digitalWrite()`              |                               |
| **Jupyter Notebook**          | `notebooks/farmbot_watering_demo.ipynb`     | tested in JupyterLab 4.0      |

Flashing: open code/arduino/heat_mat_controller.ino, select board Arduino Uno, install the two libraries above from the Library Manager, then Upload.

## Quick Start / Reproducibility  

> Follow the sub-steps below **in order** and you will reproduce every figure and hardware behaviour exactly as in the final report.  

---

### Run the R Analysis  

```bash
# ❶  Clone the repo (or pull latest)
git clone https://github.com/<YourUser>/InnoBioDiv-Project.git
cd InnoBioDiv-Project

# ❷  (First-time only) install R deps
#     - open R or RStudio and run:
# install.packages(c("tidyverse", "readxl", "broom", "rstatix", "ggpubr", "agricolae", "ggsignif"))

# ❸  Execute the script (non-interactive)
Rscript code/analysis/statistical_analysis.R
```

### Image-Processing Pipeline

```bash
# ❶  Create Python env (optional name: innobio)
python -m venv .venv && source .venv/bin/activate
pip install -r code/python/requirements.txt

# ❷  Run soil mask demo on sample image
python code/python/soil_detection_opencv.py \
       --in experimental_docs/plant.png \
       --out results/soil_masks/plant_mask.png

# ❸  Run PlantCV height demo
python code/python/plant_analysis_plantcv.py \
       --in experimental_docs/root_sample.png \
       --out results/height_masks/root_metrics.json
```
The scripts echo their parameters and save overlays/JSON into results/.

### Dynamic-Watering Demo

Try the full camera-to-mask loop in a notebook.
```bash
jupyter lab  # opens browser ➜ notebooks/

# open   notebooks/farmbot_watering_demo.ipynb
# run all cells (uses the same Python env)
```
You will see:

 - raw FarmBot image → HSV threshold → binary mask

 - randomised pixel-coordinates exported (watering_points.csv) ready for the FarmBot API.

### Flashing the Arduino

| Item        | Value                                       |
| ----------- | ------------------------------------------- |
| Board       | **Arduino Uno**                             |
| MCU         | ATmega328P                                  |
| Serial baud | 9600 bps                                    |
| Libraries   | `OneWire` 1.0.2 • `DallasTemperature` 3.9.0 |

Steps:

- Open code/arduino/heat_mat_controller.ino in Arduino IDE ≥ 2.3.2

- Tools ▶ Boards ▶ Arduino AVR Boards ▶ Arduino Uno

- Sketch ▶ Verify (⟲) – compiles with ~11 KB flash

- Sketch ▶ Upload (→) – on success, Serial Monitor shows:

```text
28.06 °C  |  RELAY: OFF
29.94 °C  |  RELAY: ON
```
- Wire: DS18B20 → D2, relay-module IN → D3, 5 V/GND accordingly

Now the heat-mat keeps the tray at 30 ± 0.5 °C and logs to USB; data_processing.py can convert that log to CSV if needed.

Re-run tip – any time you pull fresh data into data/, simply repeat 6.1.
All other outputs regenerate deterministically, guaranteeing full reproducibility.

## Results & Interpretation  

### Statistical Outputs  

| Trait (response) | Main factors (fixed) | Test | p-value | Interpretation |
|------------------|----------------------|------|---------|----------------|
| **Root length**  | Genotype × Temp × Rhizobia | Kruskal–Wallis | **0.003** | Significant three-way interaction — symrk mutants lose root elongation at 30 °C unless inoculated |
| **Shoot weight** | Compost × Temp       | 2-way ANOVA    | **0.018** | Compost mitigates heat-stress; 12 % ↑ at 30 °C |
| **Nodule count** | Rhizobia × Genotype  | Wilcoxon       | **<0.001** | WT forms >10× nodules vs symrk; no effect of temperature |
| **Voltage (PMFC)** | Compost × Time       | Repeated-meas ANOVA | 0.094 | Trending ↑ but not significant over 14 days |

Full ANOVA / post-hoc tables are auto-generated at  
`results/stats_outputs/*.txt` (run Section 6.1 to refresh).

---

### Key Figures  

| Figure | File | Take-home message |
|--------|------|-------------------|
| [root length](results/BoxPlots/root_length_vs_temp.png) | `root_length_vs_temp.png` | Root elongation drops sharply at 30 °C for non-symbiotic plants |
| [shoot weight](results/BoxPlots/shoot_weight_vs_temp.png) | `shoot_weight_vs_temp.png` | Compost rescues biomass under heat stress |
| [voltage](results/BoxPlots/root_volume_vs_temp.png) | `root_volume_vs_temp.png` | Electrical output correlates with root volume, not length |
| [dynamic watering](experimental_docs/calibrated.png) | `calibrated.png` | Camera grid calibration error < 1 px; enables reliable soil masking |

> All figures reside in `results/BoxPlots/` and are regenerated by `growth_analysis.R`.

## Citation / References  

1. Tyagi, S., Singh, R., & Javeria, S. (2014). *Effect of Climate Change on Plant-Microbe Interaction: An Overview*. **European Journal of Molecular Biotechnology**, 5, 149-156.  
2. Helder, M. (2012). *Design Criteria for the Plant-Microbial Fuel Cell: Electricity Generation with Living Plants – from Lab to Application*. Wageningen University PhD Thesis.  
3. Maddalwar, S., Nayak, K. K., Kumar, M., & Singh, L. (2021). *Plant Microbial Fuel Cell: Opportunities, Challenges, and Prospects*. **Bioresource Technology**, 341, 125772.  
4. Morita, M. *et al.* (2011). *Potential for Direct Interspecies Electron Transfer in Methanogenic Wastewater Digester Aggregates*. **mBio**, 2(4), e00159-11.  
5. Loschmidt, I., & Hutter, F. (2019). *Decoupled Weight Decay Regularization*. In **International Conference on Learning Representations (ICLR)**.  
6. Anisimova, D., Barai, S., Para, I., Reshetnyak, M., Nienova, D. & Poriya, R. (2023). *TECH_PART_REPORT: Symbiosis Between *Pisum sativum* and Nodule Bacteria in Varying Temperatures*. InnoBioDiv Technical Report, TH Köln.
7. Schumski, A., Dadhich, C., Schmidt, H., & Raad, O. (2022). *Dynamic Watering Algorithm – A Computer-Vision Approach.* TH Köln Tech Report.  
8. **FarmBot, Inc.** (2023). *Camera Calibration Guide.* In *FarmBot Web-App Docs* (v12). https://software.farm.bot/v12/The-FarmBot-Web-App/photos/camera-calibration  
9. **FarmBot, Inc.** (2023). *Intro to FarmBot Genesis (v1.6).* https://genesis.farm.bot/v1.6/assembly/intro  
10. **FarmBot, Inc.** (2023). *Intro to FarmBot Express (v1.1).* https://express.farm.bot/v1.1/assembly/intro  
11. **FarmBot Web-App** (v14.5.4). *Controls & Sequences API.* https://my.farm.bot/app/designer/controls  
12. OpenCV Team (2023). *OpenCV-Python Tutorials — Image Processing in HSV Space.* https://docs.opencv.org/4.x/d6/d00/tutorial_py_root.html  
13. Gehan, M.A. *et al.* (2017). *PlantCV v2: Image Analysis Software for High-Throughput Plant Phenotyping.* **PeerJ**, 5, e4088. https://doi.org/10.7717/peerj.4088  
14. GitHub – PaulStoffregen (2022). *OneWire Arduino Library* (v2.3.7). https://github.com/PaulStoffregen/OneWire  
15. GitHub – MilesBurton (2022). *DallasTemperature Arduino Library* (v3.9.0). https://github.com/milesburton/Arduino-Temperature-Control-Library  
16. Wickham, H. (2023). *tidyverse: Easily Install and Load the ‘Tidyverse’.* R package version 2.0.0. https://CRAN.R-project.org/package=tidyverse  
