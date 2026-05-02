"""
dashboard.py

Streamlit dashboard for the E-Commerce Analytics System.
Combines live SQL data with LLM-generated insights.

Run with:
    streamlit run dashboard.py
"""

import streamlit as st
import pandas as pd
import plotly.express as px
from db_connection import run_query
from llm_analytics import (
    summarize_customer_feedback,
    classify_customer_issue,
    generate_monthly_report,
)

# ─── Page config ────────────────────────────────────────────────────────────
st.set_page_config(
    page_title="E-Commerce Analytics",
    page_icon="🛒",
    layout="wide",
)

st.title("🛒 E-Commerce Analytics Dashboard")
st.caption("Brazilian E-Commerce Dataset · PostgreSQL + LLaMA 3 via Groq")

# ─── Sidebar navigation ──────────────────────────────────────────────────────
page = st.sidebar.radio(
    "Navigate",
    ["📊 Overview", "📦 Orders & Delivery", "🏆 Sellers & Products",
     "🤖 AI: Feedback Summary", "🤖 AI: Issue Classifier", "🤖 AI: Monthly Report"],
)

# ═════════════════════════════════════════════════════════════════════════════
# PAGE 1 — OVERVIEW
# ═════════════════════════════════════════════════════════════════════════════
if page == "📊 Overview":
    st.header("Business Overview")

    col1, col2, col3, col4 = st.columns(4)

    total_orders = run_query("SELECT COUNT(*) AS n FROM orders;")[0]["n"]
    total_customers = run_query("SELECT COUNT(*) AS n FROM customers;")[0]["n"]
    total_sellers = run_query("SELECT COUNT(*) AS n FROM sellers;")[0]["n"]
    total_revenue = run_query("SELECT ROUND(SUM(payment_value)::numeric,2) AS n FROM payments;")[0]["n"]

    col1.metric("Total Orders", f"{total_orders:,}")
    col2.metric("Total Customers", f"{total_customers:,}")
    col3.metric("Active Sellers", f"{total_sellers:,}")
    col4.metric("Total Revenue", f"${total_revenue:,.2f}")

    st.divider()

    # Monthly orders trend
    st.subheader("Monthly Orders Trend")
    monthly = run_query(
        """
        SELECT DATE_TRUNC('month', order_purchase_timestamp)::DATE AS month,
               COUNT(*) AS orders
        FROM orders
        WHERE order_purchase_timestamp > '1970-01-02'
        GROUP BY month
        ORDER BY month;
        """
    )
    if monthly:
        df_monthly = pd.DataFrame(monthly)
        fig = px.line(df_monthly, x="month", y="orders", markers=True,
                      labels={"month": "Month", "orders": "Orders"})
        st.plotly_chart(fig, use_container_width=True)

    # Payment type breakdown
    st.subheader("Payment Method Breakdown")
    pay = run_query(
        """
        SELECT payment_type, COUNT(*) AS count
        FROM payments
        WHERE payment_type != 'Unknown'
        GROUP BY payment_type
        ORDER BY count DESC;
        """
    )
    if pay:
        df_pay = pd.DataFrame(pay)
        fig2 = px.pie(df_pay, names="payment_type", values="count")
        st.plotly_chart(fig2, use_container_width=True)


# ═════════════════════════════════════════════════════════════════════════════
# PAGE 2 — ORDERS & DELIVERY
# ═════════════════════════════════════════════════════════════════════════════
elif page == "📦 Orders & Delivery":
    st.header("Orders & Delivery Performance")

    # Average delivery days by state
    st.subheader("Average Delivery Time by State (days)")
    del_rows = run_query(
        """
        SELECT c.customer_state AS state,
               ROUND(AVG(EXTRACT(EPOCH FROM (
                   o.order_delivered_customer_date - o.order_purchase_timestamp
               )) / 86400)::numeric, 1) AS avg_days
        FROM orders o
        JOIN customers c ON o.customer_id = c.customer_id
        WHERE o.order_status = 'delivered'
          AND o.order_delivered_customer_date > '1970-01-02'
        GROUP BY state
        ORDER BY avg_days DESC;
        """
    )
    if del_rows:
        df_del = pd.DataFrame(del_rows)
        fig = px.bar(df_del, x="state", y="avg_days",
                     labels={"state": "State", "avg_days": "Avg Days"},
                     color="avg_days", color_continuous_scale="Reds")
        st.plotly_chart(fig, use_container_width=True)

    # Order status distribution
    st.subheader("Order Status Distribution")
    status_rows = run_query(
        """
        SELECT order_status, COUNT(*) AS count
        FROM orders
        WHERE order_status != 'Unknown'
        GROUP BY order_status
        ORDER BY count DESC;
        """
    )
    if status_rows:
        df_status = pd.DataFrame(status_rows)
        fig2 = px.bar(df_status, x="order_status", y="count",
                      labels={"order_status": "Status", "count": "Count"},
                      color="count", color_continuous_scale="Blues")
        st.plotly_chart(fig2, use_container_width=True)


