#!/usr/bin/env bash
# To be launched in a container that features Git and Python 3, as well as all basic dependencies
# for a desktop application. Artifacts will be copied to the `/output` directory, which must be
# mapped in advance before spawning the container.

ls /output || exit 1

# Prepare working directory.
cd /tmp
rm -rf MKDDEXT_BUNDLE_TMP
mkdir MKDDEXT_BUNDLE_TMP
cd MKDDEXT_BUNDLE_TMP

# Check out code.
git clone https://github.com/cristian64/mkdd-extender.git --depth=1
cd mkdd-extender

# Install dependencies.
python3 -m venv venv
source venv/bin/activate
export PYTHONNOUSERSITE=1
python3 -m pip install -r requirements.txt
python3 -m pip install altgraph==0.17.4 packaging==23.2 pyinstaller==6.2.0 pyinstaller-hooks-contrib==2023.10

# Create standalone Python application.
pyinstaller mkdd_extender.spec

# Remove unnecessary files and copy license.
cd dist
bundle_name=$(ls)
cd "$bundle_name/_internal"
rm -r "data/extender_cup/model"
rm "data/extender_cup/cup_logo.svg"
rm libgdk*  # Remove to ensure the system's are used.
cp COPYING README.md ..
cd -

# Create tarball.
python3 -c "import shutil; d = '$bundle_name'; shutil.make_archive(d, 'xztar', '.', d)"

# Create AppImage.
mkdir -p "$bundle_name.AppDir/usr"
cp -R "$bundle_name" "$bundle_name.AppDir/usr/bin"
cp ../build_scripts/mkdd-extender.desktop "$bundle_name.AppDir"
cp ../data/gui/logo256x256.png "$bundle_name.AppDir/mkdd-extender.png"
ln -sr "$bundle_name.AppDir/usr/bin/mkdd-extender" "$bundle_name.AppDir/AppRun"
curl -sSfL https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -o appimagetool
chmod +x appimagetool
./appimagetool --appimage-extract
./squashfs-root/AppRun "$bundle_name.AppDir" "$bundle_name.AppImage"

# Save artifacts.
cp "$bundle_name.tar.xz" /output
cp "$bundle_name.AppImage" /output
