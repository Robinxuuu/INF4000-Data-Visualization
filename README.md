# 📰 INF4000 Final Project – Sentiment Analysis & News Visualisation

This repository contains the final project for the INF4000 Data Visualization course at [Your University]. The goal of the project is to explore how sentiment varies across different news categories and to reflect on whether news media uses emotional expression to manipulate reader perceptions.

🔗 **Report title**: *How Does Sentiment Vary Across Different News Categories?*  
📊 **Tool**: R + ggplot2  
📁 **Deliverables**: Report (3000 words), R script, and 4 final visualizations

---

## 🧠 Project Motivation

News is not just a channel for delivering facts, but a medium that often reflects public emotions and shapes social attitudes. By applying **sentiment analysis** and data visualization to news headlines, this project investigates whether certain categories (e.g., politics, business, entertainment) systematically lean toward emotional language.

---

## 📈 Visualizations

The project uses a composite visualization made up of four key charts:

1. **Stacked Bar Chart** – Yearly Frequency of News by Category  
2. **Treemap** – Sentiment Composition by News Category  
3. **Boxplot** – Sentiment Variability Across Categories  
4. **Heatmap** – Sentiment Trends Over Time and Category

Each chart is designed following the **ASSERT framework** and analyzed using **the grammar of graphics** principles.

---

## 📁 Files

| File | Description |
|------|-------------|
| `4000 R [v6].R` | Clean R script used to preprocess data and create all visualizations |
| `INF4000 Data Visualization Final Report.docx` | Final report with full theoretical analysis and visual critique |
| `outputs/` (optional) | Exported .png or .pdf charts (can be added if needed) |

---

## 📚 Key Methods & Frameworks

- **Sentiment Analysis** of news headlines using text mining
- Visual critique using:
  - ASSERT framework (Ask, Structure, State, Envision, Refine, Tell)
  - Grammar of Graphics (e.g., aesthetic mappings, geoms, facets, etc.)
- Accessibility and design reflection (e.g., color choices, layout)

---

## 📌 Sample Insights

- Political news headlines tend to show higher sentiment variability  
- Entertainment news often has more positive sentiment overall  
- Some categories display emotional peaks around specific years or events

---

## 🔧 Requirements

To rerun the code, you’ll need:

```r
# In R
install.packages("tidyverse")
install.packages("lubridate")
install.packages("ggplot2")
# ... any others used in your script
