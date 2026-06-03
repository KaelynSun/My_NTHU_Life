//import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_nthu_life/pet_files/pet_data.dart';
import 'package:my_nthu_life/services/firestore_services.dart';
//import 'package:shared_preferences/shared_preferences.dart';

class PetDashboardWidget extends StatefulWidget {
  final int currentCredits;
  final String studentID; // Scoped to student ID to prevent multi-account data leakage

  const PetDashboardWidget({
    super.key,
    required this.currentCredits,
    required this.studentID,
  });

  // ===== COLOR SCHEME CONFIGURATION =====
  static const purpleMain = Color(0xFF7C3AED);
  static const purpleDark = Color(0xFF6D28D9);

  @override
  State<PetDashboardWidget> createState() =>
      _PetDashboardWidgetState();
}

class _PetDashboardWidgetState
    extends State<PetDashboardWidget> {

  final FirestoreService _firestoreService = FirestoreService();
  StreakPet? _currentPet;

  Future<void> _initializeNewPet(String name) async {
    final newPet = StreakPet(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      currentLevel: 1,
      growthPoints: 0,
      currentStreak: 1,
      currentStage: 'egg',
      coins: 100, // pas final balikin lg ke 0.

      ownedAccessories: [], // New field for tracking owned accessories
      equippedAccessory: '', // New field for currently equipped accessory
    );
    
    // Sikka: change sharedpreferences to firestore
    
    /*
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'user_streak_pet',
      jsonEncode(newPet.toJson()),
    );
    */

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.studentID)
        .set({
      'pet': newPet.toJson(),
    }, SetOptions(merge: true));

    setState(() {
      _currentPet = newPet;
    });
  }

  // Sikka: Accessory Shop Data
  final List<Map<String, dynamic>> accessories = [
    {
      'name': '👓 Cool Glasses',
      'price': 20,
    },
    {
      'name': '🎀 Pink Ribbon',
      'price': 25,
    },
    {
      'name': '🪄 Wizard Hat',
      'price': 40,
    },
    {
      'name': '👑 Golden Crown',
      'price': 60,
    },
  ];

  // Sikka: pet shop
  Future<void> _buyAccessory(String itemName, int price) async {
    if (_currentPet == null) return;

    if (_currentPet!.coins < price) return;

    setState(() {
      _currentPet!.coins -= price;
      _currentPet!.ownedAccessories.add(itemName);
    });

    // sikka: ganti sharedpreferences ke firestore
    /*
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'user_streak_pet',
      jsonEncode(_currentPet!.toJson()),
    );
    */
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.studentID)
        .set({
      'pet': _currentPet!.toJson(),
    }, SetOptions(merge: true));
  }

  Future<void> _equipAccessory(String itemName) async {
    if (_currentPet == null) return;

    setState(() {
      _currentPet!.equippedAccessory = itemName;
    });

    // sikka: ganti sharedpreferences ke firestore
    /*
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'user_streak_pet',
      jsonEncode(_currentPet!.toJson()),
    );
    */
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.studentID)
        .set({
      'pet': _currentPet!.toJson(),
    }, SetOptions(merge: true));
  }

  void _showAccessoryShop() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A102B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Pet Accessory Shop",
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              ...accessories.map((item) {
                final bool owned =
                    _currentPet!.ownedAccessories.contains(
                      item['name'],
                    );

                final bool equipped =
                    _currentPet!.equippedAccessory ==
                        item['name'];

                return Card(
                  color: const Color(0xFF2A1B3D),
                  child: ListTile(
                    title: Text(
                      item['name'],
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),

                    subtitle: Text(
                      "${item['price']} Coins",
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),

                    trailing: owned
                        ? ElevatedButton(
                            onPressed: () {
                              _equipAccessory(
                                item['name'],
                              );

                              Navigator.pop(context);
                            },
                            child: Text(
                              equipped
                                  ? "Equipped"
                                  : "Equip",
                            ),
                          )
                        : ElevatedButton(
                            onPressed: () {
                              _buyAccessory(
                                item['name'],
                                item['price'],
                              );

                              Navigator.pop(context);
                            },
                            child: const Text("Buy"),
                          ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // Sikka: pet hub
  void _showPetHub() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A102B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // title
                Text(
                  "🐾 Pet Hub",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                // pet image
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      _getPetAssetPath(
                        _currentPet!.currentStage,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // pet name
                Text(
                  _currentPet!.name,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Lv. ${_currentPet!.currentLevel} • ${_currentPet!.rank}",
                  style: GoogleFonts.outfit(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 20),

                // equipped item
                Text(
                  "✨ Equipped Accessory",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1B3D),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _currentPet!.equippedAccessory.isEmpty
                        ? "No accessory equipped"
                        : _currentPet!.equippedAccessory,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                    ),
                  ),
                ),

                // Sikka: Owned accessories section
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "🎒 Owned Accessories",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1B3D),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _currentPet!.ownedAccessories.isEmpty
                      ? Text(
                          "No accessories owned yet",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: Colors.grey.shade400,
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              _currentPet!.ownedAccessories
                                  .map((item) {
                            return Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF7B2CBF),
                                borderRadius:
                                    BorderRadius.circular(
                                  12,
                                ),
                              ),
                              child: Text(
                                item,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showAccessoryShop();
                  },
                  icon: const Icon(
                    Icons.shopping_bag_outlined,
                  ),
                  label:
                      const Text("Open Accessory Shop"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF7B2CBF),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentID)
          .snapshots(),
      builder: (context, snapshot) {

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const SizedBox(
              height: 140,
              child: Center(
                child: CircularProgressIndicator(
                  color: PetDashboardWidget.purpleMain,
                ),
              ),
            ),
          );
        }

        final userData = snapshot.data?.data() ?? {};

        // Return hatching placeholder option card if profile dataset doesn't have a pet map entry
        if (userData['pet'] == null) {
          return Card(
            elevation: 4,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "You don't have a streak pet yet!",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                      color: theme
                          .colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Hatch an egg and complete your daily targets in NTHYou to grow your companion.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: theme.colorScheme
                          .onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton
                        .styleFrom(
                      backgroundColor:
                          PetDashboardWidget
                              .purpleMain,
                      foregroundColor:
                          Colors.white,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                                10),
                      ),
                    ),
                    onPressed: () =>
                        _initializeNewPet(
                      "NTHU Buddy",
                    ),
                    child: Text(
                      "Hatch My First Egg",
                      style: GoogleFonts.outfit(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        _currentPet =
            StreakPet.fromJson(userData['pet']);

        final pet = _currentPet!;

        return Card(
          elevation: 4,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
          child: Padding(
            padding:
                const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [

                Row(
                  children: [

                    GestureDetector(
                      onTap: _showPetHub,
                      child: Container(
                        width: 65,
                        height: 65,
                        decoration:
                            BoxDecoration(
                          color: Colors
                              .purple
                              .withOpacity(
                                  0.12),
                          shape:
                              BoxShape.circle,
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius
                                  .circular(
                                      32),
                          child: Padding(
                            padding:
                                const EdgeInsets
                                    .all(8.0),
                            child:
                                Image.asset(
                              _getPetAssetPath(
                                pet.currentStage,
                              ),
                              fit: BoxFit
                                  .contain,
                              alignment:
                                  Alignment
                                      .center,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [

                          Row(
                            children: [

                              Expanded(
                                child: Text(
                                  pet.name,
                                  style:
                                      const TextStyle(
                                    fontSize:
                                        18,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                ),
                              ),

                              const SizedBox(
                                  width: 8),

                              const Icon(
                                Icons
                                    .monetization_on_rounded,
                                color: Color(
                                    0xFFFFB74D),
                                size: 14,
                              ),

                              const SizedBox(
                                  width: 4),

                              Text(
                                "${pet.coins}",
                                style:
                                    GoogleFonts
                                        .outfit(
                                  fontSize:
                                      12,
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                  color: Theme.of(
                                          context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                              height: 4),

                          Text(
                            "Lv. ${pet.currentLevel} • ${pet.currentStage.toUpperCase()}",
                            style: TextStyle(
                              color: Colors
                                  .grey
                                  .shade600,
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(
                              height: 4),

                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .center,
                            children: [

                              Image.asset(
                                _getRankBadgeAsset(
                                  pet.rank,
                                ),
                                width: 18,
                                height: 18,
                                fit: BoxFit
                                    .contain,
                                errorBuilder:
                                    (
                                  context,
                                  error,
                                  stackTrace,
                                ) {
                                  return const Icon(
                                    Icons
                                        .shield_rounded,
                                    size: 16,
                                    color: Colors
                                        .grey,
                                  );
                                },
                              ),

                              const SizedBox(
                                  width: 5),

                              Text(
                                pet.rank,
                                style:
                                    TextStyle(
                                  color:
                                      _getRankColor(
                                    pet.rank,
                                  ),
                                  fontSize:
                                      13,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                ),
                              ),

                              Expanded(
                                child: Text(
                                  " • ${pet.title}",
                                  style:
                                      TextStyle(
                                    color: Colors
                                        .grey
                                        .shade700,
                                    fontSize:
                                        13,
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.amber.shade700,
                        borderRadius:
                            BorderRadius
                                .circular(12),
                      ),
                      child: Text(
                        "🔥 ${pet.currentStreak} Day",
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    const Text(
                      "Growth Progress",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                    Text(
                      "${pet.growthPoints} / 100 EXP",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors
                            .grey.shade600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(
                          10),
                  child:
                      LinearProgressIndicator(
                    value:
                        pet.growthPoints /
                            100,
                    backgroundColor:
                        Colors.grey.shade200,
                    valueColor:
                        const AlwaysStoppedAnimation<
                            Color>(
                      Colors.green,
                    ),
                    minHeight: 12,
                  ),
                ),

                const SizedBox(height: 16),

                // Task 1: hapus tombol cheat EXP.
                /*
                ElevatedButton.icon(
                  onPressed: _simulateEarnEXP,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text("Simulate Completing a Habit (+20 EXP)"),
                ),
                */

                SizedBox(
                  width: double.infinity,
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        _showAccessoryShop,
                    icon: const Icon(
                      Icons
                          .shopping_bag_outlined,
                    ),
                    label: const Text(
                      "Accessory Shop",
                    ),
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          const Color(
                              0xFF7B2CBF),
                      foregroundColor:
                          Colors.white,
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 14,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                                    14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getRankColor(String rank) {
    switch (rank) {
      case 'Bronze':
        return const Color(0xFF8C5A2B);

      case 'Silver':
        return const Color(0xFF6E7C91);

      case 'Gold':
        return const Color(0xFFB38B2D);

      case 'Diamond':
        return const Color(0xFF3AA6A0);

      default:
        return Colors.black87;
    }
  }

  String _getRankBadgeAsset(String rank) {
    switch (rank) {
      case 'Bronze':
        return 'assets/badge/bronze_badge.png';

      case 'Silver':
        return 'assets/badge/silver.png';

      case 'Gold':
        return 'assets/badge/gold_badge.png';

      case 'Diamond':
        return 'assets/badge/diamond_badge.png';

      default:
        return 'assets/badge/bronze_badge.png';
    }
  }

  String _getPetAssetPath(String stage) {
    switch (stage) {
      case 'egg':
        return 'assets/pet/Egg.png';

      case 'baby':
        return 'assets/pet/baby.png';

      case 'juvenile':
        return 'assets/pet/juvenile.png';

      case 'adult':
        return 'assets/pet/adult.png';

      default:
        return 'assets/pet/adult.png';
    }
  }
}