VENV = .venv
PYTHON = $(VENV)/bin/python
UV = uv

.PHONY: help install liftover test lint notebook clean

help:
	@echo "Available targets:"
	@echo "  make install    - Create virtualenv with Python 3.12 via uv, install dependencies and liftOver"
	@echo "  make liftover   - Download standalone UCSC liftOver binary into $(VENV)/bin"
	@echo "  make notebook   - Launch Jupyter Lab"
	@echo "  make test       - Run pytest test suite"
	@echo "  make clean      - Remove virtualenv and temporary build artifacts"

install:
	$(UV) venv --python 3.12 $(VENV)
	$(UV) pip install --python $(PYTHON) -e ".[notebook,yaml,test]"
	@$(MAKE) liftover

liftover:
	@mkdir -p $(VENV)/bin
	@OS=$$(uname -s); ARCH=$$(uname -m); \
	if [ "$$OS" = "Darwin" ] && [ "$$ARCH" = "arm64" ]; then \
		echo "Downloading UCSC liftOver for macOS (arm64)..."; \
		curl -fsSL -o $(VENV)/bin/liftOver http://hgdownload.soe.ucsc.edu/admin/exe/macOSX.arm64/liftOver; \
	elif [ "$$OS" = "Darwin" ]; then \
		echo "Downloading UCSC liftOver for macOS (x86_64)..."; \
		curl -fsSL -o $(VENV)/bin/liftOver http://hgdownload.soe.ucsc.edu/admin/exe/macOSX.x86_64/liftOver; \
	else \
		echo "Downloading UCSC liftOver for Linux (x86_64)..."; \
		curl -fsSL -o $(VENV)/bin/liftOver http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/liftOver; \
	fi
	@chmod +x $(VENV)/bin/liftOver
	@echo "UCSC liftOver successfully installed to $(VENV)/bin/liftOver"

test:
	$(PYTHON) -m pytest

notebook:
	$(VENV)/bin/jupyter lab --notebook-dir=notebooks

clean:
	rm -rf $(VENV) build/ dist/ *.egg-info .pytest_cache

