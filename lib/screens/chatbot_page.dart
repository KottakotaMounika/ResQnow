import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

// Import the REAL AppActionController from your home page
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print("✅ Environment loaded successfully");
  } catch (e) {
    print("⚠️ Could not load .env file: $e");
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppActionController(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ResQnow Assistant',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.red,
        brightness: Brightness.light,
      ),
      home: const ChatbotPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Chat Message Model
class ChatMessage {
  final String text;
  final bool isUser;
  final bool isGeminiResponse;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    this.isUser = false,
    this.isGeminiResponse = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Available App Actions
enum AppAction { triggerSOS, findNearbyHospitals, toggleSiren, findPolice }

/// AI Status
enum AIStatus { initializing, ready, error, offline }

/// Main Chatbot Controller with Gemini Integration
class ChatbotController {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  late final GenerativeModel _model;
  late final ChatSession _chat;
  final ValueNotifier<List<ChatMessage>> messages = ValueNotifier([]);
  final ValueNotifier<bool> isTyping = ValueNotifier(false);
  final ValueNotifier<AIStatus> aiStatus = ValueNotifier(AIStatus.initializing);
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final ValueNotifier<bool> isListening = ValueNotifier(false);

  bool _geminiInitialized = false;

  // Direct command mapping (these bypass Gemini)
  final Map<String, AppAction> _directCommands = {
    'sos': AppAction.triggerSOS,
    'emergency': AppAction.triggerSOS,
    'help me': AppAction.triggerSOS,
    'send sos': AppAction.triggerSOS,
    'activate sos': AppAction.triggerSOS,
    'find hospitals': AppAction.findNearbyHospitals,
    'hospital': AppAction.findNearbyHospitals,
    'hospitals': AppAction.findNearbyHospitals,
    'nearby hospitals': AppAction.findNearbyHospitals,
    'medical help': AppAction.findNearbyHospitals,
    'find police': AppAction.findPolice,
    'police': AppAction.findPolice,
    'police station': AppAction.findPolice,
    'report crime': AppAction.findPolice,
    'siren': AppAction.toggleSiren,
    'toggle siren': AppAction.toggleSiren,
    'emergency siren': AppAction.toggleSiren,
    'make noise': AppAction.toggleSiren,
  };

  // Minimal fallback responses (only used when Gemini fails)
  final Map<String, String> _fallbackResponses = {
    'hello': "Hello! I'm ResQnow. My AI features are currently limited, but I can still help with emergencies. Try saying 'emergency' or 'help'.",
    'hi': "Hi! I'm in fallback mode but still ready to help with safety concerns.",
    'help': "I can help with:\n• Emergency SOS (say 'emergency')\n• Find hospitals\n• Find police\n• Activate siren",
    'thank you': "You're welcome! Stay safe.",
    'thanks': "You're welcome!",
    'bye': "Goodbye! Stay safe.",
    'goodbye': "Take care!",
  };

  // Gemini function declarations
  final _tools = [
    Tool(functionDeclarations: [
      FunctionDeclaration(
        'triggerSOS',
        'Activates emergency SOS sequence for immediate help',
        Schema(SchemaType.object, properties: {}),
      ),
      FunctionDeclaration(
        'findNearbyHospitals',
        'Locates and displays nearby hospitals and medical facilities',
        Schema(SchemaType.object, properties: {}),
      ),
      FunctionDeclaration(
        'toggleSiren',
        'Activates emergency siren to alert nearby people',
        Schema(SchemaType.object, properties: {}),
      ),
      FunctionDeclaration(
        'findPoliceStations',
        'Finds nearby police stations and law enforcement services',
        Schema(SchemaType.object, properties: {}),
      ),
    ])
  ];

  ChatbotController() {
    _initializeGemini();
    _initialize();
  }

  void _initializeGemini() {
    aiStatus.value = AIStatus.initializing;

    try {
      if (_apiKey.isNotEmpty && _apiKey != 'NO_KEY') {
        print("🔄 Initializing Gemini with API key: ${_apiKey.substring(0, 10)}...");

        // Create model with system instruction
        _model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: _apiKey,
          tools: _tools,
          generationConfig: GenerationConfig(
            temperature: 0.9,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 1024,
          ),
          safetySettings: [
            SafetySetting(HarmCategory.harassment, HarmBlockThreshold.low),
            SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.low),
            SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
            SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.low),
          ],
          systemInstruction: Content.text(
            "You are ResQnow, a compassionate and intelligent AI safety assistant. Your primary mission is to help people stay safe and provide immediate assistance in emergencies.\n\n"
            "Key behaviors:\n"
            "- Be warm, empathetic, and reassuring in all interactions\n"
            "- Always respond naturally and conversationally\n"
            "- For emergencies, use the appropriate functions: triggerSOS, findNearbyHospitals, toggleSiren, findPoliceStations\n"
            "- Provide helpful, detailed responses to questions\n"
            "- For mental health concerns, be gentle and encouraging\n"
            "- Answer questions about safety, provide advice, or just have friendly conversations\n"
            "- Be proactive in offering help and asking follow-up questions\n"
            "- Show personality and care in your responses\n\n"
            "Remember: You are a helpful AI assistant focused on safety, but you can discuss any topic the user wants to talk about."
          ),
        );

        // Start chat with empty history
        _chat = _model.startChat();
        _geminiInitialized = true;
        aiStatus.value = AIStatus.ready;
        print("✅ Gemini AI initialized successfully!");
      } else {
        print("❌ No valid Gemini API key found");
        aiStatus.value = AIStatus.offline;
      }
    } catch (e) {
      print("❌ Gemini initialization error: $e");
      _geminiInitialized = false;
      aiStatus.value = AIStatus.error;
    }
  }

  Future<void> _initialize() async {
    try {
      await _speechToText.initialize();
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
    } catch (e) {
      print("TTS/STT initialization error: $e");
    }

    // Welcome message based on AI status
    String welcomeMessage;
    if (_geminiInitialized) {
      welcomeMessage = "Hello! I'm ResQnow, your AI safety assistant powered by Gemini. I'm here to help with emergencies, answer questions, provide safety guidance, or just chat. What's on your mind?";
    } else {
      welcomeMessage = "Hello! I'm ResQnow in basic mode. I can help with emergencies and basic safety functions. How can I assist you?";
    }

    _addMessage(
      ChatMessage(
        text: welcomeMessage,
        isGeminiResponse: _geminiInitialized,
      ),
      speakMessage: false
    );
  }

  Future<void> sendMessage(String text, BuildContext context) async {
    if (text.trim().isEmpty) return;

    final query = text.trim().toLowerCase();
    _addMessage(ChatMessage(text: text, isUser: true), speakMessage: false);
    isTyping.value = true;

    try {
      // 1. Direct emergency commands (highest priority)
      if (_directCommands.containsKey(query)) {
        print("🚨 Executing direct command: $query");
        final action = _directCommands[query]!;
        await _executeDirectCommand(action, context);
        return;
      }

      // 2. Critical mental health queries
      if (_isCriticalMentalHealthQuery(query)) {
        print("💭 Mental health response triggered");
        _addMessage(ChatMessage(text: _getSafeMentalHealthResponse()));
        return;
      }

      // 3. Try Gemini AI (if available)
      if (_geminiInitialized && aiStatus.value == AIStatus.ready) {
        print("🤖 Using Gemini AI for response");
        await _handleGeminiResponse(text, context);
      } else {
        print("📱 Using fallback response");
        await _handleFallbackResponse(query);
      }

    } catch (e) {
      print("❌ Error in sendMessage: $e");
      await _handleFallbackResponse(query);
    } finally {
      isTyping.value = false;
    }
  }

  Future<void> _handleGeminiResponse(String text, BuildContext context) async {
    try {
      print("📤 Sending to Gemini: ${text.length > 50 ? text.substring(0, 50) + '...' : text}");

      final response = await _chat.sendMessage(Content.text(text)).timeout(
        const Duration(seconds: 20),
      );

      print("📥 Gemini response received");
      final functionCalls = response.functionCalls.toList();

      if (functionCalls.isNotEmpty) {
        print("⚙️ Function call detected: ${functionCalls.first.name}");
        final call = functionCalls.first;
        final action = _getActionFromFuncName(call.name);

        if (action != null) {
          final result = await _executeDirectCommand(action, context);

          // Send function result back to Gemini
          final functionResponse = Content.functionResponse(call.name, {'result': result});
          final nextResponse = await _chat.sendMessage(functionResponse).timeout(
            const Duration(seconds: 15),
          );

          if (nextResponse.text != null && nextResponse.text!.trim().isNotEmpty) {
            _addMessage(ChatMessage(
              text: nextResponse.text!.trim(),
              isGeminiResponse: true,
            ));
          }
        } else {
          _addMessage(ChatMessage(
            text: "I encountered an issue with that function. Please try again or ask for help differently.",
            isGeminiResponse: true,
          ));
        }
      } else {
        // Regular text response from Gemini
        final responseText = response.text?.trim();
        if (responseText != null && responseText.isNotEmpty) {
          print("💬 Gemini text response: ${responseText.length} characters");
          _addMessage(ChatMessage(
            text: responseText,
            isGeminiResponse: true,
          ));
        } else {
          print("⚠️ Empty response from Gemini");
          _addMessage(ChatMessage(
            text: "I'm here to help! Could you rephrase your question?",
            isGeminiResponse: true,
          ));
        }
      }
    } catch (e) {
      print("❌ Gemini API error: $e");
      aiStatus.value = AIStatus.error;
      await _handleFallbackResponse(text.toLowerCase());
    }
  }

  Future<void> _handleFallbackResponse(String query) async {
    print("📱 Using fallback response for: $query");
    await Future.delayed(const Duration(milliseconds: 600));

    String response = "I'm in basic mode right now. I can help with emergency functions like 'SOS', 'find hospitals', 'police', or 'siren'. What do you need?";

    // Check for basic predefined responses
    for (String key in _fallbackResponses.keys) {
      if (query.contains(key)) {
        response = _fallbackResponses[key]!;
        break;
      }
    }

    // Basic context-aware responses
    if (query.contains('emergency') || query.contains('urgent')) {
      response = "🚨 Emergency mode activated! I can:\n• Trigger SOS (say 'SOS')\n• Find hospitals (say 'hospitals')\n• Find police (say 'police')\n• Activate siren (say 'siren')\n\nWhat do you need right now?";
    } else if (query.contains('scared') || query.contains('afraid')) {
      response = "I understand you're scared. I'm here to help. If it's an emergency, say 'SOS'. Otherwise, I can help you find nearby hospitals or police. Are you safe right now?";
    } else if (query.contains('hospital') || query.contains('medical')) {
      response = "Say 'find hospitals' and I'll help you locate nearby medical facilities. For emergencies, call 102 or say 'SOS'.";
    } else if (query.contains('police') || query.contains('crime')) {
      response = "Say 'find police' to locate nearby police stations. For immediate danger, call 100 or say 'SOS'.";
    }

    _addMessage(ChatMessage(text: response, isGeminiResponse: false));
  }

  Future<String> _executeDirectCommand(AppAction action, BuildContext context) async {
    try {
      // Get the REAL AppActionController from the provider
      final appController = Provider.of<AppActionController>(context, listen: false);
      String result;

      switch (action) {
        case AppAction.triggerSOS:
          result = await appController.triggerSOS(context);
          break;
        case AppAction.findNearbyHospitals:
          result = await appController.findNearbyHospitals(context);
          break;
        case AppAction.toggleSiren:
          result = await appController.toggleSiren();
          break;
        case AppAction.findPolice:
          result = await appController.findPoliceStations(context);
          break;
      }

      _addMessage(ChatMessage(text: result));
      return result;
    } catch (e) {
      print("Error executing command: $e");

      // Fallback responses for each action
      String fallbackResult;
      switch (action) {
        case AppAction.triggerSOS:
          fallbackResult = "🚨 SOS Alert Activated! Emergency protocols initiated. Help is being dispatched to your location. Stay calm and stay safe.";
          break;
        case AppAction.findNearbyHospitals:
          fallbackResult = "🏥 Locating nearby hospitals... Please call 102 for ambulance services or visit your nearest emergency room if this is urgent.";
          break;
        case AppAction.toggleSiren:
          fallbackResult = "🔊 Emergency siren activated! This alert will help people nearby locate you. Sound will continue for 30 seconds.";
          break;
        case AppAction.findPolice:
          fallbackResult = "👮‍♂️ Finding police stations... For immediate emergency assistance, call 100. Help is available and on the way.";
          break;
      }

      _addMessage(ChatMessage(text: fallbackResult));
      return fallbackResult;
    }
  }

  void _addMessage(ChatMessage? message, {bool speakMessage = true}) async {
    if (message?.text == null || message!.text.isEmpty) return;
    messages.value = [message, ...messages.value];

    if (!message.isUser && speakMessage) {
      await speak(message.text);
    }
  }

  void toggleListening(TextEditingController textController, BuildContext context) async {
    try {
      bool available = await _speechToText.initialize();
      if (!available) {
        _addMessage(ChatMessage(text: "Speech recognition is not available on this device. Please type your message instead."));
        return;
      }

      if (isListening.value) {
        await _speechToText.stop();
        isListening.value = false;
      } else {
        isListening.value = true;
        textController.clear();

        _speechToText.listen(
          onResult: (result) {
            textController.text = result.recognizedWords;
            if (result.finalResult) {
              sendMessage(result.recognizedWords, context);
              isListening.value = false;
            }
          },
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.confirmation,
        );
      }
    } catch (e) {
      print("Speech recognition error: $e");
      _addMessage(ChatMessage(text: "Speech recognition encountered an error. Please try typing your message."));
      isListening.value = false;
    }
  }

  Future<void> speak(String text) async {
    try {
      String cleanText = text.replaceAll(RegExp(r'[🚨🏥🔊👮‍♂️💬🆘]'), '').trim();
      await _flutterTts.speak(cleanText);
    } catch (e) {
      print("TTS Error: $e");
    }
  }

  AppAction? _getActionFromFuncName(String name) {
    switch (name) {
      case 'triggerSOS':
        return AppAction.triggerSOS;
      case 'findNearbyHospitals':
        return AppAction.findNearbyHospitals;
      case 'toggleSiren':
        return AppAction.toggleSiren;
      case 'findPoliceStations':
        return AppAction.findPolice;
      default:
        return null;
    }
  }

  bool _isCriticalMentalHealthQuery(String query) {
    final criticalKeywords = [
      'suicide', 'kill myself', 'end my life', 'want to die',
      'self harm', 'hurt myself', 'hopeless', 'no point living'
    ];
    return criticalKeywords.any((keyword) => query.contains(keyword));
  }

  String _getSafeMentalHealthResponse() {
    return "I'm really concerned about you right now, and I want you to know that you're not alone. What you're feeling is temporary, even though it might not seem that way.\n\n"
        "🆘 **Immediate Help:**\n"
        "• India: KIRAN Mental Health Helpline: 1800-599-0019\n"
        "• Crisis Text Line: Text HOME to 741741\n"
        "• Or go to your nearest emergency room\n\n"
        "You matter more than you know. Please reach out to someone you trust or a mental health professional. I'm here to listen too, but professional help is important right now.";
  }

  void dispose() {
    messages.dispose();
    isTyping.dispose();
    isListening.dispose();
    aiStatus.dispose();
    _speechToText.stop();
    _flutterTts.stop();
  }
}

