# Make sure shared libraries was linked correctly
python -m venv /tmp/aml-ve
source /tmp/aml-ve/bin/activate
easy_install --version
pip install psutil --verbose