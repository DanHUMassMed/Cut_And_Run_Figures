VENV = .venv
PYTHON = $(VENV)/bin/python
UV = uv
KERNEL_NAME = cut-and-run
KERNEL_DISPLAY_NAME = Python 3.12 (Cut and Run)

.PHONY: help install liftover set-kernel notebook readme clean

help:
	@echo "Available targets:"
	@echo "  make install    - Create virtualenv with Python 3.12 via uv, install dependencies, register kernel, and liftOver"
	@echo "  make liftover   - Download standalone UCSC liftOver binary into $(VENV)/bin"
	@echo "  make set-kernel - Set the kernel for all notebooks to the local venv"
	@echo "  make notebook   - Launch Jupyter Lab"
	@echo "  make readme     - Render and preview README.md in default web browser via grip"
	@echo "  make clean      - Remove virtualenv and temporary build artifacts"

install:
	$(UV) venv --python 3.12 $(VENV)
	$(UV) pip install --python $(PYTHON) -e ".[notebook,yaml,test,doc]"
	$(PYTHON) -m ipykernel install --user \
        --name $(KERNEL_NAME) \
        --display-name "$(KERNEL_DISPLAY_NAME)"
	@$(MAKE) set-kernel
	@$(MAKE) liftover
	@if [ ! -f .env ]; then cp env.example .env; echo "Initialized default .env configuration."; fi
	@echo ""
	@echo "=================================================================="
	@echo " Installation Complete!"
	@echo " Run 'make notebook' to launch JupyterLab."
	@echo "=================================================================="

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



set-kernel:
	$(PYTHON) set_kernel.py

notebook:
	$(VENV)/bin/jupyter lab --notebook-dir=notebooks

readme:
	@PYTHONWARNINGS="ignore" $(VENV)/bin/grip README.md -b

clean:
	rm -rf $(VENV) build/ dist/ *.egg-info .pytest_cache

