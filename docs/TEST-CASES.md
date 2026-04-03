# PDF Scanner Detailed Test Cases

**Document:** TEST-CASES.md  
**Product:** PDF Scanner & Document Tool  
**Publisher:** Heldig Lab  
**Source of Truth:** [REQUIREMENTS.md](./REQUIREMENTS.md)  
**Related Documents:** [TEST-PLAN.md](./TEST-PLAN.md)

## Purpose

This document provides step-by-step test cases for the PDF Scanner. It focuses on validating edge detection, perspective transform, offline OCR, and PDF generation.

---

## 1. Document Capture & Processing (TC-100)

### TC-101: Auto-Capture on High-Contrast Background
**Objective:** Verify the edge detection model accurately frames a document and captures automatically.
1. Place a white piece of A4 paper with text on a dark table.
2. Launch the app and tap the FAB to open the camera.
3. Enable "Auto-Capture" mode.
4. Hold the phone steady over the paper.
5. **Expected Result:** The blue AR polygon accurately snaps to the four corners of the paper. Within 1-2 seconds of holding steady, the app automatically triggers the shutter (with a white flash and haptic feedback) and saves the frame.

### TC-102: Manual Capture & Crop
**Objective:** Verify manual capture and perspective correction.
1. Open the camera in "Manual" mode.
2. Capture a document at a slight angle (e.g., 45 degrees).
3. The app proceeds to the Edit & Crop view.
4. Manually drag the four corners of the crop tool to match the document's physical corners. Ensure the magnifying loupe appears.
5. Tap "Save".
6. **Expected Result:** The resulting image is perfectly flattened (perspective transformed) to a standard rectangular aspect ratio without distortion.

