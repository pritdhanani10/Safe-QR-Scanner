import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/security/content_parser.dart';
import '../../core/security/risk_engine.dart';
import '../../core/theme/app_theme.dart';
import '../../models/scan_record.dart';
import '../history/history_repository.dart';
import '../result/result_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  late MobileScannerController _scannerController;
  late AnimationController _laserAnimController;
  final ImagePicker _imagePicker = ImagePicker();

  bool _isProcessing = false;
  bool _isTorchOn = false;
  CameraFacing _cameraFacing = CameraFacing.back;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: _cameraFacing,
      torchEnabled: false,
    );

    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserAnimController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.trim().isNotEmpty) {
        _handleDecodedPayload(raw.trim());
        break;
      }
    }
  }

  Future<void> _handleDecodedPayload(String raw) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final parsed = ContentParser.parse(raw);
      final security = RiskEngine.evaluate(
        type: parsed.type,
        rawContent: raw,
        metadata: parsed.metadata,
      );

      final record = ScanRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        rawContent: raw,
        type: parsed.type,
        title: parsed.title,
        subtitle: parsed.subtitle,
        timestamp: DateTime.now(),
        securityResult: security,
        metadata: parsed.metadata,
      );

      // Persist in local offline history
      await HistoryRepository().saveScan(record);

      if (!mounted) return;

      // Navigate to detailed security inspection screen
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultScreen(record: record),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final barcodeCapture = await _scannerController.analyzeImage(pickedFile.path);
      if (barcodeCapture != null && barcodeCapture.barcodes.isNotEmpty) {
        final raw = barcodeCapture.barcodes.first.rawValue;
        if (raw != null && raw.isNotEmpty) {
          await _handleDecodedPayload(raw);
          return;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No QR code detected in selected image.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not scan image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Live Camera Viewfinder
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
              errorBuilder: (context, error) {
                return _buildCameraFallback(error.toString());
              },
            ),
          ),

          // 2. Dark Overlay & Scanning Frame
          Positioned.fill(
            child: _buildScannerOverlay(),
          ),

          // 3. Header Top Bar with Brand and Controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Brand badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.surfaceBorder),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_rounded, size: 16, color: AppTheme.primary),
                          SizedBox(width: 8),
                          Text(
                            'Safe QR',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Torch Button
                    _buildRoundIconButton(
                      icon: _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      isActive: _isTorchOn,
                      onTap: () async {
                        await _scannerController.toggleTorch();
                        setState(() => _isTorchOn = !_isTorchOn);
                      },
                    ),
                    const SizedBox(width: 10),
                    // Camera Switch Button
                    _buildRoundIconButton(
                      icon: Icons.flip_camera_ios_rounded,
                      onTap: () async {
                        await _scannerController.switchCamera();
                        setState(() {
                          _cameraFacing = _cameraFacing == CameraFacing.back
                              ? CameraFacing.front
                              : CameraFacing.back;
                        });
                      },
                    ),
                    const SizedBox(width: 10),
                    // Pick from Gallery
                    _buildRoundIconButton(
                      icon: Icons.photo_library_outlined,
                      onTap: _pickImageFromGallery,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Bottom Philosophy Banner & Test Simulator Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Philosophy Tagline
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.security, size: 14, color: AppTheme.primaryLight),
                          SizedBox(width: 8),
                          Text(
                            'Scan first. Trust later.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryLight,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Quick Test Simulator Button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.surfaceElevated.withOpacity(0.95),
                          foregroundColor: AppTheme.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: AppTheme.primary, width: 1.2),
                          ),
                        ),
                        icon: const Icon(Icons.bug_report_outlined, size: 18, color: AppTheme.primary),
                        label: const Text(
                          'Test Payloads & Simulator',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        onPressed: _openSimulatorModal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSize = constraints.maxWidth * 0.72;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Dark vignette around target
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.55),
                BlendMode.srcOut,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Center(
                    child: Container(
                      height: boxSize,
                      width: boxSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Reticle Border Frame
            Container(
              width: boxSize,
              height: boxSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.primary.withOpacity(0.6),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  // Corner accent marks
                  ..._buildCorners(),
                  // Animated glowing laser line
                  AnimatedBuilder(
                    animation: _laserAnimController,
                    builder: (context, child) {
                      return Positioned(
                        top: (boxSize - 10) * _laserAnimController.value,
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.8),
                                blurRadius: 10,
                                spreadRadius: 3,
                              ),
                            ],
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppTheme.primaryLight,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildCorners() {
    const size = 20.0;
    const thickness = 3.5;
    const radius = 24.0;
    const color = AppTheme.primary;

    return [
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: thickness),
              left: BorderSide(color: color, width: thickness),
            ),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(radius)),
          ),
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: thickness),
              right: BorderSide(color: color, width: thickness),
            ),
            borderRadius: BorderRadius.only(topRight: Radius.circular(radius)),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: thickness),
              left: BorderSide(color: color, width: thickness),
            ),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(radius)),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: thickness),
              right: BorderSide(color: color, width: thickness),
            ),
            borderRadius: BorderRadius.only(bottomRight: Radius.circular(radius)),
          ),
        ),
      ),
    ];
  }

  Widget _buildCameraFallback(String error) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_outlined, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            const Text(
              'Camera Preview Not Active',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Running on Desktop/Simulator without camera access? Use the Test Simulator below or pick an image to test.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              icon: const Icon(Icons.bug_report, color: Colors.black),
              label: const Text('Launch Simulator', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
              onPressed: _openSimulatorModal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : AppTheme.surface.withOpacity(0.85),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? AppTheme.primaryLight : AppTheme.surfaceBorder,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? const Color(0xFF001E28) : AppTheme.textPrimary,
        ),
      ),
    );
  }

  void _openSimulatorModal() {
    final customTextCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.science_outlined, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'QR PAYLOAD SIMULATOR',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppTheme.primary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Select a preset threat/payload to test how Safe QR Scanner analyzes risks before opening:',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),

                // Custom Input Box
                TextField(
                  controller: customTextCtrl,
                  decoration: InputDecoration(
                    hintText: 'Or paste custom URL or QR text...',
                    hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: AppTheme.surfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, color: AppTheme.primary),
                      onPressed: () {
                        if (customTextCtrl.text.trim().isNotEmpty) {
                          Navigator.of(ctx).pop();
                          _handleDecodedPayload(customTextCtrl.text.trim());
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text('TEST CASES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
                const SizedBox(height: 10),

                _buildPresetItem(
                  ctx: ctx,
                  tag: 'CRITICAL',
                  tagColor: AppTheme.riskCritical,
                  title: 'Phishing: Bank Urgent Verify',
                  subtitle: 'http://bank-account-urgent-verify.xyz/login',
                  payload: 'http://bank-account-urgent-verify.xyz/login',
                ),
                _buildPresetItem(
                  ctx: ctx,
                  tag: 'CRITICAL',
                  tagColor: AppTheme.riskCritical,
                  title: 'UPI Scam: Fake KYC Refund',
                  subtitle: 'upi://pay?pa=fraudster@upi&pn=SBI%20KYC&am=25000&tn=KYC%20Refund%20Reward',
                  payload: 'upi://pay?pa=fraudster@upi&pn=SBI%20KYC&am=25000&tn=KYC%20Refund%20Reward',
                ),
                _buildPresetItem(
                  ctx: ctx,
                  tag: 'HIGH',
                  tagColor: AppTheme.riskHigh,
                  title: 'Typosquatting / Look-alike Brand',
                  subtitle: 'https://paypa1-security-check.com/signin',
                  payload: 'https://paypa1-security-check.com/signin',
                ),
                _buildPresetItem(
                  ctx: ctx,
                  tag: 'HIGH',
                  tagColor: AppTheme.riskHigh,
                  title: 'Raw IP Address Host',
                  subtitle: 'http://192.168.1.105:8080/admin/reset',
                  payload: 'http://192.168.1.105:8080/admin/reset',
                ),
                _buildPresetItem(
                  ctx: ctx,
                  tag: 'MEDIUM',
                  tagColor: AppTheme.riskMedium,
                  title: 'URL Shortener (Masked Destination)',
                  subtitle: 'https://bit.ly/secure-account-update',
                  payload: 'https://bit.ly/secure-account-update',
                ),
                _buildPresetItem(
                  ctx: ctx,
                  tag: 'MEDIUM',
                  tagColor: AppTheme.riskMedium,
                  title: 'Valid UPI Merchant Payment',
                  subtitle: 'upi://pay?pa=grocery@okaxis&pn=Daily%20Store&am=350&cu=INR&tn=Invoice%20492',
                  payload: 'upi://pay?pa=grocery@okaxis&pn=Daily%20Store&am=350&cu=INR&tn=Invoice%20492',
                ),
                _buildPresetItem(
                  ctx: ctx,
                  tag: 'LOW',
                  tagColor: AppTheme.riskLow,
                  title: 'Safe Official URL',
                  subtitle: 'https://flutter.dev/development',
                  payload: 'https://flutter.dev/development',
                ),
                _buildPresetItem(
                  ctx: ctx,
                  tag: 'LOW',
                  tagColor: AppTheme.riskLow,
                  title: 'Wi-Fi Network Credentials',
                  subtitle: 'WIFI:S:CyberSecurity_HQ;T:WPA;P:SuperSafePass99;;',
                  payload: 'WIFI:S:CyberSecurity_HQ;T:WPA;P:SuperSafePass99;;',
                ),
                _buildPresetItem(
                  ctx: ctx,
                  tag: 'LOW',
                  tagColor: AppTheme.riskLow,
                  title: 'Contact Card (vCard)',
                  subtitle: 'BEGIN:VCARD\nFN:Agent Smith\nTEL:+919876543210\nORG:Safe QR\nEND:VCARD',
                  payload: 'BEGIN:VCARD\nFN:Agent Smith\nTEL:+919876543210\nORG:Safe QR\nEND:VCARD',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPresetItem({
    required BuildContext ctx,
    required String tag,
    required Color tagColor,
    required String title,
    required String subtitle,
    required String payload,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          dense: true,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: tagColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: tagColor),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppTheme.textMuted),
          onTap: () {
            Navigator.of(ctx).pop();
            _handleDecodedPayload(payload);
          },
        ),
      ),
    );
  }
}
