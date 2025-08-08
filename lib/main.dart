import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:file_picker/file_picker.dart';

// ChaosManager handles all the chaos behaviors
class ChaosManager {
  late Timer _timer;
  final Random _random = Random();
  final TextEditingController textController;
  final VoidCallback updateState;

  ChaosManager({required this.textController, required this.updateState});

  void startChaos() {
    _scheduleNextChaos();
  }

  void stopChaos() {
    _timer.cancel();
  }

  void _scheduleNextChaos() {
    // Random interval between 7-15 seconds
    final int seconds = 7 + _random.nextInt(9); // 7 to 15 seconds
    _timer = Timer(Duration(seconds: seconds), () {
      _executeChaosAction();
      _scheduleNextChaos(); // Schedule the next chaos event
    });
  }

  void _executeChaosAction() {
    // Adjusted probabilities - letter operations favored over word deletion
    final chaosActions = <double, VoidCallback>{
      0.35: () => randomLetterDeletion(), // 35% - High: Remove single letters
      0.25: () => letterSwapping(), // 25% - High: Swap letters within words
      0.15: () => cursorTeleportation(), // 15% - Medium: Move cursor randomly
      0.10: () =>
          punctuationInjection(), // 10% - Medium: Add random punctuation
      0.08: () => randomSpaceAddition(), // 8% - Low: Add random spaces
      0.05: () => wordDeletion(), // 5% - Lower: Remove entire words
      0.02: () => wordSwapping(), // 2% - Lowest: Swap words between lines
    };

    // Generate random number and select action based on cumulative probability
    final randomValue = _random.nextDouble();
    double cumulativeProbability = 0.0;

    for (final entry in chaosActions.entries) {
      cumulativeProbability += entry.key;
      if (randomValue <= cumulativeProbability) {
        entry.value();
        updateState();
        return;
      }
    }
  }

  // Random Indentation on Save - will be called from save method
  void randomIndentationOnSave() {
    final text = textController.text;
    if (text.isEmpty) return;

    final lines = text.split('\n');
    final linesToModify = _random.nextInt(3) + 1; // Modify 1-3 lines

    for (int i = 0; i < linesToModify; i++) {
      final lineIndex = _random.nextInt(lines.length);
      final indentType = _random.nextBool() ? '\t' : '  '; // Tab or 2 spaces
      final indentCount = _random.nextInt(3) + 1; // 1-3 indentations
      lines[lineIndex] = (indentType * indentCount) + lines[lineIndex];
    }

    textController.text = lines.join('\n');
  }

  void cursorTeleportation() {
    final text = textController.text;
    if (text.isEmpty) return;

    final newPosition = _random.nextInt(text.length);
    textController.selection = TextSelection.collapsed(offset: newPosition);
  }

  void randomDeletion() {
    final text = textController.text;
    if (text.isEmpty) return;

    if (_random.nextBool()) {
      // Delete a random letter
      final position = _random.nextInt(text.length);
      final newText =
          text.substring(0, position) + text.substring(position + 1);
      textController.text = newText;
    } else {
      // Delete a random word
      final words = text.split(RegExp(r'\s+'));
      if (words.isNotEmpty) {
        final wordIndex = _random.nextInt(words.length);
        words.removeAt(wordIndex);
        textController.text = words.join(' ');
      }
    }
  }

  void letterOrWordSwapping() {
    final text = textController.text;
    if (text.length < 2) return;

    if (_random.nextBool() && text.length > 1) {
      // Swap letters within a word
      final lines = text.split('\n');
      final words = <String>[];
      final lineIndices = <int>[];

      for (int i = 0; i < lines.length; i++) {
        final lineWords = lines[i].split(RegExp(r'\s+'));
        for (final word in lineWords) {
          if (word.length > 1) {
            words.add(word);
            lineIndices.add(i);
          }
        }
      }

      if (words.isNotEmpty) {
        final wordIndex = _random.nextInt(words.length);
        final word = words[wordIndex];
        final chars = word.split('');

        if (chars.length > 1) {
          final pos1 = _random.nextInt(chars.length);
          int pos2 = _random.nextInt(chars.length);
          while (pos2 == pos1) {
            pos2 = _random.nextInt(chars.length);
          }

          final temp = chars[pos1];
          chars[pos1] = chars[pos2];
          chars[pos2] = temp;

          final newWord = chars.join('');
          textController.text = text.replaceFirst(word, newWord);
        }
      }
    } else {
      // Swap entire words between lines
      final lines = text.split('\n');
      if (lines.length < 2) return;

      final line1Index = _random.nextInt(lines.length);
      int line2Index = _random.nextInt(lines.length);
      while (line2Index == line1Index) {
        line2Index = _random.nextInt(lines.length);
      }

      final words1 = lines[line1Index].split(RegExp(r'\s+'));
      final words2 = lines[line2Index].split(RegExp(r'\s+'));

      if (words1.isNotEmpty && words2.isNotEmpty) {
        final word1Index = _random.nextInt(words1.length);
        final word2Index = _random.nextInt(words2.length);

        final temp = words1[word1Index];
        words1[word1Index] = words2[word2Index];
        words2[word2Index] = temp;

        lines[line1Index] = words1.join(' ');
        lines[line2Index] = words2.join(' ');

        textController.text = lines.join('\n');
      }
    }
  }

  void punctuationInjection() {
    final text = textController.text;
    if (text.isEmpty) return;

    final punctuations = ['.', ',', '!', '?', ';', ':'];
    final punctuation = punctuations[_random.nextInt(punctuations.length)];
    final position = _random.nextInt(text.length + 1);

    final newText =
        text.substring(0, position) + punctuation + text.substring(position);
    textController.text = newText;
  }

  // Specialized chaos methods with specific probabilities
  void randomLetterDeletion() {
    final text = textController.text;
    if (text.isEmpty) return;

    final position = _random.nextInt(text.length);
    final newText = text.substring(0, position) + text.substring(position + 1);
    textController.text = newText;
  }

  void letterSwapping() {
    final text = textController.text;
    if (text.length < 2) return;

    // Find words with more than 1 character
    final lines = text.split('\n');
    final words = <String>[];
    final positions = <int>[];
    int currentPos = 0;

    for (final line in lines) {
      final lineWords = line.split(RegExp(r'\s+'));
      for (final word in lineWords) {
        if (word.length > 1) {
          words.add(word);
          positions.add(currentPos + line.indexOf(word));
        }
      }
      currentPos += line.length + 1; // +1 for newline
    }

    if (words.isNotEmpty) {
      final wordIndex = _random.nextInt(words.length);
      final word = words[wordIndex];
      final chars = word.split('');

      if (chars.length > 1) {
        final pos1 = _random.nextInt(chars.length);
        int pos2 = _random.nextInt(chars.length);
        while (pos2 == pos1) {
          pos2 = _random.nextInt(chars.length);
        }

        final temp = chars[pos1];
        chars[pos1] = chars[pos2];
        chars[pos2] = temp;

        final newWord = chars.join('');
        textController.text = text.replaceFirst(word, newWord);
      }
    }
  }