# ═════════════════════════════════════════════════════════════════════════════
# PAGE 3 — SELLERS & PRODUCTS
# ═════════════════════════════════════════════════════════════════════════════
elif page == "🏆 Sellers & Products":
    st.header("Sellers & Products")

    # Top 10 sellers by revenue
    st.subheader("Top 10 Sellers by Revenue")
    sellers = run_query(
        """
        SELECT s.seller_id,
               s.seller_city,
               s.seller_state,
               ROUND(SUM(oi.price)::numeric, 2) AS total_revenue
        FROM sellers s
        JOIN order_items oi ON s.seller_id = oi.seller_id
        GROUP BY s.seller_id, s.seller_city, s.seller_state
        ORDER BY total_revenue DESC
        LIMIT 10;
        """
    )
    if sellers:
        st.dataframe(pd.DataFrame(sellers), use_container_width=True)

    # Top product categories
    st.subheader("Top 10 Product Categories by Orders")
    cats = run_query(
        """
        SELECT COALESCE(pct.product_category_name_english, p.product_category_name) AS category,
               COUNT(oi.order_id) AS orders
        FROM products p
        JOIN order_items oi ON p.product_id = oi.product_id
        LEFT JOIN product_category_name_translation pct
               ON p.product_category_name = pct.product_category_name
        GROUP BY category
        ORDER BY orders DESC
        LIMIT 10;
        """
    )
    if cats:
        df_cats = pd.DataFrame(cats)
        fig = px.bar(df_cats, x="orders", y="category", orientation="h",
                     labels={"orders": "Orders", "category": "Category"})
        fig.update_layout(yaxis={"categoryorder": "total ascending"})
        st.plotly_chart(fig, use_container_width=True)


# ═════════════════════════════════════════════════════════════════════════════
# PAGE 4 — AI: FEEDBACK SUMMARY
# ═════════════════════════════════════════════════════════════════════════════
elif page == "🤖 AI: Feedback Summary":
    st.header("LLaMA 3 — Customer Feedback Summary")
    st.info("LLaMA 3 (via Groq) will analyse recent customer interaction records and summarise sentiment & themes.")

    limit = st.slider("Number of recent records to analyse", 10, 200, 50, step=10)

    if st.button("Generate Summary"):
        with st.spinner("Asking LLaMA 3…"):
            summary = summarize_customer_feedback(limit=limit)
        st.success("Done!")
        st.markdown(summary)


# ═════════════════════════════════════════════════════════════════════════════
# PAGE 5 — AI: ISSUE CLASSIFIER
# ═════════════════════════════════════════════════════════════════════════════
elif page == "🤖 AI: Issue Classifier":
    st.header("LLaMA 3 — Customer Issue Classifier")
    st.info("Type a customer complaint and LLaMA 3 (via Groq) will classify it into a support category.")

    issue_text = st.text_area("Customer complaint text", height=120,
                               placeholder="e.g. My order arrived broken and the packaging was damaged…")

    if st.button("Classify Issue") and issue_text.strip():
        with st.spinner("Classifying…"):
            result = classify_customer_issue(issue_text)
        st.success("Classification complete!")
        col1, col2 = st.columns(2)
        col1.metric("Category", result.get("category", "N/A"))
        col2.metric("Confidence", result.get("confidence", "N/A").capitalize())
        st.write("**Reasoning:**", result.get("brief_reason", ""))


# ═════════════════════════════════════════════════════════════════════════════
# PAGE 6 — AI: MONTHLY REPORT
# ═════════════════════════════════════════════════════════════════════════════
elif page == "🤖 AI: Monthly Report":
    st.header("LLaMA 3 — Monthly Executive Report")
    st.info("Select a month and LLaMA 3 (via Groq) will generate an executive summary using live database metrics.")

    col1, col2 = st.columns(2)
    year = col1.number_input("Year", min_value=2016, max_value=2025, value=2018)
    month = col2.number_input("Month", min_value=1, max_value=12, value=1)

    if st.button("Generate Report"):
        with st.spinner("Pulling metrics and asking LLaMA 3…"):
            report = generate_monthly_report(int(year), int(month))
        st.success("Report ready!")
        st.markdown(report)
