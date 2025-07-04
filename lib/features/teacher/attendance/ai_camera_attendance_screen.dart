import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../../core/services/ai_face_detection_service.dart';
import '../../../models/student/student.dart';
import '../../../models/timestamp/timestamp_model.dart';

class AiCameraAttendanceScreen extends StatefulWidget {
  final Function(String studentId, String studentName, String imagePath)? onAttendanceMarked;
  
  const AiCameraAttendanceScreen({
    super.key,
    this.onAttendanceMarked,
  });

  @override
  State<AiCameraAttendanceScreen> createState() => _AiCameraAttendanceScreenState();
}

class _AiCameraAttendanceScreenState extends State<AiCameraAttendanceScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  late final AiFaceDetectionService _aiService;
  bool _isInitialized = false;
  bool _isAnalyzing = false;
  bool _showingResults = false;
  List<StudentMatch> _currentMatches = [];
  List<Student> _availableStudents = [];
  int _currentMatchIndex = 0;
  String? _currentImagePath; // Store the image path for attendance record
  
  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  // Swipe detection
  bool _isDragging = false;
  double _dragPosition = 0.0;
  static const double _swipeThreshold = 100.0;

  @override
  void initState() {
    super.initState();
    _aiService = AiFaceDetectionService();
    _initializeAnimations();
    _initializeCamera();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      // For demo purposes, create some dummy students
      _availableStudents = [
        Student(
          id: '1',
          firstName: 'Lai Ze',
          lastName: 'Min',
          dateOfBirth: DateTime(2018, 1, 1),
          profilePictureUrl: null,
          timestamps: Timestamps.now(),
        ),
        Student(
          id: '2',
          firstName: 'Chuah Kee',
          lastName: 'Yong',
          dateOfBirth: DateTime(2018, 2, 1),
          profilePictureUrl: null,
          timestamps: Timestamps.now(),
        ),
        Student(
          id: '3',
          firstName: 'Elvis',
          lastName: 'Chang',
          dateOfBirth: DateTime(2018, 3, 1),
          profilePictureUrl: null,
          timestamps: Timestamps.now(),
        ),
      ];
    } catch (e) {
      debugPrint('Error loading students: $e');
    }
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.medium,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() => _isInitialized = true);
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _captureAndAnalyze() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    
    setState(() => _isAnalyzing = true);
    
    try {
      final image = await _cameraController!.takePicture();
      _currentImagePath = image.path; // Store the image path
      
      final results = await _aiService.detectAndIdentifyStudents(
        imagePath: image.path,
        availableStudents: _availableStudents,
      );
      
      if (results.hasMatches) {
        setState(() {
          _currentMatches = results.studentMatches;
          _currentMatchIndex = 0;
          _showingResults = true;
          _isAnalyzing = false;
        });
        // Cards will be visible immediately without fade animation
      } else {
        _showNoMatchDialog();
      }
    } catch (e) {
      debugPrint('Error capturing/analyzing image: $e');
      setState(() => _isAnalyzing = false);
    }
  }

  void _showNoMatchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Student Found'),
        content: const Text('Could not identify any student in the photo. Please try again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isAnalyzing = false);
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _swipeLeft() async {
    if (_currentMatchIndex < _currentMatches.length - 1) {
      // Animate current card sliding out
      await _slideController.forward();
      
      // Update to next match and reset animations
      setState(() {
        _currentMatchIndex++;
        _dragPosition = 0.0;
      });
      
      // Reset slide animation for new card
      _slideController.reset();
      
      // No need for fade animation anymore - cards stay visible
    } else {
      _showNoMoreMatchesDialog();
    }
  }

  void _swipeRight() {
    final currentMatch = _currentMatches[_currentMatchIndex];
    _confirmAttendance(currentMatch.student);
  }

  void _showNoMoreMatchesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No More Matches'),
        content: const Text('These were all the possible matches. Would you like to try taking another photo?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetToCamera();
            },
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _resetToCamera() {
    setState(() {
      _showingResults = false;
      _currentMatches.clear();
      _currentMatchIndex = 0;
      _dragPosition = 0.0;
      _currentImagePath = null; // Clear the image path
    });
    _slideController.reset();
    _scaleController.reset();
  }

  void _confirmAttendance(Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Attendance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: student.profilePictureUrl != null
                  ? NetworkImage(student.profilePictureUrl!)
                  : null,
              child: student.profilePictureUrl == null
                  ? Text('${student.firstName[0]}${student.lastName[0]}'.toUpperCase())
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              'Mark ${student.firstName} ${student.lastName} as present?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _markAttendance(student);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _markAttendance(Student student) {
    // Call the callback if provided to update the parent screen
    if (widget.onAttendanceMarked != null && _currentImagePath != null) {
      widget.onAttendanceMarked!(
        student.id,
        '${student.firstName} ${student.lastName}',
        _currentImagePath!,
      );
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${student.firstName} ${student.lastName} marked present!'),
        backgroundColor: Colors.green,
      ),
    );
    _resetToCamera();
  }

  void _onPanStart(DragStartDetails details) {
    _isDragging = true;
    _scaleController.forward();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    
    setState(() {
      _dragPosition += details.delta.dx;
      _dragPosition = _dragPosition.clamp(-200.0, 200.0);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _isDragging = false;
    _scaleController.reverse();
    
    if (_dragPosition < -_swipeThreshold) {
      // Swipe left - next match
      _swipeLeft();
    } else if (_dragPosition > _swipeThreshold) {
      // Swipe right - confirm
      _swipeRight();
    } else {
      // Return to center
      setState(() => _dragPosition = 0.0);
    }
  }

  Widget _buildSwipeableCard() {
    if (_currentMatches.isEmpty || _currentMatchIndex >= _currentMatches.length) {
      return const SizedBox();
    }

    final currentMatch = _currentMatches[_currentMatchIndex];
    final rotation = _dragPosition * 0.001;
    final opacity = 1.0 - (_dragPosition.abs() / 200.0).clamp(0.0, 0.3);

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: Listenable.merge([_slideAnimation, _scaleAnimation]),
        builder: (context, child) {
          // Only apply slide animation during the actual swipe transition
          final slideOffset = _slideController.isAnimating 
              ? _slideAnimation.value * MediaQuery.of(context).size.width
              : Offset.zero;
          
          return Transform.translate(
            offset: slideOffset + Offset(_dragPosition, 0),
            child: Transform.rotate(
              angle: rotation,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: opacity, // Remove fade animation dependency
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      width: 280,
                      height: 400,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade50,
                            Colors.white,
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: currentMatch.student.profilePictureUrl != null
                                ? NetworkImage(currentMatch.student.profilePictureUrl!)
                                : null,
                            child: currentMatch.student.profilePictureUrl == null
                                ? Text(
                                    '${currentMatch.student.firstName[0]}${currentMatch.student.lastName[0]}'.toUpperCase(),
                                    style: const TextStyle(fontSize: 36),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '${currentMatch.student.firstName} ${currentMatch.student.lastName}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Class: ${currentMatch.student.classroomId ?? 'N/A'}',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getConfidenceColor(currentMatch.confidenceScore),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${(currentMatch.confidenceScore * 100).toInt()}% match',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            'Swipe right to confirm\nSwipe left for next match',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.9) return Colors.green;
    if (confidence >= 0.8) return Colors.orange;
    return Colors.red;
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FloatingActionButton(
          heroTag: 'swipe_left',
          onPressed: _swipeLeft,
          backgroundColor: Colors.orange,
          child: const Icon(Icons.arrow_back),
        ),
        FloatingActionButton(
          heroTag: 'swipe_right',
          onPressed: _swipeRight,
          backgroundColor: Colors.green,
          child: const Icon(Icons.check),
        ),
      ],
    );
  }

  Widget _buildMatchIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Match ${_currentMatchIndex + 1} of ${_currentMatches.length}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Camera Attendance'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_showingResults)
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: _resetToCamera,
              tooltip: 'Take New Photo',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Preview
          if (_isInitialized && !_showingResults)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            ),
          
          // Loading Overlay
          if (_isAnalyzing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Analyzing photo...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Results Overlay
          if (_showingResults)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.blue.shade100,
                    Colors.blue.shade50,
                  ],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildMatchIndicator(),
                  Expanded(
                    child: Center(
                      child: _buildSwipeableCard(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: _buildActionButtons(),
                  ),
                ],
              ),
            ),
          
          // Camera Controls
          if (_isInitialized && !_showingResults && !_isAnalyzing)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton.large(
                  onPressed: _captureAndAnalyze,
                  backgroundColor: Colors.white,
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.blue,
                    size: 32,
                  ),
                ),
              ),
            ),
          
          // Instructions
          if (_isInitialized && !_showingResults && !_isAnalyzing)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Position student\'s face in the camera and tap the capture button',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
}