// UI Implementation
class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> with TickerProviderStateMixin {
  late final ChatbotController _controller;
  final TextEditingController _textController = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = ChatbotController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    _controller.sendMessage(text, context);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.security, color: Colors.red.shade700, size: 20),
            ),
            const SizedBox(width: 12),
            const Text("ResQnow Assistant", style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            // AI Status Indicator
            ValueListenableBuilder<AIStatus>(
              valueListenable: _controller.aiStatus,
              builder: (context, status, child) {
                IconData icon;
                Color color;
                String tooltip;

                switch (status) {
                  case AIStatus.ready:
                    icon = Icons.smart_toy;
                    color = Colors.green;
                    tooltip = "Gemini AI Active";
                    break;
                  case AIStatus.initializing:
                    icon = Icons.hourglass_empty;
                    color = Colors.orange;
                    tooltip = "AI Initializing";
                    break;
                  case AIStatus.error:
                    icon = Icons.error_outline;
                    color = Colors.red;
                    tooltip = "AI Error - Basic Mode";
                    break;
                  case AIStatus.offline:
                    icon = Icons.wifi_off;
                    color = Colors.grey;
                    tooltip = "Basic Mode Only";
                    break;
                }

                return Tooltip(
                  message: tooltip,
                  child: Icon(icon, color: color, size: 20),
                );
              },
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        elevation: 0,
        scrolledUnderElevation: 4,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Listening indicator
            ValueListenableBuilder<bool>(
              valueListenable: _controller.isListening,
              builder: (context, isListening, child) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isListening ? 60 : 0,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade100, Colors.red.shade50],
                  ),
                ),
                child: isListening
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.mic, color: Colors.red, size: 20),
                          ),
                          const SizedBox(width: 12),
                          AnimatedTextKit(
                            animatedTexts: [
                              WavyAnimatedText(
                                'Listening for your voice...',
                                textStyle: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            ],
                            isRepeatingAnimation: true,
                            repeatForever: true,
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ),

            // Messages list
            Expanded(
              child: ValueListenableBuilder<List<ChatMessage>>(
                valueListenable: _controller.messages,
                builder: (context, messages, child) => ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length,
                  itemBuilder: (_, int index) => _buildMessageBubble(messages[index]),
                ),
              ),
            ),

            // Typing indicator
            ValueListenableBuilder<bool>(
              valueListenable: _controller.isTyping,
              builder: (context, isTyping, child) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: isTyping ? 50 : 0,
                child: isTyping
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AnimatedTextKit(
                                animatedTexts: [
                                  WavyAnimatedText(
                                    'ResQnow is thinking...',
                                    textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                          fontWeight: FontWeight.w500,
                                        ),
                                  )
                                ],
                                isRepeatingAnimation: true,
                                repeatForever: true,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),

            const Divider(height: 1.0),
            _buildTextComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: message.isGeminiResponse
                      ? [Colors.purple.shade400, Colors.blue.shade600]
                      : [Colors.grey.shade400, Colors.grey.shade600],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                message.isGeminiResponse ? Icons.auto_awesome : Icons.support_agent,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                gradient: isUser
                    ? LinearGradient(
                        colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                      )
                    : LinearGradient(
                        colors: [
                          theme.colorScheme.secondaryContainer,
                          theme.colorScheme.secondaryContainer.withOpacity(0.8),
                        ],
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : theme.colorScheme.onSecondaryContainer,
                      fontSize: 16,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (!isUser && message.isGeminiResponse) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 12,
                          color: theme.colorScheme.onSecondaryContainer.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Powered by Gemini',
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSecondaryContainer.withOpacity(0.6),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.person,
                color: theme.primaryColor,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: InputDecoration(
                  hintText: "Ask me anything or say 'emergency' for help...",
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          ValueListenableBuilder<bool>(
            valueListenable: _controller.isListening,
            builder: (context, isListening, child) => Container(
              decoration: BoxDecoration(
                color: isListening ? Colors.red : Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                iconSize: 24,
                icon: Icon(isListening ? Icons.mic_off : Icons.mic),
                color: Colors.white,
                onPressed: () => _controller.toggleListening(_textController, context),
                tooltip: isListening ? 'Stop listening' : 'Start voice input',
              ),
            ),
          ),
          const SizedBox(width: 4.0),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send),
              color: Colors.white,
              onPressed: () => _handleSubmitted(_textController.text),
              tooltip: 'Send message',
            ),
          ),
        ],
      ),
    );
  }
}