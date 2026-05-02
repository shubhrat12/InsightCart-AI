# E-Commerce Analytics System with LLM-Augmented Intelligence

## Overview

A comprehensive e-commerce analytics platform built with **PostgreSQL**, **Python**, and **LLM-powered intelligence**, based on the **Brazilian E-Commerce Public Dataset**. The system enables scalable storage, efficient querying, and insightful reporting of customer, order, payment, and seller data — now fully deployed to the cloud with an interactive real-time dashboard.

🔗 **Live App**: [https://dashboardpy-kd6kgsdnkpzg5s7wjd3uaf.streamlit.app/](https://dashboardpy-kd6kgsdnkpzg5s7wjd3uaf.streamlit.app/)

---

## Dataset

This project uses the **Brazilian E-Commerce Public Dataset** extended with custom data files for richer analytics.

- Customer profiles and purchase history
- Order items, product details, and categories
- Sellers and geolocation data
- Payment methods and transaction values
- Customer interactions, feedback scores, and web/social traffic

**Dataset Download**:
[https://www.mediafire.com/file/j3yn49hxmsvklpk/Data.zip/file](https://www.mediafire.com/file/j3yn49hxmsvklpk/Data.zip/file)

---

## Phase 1: PostgreSQL-Based Analytics System ✅

### Technologies Used
- PostgreSQL
- SQL (DDL, DML, analytical queries)
- PL/pgSQL (stored procedures, triggers)
- Indexing and query optimization

### Core Features
- Structured schema with 11+ interconnected tables
- Data cleaning and loading via SQL scripts
- Complex queries for sales trends, delivery delays, seller rankings, and customer behaviour
- Stored procedures for customer and order management workflows
- Triggers for error logging and data integrity
- Performance tuning using `EXPLAIN ANALYZE` and targeted indexing

### Deliverables
- `load_create.sql` — Table schemas, constraints, and data load operations
- `sql project 2.sql` — Core SQL logic including CRUD, analytics, functions, triggers, and indexes
- `Phase2report.pdf` — Full documentation covering schema design, ER diagrams, query logic, and performance optimization

### ER Diagram

![ER Diagram](er_diagram.png)

---

## Phase 2: LLM-Augmented Intelligence ✅

The system is extended with **LLaMA 3 via Groq API** to extract insights from unstructured customer data and generate human-readable reports.

### Features Implemented
- **Customer Feedback Summariser** — Analyses recent interaction records and summarises sentiment and themes
- **Issue Classifier** — Classifies free-text customer complaints into categories (Delivery, Quality, Payment, etc.)
- **Monthly Executive Report Generator** — Pulls key metrics from PostgreSQL and generates a professional business summary

### Technologies Used
- Groq API (LLaMA 3.3 70B) — free tier
- Python (`groq` SDK)
- `psycopg2` for PostgreSQL connectivity

---

## Phase 3: Cloud Deployment ✅

The full system is deployed to the cloud using a free-tier stack with no payment details required.

| Component | Service |
|-----------|---------|
| Database | Supabase (PostgreSQL, free tier) |
| LLM | Groq API (LLaMA 3.3 70B, free tier) |
| Dashboard | Streamlit Community Cloud (free tier) |

### Data Migrated to Supabase
- 99,442 orders
- 1,000,163 geolocation records
- 112,650 order items
- 3,000 customers
- 3,001 sellers
- 99,441 products
- 103,886 payments
- 32,951 social media mentions
- 3,095 ecommerce traffic records
- 3,000 customer interactions

---

## Local Setup

### Prerequisites
- Python 3.10+
- PostgreSQL (local) or Supabase account
- Groq API key (free at [https://console.groq.com](https://console.groq.com))

### Installation

1. Clone the repository:
```bash
git clone https://github.com/shubhrat12/E-Commerce-Analytics-System-with-LLM-Augmented-Intelligence
cd E-Commerce-Analytics-System-with-LLM-Augmented-Intelligence
```


2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Create a `.env` file:
```
DB_HOST=your_db_host
DB_PORT=5432
DB_NAME=postgres
DB_USER=your_db_user
DB_PASSWORD=your_db_password
GROQ_API_KEY=your_groq_api_key
```

4. Run the dashboard:
```bash
streamlit run dashboard.py
```

---

### Common Setup Issue: CSV Path / Permission Error in PostgreSQL

When loading CSVs using the `COPY` command you may encounter:
```
ERROR: could not open file "..." for reading: Permission denied
```

**Solution**: Move CSV files to `C:\pg_import\` and update paths in `load_create.sql` to use forward slashes:
```sql
COPY customers FROM 'C:/pg_import/customers.csv' WITH (FORMAT csv, HEADER true);
```

Alternatively use pgAdmin: **Right-click table → Import/Export Data → Select CSV → Enable Header**

---

## Project Status

- ✅ SQL infrastructure and analytics system completed
- ✅ LLM integration completed (Groq API — LLaMA 3.3 70B)
- ✅ Streamlit dashboard completed
- ✅ Full cloud deployment live

---

## Project Status

- ✅ SQL infrastructure and analytics system completed
- ✅ LLM integration completed (Groq API — LLaMA 3.3 70B)
- ✅ Streamlit dashboard completed
- ✅ Full cloud deployment live
