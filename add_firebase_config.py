#!/usr/bin/env python3
"""
Script to add GoogleService-Info.plist to the Xcode project.
This is needed because Flutter doesn't automatically add it to the pbxproj.
"""

import os
import re

def add_file_to_xcode_project():
    pbxproj_path = 'ios/Runner.xcodeproj/project.pbxproj'
    google_service_plist = 'GoogleService-Info.plist'

    with open(pbxproj_path, 'r') as f:
        content = f.read()

    # Check if it's already there
    if google_service_plist in content:
        print(f"✓ {google_service_plist} is already in the Xcode project")
        return True

    # Find the Resources build phase section
    # Look for a line like "Copy Bundle Resources" followed by files

    # Pattern to find the build phases
    # We need to add the file to the Copy Bundle Resources phase

    # First, find where other resource files are listed
    # Look for Info.plist or similar files in the Copy Bundle Resources phase

    resources_pattern = r'(Resources.*?files = \(\s*)'

    # Find the first resources section
    match = re.search(r'name = "Copy Bundle Resources";.*?files = \((.*?)\);', content, re.DOTALL)

    if match:
        files_section = match.group(1)
        # Check if file is already there
        if google_service_plist not in files_section:
            # Add the file before the closing parenthesis
            new_files = files_section.rstrip() + f'\n\t\t\t\t{google_service_plist} /* {google_service_plist} */,\n\t\t\t'
            new_content = content.replace(files_section, new_files)

            with open(pbxproj_path, 'w') as f:
                f.write(new_content)

            print(f"✓ Added {google_service_plist} to Copy Bundle Resources phase")
            return True

    # If we couldn't find the pattern, try a simpler approach
    # Look for any pbxproj file list and add it there
    if 'PBXFileReference' in content:
        # Find a good place to add the file reference
        # Look for Info.plist and add our file near it
        plist_pattern = r'(.*?Info\.plist.*?;)'
        match = re.search(plist_pattern, content, re.DOTALL)

        if match:
            # Add file reference
            file_ref = f'{google_service_plist} /* {google_service_plist} */ = {{isa = PBXFileReference; lastKnownFileType = file; name = {google_service_plist}; path = Runner/{google_service_plist}; sourceTree = SOURCE_ROOT; }};'

            insert_pos = match.end()
            new_content = content[:insert_pos] + '\n\t\t' + file_ref + content[insert_pos:]

            with open(pbxproj_path, 'w') as f:
                f.write(new_content)

            print(f"✓ Added {google_service_plist} file reference to Xcode project")
            return True

    print(f"✗ Could not automatically add {google_service_plist} to Xcode project")
    print("Please add it manually:")
    print("1. Open ios/Runner.xcodeproj in Xcode")
    print("2. Select the 'Runner' target")
    print("3. Go to 'Build Phases' > 'Copy Bundle Resources'")
    print("4. Click '+' and select GoogleService-Info.plist from the ios/Runner folder")

    return False

if __name__ == '__main__':
    os.chdir('/Users/isisj/PhpstormProjects/collectable')
    add_file_to_xcode_project()

