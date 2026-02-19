import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart' as path;
import '../models/fir_model.dart';
import '../services/storage_service.dart';

class FIRDetailPage extends StatefulWidget {
  final FIR fir;
  final Function()? onUpdated;

  const FIRDetailPage({
    super.key,
    required this.fir,
    this.onUpdated,
  });

  @override
  State<FIRDetailPage> createState() => _FIRDetailPageState();
}

class _FIRDetailPageState extends State<FIRDetailPage>
    with TickerProviderStateMixin {
  final StorageService _storageService = StorageService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late TabController _tabController;
  
  bool _isAudioPlaying = false;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeAudioPlayer();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _initializeAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          _isAudioPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((Duration duration) {
      if (mounted) {
        setState(() {
          _audioDuration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((Duration position) {
      if (mounted) {
        setState(() {
          _audioPosition = position;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("FIR Report #${widget.fir.id}"),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        actions: [
          IconButton(
            onPressed: _shareCompleteReport,
            icon: const Icon(Icons.share),
            tooltip: "Share Complete Report",
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'edit_status':
                  _showStatusUpdateDialog();
                  break;
                case 'delete':
                  _showDeleteConfirmDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit_status',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined),
                    SizedBox(width: 8),
                    Text('Update Status'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Report', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Status and key info card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.fir.accidentType,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Chip(
                        label: Text(widget.fir.status),
                        backgroundColor: _getStatusColor(widget.fir.status),
                        labelStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        widget.fir.formattedDate,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.fir.location,
                          style: TextStyle(color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(widget.fir.severity),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.fir.severity,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (widget.fir.hasEvidence)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.attach_file, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.fir.evidenceCount} evidence',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: [
              const Tab(icon: Icon(Icons.description), text: "Details"),
              Tab(
                icon: const Icon(Icons.photo_library),
                text: "Photos (${widget.fir.photoPaths?.length ?? 0})",
              ),
              Tab(
                icon: const Icon(Icons.video_library),
                text: "Videos (${widget.fir.videoPaths?.length ?? 0})",
              ),
              Tab(
                icon: const Icon(Icons.audiotrack),
                text: widget.fir.audioPath != null ? "Audio" : "No Audio",
              ),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildPhotosTab(),
                _buildVideosTab(),
                _buildAudioTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Description",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.fir.description,
                    style: const TextStyle(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Report Summary",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow("Report ID", "#${widget.fir.id}"),
                  _buildInfoRow("Type", widget.fir.accidentType),
                  _buildInfoRow("Severity", widget.fir.severity),
                  _buildInfoRow("Status", widget.fir.status),
                  _buildInfoRow("Date & Time", widget.fir.formattedDate),
                  _buildInfoRow("Location", widget.fir.location),
                  _buildInfoRow("Evidence", widget.fir.evidenceSummary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          const Text(": "),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosTab() {
    final photos = widget.fir.photoPaths ?? [];
    
    if (photos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No photos attached",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Photo viewer
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(
                onTap: () => _showFullScreenPhoto(photos[_currentPhotoIndex]),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      child: File(photos[_currentPhotoIndex]).existsSync()
                          ? Image.file(
                              File(photos[_currentPhotoIndex]),
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.image_not_supported, size: 64),
                              ),
                            ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${_currentPhotoIndex + 1}/${photos.length}",
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton.small(
                        onPressed: () => _shareMedia(photos[_currentPhotoIndex]),
                        backgroundColor: Colors.blue,
                        child: const Icon(Icons.share, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Photo navigation
        if (photos.length > 1) ...[
          Container(
            height: 60,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: _currentPhotoIndex > 0
                      ? () => setState(() => _currentPhotoIndex--)
                      : null,
                  icon: const Icon(Icons.arrow_back_ios),
                ),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => setState(() => _currentPhotoIndex = index),
                        child: Container(
                          width: 60,
                          height: 60,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: index == _currentPhotoIndex
                                  ? Colors.blue
                                  : Colors.grey,
                              width: index == _currentPhotoIndex ? 2 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: File(photos[index]).existsSync()
                                ? Image.file(
                                    File(photos[index]),
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.image_not_supported),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                IconButton(
                  onPressed: _currentPhotoIndex < photos.length - 1
                      ? () => setState(() => _currentPhotoIndex++)
                      : null,
                  icon: const Icon(Icons.arrow_forward_ios),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Photo info and actions
        Container(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    path.basename(photos[_currentPhotoIndex]),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showFullScreenPhoto(photos[_currentPhotoIndex]),
                        icon: const Icon(Icons.fullscreen),
                        label: const Text("View Full"),
                      ),
                      TextButton.icon(
                        onPressed: () => _shareMedia(photos[_currentPhotoIndex]),
                        icon: const Icon(Icons.share),
                        label: const Text("Share"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideosTab() {
    final videos = widget.fir.videoPaths ?? [];
    
    if (videos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No videos attached",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final videoPath = videos[index];
        final videoFile = File(videoPath);
        final fileName = path.basename(videoPath);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.play_circle_fill, color: Colors.blue, size: 32),
            ),
            title: Text(fileName, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(videoFile.existsSync() ? "Ready to play" : "File not found"),
                const SizedBox(height: 4),
                if (videoFile.existsSync())
                  FutureBuilder<int>(
                    future: videoFile.length(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text("${_formatFileSize(snapshot.data!)}");
                      }
                      return const SizedBox.shrink();
                    },
                  ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'play':
                    _playVideo(videoPath);
                    break;
                  case 'share':
                    _shareMedia(videoPath);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'play',
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow),
                      SizedBox(width: 8),
                      Text('Play Video'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share),
                      SizedBox(width: 8),
                      Text('Share'),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () => _playVideo(videoPath),
          ),
        );
      },
    );
  }

  Widget _buildAudioTab() {
    if (widget.fir.audioPath == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.audiotrack_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No audio recording attached",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final audioFile = File(widget.fir.audioPath!);
    final fileName = path.basename(widget.fir.audioPath!);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.audiotrack, size: 64, color: Colors.green),
                  const SizedBox(height: 16),
                  Text(
                    fileName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    audioFile.existsSync() ? "Audio Evidence Available" : "File not found",
                    style: TextStyle(
                      color: audioFile.existsSync() ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Audio controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => _seekAudio(_audioPosition - const Duration(seconds: 10)),
                        icon: const Icon(Icons.replay_10),
                      ),
                      const SizedBox(width: 16),
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.green,
                        child: IconButton(
                          onPressed: audioFile.existsSync() ? _toggleAudioPlayback : null,
                          icon: Icon(
                            _isAudioPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () => _seekAudio(_audioPosition + const Duration(seconds: 10)),
                        icon: const Icon(Icons.forward_10),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Progress bar
                  Column(
                    children: [
                      Slider(
                        value: _audioDuration.inMilliseconds > 0
                            ? _audioPosition.inMilliseconds / _audioDuration.inMilliseconds
                            : 0,
                        onChanged: (value) {
                          _seekAudio(Duration(milliseconds: (value * _audioDuration.inMilliseconds).round()));
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(_audioPosition)),
                            Text(_formatDuration(_audioDuration)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: audioFile.existsSync() ? () => _shareMedia(widget.fir.audioPath!) : null,
                        icon: const Icon(Icons.share),
                        label: const Text("Share Audio"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Audio player methods
  void _toggleAudioPlayback() async {
    try {
      if (_isAudioPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(DeviceFileSource(widget.fir.audioPath!));
      }
    } catch (e) {
      _showErrorSnackBar("Error playing audio: $e");
    }
  }

  void _seekAudio(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      _showErrorSnackBar("Error seeking audio: $e");
    }
  }

  // Media sharing methods
  void _shareCompleteReport() async {
    try {
      List<XFile> filesToShare = [];
      
      // Add photos
      if (widget.fir.photoPaths != null) {
        for (String photoPath in widget.fir.photoPaths!) {
          if (File(photoPath).existsSync()) {
            filesToShare.add(XFile(photoPath));
          }
        }
      }
      
      // Add videos
      if (widget.fir.videoPaths != null) {
        for (String videoPath in widget.fir.videoPaths!) {
          if (File(videoPath).existsSync()) {
            filesToShare.add(XFile(videoPath));
          }
        }
      }
      
      // Add audio
      if (widget.fir.audioPath != null && File(widget.fir.audioPath!).existsSync()) {
        filesToShare.add(XFile(widget.fir.audioPath!));
      }
      
      String reportText = '''
🚨 INCIDENT REPORT #${widget.fir.id}

📝 Type: ${widget.fir.accidentType}
📅 Date: ${widget.fir.formattedDate}
📍 Location: ${widget.fir.location}
⚠️ Severity: ${widget.fir.severity}
📊 Status: ${widget.fir.status}

📖 Description:
${widget.fir.description}

📎 Evidence: ${filesToShare.length} file(s) attached
      ''';
      
      if (filesToShare.isNotEmpty) {
        await Share.shareXFiles(filesToShare, text: reportText);
      } else {
        await Share.share(reportText);
      }
    } catch (e) {
      _showErrorSnackBar("Error sharing report: $e");
    }
  }

  void _shareMedia(String filePath) async {
    try {
      if (File(filePath).existsSync()) {
        await Share.shareXFiles([XFile(filePath)]);
      } else {
        _showErrorSnackBar("File not found");
      }
    } catch (e) {
      _showErrorSnackBar("Error sharing file: $e");
    }
  }

  // Photo viewer methods
  void _showFullScreenPhoto(String photoPath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenPhotoViewer(
          photoPath: photoPath,
          onShare: () => _shareMedia(photoPath),
        ),
      ),
    );
  }

  // Video player method
  void _playVideo(String videoPath) {
    if (File(videoPath).existsSync()) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VideoPlayerPage(
            videoPath: videoPath,
            onShare: () => _shareMedia(videoPath),
          ),
        ),
      );
    } else {
      _showErrorSnackBar("Video file not found");
    }
  }

  // Status update dialog
  void _showStatusUpdateDialog() {
    String selectedStatus = widget.fir.status;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Status"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text("Submitted"),
              value: "Submitted",
              groupValue: selectedStatus,
              onChanged: (value) => selectedStatus = value!,
            ),
            RadioListTile<String>(
              title: const Text("Under Investigation"),
              value: "Under Investigation",
              groupValue: selectedStatus,
              onChanged: (value) => selectedStatus = value!,
            ),
            RadioListTile<String>(
              title: const Text("Resolved"),
              value: "Resolved",
              groupValue: selectedStatus,
              onChanged: (value) => selectedStatus = value!,
            ),
            RadioListTile<String>(
              title: const Text("Closed"),
              value: "Closed",
              groupValue: selectedStatus,
              onChanged: (value) => selectedStatus = value!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _storageService.updateFIRStatus(widget.fir.id!, selectedStatus);
                Navigator.pop(context);
                if (widget.onUpdated != null) widget.onUpdated!();
                _showSuccessSnackBar("Status updated successfully");
              } catch (e) {
                _showErrorSnackBar("Error updating status: $e");
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  // Delete confirmation dialog
  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Report"),
        content: const Text("Are you sure you want to delete this report? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _storageService.deleteFIR(widget.fir.id!);
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to list
                if (widget.onUpdated != null) widget.onUpdated!();
                _showSuccessSnackBar("Report deleted successfully");
              } catch (e) {
                Navigator.pop(context);
                _showErrorSnackBar("Error deleting report: $e");
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Utility methods
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Colors.orange;
      case 'under investigation':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'minor':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'severe':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (bytes.bitLength - 1) ~/ 10;
    return "${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${suffixes[i]}";
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// Full screen photo viewer
class FullScreenPhotoViewer extends StatelessWidget {
  final String photoPath;
  final VoidCallback onShare;

  const FullScreenPhotoViewer({
    super.key,
    required this.photoPath,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: onShare,
            icon: const Icon(Icons.share, color: Colors.white),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: File(photoPath).existsSync()
              ? Image.file(File(photoPath))
              : const Icon(Icons.image_not_supported, size: 64, color: Colors.white),
        ),
      ),
    );
  }
}

// Basic video player page (you might want to use video_player package for better functionality)
class VideoPlayerPage extends StatelessWidget {
  final String videoPath;
  final VoidCallback onShare;

  const VideoPlayerPage({
    super.key,
    required this.videoPath,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Video Player"),
        actions: [
          IconButton(
            onPressed: onShare,
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_file, size: 100, color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              path.basename(videoPath),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              "Video player functionality requires\nvideo_player package integration",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.share),
              label: const Text("Share Video"),
            ),
          ],
        ),
      ),
    );
  }
}