### TC-103: Image Enhancement Filters
**Objective:** Verify the Black & White filter optimizes document legibility.
1. Capture a document with faint gray text or shadows.
2. In the Edit view, apply the "Black & White" filter.
3. **Expected Result:** The background shadows are blown out to pure white (#FFFFFF), and the text is thresholded to pure black (#000000), resulting in a high-contrast scan suitable for printing.

---

## 2. OCR & PDF Export (TC-200)

### TC-201: Offline OCR Extraction
**Objective:** Verify the on-device ML model accurately extracts text without an internet connection.
1. Put the device in Airplane Mode.
2. Capture a standard receipt with clear text.
3. In the Document Detail view, tap "OCR Text".
4. **Expected Result:** The app extracts the text accurately in under 2.5 seconds. A bottom sheet appears with the text and a "Copy to Clipboard" button.

### TC-202: Multi-Page PDF Compilation & Export
**Objective:** Verify the app can compile a batch of scans into a single PDF.
1. In the camera, enable "Batch" mode.
2. Capture 5 distinct pages consecutively.
3. Proceed to the Document Detail view.
4. Tap the "Share/Export" icon.
5. Select "Export as PDF" and choose "High Quality".
6. **Expected Result:** The OS share sheet appears. Saving the PDF to local Files and opening it reveals a single 5-page PDF document with all pages in the correct order and high resolution. No watermarks are present.

---

## 3. Extended Capture & Editing (TC-100 continued)

### TC-103: Real-Time Edge Detection Overlay
**Objective:** Verify the edge detection model highlights document boundaries as the camera moves.
1. Launch the app and open the camera viewfinder.
2. Slowly move the phone over a document placed on a contrasting surface.
3. Tilt and rotate the phone at various angles.
4. **Expected Result:** A blue polygon overlay continuously tracks and snaps to the document edges in real-time at 30+ FPS. The polygon updates smoothly as the phone moves — no flickering or jumping. When the document leaves the frame, the polygon disappears cleanly.

### TC-104: Auto-Capture on Steady Hold
**Objective:** Verify auto-capture triggers after the device is held steady.
1. Enable "Auto-Capture" mode.
2. Position the phone over a document on a dark surface.
3. Hold the phone steady (no movement) for 1-2 seconds.
4. **Expected Result:** The app automatically triggers the shutter with a white flash animation and haptic feedback. The captured image proceeds to the crop/edit view. No manual tap was required.

### TC-105: Manual Capture via Shutter Button
**Objective:** Verify the manual shutter button captures correctly.
1. Disable "Auto-Capture" mode (set to "Manual").
2. Position the phone over a document.
3. Tap the shutter button.
4. **Expected Result:** The image is captured instantly on tap. Haptic feedback fires. The captured frame proceeds to the crop/edit view with the edge detection polygon pre-applied.

### TC-106: Adjust 4-Corner Crop Handles
**Objective:** Verify manual corner adjustment applies correct perspective correction.
1. Capture a document at a 30-45 degree angle.
2. In the crop view, drag each of the four corner handles to precisely match the document corners. Verify the magnifying loupe appears on each drag.
3. Tap "Apply" / "Save".
4. **Expected Result:** The output image is a perfectly rectangular, flattened document with no barrel distortion or skew. Text lines that were slanted in the original photo now appear horizontal.

### TC-107: Apply Image Enhancement Filters
**Objective:** Verify all filter modes produce visually distinct results.
1. Capture a color document with shadows and light gradients.
2. In the edit view, cycle through all filters: Original, Black & White, Grayscale, Color Enhance.
3. **Expected Result:** Each filter produces a visually distinct output. "Black & White" thresholds to pure black text on white background. "Grayscale" preserves shading but removes color. "Color Enhance" boosts saturation and contrast. "Original" shows the unmodified capture. Switching between filters is instant (< 500ms).

### TC-108: Batch Scan — Multi-Page Document
**Objective:** Verify batch mode captures multiple pages into one document.
1. Enable "Batch" mode in the camera.
2. Capture 3 distinct document pages sequentially.
3. After each capture, verify a page counter increments (e.g., "Page 1 of 1" -> "Page 2" -> "Page 3").
4. Tap "Done" to finalize the batch.
5. **Expected Result:** The Document Detail view shows a single document containing 3 pages. Swiping through the pages shows them in the order they were captured (Page 1 first, Page 3 last).

### TC-109: Reorder Pages in Multi-Page Document
**Objective:** Verify page reordering persists correctly.
1. Create a 3-page document via batch scan.
2. Open the document and enter the page management / reorder view.
3. Drag Page 3 to the Page 1 position.
4. Save and close the document.
5. Reopen the document.
6. **Expected Result:** The new page order (original Page 3 is now first) persists after saving. Exporting as PDF reflects the reordered sequence.

### TC-110: OCR Text Extraction — Typed English Text
**Objective:** Verify OCR accurately extracts printed English text.
1. Print a paragraph of standard English text (12pt font, black on white).
2. Scan the printed page.
3. Tap "OCR Text" in the Document Detail view.
4. **Expected Result:** The extracted text matches the printed source with 95%+ accuracy. Common words, numbers, and punctuation are correct. The text is copyable via the "Copy to Clipboard" button.

### TC-111: Export Single Document as PDF
**Objective:** Verify PDF export produces a valid, complete file.
1. Create a 3-page document via batch scan.
2. Tap "Share/Export" and select "Export as PDF".
3. Save the PDF to Files.
4. Open the saved PDF in a standard PDF reader.
5. **Expected Result:** The PDF contains exactly 3 pages in the correct order. Each page displays the scanned content at the selected quality level. No watermarks are present. The file is a valid PDF (opens in any PDF reader without errors).

### TC-112: Share PDF via System Share Sheet
**Objective:** Verify the share sheet receives a valid PDF file.
1. Export a scanned document as PDF.
2. Tap the share icon to open the native OS share sheet.
3. Send via AirDrop, save to Files, or share to another app.
4. **Expected Result:** The share sheet displays the PDF with correct filename and file size. The recipient receives a valid, openable PDF file with all pages intact.

### TC-113: Search Documents by OCR Text
**Objective:** Verify full-text search queries OCR content.
1. Scan 3 different documents — one containing the word "Invoice", one containing "Receipt", and one containing "Contract".
2. In the Library view, tap the search bar.
3. Type "Invoice".
4. **Expected Result:** Only the document containing "Invoice" in its OCR text appears in the search results. "Receipt" and "Contract" documents are filtered out. Clearing the search restores all 3 documents.

### TC-114: Delete Document from Library
**Objective:** Verify document deletion frees storage.
1. Note the app's storage usage (Settings or system storage).
2. Create a multi-page document with high-quality scans.
3. Delete the document from the Library (long press or swipe).
4. Confirm deletion.
5. **Expected Result:** The document disappears from the Library grid/list immediately. The app's storage usage decreases. The document's images, enhanced copies, and any generated PDFs are permanently removed from the filesystem.

### TC-115: Low-Light Scanning Handling
**Objective:** Verify the app handles poor lighting gracefully.
1. Place a document in a dimly lit environment.
2. Open the camera viewfinder.
3. **Expected Result:** The app either displays a "Low light detected" warning banner or automatically suggests enabling the flash/torch. If flash is set to "Auto", it activates automatically. Edge detection may be less accurate but does not crash or freeze.

### TC-116: App Crash Recovery During Batch Scan
**Objective:** Verify previously captured pages survive an app crash.
1. Start a batch scan and capture 3 pages.
2. Force-kill the app from the app switcher before tapping "Done".
3. Relaunch the app.
4. **Expected Result:** The app offers to recover the in-progress batch scan. The 3 previously captured pages are available and can be finalized into a document. No captured images are lost.

### TC-117: Dark Mode UI Compatibility
**Objective:** Verify all UI elements are visible in system dark mode.
1. Enable system Dark Mode in device Settings.
2. Launch the app and navigate through all major screens: Library, Camera, Crop/Edit, Document Detail, Settings.
3. **Expected Result:** All text is legible against dark backgrounds. No white-on-white or black-on-black text. All icons, buttons, and interactive elements are clearly visible. The camera viewfinder overlay (edge detection polygon) remains visible against both light and dark documents.

---

## 4. Privacy & Zero-Backend Validation (TC-300)

### TC-301: Network Traffic Audit
**Objective:** Prove mathematically that the app does not leak data.
1. Connect the testing device to a proxy (e.g., Charles Proxy).
2. Launch the app, capture a document, run OCR, and export a PDF.
3. Review the proxy traffic logs.
4. **Expected Result:** Zero network requests are initiated by the application. (Note: OS-level telemetry is out of scope).

### TC-302: Total Data Erasure
**Objective:** Verify that the user can completely wipe their scans.
1. Create 3 multi-page documents.
2. Navigate to Settings > Data.
3. Tap "Clear All Data" and confirm.
4. **Expected Result:** The app returns to the empty state. A subsequent check of the Expo FileSystem directory confirms that all original images, enhanced images, and PDFs have been deleted permanently. The SQLite database is empty.
