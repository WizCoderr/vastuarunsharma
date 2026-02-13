import 'dart:async';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:camera/camera.dart'; // Added camera package
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../widgets/compass/compass_dial.dart';
import '../../../widgets/compass/compass_control_button.dart';
import '../../../widgets/compass/compass_bottom_action.dart';

class CompassScreen extends StatefulWidget {
  const CompassScreen({super.key});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen>
    with WidgetsBindingObserver {
  double? _heading;
  StreamSubscription<CompassEvent>? _compassSubscription;
  String _latitude = "0.0";
  String _longitude = "0.0";
  String _statusMessage = "";

  // Map related
  bool _showMap = false;
  GoogleMapController? _mapController;
  LatLng _currentLatLng = const LatLng(0, 0);

  // Camera related
  CameraController? _cameraController;
  bool _showCamera = false;
  String _cameraError = "";
  List<CameraDescription> _cameras = [];

  // Screenshot & UI
  final ScreenshotController _screenshotController = ScreenshotController();
  Offset? _compassOffset;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCompass();
    _initLocation();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) setState(() => _cameraError = "No cameras found");
        return;
      }

      // Initialize the first camera (rear)
      final camera = _cameras.first;
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium, // Lower resolution for better compatibility
        enableAudio: false,
      );

      await _cameraController?.initialize();
      if (mounted) setState(() => _cameraError = "");
    } on CameraException catch (e) {
      debugPrint("Camera Error: ${e.code} - ${e.description}");
      if (mounted) {
        setState(
          () =>
              _cameraError = "Camera Error: ${e.code}\n${e.description ?? ''}",
        );
      }
    } catch (e) {
      debugPrint("Error initializing camera: $e");
      if (mounted) {
        setState(() => _cameraError = "Error: $e");
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _onNewCameraSelected(cameraController.description);
    }
  }

  void _onNewCameraSelected(CameraDescription cameraDescription) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _cameraController = cameraController;

    try {
      await cameraController.initialize();
      if (mounted) setState(() => _cameraError = "");
    } on CameraException catch (e) {
      if (mounted) {
        setState(() => _cameraError = "Camera Error: ${e.code}");
      }
    }
  }

  void _initCompass() {
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (mounted) {
        setState(() {
          _heading = event.heading;
        });
      }
    });
  }

  // ... existing _initLocation code ...
  Future<void> _initLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() => _statusMessage = "Location services disabled");
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() => _statusMessage = "Location permission denied");
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(
          () => _statusMessage = "Location permission permanently denied",
        );
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _latitude = position.latitude.toStringAsFixed(7);
          _longitude = position.longitude.toStringAsFixed(7);
          _currentLatLng = LatLng(position.latitude, position.longitude);
        });

        // Update map camera if map is already created
        if (_mapController != null && _showMap) {
          _mapController!.animateCamera(CameraUpdate.newLatLng(_currentLatLng));
        }
      }
    } catch (e) {
      if (mounted) setState(() => _statusMessage = "Error getting location");
    }
  }

  void _toggleMap() {
    setState(() {
      _showMap = !_showMap;
      if (_showMap) {
        _showCamera = false; // Turn off camera if map is on
      }
    });
  }

  void _toggleCamera() {
    setState(() {
      _showCamera = !_showCamera;
      if (_showCamera) {
        _showMap = false; // Turn off map if camera is on
        // Retry initialization if we have an error or it's not initialized
        if (_cameraError.isNotEmpty ||
            _cameraController == null ||
            !_cameraController!.value.isInitialized) {
          _initCamera();
        }
      }
    });
  }

  Future<void> _captureScreenshot() async {
    try {
      bool hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      final Uint8List? image = await _screenshotController.capture();
      if (image != null) {
        // defined unique name
        final String fileName =
            "compass_capture_${DateTime.now().millisecondsSinceEpoch}.png";

        // Save to temporary file for passing to next screen
        final directory = await getTemporaryDirectory();
        final File file = File('${directory.path}/$fileName');
        await file.writeAsBytes(image);

        // Also save to gallery as requested previously, or keep it optional?
        // User said "open a new page", but "capture" usually implies saving too.
        // Let's keep gallery save for safety/utility.
        await Gal.putImageBytes(image, name: fileName);

        if (mounted) {
          context.push(
            RouteConstants.compassResult,
            extra: {'imagePath': file.path},
          );
        }
      }
    } on GalException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving screenshot: ${e.type.message}")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error capturing screenshot: $e")),
        );
      }
    }
  }

  Future<void> _openGallery() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Selected: ${pickedFile.name}")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Could not open gallery")));
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _compassSubscription?.cancel();
    _mapController?.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If heading is null, we can show a loader or waiting message
    // default to 0 if null for UI rendering
    final double displayHeading = _heading ?? 0.0;

    // Initial position calculation (center of screen)
    // We use MediaQuery to get screen size.
    // If offset is null, center it.
    final screenSize = MediaQuery.of(context).size;

    // Compass dimensions (300x300 as defined in CompassDial)
    const double compassSize = 300.0;

    // Initialize position if not set
    _compassOffset ??= Offset(
      (screenSize.width - compassSize) / 2,
      (screenSize.height - compassSize) / 2,
    );

    // Determine if we are in "background mode" (Camera or Map) to adjust UI contrast
    final bool isBackgroundMode = _showMap || _showCamera;

    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Layer 0: Camera Preview (if toggled)
            if (_showCamera)
              SizedBox.expand(
                child: _cameraError.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _cameraError,
                            style: const TextStyle(
                              color: Colors.red,
                              backgroundColor: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                    : (_cameraController != null &&
                          _cameraController!.value.isInitialized)
                    ? CameraPreview(_cameraController!)
                    : const Center(child: CircularProgressIndicator()),
              ),

            // Layer 1: Google Map (only visible if toggled)
            if (_showMap)
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentLatLng,
                  zoom: 19.0, // Increased zoom for better detail
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled:
                    false, // Disable default controls to use custom ones
                compassEnabled: false,
                mapType: MapType
                    .hybrid, // Hybrid to match screenshot looks (Satellite + Labels)
                onMapCreated: (controller) {
                  _mapController = controller;
                  // If we have a location, ensure we move to it
                  if (_currentLatLng.latitude != 0 &&
                      _currentLatLng.longitude != 0) {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLng(_currentLatLng),
                    );
                  }
                },
              ),

            // Layer 1.5: Crosshairs (only if map or camera is shown)
            if (_showMap || _showCamera)
              Positioned.fill(child: CustomPaint(painter: CrosshairPainter())),

            // Layer 2: UI Overlay (Fixed Elements)
            SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      SizedBox(height: 20),
                      // Top Controls
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 10.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CompassControlButton(
                              icon: _showMap
                                  ? Icons.layers_clear
                                  : Icons.location_on_outlined,
                              label: _showMap ? "Hide Map" : "Google map",
                              onTap: _toggleMap,
                            ),
                            const Spacer(),
                            CompassControlButton(
                              icon: _showCamera
                                  ? Icons.camera_alt
                                  : Icons.camera_alt_outlined,
                              label: _showCamera
                                  ? "Hide Camera"
                                  : "Rear Camera",
                              onTap: _toggleCamera,
                            ),
                          ],
                        ),
                      ),

                      // Degree Display
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Column(
                          children: [
                            Text(
                              "${displayHeading.toStringAsFixed(0)}° Degree",
                              style: const TextStyle(
                                fontSize: 28, // Larger
                                fontWeight: FontWeight.bold,
                                color: Colors.red, // Red as per screenshot
                                shadows: [
                                  Shadow(
                                    blurRadius: 2.0,
                                    color: Colors.black,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                            // Dropdown arrow
                            if (!isBackgroundMode)
                              const Icon(
                                Icons.arrow_drop_down,
                                size: 30,
                                color: Colors.blue,
                              ),

                            if (isBackgroundMode)
                              const Icon(
                                Icons.arrow_drop_down,
                                size: 30,
                                color: Colors.blue,
                              ),

                            if (_statusMessage.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _statusMessage,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const Spacer(), // Pushes bottom content down
                      // Info Section (Fixed at bottom)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              // Remove background in map/camera mode
                              padding: const EdgeInsets.all(8),
                              decoration: isBackgroundMode
                                  ? null
                                  : BoxDecoration(
                                      color: Colors.white.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Geo-Coordinate:",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isBackgroundMode
                                          ? Colors.white
                                          : Colors.black,
                                      shadows: isBackgroundMode
                                          ? [
                                              const Shadow(
                                                blurRadius: 2,
                                                color: Colors.black,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Latitude: $_latitude",
                                    style: TextStyle(
                                      color: isBackgroundMode
                                          ? Colors.white
                                          : Colors.black,
                                      shadows: isBackgroundMode
                                          ? [
                                              const Shadow(
                                                blurRadius: 2,
                                                color: Colors.black,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                  Text(
                                    "Longitude: $_longitude",
                                    style: TextStyle(
                                      color: isBackgroundMode
                                          ? Colors.white
                                          : Colors.black,
                                      shadows: isBackgroundMode
                                          ? [
                                              const Shadow(
                                                blurRadius: 2,
                                                color: Colors.black,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              // Remove background in map/camera mode
                              padding: const EdgeInsets.all(8),
                              decoration: isBackgroundMode
                                  ? null
                                  : BoxDecoration(
                                      color: Colors.white.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Magnetic Field:",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isBackgroundMode
                                          ? Colors.white
                                          : Colors.black,
                                      shadows: isBackgroundMode
                                          ? [
                                              const Shadow(
                                                blurRadius: 2,
                                                color: Colors.black,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        color: isBackgroundMode
                                            ? Colors.white
                                            : Colors.black,
                                        shadows: isBackgroundMode
                                            ? [
                                                const Shadow(
                                                  blurRadius: 2,
                                                  color: Colors.black,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      children: [
                                        const TextSpan(text: "Strength: "),
                                        TextSpan(
                                          text: "46 μT",
                                          style: TextStyle(
                                            color: Colors.red, // Red always
                                            fontWeight: FontWeight.bold,
                                            shadows: isBackgroundMode
                                                ? [
                                                    const Shadow(
                                                      blurRadius: 2,
                                                      color: Colors.black,
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Bottom Actions
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            CompassBottomAction(
                              icon: Icons.home_outlined,
                              label: "Home Page",
                              onTap: () {
                                context.go(RouteConstants.dashboard);
                              },
                            ),
                            CompassBottomAction(
                              icon: Icons.crop_free,
                              label: "Capture",
                              hasRing: true,
                              onTap: _captureScreenshot,
                            ),
                            CompassBottomAction(
                              icon: Icons.image_outlined,
                              label: "Last Captured",
                              onTap: _openGallery,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Layer 3: Movable Compass Dial
            // Placed after SafeArea to be on top, but controlled by Positioned
            if (_compassOffset != null)
              Positioned(
                left: _compassOffset!.dx,
                top: _compassOffset!.dy,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _compassOffset = _compassOffset! + details.delta;
                    });
                  },
                  child: CompassDial(
                    heading: displayHeading,
                    isMapMode:
                        isBackgroundMode, // Use background mode state for transparency
                  ),
                ),
              ),

            // Layer 4: Custom Zoom Controls (Only in Map Mode)
            if (_showMap)
              Positioned(
                bottom: 120, // Adjust to be above bottom actions
                right: 16,
                child: Column(
                  children: [
                    // Location Reset Button
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.red.shade700, Colors.red.shade500],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: FloatingActionButton.small(
                        heroTag: "btnLocation",
                        backgroundColor:
                            Colors.transparent, // Transparent to show gradient
                        elevation: 0,
                        onPressed: () {
                          if (_mapController != null &&
                              _currentLatLng.latitude != 0) {
                            _mapController!.animateCamera(
                              CameraUpdate.newLatLng(_currentLatLng),
                            );
                          }
                        },
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Zoom Buttons Container
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade700, Colors.red.shade500],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Zoom In
                          InkWell(
                            onTap: () {
                              _mapController?.animateCamera(
                                CameraUpdate.zoomIn(),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Icon(Icons.add, color: Colors.white),
                            ),
                          ),
                          // Divider
                          Container(
                            width: 30,
                            height: 1,
                            color: Colors.white24,
                          ),
                          // Zoom Out
                          InkWell(
                            onTap: () {
                              _mapController?.animateCamera(
                                CameraUpdate.zoomOut(),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Icon(Icons.remove, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Vertical line
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), paint);

    // Horizontal line
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
