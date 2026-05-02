"""
db_connection.py
Handles PostgreSQL connection using psycopg2 and environment variables.
"""

import os
import psycopg2
import psycopg2.extras
from dotenv import load_dotenv

load_dotenv()


def get_connection():
    """Return a new psycopg2 connection using .env credentials."""
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "localhost"),
        port=os.getenv("DB_PORT", "5432"),
        dbname=os.getenv("DB_NAME", "ecommerce_db"),
        user=os.getenv("DB_USER", "postgres"),
        password=os.getenv("DB_PASSWORD", ""),
    )


def run_query(sql: str, params=None) -> list[dict]:
    """
    Execute a SELECT query and return rows as a list of dicts.
    
    Args:
        sql: SQL query string
        params: optional tuple of query parameters
    Returns:
        list of row dicts
    """
    conn = get_connection()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(sql, params)
            return [dict(row) for row in cur.fetchall()]
    finally:
        conn.close()


if __name__ == "__main__":
    # Quick sanity check
    rows = run_query("SELECT COUNT(*) AS total FROM customers;")
    print("Customers:", rows)
