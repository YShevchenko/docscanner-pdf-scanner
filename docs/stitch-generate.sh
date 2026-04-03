#!/bin/bash
# Script to generate PDF Scanner UI designs using Google Stitch
# Requires gcloud application-default credentials

set -e

WORK_DIR="/Users/yts/lab/planned/pdf-scanner/docs/stitch-designs"
mkdir -p "$WORK_DIR"
LOG_FILE="$WORK_DIR/generation.log"

echo "Starting Stitch Generation for PDF Scanner..." > "$LOG_FILE"

# Get Token
TOKEN=$(gcloud auth application-default print-access-token)
export STITCH_ACCESS_TOKEN=$TOKEN
export GOOGLE_CLOUD_PROJECT=lab-apps-490222

export PATH="/opt/homebrew/bin:$PATH"

# 1. Create Project
echo "Creating project..." | tee -a "$LOG_FILE"
PROJECT_JSON=$(stitch-mcp tool create_project -d '{"title": "PDF Scanner - Vibecodable"}' -o json)
PROJECT_ID=$(echo "$PROJECT_JSON" | grep -o '"name":"projects/[^"]*' | cut -d'/' -f2 | head -1)

echo "Project ID: $PROJECT_ID" | tee -a "$LOG_FILE"

if [ -z "$PROJECT_ID" ]; then
  echo "Failed to create project." | tee -a "$LOG_FILE"
  exit 1
fi

# Define prompts
declare -a PROMPTS=(
  "Mobile app home screen for a document scanner. A clean grid displaying thumbnails of scanned documents like receipts and forms. Each card shows a title like 'Tax 2026' and a date. Top bar has a search input. Bottom right corner has a large, prominent floating action button with a camera icon to scan a new document. Color palette is monochromatic and professional."
  "Mobile app camera viewfinder screen for scanning documents. Full screen live camera preview. Overlaid is a bright blue polygon outlining a piece of paper on a dark desk. A translucent top bar has a flash toggle icon. A translucent bottom bar has a large circular shutter button, a gallery icon, and a toggle for 'Single' vs 'Batch' mode."
  "Mobile app image editing and cropping screen. A captured document is shown in the center with a 4-point magnetic crop tool with corner handles. The top bar has 'Cancel' and 'Done' buttons. The bottom bar has icons to rotate 90 degrees and apply color filters like B&W, Grayscale, and Original."
  "Mobile app document detail view. The main area shows a full-screen scrollable preview of a scanned, flattened document. The top bar has a back arrow, the document title 'Receipt 01', and an export/share icon. The bottom bar has buttons: 'Add Page', 'OCR Text', and 'Delete' icon."
  "Mobile app settings screen. A clean native list layout. Sections include 'Preferences' with an option for 'Default Export Quality', 'Data Management' with 'Clear Cache' and 'Export All Data to JSON', and 'About'. The design is minimal, text-heavy, and focuses on utility."
)

declare -a FILENAMES=(
  "01_Library"
  "02_CameraViewfinder"
  "03_EditCrop"
  "04_DocumentDetail"
  "05_Settings"
)

# 2. Generate Screens
for i in "${!PROMPTS[@]}"; do
  export STITCH_ACCESS_TOKEN=$(gcloud auth application-default print-access-token)
  PROMPT="${PROMPTS[$i]}"
  FILENAME="${FILENAMES[$i]}"
  
  echo "Generating Screen $((i+1))/5: $FILENAME..." | tee -a "$LOG_FILE"
  
  SCREEN_JSON=$(stitch-mcp tool generate_screen_from_text -d "{\"projectId\": \"$PROJECT_ID\", \"prompt\": \"$PROMPT\"}" -o json || true)
  SCREEN_ID=$(echo "$SCREEN_JSON" | grep -o '"name":"projects/[^"]*/screens/[^"]*' | cut -d'/' -f4 | head -1)
  
  if [ -n "$SCREEN_ID" ]; then
    echo "  Success! Screen ID: $SCREEN_ID" | tee -a "$LOG_FILE"
    echo "  Fetching HTML..." | tee -a "$LOG_FILE"
    CODE_JSON=$(stitch-mcp tool get_screen_code -d "{\"projectId\": \"$PROJECT_ID\", \"screenId\": \"$SCREEN_ID\"}" -o json || true)
    echo "$CODE_JSON" > "$WORK_DIR/$FILENAME.json"
    echo "  Saved to $FILENAME.json" | tee -a "$LOG_FILE"
  else
    echo "  Failed to generate screen. Response: $SCREEN_JSON" | tee -a "$LOG_FILE"
  fi
done

echo "All generation tasks completed!" | tee -a "$LOG_FILE"