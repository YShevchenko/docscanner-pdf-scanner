# Codex Review -- 2026-04-03

## Documentation

- **Product:** PDF Scanner & Document Tool -- a privacy-first, paid-upfront document scanner for iOS and Android. Zero backend, zero subscriptions, zero ads.
- **Spec:** `docs/SPEC.md` defines the product identity, vision, and anti-scam positioning. Scope is explicitly limited to "product vision and identity only" -- it does not cover feature flows, screen-by-screen behavior, data models, or architecture (those live in separate docs).
- **Architecture:** `docs/ARCHITECTURE.md` defines the Expo/React Native stack, on-device ML pipeline (Apple Vision / ML Kit), local SQLite + FileSystem storage, and the zero-backend constraint. The actual codebase is Flutter (not React Native/Expo as the architecture doc states), so the architecture document is out of sync with the implementation.
- **Requirements:** `docs/REQUIREMENTS.md` enumerates 20+ functional requirements (capture, crop, OCR, library, export) and 4 high-level NFRs (privacy, monetization, performance, offline). `docs/NON-FUNCTIONAL-REQUIREMENTS.md` expands these into 12 detailed quality attributes with measurable thresholds (cold start < 1s, edge detection >= 30 fps, OCR < 2.5s per page, etc.).
- **UI/UX:** `docs/UI-UX-SPEC.md` specifies screens (Library, Camera Viewfinder, Edit & Crop, Document Detail, Settings), color palette, typography, gesture language, transitions, dark mode, and error/edge states. The implementation follows this spec closely.
- **Marketing:** `docs/MARKETING.md` classifies the app as Tier 2 (Smart Utility), targets college students and small business owners via Reddit Ads / Twitter / Apple Search Ads, and sets a $9.99 price point for US/EU. The document is thin -- it lists channels, targeting, and a core hook but does not include budgets, CPI/LTV targets, creative test hypotheses, or retention metrics.
- **Testing:** `docs/TEST-PLAN.md` defines a four-tier QA strategy (unit, integration, E2E, manual) and core test scenarios for capture, image processing, OCR/export, and zero-backend validation. `docs/TEST-CASES.md` provides 17 detailed step-by-step test cases covering auto-capture, manual crop, filters, offline OCR, multi-page PDF, search, deletion, low-light, crash recovery, dark mode, network audit, and data erasure.

## Code & Monetization

- **Framework mismatch:** The docs specify Expo / React Native, but the app is built with Flutter (Dart). `pubspec.yaml` confirms `docscanner_app` version 1.0.1, targeting SDK ^3.11.3.
- **Code root:** `docscanner_app/lib/` contains the Flutter project with a clean layered structure: `core/` (models, database, services, constants, theme) and `presentation/` (screens, providers, widgets).
- **Models:** Three domain models -- `Document` (id, title, pageCount, totalSizeBytes, createdAt, updatedAt, tags), `ScanPage` (id, documentId, pageNumber, imagePath, thumbnailPath, extractedText, createdAt), and `Tag` (id, name). All implement `toMap`/`fromMap` serialization, `copyWith`, and equality by id.
- **Database:** `AppDatabase` (singleton, sqflite) creates five tables -- `documents`, `pages`, `tags`, `document_tags`, and `pages_fts` (FTS5 virtual table for full-text search on extracted OCR text). Triggers keep FTS in sync on insert/update/delete. Search combines FTS results with title LIKE matching.
- **Services:**
  - `OcrService` -- uses `google_mlkit_text_recognition` for on-device OCR. Returns empty string on failure (non-fatal).
  - `PdfService` -- compiles image paths into multi-page PDF using the `pdf` package. Supports low/medium/high JPEG quality. No watermarks (FR-045). The `_compressJpeg` method is a stub -- it returns original bytes unchanged for quality < 95.
  - `FilterService` -- applies Original, B&W (grayscale + threshold at 128), Grayscale, and Color Enhance (saturation 1.4x, contrast 1.2x) using the `image` package.
  - `ThumbnailService` -- generates 200x280 JPEG thumbnails for library grid display.
