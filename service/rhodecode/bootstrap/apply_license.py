"""
echo "%run path/create_docs_repo.py" | rc-ishell .dev/dev.ini
"""

import os
from rhodecode.model.db import Session

LICENSE_FILE_NAME = 'rhodecode_enterprise.license'


def main():
    license_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), LICENSE_FILE_NAME)

    if not os.path.isfile(license_file):
        print('No license file at {}'.format(license_file))
        return

    try:
        from rc_license.models import apply_license
    except ImportError:
        print('Cannot import apply_license')
        return

    with open(license_file, 'r') as f:
        license_data = f.read()

    apply_license(license_data)
    Session().commit()


main()
