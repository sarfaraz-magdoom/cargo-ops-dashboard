# ✈️ Cargo Operations Command Centre — Power BI Executive Dashboard

An end‑to‑end **data‑engineering + analytics** project: a SQL → Python → Parquet → Power BI pipeline feeding a 4‑page executive dashboard that turns ~5.7M air‑cargo movements into decision‑ready KPIs, trends and insights.

> **Stack:** SQL Server · Python (polars / pyarrow) · Parquet · Power BI (star‑schema model, 71 DAX measures, PBIR enhanced report format)

---

## 📸 Dashboard

| Executive Overview | Volume, Yield & Revenue |
|---|---|
| ![Overview](docs/screenshots/01-overview.png) | ![Revenue](docs/screenshots/02-revenue.png) |
| **On‑Time & Delay Performance** | **Cargo iQ Quality & Hub Dwell** |
| ![OTP](docs/screenshots/03-otp.png) | ![CargoIQ](docs/screenshots/04-cargoiq.png) |

🔗 **Live report:** _(https://app.powerbi.com/view?r=eyJrIjoiMDQ4ZDFmNjItNTliNC00ZDAxLWEyYzItMzdmN2MwNTI1ZGFjIiwidCI6ImMzMmM5MzI0LTY0NWMtNDNiOC1hOGVkLTUyNThkZTAwY2VhMCJ9)_

---

## 🎯 What it answers

A cargo/airline operations leader needs one place to see **how much moved, how much it earned, how reliably it ran, and how cleanly it flowed through hubs.** This dashboard covers all four:

1. **Executive Overview** – headline KPIs (cargo tonnes, revenue, OTP, load factor, yield, dwell), monthly revenue + tonnage trend, load‑factor mix, top carriers.
2. **Volume, Yield & Revenue** – revenue/yield KPIs, monthly revenue + yield, revenue by yield tier, top routes & carriers.
3. **On‑Time & Delay Performance** – OTP trend + 3‑month moving average, delay causes, severity bands, weekday reliability.
4. **Cargo iQ Quality & Hub Dwell** – FAP/DAP milestone adherence, dwell by hub, slippage mix, dwell bands.

Each page ends with a data‑driven **Key Insights** bar.

---

## 🏗️ Architecture

![Data architecture: SQL Server → Python ETL → Parquet → Power BI](docs/architecture.svg)

---

## 🧱 Data model (star schema)

| Table | Role | Notes |
|---|---|---|
| `fact_flights` | Fact | ~5.7M rows — on‑time / delay performance, delay cause & severity bands |
| `fact_tonnage` | Fact | ~418K rows — freight/mail tonnes, FTK/AFTK, revenue, load‑factor & yield tiers |
| `fact_cargo_iq` | Fact | Cargo iQ milestones — dwell, slippage, FAP/DAP across 8 hubs |
| `Calendar` | Dim | Marked date table; `Month`/`Quarter`/`Day Name` have sort‑by columns |
| `dim_carrier` | Dim | Carrier lookup |
| `dim_route` | Dim | Route (origin → dest) |
| `airports` | Dim | IATA, city, country, lat/long |
| `DimAirlines` | Dim | Airline names |

**71 measures** organised into display folders: Volume & Tonnage · On‑Time Performance · Load Factor & Capacity · Yield & Revenue · Hub Dwell & Milestones · Time Intelligence · Rankings · Delay Diagnostics · Utilization Mix · Cargo iQ Quality.

---

## 🔎 Selected insights (FY2015)

- **$11.8bn** revenue on **14.3M** cargo tonnes at **82%** on‑time — but **load factor is only 15%**: 93% of segments fly under half‑full (the biggest capacity opportunity).
- **Concentration:** FedEx (FX) moves **43%** of all freight and leads revenue (~$4bn).
- **Yield mix is the profit lever:** premium‑yield lanes drive **54%** of revenue on minority volume.
- **Delay drivers:** Late Aircraft, Carrier and NAS; only **29%** of delayed departures recover in the air; OTP peaks ~88% in October.
- **Hub bottlenecks:** average dwell ~93h, with **Amsterdam (~182h)** and London the worst vs Hong Kong (~40h).
---

## 📁 Repository structure

```
cargo-ops-dashboard/
├─ Cargo Operations Dashboard.pbip          # Power BI project entry point
├─ Cargo Operations Dashboard.SemanticModel/ # TMDL model: tables, relationships, 71 DAX measures
├─ Cargo Operations Dashboard.Report/        # PBIR report: 4 pages of visuals (JSON)
├─ etl_cargo_ops.ipynb                        # main ETL notebook
├─ export_parquet.py                          # write columnar Parquet fact tables
├─ all_views.sql                              # SQL Server dimension views
└─ docs/screenshots/                          # dashboard images for this README
```

---

## 📌 Data provenance

Built on the public **2015 U.S. flight‑performance dataset** (flights, airlines, airports), reframed as an air‑cargo operation and **augmented with synthesized** cargo tonnage, revenue/yield and Cargo iQ milestone data for portfolio/demonstration purposes. No proprietary or personal data is used.

---

## 👤 Author

**Magdoom Sarfaraz** — Data / Analytics Engineering
🔗 GitHub: [github.com/sarfaraz-magdoom](https://github.com/sarfaraz-magdoom)
_(https://www.linkedin.com/in/sarfaraz20/)_


# Cargo Operations Performance Dashboard

Three public aviation datasets, a galaxy schema in SQL Server, and a Power BI
model that tries to answer the questions a cargo ops team actually asks rather
than the ones that are easy to chart.

**Stack:** Python (Polars) · SQL Server · Parquet · Power BI
**Data:** US DOT On-Time Performance (5.7M rows) · BTS T-100 Segment · synthetic Cargo iQ milestones

---

## What this is

Air cargo performance splits into two conversations that are usually held in
different rooms. Operations cares about whether freight moved when it was
supposed to. Commercial cares about how much moved and what it was worth. Most
public dashboards pick one.

This one models both, joined through conformed carrier and route dimensions, so
you can ask "our OTP on this lane is fine, so why is the load factor terrible"
without exporting to Excel first.

## The data

| Source | Grain | What it gives you |
|---|---|---|
| DOT On-Time Performance | one row per flight | OTP, delay causes, route punctuality |
| BTS T-100 Segment | carrier/route/month | freight tonnage, capacity, departures |
| Cargo iQ milestones | one row per shipment | RCS/DEP/RCF/DLV timings, FAP and DAP |

The Cargo iQ data is synthetic. The real thing is IATA member-proprietary and
not downloadable, so I generated it against the structure documented at
cargoiq.org — the `i1/i2/i3/o` segment layout with planned/effective pairs.
It's modelled, not real, and the README says so because pretending otherwise
would be the kind of thing that falls apart in the first interview question.

## Things worth knowing about the model

**Load factor is distance-weighted, not per-flight.** The first version
calculated a `load_factor_pct` column per row and averaged it. That's wrong —
it treats a 400km hop and a transatlantic sector as equal. The column was
dropped entirely in favour of `RFTK / AFTK` computed as measures, which is what
the industry actually uses. Deleting a column you already built is annoying but
this one deserved it.

**The facts are Parquet, not SQL views.** Original build imported the eight
`vw_*` summary views into Power BI. Everything looked fine until time
intelligence started erroring, because pre-aggregated views have no date grain
to work with. The fix was exporting the underlying fact tables to
Hive-partitioned Parquet (~250MB) and rebuilding relationships against a proper
Calendar table. If you're reading this because your own DAX time intelligence
is broken, that's probably why.

**Cargo iQ has no calendar date.** The milestone data is relative timings only,
so `fact_cargo_iq` doesn't join to Calendar. Any measure crossing that fact and
a date filter will silently give you nonsense. This is a modelling constraint
inherited from the source, not something to fix.

## Known issue

About 30% of `fact_cargo_iq` rows have negative dwell times. Traced to the
milestone timestamp subtraction in the Polars generator — the segment ordering
assumption doesn't hold for multi-leg shipments. The dwell-time visuals filter
these out rather than showing wrong numbers, but the underlying generator still
needs fixing. Leaving it visible here rather than quietly dropping the rows.

## Repo layout

```
cargo-ops-dashboard/
│
├── data/
│   ├── raw/                    # source downloads, gitignored
│   │   ├── flights.csv         # DOT On-Time Performance
│   │   └── t100_segment.csv    # BTS T-100
│   └── parquet/                # Hive-partitioned facts, gitignored
│       ├── fact_flights/
│       ├── fact_tonnage/
│       └── fact_cargo_iq/
│
├── scripts/
│   ├── cargo_ops_loader.py     # three sources -> SQL Server
│   ├── generate_cargo_iq.py    # synthetic milestone generator
│   └── export_parquet.py       # SQL facts -> partitioned Parquet
│
├── sql/
│   ├── 01_schema.sql           # galaxy schema, 3 facts + 3 conformed dims
│   ├── 02_dimensions.sql       # dim_carrier, dim_route, dim_date
│   └── 03_views.sql            # 8 analytics views
│
├── powerbi/
│   ├── CargoOps.pbix
│   └── measures.md             # DAX reference, grouped by display folder
│
├── docs/
│   ├── schema.png              # galaxy schema diagram
│   └── kpi_definitions.md      # FTK, RFTK, AFTK, FAP, DAP, dwell
│
├── screenshots/                # dashboard pages, referenced above
│
├── requirements.txt
└── README.md
```

`data/` is gitignored end to end — the raw downloads are several GB and the
Parquet exports are derived. Both regenerate from the scripts.

## Running it

```bash
pip install -r requirements.txt

python scripts/generate_cargo_iq.py     # synthetic milestone data
python scripts/cargo_ops_loader.py      # load all three into SQL Server
python scripts/export_parquet.py        # export facts for Power BI
```

Loader writes with `if_exists="replace"` so re-running is safe. Chunk size is
50,000 with `fast_executemany=True` — smaller chunks were roughly four times
slower on the 5.7M row flights table.

Point Power BI at the Parquet folders, not the SQL views. See above.

## What I'd do differently

Fix the dwell-time generator before building anything on top of it. I built the
Power BI layer first and then found the bug, which meant reworking visuals that
were already finished. Validate the fact tables, then model.
