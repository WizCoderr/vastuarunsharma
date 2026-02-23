import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';
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
import '../../../widgets/compass/compass_control_button.dart';
import '../../../widgets/compass/compass_bottom_action.dart';
import 'compas_screen.dart';

class Thirtytwozonecompass extends StatefulWidget {
  const Thirtytwozonecompass({super.key});

  @override
  State<Thirtytwozonecompass> createState() => _ThirtytwozonecompassState();
}

class _ThirtytwozonecompassState extends State<Thirtytwozonecompass>
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
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  double _magneticField = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCompass();
    _initLocation();
    _initCamera();
    _initMagnetometer();
  }

  void _initMagnetometer() {
    _magnetometerSubscription = magnetometerEventStream().listen((event) {
      final double strength = math.sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      if (mounted) {
        setState(() {
          _magneticField = strength;
        });
      }
    });
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) setState(() => _cameraError = "No cameras found");
        return;
      }

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
        setState(
          () =>
              _cameraError = "Camera Error: ${e.code}\n${e.description ?? ''}",
        );
      }
    } catch (e) {
      debugPrint("Error initializing camera: $e");
      if (mounted) setState(() => _cameraError = "Error: $e");
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
      if (mounted) setState(() => _cameraError = "Camera Error: ${e.code}");
    }
  }

  void _initCompass() {
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (mounted) {
        setState(() {
          double? heading = event.heading;
          if (heading != null && heading < 0) {
            heading = heading + 360;
          }
          _heading = heading;
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
            "compass_32_capture_${DateTime.now().millisecondsSinceEpoch}.png";
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
    _magnetometerSubscription?.cancel();
    _mapController?.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  // Helper method to get direction label from heading
  String _getDirectionLabel(double heading) {
    // Normalize heading to 0-360
    heading = heading % 360;
    if (heading < 0) heading += 360;

    // Define 32 compass directions
    final directions = [
      'North',
      'North by East',
      'North-Northeast',
      'Northeast by North',
      'Northeast',
      'Northeast by East',
      'East-Northeast',
      'East by North',
      'East',
      'East by South',
      'East-Southeast',
      'Southeast by East',
      'Southeast',
      'Southeast by South',
      'South-Southeast',
      'South by East',
      'South',
      'South by West',
      'South-Southwest',
      'Southwest by South',
      'Southwest',
      'Southwest by West',
      'West-Southwest',
      'West by South',
      'West',
      'West by North',
      'West-Northwest',
      'Northwest by West',
      'Northwest',
      'Northwest by North',
      'North-Northwest',
      'North by West',
    ];

    // Each direction spans 11.25 degrees (360 / 32)
    final index = ((heading + 5.625) / 11.25).floor() % 32;
    return directions[index];
  }

  @override
  Widget build(BuildContext context) {
    final double displayHeading = _heading ?? 0.0;
    // final screenSize = MediaQuery.of(context).size;
    // final double compassSize = screenSize.width - 40;

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
            if (_showMap || _showCamera)
              Positioned.fill(child: CustomPaint(painter: CrosshairPainter())),

            // Layer 2: Centered Compass Dial
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 20,
                height: MediaQuery.of(context).size.width - 20,
                child: Transform.rotate(
                  angle: -displayHeading * (math.pi / 180),
                  child: Image.asset(
                    "assets/images/42Devta.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // Layer 3: UI Overlay (Controls, Text, etc.)
            SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 20),
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
                            // Degree Display (Between Controls)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              decoration: BoxDecoration(
                                color: isBackgroundMode
                                    ? Colors.black.withOpacity(0.7)
                                    : Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8.0,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Degree Value with Symbol
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayHeading.toStringAsFixed(0),
                                        style: TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: isBackgroundMode
                                              ? Colors.white
                                              : Colors.red.shade700,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 4.0,
                                              color: Colors.black.withOpacity(
                                                0.3,
                                              ),
                                              offset: const Offset(2, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        "°",
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: isBackgroundMode
                                              ? Colors.white
                                              : Colors.red.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Direction Label
                                  Text(
                                    _getDirectionLabel(displayHeading),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isBackgroundMode
                                          ? Colors.white70
                                          : Colors.red.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

                      // Info Section - Moved to Top
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoBox(
                              "Geo-Coordinate:",
                              "Latitude: $_latitude\nLongitude: $_longitude",
                              isBackgroundMode,
                            ),
                            _buildInfoBox(
                              "Magnetic Field:",
                              "Strength: ${_magneticField.toStringAsFixed(0)} μT",
                              isBackgroundMode,
                              valueColor: Colors.red,
                            ),
                          ],
                        ),
                      ),

                      
                      // Status Message
                      if (_statusMessage.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8.0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 6.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            _statusMessage,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      const Spacer(),

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
                              onTap: () => context.go(RouteConstants.dashboard),
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(
    String title,
    String content,
    bool isBackgroundMode, {
    Color? valueColor,
  }) {
    return Container(
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
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isBackgroundMode ? Colors.white : Colors.black,
              shadows: isBackgroundMode
                  ? [const Shadow(blurRadius: 2, color: Colors.black)]
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              color:
                  valueColor ??
                  (isBackgroundMode ? Colors.white : Colors.black),
              fontWeight: valueColor != null
                  ? FontWeight.bold
                  : FontWeight.normal,
              shadows: isBackgroundMode
                  ? [const Shadow(blurRadius: 2, color: Colors.black)]
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
