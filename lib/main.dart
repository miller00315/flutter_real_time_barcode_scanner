import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

late List<CameraDescription> _cameras;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _cameras = await availableCameras();
  runApp(const CameraScreen());
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController controller;
  CameraImage? img;
  bool isBusy = false;
  String result = "results will be shown";

  late BarcodeScanner barcodeScanner;
  @override
  void initState() {
    super.initState();

    final List<BarcodeFormat> formats = [BarcodeFormat.all];

    barcodeScanner = BarcodeScanner(formats: formats);

    controller = CameraController(_cameras[0], ResolutionPreset.high);

    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      controller.startImageStream((image) => {
            if (!isBusy) {isBusy = true, img = image, doBarcodeScanning()}
          });
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            print('User denied camera access.');
            break;
          default:
            print('Handle other errors.');
            break;
        }
      }
    });
  }

  //TODO barcode scanning code here
  doBarcodeScanning() async {
    final InputImage inputImage = getInputImage();

    final List<Barcode> barCodes =
        await barcodeScanner.processImage(inputImage);
    for (Barcode barCode in barCodes) {
      final BarcodeType type = barCode.type;

      /*  final Rect boundBox = barCode.boundingBox;

      final String? displayValue = barCode.displayValue;

      final String? rawValue = barCode.rawValue; */

      if (barCode.value != null) {
        switch (type) {
          case BarcodeType.wifi:
            BarcodeWifi? barCodeWifi = barCode.value as BarcodeWifi?;

            if (barCodeWifi != null) {
              result = 'Wifi: ${barCodeWifi.ssid} ${barCodeWifi.password}';
            }

            break;
          case BarcodeType.url:
            BarcodeUrl? barCodeUrl = barCode.value as BarcodeUrl?;

            if (barCodeUrl != null) {
              result = 'Url: ${barCodeUrl.url}';
            }

            break;

          default:
            result = "results will be shown here";
            break;
        }
      }
    }

    setState(() {
      isBusy = false;
      result;
    });
  }

  InputImage getInputImage() {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in img!.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();
    final Size imageSize = Size(img!.width.toDouble(), img!.height.toDouble());
    final camera = _cameras[0];
    final imageRotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    // if (imageRotation == null) return;

    final inputImageFormat =
        InputImageFormatValue.fromRawValue(img!.format.raw);

    // if (inputImageFormat == null) return null;

    final inputImageData = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation!,
      format: inputImageFormat!,
      bytesPerRow: img!.width.toInt(),
    );

    final inputImage =
        InputImage.fromBytes(bytes: bytes, metadata: inputImageData);

    return inputImage;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(controller),
            Container(
              margin: const EdgeInsets.only(left: 10, bottom: 10),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  result,
                  style: const TextStyle(color: Colors.white, fontSize: 25),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
