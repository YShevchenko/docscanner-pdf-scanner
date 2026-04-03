# PDF Scanner Test Plan

**Document:** TEST-PLAN.md  
**Product:** PDF Scanner & Document Tool  
**Publisher:** Heldig Lab  
**Source of Truth:** [REQUIREMENTS.md](./REQUIREMENTS.md)  
**Related Documents:** [ARCHITECTURE.md](./ARCHITECTURE.md), [NON-FUNCTIONAL-REQUIREMENTS.md](./NON-FUNCTIONAL-REQUIREMENTS.md)

## 1. Quality Strategy

PDF Scanner relies on high-performance camera access and local file system management. Our QA strategy focuses on **Device Performance** (ensuring memory isn't leaked during batch scanning) and **Export Accuracy** (ensuring PDFs are formatted correctly).

### 1.1 Testing Tiers
- **Unit Tests:** Business logic validation (PDF compilation, Date formatting).
- **Integration Tests:** SQLite indexing, FileSystem read/writes, Vision Model bridging.
- **E2E Tests:** End-to-end scanning flows (Capture -> Crop -> Filter -> Export).
- **Manual QA:** Edge detection under various lighting conditions, multi-page batch scanning stability.

---

## 2. Test Environments

| Environment | Description |
|---|---|
| **iOS Simulator** | Limited use (Camera APIs cannot be fully tested here). Good for UI layouts and Export flows. |
| **Android Emulator** | Limited use. Layouts only. |
| **Physical iOS Device** | iPhone 13 (or newer) - **Critical** for Vision model performance and thermal throttling tests. |
| **Physical Android Device** | Samsung Galaxy S21 (or newer) - **Critical** for testing camera autofocus stability and ML Kit OCR. |

---

## 3. Core Test Scenarios

### 3.1 Document Capture & Edge Detection
- Validate that the AR polygon accurately snaps to high-contrast documents.
- Validate that the polygon falls back gracefully on low-contrast documents.
- Validate that Auto-Capture triggers only when the device is held steady.

### 3.2 Image Processing
- Validate the perspective transform accurately flattens an angled shot.
- Validate that "Black & White" filter aggressively thresholds the image to pure #000000 and #FFFFFF.
- Validate that "Grayscale" retains shading.

### 3.3 OCR & PDF Export
- Validate that on-device OCR correctly extracts English text from a standard receipt.
- Validate that exporting a 10-page document creates a single multi-page PDF.
- Validate that exporting to the OS share sheet works without crashing.

### 3.4 Zero-Backend Validation
- Run the entire application in Airplane Mode for 24 hours. Ensure 100% functionality.
- Monitor network traffic (Charles Proxy) to ensure absolutely zero bytes are sent to any external server during usage.