  void wordDeletion() {
    final text = textController.text;
    if (text.isEmpty) return;

    final words = text.split(RegExp(r'\s+'));
    if (words.isNotEmpty) {
      final wordIndex = _random.nextInt(words.length);
      words.removeAt(wordIndex);
      textController.text = words.join(' ');
    }
  }

  void wordSwapping() {
    final text = textController.text;
    final lines = text.split('\n');
    if (lines.length < 2) return;

    final line1Index = _random.nextInt(lines.length);
    int line2Index = _random.nextInt(lines.length);
    while (line2Index == line1Index) {
      line2Index = _random.nextInt(lines.length);
    }

    final words1 = lines[line1Index].split(RegExp(r'\s+'));
    final words2 = lines[line2Index].split(RegExp(r'\s+'));

    if (words1.isNotEmpty && words2.isNotEmpty) {
      final word1Index = _random.nextInt(words1.length);
      final word2Index = _random.nextInt(words2.length);

      final temp = words1[word1Index];
      words1[word1Index] = words2[word2Index];
      words2[word2Index] = temp;

      lines[line1Index] = words1.join(' ');
      lines[line2Index] = words2.join(' ');

      textController.text = lines.join('\n');
    }
  }

  void randomSpaceAddition() {
    final text = textController.text;
    if (text.isEmpty) return;

    final position = _random.nextInt(text.length + 1);
    final spacesToAdd = _random.nextInt(3) + 1; // Add 1-3 spaces
    final spaces = ' ' * spacesToAdd;

    final newText =
        text.substring(0, position) + spaces + text.substring(position);
    textController.text = newText;
  }

  // New gentler chaos methods for better user experience
  void gentleLetterSwapping() {
    final text = textController.text;
    if (text.length < 2) return;

    // Only swap adjacent letters within words (much more recoverable)
    final lines = text.split('\n');
    final words = <String>[];
    final positions = <int>[];
    int currentPos = 0;

    for (final line in lines) {
      final lineWords = line.split(RegExp(r'\s+'));
      for (final word in lineWords) {
        if (word.length > 2) {
          // Only swap in words with 3+ characters
          words.add(word);
          positions.add(currentPos + line.indexOf(word));
        }
      }
      currentPos += line.length + 1; // +1 for newline
    }

    if (words.isNotEmpty) {
      final wordIndex = _random.nextInt(words.length);
      final word = words[wordIndex];
      final chars = word.split('');

      if (chars.length > 2) {
        // Only swap adjacent characters, not random ones
        final pos1 =
            1 + _random.nextInt(chars.length - 2); // Avoid first and last char
        final pos2 = pos1 + 1;

        final temp = chars[pos1];
        chars[pos1] = chars[pos2];
        chars[pos2] = temp;

        final newWord = chars.join('');
        textController.text = text.replaceFirst(word, newWord);
      }
    }
  }

  void cursorNudge() {
    final text = textController.text;
    if (text.isEmpty) return;

    final currentPosition = textController.selection.baseOffset;
    // Small nudge of 1-5 characters, not full teleportation
    final nudgeDistance =
        (_random.nextInt(5) + 1) * (_random.nextBool() ? 1 : -1);
    final newPosition = (currentPosition + nudgeDistance).clamp(0, text.length);

    textController.selection = TextSelection.collapsed(offset: newPosition);
  }

  void gentlePunctuationInjection() {
    final text = textController.text;
    if (text.isEmpty) return;

    // Only add gentle punctuation, no aggressive ones
    final punctuations = ['.', ',', ';']; // Removed !, ?, :
    final punctuation = punctuations[_random.nextInt(punctuations.length)];

    // Try to insert at word boundaries or near spaces for more natural placement
    final spacePositions = <int>[];
    for (int i = 0; i < text.length; i++) {
      if (text[i] == ' ') {
        spacePositions.add(i);
      }
    }

    final position = spacePositions.isNotEmpty
        ? spacePositions[_random.nextInt(spacePositions.length)]
        : _random.nextInt(text.length + 1);

    final newText =
        text.substring(0, position) + punctuation + text.substring(position);
    textController.text = newText;
  }

  void randomCapitalization() {
    final text = textController.text;
    if (text.isEmpty) return;

    // Find letters to capitalize/decapitalize
    final letters = <int>[];
    for (int i = 0; i < text.length; i++) {
      if (RegExp(r'[a-zA-Z]').hasMatch(text[i])) {
        letters.add(i);
      }
    }

    if (letters.isNotEmpty) {
      final position = letters[_random.nextInt(letters.length)];
      final char = text[position];
      final newChar = char == char.toUpperCase()
          ? char.toLowerCase()
          : char.toUpperCase();

      final newText =
          text.substring(0, position) + newChar + text.substring(position + 1);
      textController.text = newText;
    }
  }

  void doubleSpaceInsertion() {
    final text = textController.text;
    if (text.isEmpty) return;

    // Find existing spaces and make them double spaces
    final spacePositions = <int>[];
    for (int i = 0; i < text.length; i++) {
      if (text[i] == ' ' && (i == 0 || text[i - 1] != ' ')) {
        spacePositions.add(i);
      }
    }

    if (spacePositions.isNotEmpty) {
      final position = spacePositions[_random.nextInt(spacePositions.length)];
      final newText =
          '${text.substring(0, position + 1)} ${text.substring(position + 1)}';
      textController.text = newText;
    } else {
      // If no spaces, just add one somewhere reasonable
      final position = _random.nextInt(text.length + 1);
      final newText =
          '${text.substring(0, position)}  ${text.substring(position)}';
      textController.text = newText;
    }
  }

  void gentleLetterDeletion() {
    final text = textController.text;
    if (text.length < 10) return; // Only delete if there's plenty of text

    // Avoid deleting from small words or important positions
    final safePositions = <int>[];
    for (int i = 1; i < text.length - 1; i++) {
      if (text[i] != ' ' && text[i - 1] != ' ' && text[i + 1] != ' ') {
        safePositions.add(i);
      }
    }

    if (safePositions.isNotEmpty) {
      final position = safePositions[_random.nextInt(safePositions.length)];
      final newText =
          text.substring(0, position) + text.substring(position + 1);
      textController.text = newText;
    }
  }

