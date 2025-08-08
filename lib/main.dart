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
    final actions = [
      cursorTeleportation,
      randomDeletion,
      letterOrWordSwapping,
      punctuationInjection,
    ];

    // Pick a random action
    final action = actions[_random.nextInt(actions.length)];
    action();
    updateState();
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
}

// TypingSpeedMonitor handles speed-based chaos escalation
class TypingSpeedMonitor {
  final Random _random = Random();
  final VoidCallback showSpeedWarning;
  final VoidCallback forceShutdown;
  final VoidCallback triggerSpeedChaos;

  // Typing speed tracking
  final List<DateTime> _keystrokes = [];
  Timer? _speedCheckTimer;
  int _speedViolationCount = 0;

  // Speed thresholds (characters per minute)
  static const int _warningThreshold = 300; // 5 chars/sec
  static const int _chaosThreshold = 450; // 7.5 chars/sec
  static const int _shutdownThreshold = 600; // 10 chars/sec

  TypingSpeedMonitor({
    required this.showSpeedWarning,
    required this.forceShutdown,
    required this.triggerSpeedChaos,
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

    if (cpm >= _shutdownThreshold) {
      _speedViolationCount++;
      if (_speedViolationCount >= 3) {
        // Ultimate punishment
        forceShutdown();
        return;
      }
      showSpeedWarning();
      triggerSpeedChaos();
    } else if (cpm >= _chaosThreshold) {
      _speedViolationCount++;
      triggerSpeedChaos();
      if (_random.nextDouble() < 0.7) {
        // 70% chance
        showSpeedWarning();
      }
    } else if (cpm >= _warningThreshold) {
      if (_random.nextDouble() < 0.4) {
        // 40% chance
        showSpeedWarning();
      }
    } else {
      // Reduce violation count if typing slows down
      if (_speedViolationCount > 0) {
        _speedViolationCount = (_speedViolationCount - 1).clamp(0, 10);
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
      triggerSpeedChaos: _triggerSpeedChaos,
    );

    // Start monitoring
    _typingSpeedMonitor?.startMonitoring();
  }

  void _showSpeedWarning() {
    final messages = [
      "🐌 SLOW DOWN THERE, SPEEDRACER! 🐌\nThe system can't handle your lightning fingers!",
      "⚡ TYPING SPEED VIOLATION DETECTED ⚡\nYou're going faster than a caffeinated cheetah!",
      "🚨 SPEED LIMIT EXCEEDED 🚨\nThis is a text editor, not a racing game!",
      "🔥 BURNING RUBBER ON THE KEYBOARD? 🔥\nSlow down before you break something!",
      "⚠️ DANGER: HYPERSONIC TYPING ⚠️\nYour fingers are moving faster than the speed of light!",
      "🎯 TYPING SPEED: LUDICROUS MODE 🎯\nEven NASA computers are jealous!",
      "💨 WHOOSH! TOO FAST! 💨\nYou're typing so fast, you're creating a time paradox!",
    ];

    final randomMessage = messages[Random().nextInt(messages.length)];

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
            Icon(Icons.warning, color: Colors.black87, size: 20),
            const SizedBox(width: 8),
            Text(
              'SPEED WARNING',
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
          width: 350,
          child: Text(
            randomMessage,
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
            onPressed: () => Navigator.pop(context),
            child: const Text('I\'LL SLOW DOWN, I PROMISE!'),
          ),
        ],
      ),
    );
  }

  void _forceShutdown() {
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
          width: 350,
          child: Text(
            "💥 CRITICAL ERROR: FINGERS TOO FAST! 💥\n\nYour typing speed has exceeded all known limits of human capability! The application must shut down to prevent a keyboard singularity from forming.\n\nFarewell, speed demon! 👋",
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
              // Force close app after brief delay
              Timer(const Duration(seconds: 1), () {
                SystemNavigator.pop();
              });
            },
            child: const Text('ACCEPT DEFEAT'),
          ),
        ],
      ),
    );
  }

  void _triggerSpeedChaos() {
    // Trigger additional chaos beyond normal chaos manager
    // Call chaos manager's methods directly
    if (_chaosManager != null) {
      final extraChaosActions = [
        () => _chaosManager!.cursorTeleportation(),
        () => _chaosManager!.cursorTeleportation(), // Extra cursor chaos
        () => _chaosManager!.punctuationInjection(),
        () => _chaosManager!.randomDeletion(),
      ];

      final action =
          extraChaosActions[Random().nextInt(extraChaosActions.length)];
      action();
      setState(() {});
    }
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

  void _handleTextChanged(String newText) {
    setState(() {
      _isModified = true;
    });
    _updateStats();

    // Record keystroke for speed monitoring
    _typingSpeedMonitor?.recordKeystroke();
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
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: null,
                      expands: true,
                      onChanged: _handleTextChanged,
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
