import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

enum ElementType {
  heading, paragraph, button, list, video, card, icon, imageSlider, submitButton, nextButton, backButton, loginButton, image, logo, radioGroup, checkbox, bottomBar, cardRow2, cardRow3, appBar, textField
}

// Video Player Widget Implementation
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  
  const VideoPlayerWidget({Key? key, required this.videoUrl}) : super(key: key);
  
  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }
  
  void _initializeVideo() {
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _controller.play();
          _controller.setLooping(true);
        }
      });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: _isInitialized
          ? VideoPlayer(_controller)
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

// Image Slider Widget Implementation
class ImageSliderWidget extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  
  const ImageSliderWidget({Key? key, required this.imageUrls, required this.height}) : super(key: key);
  
  @override
  _ImageSliderWidgetState createState() => _ImageSliderWidgetState();
}

class _ImageSliderWidgetState extends State<ImageSliderWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Image.network(
                widget.imageUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                  const Center(child: Text('Error loading image')),
              );
            },
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.imageUrls.length, (index) => 
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.5),
                  ),
                )
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// Page Data
final Map<String, dynamic> pageData = {
  'name': 'Page 1',
  'backgroundColor': '#FFFFFF',
  'elements': [
  ]
};

class GeneratedPage extends StatefulWidget {
  const GeneratedPage({super.key});

  @override
  _GeneratedPageState createState() => _GeneratedPageState();
}

class _GeneratedPageState extends State<GeneratedPage> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    for (var el in pageData['elements']) {
      if (el['type'] == ElementType.textField) {
        _controllers[el['fieldId']] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitForm() async {
    // Prevent multiple submissions
    if (_isSubmitting) return;
    
    setState(() {
      _isSubmitting = true;
    });
    
    final Map<String, dynamic> formData = {};
    for (var el in pageData['elements']) {
      if (el['type'] == ElementType.textField) {
        formData[el['fieldId']] = _controllers[el['fieldId']]?.text ?? '';
      }
    }

    print('Submitting form to: http://localhost:3000/submit-form');
    print('Form data: $formData');
    
    // Submit to backend
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/submit-form'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(formData),
      ).timeout(const Duration(seconds: 30));
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Form submitted successfully! ID: ${result['id'] ?? 'unknown'}')),
        );
      } else {
        print('❌ Backend response: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${response.body}')),
        );
      }
    } on TimeoutException catch (e) {
      print('❌ Form submission timed out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection timed out. Please check your network connection.')),
      );
    } on http.ClientException catch (e) {
      print('❌ Client exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to connect to server. Please check if the server is running.')),
      );
    } catch (e) {
      print('❌ Error submitting form: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Color(0xFFFFFF),
        child: ListView(
          children: [
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Generated App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const GeneratedPage(),
    );
  }
}