- **Screens:** Six screens implemented -- `LibraryScreen` (grid/list toggle, search, tag filter, sort by date/name, delete confirmation), `CameraScreen` (scan via `cunning_document_scanner` or import from gallery, torch toggle), `ManualCropScreen` (4-corner draggable crop with perspective rectification via `img.copyRectify`), `EditScreen` (page viewer with filter bar, rotate, reorder, add/delete pages, custom title), `DocumentDetailScreen` (page list, rename, OCR bottom sheet, export as PDF or JPEG, delete), `SettingsScreen` (default export quality, cache management, version/publisher/privacy info).
- **State management:** Single `DocumentProvider` (ChangeNotifier via `provider` package) handles all CRUD, scan-save pipeline (copy images, run OCR, generate thumbnails, compile PDF), search, sort, tag management, and page reordering.
- **IAP / Ads / Subscriptions:** None. No IAP service exists, no RevenueCat integration, no ad SDK. This is correct -- the spec mandates a paid-upfront app (NFR-502, NFR-503). Revenue comes entirely from the one-time App Store / Play Store purchase price.
- **Tests:** `test/widget_test.dart` contains 10 unit tests across three groups: `Document model` (toMap/fromMap round-trip, copyWith, equality), `ScanPage model` (toMap/fromMap round-trip, null optional fields), and `FilterService` (filterLabel strings, applyFilterToBytes for original/grayscale/B&W, FilterType enum completeness). There is also a basic `PdfService` path constants test.

## Stability & Revenue Risks

1. **Architecture doc / code mismatch:** `ARCHITECTURE.md` describes an Expo/React Native stack with React Navigation, VisionCamera, and expo-sqlite. The actual app is Flutter with sqflite, cunning_document_scanner, and google_mlkit_text_recognition. Anyone reading the docs will get the wrong picture of the codebase. This should be corrected before onboarding contributors or conducting further reviews.
2. **JPEG compression stub:** `PdfService._compressJpeg` returns input bytes unchanged for quality < 95 (all presets). The "Low" and "Medium" export quality settings produce the same file size as "High". This undermines the export quality picker in Settings and the FR-044 requirement.
3. **No integration or E2E tests:** The test suite covers model serialization and filter label logic, but there are no tests for the database layer (AppDatabase CRUD, FTS search), the scan-save pipeline (DocumentProvider.saveScannedPages), PDF compilation, or any widget/screen tests. The TEST-PLAN.md calls for integration and E2E tests that do not exist yet.
4. **Marketing doc is incomplete:** `MARKETING.md` is four sections and 10 lines. It names channels and a price point but has no budgets, CPI vs. LTV expectations, creative test plans, retention benchmarks, or geographic rollout timeline. Scaling paid UA without these guardrails risks unprofitable spend.
5. **No crash recovery for batch scans:** The spec (NFR-302) and test cases (TC-116) require that pages captured before an app crash are recoverable. The current `DocumentProvider.saveScannedPages` copies images to permanent storage only at save time. If the app crashes during the camera/edit flow, temporary files from `cunning_document_scanner` are lost with no recovery mechanism.
6. **Rotation and filters not persisted to saved files:** `EditScreen` applies rotation (`RotatedBox`) and filter (`filteredBytes`) in the UI only. When `_save()` runs, it writes `page.originalPath` to the final paths list, discarding any rotation or filter the user applied. The saved document will not reflect the user's edits.
7. **No "Clear All Data" implementation:** The Settings screen only clears the thumbnail cache. TEST-CASES.md TC-302 expects a "Clear All Data" function that wipes all documents, images, PDFs, and the SQLite database. This does not exist.

## Next Steps

1. **Fix the architecture doc** to reflect the actual Flutter / sqflite / cunning_document_scanner / google_mlkit stack, or migrate the code to match the spec. The mismatch is the single biggest documentation-level issue.
2. **Implement real JPEG compression** in `PdfService._compressJpeg` so that Low/Medium/High export quality settings produce meaningfully different file sizes (use the `image` package to decode and re-encode at the target quality).
3. **Persist rotation and filter edits** in `EditScreen._save()` -- write the rotated/filtered bytes to disk instead of the original path, so the saved document matches what the user saw in the editor.
4. **Add database and provider tests** -- at minimum, test `AppDatabase` CRUD operations, FTS search behavior, and the `DocumentProvider.saveScannedPages` pipeline using mock file paths.
5. **Implement batch scan crash recovery** (NFR-302) -- save captured images to a known recovery directory immediately on capture, then clean up on successful save or offer recovery on next launch.
6. **Add "Clear All Data" to Settings** -- wipe the `scans/`, `pdfs/`, and `thumbnails/` directories plus all SQLite tables, matching TC-302.
7. **Expand `MARKETING.md`** with explicit budgets, CPI/LTV thresholds, creative test plans, and retention metrics so UA spend can be evaluated and scaled.
