import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:zxing2/qrcode.dart';
import '../services/qr_service.dart';
import 'send_screen.dart';

class QRScannerScreen extends StatefulWidget {
  final Function(String)? onQRScanned;
  
  const QRScannerScreen({super.key, this.onQRScanned});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}


class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  String? _statusText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        title: const Text(
          'Scan QR Code',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              await _controller.toggleTorch();
              setState(() {});
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.flash_on,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    if (_isProcessing) return;
                    final barcodes = capture.barcodes;
                    if (barcodes.isEmpty) return;
                    final val = barcodes.first.rawValue;
                    if (val != null && val.isNotEmpty) {
                      _processQRCode(val);
                    }
                  },
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.blue),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Point your camera at a QR code',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusText ?? 'Position the QR code within the frame to scan',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickImageFromGallery,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Upload QR'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _manualEntry(context),
                          icon: const Icon(Icons.keyboard),
                          label: const Text('Manual Entry'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processQRCode(String qrData) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
      _statusText = 'Processing QR code...';
    });

    try {
      // Parse UPI QR code
      final upiData = QRService.parseUpiQRData(qrData);
      
      if (upiData.isEmpty) {
        throw Exception('Invalid QR code format');
      }

      final upiId = upiData['upiId'];
      if (upiId == null || upiId.isEmpty) {
        throw Exception('UPI ID not found in QR code');
      }

      // Basic UPI format validation
      if (!_isValidUpiFormat(upiId)) {
        throw Exception('Invalid UPI ID format');
      }

      // Stop camera while navigating
      await _controller.stop();

      if (widget.onQRScanned != null) {
        // Return scanned raw data to parent (so it can parse extra fields too)
        widget.onQRScanned!(qrData);
        if (mounted) Navigator.pop(context);
      } else {
        // Navigate to send screen with pre-filled data
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SendScreen(
              prefilledUpiId: upiId,
              prefilledAmount: upiData['amount'],
              prefilledNote: upiData['note'],
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusText = 'Error: ${e.toString()}';
        _isProcessing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR Scan Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Restart scanner after short delay
      Future.delayed(const Duration(seconds: 1), () async {
        if (!mounted) return;
        setState(() => _statusText = null);
        await _controller.start();
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
      if (res == null || res.files.isEmpty) return;

      setState(() {
        _isProcessing = true;
        _statusText = 'Reading QR code from image...';
      });

      final bytes = res.files.first.bytes;
      if (bytes == null) throw Exception('Could not read image bytes');

      // Decode image and then QR using zxing2
      final decodedImg = img.decodeImage(bytes);
      if (decodedImg == null) throw Exception('Unsupported image');

      // Convert image to grayscale for better QR detection
      final grayscale = img.grayscale(decodedImg);
      final pixelBytes = grayscale.getBytes();
      
      // Simple QR code detection for web platform
      // For now, we'll show a helpful message and allow manual entry
      setState(() {
        _statusText = 'Image QR scanning is not fully supported on web. Please use camera or manual entry.';
        _isProcessing = false;
      });
      
      // Show manual entry dialog as fallback
      _manualEntry(context);
      return;
    } catch (e) {
      setState(() {
        _statusText = 'Error reading image: ${e.toString()}';
        _isProcessing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _manualEntry(BuildContext context) {
    final TextEditingController upiController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter UPI ID'),
        content: TextField(
          controller: upiController,
          decoration: const InputDecoration(
            labelText: 'UPI ID',
            hintText: 'e.g., user@paytm',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final upiId = upiController.text.trim();
              if (upiId.isNotEmpty) {
                Navigator.pop(context);
                if (widget.onQRScanned != null) {
                  widget.onQRScanned!(upiId);
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SendScreen(prefilledUpiId: upiId),
                    ),
                  );
                }
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isValidUpiFormat(String upiId) {
    if (upiId.isEmpty) return false;

    // Must contain exactly one @ symbol
    final parts = upiId.split('@');
    if (parts.length != 2) return false;

    final username = parts[0];
    final provider = parts[1];

    // Username should not be empty and should be alphanumeric
    if (username.isEmpty || !RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(username)) {
      return false;
    }

    // Provider should not be empty
    if (provider.isEmpty) return false;

    return true;
  }
}
