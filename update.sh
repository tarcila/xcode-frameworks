#!/usr/bin/env bash
set -euo pipefail
set -x

sdk='/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX14.2.sdk'
frameworks="$sdk/System/Library/Frameworks"
includes="$sdk/usr/include"
libs="$sdk/usr/lib"

rm -rf Frameworks/
rm -rf include/
rm -rf lib/

mkdir -p ./Frameworks
mkdir -p ./include
mkdir -p ./lib

# General includes, removing uncommon or useless ones
cp -R $includes/ ./include
rm -rf ./include/apache2

# General libraries
mkdir -p lib/
cp $libs/libobjc.tbd ./lib/
cp $libs/libobjc.A.tbd ./lib/

# General frameworks
general=("CoreFoundation" "Foundation" "IOKit" "Security" "CoreServices" "DiskArbitration" "CFNetwork" "ApplicationServices" "ImageIO" "Symbols")
for fw in ${general[@]}; do
    cp -R "$frameworks/$fw.framework" "./Frameworks/$fw.framework"
done

# Audio frameworks
audio=("AudioToolbox" "CoreAudio" "CoreMIDI" "CoreAudioTypes" "AudioUnit" "AVFoundation" "AVFAudio")
for fw in ${audio[@]}; do
    cp -R "$frameworks/$fw.framework" "./Frameworks/$fw.framework"
done

# Graphics frameworks
graphics=("Metal" "OpenGL" "CoreGraphics" "IOSurface" "QuartzCore" "CoreImage" "CoreVideo" "CoreText" "ColorSync")
for fw in ${graphics[@]}; do
    cp -R "$frameworks/$fw.framework" "./Frameworks/$fw.framework"
done

# Input/Windowing frameworks & deps
windowing=("AppKit" "Carbon" "CloudKit" "Cocoa" "CoreHaptics" "CoreData" "CoreLocation" "ForceFeedback" "GameController" "Kernel")
for fw in ${windowing[@]}; do
    cp -R "$frameworks/$fw.framework" "./Frameworks/$fw.framework"
done

# Remove unnecessary files
find . | grep '\.swiftmodule' | xargs rm -rf

# Trim large frameworks

# 4.9M -> 1M
cat ./Frameworks/Foundation.framework/Versions/C/Foundation.tbd | grep -v 'libswiftFoundation' > tmp
mv tmp ./Frameworks/Foundation.framework/Versions/C/Foundation.tbd

# 13M -> 368K
find ./Frameworks/Kernel.framework -type f | grep -v IOKit/hidsystem | xargs rm -rf

# 29M -> 28M
find . | grep '\.apinotes' | xargs rm -rf
find . | grep '\.r' | xargs rm -rf
find . | grep '\.modulemap' | xargs rm -rf

# 668K
rm ./Frameworks/OpenGL.framework/Versions/A/Libraries/libLLVMContainer.tbd

# 672K
rm ./Frameworks/OpenGL.framework/Versions/A/Libraries/3425AMD/libLLVMContainer.tbd

# 444K
rm ./Frameworks/CloudKit.framework/Versions/A/CloudKit.tbd

# Remove broken symlinks
find . -type l ! -exec test -e {} \; -print | xargs rm

# Replace symlinks with their actual file contents
dir=Frameworks
tar -hcf tmp.tar $dir && rm -rf $dir && mkdir tmp && tar -xf tmp.tar
rm -rf tmp tmp.tar

dir=include
tar -hcf tmp.tar $dir && rm -rf $dir && mkdir tmp && tar -xf tmp.tar
rm -rf tmp tmp.tar

dir=lib
tar -hcf tmp.tar $dir && rm -rf $dir && mkdir tmp && tar -xf tmp.tar
rm -rf tmp tmp.tar

# Now that /Versions/Current symlinks are realized, we no longer need the duplicate
find Frameworks | grep '/Versions/A/' | xargs rm -rf
find Frameworks | grep '/Versions/C/' | xargs rm -rf
