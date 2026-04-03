# PDF Scanner Requirements

**Document:** REQUIREMENTS.md  
**Product:** PDF Scanner & Document Tool  
**Publisher:** Heldig Lab  
**Source of Truth:** [SPEC.md](./SPEC.md)  
**Related Documents:** [ARCHITECTURE.md](./ARCHITECTURE.md), [NON-FUNCTIONAL-REQUIREMENTS.md](./NON-FUNCTIONAL-REQUIREMENTS.md)

## Purpose

This document enumerates the functional requirements (FR) and high-level non-functional requirements (NFR) for the PDF Scanner launch (v1.0). The overriding constraint for all requirements is that **the app is a one-time purchase with absolutely no subscriptions, ads, or backend infrastructure.**

---

## 1. Functional Requirements

### 1.1 Document Capture (FR-001 to FR-010)

| ID | Requirement | Priority |
|---|---|---|
| FR-001 | The system shall provide a camera viewfinder with real-time edge detection overlay for documents. | High |
| FR-002 | The system shall auto-capture when a steady document is detected, or allow manual shutter capture. | High |
| FR-003 | The system shall support capturing multiple pages into a single document batch. | High |
| FR-004 | The system shall allow the user to toggle the camera flash (Torch) on/off/auto. | Medium |
| FR-005 | The system shall allow importing existing images from the device photo library for scanning. | High |

### 1.2 Document Enhancement & Editing (FR-011 to FR-020)

| ID | Requirement | Priority |
|---|---|---|
| FR-011 | The system shall provide a crop screen with a magnetic 4-corner perspective adjustment tool. | High |
| FR-012 | The system shall allow the user to rotate the scanned image in 90-degree increments. | High |
| FR-013 | The system shall apply a perspective transform to flatten the cropped image. | High |
| FR-014 | The system shall provide image enhancement filters: Original, Black & White, Grayscale, and Color Enhance. | High |
| FR-015 | The system shall allow the user to re-order, delete, or add pages to an existing document. | High |

### 1.3 OCR & Processing (FR-021 to FR-030)

| ID | Requirement | Priority |
|---|---|---|
| FR-021 | The system shall perform Optical Character Recognition (OCR) on all scanned pages entirely on-device. | High |
| FR-022 | The system shall save the extracted OCR text to the local SQLite database for full-text searching. | High |
| FR-023 | The system shall allow the user to copy the extracted OCR text to the device clipboard. | Medium |

### 1.4 Organization & Search (FR-031 to FR-040)

| ID | Requirement | Priority |
|---|---|---|
| FR-031 | The system shall present a "Library" home screen displaying all scanned documents as a grid or list. | High |
| FR-032 | The system shall allow the user to rename documents. Default names shall be timestamp-based (e.g., "Scan 2026-03-31 10:00"). | High |
| FR-033 | The system shall allow users to add custom tags or place documents in local folders. | Medium |
| FR-034 | The system shall provide a full-text search bar that queries document titles, tags, and extracted OCR text. | High |
| FR-035 | The system shall sort the Library by Date (default) or Name. | Medium |

### 1.5 Export & Sharing (FR-041 to FR-050)

| ID | Requirement | Priority |
|---|---|---|
| FR-041 | The system shall compile a multi-page document into a standard PDF file. | High |
| FR-042 | The system shall allow exporting the document as a PDF to the native OS share sheet (Email, Messages, AirDrop, Files). | High |
| FR-043 | The system shall allow exporting individual pages as JPEG images to the native OS share sheet or Photos library. | High |
| FR-044 | The system shall allow the user to select the PDF quality/file size (Low, Medium, High) before exporting. | Medium |
| FR-045 | The system shall **never** apply a watermark to exported PDFs or images. | Critical |

---

## 2. Non-Functional Requirements (High-Level)

| ID | Category | Requirement |
|---|---|---|
| NFR-001 | **Privacy** | **Zero-Backend:** No document images, metadata, or extracted text shall ever be transmitted to Heldig Lab or any third-party server. |
| NFR-002 | **Monetization** | The app shall be a one-time paid upfront app. No recurring subscriptions, ads, or restricted "Pro" tiers shall exist. |
| NFR-003 | **Performance** | Real-time edge detection must run at 30+ FPS on a modern device. |
| NFR-004 | **Offline** | 100% of the application's features (including OCR) must work in Airplane Mode. |
