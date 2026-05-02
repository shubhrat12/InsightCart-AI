"""
llm_analytics.py

Uses Groq API (free tier) with LLaMA 3 to:
1. Summarize customer feedback / interaction scores
2. Classify customer issues into categories
3. Generate executive-level monthly performance reports from SQL data

Requirements:
  - pip install groq
  - GROQ_API_KEY set in your .env file
  - Get your free API key at: https://console.groq.com
"""

import os
import json
from groq import Groq
from dotenv import load_dotenv
from db_connection import run_query

load_dotenv()

client = Groq(api_key=os.getenv("GROQ_API_KEY"))
#MODEL = "llama3-8b-8192"
MODEL = "llama-3.3-70b-versatile"

def _ask_groq(prompt: str, max_tokens: int = 600) -> str:
    """Send a prompt to Groq (LLaMA 3) and return the response text."""
    try:
        response = client.chat.completions.create(
            model=MODEL,
            messages=[{"role": "user", "content": prompt}],
            max_tokens=max_tokens,
            temperature=0.3,
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        return f"ERROR: {e}"


# ─────────────────────────────────────────────
# 1. Summarise recent customer feedback
# ─────────────────────────────────────────────

def summarize_customer_feedback(limit: int = 50) -> str:
    """
    Pull recent customer_interactions rows and ask LLaMA 3 to summarise
    the overall sentiment and top themes.
    """
    rows = run_query(
        """
        SELECT interaction_type, interaction_channel, feedback_score
        FROM customer_interactions
        ORDER BY interaction_date DESC
        LIMIT %s;
        """,
        (limit,),
    )

    if not rows:
        return "No customer interaction data found."

    lines = [
        f"Type={r['interaction_type']}, Channel={r['interaction_channel']}, Score={r['feedback_score']}"
        for r in rows
    ]
    data_block = "\n".join(lines)

    prompt = f"""You are a senior customer-experience analyst.
Below are {limit} recent customer interaction records (type, channel, feedback score out of 10).

{data_block}

Please provide:
1. Overall sentiment summary (2-3 sentences)
2. Top 3 themes or patterns you observe
3. One concrete recommendation for improvement
"""

    return _ask_groq(prompt, max_tokens=600)


# ─────────────────────────────────────────────
# 2. Classify a single free-text customer issue
# ─────────────────────────────────────────────

ISSUE_CATEGORIES = [
    "Delivery Problem",
    "Product Quality",
    "Payment Issue",
    "Wrong Item",
    "Customer Service",
    "Return / Refund",
    "Other",
]


def classify_customer_issue(issue_text: str) -> dict:
    """
    Given a free-text customer complaint, return a JSON dict with:
      - category  (one of ISSUE_CATEGORIES)
      - confidence  (high / medium / low)
      - brief_reason  (one sentence)
    """
    categories_str = ", ".join(ISSUE_CATEGORIES)

    prompt = f"""You are a customer support classifier for an e-commerce platform.
Classify the following customer complaint into exactly one of these categories:
{categories_str}

Complaint: "{issue_text}"

Respond ONLY with valid JSON in this exact format, with no extra text:
{{"category": "<category>", "confidence": "<high|medium|low>", "brief_reason": "<one sentence>"}}
"""

    raw = _ask_groq(prompt, max_tokens=150)
    # Strip markdown fences if present
    if raw.startswith("```"):
        raw = raw.split("```")[1]
        if raw.startswith("json"):
            raw = raw[4:]
    return json.loads(raw.strip())


# ─────────────────────────────────────────────
# 3. Generate monthly executive report
# ─────────────────────────────────────────────

def generate_monthly_report(year: int, month: int) -> str:
    """
    Pulls key metrics for the given month from PostgreSQL and asks LLaMA 3
    to write a concise executive summary report.
    """
    # --- Revenue & orders ---
    revenue_rows = run_query(
        """
        SELECT
            COUNT(DISTINCT o.order_id)              AS total_orders,
            ROUND(SUM(p.payment_value)::numeric, 2) AS total_revenue,
            ROUND(AVG(p.payment_value)::numeric, 2) AS avg_order_value
        FROM orders o
        JOIN payments p ON o.order_id = p.order_id
        WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = %s
          AND EXTRACT(MONTH FROM o.order_purchase_timestamp) = %s;
        """,
        (year, month),
    )

    # --- Top 3 product categories ---
    top_cats = run_query(
        """
        SELECT pct.product_category_name_english AS category,
               COUNT(oi.order_id) AS orders
        FROM order_items oi
        JOIN orders o ON oi.order_id = o.order_id
        JOIN products p ON oi.product_id = p.product_id
        LEFT JOIN product_category_name_translation pct
               ON p.product_category_name = pct.product_category_name
        WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = %s
          AND EXTRACT(MONTH FROM o.order_purchase_timestamp) = %s
        GROUP BY category
        ORDER BY orders DESC
        LIMIT 3;
        """,
        (year, month),
    )

    # --- Average delivery days ---
    delivery_rows = run_query(
        """
        SELECT ROUND(AVG(EXTRACT(EPOCH FROM (
                   order_delivered_customer_date - order_purchase_timestamp
               )) / 86400)::numeric, 1) AS avg_delivery_days
        FROM orders
        WHERE order_status = 'delivered'
          AND EXTRACT(YEAR FROM order_purchase_timestamp) = %s
          AND EXTRACT(MONTH FROM order_purchase_timestamp) = %s;
        """,
        (year, month),
    )

    # --- Average feedback score ---
    feedback_rows = run_query(
        """
        SELECT ROUND(AVG(feedback_score)::numeric, 2) AS avg_feedback
        FROM customer_interactions
        WHERE EXTRACT(YEAR FROM interaction_date) = %s
          AND EXTRACT(MONTH FROM interaction_date) = %s;
        """,
        (year, month),
    )

    # --- Social media mentions ---
    social_rows = run_query(
        """
        SELECT SUM(mentions) AS total_mentions
        FROM social_media_mentions
        WHERE EXTRACT(YEAR FROM date) = %s
          AND EXTRACT(MONTH FROM date) = %s;
        """,
        (year, month),
    )

    metrics = {
        "period": f"{year}-{month:02d}",
        "total_orders": revenue_rows[0].get("total_orders") if revenue_rows else "N/A",
        "total_revenue": revenue_rows[0].get("total_revenue") if revenue_rows else "N/A",
        "avg_order_value": revenue_rows[0].get("avg_order_value") if revenue_rows else "N/A",
        "avg_delivery_days": delivery_rows[0].get("avg_delivery_days") if delivery_rows else "N/A",
        "avg_feedback_score": feedback_rows[0].get("avg_feedback") if feedback_rows else "N/A",
        "social_mentions": social_rows[0].get("total_mentions") if social_rows else "N/A",
        "top_categories": top_cats,
    }

    prompt = f"""You are a senior e-commerce business analyst.
Using the metrics below, write a professional executive summary report for {metrics['period']}.
Keep it under 300 words. Use clear headings. Highlight wins, risks, and one action item.

Metrics:
- Total Orders: {metrics['total_orders']}
- Total Revenue: ${metrics['total_revenue']}
- Average Order Value: ${metrics['avg_order_value']}
- Average Delivery Time: {metrics['avg_delivery_days']} days
- Average Customer Feedback Score: {metrics['avg_feedback_score']} / 10
- Social Media Mentions: {metrics['social_mentions']}
- Top Product Categories: {metrics['top_categories']}
"""

    return _ask_groq(prompt, max_tokens=600)


# ─────────────────────────────────────────────
# Quick CLI demo
# ─────────────────────────────────────────────

if __name__ == "__main__":
    print("=== FEEDBACK SUMMARY ===")
    print(summarize_customer_feedback(limit=30))

    print("\n=== ISSUE CLASSIFIER ===")
    test_issue = "I ordered a laptop stand 3 weeks ago and it still hasn't arrived."
    print(f"Issue: {test_issue}")
    print(classify_customer_issue(test_issue))

    print("\n=== MONTHLY REPORT (2018-01) ===")
    print(generate_monthly_report(2018, 1))
