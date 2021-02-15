"""
echo "%run path/set_default_renderer_to_md.py" | RC_SETTING='[["markup_renderer", "markdown", "unicode"]]' rc-ishell .dev/dev.ini
"""

import os
import json
from rhodecode.model.db import Session
from rhodecode.model.settings import SettingsModel

defaults = json.dumps([
    ('markup_renderer', 'markdown', 'unicode')
])


def main(json_args):
    model = SettingsModel()
    for setting_name, value, type_ in json_args:
        model.create_or_update_setting(setting_name, value, type_)
    Session().commit()
    print('ok')


args = json.loads(os.environ.get('RC_SETTING') or defaults)
main(args)
