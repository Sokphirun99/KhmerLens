import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isFlashOn = false;
  late AnimationController _animController;
  final List<String> _capturedImages = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        _showError('No camera found');
        return;
      }

      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() => _isInitialized = true);
        _animController.forward();
      }
    } catch (e) {
      _showError('Camera error: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    // Animate button
    await _animController.reverse();
    await _animController.forward();

    try {
      final XFile image = await _controller!.takePicture();

      if (mounted) {
        HapticFeedback.mediumImpact();
        setState(() {
          _capturedImages.add(image.path);
        });

        // Show snackbar with option to finish
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('រូបភាពទី ${_capturedImages.length} ត្រូវបានថតរួច'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'បញ្ចប់',
              onPressed: () => _finishCapture(),
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to capture: $e');
    }
  }

  void _finishCapture() {
    if (_capturedImages.isEmpty) {
      context.pop();
    } else {
      context.pop(_capturedImages);
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;

    try {
      if (_isFlashOn) {
        await _controller!.setFlashMode(FlashMode.off);
      } else {
        await _controller!.setFlashMode(FlashMode.torch);
      }
      setState(() => _isFlashOn = !_isFlashOn);
    } catch (e) {
      debugPrint('Flash error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/camera_loading.json',
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 16),
              const Text(
                'កំពុងចាប់ផ្តើមកាមេរ៉ា...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          // Document guide overlay
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Top instruction
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'រៀបចំឯកសារក្នុងក្របនេះ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  // Corner markers
                  ..._buildCornerMarkers(),
                ],
              ),
            ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                  duration: 2000.ms,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTopButton(
                      Icons.close,
                      () => context.pop(),
                      tooltip: 'បិទ',
                    ),
                    Row(
                      children: [
                        // Image counter badge
                        if (_capturedImages.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_capturedImages.length} រូប',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        _buildTopButton(
                          _isFlashOn ? Icons.flash_on : Icons.flash_off,
                          _toggleFlash,
                          tooltip: _isFlashOn ? 'បិទភ្លើង' : 'បើកភ្លើង',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Image preview strip (above bottom controls)
          if (_capturedImages.isNotEmpty)
            Positioned(
              bottom: 140,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _capturedImages.length,
                  itemBuilder: (context, index) {
                    return _buildImagePreview(_capturedImages[index], index);
                  },
                ),
              ).animate().fadeIn().slideY(begin: 0.2, end: 0),
            ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery button - multi-select
                    _buildControlButton(
                      Icons.photo_library,
                      () async {
                        final ImagePicker picker = ImagePicker();
                        final List<XFile> images = await picker.pickMultiImage();
                        if (images.isNotEmpty && context.mounted) {
                          HapticFeedback.lightImpact();
                          final imagePaths = images.map((img) => img.path).toList();
                          context.pop(imagePaths);
                        }
                      },
                      tooltip: 'ជ្រើសរូបពីវិចិត្រសាល',
                    ),

                    // Capture button with animation
                    ScaleTransition(
                      scale: Tween<double>(begin: 1.0, end: 0.9).animate(
                        CurvedAnimation(
                          parent: _animController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: GestureDetector(
                        onTap: _takePicture,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Done button (visible when images captured)
                    if (_capturedImages.isNotEmpty)
                      _buildControlButton(
                        Icons.check,
                        _finishCapture,
                        tooltip: 'បញ្ចប់',
                      )
                    else
                      const SizedBox(width: 56), // Spacer for symmetry
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopButton(IconData icon, VoidCallback onPressed, {String? tooltip}) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 28),
          onPressed: onPressed,
          tooltip: tooltip,
        ),
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed, {String? tooltip}) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 28),
          onPressed: onPressed,
          tooltip: tooltip,
        ),
      ),
    );
  }

  List<Widget> _buildCornerMarkers() {
    return [
      // Top-left
      Positioned(
        top: 16,
        left: 16,
        child: _buildCorner(true, true),
      ),
      // Top-right
      Positioned(
        top: 16,
        right: 16,
        child: _buildCorner(true, false),
      ),
      // Bottom-left
      Positioned(
        bottom: 16,
        left: 16,
        child: _buildCorner(false, true),
      ),
      // Bottom-right
      Positioned(
        bottom: 16,
        right: 16,
        child: _buildCorner(false, false),
      ),
    ];
  }

  Widget _buildCorner(bool isTop, bool isLeft) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildImagePreview(String imagePath, int index) {
    return Container(
      width: 60,
      height: 80,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: [
            // Thumbnail image
            Positioned.fill(
              child: Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade800,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.white54,
                      size: 24,
                    ),
                  );
                },
              ),
            ),
            // Image number badge
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Delete button (optional - on long press)
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _capturedImages.removeAt(index);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('រូបភាពត្រូវបានលុបចេញ'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
