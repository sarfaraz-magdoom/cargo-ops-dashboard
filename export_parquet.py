from pathlib import Path
import polars as pl
from sqlalchemy import create_engine

SERVER   = r"MS\SQLEXPRESS"
DATABASE = "CargoOps"

PARQUET_DIR = Path("data/parquet")

FACT_DATE_COL = {
    "fact_flights": "flight_date",
    "fact_tonnage": "flight_date",
}

FACT_NO_DATE = ["fact_cargo_iq"]

CONN = (
    f"mssql+pyodbc://@{SERVER}/{DATABASE}"
    "?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes"
)


def main():
    engine = create_engine(CONN)
    PARQUET_DIR.mkdir(parents=True, exist_ok=True)

    # for dated facts: read, ensure Date type, partition by year/month ---
    for name, date_col in FACT_DATE_COL.items():
        df = pl.read_database(f"SELECT * FROM dbo.{name}", engine.connect())

        if df[date_col].dtype != pl.Date:
            df = df.with_columns(pl.col(date_col).cast(pl.Date, strict=False))

        df = df.with_columns(
            pl.col(date_col).dt.year().alias("year"),
            pl.col(date_col).dt.month().alias("month"),
        )
        target = PARQUET_DIR / name
        df.write_parquet(
            target,
            use_pyarrow=True,
            pyarrow_options={"partition_cols": ["year", "month"]},
        )
        print(f"  {name:14s} -> {target}\\year=*\\month=*  ({df.height:,} rows)")

    # for undated fact: flat file
    for name in FACT_NO_DATE:
        df = pl.read_database(f"SELECT * FROM dbo.{name}", engine.connect())
        target = PARQUET_DIR / f"{name}.parquet"
        df.write_parquet(target, compression="zstd")
        print(f"  {name:14s} -> {target}  (flat, no date)  ({df.height:,} rows)")

    print("\nDone. Point Power BI at:", PARQUET_DIR.resolve())


if __name__ == "__main__":
    main()