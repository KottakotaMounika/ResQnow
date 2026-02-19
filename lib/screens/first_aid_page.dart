// lib/screens/first_aid_page.dart
import 'package:flutter/material.dart';

class FirstAidPage extends StatelessWidget {
  const FirstAidPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("First-Aid Guide"),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          // Emergency Numbers Card
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.emergency, color: Colors.red.shade700, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        "Emergency Numbers",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text("🚨 Police: 100 • 🏥 Ambulance: 108 • 🔥 Fire: 101"),
                  const Text("📞 Emergency Helpline: 112"),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),

          // Basic First Aid
          _buildSection(context, "Basic Emergency Care", [
            _buildAidCard(
              context,
              'CPR (Cardiopulmonary Resuscitation)',
              Icons.favorite_border,
              [
                '1. Check Responsiveness: Tap shoulders and shout "Are you okay?"',
                '2. Call for Help: Call 108 immediately or ask someone else to do it',
                '3. Check Airway: Tilt head back, lift chin to open airway',
                '4. Check Breathing: Look, listen, and feel for breathing for 10 seconds',
                '5. Chest Compressions: Place heel of hand on center of chest',
                '6. Push hard and fast: At least 2 inches deep, 100-120 compressions per minute',
                '7. Give Rescue Breaths: Tilt head, lift chin, pinch nose, give 2 breaths',
                '8. Continue Cycles: 30 compressions, 2 breaths until help arrives',
                '⚠️ Important: Get trained in CPR from certified instructors',
              ],
              Colors.red.shade100,
            ),
            _buildAidCard(
              context,
              'Recovery Position',
              Icons.airline_seat_flat,
              [
                '1. Check if person is unconscious but breathing normally',
                '2. Kneel beside them and straighten their legs',
                '3. Place arm nearest to you at right angles to their body',
                '4. Bring far arm across chest, place back of hand against near cheek',
                '5. With your other hand, grasp far leg just above knee and pull up',
                '6. Roll them toward you by pulling on their leg',
                '7. Adjust top leg so both hip and knee are bent at right angles',
                '8. Tilt head back to keep airway open',
                '⚠️ Monitor breathing and pulse regularly',
              ],
              Colors.blue.shade100,
            ),
          ]),

          // Wound Care
          _buildSection(context, "Wound Care", [
            _buildAidCard(
              context,
              'Cuts & Bleeding',
              Icons.healing_outlined,
              [
                '1. Protect Yourself: Wear gloves if available',
                '2. Apply Direct Pressure: Use clean cloth, press firmly on wound',
                '3. Elevate: Raise injured part above heart level if possible',
                '4. Maintain Pressure: Don\'t remove cloth, add more if needed',
                '5. Pressure Points: If bleeding doesn\'t stop, apply pressure to arterial points',
                '6. Clean Wound: Once bleeding stops, rinse gently with clean water',
                '7. Cover: Apply sterile bandage, change daily',
                '8. Watch for Infection: Swelling, redness, warmth, pus, red streaking',
                '⚠️ Seek medical help for deep cuts, puncture wounds, or signs of infection',
              ],
            ),
            _buildAidCard(
              context,
              'Burns (Minor)',
              Icons.local_fire_department_outlined,
              [
                '1. Remove from Heat Source: Ensure safety first',
                '2. Cool the Burn: Hold under cool (not cold) water for 10-20 minutes',
                '3. Remove Jewelry: Gently remove before swelling occurs',
                '4. Don\'t Break Blisters: They protect against infection',
                '5. Apply Aloe Vera: Or cool, moist compress',
                '6. Cover Loosely: Use sterile, non-fluffy bandage',
                '7. Over-the-counter Pain Relief: Ibuprofen or acetaminophen',
                '8. Stay Hydrated: Drink plenty of fluids',
                '❌ Do NOT use: Ice, butter, oils, egg whites, or toothpaste',
                '⚠️ Seek medical help for burns larger than palm size or on face/joints',
              ],
              Colors.orange.shade100,
            ),
            _buildAidCard(
              context,
              'Severe Burns',
              Icons.warning_amber,
              [
                '1. Call 108 Immediately: This is a medical emergency',
                '2. Remove from Source: Ensure your safety first',
                '3. Don\'t Remove Clothing: If stuck to skin',
                '4. Cool with Water: Pour cool water over burn for 20 minutes',
                '5. Cover with Clean Cloth: Protect from infection',
                '6. Treat for Shock: Lay flat, elevate legs, keep warm',
                '7. Monitor Vital Signs: Breathing, pulse, consciousness',
                '❌ Do NOT: Use ice, break blisters, apply ointments',
                '⚠️ Signs of severe burns: White/charred skin, deep burns, burns on face/hands/feet/genitals',
              ],
              Colors.red.shade100,
            ),
          ]),

          // Breathing Emergencies
          _buildSection(context, "Breathing Emergencies", [
            _buildAidCard(
              context,
              'Choking (Adult)',
              Icons.air_outlined,
              [
                '1. Assess Situation: Can they speak, cough, or breathe?',
                '2. Encourage Coughing: If they can cough, encourage forceful coughing',
                '3. Back Blows: Stand behind, lean forward, give 5 sharp blows between shoulder blades',
                '4. Abdominal Thrusts (Heimlich): Stand behind, wrap arms around waist',
                '5. Make a Fist: Place above navel, below rib cage',
                '6. Quick Upward Thrusts: Give 5 quick, upward thrusts',
                '7. Alternate: Continue alternating 5 back blows and 5 abdominal thrusts',
                '8. Call 108: If object doesn\'t dislodge or person becomes unconscious',
                '⚠️ For pregnant women or obese adults: Use chest thrusts instead',
              ],
            ),
            _buildAidCard(
              context,
              'Choking (Infant)',
              Icons.child_care,
              [
                '1. Hold Infant Face Down: Support head and neck, place on your forearm',
                '2. Back Blows: Give 5 gentle but firm blows between shoulder blades',
                '3. Turn Over: Support head, turn face up on your forearm',
                '4. Chest Thrusts: Use 2 fingers, push on center of chest 5 times',
                '5. Check Mouth: Look for object, remove if visible and loose',
                '6. Repeat Cycle: Back blows, chest thrusts, check mouth',
                '7. Call 108: If object doesn\'t dislodge',
                '8. CPR if Unconscious: Begin infant CPR if baby becomes unresponsive',
                '❌ Do NOT: Turn infant upside down by feet, use abdominal thrusts',
              ],
              Colors.pink.shade100,
            ),
            _buildAidCard(
              context,
              'Asthma Attack',
              Icons.air,
              [
                '1. Help Patient Sit Upright: Leaning slightly forward',
                '2. Stay Calm: Keep patient calm and reassured',
                '3. Locate Inhaler: Help find and use rescue inhaler (usually blue)',
                '4. Shake Inhaler: Shake well before use',
                '5. Use Spacer: If available, attach spacer device',
                '6. Breathe Slowly: One puff, breathe in slowly and deeply, hold 10 seconds',
                '7. Wait and Repeat: Wait 1 minute, then repeat if needed',
                '8. Monitor: Watch for improvement in breathing',
                '🚨 Call 108 if: No improvement after inhaler, can\'t speak in full sentences, lips/fingers turn blue',
              ],
              Colors.lightBlue.shade100,
            ),
          ]),

          // Medical Emergencies
          _buildSection(context, "Medical Emergencies", [
            _buildAidCard(
              context,
              'Heart Attack',
              Icons.monitor_heart,
              [
                '1. Call 108 Immediately: Time is critical',
                '2. Recognize Signs: Chest pain, shortness of breath, nausea, sweating',
                '3. Have Patient Rest: Sit or lie down in comfortable position',
                '4. Loosen Clothing: Around neck and chest',
                '5. Give Aspirin: If not allergic, give one adult aspirin to chew',
                '6. Monitor Vital Signs: Stay with patient, watch breathing',
                '7. Be Ready for CPR: If patient loses consciousness',
                '8. Stay Calm: Reassure patient that help is coming',
                '⚠️ Signs: Crushing chest pain, pain radiating to arm/jaw, cold sweat',
              ],
              Colors.red.shade100,
            ),
            _buildAidCard(
              context,
              'Stroke (F.A.S.T.)',
              Icons.psychology,
              [
                '🅵 Face Drooping: Ask person to smile, check if smile is uneven',
                '🅰 Arm Weakness: Ask to raise both arms, check if one drifts down',
                '🆂 Speech Difficulty: Ask to repeat simple phrase, check for slurred speech',
                '🆃 Time to Call 108: If any signs present, note time symptoms started',
                '5. Additional Signs: Sudden confusion, vision problems, severe headache',
                '6. Keep Patient Comfortable: Don\'t give food or water',
                '7. Monitor Closely: Watch for changes in condition',
                '8. Note Symptoms: Write down time symptoms started for medical team',
                '⚠️ Every minute counts - immediate medical attention is critical',
              ],
              Colors.purple.shade100,
            ),
            _buildAidCard(
              context,
              'Seizures',
              Icons.flash_on,
              [
                '1. Stay Calm: Most seizures last 1-2 minutes and stop on their own',
                '2. Protect from Injury: Move dangerous objects away',
                '3. Cushion Head: Place something soft under head',
                '4. Turn on Side: To prevent choking if vomiting occurs',
                '5. Time the Seizure: Note start time',
                '6. Don\'t Restrain: Never hold person down',
                '7. Stay with Person: Until fully conscious',
                '8. Call 108 if: Seizure lasts over 5 minutes, multiple seizures, injury occurs, first time seizure',
                '❌ Do NOT: Put anything in their mouth, give water or food',
              ],
              Colors.yellow.shade100,
            ),
            _buildAidCard(
              context,
              'Diabetic Emergency',
              Icons.medical_information,
              [
                '1. Check Consciousness: Is person alert and responsive?',
                '2. If Conscious and Can Swallow: Give sugary drink or candy',
                '3. Low Blood Sugar Signs: Sweating, shakiness, confusion, pale skin',
                '4. High Blood Sugar Signs: Extreme thirst, frequent urination, fruity breath',
                '5. Follow Their Plan: Most diabetics have emergency plan',
                '6. Don\'t Give Insulin: Unless you\'re trained and authorized',
                '7. Monitor Closely: Stay with person',
                '8. Call 108 if: Unconscious, vomiting, doesn\'t improve in 15 minutes',
                '⚠️ When in doubt, treat as low blood sugar emergency',
              ],
            ),
          ]),

          // Injuries
          _buildSection(context, "Common Injuries", [
            _buildAidCard(
              context,
              'Sprains & Strains',
              Icons.healing,
              [
                '🆁 Rest: Stop activity, don\'t use injured area',
                '🧊 Ice: Apply for 15-20 minutes every 2-3 hours for first 48 hours',
                '🔄 Compression: Use elastic bandage, not too tight',
                '⬆️ Elevation: Raise injured area above heart level when possible',
                '5. Pain Relief: Over-the-counter pain medication as directed',
                '6. Gradual Return: Slowly return to activity as pain decreases',
                '7. Seek Medical Help if: Severe pain, numbness, can\'t bear weight',
                '⚠️ Difference: Sprain affects ligaments, strain affects muscles/tendons',
              ],
            ),
            _buildAidCard(
              context,
              'Fractures (Broken Bones)',
              Icons.accessible_forward,
              [
                '1. Don\'t Move: Keep person still, don\'t try to realign bone',
                '2. Call 108: For suspected fractures',
                '3. Support Injury: Immobilize area above and below fracture',
                '4. Use Splints: Rigid materials like boards, rolled newspapers',
                '5. Pad Splints: Use cloth or towels for comfort',
                '6. Treat for Shock: Keep warm, elevate legs if no spinal injury',
                '7. Monitor Circulation: Check pulse, skin color beyond injury',
                '8. Ice Application: Apply ice pack wrapped in cloth',
                '⚠️ Open Fracture: Don\'t push bone back in, cover with sterile gauze',
              ],
              Colors.grey.shade200,
            ),
            _buildAidCard(
              context,
              'Head Injuries',
              Icons.psychology_outlined,
              [
                '1. Keep Person Still: Don\'t move unless necessary',
                '2. Call 108: For any significant head injury',
                '3. Monitor Consciousness: Check alertness, confusion',
                '4. Control Bleeding: Apply pressure around wound, not directly on skull',
                '5. Watch for Symptoms: Vomiting, vision changes, memory loss',
                '6. Keep Awake: If person is drowsy but conscious',
                '7. Apply Ice: To reduce swelling (wrapped in cloth)',
                '8. Don\'t Give Medications: Could mask important symptoms',
                '🚨 Emergency Signs: Loss of consciousness, severe confusion, repeated vomiting',
              ],
              Colors.red.shade100,
            ),
          ]),

          // Environmental Emergencies
          _buildSection(context, "Environmental Emergencies", [
            _buildAidCard(
              context,
              'Heat Stroke',
              Icons.wb_sunny,
              [
                '1. Call 108 Immediately: This is life-threatening',
                '2. Move to Cool Area: Get out of heat and sun',
                '3. Remove Excess Clothing: Help body cool down',
                '4. Cool Aggressively: Ice packs on neck, armpits, groin',
                '5. Fan the Person: Increase air circulation',
                '6. Monitor Temperature: Goal is to reduce quickly',
                '7. If Conscious: Give cool water to sip slowly',
                '8. Be Ready for Seizures: Heat stroke can cause complications',
                '⚠️ Signs: High body temperature, altered mental state, hot/dry skin or profuse sweating',
              ],
              Colors.red.shade100,
            ),
            _buildAidCard(
              context,
              'Hypothermia',
              Icons.ac_unit,
              [
                '1. Call 108: For moderate to severe hypothermia',
                '2. Move to Warm Area: Get out of cold environment',
                '3. Remove Wet Clothing: Replace with dry, loose clothing',
                '4. Insulate Body: Cover with blankets, focus on core',
                '5. Give Warm Drinks: If conscious, no alcohol or caffeine',
                '6. Warm Gradually: Avoid rapid rewarming',
                '7. Handle Gently: Sudden movements can cause dangerous heart rhythms',
                '8. Monitor Breathing: Be prepared for CPR',
                '⚠️ Signs: Shivering, confusion, drowsiness, slurred speech',
              ],
              Colors.blue.shade100,
            ),
            _buildAidCard(
              context,
              'Drowning',
              Icons.pool,
              [
                '1. Ensure Scene Safety: Don\'t become a victim yourself',
                '2. Call 108: Even if person seems fine afterward',
                '3. Remove from Water: Use reaching assist, throw flotation',
                '4. Check Breathing: Look, listen, feel',
                '5. Begin Rescue Breathing: If not breathing, start immediately',
                '6. Clear Airway: Remove visible obstructions',
                '7. CPR if No Pulse: Begin chest compressions',
                '8. Keep Warm: Prevent hypothermia',
                '⚠️ Dry Drowning: Monitor for hours after - water in lungs can cause delayed problems',
              ],
              Colors.blue.shade100,
            ),
          ]),

          // Poisoning
          _buildSection(context, "Poisoning", [
            _buildAidCard(
              context,
              'General Poisoning',
              Icons.warning_rounded,
              [
                '1. Identify the Poison: Keep container or take photo',
                '2. Call Poison Control: India - 1800-110-0229',
                '3. Follow Instructions: From poison control center',
                '4. Don\'t Induce Vomiting: Unless specifically told to',
                '5. Remove from Exposure: Fresh air if inhaled, remove contaminated clothing',
                '6. Rinse Skin/Eyes: With water for chemical exposure',
                '7. Give Activated Charcoal: Only if instructed by professionals',
                '8. Save Evidence: Bring poison container to hospital',
                '⚠️ Signs: Nausea, vomiting, confusion, difficulty breathing, burns around mouth',
              ],
              Colors.orange.shade100,
            ),
          ]),

          // Footer with Important Notes
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        "Important Reminders",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text("• Always call for professional medical help in serious emergencies"),
                  const Text("• Get proper first aid training from certified instructors"),
                  const Text("• Keep a well-stocked first aid kit at home and in your car"),
                  const Text("• Know the location of the nearest hospital"),
                  const Text("• This guide is for reference only and doesn't replace professional training"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAidCard(
    BuildContext context, 
    String title, 
    IconData icon, 
    List<String> steps,
    [Color? backgroundColor]
  ) {
    return Card(
      color: backgroundColor,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        leading: Icon(
          icon, 
          color: Theme.of(context).colorScheme.error, 
          size: 32
        ),
        title: Text(
          title, 
          style: const TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.w600
          )
        ),
        children: steps.map((step) => Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            step,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        )).toList(),
      ),
    );
  }
}