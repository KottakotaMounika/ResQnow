// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:http/http.dart' as http;
// import 'package:latlong2/latlong.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter_sound/flutter_sound.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as path;
// import 'package:permission_handler/permission_handler.dart';
// import '../services/location_service.dart';
// import '../services/storage_service.dart';
// import '../models/fir_model.dart';
// import 'fir_detail_page.dart';

// class PoliceServicesPage extends StatelessWidget {
//   const PoliceServicesPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Police Services'),
//         backgroundColor: Theme.of(context).colorScheme.surface,
//         elevation: 0,
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Theme.of(context).colorScheme.surface,
//               Theme.of(context).colorScheme.background,
//             ],
//           ),
//         ),
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             _buildServiceCard(
//               context,
//               icon: Icons.report_outlined,
//               title: 'File Incident Report',
//               subtitle: 'Report incidents with multimedia evidence',
//               color: Colors.red,
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => const AccidentReportPage()),
//               ),
//             ),
//             const SizedBox(height: 16),
//             _buildServiceCard(
//               context,
//               icon: Icons.folder_outlined,
//               title: 'View My Reports (FIR)',
//               subtitle: 'Check status and view submitted reports',
//               color: Colors.blue,
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => const ViewFIRPage()),
//               ),
//             ),
//             const SizedBox(height: 16),
//             _buildServiceCard(
//               context,
//               icon: Icons.location_on_outlined,
//               title: 'Nearby Police Stations',
//               subtitle: 'Find police stations on interactive map',
//               color: Colors.green,
//               onTap: () async {
//                 final locationResult = await LocationService.getCurrentLocation();
//                 locationResult.fold(
//                   (error) {
//                     if (context.mounted) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text(error),
//                           backgroundColor: Colors.red,
//                         ),
//                       );
//                     }
//                   },
//                   (position) {
//                     if (context.mounted) {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => NearbyPoliceMap(
//                             userLocation: LatLng(position.latitude, position.longitude),
//                           ),
//                         ),
//                       );
//                     }
//                   },
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildServiceCard(
//     BuildContext context, {
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return Card(
//       elevation: 4,
//       shadowColor: color.withOpacity(0.3),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(16),
//         child: Container(
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(16),
//             gradient: LinearGradient(
//               colors: [Colors.white, color.withOpacity(0.05)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//           child: Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Icon(icon, color: color, size: 32),
//               ),
//               const SizedBox(width: 20),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 18,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       subtitle,
//                       style: TextStyle(
//                         color: Colors.grey[600],
//                         fontSize: 14,
//                         height: 1.4,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Icon(
//                 Icons.arrow_forward_ios,
//                 size: 20,
//                 color: Colors.grey[400],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class AccidentReportPage extends StatefulWidget {
//   const AccidentReportPage({super.key});
  
//   @override
//   State<AccidentReportPage> createState() => _AccidentReportPageState();
// }

// class _AccidentReportPageState extends State<AccidentReportPage> {
//   final _formKey = GlobalKey<FormState>();
//   String _severity = 'Moderate';
//   String _location = 'Fetching location...';
//   final _typeController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   final _storageService = StorageService();

//   // Media recording and storage
//   FlutterSoundRecorder? _soundRecorder;
//   bool _isRecording = false;
//   String? _audioPath;
//   List<String> _photoPaths = [];
//   List<String> _videoPaths = [];
//   bool _isLoadingLocation = true;

//   @override
//   void initState() {
//     super.initState();
//     _getLocation();
//     _initializeRecorder();
//   }

//   @override
//   void dispose() {
//     _typeController.dispose();
//     _descriptionController.dispose();
//     _soundRecorder?.closeRecorder();
//     super.dispose();
//   }

//   Future<void> _initializeRecorder() async {
//     _soundRecorder = FlutterSoundRecorder();
//     await _soundRecorder!.openRecorder();
//   }

//   Future<void> _getLocation() async {
//     setState(() => _isLoadingLocation = true);
//     final locationResult = await LocationService.getCurrentLocation();
//     locationResult.fold(
//       (error) => setState(() {
//         _location = 'Could not fetch location';
//         _isLoadingLocation = false;
//       }),
//       (position) => setState(() {
//         _location = "${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}";
//         _isLoadingLocation = false;
//       }),
//     );
//   }

//   Future<void> _capturePhoto() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.image,
//         allowMultiple: true,
//       );

//       if (result != null) {
//         final directory = await getApplicationDocumentsDirectory();
//         final timestamp = DateTime.now().millisecondsSinceEpoch;
        
//         for (int i = 0; i < result.files.length; i++) {
//           final file = result.files[i];
//           if (file.path != null) {
//             final newPath = path.join(directory.path, 'evidence_photo_${timestamp}_$i.jpg');
//             await File(file.path!).copy(newPath);
//             setState(() {
//               _photoPaths.add(newPath);
//             });
//           }
//         }
        
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('✅ ${result.files.length} photo(s) added successfully'),
//               backgroundColor: Colors.green,
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('❌ Error capturing photo: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _captureVideo() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.video,
//         allowMultiple: true,
//       );

//       if (result != null) {
//         final directory = await getApplicationDocumentsDirectory();
//         final timestamp = DateTime.now().millisecondsSinceEpoch;
        
//         for (int i = 0; i < result.files.length; i++) {
//           final file = result.files[i];
//           if (file.path != null) {
//             final newPath = path.join(directory.path, 'evidence_video_${timestamp}_$i.mp4');
//             await File(file.path!).copy(newPath);
//             setState(() {
//               _videoPaths.add(newPath);
//             });
//           }
//         }
        
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('✅ ${result.files.length} video(s) added successfully'),
//               backgroundColor: Colors.green,
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('❌ Error capturing video: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _startRecording() async {
//     try {
//       final permission = await Permission.microphone.request();
//       if (permission != PermissionStatus.granted) {
//         throw 'Microphone permission not granted';
//       }

//       final directory = await getApplicationDocumentsDirectory();
//       final timestamp = DateTime.now().millisecondsSinceEpoch;
//       final audioPath = path.join(directory.path, 'evidence_audio_$timestamp.aac');

//       await _soundRecorder!.startRecorder(toFile: audioPath);
//       setState(() {
//         _isRecording = true;
//         _audioPath = audioPath;
//       });
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('❌ Error starting recording: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _stopRecording() async {
//     try {
//       await _soundRecorder!.stopRecorder();
//       setState(() {
//         _isRecording = false;
//       });
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('✅ Audio recorded successfully'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('❌ Error stopping recording: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   void _removePhoto(int index) {
//     setState(() {
//       _photoPaths.removeAt(index);
//     });
//   }

//   void _removeVideo(int index) {
//     setState(() {
//       _videoPaths.removeAt(index);
//     });
//   }

//   void _removeAudio() {
//     setState(() {
//       _audioPath = null;
//     });
//   }

//   void _submitReport() async {
//     if (_formKey.currentState!.validate()) {
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => const AlertDialog(
//           content: Row(
//             children: [
//               CircularProgressIndicator(),
//               SizedBox(width: 16),
//               Text("Submitting report..."),
//             ],
//           ),
//         ),
//       );

//       try {
//         final fir = FIR(
//           accidentType: _typeController.text.trim(),
//           description: _descriptionController.text.trim(),
//           severity: _severity,
//           location: _location,
//           dateTime: DateTime.now(),
//           status: 'Submitted',
//           photoPaths: _photoPaths.isEmpty ? null : _photoPaths,
//           videoPaths: _videoPaths.isEmpty ? null : _videoPaths,
//           audioPath: _audioPath,
//         );
        
//         await _storageService.insertFIR(fir);

//         if (mounted) {
//           Navigator.pop(context); // Close loading dialog
//           showDialog(
//             context: context,
//             builder: (_) => AlertDialog(
//               icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
//               title: const Text("Report Submitted Successfully"),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text("Your incident report has been submitted with:"),
//                   const SizedBox(height: 12),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       _buildEvidenceChip(Icons.photo, '${_photoPaths.length}', 'Photos'),
//                       _buildEvidenceChip(Icons.videocam, '${_videoPaths.length}', 'Videos'),
//                       _buildEvidenceChip(Icons.mic, _audioPath != null ? '1' : '0', 'Audio'),
//                     ],
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                     Navigator.of(context).pop();
//                   },
//                   child: const Text("OK"),
//                 ),
//               ],
//             ),
//           );
//         }
//       } catch (e) {
//         if (mounted) {
//           Navigator.pop(context); // Close loading dialog
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('❌ Error submitting report: $e'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//     }
//   }

//   Widget _buildEvidenceChip(IconData icon, String count, String label) {
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: Colors.blue.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(icon, color: Colors.blue, size: 20),
//         ),
//         const SizedBox(height: 4),
//         Text(count, style: const TextStyle(fontWeight: FontWeight.bold)),
//         Text(label, style: const TextStyle(fontSize: 12)),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("File Incident Report"),
//         backgroundColor: Theme.of(context).colorScheme.surface,
//         elevation: 0,
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Theme.of(context).colorScheme.surface,
//               Theme.of(context).colorScheme.background,
//             ],
//           ),
//         ),
//         child: Form(
//           key: _formKey,
//           child: ListView(
//             padding: const EdgeInsets.all(16.0),
//             children: [
//               // Incident Details Section
//               Card(
//                 elevation: 2,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                 child: Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Icon(Icons.info_outline, color: Colors.blue),
//                           const SizedBox(width: 8),
//                           Text(
//                             "Incident Details",
//                             style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.blue,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 20),
                      
//                       TextFormField(
//                         controller: _typeController,
//                         decoration: InputDecoration(
//                           labelText: "Incident Type",
//                           hintText: "e.g., Traffic Accident, Theft, Assault",
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           prefixIcon: const Icon(Icons.report_outlined),
//                         ),
//                         validator: (value) =>
//                             value!.isEmpty ? "Please enter incident type" : null,
//                       ),
                      
//                       const SizedBox(height: 16),
                      
//                       TextFormField(
//                         controller: _descriptionController,
//                         decoration: InputDecoration(
//                           labelText: "Detailed Description",
//                           hintText: "Describe what happened in detail...",
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           prefixIcon: const Icon(Icons.description_outlined),
//                         ),
//                         maxLines: 4,
//                         validator: (value) =>
//                             value!.isEmpty ? "Please enter a description" : null,
//                       ),
                      
//                       const SizedBox(height: 16),
                      
//                       DropdownButtonFormField<String>(
//                         decoration: InputDecoration(
//                           labelText: "Severity Level",
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           prefixIcon: const Icon(Icons.priority_high_outlined),
//                         ),
//                         value: _severity,
//                         items: [
//                           DropdownMenuItem(value: 'Minor', child: Row(
//                             children: [
//                               Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
//                               const SizedBox(width: 8),
//                               const Text('Minor'),
//                             ],
//                           )),
//                           DropdownMenuItem(value: 'Moderate', child: Row(
//                             children: [
//                               Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
//                               const SizedBox(width: 8),
//                               const Text('Moderate'),
//                             ],
//                           )),
//                           DropdownMenuItem(value: 'Severe', child: Row(
//                             children: [
//                               Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
//                               const SizedBox(width: 8),
//                               const Text('Severe'),
//                             ],
//                           )),
//                         ],
//                         onChanged: (value) => setState(() => _severity = value ?? 'Moderate'),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 16),

//               // Location Section
//               Card(
//                 elevation: 2,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                 child: ListTile(
//                   contentPadding: const EdgeInsets.all(20),
//                   leading: Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.green.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Icon(Icons.location_on, color: Colors.green),
//                   ),
//                   title: const Text("Location", style: TextStyle(fontWeight: FontWeight.bold)),
//                   subtitle: _isLoadingLocation 
//                     ? Row(
//                         children: [
//                           SizedBox(
//                             width: 16,
//                             height: 16,
//                             child: CircularProgressIndicator(strokeWidth: 2),
//                           ),
//                           const SizedBox(width: 8),
//                           const Text("Fetching location..."),
//                         ],
//                       )
//                     : Text(_location),
//                   trailing: IconButton(
//                     icon: const Icon(Icons.my_location),
//                     onPressed: _getLocation,
//                     tooltip: "Refresh location",
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 16),

//               // Evidence Collection Section
//               Card(
//                 elevation: 2,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                 child: Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Icon(Icons.attach_file, color: Colors.purple),
//                           const SizedBox(width: 8),
//                           Text(
//                             "Evidence Collection",
//                             style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.purple,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         "Add photos, videos, and audio recordings as evidence",
//                         style: TextStyle(color: Colors.grey[600], fontSize: 14),
//                       ),
//                       const SizedBox(height: 20),

//                       // Media capture buttons
//                       Column(
//                         children: [
//                           // Photo and Video buttons row
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: ElevatedButton.icon(
//                                   onPressed: _capturePhoto,
//                                   icon: const Icon(Icons.camera_alt),
//                                   label: const Text("Add Photos"),
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: Colors.blue,
//                                     foregroundColor: Colors.white,
//                                     padding: const EdgeInsets.symmetric(vertical: 12),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: ElevatedButton.icon(
//                                   onPressed: _captureVideo,
//                                   icon: const Icon(Icons.videocam),
//                                   label: const Text("Add Videos"),
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: Colors.orange,
//                                     foregroundColor: Colors.white,
//                                     padding: const EdgeInsets.symmetric(vertical: 12),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
                          
//                           const SizedBox(height: 12),
                          
//                           // Audio recording button
//                           SizedBox(
//                             width: double.infinity,
//                             child: ElevatedButton.icon(
//                               onPressed: _isRecording ? _stopRecording : _startRecording,
//                               icon: Icon(_isRecording ? Icons.stop : Icons.mic),
//                               label: Text(_isRecording ? "Stop Recording" : "Record Audio Evidence"),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: _isRecording ? Colors.red : Colors.green,
//                                 foregroundColor: Colors.white,
//                                 padding: const EdgeInsets.symmetric(vertical: 12),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 20),

//                       // Evidence summary
//                       Container(
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: Colors.grey[50],
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(color: Colors.grey[200]!),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               "Evidence Summary",
//                               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                             ),
//                             const SizedBox(height: 12),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                               children: [
//                                 _buildEvidenceCounter(Icons.photo, _photoPaths.length, "Photos"),
//                                 _buildEvidenceCounter(Icons.videocam, _videoPaths.length, "Videos"),
//                                 _buildEvidenceCounter(Icons.audiotrack, _audioPath != null ? 1 : 0, "Audio"),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),

//                       // Display collected media previews
//                       if (_photoPaths.isNotEmpty) ...[
//                         const SizedBox(height: 16),
//                         Text("Photos (${_photoPaths.length}):", 
//                             style: const TextStyle(fontWeight: FontWeight.w500)),
//                         const SizedBox(height: 8),
//                         SizedBox(
//                           height: 80,
//                           child: ListView.builder(
//                             scrollDirection: Axis.horizontal,
//                             itemCount: _photoPaths.length,
//                             itemBuilder: (context, index) {
//                               return Container(
//                                 margin: const EdgeInsets.only(right: 8),
//                                 child: Stack(
//                                   children: [
//                                     ClipRRect(
//                                       borderRadius: BorderRadius.circular(8),
//                                       child: Container(
//                                         width: 80,
//                                         height: 80,
//                                         decoration: BoxDecoration(
//                                           borderRadius: BorderRadius.circular(8),
//                                           border: Border.all(color: Colors.grey[300]!),
//                                         ),
//                                         child: Image.file(
//                                           File(_photoPaths[index]),
//                                           fit: BoxFit.cover,
//                                         ),
//                                       ),
//                                     ),
//                                     Positioned(
//                                       top: 4,
//                                       right: 4,
//                                       child: GestureDetector(
//                                         onTap: () => _removePhoto(index),
//                                         child: Container(
//                                           decoration: const BoxDecoration(
//                                             color: Colors.red,
//                                             shape: BoxShape.circle,
//                                           ),
//                                           padding: const EdgeInsets.all(4),
//                                           child: const Icon(
//                                             Icons.close,
//                                             color: Colors.white,
//                                             size: 12,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                       ],

//                       if (_videoPaths.isNotEmpty) ...[
//                         const SizedBox(height: 16),
//                         Text("Videos (${_videoPaths.length}):", 
//                             style: const TextStyle(fontWeight: FontWeight.w500)),
//                         const SizedBox(height: 8),
//                         Column(
//                           children: _videoPaths.asMap().entries.map((entry) {
//                             int index = entry.key;
//                             String videoPath = entry.value;
//                             return Container(
//                               margin: const EdgeInsets.only(bottom: 8),
//                               padding: const EdgeInsets.all(12),
//                               decoration: BoxDecoration(
//                                 color: Colors.blue.withOpacity(0.05),
//                                 borderRadius: BorderRadius.circular(8),
//                                 border: Border.all(color: Colors.blue.withOpacity(0.2)),
//                               ),
//                               child: Row(
//                                 children: [
//                                   const Icon(Icons.videocam, color: Colors.blue),
//                                   const SizedBox(width: 12),
//                                   Expanded(
//                                     child: Text(
//                                       path.basename(videoPath),
//                                       style: const TextStyle(fontWeight: FontWeight.w500),
//                                     ),
//                                   ),
//                                   IconButton(
//                                     icon: const Icon(Icons.delete, color: Colors.red),
//                                     onPressed: () => _removeVideo(index),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           }).toList(),
//                         ),
//                       ],

//                       if (_audioPath != null) ...[
//                         const SizedBox(height: 16),
//                         const Text("Audio Recording:", 
//                             style: TextStyle(fontWeight: FontWeight.w500)),
//                         const SizedBox(height: 8),
//                         Container(
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: Colors.green.withOpacity(0.05),
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(color: Colors.green.withOpacity(0.2)),
//                           ),
//                           child: Row(
//                             children: [
//                               const Icon(Icons.audiotrack, color: Colors.green),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Text(
//                                   path.basename(_audioPath!),
//                                   style: const TextStyle(fontWeight: FontWeight.w500),
//                                 ),
//                               ),
//                               IconButton(
//                                 icon: const Icon(Icons.delete, color: Colors.red),
//                                 onPressed: _removeAudio,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 24),

//               // Submit button
//               SizedBox(
//                 width: double.infinity,
//                 height: 56,
//                 child: ElevatedButton(
//                   onPressed: _submitReport,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.red,
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     elevation: 3,
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Icon(Icons.send, size: 20),
//                       const SizedBox(width: 8),
//                       const Text(
//                         "Submit Incident Report",
//                         style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 16),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildEvidenceCounter(IconData icon, int count, String label) {
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: count > 0 ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(
//             icon,
//             color: count > 0 ? Colors.green : Colors.grey,
//             size: 24,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           count.toString(),
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 18,
//             color: count > 0 ? Colors.green : Colors.grey,
//           ),
//         ),
//         Text(
//           label,
//           style: const TextStyle(fontSize: 12),
//         ),
//       ],
//     );
//   }
// }

// // Keep your existing ViewFIRPage and NearbyPoliceMap classes here...
// // [The rest of your ViewFIRPage and NearbyPoliceMap classes remain the same]

// class ViewFIRPage extends StatefulWidget {
//   const ViewFIRPage({super.key});

//   @override
//   State<ViewFIRPage> createState() => _ViewFIRPageState();
// }

// class _ViewFIRPageState extends State<ViewFIRPage> {
//   final _storageService = StorageService();
//   late Future<List<FIR>> _reportsFuture;
//   String _selectedFilter = 'All';
//   String _searchQuery = '';
//   final TextEditingController _searchController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _reportsFuture = _storageService.getAllFIRs();
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   void _refreshReports() {
//     setState(() {
//       _reportsFuture = _getFilteredFIRs();
//     });
//   }

//   Future<List<FIR>> _getFilteredFIRs() async {
//     if (_searchQuery.isNotEmpty) {
//       return await _storageService.searchFIRs(_searchQuery);
//     }
    
//     switch (_selectedFilter) {
//       case 'With Evidence':
//         return await _storageService.getFIRsWithEvidence();
//       case 'Submitted':
//         return await _storageService.getFIRsByStatus('Submitted');
//       case 'Under Investigation':
//         return await _storageService.getFIRsByStatus('Under Investigation');
//       case 'Resolved':
//         return await _storageService.getFIRsByStatus('Resolved');
//       default:
//         return await _storageService.getAllFIRs();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("My Reports (FIR)"),
//         backgroundColor: Theme.of(context).colorScheme.surface,
//         actions: [
//           IconButton(
//             onPressed: _refreshReports,
//             icon: const Icon(Icons.refresh),
//             tooltip: "Refresh",
//           ),
//         ],
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Theme.of(context).colorScheme.surface,
//               Theme.of(context).colorScheme.background,
//             ],
//           ),
//         ),
//         child: Column(
//           children: [
//             // Search and filter section
//             Container(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   // Search bar
//                   TextField(
//                     controller: _searchController,
//                     decoration: InputDecoration(
//                       hintText: "Search reports...",
//                       prefixIcon: const Icon(Icons.search),
//                       suffixIcon: _searchQuery.isNotEmpty
//                           ? IconButton(
//                               onPressed: () {
//                                 _searchController.clear();
//                                 setState(() {
//                                   _searchQuery = '';
//                                   _refreshReports();
//                                 });
//                               },
//                               icon: const Icon(Icons.clear),
//                             )
//                           : null,
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     onChanged: (value) {
//                       setState(() {
//                         _searchQuery = value;
//                       });
//                       // Debounce search
//                       Future.delayed(const Duration(milliseconds: 500), () {
//                         if (_searchQuery == value) {
//                           _refreshReports();
//                         }
//                       });
//                     },
//                   ),
                  
//                   const SizedBox(height: 12),
                  
//                   // Filter chips
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: Row(
//                       children: [
//                         'All',
//                         'With Evidence',
//                         'Submitted',
//                         'Under Investigation',
//                         'Resolved'
//                       ].map((filter) {
//                         final isSelected = _selectedFilter == filter;
//                         return Padding(
//                           padding: const EdgeInsets.only(right: 8),
//                           child: FilterChip(
//                             label: Text(filter),
//                             selected: isSelected,
//                             onSelected: (selected) {
//                               setState(() {
//                                 _selectedFilter = selected ? filter : 'All';
//                                 _refreshReports();
//                               });
//                             },
//                             backgroundColor: isSelected ? Colors.blue.withOpacity(0.2) : null,
//                             selectedColor: Colors.blue.withOpacity(0.3),
//                           ),
//                         );
//                       }).toList(),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
            
//             // Reports list
//             Expanded(
//               child: FutureBuilder<List<FIR>>(
//                 future: _reportsFuture,
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }
                  
//                   if (snapshot.hasError) {
//                     return Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const Icon(Icons.error_outline, size: 64, color: Colors.red),
//                           const SizedBox(height: 16),
//                           Text("Error: ${snapshot.error}"),
//                           const SizedBox(height: 16),
//                           ElevatedButton(
//                             onPressed: _refreshReports,
//                             child: const Text("Retry"),
//                           ),
//                         ],
//                       ),
//                     );
//                   }
                  
//                   if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                     return Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const Icon(Icons.description_outlined, size: 64, color: Colors.grey),
//                           const SizedBox(height: 16),
//                           Text(
//                             _searchQuery.isNotEmpty
//                                 ? "No reports match your search"
//                                 : _selectedFilter == 'All'
//                                     ? "You have not submitted any reports yet."
//                                     : "No reports found for '$_selectedFilter'",
//                             style: const TextStyle(fontSize: 16, color: Colors.grey),
//                             textAlign: TextAlign.center,
//                           ),
//                           if (_searchQuery.isNotEmpty || _selectedFilter != 'All') ...[
//                             const SizedBox(height: 16),
//                             ElevatedButton(
//                               onPressed: () {
//                                 _searchController.clear();
//                                 setState(() {
//                                   _searchQuery = '';
//                                   _selectedFilter = 'All';
//                                   _refreshReports();
//                                 });
//                               },
//                               child: const Text("Show All Reports"),
//                             ),
//                           ],
//                         ],
//                       ),
//                     );
//                   }

//                   final reports = snapshot.data!;
//                   return RefreshIndicator(
//                     onRefresh: () async => _refreshReports(),
//                     child: ListView.builder(
//                       padding: const EdgeInsets.all(16),
//                       itemCount: reports.length,
//                       itemBuilder: (context, index) {
//                         final report = reports[index];
//                         return _buildReportCard(report);
//                       },
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildReportCard(FIR report) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: InkWell(
//         onTap: () => _openReportDetails(report),
//         borderRadius: BorderRadius.circular(16),
//         child: Container(
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(16),
//             gradient: LinearGradient(
//               colors: [Colors.white, Colors.grey.withOpacity(0.02)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header row with title and status
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           report.accidentType,
//                           style: const TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           "Report #${report.id}",
//                           style: TextStyle(
//                             color: Colors.grey[600],
//                             fontSize: 12,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                     decoration: BoxDecoration(
//                       color: _getStatusColor(report.status).withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(16),
//                       border: Border.all(
//                         color: _getStatusColor(report.status).withOpacity(0.3),
//                       ),
//                     ),
//                     child: Text(
//                       report.status,
//                       style: TextStyle(
//                         color: _getStatusColor(report.status),
//                         fontWeight: FontWeight.w600,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 12),

//               // Date and location
//               Row(
//                 children: [
//                   Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
//                   const SizedBox(width: 4),
//                   Text(
//                     report.formattedDate,
//                     style: TextStyle(color: Colors.grey[600], fontSize: 13),
//                   ),
//                   const SizedBox(width: 16),
//                   Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
//                   const SizedBox(width: 4),
//                   Expanded(
//                     child: Text(
//                       report.location,
//                       style: TextStyle(color: Colors.grey[600], fontSize: 13),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 12),

//               // Description preview
//               Text(
//                 report.description,
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//                 style: const TextStyle(height: 1.4),
//               ),

//               const SizedBox(height: 12),

//               // Footer with severity and evidence info
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: _getSeverityColor(report.severity).withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           _getSeverityIcon(report.severity),
//                           size: 14,
//                           color: _getSeverityColor(report.severity),
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           report.severity,
//                           style: TextStyle(
//                             color: _getSeverityColor(report.severity),
//                             fontWeight: FontWeight.w600,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
                  
//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       if (report.hasEvidence) ...[
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                           decoration: BoxDecoration(
//                             color: Colors.blue.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               const Icon(Icons.attach_file, size: 14, color: Colors.blue),
//                               const SizedBox(width: 4),
//                               Text(
//                                 '${report.evidenceCount}',
//                                 style: const TextStyle(
//                                   color: Colors.blue,
//                                   fontWeight: FontWeight.w600,
//                                   fontSize: 12,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                       ],
//                       const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
//                     ],
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _openReportDetails(FIR report) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => FIRDetailPage(
//           fir: report,
//           onUpdated: _refreshReports,
//         ),
//       ),
//     );
//   }

//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'submitted':
//         return Colors.orange;
//       case 'under investigation':
//         return Colors.blue;
//       case 'resolved':
//         return Colors.green;
//       case 'closed':
//         return Colors.grey;
//       default:
//         return Colors.grey;
//     }
//   }

//   Color _getSeverityColor(String severity) {
//     switch (severity.toLowerCase()) {
//       case 'minor':
//         return Colors.green;
//       case 'moderate':
//         return Colors.orange;
//       case 'severe':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }

//   IconData _getSeverityIcon(String severity) {
//     switch (severity.toLowerCase()) {
//       case 'minor':
//         return Icons.info_outline;
//       case 'moderate':
//         return Icons.warning_amber;
//       case 'severe':
//         return Icons.dangerous;
//       default:
//         return Icons.help_outline;
//     }
//   }
// }

// // Keep the existing NearbyPoliceMap class unchanged
// class NearbyPoliceMap extends StatefulWidget {
//   final LatLng userLocation;
//   const NearbyPoliceMap({super.key, required this.userLocation});

//   @override
//   State<NearbyPoliceMap> createState() => _NearbyPoliceMapState();
// }

// class _NearbyPoliceMapState extends State<NearbyPoliceMap> {
//   final MapController _mapController = MapController();
//   List<Marker> _markers = [];
//   List<Map<String, dynamic>> _policeStations = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _fetchNearbyPoliceStations();
//   }

//   Future<void> _fetchNearbyPoliceStations() async {
//     String overpassQuery =
//         '[out:json];node["amenity"="police"](around:5000,${widget.userLocation.latitude},${widget.userLocation.longitude});out;';
//     final response = await http.get(Uri.parse(
//         'https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(overpassQuery)}'));

//     if (mounted) {
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         _markers.clear();
//         _policeStations.clear();

//         _markers.add(Marker(
//           point: widget.userLocation,
//           width: 80,
//           height: 80,
//           child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
//         ));

//         for (var element in data['elements']) {
//           final lat = element['lat'];
//           final lon = element['lon'];
//           final name = element['tags']?['name'] ?? 'Police Station';
//           final distance = const Distance()
//               .as(LengthUnit.Meter, widget.userLocation, LatLng(lat, lon));

//           _policeStations
//               .add({'name': name, 'lat': lat, 'lon': lon, 'distance': distance});

//           _markers.add(
//             Marker(
//               point: LatLng(lat, lon),
//               width: 80,
//               height: 80,
//               child: GestureDetector(
//                 onTap: () => _showLocationInfo(name, distance),
//                 child: Icon(Icons.local_police,
//                     color: Theme.of(context).primaryColor, size: 35),
//               ),
//             ),
//           );
//         }
//         _policeStations.sort((a, b) => a['distance'].compareTo(b['distance']));

//         setState(() => _isLoading = false);
//       } else {
//         setState(() => _isLoading = false);
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//               content: Text("Failed to fetch police station data.")));
//         }
//       }
//     }
//   }

//   void _showLocationInfo(String name, double distance) {
//     showModalBottomSheet(
//       context: context,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => Container(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.local_police, color: Colors.blue, size: 24),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     name,
//                     style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
//                 const SizedBox(width: 8),
//                 Text(
//                   "Distance: ${distance.toStringAsFixed(0)} meters away",
//                   style: TextStyle(color: Colors.grey[600]),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 onPressed: () => Navigator.pop(context),
//                 icon: const Icon(Icons.close),
//                 label: const Text("Close"),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue,
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showAllStationsList() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => DraggableScrollableSheet(
//         expand: false,
//         initialChildSize: 0.4,
//         minChildSize: 0.2,
//         maxChildSize: 0.6,
//         builder: (context, scrollController) => Container(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             children: [
//               Text(
//                 "Nearby Police Stations",
//                 style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Expanded(
//                 child: ListView.builder(
//                   controller: scrollController,
//                   itemCount: _policeStations.length,
//                   itemBuilder: (context, index) {
//                     final station = _policeStations[index];
//                     return Card(
//                       margin: const EdgeInsets.only(bottom: 8),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: ListTile(
//                         leading: Container(
//                           padding: const EdgeInsets.all(8),
//                           decoration: BoxDecoration(
//                             color: Colors.blue.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: const Icon(Icons.local_police, color: Colors.blue),
//                         ),
//                         title: Text(station['name']),
//                         subtitle: Text(
//                           "${station['distance'].toStringAsFixed(0)} meters away",
//                         ),
//                         trailing: const Icon(Icons.directions),
//                         onTap: () {
//                           Navigator.pop(context);
//                           _mapController.move(
//                               LatLng(station['lat'], station['lon']), 17.0);
//                         },
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Nearby Police Stations"),
//         backgroundColor: Theme.of(context).colorScheme.surface,
//         actions: [
//           if (!_isLoading && _policeStations.isNotEmpty)
//             IconButton(
//               icon: const Icon(Icons.list_alt_outlined),
//               onPressed: _showAllStationsList,
//               tooltip: "Show all stations in a list",
//             )
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _policeStations.isEmpty
//               ? Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
//                       const SizedBox(height: 16),
//                       Text(
//                         "No police stations found nearby",
//                         style: TextStyle(fontSize: 16, color: Colors.grey[600]),
//                       ),
//                     ],
//                   ),
//                 )
//               : FlutterMap(
//                   mapController: _mapController,
//                   options: MapOptions(
//                     initialCenter: widget.userLocation,
//                     initialZoom: 14,
//                   ),
//                   children: [
//                     TileLayer(
//                       urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
//                     ),
//                     MarkerLayer(markers: _markers),
//                   ],
//                 ),
//     );
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../models/fir_model.dart';
import 'fir_detail_page.dart';

class PoliceServicesPage extends StatelessWidget {
  const PoliceServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Police Services')),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          _buildServiceCard(
            context,
            icon: Icons.note_add_outlined,
            title: 'File Accident Report',
            subtitle: 'Report a traffic incident with evidence',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AccidentReportPage())),
          ),
          _buildServiceCard(
            context,
            icon: Icons.description_outlined,
            title: 'View My Reports (FIR)',
            subtitle: 'Check the status of your reports',
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ViewFIRPage())),
          ),
          _buildServiceCard(
            context,
            icon: Icons.location_on_outlined,
            title: 'Nearby Police Stations',
            subtitle: 'Find police stations on the map',
            onTap: () async {
              final locationResult = await LocationService.getCurrentLocation();
              locationResult.fold(
                (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(error)));
                  }
                },
                (position) {
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => NearbyPoliceMap(
                              userLocation: LatLng(
                                  position.latitude, position.longitude))),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class AccidentReportPage extends StatefulWidget {
  const AccidentReportPage({super.key});
  @override
  State<AccidentReportPage> createState() => _AccidentReportPageState();
}

class _AccidentReportPageState extends State<AccidentReportPage> {
  final _formKey = GlobalKey<FormState>();
  String _severity = 'Moderate';
  String _location = 'Fetching...';
  final _typeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _storageService = StorageService();

  // Media recording and storage
  FlutterSoundRecorder? _soundRecorder;
  bool _isRecording = false;
  String? _audioPath;
  List<String> _photoPaths = [];
  List<String> _videoPaths = [];

  @override
  void initState() {
    super.initState();
    _getLocation();
    _initializeRecorder();
  }

  @override
  void dispose() {
    _typeController.dispose();
    _descriptionController.dispose();
    _soundRecorder?.closeRecorder();
    super.dispose();
  }

  Future<void> _initializeRecorder() async {
    _soundRecorder = FlutterSoundRecorder();
    await _soundRecorder!.openRecorder();
  }

  Future<void> _getLocation() async {
    final locationResult = await LocationService.getCurrentLocation();
    locationResult.fold(
      (error) => setState(() => _location = 'Could not fetch location'),
      (position) => setState(() =>
          _location = "${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}"),
    );
  }

  Future<void> _capturePhoto() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null) {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        
        for (int i = 0; i < result.files.length; i++) {
          final file = result.files[i];
          if (file.path != null) {
            final newPath = path.join(directory.path, 'evidence_photo_${timestamp}_$i.jpg');
            await File(file.path!).copy(newPath);
            setState(() {
              _photoPaths.add(newPath);
            });
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${result.files.length} photo(s) added')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing photo: $e')));
      }
    }
  }

  Future<void> _captureVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: true,
      );

      if (result != null) {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        
        for (int i = 0; i < result.files.length; i++) {
          final file = result.files[i];
          if (file.path != null) {
            final newPath = path.join(directory.path, 'evidence_video_${timestamp}_$i.mp4');
            await File(file.path!).copy(newPath);
            setState(() {
              _videoPaths.add(newPath);
            });
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${result.files.length} video(s) added')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing video: $e')));
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      final permission = await Permission.microphone.request();
      if (permission != PermissionStatus.granted) {
        throw 'Microphone permission not granted';
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final audioPath = path.join(directory.path, 'evidence_audio_$timestamp.aac');

      await _soundRecorder!.startRecorder(toFile: audioPath);
      setState(() {
        _isRecording = true;
        _audioPath = audioPath;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting recording: $e')));
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _soundRecorder!.stopRecorder();
      setState(() {
        _isRecording = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio recorded successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping recording: $e')));
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photoPaths.removeAt(index);
    });
  }

  void _removeVideo(int index) {
    setState(() {
      _videoPaths.removeAt(index);
    });
  }

  void _removeAudio() {
    setState(() {
      _audioPath = null;
    });
  }

  void _submitReport() async {
    if (_formKey.currentState!.validate()) {
      final fir = FIR(
        accidentType: _typeController.text.trim(),
        description: _descriptionController.text.trim(),
        severity: _severity,
        location: _location,
        dateTime: DateTime.now(),
        status: 'Submitted',
        photoPaths: _photoPaths.isEmpty ? null : _photoPaths,
        videoPaths: _videoPaths.isEmpty ? null : _videoPaths,
        audioPath: _audioPath,
      );
      
      await _storageService.insertFIR(fir);

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Report Submitted"),
            content: Text("Your report has been submitted with ${_photoPaths.length} photo(s), ${_videoPaths.length} video(s), and ${_audioPath != null ? 1 : 0} audio recording."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("File Accident Report")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _typeController,
              decoration: const InputDecoration(
                  labelText: "Accident Type (e.g., Collision)"),
              validator: (value) =>
                  value!.isEmpty ? "Please enter accident type" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 4,
              validator: (value) =>
                  value!.isEmpty ? "Please enter a description" : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Severity"),
              value: _severity,
              items: ['Minor', 'Moderate', 'Severe']
                  .map((level) =>
                      DropdownMenuItem(value: level, child: Text(level)))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _severity = value ?? 'Moderate'),
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade400),
              ),
              title: const Text("Location"),
              subtitle: Text(_location),
              trailing: IconButton(
                icon: const Icon(Icons.my_location),
                onPressed: _getLocation,
              ),
            ),
            const SizedBox(height: 24),

            // Evidence Collection Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Evidence Collection", 
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold
                        )),
                    const SizedBox(height: 16),

                    // Media capture buttons - Fixed layout
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _capturePhoto,
                                icon: const Icon(Icons.camera_alt),
                                label: const Text("Photos"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _captureVideo,
                                icon: const Icon(Icons.videocam),
                                label: const Text("Videos"),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isRecording ? _stopRecording : _startRecording,
                            icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                            label: Text(_isRecording ? "Stop Recording" : "Record Audio"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isRecording ? Colors.red : null,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Display evidence counts
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildEvidenceCount(Icons.photo, _photoPaths.length, "Photos"),
                          _buildEvidenceCount(Icons.videocam, _videoPaths.length, "Videos"),
                          _buildEvidenceCount(Icons.audiotrack, _audioPath != null ? 1 : 0, "Audio"),
                        ],
                      ),
                    ),

                    // Display collected media previews
                    if (_photoPaths.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text("Photos (${_photoPaths.length}):", 
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _photoPaths.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Image.file(
                                        File(_photoPaths[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: GestureDetector(
                                      onTap: () => _removePhoto(index),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(2),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    if (_videoPaths.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text("Videos (${_videoPaths.length}):", 
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Column(
                        children: _videoPaths.asMap().entries.map((entry) {
                          int index = entry.key;
                          String videoPath = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: ListTile(
                              dense: true,
                              leading: const Icon(Icons.videocam, color: Colors.blue, size: 20),
                              title: Text("Video ${index + 1}", style: const TextStyle(fontSize: 14)),
                              subtitle: Text(path.basename(videoPath), style: const TextStyle(fontSize: 12)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () => _removeVideo(index),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    if (_audioPath != null) ...[
                      const SizedBox(height: 16),
                      const Text("Audio Recording:", 
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.audiotrack, color: Colors.green, size: 20),
                        title: const Text("Audio Evidence", style: TextStyle(fontSize: 14)),
                        subtitle: Text(path.basename(_audioPath!), style: const TextStyle(fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: _removeAudio,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitReport,
              child: const Text("Submit Report"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceCount(IconData icon, int count, String label) {
    return Column(
      children: [
        Icon(icon, color: count > 0 ? Colors.green : Colors.grey, size: 20),
        const SizedBox(height: 4),
        Text(count.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class ViewFIRPage extends StatefulWidget {
  const ViewFIRPage({super.key});

  @override
  State<ViewFIRPage> createState() => _ViewFIRPageState();
}

class _ViewFIRPageState extends State<ViewFIRPage> {
  final _storageService = StorageService();
  late Future<List<FIR>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _storageService.getAllFIRs();
  }

  void _refreshReports() {
    setState(() {
      _reportsFuture = _storageService.getAllFIRs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Reports (FIR)")),
      body: FutureBuilder<List<FIR>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("You have not submitted any reports yet."));
          }

          final reports = snapshot.data!;
          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return Card(
                child: ListTile(
                  title: Text(report.accidentType),
                  subtitle: Text("On ${report.formattedDate} at ${report.location}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (report.hasEvidence)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${report.evidenceCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Chip(label: Text(report.status)),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FIRDetailPage(
                          fir: report,
                          onUpdated: _refreshReports,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class NearbyPoliceMap extends StatefulWidget {
  final LatLng userLocation;
  const NearbyPoliceMap({super.key, required this.userLocation});

  @override
  State<NearbyPoliceMap> createState() => _NearbyPoliceMapState();
}

class _NearbyPoliceMapState extends State<NearbyPoliceMap> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  List<Map<String, dynamic>> _policeStations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNearbyPoliceStations();
  }

  Future<void> _fetchNearbyPoliceStations() async {
    String overpassQuery =
        '[out:json];node["amenity"="police"](around:5000,${widget.userLocation.latitude},${widget.userLocation.longitude});out;';
    final response = await http.get(Uri.parse(
        'https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(overpassQuery)}'));

    if (mounted) {
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _markers.clear();
        _policeStations.clear();

        _markers.add(Marker(
          point: widget.userLocation,
          width: 80,
          height: 80,
          child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
        ));

        for (var element in data['elements']) {
          final lat = element['lat'];
          final lon = element['lon'];
          final name = element['tags']?['name'] ?? 'Police Station';
          final distance = const Distance()
              .as(LengthUnit.Meter, widget.userLocation, LatLng(lat, lon));

          _policeStations
              .add({'name': name, 'lat': lat, 'lon': lon, 'distance': distance});

          _markers.add(
            Marker(
              point: LatLng(lat, lon),
              width: 80,
              height: 80,
              child: GestureDetector(
                onTap: () => _showLocationInfo(name, distance),
                child: Icon(Icons.local_police,
                    color: Theme.of(context).primaryColor, size: 35),
              ),
            ),
          );
        }
        _policeStations.sort((a, b) => a['distance'].compareTo(b['distance']));

        setState(() => _isLoading = false);
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Failed to fetch police station data.")));
        }
      }
    }
  }

  void _showLocationInfo(String name, double distance) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Distance: ${distance.toStringAsFixed(0)} meters away"),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text("Close"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllStationsList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.6,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text("Nearby Stations",
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _policeStations.length,
                  itemBuilder: (context, index) {
                    final station = _policeStations[index];
                    return Card(
                      child: ListTile(
                        leading:
                            const Icon(Icons.local_police, color: Colors.blue),
                        title: Text(station['name']),
                        subtitle: Text(
                            "Distance: ${station['distance'].toStringAsFixed(0)} meters"),
                        onTap: () {
                          Navigator.pop(context);
                          _mapController.move(
                              LatLng(station['lat'], station['lon']), 17.0);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Police Stations"),
        actions: [
          if (!_isLoading && _policeStations.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.list_alt_outlined),
              onPressed: _showAllStationsList,
              tooltip: "Show all stations in a list",
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _policeStations.isEmpty
              ? const Center(
                  child: Text("No police stations found nearby.",
                      style: TextStyle(fontSize: 16)))
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: widget.userLocation,
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    ),
                    MarkerLayer(markers: _markers),
                  ],
                ),
    );
  }
}