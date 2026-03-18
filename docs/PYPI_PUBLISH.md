# PyPI Publish Guide

Build:
```bash
cd packages/sdk-py
python3 -m pip install --upgrade build
python3 -m build
```

Publish:
```bash
python3 -m pip install --upgrade twine
python3 -m twine upload dist/*
```
