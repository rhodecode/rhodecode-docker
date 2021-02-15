"""
echo "%run path/enable_svn_proxy.py" | RC_SETTING='{"vcs_svn_proxy_http_requests_enabled":true, "vcs_svn_proxy_http_server_url": "http://localhost:8090"}' rc-ishell .dev/dev.ini
"""

import os
import json
from rhodecode.model.db import Session
from rhodecode.model.settings import VcsSettingsModel

defaults = json.dumps({
    'vcs_svn_proxy_http_requests_enabled': True,
    'vcs_svn_proxy_http_server_url': 'http://svn:8090'
})


def main(json_args):
    model = VcsSettingsModel()
    model.create_or_update_global_svn_settings(json_args)
    Session().commit()
    print('ok')


args = json.loads(os.environ.get('RC_SETTING') or defaults)
main(args)
