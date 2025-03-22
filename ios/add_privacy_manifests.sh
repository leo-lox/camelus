#!/bin/bash

# Path to the app Frameworks directory
FRAMEWORKS_DIR="./build/ios/iphoneos/Runner.app/Frameworks"

# Create privacy manifest for DKImagePickerController
mkdir -p "$FRAMEWORKS_DIR/DKImagePickerController.framework"
cat > "$FRAMEWORKS_DIR/DKImagePickerController.framework/PrivacyInfo.xcprivacy" << 'EOL'
{
  "NSPrivacyCollectedDataTypes": [],
  "NSPrivacyAccessedAPITypes": [
    {
      "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryPhotoLibrary",
      "NSPrivacyAccessedAPITypeReasons": ["C317.1"]
    },
    {
      "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryCamera",
      "NSPrivacyAccessedAPITypeReasons": ["C317.1"]
    }
  ]
}
EOL

# Create privacy manifest for DKPhotoGallery
mkdir -p "$FRAMEWORKS_DIR/DKPhotoGallery.framework"
cat > "$FRAMEWORKS_DIR/DKPhotoGallery.framework/PrivacyInfo.xcprivacy" << 'EOL'
{
  "NSPrivacyCollectedDataTypes": [],
  "NSPrivacyAccessedAPITypes": [
    {
      "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryPhotoLibrary",
      "NSPrivacyAccessedAPITypeReasons": ["C317.1"]
    }
  ]
}
EOL

# Create privacy manifest for SDWebImage
mkdir -p "$FRAMEWORKS_DIR/SDWebImage.framework"
cat > "$FRAMEWORKS_DIR/SDWebImage.framework/PrivacyInfo.xcprivacy" << 'EOL'
{
  "NSPrivacyCollectedDataTypes": [],
  "NSPrivacyAccessedAPITypes": [
    {
      "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryNetworkInformation",
      "NSPrivacyAccessedAPITypeReasons": ["CA92.1"]
    }
  ]
}
EOL

# Create privacy manifest for SwiftyGif
mkdir -p "$FRAMEWORKS_DIR/SwiftyGif.framework"
cat > "$FRAMEWORKS_DIR/SwiftyGif.framework/PrivacyInfo.xcprivacy" << 'EOL'
{
  "NSPrivacyCollectedDataTypes": [],
  "NSPrivacyAccessedAPITypes": []
}
EOL

echo "Privacy manifests added to frameworks"