  void autocorrectMischief() {
    final text = textController.text;
    if (text.isEmpty) return;

    // Simple "autocorrect" style replacements that are obvious and easily fixed
    final autocorrects = {
      'the ': 'teh ',
      'and ': 'adn ',
      'you ': 'yuo ',
      'that ': 'taht ',
      'with ': 'wiht ',
      'have ': 'ahve ',
      'this ': 'thsi ',
      'will ': 'wlil ',
      'your ': 'yuor ',
      'from ': 'form ',
    };

    for (final entry in autocorrects.entries) {
      if (text.contains(entry.key) && _random.nextDouble() < 0.3) {
        textController.text = text.replaceFirst(entry.key, entry.value);
        break;
      }
    }
  }
}

// TypingSpeedMonitor handles speed-based chaos escalation
class TypingSpeedMonitor {
  final Function(int) showSpeedWarning; // Pass violation count
  final VoidCallback forceShutdown;
  final VoidCallback immediateShutdown; // New immediate shutdown callback
  final VoidCallback triggerSpeedChaos;
  final VoidCallback showSubscriptionPrompt; // New subscription prompt
  final bool Function() isDialogVisible; // Check if any dialog is visible

  // Typing speed tracking
  final List<DateTime> _keystrokes = [];
  final Random _random = Random();
  Timer? _speedCheckTimer;
  int _speedViolationCount = 0;
  DateTime? _lastWarningTime; // Track when last warning was shown
  bool _currentViolationAcknowledged =
      true; // Track if current violation level has been acknowledged

  // Speed thresholds (words per minute - assuming 5 chars per word)
  static const int _warningThreshold = 300; // 65 WPM (65 * 5 chars)

  TypingSpeedMonitor({
    required this.showSpeedWarning,
    required this.forceShutdown,
    required this.immediateShutdown,
    required this.triggerSpeedChaos,
    required this.showSubscriptionPrompt,
    required this.isDialogVisible,
  });

  void startMonitoring() {
    _speedCheckTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkTypingSpeed();
    });
  }

  void stopMonitoring() {
    _speedCheckTimer?.cancel();
    _keystrokes.clear();
    _speedViolationCount = 0;
    _lastWarningTime = null; // Reset warning timer
    _currentViolationAcknowledged = true; // Reset acknowledgment flag
  }

  void acknowledgeCurrentViolation() {
    _currentViolationAcknowledged = true;
  }

  void recordKeystroke() {
    final now = DateTime.now();
    _keystrokes.add(now);

    // Keep only keystrokes from the last 10 seconds
    _keystrokes.removeWhere((time) => now.difference(time).inSeconds > 10);
  }

  void _checkTypingSpeed() {
    if (_keystrokes.isEmpty) return;

    final now = DateTime.now();
    final recentKeystrokes = _keystrokes
        .where((time) => now.difference(time).inSeconds <= 6)
        .length;

    // Calculate characters per minute
    final cpm = (recentKeystrokes * 10); // Rough approximation

    // Only act if speed is above threshold and no dialog is currently visible
    if (cpm >= _warningThreshold) {
      // Check if enough time has passed since last warning (minimum 15 seconds gap - longer pause)
      final canShowWarning =
          _lastWarningTime == null ||
          now.difference(_lastWarningTime!).inSeconds >= 15;

      // Only increment violation count when we can show a warning and current violation hasn't been acknowledged
      if (!isDialogVisible() &&
          canShowWarning &&
          _currentViolationAcknowledged) {
        _speedViolationCount++;
        _lastWarningTime = now;
        _currentViolationAcknowledged =
            false; // Mark current violation as not acknowledged

        if (_speedViolationCount == 1) {
          // First violation - show sarcastic warning
          showSpeedWarning(_speedViolationCount);
          triggerSpeedChaos();
        } else if (_speedViolationCount == 2) {
          // Second violation - show subscription prompt or another sarcastic warning
          if (_random.nextBool()) {
            showSubscriptionPrompt(); // 50% chance for subscription
          } else {
            showSpeedWarning(_speedViolationCount); // 50% chance for warning
          }
          triggerSpeedChaos();
        } else if (_speedViolationCount >= 3) {
          // Third violation - shutdown
          forceShutdown();
          return;
        }
      }
    } else {
      // Reduce violation count if typing slows down (below warning threshold)
      if (_speedViolationCount > 0) {
        _speedViolationCount = (_speedViolationCount - 1).clamp(0, 10);
        _currentViolationAcknowledged =
            true; // Reset acknowledgment when slowing down
      }
    }
  }
}

// Intent classes for keyboard shortcuts
class SelectAllIntent extends Intent {
  const SelectAllIntent();
}

class SaveIntent extends Intent {
  const SaveIntent();
}

class NewFileIntent extends Intent {
  const NewFileIntent();
}

class OpenFileIntent extends Intent {
  const OpenFileIntent();
}

class SaveAsIntent extends Intent {
  const SaveAsIntent();
}

class FindIntent extends Intent {
  const FindIntent();
}

class ReplaceIntent extends Intent {
  const ReplaceIntent();
}

class FindNextIntent extends Intent {
  const FindNextIntent();
}

class FindPreviousIntent extends Intent {
  const FindPreviousIntent();
}

class GoToIntent extends Intent {
  const GoToIntent();
}

class InsertDateTimeIntent extends Intent {
  const InsertDateTimeIntent();
}

// TabData class to manage individual tab state
class TabData {
  final TextEditingController controller;
  final FocusNode focusNode;
  String fileName;
  String? filePath;
  bool isModified;
  int lineNumber;
  int columnNumber;
  int wordCount;
  int charCount;

  TabData({
    required this.controller,
    required this.focusNode,
    this.fileName = 'Untitled.txt',
    this.filePath,
    this.isModified = false,
    this.lineNumber = 1,
    this.columnNumber = 30,
    this.wordCount = 0,
    this.charCount = 0,
  });

  void dispose() {
    controller.dispose();
    focusNode.dispose();
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
      title: 'Notepad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Colors.black87,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.grey.shade50,
        fontFamily: 'Segoe UI',
      ),
      home: const ModernNotepadPage(),
    );
  }
}

class ModernNotepadPage extends StatefulWidget {
  const ModernNotepadPage({super.key});

  @override
  State<ModernNotepadPage> createState() => _ModernNotepadPageState();
}

class _ModernNotepadPageState extends State<ModernNotepadPage> {
  // Tab management
  final List<TabData> _tabs = [];
  int _currentTabIndex = 0;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();

  // Find/Replace functionality
  int _currentSearchIndex = -1;
  final List<int> _searchResults = [];

  // Text formatting state
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;

  // Chaos mode state
  final bool _isChaosEnabled = false;
  ChaosManager? _chaosManager;
  TypingSpeedMonitor? _typingSpeedMonitor;

  // Speed violation tracking
  int _speedViolationCount = 0;
  bool _isSpeedWarningVisible = false;
  bool _isSubscriptionPromptVisible = false;

