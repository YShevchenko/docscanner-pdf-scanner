# PDF Scanner Non-Functional Requirements

**Document:** NON-FUNCTIONAL-REQUIREMENTS.md  
**Product:** PDF Scanner & Document Tool  
**Publisher:** Heldig Lab  
**Source of Truth:** [SPEC.md](./SPEC.md)  
**Related Documents:** [ARCHITECTURE.md](./ARCHITECTURE.md), [REQUIREMENTS.md](./REQUIREMENTS.md)

## Purpose

This document defines the quality attributes, constraints, and operational standards for the PDF Scanner. It strictly enforces the "One Price Forever" and "Zero Backend" principles.

---

## 1. Privacy & Security (NFR-100)

| ID | Requirement | Metric / Standard |
|---|---|---|
| NFR-101 | **Zero-Knowledge Architecture** | No document images, extracted text (OCR), or metadata shall be transmitted to Heldig Lab or any 3rd party analytics provider. |
| NFR-102 | **No Identity Anchor** | The system shall not require email, phone, or social login. The app is completely anonymous. |
| NFR-103 | **Data At Rest** | The local SQLite database and file system shall be stored in the app's protected sandbox directory. |
| NFR-104 | **Permissions** | The app shall only request Camera permission when the user taps "Scan". Photos permission is only requested if importing an existing image. |

## 2. Performance & Efficiency (NFR-200)

| ID | Requirement | Metric / Standard |
|---|---|---|
| NFR-201 | **Cold Start Time** | App shall reach the interactable Library dashboard in < 1.0 second. |
| NFR-202 | **Scanner Frame Rate** | The camera viewfinder and real-time edge detection polygon shall maintain >= 30 fps to ensure a smooth, professional feel. |
| NFR-203 | **Capture Latency** | From shutter press to the preview thumbnail appearing shall take < 400ms. |
| NFR-204 | **OCR Speed** | Extracting text from a standard A4 page shall complete in < 2.5 seconds on-device. |
| NFR-205 | **Storage Efficiency** | Original high-res captures are compressed before saving to the FileSystem to prevent the app from bloating device storage. |

## 3. Reliability & Availability (NFR-300)

| ID | Requirement | Metric / Standard |
|---|---|---|
| NFR-301 | **Offline Autonomy** | 100% of the application's core tracking logic (Scanning, Cropping, OCR, PDF Export) must remain functional without an internet connection. |
| NFR-302 | **Crash Recovery** | If the app crashes during a multi-page scan, the temporary pages captured so far must be recovered upon the next app launch. |

## 4. Usability & Accessibility (NFR-400)

| ID | Requirement | Metric / Standard |
|---|---|---|
| NFR-401 | **Calm UX** | The interface shall be free of gamification, "rate this app" popups during tasks, and urgency indicators. |
| NFR-402 | **Dark Mode** | The app shall support a native system Dark Mode. |
| NFR-403 | **Haptic Feedback** | Subtle haptic confirmation shall occur upon automatic edge detection capture. |

## 5. Monetization Constraint (NFR-500)

| ID | Requirement | Metric / Standard |
|---|---|---|
| NFR-501 | **One-Time Paid App** | The app shall be configured as a Paid App in the App Store/Play Store. |
| NFR-502 | **No IAP** | No In-App Purchases, subscriptions, or RevenueCat integrations shall exist in the codebase. |
| NFR-503 | **No Ads** | No ad SDKs (AdMob, Google Mobile Ads) shall be included in the binary. |
