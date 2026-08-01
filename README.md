# B2B-Sales-Pipeline-Account-Performance-Dashboard
This project presents an end-to-end Business Intelligence solution designed to analyze B2B sales performance, sales funnel velocity, revenue growth trends, and sales agent efficiency.

Using the CRM Sales Opportunities dataset from Maven Analytics, the raw data was ingested, cleaned, and transformed using SQL Server and Power Query, followed by advanced DAX modeling and executive visualization in Power BI. The resulting two-page dashboard provides actionable insights to help sales leadership optimize pipeline conversion and streamline sales cycles.

**Business Problem & Objectives**
Analyzing B2B sales operations requires understanding both macro-level business performance and micro-level team efficiency. This project addresses several core questions:

**Executive Performance**: What is our total revenue, win rate %, average deal size, and month-over-month (MoM) revenue growth?
**Pipeline Velocity**: At what stage of the sales pipeline are prospective deals dropping off?
**Product Revenue Distribution**: Which product hardware lines drive the vast majority of closed-won revenue?
**Sales Force Efficiency**: Who are our top-performing sales representatives and managers, and what is their average sales cycle duration?
**Account Concentration**: How heavily dependent is total revenue on Enterprise vs. Mid-Market and Small accounts?

**Dataset & Data Architecture**
Data Source
**Provider**: Maven Analytics Data Playground: https://www.mavenanalytics.io/data-playground
**Dataset**: CRM Sales Opportunities
**Contents**: Contains B2B sales pipeline data for a fictitious hardware company, including individual deal stages (Prospecting, Engaging, Won, Lost), products, sales agents, regional teams, and account details.

**Tech Stack Pipeline**
[ Maven Analytics CRM CSVs ] --> [ SQL Server Database ] --> [ Power Query ETL ] --> [ Power BI (Star Schema & DAX) ]
**Database Engine**: SQL Server (Data staging, views, and integrity checks)
**ETL & Data Transformation**: Power Query (Custom conditional column indexing for sales process ordering)
**Data Modeling**: Star Schema (vw_fact_sales_pipeline linked to dim_date, dim_accounts, dim_products, and dim_teams)
**Visualization**: Power BI Desktop

**Dashboard Structure**
**Page 1**: Executive Sales Overview
Designed for executive decision-makers to track high-level revenue health and conversion velocity.
**KPI Cards**: Total Revenue ($10.01M), Average Ticket Size ($2.36K), Win Rate % (63.15%), and Avg Sales Cycle Days (52 days).
**Revenue Trend by Month**: Combo chart tracking Monthly Closed-Won Revenue alongside Month-over-Month (MoM) Revenue Growth % chronologically from JAN to DEC.
**Pipeline Conversion Funnel**: Logical progression across deal stages (Prospecting $\rightarrow$ Engaging $\rightarrow$ Won $\rightarrow$ Lost).
**Top Products by Revenue**: Horizontal ranking identifying core revenue drivers (Led by GTXPro and GTX Plus Pro).
**Revenue Distribution by Company Size**: Monochromatic donut chart showcasing account portfolio breakdown (90.03% Enterprise dominated).

**Page 2**: Sales Team & Account Performance
Designed for Regional Managers and Sales Directors to evaluate team productivity and key account distribution.
**Key Metrics**: Closed Deals (7K), Overall Win Rate % (63.15%), Avg Cycle Days (52), and Dynamic Top Sales Agent (Darcel Schlecht).
**Revenue by Sales Agent**: Ranking chart highlighting individual sales rep contributions.
**Sales Rep Efficiency Matrix**: Comprehensive table combining Total Revenue (with data bars), Win Rate %, and Average Sales Cycle length per representative.
**Revenue by Sales Manager**: Managerial performance comparison (Led by Melvin Marxen and Summer Sewald).
**Top 10 Key Accounts**: Filtered view highlighting top corporate clients by total spend.

**DAX Calculations & Key Measures**
All metrics were centralized inside a dedicated Key_measures table for clean data architecture.

**1. Dynamic Top Sales Agent**

Top Sales Agent = 
CALCULATE(
    SELECTEDVALUE(vw_fact_sales_pipeline[sales_agent]),
    TOPN(
        1, 
        ALLSELECTED(vw_fact_sales_pipeline[sales_agent]), 
        [Total Revenue], 
        DESC
    )
)

**2. Month-over-Month (MoM) Revenue Growth %**

MoM Revenue Growth % = 
VAR CurrentMonthRevenue = [Total Revenue]
VAR PreviousMonthRevenue = 
    CALCULATE(
        [Total Revenue],
        DATEADD(dim_date[Date], -1, MONTH)
    )
RETURN
    DIVIDE(CurrentMonthRevenue - PreviousMonthRevenue, PreviousMonthRevenue, 0)

**3. Win Rate %**

Win Rate % = 
DIVIDE(
    CALCULATE(COUNT(vw_fact_sales_pipeline[opportunity_id]), vw_fact_sales_pipeline[deal_stage] = "Won"),
    COUNT(vw_fact_sales_pipeline[opportunity_id]),
    0
)

**Key Business Insights**
**Enterprise Revenue Dominance**: Enterprise accounts generate 90.03% ($9.01M) of total revenue. Strategic account management resources should focus heavily on enterprise retention and upselling.
**Product Portfolio Concentration**: The GTXPro and GTX Plus Pro hardware lines account for over 60% of overall sales volume, indicating a high reliance on top-tier flagship offerings.
**Sales Cycle Efficiency**: The overall average sales cycle is 52 days. However, top-tier reps like Cecily Lampkin and Elease Gluck achieve cycle times as low as 42–44 days while maintaining high Win Rates (~66%).
**Funnel Progression**: The stage transition from Engaging to Won represents the highest opportunity for revenue optimization, pointing to a need for targeted closing playbooks.

**How to Replicate This Project**
Download the Data:
-Get the CRM Sales Opportunities CSV files directly from Maven Analytics.(https://www.mavenanalytics.io/data-playground)

Database Setup:
-Import the tables into SQL Server and execute the scripts in /SQL/ to build the star schema views.

Power BI Configuration:
-Open CRM Sales Report.pbix.
-Update the SQL Server connection string under **Data Source Settings**.
-Refresh the data model.

**Author**
Francisco Javier Bermudez Espinoza
Systems Engineering Graduate & Data Analyst

Specialized in SQL Server, Tableau, Power BI, DAX Modeling, and Business Intelligence.

**LinkedIn**: www.linkedin.com/in/francisco-bermudez-00377a14b
**Portfolio**: https://github.com/FranBer24
