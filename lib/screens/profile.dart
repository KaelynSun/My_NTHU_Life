import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  final String studentID;

  const ProfileScreen({super.key, required this.studentID});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Local profile states
  String _displayName = "Loading Name...";
  String _department = "Loading Department...";
  String _bio = "No status bio written yet.";
  String? _profileImageUrl;

  // Analytics states
  int _currentStreak = 0;
  int _completedTasks = 0;
  int _totalTasks = 0;
  double _currentGpa = 0.0;
  int _enrolledCredits = 0;
  bool _isLoadingMetrics = true;
  bool _isUploadingImage = false;

  static const Color purpleMain = Color(0xFF7C3AED);

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadAllMetrics();
  }

  // ===== FIREBASE & CACHE PROFILE STORAGE =====
  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Quick local cache lookup for snappy loads
    if (mounted) {
      setState(() {
        _displayName = prefs.getString('profile_name_${widget.studentID}') ?? "NTHU Student";
        _department = prefs.getString('profile_dept_${widget.studentID}') ?? "Computer Science";
        _bio = prefs.getString('profile_bio_${widget.studentID}') ?? "Keep moving forward.";
        _profileImageUrl = prefs.getString('profile_image_${widget.studentID}');
      });
    }

    // Pull ground truth from Firestore
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.studentID).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final name = data['name'] ?? "NTHU Student";
        final dept = data['department'] ?? "Computer Science";
        final bioText = data['bio'] ?? "Keep moving forward.";
        final imgUrl = data['profileImageUrl'] as String?;

        if (mounted) {
          setState(() {
            _displayName = name;
            _department = dept;
            _bio = bioText;
            _profileImageUrl = imgUrl;
          });
        }

        // Cache the updated values locally
        await prefs.setString('profile_name_${widget.studentID}', name);
        await prefs.setString('profile_dept_${widget.studentID}', dept);
        await prefs.setString('profile_bio_${widget.studentID}', bioText);
        if (imgUrl != null) {
          await prefs.setString('profile_image_${widget.studentID}', imgUrl);
        }
      }
    } catch (e) {
      debugPrint("Error fetching Firestore user profile: $e");
    }
  }

  Future<void> _updateProfileField(String fieldKey, String value) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.studentID).set({
        fieldKey: value,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error pushing profile field to Firestore: $e");
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_${fieldKey}_${widget.studentID}', value);
  }

  // ===== IMAGE PICKER & FIREBASE STORAGE PIPELINE =====
  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    
    try {
      // 1. Pick image from gallery
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Compresses image slightly to reduce Firestore upload time/size
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      // 2. Upload to Firebase Storage
      final file = File(pickedFile.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_profiles')
          .child('${widget.studentID}.jpg');

      await storageRef.putFile(file);
      
      // 3. Grab the public download URL
      final String downloadUrl = await storageRef.getDownloadURL();

      // 4. Update Firestore and State
      await _updateProfileField('profileImageUrl', downloadUrl);
      
      if (mounted) {
        setState(() {
          _profileImageUrl = downloadUrl;
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully!')),
      );
    } catch (e) {
      debugPrint("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  // ===== MATH METRICS PIPELINE =====
  Future<void> _loadAllMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Streak Metric
      final petString = prefs.getString('streak_pet_${widget.studentID}');
      if (petString != null) {
        final Map<String, dynamic> petMap = jsonDecode(petString);
        _currentStreak = petMap['currentStreak'] ?? 0;
      }

      // Tasks Metric
      final tasksString = prefs.getString('tasks_${widget.studentID}');
      if (tasksString != null) {
        final Map<String, dynamic> coursesMap = jsonDecode(tasksString);
        int total = 0;
        int completed = 0;
        coursesMap.forEach((_, taskList) {
          if (taskList is List) {
            for (var task in taskList) {
              total++;
              if (task['isDone'] == true) completed++;
            }
          }
        });
        _totalTasks = total;
        _completedTasks = completed;
      }

      // Cumulative GPA Metric
      final gpaString = prefs.getString('gpa_courses_${widget.studentID}');
      if (gpaString != null) {
        final List<dynamic> decodedGpa = jsonDecode(gpaString);
        double totalPoints = 0;
        int totalCreditsWithGrades = 0;

        final Map<String, double> gradePoints = {
          'A+': 4.3, 'A': 4.0, 'A-': 3.7,
          'B+': 3.3, 'B': 3.0, 'B-': 2.7,
          'C+': 2.3, 'C': 2.0, 'C-': 1.7,
          'D': 1.0,  'F': 0.0, 'X': 0.0,
        };

        for (var course in decodedGpa) {
          final String? grade = course['grade'];
          final int credits = course['credits'] ?? 0;
          if (grade != null && grade != '-' && gradePoints.containsKey(grade)) {
            totalPoints += (gradePoints[grade]! * credits);
            totalCreditsWithGrades += credits;
          }
        }
        _currentGpa = totalCreditsWithGrades > 0 ? (totalPoints / totalCreditsWithGrades) : 0.0;
      }

      // Enrolled Credits Metric
      final semestersString = prefs.getString('Semesters_${widget.studentID}');
      if (semestersString != null) {
        final List<dynamic> decodedSemesters = jsonDecode(semestersString);
        int creditsAccumulator = 0;
        for (var semester in decodedSemesters) {
          if (semester['courses'] != null) {
            for (var course in semester['courses']) {
              creditsAccumulator += (course['credits'] as num).toInt();
            }
          }
        }
        _enrolledCredits = creditsAccumulator;
      }
    } catch (e) {
      debugPrint("Error parsing system radar metrics: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingMetrics = false);
      }
    }
  }

  // ===== DIALOG FIELDS INLINE EDITING =====
  void _showEditFieldDialog(String title, String fieldKey, String initialValue, Function(String) onSave) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surfaceContainerLow,
          title: Text("Edit $title", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: cs.onSurface)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: cs.onSurface),
            decoration: InputDecoration(
              filled: true,
              fillColor: cs.surfaceContainerHigh,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.outlineVariant)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: purpleMain)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: cs.onSurfaceVariant)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: purpleMain, foregroundColor: Colors.white),
              onPressed: () {
                final newValue = controller.text.trim();
                if (newValue.isNotEmpty) {
                  onSave(newValue);
                  _updateProfileField(fieldKey, newValue);
                }
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final double consistencyVal = ((_currentStreak / 30) * 100).clamp(0.0, 100.0);
    final double productivityVal = _totalTasks > 0 ? ((_completedTasks / _totalTasks) * 100) : 0.0;
    final double intelligenceVal = ((_currentGpa / 4.3) * 100).clamp(0.0, 100.0);
    final double ambitionVal = ((_enrolledCredits / 25) * 100).clamp(0.0, 100.0);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoadingMetrics
            ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(purpleMain)))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Profile",
                      style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: cs.onSurface),
                    ),
                    const SizedBox(height: 24),
                    
                    // ===== EDITABLE AVATAR STACK =====
                    Center(
                      child: GestureDetector(
                        onTap: _isUploadingImage ? null : _pickAndUploadImage,
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle, 
                                border: Border.all(color: purpleMain.withOpacity(0.2), width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: purpleMain.withOpacity(0.1),
                                backgroundImage: _profileImageUrl != null 
                                    ? NetworkImage(_profileImageUrl!) 
                                    : null,
                                child: _profileImageUrl == null && !_isUploadingImage
                                    ? const Icon(Icons.person_rounded, size: 52, color: purpleMain)
                                    : _isUploadingImage
                                        ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(purpleMain))
                                        : null,
                              ),
                            ),
                            if (!_isUploadingImage)
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: purpleMain,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    
                    // ===== EDITABLE USER SPECIFIC PARAMETERS =====
                    _buildFieldLabel("Name"),
                    const SizedBox(height: 6),
                    _buildEditableCard(
                      context,
                      text: _displayName,
                      onTap: () => _showEditFieldDialog("Name", "name", _displayName, (val) => setState(() => _displayName = val)),
                    ),
                    
                    const SizedBox(height: 16),
                    _buildFieldLabel("Student ID (Fixed Reference)"),
                    const SizedBox(height: 6),
                    _buildDataCard(context, text: widget.studentID),
                    
                    const SizedBox(height: 16),
                    _buildFieldLabel("Department"),
                    const SizedBox(height: 6),
                    _buildEditableCard(
                      context,
                      text: _department,
                      onTap: () => _showEditFieldDialog("Department", "department", _department, (val) => setState(() => _department = val)),
                    ),

                    const SizedBox(height: 16),
                    _buildFieldLabel("Status Bio"),
                    const SizedBox(height: 6),
                    _buildEditableCard(
                      context,
                      text: _bio,
                      onTap: () => _showEditFieldDialog("Bio", "bio", _bio, (val) => setState(() => _bio = val)),
                    ),
                    
                    const SizedBox(height: 36),
                    Text(
                      "Student Stats Matrix",
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface),
                    ),
                    const SizedBox(height: 20),
                    
                    // ===== MATRIX GRAPH DATA ARRAY =====
                    SizedBox(
                      height: 240,
                      width: double.infinity,
                      child: RadarChart(
                        RadarChartData(
                          radarShape: RadarShape.polygon,
                          isMinValueAtCenter: true,
                          dataSets: [
                            RadarDataSet(
                              fillColor: purpleMain.withOpacity(0.18),
                              borderColor: purpleMain,
                              borderWidth: 2.5,
                              entryRadius: 3.5,
                              dataEntries: [
                                RadarEntry(value: consistencyVal),
                                RadarEntry(value: productivityVal),
                                RadarEntry(value: intelligenceVal),
                                RadarEntry(value: ambitionVal),
                              ],
                            ),
                          ],
                          getTitle: (index, angle) {
                            switch (index) {
                              case 0: return RadarChartTitle(text: 'Consistency 🔥', angle: angle);
                              case 1: return RadarChartTitle(text: 'Productivity ⚡', angle: angle);
                              case 2: return RadarChartTitle(text: 'Intelligence 🧠', angle: angle);
                              case 3: return RadarChartTitle(text: 'Ambition 🎯', angle: angle);
                              default: return const RadarChartTitle(text: '');
                            }
                          },
                          tickCount: 4,
                          ticksTextStyle: const TextStyle(color: Colors.transparent),
                          gridBorderData: BorderSide(color: cs.outlineVariant.withOpacity(0.35), width: 1),
                          radarBorderData: BorderSide(color: cs.outlineVariant.withOpacity(0.6), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 0.2),
    );
  }

  Widget _buildDataCard(BuildContext context, {required String text}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.onSurface.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.1)),
      ),
      child: Text(text, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
    );
  }

  Widget _buildEditableCard(BuildContext context, {required String text, required VoidCallback onTap}) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.onSurface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.edit_outlined, size: 16, color: cs.onSurfaceVariant.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}