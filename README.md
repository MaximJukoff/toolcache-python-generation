# toolcache-python-generation

TODO
<br/>Create submodule:
<br/>git submodule add -b master https://github.com/akv-platform/helpers.git
<br/>Clone repository with submodules:
1. git clone --branch v-dmshib/refactor-helper-module --recursive https://github.com/akv-platform/toolcache-python-generation.git
2. More modern variant: git clone --branch v-dmshib/refactor-helper-module --recurse-submodules https://github.com/akv-platform/toolcache-python-generation.git
3. Clone and update submodule: git clone --branch v-dmshib/refactor-helper-module --recurse-submodules --remote-submodules https://github.com/akv-platform/toolcache-python-generation.git
<br/>Submodule takes timestamp of current changes. So if you want to keep it up to date you should use third variant or after clone excecute: git submodule update --init and after that you can continue use git submodule update --remote. 