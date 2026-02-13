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
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../widgets/compass/sixteen_zone_compass_dial.dart';
import '../../../widgets/compass/compass_control_button.dart';
import '../../../widgets/compass/compass_bottom_action.dart';

class SixteenZoneCompass extends StatefulWidget {
  const SixteenZoneCompass({super.key});

  @override
  State<SixteenZoneCompass> createState() => _SixteenZoneCompassState();
}

class _SixteenZoneCompassState extends State<SixteenZoneCompass>
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
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController?.initialize();
      if (mounted) setState(() => _cameraError = "");
    } on CameraException catch (e) {
      debugPrint("Camera Error: ${e.code} - ${e.description}");
      if (mounted) {
        setState(() => _cameraError = "Camera Error: ${e.code}");
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
        _showCamera = false;
      }
    });
  }

  void _toggleCamera() {
    setState(() {
      _showCamera = !_showCamera;
      if (_showCamera) {
        _showMap = false;
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
        final String fileName =
            "compass_16zone_${DateTime.now().millisecondsSinceEpoch}.png";
        final directory = await getTemporaryDirectory();
        final File file = File('${directory.path}/$fileName');
        await file.writeAsBytes(image);
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
      if (pickedFile != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Selected: ${pickedFile.name}")));
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
    final double displayHeading = _heading ?? 0.0;
    final screenSize = MediaQuery.of(context).size;
    const double compassSize = 320.0; // Matches dial size

    // Initialize position if not set
    _compassOffset ??= Offset(
      (screenSize.width - compassSize) / 2,
      (screenSize.height - compassSize) / 2,
    );

    final bool isBackgroundMode = _showMap || _showCamera;

    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Layer 0: Camera Preview
            if (_showCamera)
              SizedBox.expand(
                child: _cameraError.isNotEmpty
                    ? Center(
                        child: Text(
                          _cameraError,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : (_cameraController != null &&
                          _cameraController!.value.isInitialized)
                    ? CameraPreview(_cameraController!)
                    : const Center(child: CircularProgressIndicator()),
              ),

            // Layer 1: Google Map
            if (_showMap)
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentLatLng,
                  zoom: 19.0,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false,
                mapType: MapType.hybrid,
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (_currentLatLng.latitude != 0 &&
                      _currentLatLng.longitude != 0) {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLng(_currentLatLng),
                    );
                  }
                },
              ),

            // Layer 1.5: Crosshairs
            if (isBackgroundMode)
              Positioned.fill(child: CustomPaint(painter: _CrosshairPainter())),

            // Layer 2: UI Controls
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Top Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
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

                        // Degree Display (Center Top)
                        Column(
                          children: [
                            Text(
                              "${displayHeading.toStringAsFixed(0)}° Degree",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors
                                    .black, // Changed to black as per white bg, or dynamic
                                shadows: [
                                  Shadow(
                                    blurRadius: 2.0,
                                    color: Colors.white,
                                    offset: Offset(0, 0),
                                  ),
                                ],
                              ),
                            ),
                            // Arrow pointing down to compass
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.blue,
                              size: 30,
                            ),
                          ],
                        ),

                        CompassControlButton(
                          icon: _showCamera
                              ? Icons.camera_alt
                              : Icons.camera_alt_outlined,
                          label: _showCamera ? "Hide Camera" : "Rear Camera",
                          onTap: _toggleCamera,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Bottom Info Section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 10.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Geo-Coordinate
                        Column(
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
                                    ? const [
                                        Shadow(
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
                                    ? const [
                                        Shadow(
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
                                    ? const [
                                        Shadow(
                                          blurRadius: 2,
                                          color: Colors.black,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ],
                        ),

                        // Magnetic Field
                        Column(
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
                                    ? const [
                                        Shadow(
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
                                      ? const [
                                          Shadow(
                                            blurRadius: 2,
                                            color: Colors.black,
                                          ),
                                        ]
                                      : null,
                                ),
                                children: [
                                  const TextSpan(text: "Strength: "),
                                  TextSpan(
                                    text: "57 μT",
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

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
            ),

            // Layer 3: Movable Compass Dial
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
                  child: SixteenZoneCompassDial(
                    heading: displayHeading,
                    isMapMode: isBackgroundMode,
                  ),
                ),
              ),

            // Zoom Controls for Map
            if (_showMap)
              Positioned(
                bottom: 120,
                right: 16,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: "btnLocation16",
                      backgroundColor: Colors.white,
                      onPressed: () {
                        if (_mapController != null &&
                            _currentLatLng.latitude != 0) {
                          _mapController!.animateCamera(
                            CameraUpdate.newLatLng(_currentLatLng),
                          );
                        }
                      },
                      child: const Icon(Icons.my_location, color: Colors.blue),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: "btnZoomIn16",
                      backgroundColor: Colors.white,
                      onPressed: () {
                        _mapController?.animateCamera(CameraUpdate.zoomIn());
                      },
                      child: const Icon(Icons.add, color: Colors.blue),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: "btnZoomOut16",
                      backgroundColor: Colors.white,
                      onPressed: () {
                        _mapController?.animateCamera(CameraUpdate.zoomOut());
                      },
                      child: const Icon(Icons.remove, color: Colors.blue),
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

class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), paint);
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
