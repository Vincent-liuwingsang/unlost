# create python bundle

python -m PyInstaller unlost_server.py -D -y --windowed --hidden-import=torch --hidden-import=unlost_server --collect-data torch --collect-data en_core_web_sm --copy-metadata torch --copy-metadata tqdm --copy-metadata regex  --copy-metadata requests --copy-metadata packaging --copy-metadata filelock --copy-metadata numpy --copy-metadata tokenizers --copy-metadata importlib_metadata --copy-metadata huggingface-hub --copy-metadata safetensors --copy-metadata pyyaml --exclude-module skl2onnx --add-data "query_classifier.pickle:." --codesign-identity Y96AFSD559


python -m PyInstaller unlost_server.spec -y

# create dmg

create-dmg \
  --volname "Unlost Installer" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "unlost.app" 200 200 \
  --hide-extension "unlost.app" \
  --app-drop-link 600 185 \
  --codesign "Y96AFSD559" \
  --notarize "unlost_app_notarize" \
  "/Users/wingsangvincentliu/Desktop/Unlost.nosync/0.2.1/unlost.dmg" \
  "/Users/wingsangvincentliu/Desktop/Unlost.nosync/0.2.1/"


# check if app/dmg is notarized/signed properly

spctl -a -t exec -vvv ~/Desktop/Unlost.nosync/0.2.5/unlost.app 
spctl -a -t open -vvvv --context context:primary-signature  ~/Desktop/Unlost.nosync/0.2.5/unlost.dmg

# generate appcast

~/Library/Developer/Xcode/DerivedData/unlost-bilkxoyyzpfmithgmpxgsqtvjmuk/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_appcast ~/Desktop/Unlost.nosync/0.2.2/   
 

# transform ips into crash format

swift convertFromJSON.swift -i ~/Library/Logs/DiagnosticReports/unlost-2023-08-24-155740.ips -o ~/Library/Logs/DiagnosticReports/unlost-2023-08-24-155740.ips

# symlink code to raw address

export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

/Applications/Xcode.app/Contents/SharedFrameworks/DVTFoundation.framework/Versions/A/Resources/symbolicatecrash ~/Library/Logs/DiagnosticReports/unlost-2023-08-24-155740.ips  ~/Library/Developer/Xcode/Archives/2023-08-24/unlost\ 24-08-2023,\ 14.33.xcarchive > ~/Desktop/Unlost.nosync/0.2.1/debug.crash

# create notarize credentials

xcrun notarytool store-credentials unlost_app_notarize --apple-id wingsangvincentliu@gmail.com --password hzgn-kdmr-moty-xwvh --team-id Y96AFSD559