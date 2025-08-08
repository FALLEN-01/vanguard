import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'chaos/chaos_controller.dart';
import 'screens/chaos_settings_screen.dart';

// Intent classes for keyboard shortcuts
class SelectAllIntent extends Intent {
  const SelectAllIntent();
}

class ChaosToggleIntent extends Intent {
  const ChaosToggleIntent();
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

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScramPad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Colors.blue,
          surface: Color(0xFFFAFAFA),
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
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
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // File handling
  String _currentFileName = 'Untitled';
  String? _currentFilePath;
  bool _isModified = false;

  // Find/Replace functionality
  String _searchTerm = '';
  String _replaceTerm = '';
  int _currentSearchIndex = -1;
  List<int> _searchResults = [];
  bool _isSearchVisible = false;
  bool _isReplaceVisible = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();

  // Chaos system - permanently active
  ChaosController? _chaosController;
  bool _isChaosEnabled = true; // Always enabled
  bool _isChaosPulseActive = false;

  final String _currentHeading = 'Normal';
  int _characterCount = 0;
  int _lineNumber = 1;
  int _columnNumber = 1;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateStats);

    // Initialize chaos controller
    _initializeChaosController();
  }

  void _initializeChaosController() {
    _chaosController = ChaosController(
      textController: _controller,
      onTextChanged: _handleChaosTextChange,
      onSelectionChanged: _handleChaosSelectionChange,
      onSave: _handleChaosSave,
    );
    // Start chaos immediately - it's permanently active
    _chaosController?.startChaos();
  }

  void _handleChaosTextChange(String newText) {
    // Update when chaos modifies text
    _updateStats();
  }

  void _handleChaosSelectionChange(TextSelection selection) {
    // Handle selection changes from chaos
    setState(() {});
  }

  void _handleChaosSave() {
    // Handle save action (could trigger file save dialog)
    // For now, just update stats
    _updateStats();
  }

  void _toggleChaos(bool enabled) {
    // Chaos mode is permanently active - this function does nothing
    // but we keep it for settings screen compatibility
    // setState(() {
    //   _isChaosEnabled = enabled;
    // });

    // Chaos always remains active
    // if (enabled) {
    //   _chaosController?.startChaos();
    // } else {
    //   _chaosController?.stopChaos();
    // }
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChaosSettingsScreen(
          isChaosEnabled: _isChaosEnabled,
          onChaosToggle: _toggleChaos,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _chaosController?.dispose();
    _controller.removeListener(_updateStats);
    _controller.dispose();
    _focusNode.dispose();
    _searchController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  void _updateStats() {
    final text = _controller.text;
    final selection = _controller.selection;

    setState(() {
      _characterCount = text.length;
      if (selection.isValid) {
        final beforeCursor = text.substring(0, selection.baseOffset);
        _lineNumber = '\n'.allMatches(beforeCursor).length + 1;
        _columnNumber = beforeCursor.split('\n').last.length + 1;
      }
    });
  }

  void _handleTextChanged(String newText) {
    setState(() {
      _isModified = true;
    });
    _updateStats();
  }

  // File handling methods
  void _newFile() {
    if (_isModified) {
      _showUnsavedChangesDialog(() => _createNewFile());
    } else {
      _createNewFile();
    }
  }

  void _createNewFile() {
    setState(() {
      _controller.text = '';
      _currentFileName = 'Untitled';
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
      // Simple file picker using system dialog (basic implementation)
      // For a more robust solution, you'd use the file_picker package
      final downloadsPath = Platform.isWindows
          ? '${Platform.environment['USERPROFILE']}${Platform.pathSeparator}Downloads'
          : '${Platform.environment['HOME']}${Platform.pathSeparator}Downloads';

      // For demo purposes, we'll show a dialog asking for filename
      final fileName = await _showFileNameDialog(
        'Open File',
        'Enter filename to open from Downloads:',
      );
      if (fileName != null && fileName.isNotEmpty) {
        final filePath = '$downloadsPath${Platform.pathSeparator}$fileName';
        final file = File(filePath);

        if (await file.exists()) {
          final content = await file.readAsString();
          setState(() {
            _controller.text = content;
            _currentFileName = fileName;
            _currentFilePath = filePath;
            _isModified = false;
          });
          _showSnackBar('File opened successfully');
        } else {
          _showSnackBar('File not found: $fileName');
        }
      }
    } catch (e) {
      _showSnackBar('Error opening file: $e');
    }
  }

  Future<String?> _showFileNameDialog(String title, String hint) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: hint),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _clearFormatting() {
    // Since we removed rich text formatting, this just shows a message
    _showSnackBar('No formatting to clear - plain text mode active');
  }

  void _exitApplication() {
    if (_isModified) {
      _showUnsavedChangesDialog(() => _performExit());
    } else {
      _performExit();
    }
  }

  void _performExit() {
    // In a real app, you'd use SystemNavigator.pop() or similar
    _showSnackBar('Exit requested - close window manually');
  }

  // Find and Replace functionality
  void _showFindDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isChaosEnabled ? Colors.red.shade50 : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _isChaosEnabled ? Colors.red.shade200 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        title: Row(
          children: [
            Icon(
              Icons.search,
              color: _isChaosEnabled ? Colors.red.shade600 : Colors.blue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Find',
              style: TextStyle(
                color: _isChaosEnabled ? Colors.red.shade700 : null,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Enter text to find...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _isChaosEnabled
                    ? Colors.red.shade300
                    : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _isChaosEnabled ? Colors.red.shade500 : Colors.blue,
                width: 2,
              ),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: _isChaosEnabled
                  ? Colors.red.shade400
                  : Colors.grey.shade600,
            ),
          ),
          autofocus: true,
          onSubmitted: (_) => _performSearch(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: _isChaosEnabled ? Colors.red.shade600 : null,
              ),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.search_outlined, size: 16),
            label: const Text('Find All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isChaosEnabled ? Colors.red.shade100 : null,
              foregroundColor: _isChaosEnabled ? Colors.red.shade700 : null,
            ),
            onPressed: () {
              _performSearch();
              Navigator.pop(context);
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Find Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isChaosEnabled
                  ? Colors.red.shade600
                  : Colors.blue,
              foregroundColor: Colors.white,
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
    setState(() {
      _isSearchVisible = true;
      _isReplaceVisible = false;
    });
  }

  void _showReplaceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isChaosEnabled ? Colors.red.shade50 : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _isChaosEnabled ? Colors.red.shade200 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        title: Row(
          children: [
            Icon(
              Icons.find_replace,
              color: _isChaosEnabled ? Colors.red.shade600 : Colors.blue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Find and Replace',
              style: TextStyle(
                color: _isChaosEnabled ? Colors.red.shade700 : null,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Find',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _isChaosEnabled ? Colors.red.shade500 : Colors.blue,
                    width: 2,
                  ),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: _isChaosEnabled
                      ? Colors.red.shade400
                      : Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _replaceController,
              decoration: InputDecoration(
                labelText: 'Replace with',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _isChaosEnabled ? Colors.red.shade500 : Colors.blue,
                    width: 2,
                  ),
                ),
                prefixIcon: Icon(
                  Icons.edit,
                  color: _isChaosEnabled
                      ? Colors.red.shade400
                      : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: _isChaosEnabled ? Colors.red.shade600 : null,
              ),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.search_outlined, size: 16),
            label: const Text('Find All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isChaosEnabled ? Colors.red.shade100 : null,
              foregroundColor: _isChaosEnabled ? Colors.red.shade700 : null,
            ),
            onPressed: () {
              _performSearch();
              Navigator.pop(context);
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.swap_horiz, size: 16),
            label: const Text('Replace'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isChaosEnabled
                  ? Colors.red.shade200
                  : Colors.orange,
              foregroundColor: _isChaosEnabled
                  ? Colors.red.shade800
                  : Colors.white,
            ),
            onPressed: () {
              _replaceSelected();
              Navigator.pop(context);
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.swap_vert, size: 16),
            label: const Text('Replace All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isChaosEnabled
                  ? Colors.red.shade600
                  : Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              _replaceAll();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
    setState(() {
      _isSearchVisible = true;
      _isReplaceVisible = true;
    });
  }

  void _hideFindReplace() {
    setState(() {
      _isSearchVisible = false;
      _isReplaceVisible = false;
      _searchResults.clear();
      _currentSearchIndex = -1;
    });
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
      if (_currentFilePath != null) {
        // Save to existing file
        final file = File(_currentFilePath!);
        await file.writeAsString(_controller.text);
        setState(() {
          _isModified = false;
        });
        _showSnackBar('File saved successfully');
      } else {
        // Save as new file
        await _saveAsFile();
      }
    } catch (e) {
      _showSnackBar('Error saving file: $e');
    }
  }

  Future<void> _saveAsFile() async {
    try {
      // For now, save to Downloads folder with timestamp
      final downloadsPath = Platform.isWindows
          ? '${Platform.environment['USERPROFILE']}${Platform.pathSeparator}Downloads'
          : '${Platform.environment['HOME']}${Platform.pathSeparator}Downloads';

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = _currentFileName == 'Untitled'
          ? 'scrampad_$timestamp.txt'
          : _currentFileName;

      final filePath = '$downloadsPath${Platform.pathSeparator}$fileName';
      final file = File(filePath);

      await file.writeAsString(_controller.text);

      setState(() {
        _currentFilePath = filePath;
        _currentFileName = fileName;
        _isModified = false;
      });

      _showSnackBar('File saved as $fileName');
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
    // Always use the file save functionality
    _saveFile();
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
            backgroundColor: Colors.white,
            body: Column(
              children: [
                Container(
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _isChaosEnabled
                              ? Colors.red.shade50
                              : Colors.pink.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isChaosEnabled
                                ? Colors.red.shade100
                                : Colors.pink.shade100,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isModified
                                  ? '$_currentFileName*'
                                  : _currentFileName,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.close,
                              size: 10,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(left: 3),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _isChaosEnabled
                                ? Colors.red.shade100
                                : Colors.pink.shade100,
                            width: 0.8,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          color: _isChaosEnabled
                              ? Colors.red.shade50
                              : Colors.pink.shade50,
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
                      const Spacer(), // Push settings icon to the right
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _openSettings,
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.settings,
                                size: 14,
                                color: _isChaosEnabled
                                    ? Colors.red.shade400
                                    : Colors.grey.shade400,
                              ),
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
                    color: _isChaosEnabled
                        ? Colors.red.shade50.withOpacity(0.3)
                        : Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: _isChaosEnabled
                            ? Colors.red.shade100
                            : const Color(0xFFE0E0E0),
                        width: 0.5,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isChaosEnabled
                            ? Colors.red.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05)),
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
                          color: _isChaosEnabled
                              ? Colors.red.shade50.withOpacity(0.5)
                              : Colors.transparent,
                          border: _isChaosEnabled
                              ? Border.all(
                                  color: Colors.red.shade100,
                                  width: 0.5,
                                )
                              : null,
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            popupMenuTheme: PopupMenuThemeData(
                              color: _isChaosEnabled ? Colors.red.shade50 : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: _isChaosEnabled ? Colors.red.shade200 : Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
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
                                    color: _isChaosEnabled
                                        ? Colors.red.shade400
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'File',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: _isChaosEnabled
                                          ? Colors.red.shade600
                                          : Colors.grey.shade600,
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
                              value: 'new',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.note_add, 
                                    size: 16,
                                    color: _isChaosEnabled ? Colors.red.shade600 : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'New (Ctrl+N)',
                                    style: TextStyle(
                                      color: _isChaosEnabled ? Colors.red.shade700 : null,
                                      fontWeight: _isChaosEnabled ? FontWeight.w500 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'open',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.folder_open, 
                                    size: 16,
                                    color: _isChaosEnabled ? Colors.red.shade600 : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Open (Ctrl+O)',
                                    style: TextStyle(
                                      color: _isChaosEnabled ? Colors.red.shade700 : null,
                                      fontWeight: _isChaosEnabled ? FontWeight.w500 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'save',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.save, 
                                    size: 16,
                                    color: _isChaosEnabled ? Colors.red.shade600 : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Save (Ctrl+S)',
                                    style: TextStyle(
                                      color: _isChaosEnabled ? Colors.red.shade700 : null,
                                      fontWeight: _isChaosEnabled ? FontWeight.w500 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'save_as',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.save_as, 
                                    size: 16,
                                    color: _isChaosEnabled ? Colors.red.shade600 : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Save As (Ctrl+Shift+S)',
                                    style: TextStyle(
                                      color: _isChaosEnabled ? Colors.red.shade700 : null,
                                      fontWeight: _isChaosEnabled ? FontWeight.w500 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'exit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.exit_to_app, 
                                    size: 16,
                                    color: _isChaosEnabled ? Colors.red.shade600 : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Exit',
                                    style: TextStyle(
                                      color: _isChaosEnabled ? Colors.red.shade700 : null,
                                      fontWeight: _isChaosEnabled ? FontWeight.w500 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Edit menu
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: _isChaosEnabled
                              ? Colors.red.shade50.withOpacity(0.5)
                              : Colors.transparent,
                          border: _isChaosEnabled
                              ? Border.all(
                                  color: Colors.red.shade100,
                                  width: 0.5,
                                )
                              : null,
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
                                  color: _isChaosEnabled
                                      ? Colors.red.shade400
                                      : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Edit',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _isChaosEnabled
                                        ? Colors.red.shade600
                                        : Colors.grey.shade600,
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
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'select_all',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.select_all, 
                                    size: 16,
                                    color: _isChaosEnabled ? Colors.red.shade600 : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Select All (Ctrl+A)',
                                    style: TextStyle(
                                      color: _isChaosEnabled ? Colors.red.shade700 : null,
                                      fontWeight: _isChaosEnabled ? FontWeight.w500 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'find',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search, 
                                    size: 16,
                                    color: _isChaosEnabled ? Colors.red.shade600 : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Find (Ctrl+F)',
                                    style: TextStyle(
                                      color: _isChaosEnabled ? Colors.red.shade700 : null,
                                      fontWeight: _isChaosEnabled ? FontWeight.w500 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'replace',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.find_replace, 
                                    size: 16,
                                    color: _isChaosEnabled ? Colors.red.shade600 : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Replace (Ctrl+H)',
                                    style: TextStyle(
                                      color: _isChaosEnabled ? Colors.red.shade700 : null,
                                      fontWeight: _isChaosEnabled ? FontWeight.w500 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'clear',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.clear_all, 
                                    size: 16,
                                    color: _isChaosEnabled ? Colors.red.shade600 : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Clear Formatting',
                                    style: TextStyle(
                                      color: _isChaosEnabled ? Colors.red.shade700 : null,
                                      fontWeight: _isChaosEnabled ? FontWeight.w500 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildMenuButton('View'),
                      const SizedBox(width: 12),
                      _buildDropdown(_currentHeading, [
                        'Normal',
                        'H1',
                        'H2',
                        'H3',
                      ]),
                      const SizedBox(width: 6),
                      _buildDropdown('•', ['•', '1.', '→']),
                      const SizedBox(width: 12),
                      _buildFormatButton(Icons.link, false, () {}),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _isChaosEnabled
                                ? Colors.red.shade200
                                : Colors.grey.shade200,
                            width: 0.8,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          color: _isChaosEnabled
                              ? Colors.red.shade50.withOpacity(0.7)
                              : Colors.grey.shade50,
                        ),
                        child: Text(
                          'Aa',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _isChaosEnabled
                                ? Colors.red.shade600
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Text Editor Area
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: _buildTextField(),
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
                        '$_characterCount characters',
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

  Widget _buildMenuButton(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: _isChaosEnabled
            ? Colors.red.shade50.withOpacity(0.5)
            : Colors.transparent,
        border: _isChaosEnabled
            ? Border.all(color: Colors.red.shade100, width: 0.5)
            : null,
      ),
      child: InkWell(
        onTap: text == 'File' ? _showFileMenu : () {},
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                text == 'View' ? Icons.visibility_outlined : Icons.more_horiz,
                size: 12,
                color: _isChaosEnabled
                    ? Colors.red.shade400
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                text,
                style: TextStyle(
                  fontSize: 11,
                  color: _isChaosEnabled
                      ? Colors.red.shade600
                      : Colors.grey.shade600,
                  fontWeight: _isChaosEnabled
                      ? FontWeight.w500
                      : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFileMenu() {
    // Show a simple file menu
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('File'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('New'),
                onTap: () {
                  Navigator.of(context).pop();
                  _newFile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.save),
                title: const Text('Save'),
                onTap: () {
                  Navigator.of(context).pop();
                  _saveFile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.save_as),
                title: const Text('Save As'),
                onTap: () {
                  Navigator.of(context).pop();
                  _saveAsFile();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDropdown(String value, List<String> items) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(
          color: _isChaosEnabled ? Colors.red.shade200 : Colors.grey.shade200,
          width: 0.8,
        ),
        borderRadius: BorderRadius.circular(6),
        color: _isChaosEnabled
            ? Colors.red.shade50.withOpacity(0.7)
            : Colors.grey.shade50,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: _isChaosEnabled
                  ? Colors.red.shade600
                  : Colors.grey.shade600,
              fontWeight: _isChaosEnabled ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 3),
          Icon(
            Icons.arrow_drop_down,
            size: 14,
            color: _isChaosEnabled ? Colors.red.shade400 : Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  Widget _buildFormatButton(IconData icon, bool isActive, VoidCallback onTap) {
    return Container(
      width: 22,
      height: 22,
      margin: const EdgeInsets.only(right: 3),
      decoration: BoxDecoration(
        color: isActive
            ? (_isChaosEnabled ? Colors.red.shade100 : Colors.pink.shade50)
            : Colors.transparent,
        border: Border.all(
          color: isActive
              ? (_isChaosEnabled ? Colors.red.shade300 : Colors.pink.shade200)
              : (_isChaosEnabled ? Colors.red.shade200 : Colors.grey.shade200),
          width: 0.8,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Icon(
            icon,
            size: 12,
            color: isActive
                ? (_isChaosEnabled ? Colors.red.shade600 : Colors.pink.shade400)
                : (_isChaosEnabled
                      ? Colors.red.shade400
                      : Colors.grey.shade500),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return Container(
      decoration: _isChaosEnabled
          ? BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.red.shade50.withOpacity(0.1)],
              ),
            )
          : null,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLines: null,
        expands: true,
        onChanged: _handleTextChanged,
        style: TextStyle(
          fontSize: 14,
          fontFamily: 'Segoe UI',
          color: _isChaosEnabled ? Colors.red.shade900 : Colors.black,
          height: 1.4,
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
          hintText: '',
        ),
        textAlign: TextAlign.start,
        textAlignVertical: TextAlignVertical.top,
        cursorColor: _isChaosEnabled ? Colors.red.shade600 : Colors.black,
        cursorWidth: _isChaosEnabled ? 2.0 : 1.0,
        selectionControls: _isChaosEnabled
            ? MaterialTextSelectionControls()
            : null,
      ),
    );
  }
}
