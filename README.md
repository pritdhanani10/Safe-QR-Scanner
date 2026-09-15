# Safe QR Scanner 🛡️

> **"Scan first. Trust later."**

A security-focused, privacy-first QR code scanner built with Flutter that protects users from malicious URLs, phishing attacks, look-alike domains, and deceptive payment requests.

---

## 🔐 Core Philosophy: Never Trust Automatically

Standard QR scanners immediately open scanned URLs in the browser or launch payment apps without inspection. Attackers abuse this by embedding shortened URLs, homograph/punycode links, or fraudulent payment notes.

**Safe QR Scanner** breaks this chain:

```
Scan QR → Detect Content → Analyze Risk Offline → Show Transparency Preview → User Decides
```

No link is ever launched automatically. Every payload is parsed, tested against static risk heuristics, and previewed with full technical details.

---

## 🚀 Key Features

### 🛡️ URL Threat & Phishing Detection
- **HTTPS Enforcement**: Flags unencrypted cleartext HTTP connections.
- **Direct IP Address URLs**: Detects and heavily penalizes raw IP targets (e.g. `http://192.168.1.100/login`).
- **Homograph & Brand Typosquatting**: Unmasks character substitution attacks (e.g., `paypa1-security.com`, `goog1e`) and Punycode (`xn--`).
- **URL Shortener Detection**: Warns when services like `bit.ly`, `tinyurl.com`, and `t.co` conceal the actual destination.
- **Phishing & Urgency Keywords**: Identifies sensitive keywords (`login`, `verify`, `account`, `bank`, `kyc`, `refund`, `urgent`) within unverified domains.

### 💳 UPI QR Protection (Indian Banking Security)
- **Parameter Inspection**: Decodes Payee Name (`pn`), UPI ID/VPA (`pa`), Amount (`am`), Transaction Note (`tn`), and Merchant Code (`mc`).
- **Scam Note Detection**: Flags deceptive transaction notes designed to mislead users into authorizing payments (e.g. *"KYC verification refund"*, *"Lottery prize tax"*).
- **Security Rule Advisory**: Clear disclaimers reminding users that entering a UPI PIN **always debits** money and is never required to receive money or refunds.
- **Structure vs. Trust Disclaimer**: Clearly emphasizes that valid UPI structure does not prove payee trustworthiness.

### 📋 Full Payload & Type Previews
- **Multi-Format Support**: Web URLs, UPI Payments, Wi-Fi Networks, Contact Cards (vCard), Email (`mailto:`), Phone (`tel:`), SMS, and Plain Text.
- **Wi-Fi Inspector**: Parses SSID, encryption protocol (WPA/WPA2/WEP/Open), with show/hide password toggle.
- **Raw Decoded Payload**: Viewable at any time with 1-tap copy and share functionality.

### 📜 Offline Scan History
- **Zero-Cloud Storage**: 100% locally stored on your device with no remote servers or telemetry.
- **Grouped Timeline**: Displays scans organized under *Today*, *Yesterday*, and *Earlier*.
- **Filters & Search**: Fast filtering by URLs, UPI payments, and high-risk scans.
- **Privacy Controls**: Individual deletion and 1-tap complete history wipe.

### 🧪 Built-in Threat Simulator
- Includes an interactive preset drawer with 9 realistic scenarios (Bank Phishing, Fake KYC UPI Scam, URL Shorteners, Official HTTPS URLs, Wi-Fi credentials, vCard) for immediate demonstration and testing.

---

## 🎨 Design System

- **Cyber-Defense Dark Palette**: High-contrast obsidian canvas (`#0A0E17`) with glowing neon accents.
- **Dynamic Risk Gauge**: Numerical score (0–100) paired with color-coded risk levels:
  - 🟢 **LOW RISK** (80–100): Valid structure and no risk signals identified.
  - 🟡 **MEDIUM RISK** (50–79): Shortener or minor anomaly detected. Caution advised.
  - 🟠 **HIGH RISK** (25–49): Potentially unsafe. Phishing keywords or suspicious domain.
  - 🔴 **CRITICAL RISK** (0–24): High probability malicious. "Don't Open" recommended.

---

## 🏗️ Project Architecture

```
lib/
├── main.dart                              # Application root, theme, navigation
├── core/
│   ├── constants/
│   │   └── security_rules.dart            # Phishing keywords, shorteners, dangerous TLDs
│   ├── theme/
│   │   └── app_theme.dart                 # Dark cybersecurity design system
│   ├── utils/
│   │   └── date_helpers.dart              # Grouping scans into Today, Yesterday, Earlier
│   └── security/
│       ├── content_parser.dart            # Classifies QR format (URL, UPI, Wi-Fi, etc.)
│       ├── url_analyzer.dart              # Protocol, IP, shortener, and typosquatting inspection
│       ├── upi_analyzer.dart              # UPI VPA syntax, fraud note triggers, and advisories
│       └── risk_engine.dart               # Unified risk scoring (0-100) and risk level classification
├── features/
│   ├── scanner/
│   │   └── scanner_screen.dart            # Camera viewfinder, laser reticle, simulator quick-bar
│   ├── result/
│   │   ├── result_screen.dart             # Risk banner, score meter, safety checklist, actions
│   │   └── widgets/
│   │       ├── risk_badge.dart            # Circular gauge & risk level badge
│   │       ├── security_checklist.dart    # Itemized pass/warn/fail check audit
│   │       ├── upi_details_card.dart      # Payee, VPA, ₹ amount, note & fraud warning
│   │       └── parsed_content_card.dart   # Wi-Fi, vCard, URL breakdown
│   ├── history/
│   │   ├── history_screen.dart            # Grouped scan history, filters, search
│   │   └── history_repository.dart        # 100% offline local persistence
│   └── settings/
│       └── settings_screen.dart           # Sensitivity settings and privacy manifesto
└── models/
    ├── qr_type.dart                       # QR content types enum
    ├── security_result.dart               # Risk level, score, and checklist items
    └── scan_record.dart                   # Local storage scan model
```

---

## 🛠️ Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.24+ recommended)
- Android Studio / VS Code / Xcode

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/pritdhanani10/Safe-QR-Scanner.git
   cd Safe-QR-Scanner
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the automated test suite:
   ```bash
   flutter test
   ```

4. Launch the application:
   ```bash
   flutter run
   ```

---

## 🔒 Privacy Guarantee

- **No Remote Telemetry**: Camera frames and QR payloads are processed exclusively in device memory.
- **Zero Server Communication**: The static risk analysis engine runs completely offline.
- **Local History**: Scan logs remain on device and can be erased at any time in Settings.

---

## 📄 License

This project is licensed under the MIT License.
