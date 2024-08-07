# Scoreboard Detection Research

### First, create virtual environment

```bash
python -m venv .venv_sbd
```

### Then, active the environment

```bash
.venv_sbd/Scripts/activate # for Windows
#source .venv_sbd/bin/activate # for Linux
```

### Install requirements and tesserocr

```bash
python -m pip install --upgrade pip
pip install dist/tesserocr-2.6.2-cp39-cp39-win_amd64.whl
pip install -r requirements.txt
```

## Run detection

To see some examples of how to detect lines in tables (i.e. score board), run main.py file

```bash
python main.py
```

To see some examples of how to detect scores in tables (i.e. score board), run main_api.py file

```bash
python main_api.py
```

## Testing

Python unit and integration tests are located under `test`.

- Run all tests

```bash
pytest
```

- Run a specific test

```bash
pytest test/test_cell1.py
```