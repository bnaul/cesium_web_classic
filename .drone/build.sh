#!/bin/bash

set -e

pip install -r requirements.txt
python setup.py build_ext -i
make test
