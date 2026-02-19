// lib/screens/voice_memos_page.dart - CORRECTED
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/memo_model.dart';
import '../services/storage_service.dart';

class VoiceMemosPage extends StatefulWidget {
  const VoiceMemosPage({super.key});

  @override
  State<VoiceMemosPage> createState() => _VoiceMemosPageState();
}

class _VoiceMemosPageState extends State<VoiceMemosPage> {
  final StorageService _storageService = StorageService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Memo> _memos = [];
  bool _isLoading = true;
  Memo? _currentlyPlaying;

  @override
  void initState() {
    super.initState();
    _loadMemos();
    // Listen for when the player finishes playing to update the UI
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed && mounted) {
        setState(() => _currentlyPlaying = null);
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadMemos() async {
    setState(() => _isLoading = true);
    final memosFromDb = await _storageService.getAllMemos();
    if (mounted) {
      setState(() {
        _memos = memosFromDb;
        _isLoading = false;
      });
    }
  }

  Future<void> _playMemo(Memo memo) async {
    // If the tapped memo is already playing, stop it.
    if (_currentlyPlaying?.id == memo.id) {
      await _audioPlayer.stop();
      setState(() => _currentlyPlaying = null);
    } else {
      // Otherwise, stop any current playback and play the new memo.
      await _audioPlayer.stop();
      try {
        await _audioPlayer.play(DeviceFileSource(memo.filePath));
        if (mounted) {
          setState(() => _currentlyPlaying = memo);
        }
      } catch (e) {
        print("Error playing memo: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not play file. It may no longer exist.")),
        );
      }
    }
  }

  Future<void> _deleteMemo(Memo memo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Memo"),
        content: const Text("Are you sure you want to permanently delete this memo?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );

    if (confirmed == true) {
      // Stop playback if the deleted memo is the one playing
      if (_currentlyPlaying?.id == memo.id) {
        await _audioPlayer.stop();
        setState(() => _currentlyPlaying = null);
      }
      // Delete from database
      await _storageService.deleteMemo(memo.id!);
      // Try to delete the actual audio file from the device
      try {
        await File(memo.filePath).delete();
      } catch (e) {
        print("Could not delete file, it may already be gone: $e");
      }
      _loadMemos(); // Refresh the list from the database
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Voice Memos"),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMemos)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _memos.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mic_off_outlined, size: 60, color: Colors.grey),
                      SizedBox(height: 16),
                      Text("No voice memos have been recorded yet."),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _memos.length,
                  itemBuilder: (context, index) {
                    final memo = _memos[index];
                    final isPlaying = _currentlyPlaying?.id == memo.id;
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                          color: Theme.of(context).primaryColor,
                          size: 40,
                        ),
                        title: Text(memo.description ?? 'Memo from ${memo.formattedDate}'),
                        subtitle: Text('Duration: ${memo.durationString}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _deleteMemo(memo),
                        ),
                        onTap: () => _playMemo(memo),
                      ),
                    );
                  },
                ),
    );
  }
}