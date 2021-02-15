"""
echo "%run path/enable_diff_cache.py" | RC_SETTING='{"rhodecode_git_close_branch_before_merging": false, "rhodecode_pr_merge_enabled": true, "rhodecode_hg_close_branch_before_merging": false, "rhodecode_use_outdated_comments": true, "rhodecode_git_use_rebase_for_merging": false, "rhodecode_diff_cache": true, "rhodecode_hg_use_rebase_for_merging": false}' rc-ishell .dev/dev.ini
"""

import os
import json
from rhodecode.model.db import Session
from rhodecode.model.settings import VcsSettingsModel


defaults = json.dumps({
    'rhodecode_diff_cache': True,
    'rhodecode_git_close_branch_before_merging': False,
    'rhodecode_git_use_rebase_for_merging': False,
    'rhodecode_hg_close_branch_before_merging': False,
    'rhodecode_hg_use_rebase_for_merging': False,
    'rhodecode_pr_merge_enabled': True,
    'rhodecode_use_outdated_comments': True
})


def main(json_args):
    model = VcsSettingsModel()
    model.create_or_update_global_pr_settings(json_args)
    Session().commit()
    print('ok')


args = json.loads(os.environ.get('RC_SETTING') or defaults)
main(args)
