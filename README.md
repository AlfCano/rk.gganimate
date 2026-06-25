# rk.gganimate

![Version](https://img.shields.io/badge/Version-0.0.3-blue.svg)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
![RKWard](https://img.shields.io/badge/Platform-RKWard-green)
[![R Linter](https://github.com/AlfCano/rk.gganimate/actions/workflows/lintr.yml/badge.svg)](https://github.com/AlfCano/rk.gganimate/actions/workflows/lintr.yml)
![AI Gemini](https://img.shields.io/badge/AI-Gemini-4285F4?logo=googlegemini&logoColor=white)

**An RKWard GUI Plugin for Animated Storytelling and Gapminder-style Bubble Charts**

`rk.gganimate` provides a seamless, point-and-click graphical interface inside RKWard to transform complex survey designs into stunning, time-animated visualizations. Acting as a unified GUI wrapper for [`gganimate`](https://cran.r-project.org/package=gganimate), [`ggplot2`](https://cran.r-project.org/package=ggplot2), and [`srvyr`](https://cran.r-project.org/package=srvyr), this plugin allows users to extract weighted 3D data and animate it over time without writing a single line of code.

This package features an exclusive **Storytelling Highlight Mode**, allowing you to track specific data points (like tracking a specific State or Country) as they move through time, perfectly replicating the famous Hans Rosling presentations.

---

## 🌟 Key Features

* **Zero-Code Animations:** Build fluid, high-quality GIF animations directly from your datasets and export them to your local drive.
* **Storytelling Highlight Mode:** Type the exact name of a bubble (e.g., "Puebla", "Tlaxcala"), and the plugin will automatically generate a floating, semi-transparent label that tracks your target across the animation frames.
* **Smart Color Palettes:** Automatically expands qualitative palettes (like `Set1` or `Dark2`) using `colorRampPalette` if you group by variables with many categories (e.g., the 32 Mexican states), preventing grey/recycled colors.
* **Native Survey Support:** Includes a dedicated "Data Prep" tool that reads your `survey.design` objects, calculates exact weighted means and proportions, and generates the required population totals for the bubble sizes.
* **Multilingual:** Fully translated into English, Spanish, French, German, and Portuguese (Brazil).

---

## 🚀 What is new in Version 0.0.3?

This update focuses on fine-tuning the visual output, adding publication-ready details, and improving the user interface:

**✨ New Features & Improvements:**
* **Smart Legend Titles:** Added a field to customize the color legend title. If left blank, the plugin intelligently extracts the original variable label (`.rk.meta` or `variable.label`) directly from your data frame, keeping your charts looking professional automatically.
* **Caption Support:** Added a dedicated Caption field in the UI to easily include data sources, methodology notes, or credits at the bottom of your animation.
* **Dynamic Font Scaling:** Introduced a "Base Font Size" control. You can now easily scale up all text elements (titles, axes, legends) simultaneously—perfect for generating readable GIFs for PowerPoint presentations or social media.
* **UI Reorganization:** The interface has been streamlined. The overloaded "Labels & Theme" tab is now split into **"Labels"** (titles, axes, captions) and **"Theme & Tracking"** (palettes, font sizes, storytelling), providing a cleaner, step-by-step user workflow.
* **i18n Updates:** Translation files (`.po`/`.mo`) for Spanish, French, German, and Brazilian Portuguese have been updated to cover all the new UI elements.

## 🚀 What is new in Version 0.0.2?

* **Strict Rule #3 Compliance:** Fixed a scoping issue in the Data Prep module. The generated R code now correctly hardcodes the output object (`tabla_animacion`), preventing RKWard from duplicating objects or losing metadata upon saving.
* **Survey Design Parsing Fix:** Rewrote the JS `getCol()` helper with a robust regex to properly parse deeply nested `survey.design` variables. It now correctly identifies the actual column names (e.g., `ent`, `year`) instead of getting stuck on the internal `[["variables"]]` list structure.

---

## ⚙️ Prerequisites

You must have [RKWard](https://rkward.kde.org/) installed along with the following R packages:

```R
install.packages(c("ggplot2", "gganimate", "gifski", "transformr", "srvyr", "dplyr"))
```

---

## 🚀 Installation

You can install this plugin directly from GitHub using `devtools`:

```R
# Install the plugin
devtools::install_github("AlfCano/rk.gganimate")
```

Once installed, open RKWard, navigate to **Settings -> Configure RKWard -> Plugins**, and activate `rk.gganimate`.

---

## 🛠️ Usage Workflow

This plugin adds two new tools to your RKWard menus, located under the **Survey -> Graphs -> Animations** tab:

### 1. Data Prep for Animation
* **What it does:** Acts as a bridge between complex survey weights and animations. It condenses millions of survey records into a clean, 5-column data frame (Time, Group, Bubble Size, X, Y).
* **Inputs:** Provide your `survey.design` object, select a time variable (e.g., Year), a grouping variable (e.g., State), and the metrics you want to plot (continuous for the Y-axis, categorical proportions for the X-axis).

### 2. Animated Bubble Chart
* **What it does:** The main animation engine.
* **Inputs:** Select your summarized data frame, map your X and Y axes, choose the Time variable, and optionally map Bubble Size and Color.
* **Storytelling:** In the *Labels & Theme* tab, check "Highlight specific bubbles", type your target's name (or multiple names separated by commas), and tweak the animation duration/FPS in the *Render & Export* tab.

---

## 🧪 The Testing Workflow

To test the generated plugin and see the Storytelling tracking in action, paste this into the RKWard console to create a mock summarized dataset:

```r
# Create a Mock Summarized Dataset (Gapminder Style)
set.seed(123)
mock_anim_data <- expand.grid(Year = 2010:2020, State = c("Puebla", "Jalisco", "Nuevo Leon", "CDMX", "Oaxaca"))
mock_anim_data$Income <- runif(nrow(mock_anim_data), 10000, 30000) + (mock_anim_data$Year - 2010) * 1000
mock_anim_data$Poverty_Pct <- runif(nrow(mock_anim_data), 20, 60) - (mock_anim_data$Year - 2010) * 1.5
mock_anim_data$Population <- runif(nrow(mock_anim_data), 1e6, 5e6)
```

**Step-by-step Test:**

1.  **Open `Survey > Graphs > Animations > 2. Animated Bubble Chart`**
    *   *Data Frame:* Select `mock_anim_data`
    *   *X Axis:* Select `Poverty_Pct`
    *   *Y Axis:* Select `Income`
    *   *Time / Frame Variable:* Select `Year`
    *   *Bubble Size:* Select `Population`
    *   *Color / Group Category:* Select `State`
2.  **Go to the `Labels & Theme` Tab:**
    *   *Main Title:* Type `Poverty vs Income (2010-2020)`
    *   *Plot Theme:* Minimal
    *   *Storytelling:* Check the "Highlight specific bubbles" box.
    *   *Exact name(s) to track:* Type `Puebla, Nuevo Leon`
3.  **Go to the `Render & Export` Tab:**
    *   *Frames per second:* 10
    *   *Duration:* 8 seconds
    *   *Save GIF as:* Choose a folder on your computer (e.g., your Desktop) and name it `test_animation.gif`.
4.  **Click Submit!**
    *   *Note: Rendering a GIF takes a few seconds. Wait until RKWard says "Animation successfully saved".*

**Result:** Check your Desktop. You will have a fluid 8-second animation where all bubbles move, but only "Puebla" and "Nuevo Leon" have a bold, floating label tracking their exact movement across the screen!

---

## 🌍 Internationalization (i18n)

The graphical interface automatically adapts to your RKWard language settings. Currently supported languages:
* 🇺🇸 English (Default)
* 🇪🇸 Spanish (Español)
* 🇫🇷 French (Français)
* 🇩🇪 German (Deutsch)
* 🇧🇷 Portuguese (Português do Brasil)

---

## 📝 License and Author

**Author:** Alfonso Cano ([@AlfCano](https://github.com/AlfCano))
**Email:** alfonso.cano@correo.buap.mx
*   **Assisted by:** Gemini, a large language model from Google.
*   **License:** GPL (>= 3)

This project is licensed under the **GPL (>= 3)** License.
