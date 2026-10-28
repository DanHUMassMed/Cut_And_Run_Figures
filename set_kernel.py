import json
from pathlib import Path

KERNEL_NAME = "cut-and-run"
KERNEL_DISPLAY_NAME = "Python 3.12 (Cut and Run)"

for path in Path("notebooks").rglob("*.ipynb"):
    notebook = json.loads(path.read_text())
    notebook["metadata"]["kernelspec"] = {
        "display_name": KERNEL_DISPLAY_NAME,
        "language": "python",
        "name": KERNEL_NAME,
    }
    path.write_text(json.dumps(notebook, indent=1) + "\n")
    print(f"Updated {path}")