# PDF Scanner UI/UX Specification

**Document:** UI-UX-SPEC.md  
**Product:** PDF Scanner & Document Tool  
**Publisher:** Heldig Lab  
**Source of Truth:** [SPEC.md](./SPEC.md)  
**Related Documents:** [ARCHITECTURE.md](./ARCHITECTURE.md), [REQUIREMENTS.md](./REQUIREMENTS.md)

## 1. Design Philosophy

PDF Scanner is built on three core pillars: **Calmness, Utility, and Trust.**

- **Calmness:** The app is a tool. It gets out of the way. No popups, no "rate us" interruptions during a workflow, no gamification.
- **Utility:** The UI is monochromatic and professional. Content (the user's documents) provides the color.
- **Trust (Zero-Backend):** No accounts, no sign-ins, no "upgrade to Pro" buttons.

---

## 2. Visual Identity

### 2.1 Color Palette

| Name | Hex Code | Usage |
|---|---|---|
| **Primary (Brand)** | `#2B2D42` | Headers, active states, main buttons |
| **Secondary (Accent)**| `#3498DB` | AR edge detection polygon, selection highlights |
| **Background (Light)** | `#F8F9FA` | Standard app background |
| **Surface (Light)** | `#FFFFFF` | Document cards |
| **Background (Dark)** | `#121212` | Dark mode background |
| **Surface (Dark)** | `#1E1E1E` | Dark mode document cards |

### 2.2 Typography

- **Headings:** System Sans-Serif (SF Pro/Roboto) - Medium.
- **Body:** System Sans-Serif - Regular.
- **Monospace:** For OCR text display to ensure exact readability.

---

## 3. Motion & Interaction

### 3.1 Gesture Language
- **Pinch-to-Zoom:** While viewing a scanned document.
- **Swipe to Delete:** In the Library list view.
- **Drag & Drop:** Reordering pages in the Edit View.

### 3.2 Transitions
- **Screen Transitions:** Fast (< 250ms) push/pop. No complex animations.
- **Capture Flash:** A brief white flash (100ms) on manual capture.
- **Edge Detection:** The blue polygon smoothly interpolates between frames, snapping cleanly to the document boundaries.

---

## 4. Screen Specifications

### 4.1 Home (Library)
- **Top Bar:** Search input, Settings icon, Sort icon (Date/Name).
- **Content:** Grid (2 columns) or List view of saved documents. Each item shows a thumbnail of the first page, Title, Date, and Page Count.
- **FAB (Floating Action Button):** A prominent, solid primary color camera icon in the bottom right corner.
- **Empty State:** A simple illustration of a document and "Tap the camera to scan your first document."

### 4.2 Camera Viewfinder
- **Full-Screen:** Live camera feed.
- **Top Bar (Translucent):** Flash toggle (Auto/On/Off), Auto-Capture toggle, Close (X) button.
- **Center:** The AR blue polygon actively highlighting detected document edges.
- **Bottom Bar (Translucent):** Gallery import icon, large circular Shutter button, Batch/Single mode toggle. A small thumbnail of the current batch appears next to the shutter.

### 4.3 Edit & Crop View
- **Top Bar:** Cancel, "Done/Save".
- **Center:** The captured image with a 4-point magnetic crop tool. The corners display a magnifying loupe when dragged to ensure precise alignment.
- **Bottom Bar:** Rotate (90 deg), Filters (Original, B&W, Grayscale, Color).
- **Batch Slider:** If multiple pages, a horizontal carousel to swipe between them.

### 4.4 Document Detail
- **Top Bar:** Back, Title (tap to edit), Share/Export icon.
- **Content:** Scrollable view of the document pages.
- **Bottom Bar:** "Add Page", "OCR Text", "Delete".
- **OCR Modal:** Tapping "OCR Text" opens a bottom sheet displaying the extracted text with a "Copy to Clipboard" button.

### 4.5 Settings
- **List Layout:** Clean, standard native list.
- **Sections:**
  - Preferences: Default export quality (High/Medium/Low).
  - Data: Clear Cache, Export All Data (JSON).
  - About: Version, Privacy Policy, Terms of Service.

---

## 5. Accessibility & Localization

### 5.1 Dark Mode Implementation
- Backgrounds switch to `#121212`.
- Text switches to `#FFFFFF` or high-contrast grey.

### 5.2 Dynamic Type
- All text elements must respond to system font scaling preferences without breaking the layout, particularly the OCR text view.

---

## Error & Edge States

- **Empty library:** "No documents yet. Tap the camera to scan your first document." Displayed with a simple document illustration in the center of the Library screen. The FAB camera button remains prominent.
- **Camera permission denied:** Full-screen prompt replacing the viewfinder. Explains: "PDF Scanner needs camera access to scan documents." A primary "Open Settings" button links directly to the app's system settings page. A secondary "Cancel" button returns to the Library.
- **Low-light warning:** Semi-transparent overlay on the camera viewfinder: "Low light detected. Try moving to a brighter area or enable flash." The flash toggle in the top bar pulses briefly to draw attention.
- **Edge detection failed:** Message below the viewfinder area: "Couldn't detect document edges. Position the document on a contrasting surface." The AR polygon is not drawn. The shutter button remains available for manual capture.
- **OCR failed (unreadable text):** In the OCR bottom sheet, instead of extracted text: "Couldn't extract text from this page. The text may be too blurry or handwritten." A "Try Again" button re-runs OCR processing.
- **Storage full:** System alert: "Device storage is full. Delete some documents or free up space to continue scanning." The capture flow is blocked until space is available. The Library remains accessible so users can delete existing documents.
- **Batch scan crash recovery:** On relaunch after an unexpected termination during a batch scan, a recovery banner appears: "We recovered X pages from your last scan session." Two actions: "Continue Editing" (opens the Edit & Crop view with recovered pages) and "Discard" (deletes the temporary files).
- **Export in progress:** A modal progress bar during PDF generation: "Creating PDF... X of Y pages." The modal blocks interaction to prevent corruption. A "Cancel" option is available to abort the export.
