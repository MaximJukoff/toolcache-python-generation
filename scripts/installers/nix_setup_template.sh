MAJOR_VERSION={0}
MINOR_VERSION={1}
BUILD_VERSION={2}
TOOLCACHE_PATH={3}

PYTHON_MAJOR=python$MAJOR_VERSION
PYTHON_MAJOR_DOT_MINOR=python$MAJOR_VERSION.$MINOR_VERSION
PYTHON_MAJORMINOR=python$MAJOR_VERSION$MINOR_VERSION
PYTHON_FULL_VERSION=$MAJOR_VERSION.$MINOR_VERSION.$BUILD_VERSION

PYTHON_TOOLCACHE_PATH=$TOOLCACHE_PATH
PYTHON_TOOLCACHE_VERSION_PATH=$PYTHON_TOOLCACHE_PATH/$PYTHON_FULL_VERSION
PYTHON_TOOLCACHE_VERSION_ARCH_PATH=$PYTHON_TOOLCACHE_VERSION_PATH/x64

set -e

echo "Check if Python hostedtoolcache folder exist..."
if [ ! -d $PYTHON_TOOLCACHE_PATH ]; then
    mkdir -p $PYTHON_TOOLCACHE_PATH
fi

echo "Delete Python $PYTHON_FULL_VERSION if installed"
rm -rf $PYTHON_TOOLCACHE_PATH/$PYTHON_FULL_VERSION

echo "Create Python $PYTHON_FULL_VERSION folder"
mkdir $PYTHON_TOOLCACHE_VERSION_PATH
mkdir $PYTHON_TOOLCACHE_VERSION_ARCH_PATH

echo "Copy Python binaries to hostedtoolcache folder"
cp ./tool.zip $PYTHON_TOOLCACHE_VERSION_ARCH_PATH

cd $PYTHON_TOOLCACHE_VERSION_ARCH_PATH

echo "Unzip python to $PYTHON_TOOLCACHE_VERSION_PATH"
unzip -q tool.zip
echo "Python unzipped successfully"
rm tool.zip

echo "Create additional symlinks (Required for UsePythonVersion VSTS task)"
ln -s ./bin/$PYTHON_MAJOR_DOT_MINOR python

cd bin/
ln -s $PYTHON_MAJOR_DOT_MINOR $PYTHON_MAJORMINOR
if [ ! -f python ]; then
    ln -s $PYTHON_MAJOR_DOT_MINOR python
fi

chmod +x ../python $PYTHON_MAJOR $PYTHON_MAJOR_DOT_MINOR $PYTHON_MAJORMINOR python

echo "Upgrading PIP..."
./python -m ensurepip
./python -m pip install --ignore-installed pip

echo "Create complete file"
touch $PYTHON_TOOLCACHE_VERSION_PATH/x64.complete