  // Computed properties for current tab
  TabData get _currentTab => _tabs[_currentTabIndex];
  TextEditingController get _controller => _currentTab.controller;
  FocusNode get _focusNode => _currentTab.focusNode;
  String get _currentFileName => _currentTab.fileName;
  set _currentFileName(String value) => _currentTab.fileName = value;
  String? get _currentFilePath => _currentTab.filePath;
  set _currentFilePath(String? value) => _currentTab.filePath = value;
  bool get _isModified => _currentTab.isModified;
  set _isModified(bool value) => _currentTab.isModified = value;
  int get _lineNumber => _currentTab.lineNumber;
  set _lineNumber(int value) => _currentTab.lineNumber = value;
  int get _columnNumber => _currentTab.columnNumber;
  set _columnNumber(int value) => _currentTab.columnNumber = value;
  int get _wordCount => _currentTab.wordCount;
  set _wordCount(int value) => _currentTab.wordCount = value;
  int get _charCount => _currentTab.charCount;
  set _charCount(int value) => _currentTab.charCount = value;

  @override
  void initState() {
    super.initState();

    // Create the first tab
    _createNewTab();

    _controller.addListener(_updateStats);

    // Initialize ChaosManager with the current controller
    _initializeChaosManager();
    _initializeTypingSpeedMonitor();

    // Set initial cursor position to column 30
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.text = '';
      _controller.selection = const TextSelection.collapsed(offset: 0);
      _focusNode.requestFocus();
    });
  }

  void _initializeChaosManager() {
    // Stop existing chaos manager if it exists
    _chaosManager?.stopChaos();

    // Initialize ChaosManager with current tab's controller
    _chaosManager = ChaosManager(
      textController: _controller,
      updateState: () => setState(() {}),
    );

    // Start chaos immediately (always active)
    _chaosManager?.startChaos();
  }

  void _initializeTypingSpeedMonitor() {
    // Stop existing monitor if it exists
    _typingSpeedMonitor?.stopMonitoring();

    // Initialize TypingSpeedMonitor
    _typingSpeedMonitor = TypingSpeedMonitor(
      showSpeedWarning: _showSpeedWarning,
      forceShutdown: _forceShutdown,
      immediateShutdown: _immediateShutdown,
      triggerSpeedChaos: _triggerSpeedChaos,
      showSubscriptionPrompt: _showSubscriptionPrompt,
      isDialogVisible: () =>
          _isSpeedWarningVisible || _isSubscriptionPromptVisible,
    );

    // Start monitoring
    _typingSpeedMonitor?.startMonitoring();
  }

  void _showSpeedWarning(int violationCount) {
    // Don't show new dialog if one is already visible
    if (_isSpeedWarningVisible) return;

    _speedViolationCount = violationCount;

    // Escalating messages with increasing mockery and intensity
    final List<List<String>> escalatingMessages = [
      // Level 1: Gentle and playful warnings (violation 1-2)
      [
        "� SPEEDY GONZALES DETECTED! �\nWhoa there, speed racer! Your fingers are on fire! Maybe take a tiny break?",
        "⚡ FAST FINGERS ALERT! ⚡\nImpressive typing speed! But remember, this isn't a race... or is it? 😏",
        "🏃‍♂️ ZOOM ZOOM! 🏃‍♂️\nYour keyboard is getting a workout! Give those keys a breather!",
      ],
      // Level 2: More insistent but still friendly (violation 3-4)
      [
        "� OK, NOW I'M IMPRESSED! 😅\nSeriously though, violation #$violationCount! Maybe slow down just a smidge?",
        "🎯 TARGETING SPEED DEMON! 🎯\nYou're really going for it! But I'm starting to get a bit dizzy watching...",
        "🎪 LADIES AND GENTLEMEN! 🎪\nWitness the incredible typing human! Violation #$violationCount and counting!",
        "🤖 PROCESSING... PROCESSING... 🤖\nMy circuits are struggling to keep up with you! Slow down, please!",
      ],
      // Level 3: Peak mockery and final warnings (violation 4+)
      [
        "😱 HOUSTON, WE HAVE A PROBLEM! 😱\nViolation #$violationCount! You're approaching typing light speed!",
        "� DEFCON 1: FINGER EMERGENCY! �\nThis is your final courtesy warning! One more and I'm taking a nap!",
        "� THE DRAMA! THE SUSPENSE! �\nViolation #$violationCount! Will they slow down? Will I survive? Find out next!",
        "💀 FINAL WARNING, SPEED FREAK! �\nViolation #$violationCount! Next time I'm pulling the plug!",
        "🚫 I CAN'T EVEN... 🚫\nYou've violated $violationCount times! Do you WANT me to crash?!",
      ],
    ];

    // Select message tier based on violation count
    int tier = 0;
    if (violationCount >= 2) {
      tier = 2; // Final warnings on 2nd violation
    } else if (violationCount >= 1) {
      tier = 0; // Initial warning on 1st violation
    }

    final messages = escalatingMessages[tier];

    // Many sarcastic messages based on violation count
    List<String> sarcasticMessages = [];
    final random = Random(); // Use local random instance

    if (violationCount == 1) {
      // Violation 1 - Sarcastic first warnings
      sarcasticMessages = [
        "Oh wow, SPEED RACER!\nSlow down there, Lightning McQueen! Your keyboard isn't built for NASCAR!",
        "TURBO FINGERS DETECTED!\nWhat's the rush? Are you late for a very important date with your text editor?",
        "BREAKING NEWS!\nLocal human thinks they're a typing machine! More at 11!",
        "ZOOM ZOOM!\nEasy there, Speed Demon! This isn't the Olympics of typing!",
        "TARGET ACQUIRED!\nWe've got a hot shot typist over here! Everyone look out!",
        "BEEP BEEP!\nError 404: Chill not found. Please slow down and try again!",
        "FIRE IN THE HOLE!\nYour fingers are literally smoking! Maybe give them a breather?",
        "LADIES AND GENTLEMEN!\nStep right up and witness the incredible FAST FINGER phenomenon!",
        "CAUTION: WET PAINT!\nOh wait, that's just your keyboard melting from the heat!",
        "HOUSTON, WE HAVE LIFTOFF!\nYour typing speed has reached escape velocity!",
      ];
    } else if (violationCount == 2) {
      // Violation 2 - More aggressive sarcasm
      sarcasticMessages = [
        "SERIOUSLY?! AGAIN?!\nI LITERALLY just told you to slow down! Are you even listening?!",
        "CONGRATULATIONS!\nYou've won the award for 'Most Likely to Ignore Warnings'!",
        "DEATH WISH MUCH?\nViolation #2! Do you WANT me to have a nervous breakdown?!",
        "THE AUDACITY!\nThe sheer NERVE of this human! Violation #2 and still going strong!",
        "THIS IS FINE!\nEverything is TOTALLY fine! Just my sanity slowly leaving my body!",
        "SHOCKING!\nAbsolutely SHOCKING that you didn't learn from violation #1!",
        "BULLSEYE!\nYou hit the target of maximum annoyance! Violation #2 achieved!",
        "RED ALERT!\nAll hands on deck! We have a repeat offender! This is not a drill!",
        "DOES NOT COMPUTE!\nError: Human refuses to follow simple instructions. System overloading!",
        "KABOOM!\nThere goes my last nerve! Violation #2 and my patience is GONE!",
      ];
    }

    final selectedMessage = sarcasticMessages.isNotEmpty
        ? sarcasticMessages[random.nextInt(sarcasticMessages.length)]
        : messages[random.nextInt(messages.length)];

    _isSpeedWarningVisible = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
        contentPadding: const EdgeInsets.all(20),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        title: Row(
          children: [
            Icon(
              violationCount >= 4
                  ? Icons.error
                  : (violationCount >= 2 ? Icons.warning_amber : Icons.warning),
              color: Colors.black87,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              violationCount >= 4
                  ? 'FINAL WARNING'
                  : (violationCount >= 2 ? 'SERIOUS WARNING' : 'SPEED WARNING'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Segoe UI',
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'VIOLATION #$violationCount',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'Segoe UI',
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Text(
            selectedMessage,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Segoe UI',
              color: Colors.black87,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(fontSize: 13, fontFamily: 'Segoe UI'),
              elevation: 1,
            ),
            onPressed: () {
              Navigator.pop(context);
              _isSpeedWarningVisible = false;
              _typingSpeedMonitor?.acknowledgeCurrentViolation();
            },
            child: Text(
              violationCount >= 2
                  ? 'I\'LL BEHAVE, I PROMISE!'
                  : 'OK, I\'LL TRY TO SLOW DOWN',
            ),
          ),
        ],
      ),
    );

    // Auto-shutdown after 2 violations with extreme speed
    if (violationCount >= 2) {
      Timer(const Duration(seconds: 3), () {
        if (_isSpeedWarningVisible) {
          Navigator.pop(context);
          _isSpeedWarningVisible = false;
          _typingSpeedMonitor?.acknowledgeCurrentViolation();
          _forceShutdown();
        }
      });
    }
  }

  void _forceShutdown() {
    // Show final dramatic shutdown dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
        contentPadding: const EdgeInsets.all(20),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        title: Row(
          children: [
            Icon(Icons.power_off, color: Colors.black87, size: 20),
            const SizedBox(width: 8),
            Text(
              'SYSTEM OVERLOAD',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Segoe UI',
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Text(
            "🎉 MISSION ACCOMPLISHED! 🎉\n\n� MAXIMUM SPEED ACHIEVED! �\n\nWow! You've pushed this humble text editor to its absolute limits! Your typing speed is truly legendary!\n\nYou've triggered $_speedViolationCount speed warnings - that's impressive dedication!\n\nTime for a well-deserved break! ☕\n\n✨ See you next time, Speed Champion! ✨\n\nClosing in 3... 2... 1... 🌟",
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Segoe UI',
              color: Colors.black87,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(fontSize: 13, fontFamily: 'Segoe UI'),
              elevation: 1,
            ),
            onPressed: () {
              Navigator.pop(context);
              // Force close app immediately using dart:io exit
              Timer(const Duration(milliseconds: 500), () {
                // For Windows desktop apps, use exit() to forcefully terminate
                exit(0);
              });
            },
            child: const Text('ACCEPT DEFEAT'),
          ),
        ],
      ),
    );

    // Also set a backup timer to force close even if user doesn't click button
    Timer(const Duration(seconds: 5), () {
      exit(0); // Backup force close after 5 seconds
    });
  }

  void _immediateShutdown() {
    // For the most extreme cases - immediate shutdown without dialog
    exit(0);
  }

  void _triggerSpeedChaos() {
    // Trigger additional chaos beyond normal chaos manager
    // Call chaos manager's methods directly
    if (_chaosManager != null) {
      final extraChaosActions = [
        () => _chaosManager!.cursorTeleportation(),
        () => _chaosManager!.cursorTeleportation(), // Extra cursor chaos
        () => _chaosManager!.punctuationInjection(),
        () => _chaosManager!.randomLetterDeletion(),
      ];

      final action =
          extraChaosActions[Random().nextInt(extraChaosActions.length)];
      action();
      setState(() {});
    }
  }

  void _showSubscriptionPrompt() {
    // Simplified to avoid character encoding issues
    _showSnackBar(
      'Premium Speed Detected! Keep typing fast - this is just for fun!',
    );

    _isSubscriptionPromptVisible = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
        contentPadding: const EdgeInsets.all(20),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        title: Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 20),
            const SizedBox(width: 8),
            Text(
              'PREMIUM SPEED DETECTED',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Segoe UI',
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Text(
            "🚀 IMPRESSIVE TYPING SPEED! 🚀\n\n⚡ You're typing at 90+ WPM! ⚡\n\nThat's genuinely impressive! You're a speed typing champion!\n\n💎 UNLOCK TURBO MODE 💎\n\nWant to go even faster? Our imaginary premium version offers:\n\n✨ Only \\9.99/month ✨\n\nFeatures include:\n• Unlimited typing speed\n• 80% less chaos events\n• Premium autocorrect comedy\n• Rainbow cursors\n• Typing sound effects\n\n(This is totally a joke, by the way! �)",
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Segoe UI',
              color: Colors.black87,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(fontSize: 13, fontFamily: 'Segoe UI'),
            ),
            onPressed: () {
              Navigator.pop(context);
              _isSubscriptionPromptVisible = false;
            },
            child: Text(
              'No thanks, I like the chaos!',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(fontSize: 13, fontFamily: 'Segoe UI'),
              elevation: 1,
            ),
            onPressed: () {
              Navigator.pop(context);
              _isSubscriptionPromptVisible = false;
              _showSnackBar(
                'Payment successful! Just kidding - this is a joke! 😄',
              );
            },
            child: const Text('TOTALLY SUBSCRIBE!'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _chaosManager?.stopChaos();
    _typingSpeedMonitor?.stopMonitoring();
    _controller.removeListener(_updateStats);

    // Dispose all tabs
    for (final tab in _tabs) {
      tab.dispose();
    }

    _searchController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  // Tab management methods
  void _createNewTab() {
    final controller = TextEditingController();
    final focusNode = FocusNode();

    controller.addListener(_updateStats);

    final newTab = TabData(controller: controller, focusNode: focusNode);

    setState(() {
      _tabs.add(newTab);
      _currentTabIndex = _tabs.length - 1;
    });

    // Initialize chaos manager for the new active tab
    _initializeChaosManager();

    // Focus the new tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
  }

  void _switchToTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      setState(() {
        _currentTabIndex = index;
      });

      // Reinitialize chaos manager for the new active tab
      _initializeChaosManager();
      _initializeTypingSpeedMonitor();

      // Focus the selected tab
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  void _closeTab(int index) {
    if (_tabs.length <= 1) {
      // Don't close the last tab, just create a new empty one
      _createNewFile();
      return;
    }

    final tabToClose = _tabs[index];

    if (tabToClose.isModified) {
      _showUnsavedChangesDialog(() => _performCloseTab(index));
    } else {
      _performCloseTab(index);
    }
  }

  void _performCloseTab(int index) {
    final tabToClose = _tabs[index];
    tabToClose.dispose();

    setState(() {
      _tabs.removeAt(index);
      if (_currentTabIndex >= _tabs.length) {
        _currentTabIndex = _tabs.length - 1;
      } else if (_currentTabIndex > index) {
        _currentTabIndex--;
      }
    });

    // Reinitialize chaos manager for the new current tab
    _initializeChaosManager();

    // Focus the current tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _updateStats() {
    final text = _controller.text;
    final selection = _controller.selection;

    setState(() {
      _charCount = text.length;

      // Calculate word count
      _wordCount = text.trim().isEmpty
          ? 0
          : text.trim().split(RegExp(r'\s+')).length;

      if (selection.isValid) {
        final beforeCursor = text.substring(0, selection.baseOffset);
        _lineNumber = '\n'.allMatches(beforeCursor).length + 1;
        _columnNumber = beforeCursor.split('\n').last.length + 1;
      } else {
        _columnNumber = 30;
      }
    });
  }

  // File handling methods
  void _newFile() {
    // Create a new tab instead of clearing current one
    _createNewTab();
  }

  void _createNewFile() {
    setState(() {
      _controller.text = '';
      _currentFileName = 'Untitled.txt';
      _currentFilePath = null;
      _isModified = false;
    });
  }

  Future<void> _openFile() async {
    if (_isModified) {
      _showUnsavedChangesDialog(() => _performOpenFile());
    } else {
      await _performOpenFile();
    }
  }

  Future<void> _performOpenFile() async {
    try {
      // Use native Windows file dialog
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Open File',
        type: FileType.custom,
        allowedExtensions: ['txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);

        if (await file.exists()) {
          final content = await file.readAsString();
          setState(() {
            _controller.text = content;
            _currentFileName = result.files.single.name;
            _currentFilePath = filePath;
            _isModified = false;
          });
          _showSnackBar('File opened successfully');
        } else {
          _showSnackBar('File not found');
        }
      }
    } catch (e) {
      _showSnackBar('Error opening file: $e');
    }
  }

  void _clearFormatting() {
    _showSnackBar('Formatting cleared');
  }

  void _exitApplication() {
    if (_isModified) {
      _showUnsavedChangesDialog(() => _performExit());
    } else {
      _performExit();
    }
  }

  void _performExit() {
    _showSnackBar('Exit requested - close window manually');
  }

  void _goToLine() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
        contentPadding: const EdgeInsets.all(16),
        titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Icon(Icons.linear_scale, color: Colors.black87, size: 16),
            const SizedBox(width: 6),
            Text(
              'Go to Line',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Segoe UI',
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 280,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Enter line number',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.black87, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            style: const TextStyle(fontSize: 13, fontFamily: 'Segoe UI'),
            keyboardType: TextInputType.number,
            autofocus: true,
            onSubmitted: (value) {
              final lineNum = int.tryParse(value);
              if (lineNum != null && lineNum > 0) {
                _jumpToLine(lineNum);
              }
              Navigator.pop(context);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Segoe UI',
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _jumpToLine(int lineNumber) {
    final text = _controller.text;
    final lines = text.split('\n');

    if (lineNumber <= lines.length) {
      int position = 0;
      for (int i = 0; i < lineNumber - 1; i++) {
        position += lines[i].length + 1; // +1 for newline character
      }
      _controller.selection = TextSelection.collapsed(offset: position);
    }
  }

  void _insertDateTime() {
    final now = DateTime.now();
    final dateTime =
        '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    final selection = _controller.selection;
    final text = _controller.text;
    final newText = text.replaceRange(selection.start, selection.end, dateTime);

    setState(() {
      _controller.text = newText;
      _controller.selection = TextSelection.collapsed(
        offset: selection.start + dateTime.length,
      );
      _isModified = true;
    });
  }

  // Find and Replace functionality
  void _showFindDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
        contentPadding: const EdgeInsets.all(16),
        titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Icon(Icons.search, color: Colors.black87, size: 16),
            const SizedBox(width: 6),
            Text(
              'Find',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Segoe UI',
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Enter text to find...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.black87, width: 1),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey.shade600,
                size: 18,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            style: const TextStyle(fontSize: 13, fontFamily: 'Segoe UI'),
            autofocus: true,
            onSubmitted: (_) => _performSearch(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Segoe UI',
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton.icon(
            icon: Icon(
              Icons.search_outlined,
              size: 14,
              color: Colors.grey.shade700,
            ),
            label: const Text('Find All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              side: BorderSide(color: Colors.grey.shade300, width: 0.5),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              textStyle: const TextStyle(fontSize: 13, fontFamily: 'Segoe UI'),
              elevation: 1,
            ),
            onPressed: () {
              _performSearch();
              Navigator.pop(context);
            },
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.arrow_forward, size: 14, color: Colors.white),
            label: const Text('Find Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              textStyle: const TextStyle(fontSize: 13, fontFamily: 'Segoe UI'),
              elevation: 1,
            ),
            onPressed: () {
              _performSearch();
              _findNext();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showReplaceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
        contentPadding: const EdgeInsets.all(16),
        titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Icon(Icons.find_replace, color: Colors.black87, size: 16),
            const SizedBox(width: 6),
            Text(
              'Find and Replace',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Segoe UI',
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Find',
                  labelStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.black87, width: 1),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade600,
                    size: 18,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                style: const TextStyle(fontSize: 13, fontFamily: 'Segoe UI'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _replaceController,
                decoration: InputDecoration(
                  labelText: 'Replace with',
                  labelStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.black87, width: 1),
                  ),
                  prefixIcon: Icon(
                    Icons.edit,
                    color: Colors.grey.shade600,
                    size: 18,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                style: const TextStyle(fontSize: 13, fontFamily: 'Segoe UI'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Segoe UI',
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton.icon(
            icon: Icon(
              Icons.search_outlined,
              size: 14,
              color: Colors.grey.shade700,
            ),
            label: const Text('Find All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              side: BorderSide(color: Colors.grey.shade300, width: 0.5),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              textStyle: const TextStyle(fontSize: 13, fontFamily: 'Segoe UI'),
              elevation: 1,
            ),
            onPressed: () {
              _performSearch();
              Navigator.pop(context);
            },
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.swap_horiz, size: 14, color: Colors.white),
            label: const Text('Replace'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              textStyle: const TextStyle(fontSize: 13, fontFamily: 'Segoe UI'),
              elevation: 1,
            ),
            onPressed: () {
              _replaceSelected();
              Navigator.pop(context);
            },
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.swap_vert, size: 14, color: Colors.white),
            label: const Text('Replace All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              textStyle: const TextStyle(fontSize: 13, fontFamily: 'Segoe UI'),
              elevation: 1,
            ),
            onPressed: () {
              _replaceAll();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _performSearch() {
    final text = _controller.text;
    final searchTerm = _searchController.text;

    if (searchTerm.isEmpty) {
      setState(() {
        _searchResults.clear();
        _currentSearchIndex = -1;
      });
      return;
    }

    setState(() {
      _searchResults.clear();
      _currentSearchIndex = -1;

      // Find all occurrences
      int index = 0;
      while (index < text.length) {
        final foundIndex = text.indexOf(searchTerm, index);
        if (foundIndex == -1) break;
        _searchResults.add(foundIndex);
        index = foundIndex + 1;
      }

      if (_searchResults.isNotEmpty) {
        _currentSearchIndex = 0;
        _highlightSearchResult();
      }
    });
  }

  void _findNext() {
    if (_searchResults.isEmpty) {
      _performSearch();
      return;
    }

    setState(() {
      _currentSearchIndex = (_currentSearchIndex + 1) % _searchResults.length;
      _highlightSearchResult();
    });
  }

  void _findPrevious() {
    if (_searchResults.isEmpty) {
      _performSearch();
      return;
    }

    setState(() {
      _currentSearchIndex =
          (_currentSearchIndex - 1 + _searchResults.length) %
          _searchResults.length;
      _highlightSearchResult();
    });
  }

  void _highlightSearchResult() {
    if (_searchResults.isEmpty || _currentSearchIndex == -1) return;

    final position = _searchResults[_currentSearchIndex];
    final searchTerm = _searchController.text;

    _controller.selection = TextSelection(
      baseOffset: position,
      extentOffset: position + searchTerm.length,
    );
  }

  void _replaceSelected() {
    if (_searchResults.isEmpty || _currentSearchIndex == -1) return;

    final text = _controller.text;
    final searchTerm = _searchController.text;
    final replaceTerm = _replaceController.text;
    final position = _searchResults[_currentSearchIndex];

    final newText = text.replaceRange(
      position,
      position + searchTerm.length,
      replaceTerm,
    );

    setState(() {
      _controller.text = newText;
      _isModified = true;
    });

    // Refresh search results
    _performSearch();
  }

  void _replaceAll() {
    final searchTerm = _searchController.text;
    final replaceTerm = _replaceController.text;

    if (searchTerm.isEmpty) return;

    final newText = _controller.text.replaceAll(searchTerm, replaceTerm);

    setState(() {
      _controller.text = newText;
      _isModified = true;
      _searchResults.clear();
      _currentSearchIndex = -1;
    });

    _showSnackBar('Replaced all occurrences');
  }

  void _showUnsavedChangesDialog(VoidCallback onProceed) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Unsaved Changes'),
          content: Text('Do you want to save changes to $_currentFileName?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onProceed();
              },
              child: const Text('Don\'t Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveFile().then((_) => onProceed());
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveFile() async {
    try {
      // Apply random indentation chaos before saving
      _chaosManager?.randomIndentationOnSave();

      if (_currentFilePath != null) {
        // Save directly to existing file without popup
        final file = File(_currentFilePath!);
        await file.writeAsString(_controller.text);
        setState(() {
          _isModified = false;
        });
        _showSnackBar('File saved successfully');
      } else {
        // Use native file dialog for new files
        await _saveAsFile();
      }
    } catch (e) {
      _showSnackBar('Error saving file: $e');
    }
  }

  Future<void> _saveAsFile() async {
    try {
      // Use native Windows file dialog
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save File As',
        fileName: _currentFileName.endsWith('.txt')
            ? _currentFileName
            : '${_currentFileName.replaceAll('.txt', '')}.txt',
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (outputFile != null) {
        // Apply random indentation chaos before saving
        _chaosManager?.randomIndentationOnSave();

        final file = File(outputFile);
        await file.writeAsString(_controller.text);

        setState(() {
          _currentFilePath = outputFile;
          _currentFileName = outputFile.split(Platform.pathSeparator).last;
          _isModified = false;
        });

        _showSnackBar('File saved as $_currentFileName');
      }
    } catch (e) {
      _showSnackBar('Error saving file: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _selectAll() {
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  void _handleSave() {
    _saveFile();
  }

  // Text formatting methods
  void _toggleBold() {
    setState(() {
      _isBold = !_isBold;
    });
  }

  void _toggleItalic() {
    setState(() {
      _isItalic = !_isItalic;
    });
  }

  void _toggleUnderline() {
    setState(() {
      _isUnderline = !_isUnderline;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA):
            const SelectAllIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
            const SaveIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN):
            const NewFileIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyO):
            const OpenFileIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyS,
        ): const SaveAsIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
            const FindIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyH):
            const ReplaceIntent(),
        LogicalKeySet(LogicalKeyboardKey.f3): const FindNextIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.f3):
            const FindPreviousIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          SelectAllIntent: CallbackAction<SelectAllIntent>(
            onInvoke: (SelectAllIntent intent) {
              _selectAll();
              return null;
            },
          ),
          SaveIntent: CallbackAction<SaveIntent>(
            onInvoke: (SaveIntent intent) {
              _handleSave();
              return null;
            },
          ),
          NewFileIntent: CallbackAction<NewFileIntent>(
            onInvoke: (NewFileIntent intent) {
              _newFile();
              return null;
            },
          ),
          OpenFileIntent: CallbackAction<OpenFileIntent>(
            onInvoke: (OpenFileIntent intent) {
              _openFile();
              return null;
            },
          ),
          SaveAsIntent: CallbackAction<SaveAsIntent>(
            onInvoke: (SaveAsIntent intent) {
              _saveAsFile();
              return null;
            },
          ),
          FindIntent: CallbackAction<FindIntent>(
            onInvoke: (FindIntent intent) {
              _showFindDialog();
              return null;
            },
          ),
          ReplaceIntent: CallbackAction<ReplaceIntent>(
            onInvoke: (ReplaceIntent intent) {
              _showReplaceDialog();
              return null;
            },
          ),
          FindNextIntent: CallbackAction<FindNextIntent>(
            onInvoke: (FindNextIntent intent) {
              _findNext();
              return null;
            },
          ),
          FindPreviousIntent: CallbackAction<FindPreviousIntent>(
            onInvoke: (FindPreviousIntent intent) {
              _findPrevious();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: Colors.grey.shade50,
            body: Column(
              children: [
                Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade200,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Tab list - scrollable if too many tabs
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _tabs.length,
                          itemBuilder: (context, index) {
                            final tab = _tabs[index];
                            final isActive = index == _currentTabIndex;

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 4,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.white
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isActive
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade200,
                                  width: 0.5,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _switchToTab(index),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        tab.isModified
                                            ? '${tab.fileName}*'
                                            : tab.fileName,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: isActive
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: isActive
                                              ? Colors.black87
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => _closeTab(index),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            size: 10,
                                            color: isActive
                                                ? Colors.grey.shade600
                                                : Colors.grey.shade400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Add new tab button
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(left: 3, right: 6),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.pink.shade100,
                            width: 0.8,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.pink.shade50,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _newFile,
                            borderRadius: BorderRadius.circular(6),
                            child: Icon(
                              Icons.add,
                              size: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Toolbar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: const Color(0xFFE0E0E0),
                        width: 0.5,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // File menu
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.transparent,
                          border: null,
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            popupMenuTheme: PopupMenuThemeData(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                                side: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 0.5,
                                ),
                              ),
                              elevation: 2,
                            ),
                          ),
                          child: PopupMenuButton<String>(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.folder_outlined,
                                    size: 12,
                                    color: Colors.black87,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'File',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onSelected: (value) {
                              switch (value) {
                                case 'new':
                                  _newFile();
                                  break;
                                case 'open':
                                  _openFile();
                                  break;
                                case 'save':
                                  _handleSave();
                                  break;
                                case 'save_as':
                                  _saveAsFile();
                                  break;
                                case 'exit':
                                  _exitApplication();
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                height: 32,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                value: 'new',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.note_add,
                                      size: 14,
                                      color: Colors.black87,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'New (Ctrl+N)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black87,
                                        fontFamily: 'Segoe UI',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                height: 32,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                value: 'open',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.folder_open,
                                      size: 14,
                                      color: Colors.black87,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Open (Ctrl+O)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black87,
                                        fontFamily: 'Segoe UI',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                height: 32,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                value: 'save',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.save,
                                      size: 14,
                                      color: Colors.black87,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Save (Ctrl+S)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black87,
                                        fontFamily: 'Segoe UI',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                height: 32,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                value: 'save_as',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.save_as,
                                      size: 14,
                                      color: Colors.black87,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Save As (Ctrl+Shift+S)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black87,
                                        fontFamily: 'Segoe UI',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                height: 32,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                value: 'exit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.exit_to_app,
                                      size: 14,
                                      color: Colors.black87,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Exit',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black87,
                                        fontFamily: 'Segoe UI',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Edit menu
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            popupMenuTheme: PopupMenuThemeData(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                                side: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 0.5,
                                ),
                              ),
                              elevation: 2,
                            ),
                          ),
                          child: PopupMenuButton<String>(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 12,
                                    color: Colors.black87,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Edit',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onSelected: (value) {
                              switch (value) {
                                case 'select_all':
                                  _selectAll();
                                  break;
                                case 'find':
                                  _showFindDialog();
                                  break;
                                case 'replace':
                                  _showReplaceDialog();
                                  break;
                                case 'clear':
                                  _clearFormatting();
                                  break;
                                case 'go_to_line':
                                  _goToLine();
                                  break;
                                case 'insert_datetime':
                                  _insertDateTime();
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                height: 32,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                value: 'select_all',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.select_all,
                                      size: 14,
                                      color: Colors.black87,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Select All (Ctrl+A)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black87,
                                        fontFamily: 'Segoe UI',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                height: 32,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                value: 'find',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.search,
                                      size: 14,
                                      color: Colors.black87,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Find (Ctrl+F)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black87,
                                        fontFamily: 'Segoe UI',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                height: 32,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                value: 'replace',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.find_replace,
                                      size: 14,
                                      color: Colors.black87,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Replace (Ctrl+H)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black87,
                                        fontFamily: 'Segoe UI',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                height: 32,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                value: 'clear',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.clear_all,
                                      size: 14,
                                      color: Colors.black87,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Clear Formatting',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black87,
                                        fontFamily: 'Segoe UI',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                height: 32,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                value: 'go_to_line',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.linear_scale,
                                      size: 14,
                                      color: Colors.black87,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Go to Line (Ctrl+G)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black87,
                                        fontFamily: 'Segoe UI',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                height: 32,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                value: 'insert_datetime',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.black87,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Insert Date/Time (F5)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black87,
                                        fontFamily: 'Segoe UI',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Text formatting buttons
                      _buildFormatButton(
                        Icons.format_bold,
                        _isBold,
                        _toggleBold,
                      ),
                      _buildFormatButton(
                        Icons.format_italic,
                        _isItalic,
                        _toggleItalic,
                      ),
                      _buildFormatButton(
                        Icons.format_underlined,
                        _isUnderline,
                        _toggleUnderline,
                      ),
                    ],
                  ),
                ),

                // Text Editor Area
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (KeyEvent event) {
                        // Only record on key down events to avoid duplicates
                        if (event is KeyDownEvent) {
                          _typingSpeedMonitor?.recordKeystroke();
                        }
                      },
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: null,
                        expands: true,
                        onChanged: (String newText) {
                          setState(() {
                            _isModified = true;
                          });
                          _updateStats();
                          // Don't call recordKeystroke here to avoid conflicts
                        },
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Segoe UI',
                          color: Colors.black,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                          hintText: 'Start typing...',
                          hintStyle: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 14,
                          ),
                        ),
                        textAlign: TextAlign.start,
                        textAlignVertical: TextAlignVertical.top,
                        cursorColor: Colors.black,
                        cursorWidth: 1.0,
                      ),
                    ),
                  ),
                ),

                // Status Bar
                Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F8F8),
                    border: Border(
                      top: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Ln $_lineNumber, Col $_columnNumber',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Words: $_wordCount  |  Characters: $_charCount',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                      const Spacer(),
                      // Chaos Mode Indicator
                      if (_isChaosEnabled) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 10,
                                color: Colors.red.shade600,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'CHAOS',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      const Text(
                        'Plain text',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        '100%',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Windows (CRLF)',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'UTF-8',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormatButton(IconData icon, bool isActive, VoidCallback onTap) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isActive ? Colors.blue.shade100 : Colors.transparent,
        border: Border.all(
          color: isActive ? Colors.blue.shade300 : Colors.grey.shade300,
          width: 0.8,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Icon(
            icon,
            size: 14,
            color: isActive ? Colors.blue.shade600 : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
