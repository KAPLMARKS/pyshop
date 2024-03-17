import 'package:http/http.dart' as http;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class Photo extends StatefulWidget {
  const Photo({super.key, required this.camera});

  final CameraDescription camera;

  @override
  PhotoState createState() => PhotoState();
}

class PhotoState extends State<Photo> {
  final textController = TextEditingController();

  late Position _currentPosition;

  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Камера'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return CameraPreview(_controller);
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: textController,
              minLines: 3,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
                labelText: 'Enter text',
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            ElevatedButton(
              onPressed: () async {
                final image = await _controller.takePicture();
                String imagePath = image.path;
                double latitude = _currentPosition.latitude;
                double longitude = _currentPosition.longitude;
                String comment = textController.text;

                var request = http.MultipartRequest(
                    'POST',
                    Uri.parse(
                        'https://flutter-sandbox.free.beeceptor.com/upload_photo/'),);
                request.headers['Content-Type'] = 'application/javascript';        
                request.fields['comment'] = comment;
                request.fields['latitude'] = latitude.toString();
                request.fields['longitude'] = longitude.toString();
                var file = await http.MultipartFile.fromPath(
                  'photo', imagePath);
                request.files.add(file);

                print(request);
              

                var response = await request.send();
                print(response.statusCode);
                print(response.headers);
                
                if (response.statusCode == 200) {
                  print('Photo uploaded successfully');
                } else {
                  print('Failed to upload photo');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text('Жмяк'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    textController.dispose();
    super.dispose();
  }

  _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
    });
  }
}
