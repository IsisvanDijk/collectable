#!/usr/bin/env python3
"""
Add GoogleService-Info.plist to the Copy Bundle Resources phase in Xcode project.
"""

import re
import sys

def add_file_to_copy_bundle_resources():
    pbxproj_path = '/Users/isisj/PhpstormProjects/collectable/ios/Runner.xcodeproj/project.pbxproj'

    try:
        with open(pbxproj_path, 'r') as f:
            content = f.read()

        # Find the file reference ID for GoogleService-Info.plist
        file_id_match = re.search(r'(\w+) /\* GoogleService-Info\.plist \*/ = \{isa = PBXFileReference;', content)
        if not file_id_match:
            print("ERROR: Could not find GoogleService-Info.plist file reference ID")
            return False

        file_id = file_id_match.group(1)
        print(f"Found file reference ID: {file_id}")

        # Find the Copy Bundle Resources section
        cbr_pattern = r'(name = "Copy Bundle Resources";[^}]*?files = \(([^)]*?)\);)'
        cbr_match = re.search(cbr_pattern, content, re.DOTALL)

        if not cbr_match:
            print("ERROR: Could not find Copy Bundle Resources phase")
            return False

        cbr_section = cbr_match.group(1)
        files_section = cbr_match.group(2)

        # Check if file is already there
        if file_id in files_section:
            print("✓ GoogleService-Info.plist is already in Copy Bundle Resources")
            return True

        # Add the file to the list
        new_file_entry = f'\n\t\t\t\t{file_id} /* GoogleService-Info.plist */,'
        new_files_section = files_section.rstrip() + new_file_entry
        new_cbr_section = cbr_section.replace(files_section, new_files_section)

        # Replace in content
        new_content = content.replace(cbr_section, new_cbr_section)

        # Write back
        with open(pbxproj_path, 'w') as f:
            f.write(new_content)

        print("✓ Successfully added GoogleService-Info.plist to Copy Bundle Resources")
        return True

    except Exception as e:
        print(f"ERROR: {str(e)}", file=sys.stderr)
        return False

if __name__ == '__main__':
    success = add_file_to_copy_bundle_resources()
    sys.exit(0 if success else 1)

