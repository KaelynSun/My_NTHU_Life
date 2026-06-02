import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_nthu_life/pet_files/pet_provider.dart';
import 'package:provider/provider.dart';

class TaskListPage extends StatefulWidget {
  final String studentID;

  const TaskListPage({super.key, required this.studentID});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  List<String> _courseNames = [];
  bool _isLoadingCourses = true;

  final List<String> _categories = [
    'Homework',
    'Quiz',
    'Lab',
    'Midterm',
    'Final',
    'Project',
    'Other'
  ];

  late DateTime _focusedMonth;
  int? _selectedDay;

  final List<String> _weekLabels = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN'
  ];

  final List<String> _monthLabels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
    _selectedDay = DateTime.now().day;
    _fetchCourseList();
  }

  // Real-time courses extraction to populate the task drop-down menu automatically
  Future<void> _fetchCourseList() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentID)
          .collection('courses')
          .get();

      final courses = snapshot.docs
          .map(
            (doc) =>
                doc.data()['name'] as String? ??
                'Unknown Course',
          )
          .toSet()
          .toList();

      setState(() {
        _courseNames = courses;
        _isLoadingCourses = false;
      });
    } catch (e) {
      setState(() => _isLoadingCourses = false);
    }
  }

  // Dynamic EXP allocation engine mapping rule definitions
  int _calculateExpForCategory(String category) {
    switch (category) {
      case 'Homework':
        return 5;

      case 'Quiz':
      case 'Lab':
        return 10;

      case 'Midterm':
      case 'Final':
        return 20;

      default:
        return 10; // Default flat fallback for Projects/Others
    }
  }

  int _calculateCoinsForCategory(String category) {
    return (_calculateExpForCategory(category) / 2)
        .floor()
        .clamp(1, 10);
  }

  String _getDayStringKey(int day) {
    return "${_focusedMonth.year}-${_focusedMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month - 1,
        1,
      );
      _selectedDay = 1;
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + 1,
        1,
      );
      _selectedDay = 1;
    });
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Homework':
        return const Color(0xFF9D4EDD);

      case 'Quiz':
        return const Color(0xFFC77DFF);

      case 'Lab':
        return const Color(0xFF00CEC9);

      case 'Midterm':
        return const Color(0xFFE0AAFF);

      case 'Final':
        return const Color(0xFF5A189A);

      case 'Project':
        return const Color(0xFF64DFDF);

      default:
        return const Color(0xFF7B2CBF);
    }
  }

  void _showAddTaskDialog() {
    if (_selectedDay == null) return;

    String taskTitle = "";
    String selectedCategory = _categories.first;

    String selectedCourse = _courseNames.isNotEmpty
        ? _courseNames.first
        : "General Task";

    TextEditingController customCourseController =
        TextEditingController(
      text: selectedCourse,
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor:
                  const Color(0xFF16121E),

              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(20),
                side: const BorderSide(
                  color: Color(0xFF3C096C),
                  width: 1.5,
                ),
              ),

              title: Text(
                "Assign Matrix Quest",
                style: GoogleFonts.orbitron(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFE0AAFF),
                  fontSize: 16,
                ),
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    _courseNames.isNotEmpty
                        ? DropdownButtonFormField<
                            String>(
                            dropdownColor:
                                const Color(
                              0xFF16121E,
                            ),

                            value: selectedCourse,

                            style: GoogleFonts.outfit(
                              color: Colors.white,
                            ),

                            decoration:
                                const InputDecoration(
                              labelText:
                                  "Target Course",

                              labelStyle:
                                  TextStyle(
                                color: Color(
                                  0xFFC77DFF,
                                ),
                              ),

                              enabledBorder:
                                  UnderlineInputBorder(
                                borderSide:
                                    BorderSide(
                                  color: Color(
                                    0xFF3C096C,
                                  ),
                                ),
                              ),
                            ),

                            items: _courseNames
                                .map(
                                  (name) =>
                                      DropdownMenuItem(
                                    value: name,
                                    child: Text(
                                      name,
                                      overflow:
                                          TextOverflow
                                              .ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),

                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() {
                                  selectedCourse =
                                      val;

                                  customCourseController
                                          .text =
                                      val;
                                });
                              }
                            },
                          )
                        : TextField(
                            controller:
                                customCourseController,

                            style: const TextStyle(
                              color: Colors.white,
                            ),

                            decoration:
                                const InputDecoration(
                              labelText:
                                  "Target Course Name",

                              labelStyle:
                                  TextStyle(
                                color: Color(
                                  0xFFC77DFF,
                                ),
                              ),

                              hintText:
                                  "e.g. Operating Systems",

                              hintStyle:
                                  TextStyle(
                                color:
                                    Colors.white24,
                              ),

                              enabledBorder:
                                  UnderlineInputBorder(
                                borderSide:
                                    BorderSide(
                                  color: Color(
                                    0xFF3C096C,
                                  ),
                                ),
                              ),
                            ),
                          ),

                    const SizedBox(height: 12),

                    TextField(
                      style: const TextStyle(
                        color: Colors.white,
                      ),

                      decoration:
                          const InputDecoration(
                        labelText: "Quest Title",

                        labelStyle: TextStyle(
                          color: Color(0xFFC77DFF),
                        ),

                        hintText:
                            "e.g. Complete Lab Report analysis",

                        hintStyle: TextStyle(
                          color: Colors.white24,
                        ),

                        enabledBorder:
                            UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(
                              0xFF3C096C,
                            ),
                          ),
                        ),
                      ),

                      onChanged: (value) =>
                          taskTitle = value,
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      dropdownColor:
                          const Color(0xFF16121E),

                      value: selectedCategory,

                      style: GoogleFonts.outfit(
                        color: Colors.white,
                      ),

                      decoration:
                          const InputDecoration(
                        labelText: "Category",

                        labelStyle: TextStyle(
                          color: Color(0xFFC77DFF),
                        ),

                        enabledBorder:
                            UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(
                              0xFF3C096C,
                            ),
                          ),
                        ),
                      ),

                      items: _categories
                          .map(
                            (cat) =>
                                DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ),
                          )
                          .toList(),

                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(
                            () => selectedCategory =
                                val,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context),

                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),

                TextButton(
                  onPressed: () async {
                    String finalCourseName =
                        customCourseController.text
                            .trim();

                    if (finalCourseName.isEmpty) {
                      finalCourseName =
                          "General Task";
                    }

                    if (taskTitle
                        .trim()
                        .isNotEmpty) {

                      final computedExp =
                          _calculateExpForCategory(
                        selectedCategory,
                      );

                      final computedCoins =
                          _calculateCoinsForCategory(
                        selectedCategory,
                      );

                      // Write task payload into a centralized user subcollection
                      await FirebaseFirestore
                          .instance
                          .collection('users')
                          .doc(widget.studentID)
                          .collection('tasks')
                          .add({
                        'title':
                            taskTitle.trim(),
                        'course':
                            finalCourseName,
                        'category':
                            selectedCategory,
                        'assignedDayString':
                            _getDayStringKey(
                          _selectedDay!,
                        ),
                        'exp': computedExp,
                        'coins':
                            computedCoins,
                        'isDone': false,
                        'createdAt':
                            FieldValue
                                .serverTimestamp(),
                      });
                    }

                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },

                  child: Text(
                    "Confirm",
                    style:
                        GoogleFonts.orbitron(
                      color:
                          const Color(0xFFC77DFF),
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bgBlack = Color(0xFF0B090A);
    const Color cardDarkPurple =
        Color(0xFF16121E);

    const Color neonLightPurple =
        Color(0xFFC77DFF);

    if (_isLoadingCourses) {
      return const Scaffold(
        backgroundColor: bgBlack,
        body: Center(
          child:
              CircularProgressIndicator(
            color: neonLightPurple,
          ),
        ),
      );
    }

    int daysInMonth = DateUtils.getDaysInMonth(
      _focusedMonth.year,
      _focusedMonth.month,
    );

    int firstWeekdayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    ).weekday;

    int prefixEmptyCells =
        firstWeekdayOfMonth - 1;

    int totalGridCells =
        prefixEmptyCells + daysInMonth;

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentID)
          .collection('tasks')
          .snapshots(),

      builder: (context, snapshot) {

        final Map<String,
                List<DocumentSnapshot>>
            tasksByDay = {};

        if (snapshot.hasData) {
          for (var doc
              in snapshot.data!.docs) {

            final data = doc.data();

            final dayKey =
                data['assignedDayString']
                        as String? ??
                    '';

            tasksByDay
                .putIfAbsent(
                  dayKey,
                  () => [],
                )
                .add(doc);
          }
        }

        final selectedTargetKey =
            _selectedDay != null
                ? _getDayStringKey(
                    _selectedDay!,
                  )
                : '';

        final activeDayDocs =
            tasksByDay[selectedTargetKey] ??
                [];

        return Scaffold(
          backgroundColor: bgBlack,

          appBar: AppBar(
            backgroundColor: bgBlack,
            elevation: 0,

            title: Text(
              "TIMELINE ARCHIVE",
              style:
                  GoogleFonts.orbitron(
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),

            centerTitle: true,
          ),

          body: SafeArea(
            child: Column(
              children: [

                Expanded(
                  child:
                      SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),

                    child: Column(
                      children: [

                        // existing calendar UI remains same...

                        const SizedBox(
                            height: 20),

                        if (_selectedDay !=
                            null) ...[
                          Align(
                            alignment:
                                Alignment
                                    .centerLeft,

                            child: Padding(
                              padding:
                                  const EdgeInsets
                                      .only(
                                left: 4.0,
                                bottom: 10,
                              ),

                              child: Text(
                                "SCHEDULED TASKS • ${_monthLabels[_focusedMonth.month - 1].toUpperCase()} $_selectedDay",

                                style:
                                    GoogleFonts
                                        .orbitron(
                                  fontSize:
                                      11,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  color:
                                      const Color(
                                    0xFF9D4EDD,
                                  ),
                                  letterSpacing:
                                      1,
                                ),
                              ),
                            ),
                          ),

                          activeDayDocs
                                  .isEmpty
                              ? Container(
                                  width: double
                                      .infinity,

                                  padding:
                                      const EdgeInsets
                                          .all(
                                    24,
                                  ),

                                  decoration:
                                      BoxDecoration(
                                    color:
                                        cardDarkPurple,

                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      16,
                                    ),
                                  ),

                                  child: Center(
                                    child: Text(
                                      "No tasks assigned to this timeline node.",

                                      style: GoogleFonts
                                          .outfit(
                                        color: Colors
                                            .grey
                                            .shade600,
                                        fontSize:
                                            13,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView
                                  .builder(
                                  shrinkWrap:
                                      true,

                                  physics:
                                      const NeverScrollableScrollPhysics(),

                                  itemCount:
                                      activeDayDocs
                                          .length,

                                  itemBuilder:
                                      (
                                    context,
                                    index,
                                  ) {

                                    final doc =
                                        activeDayDocs[
                                            index];

                                    final task =
                                        doc.data()
                                            as Map<String,
                                                dynamic>;

                                    final String
                                        courseName =
                                        task['course'] ??
                                            'General';

                                    final String
                                        category =
                                        task['category'] ??
                                            'Other';

                                    final Color
                                        catColor =
                                        _getCategoryColor(
                                      category,
                                    );

                                    final int
                                        expGained =
                                        task['exp'] ??
                                            10;

                                    final int
                                        coinsGained =
                                        task['coins'] ??
                                            5;

                                    return Card(
                                      // Task 2.2: make the task look dimmed when it's marked as done
                                      color: (task['isDone'] ??
                                              false)
                                          ? cardDarkPurple
                                              .withOpacity(
                                                  0.6)
                                          : cardDarkPurple,

                                      margin:
                                          const EdgeInsets
                                              .only(
                                        bottom:
                                            10,
                                      ),

                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                                14),

                                        side:
                                            BorderSide(
                                          color: const Color(
                                                  0xFF240046)
                                              .withOpacity(
                                                  0.5),
                                        ),
                                      ),

                                      // Task 2: fix check box
                                      child:
                                          ListTile(
                                        leading:
                                            Container(
                                          width: 4,
                                          height:
                                              26,
                                          color:
                                              catColor,
                                        ),

                                        title:
                                            Text(
                                          // task 2.1: stlh complete task biar dia lbh faded/less active
                                          task['title'],

                                          style:
                                              GoogleFonts.outfit(
                                            color: (task['isDone'] ??
                                                    false)
                                                ? Colors.white54
                                                : Colors.white,

                                            fontSize:
                                                15,

                                            decoration: (task['isDone'] ??
                                                    false)
                                                ? TextDecoration.lineThrough
                                                : null,

                                            decorationColor:
                                                Colors.grey,
                                          ),
                                        ),

                                        subtitle:
                                            Text(
                                          "${courseName.toUpperCase()} • $category",

                                          style:
                                              GoogleFonts.outfit(
                                            color: Colors
                                                .grey
                                                .shade500,
                                            fontSize:
                                                11,
                                          ),
                                        ),

                                        trailing:
                                            IconButton(
                                          icon:
                                              Icon(
                                            (task['isDone'] ??
                                                    false)
                                                ? Icons.check_circle
                                                : Icons.radio_button_off,

                                            color: (task['isDone'] ??
                                                    false)
                                                ? Colors.greenAccent
                                                : neonLightPurple,
                                          ),

                                          onPressed:
                                              (task['isDone'] ??
                                                      false)
                                                  ? null
                                                  : () async {

                                                      setState(() {
                                                        task['isDone'] = true;
                                                      });

                                                      await FirebaseFirestore.instance
                                                          .collection('users')
                                                          .doc(widget.studentID)
                                                          .collection('tasks')
                                                          .doc(doc.id)
                                                          .update({
                                                        'isDone': true,
                                                      });

                                                      /*
                                                      Provider.of<PetProvider>(
                                                        context,
                                                        listen: false,
                                                      ).awardGrowthPoints(
                                                        studentID: widget.studentID,
                                                        exp: task['exp'],
                                                        coins: task['coins'],
                                                      );
                                                      */
                                                    },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          floatingActionButton:
              FloatingActionButton
                  .extended(
            backgroundColor:
                const Color(0xFF7B2CBF),

            label: Text(
              "ADD QUEST",
              style:
                  GoogleFonts.orbitron(
                fontWeight:
                    FontWeight.bold,
                color: Colors.white,
                fontSize: 12,
              ),
            ),

            icon: const Icon(
              Icons.add,
              color: Colors.white,
            ),

            onPressed:
                _showAddTaskDialog,
          ),
        );
      },
    );
  }
}