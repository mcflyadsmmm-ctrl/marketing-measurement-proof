# SAMPLE monorepo helpers
PYTHON := .venv/bin/python
PIP := .venv/bin/pip

.PHONY: venv warehouse hightouch lola causal calendar python-all

venv:
	python3 -m venv .venv
	$(PIP) install -r requirements.txt

warehouse:
	$(MAKE) -C 04-mer-warehouse build

hightouch:
	$(PYTHON) 05-hightouch-eda/generate_sends.py
	$(PYTHON) 05-hightouch-eda/analysis.py

lola:
	$(PYTHON) 06-lola-pulse/generate_pulse.py
	$(PYTHON) 06-lola-pulse/voc.py
	$(PYTHON) 06-lola-pulse/bfcm_forecast.py
	$(PYTHON) 06-lola-pulse/plot_pulse.py

causal:
	$(PYTHON) 07-causalimpact/python/failure_case.py
	$(PYTHON) 07-causalimpact/python/saturation_hill.py

calendar:
	$(PYTHON) 08-test-calendar/generate_intraday.py
	$(PYTHON) 08-test-calendar/plot_intraday.py

python-all: warehouse hightouch lola causal calendar
