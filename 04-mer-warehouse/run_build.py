#!/usr/bin/env python3
"""Build the SAMPLE cash MER warehouse on DuckDB.

Works without dbt: load seeds, run the same SQL as the models, assert tests,
write out/preview.csv. With --preview-only, only assert + export (after dbt build).
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

import duckdb
import pandas as pd

ROOT = Path(__file__).resolve().parent
DB_PATH = ROOT / "mer_warehouse.duckdb"
SEEDS = ROOT / "seeds"
OUT = ROOT / "out"
MODELS_STAGING = ROOT / "models" / "staging"
MODELS_MARTS = ROOT / "models" / "marts"
TESTS = ROOT / "tests"

PAID_CHANNELS = ("Google", "Meta", "TikTok", "Microsoft")
LAST_CLICK_CHANNELS = PAID_CHANNELS + ("Email", "Direct")
CLAIMED_CHANNELS = PAID_CHANNELS + ("Email",)

SEED_TABLES = (
    ("ads_spend_daily", "ads_spend_daily.csv"),
    ("orders", "orders.csv"),
    ("sessions", "sessions.csv"),
    ("email_sends", "email_sends.csv"),
    ("assumptions", "assumptions.csv"),
)

REF_RE = re.compile(r"\{\{\s*ref\(\s*['\"](\w+)['\"]\s*\)\s*\}\}")
CONFIG_RE = re.compile(r"\{\{\s*config\([\s\S]*?\)\s*\}\}")


def strip_jinja(sql: str) -> str:
    sql = CONFIG_RE.sub("", sql)
    sql = REF_RE.sub(r"\1", sql)
    leftover = re.findall(r"\{\{[\s\S]*?\}\}", sql)
    if leftover:
        raise RuntimeError("Unparsed jinja in SQL: {0}".format(leftover[:3]))
    return sql.strip().rstrip(";")


def generate_seeds() -> None:
    if str(ROOT) not in sys.path:
        sys.path.insert(0, str(ROOT))
    import generate_seeds as gen  # noqa: WPS433

    gen.main()


def connect() -> duckdb.DuckDBPyConnection:
    return duckdb.connect(str(DB_PATH))


def load_seeds(con: duckdb.DuckDBPyConnection) -> None:
    for table, fname in SEED_TABLES:
        path = SEEDS / fname
        if not path.exists():
            raise FileNotFoundError("Missing seed {0}. Run generate_seeds.py.".format(path))
        df = pd.read_csv(path)
        con.execute("DROP TABLE IF EXISTS {0}".format(table))
        con.register("_seed_tmp", df)
        con.execute("CREATE TABLE {0} AS SELECT * FROM _seed_tmp".format(table))
        con.unregister("_seed_tmp")


def run_models(con: duckdb.DuckDBPyConnection) -> None:
    for path in sorted(MODELS_STAGING.glob("*.sql")):
        sql = strip_jinja(path.read_text())
        con.execute("CREATE OR REPLACE VIEW {0} AS {1}".format(path.stem, sql))
    for path in sorted(MODELS_MARTS.glob("*.sql")):
        sql = strip_jinja(path.read_text())
        con.execute("CREATE OR REPLACE TABLE {0} AS {1}".format(path.stem, sql))


def run_sql_tests(con: duckdb.DuckDBPyConnection) -> None:
    for path in sorted(TESTS.glob("*.sql")):
        sql = strip_jinja(path.read_text())
        n = con.execute("select count(*) from ({0}) t".format(sql)).fetchone()[0]
        if n:
            raise AssertionError("{0} failed ({1} rows)".format(path.name, n))
        print("pass  {0}".format(path.name))


def _count(con: duckdb.DuckDBPyConnection, sql: str) -> int:
    return int(con.execute(sql).fetchone()[0])


def run_generic_tests(con: duckdb.DuckDBPyConnection) -> None:
    paid_list = ", ".join("'{0}'".format(c) for c in PAID_CHANNELS)
    last_list = ", ".join("'{0}'".format(c) for c in LAST_CLICK_CHANNELS)
    claimed_list = ", ".join("'{0}'".format(c) for c in CLAIMED_CHANNELS)

    checks = [
        (
            "ads_spend_daily.channel accepted_values",
            "select count(*) from ads_spend_daily where channel is null or channel not in ({0})".format(
                paid_list
            ),
        ),
        (
            "orders.last_click_channel accepted_values",
            "select count(*) from orders where last_click_channel is null or last_click_channel not in ({0})".format(
                last_list
            ),
        ),
        (
            "orders.net_cash not_null",
            "select count(*) from orders where net_cash is null or gross is null or order_id is null",
        ),
        (
            "orders.order_id unique",
            "select count(*) from (select order_id from orders group by 1 having count(*) > 1) t",
        ),
        (
            "fct_daily_mer.channel accepted_values",
            "select count(*) from fct_daily_mer where channel is null or channel not in ({0})".format(
                paid_list
            ),
        ),
        (
            "fct_daily_mer not_null keys",
            "select count(*) from fct_daily_mer where date is null or spend is null or net_cash is null or company_mer is null or break_even_mer is null",
        ),
        (
            "fct_channel_claimed_vs_cash.channel accepted_values",
            "select count(*) from fct_channel_claimed_vs_cash where channel is null or channel not in ({0})".format(
                claimed_list
            ),
        ),
        (
            "dim_metric_dictionary.kpi_name unique not_null",
            "select count(*) from ("
            "select kpi_name from dim_metric_dictionary where kpi_name is null or definition is null "
            "union all "
            "select kpi_name from dim_metric_dictionary group by 1 having count(*) > 1"
            ") t",
        ),
        (
            "net_cash <= gross",
            "select count(*) from orders where net_cash > gross",
        ),
    ]
    for name, sql in checks:
        n = _count(con, sql)
        if n:
            raise AssertionError("Test failed: {0} ({1} rows)".format(name, n))
        print("pass  {0}".format(name))


def write_preview(con: duckdb.DuckDBPyConnection) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    df = con.execute(
        "select * from fct_channel_claimed_vs_cash order by claimed_revenue desc"
    ).df()
    preview = OUT / "preview.csv"
    df.to_csv(preview, index=False)
    ratio = float(df["stack_claimed_to_cash_ratio"].iloc[0])
    claimed = float(df["total_claimed_revenue"].iloc[0])
    cash = float(df["company_net_cash"].iloc[0])
    print("wrote {0}".format(preview))
    print(
        "SAMPLE over-attribution: claimed_revenue {0:,.0f} vs company net_cash {1:,.0f} ({2:.2f}x).".format(
            claimed, cash, ratio
        )
    )
    if ratio <= 1.0:
        raise AssertionError(
            "SAMPLE DGP should show stacked claimed_revenue > company net_cash; got ratio {0}".format(
                ratio
            )
        )


def build_duckdb() -> None:
    generate_seeds()
    if DB_PATH.exists():
        DB_PATH.unlink()
    wal = Path(str(DB_PATH) + ".wal")
    if wal.exists():
        wal.unlink()
    con = connect()
    try:
        load_seeds(con)
        run_models(con)
        run_sql_tests(con)
        run_generic_tests(con)
        write_preview(con)
        n_dict = _count(con, "select count(*) from dim_metric_dictionary")
        n_mer = _count(con, "select count(*) from fct_daily_mer")
        print(
            "ok  duckdb SQL path  dim_metric_dictionary={0} fct_daily_mer={1} rows  {2}".format(
                n_dict, n_mer, DB_PATH.name
            )
        )
    finally:
        con.close()


def preview_only() -> None:
    if not DB_PATH.exists():
        raise FileNotFoundError(
            "{0} missing; run without --preview-only".format(DB_PATH)
        )
    con = connect()
    try:
        run_sql_tests(con)
        run_generic_tests(con)
        write_preview(con)
        print("ok  preview-only from existing DuckDB")
    finally:
        con.close()


def main() -> None:
    parser = argparse.ArgumentParser(description="SAMPLE cash MER warehouse build")
    parser.add_argument(
        "--preview-only",
        action="store_true",
        help="Assert tests and write out/preview.csv from an existing mer_warehouse.duckdb (after dbt build).",
    )
    args = parser.parse_args()
    if args.preview_only:
        preview_only()
    else:
        build_duckdb()


if __name__ == "__main__":
    main()
