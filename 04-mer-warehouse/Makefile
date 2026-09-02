# SAMPLE cash MER warehouse.
# No Snowflake. Do not stand up Airflow / MWAA.

PY := ../.venv/bin/python
DBT := ../.venv/bin/dbt

.PHONY: seeds build dag clean

seeds:
	$(PY) generate_seeds.py

# dbt build when the venv has dbt; otherwise (or on dbt failure) DuckDB SQL.
build: seeds
	$(DBT) build --profiles-dir . && $(PY) run_build.py --preview-only || $(PY) run_build.py

# Would be an Airflow BashOperator. Not an Airflow deployment.
# BashOperator(task_id="mer_warehouse_build", bash_command="make -C 04-mer-warehouse build")
dag:
	@$(MAKE) build

clean:
	rm -rf target logs dbt_packages mer_warehouse.duckdb mer_warehouse.duckdb.wal
