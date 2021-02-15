"""
echo "%run path/generate_svn_apache_conf.py" | RC_SETTING='{"setting1":"key1"}' rc-ishell .dev/dev.ini
"""

import os
import json
from rhodecode.apps.svn_support.utils import generate_mod_dav_svn_config
from rhodecode.lib.base import bootstrap_request

defaults = json.dumps({

})


def main(json_args):
    request = bootstrap_request()
    generate_mod_dav_svn_config(request.registry)
    print('ok')


args = json.loads(os.environ.get('RC_SETTING') or defaults)
main(args)
