import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'chaos/chaos_controller.dart';
import 'screens/chaos_settings_screen.dart';

// Intent classes for keyboard shortcuts
class BoldIntent extends Intent {
  const BoldIntent();
}

class ItalicIntent extends Intent {
  const ItalicIntent();
}

class SelectAllIntent extends Intent {
  const SelectAllIntent();
}

class ChaosToggleIntent extends Intent {
  const ChaosToggleIntent();
}

class SaveIntent extends Intent {
  const SaveIntent();
}

// Rich text formatting system - replica of Windows Notepad
class TextSegment {
  String content;
  bool isBold;
  bool isItalic;
  bool isUnderline;

  TextSegment({
    required this.content,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
  });

  TextSegment copy() {
    return TextSegment(
      content: content,
      isBold: isBold,
      isItalic: isItalic,
      isUnderline: isUnderline,
    );
  }

  bool hasSameFormatting(TextSegment other) {
    return isBold == other.isBold &&
        isItalic == other.isItalic &&
        isUnderline == other.isUnderline;
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

  // Rich text formatting system
  List<TextSegment> _segments = [];
  bool _currentBold = false;
  bool _currentItalic = false;

  // Chaos system - permanently active
  ChaosController? _chaosController;
  bool _isChaosEnabled = true; // Always enabled

  final String _currentHeading = 'Normal';
  int _characterCount = 0;
  int _lineNumber = 1;
  int _columnNumber = 1;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateStats);
    // Initialize with empty document
    _segments = [TextSegment(content: '')];

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
    // Update segments when chaos modifies text
    _segments = [TextSegment(content: newText)];
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

  // Core rich text formatting methods - Exact Notepad behavior
  void _applyBoldFormatting() {
    final selection = _controller.selection;
    if (selection.isValid && !selection.isCollapsed) {
      // Apply bold to selected text (uniform override)
      _applyFormattingToSelection(isBold: true);
    } else {
      // Toggle bold mode for new text only
      setState(() {
        _currentBold = !_currentBold;
      });
    }
  }

  void _applyItalicFormatting() {
    final selection = _controller.selection;
    if (selection.isValid && !selection.isCollapsed) {
      // Apply italic to selected text (uniform override)
      _applyFormattingToSelection(isItalic: true);
    } else {
      // Toggle italic mode for new text only
      setState(() {
        _currentItalic = !_currentItalic;
      });
    }
  }

  void _applyFormattingToSelection({
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
  }) {
    final selection = _controller.selection;
    if (!selection.isValid || selection.isCollapsed) return;

    final text = _controller.text;
    final selectedText = text.substring(selection.start, selection.end);

    // Rebuild segments with the selection having uniform formatting
    List<TextSegment> newSegments = [];

    // Add text before selection (preserve existing formatting)
    if (selection.start > 0) {
      _addTextAsSegments(text.substring(0, selection.start), newSegments);
    }

    // Add formatted selection as a single segment with uniform formatting
    newSegments.add(
      TextSegment(
        content: selectedText,
        isBold: isBold ?? false,
        isItalic: isItalic ?? false,
        isUnderline: isUnderline ?? false,
      ),
    );

    // Add text after selection (preserve existing formatting)
    if (selection.end < text.length) {
      _addTextAsSegments(text.substring(selection.end), newSegments);
    }

    _segments = newSegments;
    setState(() {});
  }

  void _addTextAsSegments(String text, List<TextSegment> segments) {
    if (text.isNotEmpty) {
      // For now, add as plain text segments
      // This will be enhanced to preserve existing formatting
      segments.add(TextSegment(content: text));
    }
  }

  void _handleTextChanged(String newText) {
    final selection = _controller.selection;
    final oldText = _segments.map((s) => s.content).join();

    if (newText.length > oldText.length) {
      // Text was added - apply current formatting to new text
      final insertPosition =
          selection.baseOffset - (newText.length - oldText.length);
      final insertedText = newText.substring(
        insertPosition,
        selection.baseOffset,
      );

      if (insertedText.isNotEmpty) {
        _insertFormattedText(insertedText, insertPosition);
      }
    }

    _updateStats();
  }

  void _insertFormattedText(String text, int position) {
    // Create a new segment for the inserted text with current formatting
    final newSegment = TextSegment(
      content: text,
      isBold: _currentBold,
      isItalic: _currentItalic,
      isUnderline: false, // Add underline support later if needed
    );

    // Rebuild segments with the new formatted text
    List<TextSegment> newSegments = [];
    int currentPosition = 0;

    for (var segment in _segments) {
      if (currentPosition + segment.content.length <= position) {
        // Segment is completely before insertion point
        newSegments.add(segment);
        currentPosition += segment.content.length;
      } else if (currentPosition >= position) {
        // Segment is completely after insertion point
        if (newSegments.isEmpty || newSegments.last != newSegment) {
          newSegments.add(newSegment);
        }
        newSegments.add(segment);
        currentPosition += segment.content.length;
      } else {
        // Insertion point is within this segment - split it
        final beforeText = segment.content.substring(
          0,
          position - currentPosition,
        );
        final afterText = segment.content.substring(position - currentPosition);

        if (beforeText.isNotEmpty) {
          newSegments.add(
            TextSegment(
              content: beforeText,
              isBold: segment.isBold,
              isItalic: segment.isItalic,
              isUnderline: segment.isUnderline,
            ),
          );
        }

        newSegments.add(newSegment);

        if (afterText.isNotEmpty) {
          newSegments.add(
            TextSegment(
              content: afterText,
              isBold: segment.isBold,
              isItalic: segment.isItalic,
              isUnderline: segment.isUnderline,
            ),
          );
        }

        currentPosition += segment.content.length;
        break;
      }
    }

    _segments = newSegments;
    setState(() {});
  }

  void _selectAll() {
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  void _handleSave() {
    // Use chaos controller's save handler if chaos is enabled
    if (_isChaosEnabled && _chaosController != null) {
      _chaosController!.handleSave();
    } else {
      // Normal save logic would go here
      _handleChaosSave();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB):
            const BoldIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyI):
            const ItalicIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA):
            const SelectAllIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
            const SaveIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          BoldIntent: CallbackAction<BoldIntent>(
            onInvoke: (BoldIntent intent) {
              _applyBoldFormatting();
              return null;
            },
          ),
          ItalicIntent: CallbackAction<ItalicIntent>(
            onInvoke: (ItalicIntent intent) {
              _applyItalicFormatting();
              return null;
            },
          ),
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
                          color: Colors.pink.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.pink.shade100,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Untitled',
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
                            color: Colors.pink.shade100,
                            width: 0.8,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.pink.shade50,
                        ),
                        child: Icon(
                          Icons.add,
                          size: 12,
                          color: Colors.grey.shade400,
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
                    color: Colors.white,
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
                      _buildMenuButton('File'),
                      _buildMenuButton('Edit'),
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
                      _buildFormatButton(Icons.format_bold, _currentBold, () {
                        _applyBoldFormatting();
                      }),
                      _buildFormatButton(
                        Icons.format_italic,
                        _currentItalic,
                        () {
                          _applyItalicFormatting();
                        },
                      ),
                      _buildFormatButton(Icons.link, false, () {}),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 0.8,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.grey.shade50,
                        ),
                        child: Text(
                          'Aa',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
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
                    child: _buildRichTextField(),
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
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200, width: 0.8),
        borderRadius: BorderRadius.circular(6),
        color: Colors.grey.shade50,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 3),
          Icon(Icons.arrow_drop_down, size: 14, color: Colors.grey.shade400),
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
        color: isActive ? Colors.pink.shade50 : Colors.transparent,
        border: Border.all(
          color: isActive ? Colors.pink.shade200 : Colors.grey.shade200,
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
            color: isActive ? Colors.pink.shade400 : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  Widget _buildRichTextField() {
    // Build TextSpans from segments for rich text display
    List<TextSpan> textSpans = [];

    for (var segment in _segments) {
      if (segment.content.isNotEmpty) {
        textSpans.add(
          TextSpan(
            text: segment.content,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Segoe UI',
              color: Colors.black,
              height: 1.4,
              fontWeight: segment.isBold ? FontWeight.w600 : FontWeight.w400,
              fontStyle: segment.isItalic ? FontStyle.italic : FontStyle.normal,
              decoration: segment.isUnderline
                  ? TextDecoration.underline
                  : TextDecoration.none,
            ),
          ),
        );
      }
    }

    // For now, use simple TextField approach that shows current formatting
    // This avoids cursor alignment issues while we build the core functionality
    return TextField(
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
        // New text will use current formatting mode
        fontWeight: _currentBold ? FontWeight.w600 : FontWeight.w400,
        fontStyle: _currentItalic ? FontStyle.italic : FontStyle.normal,
      ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.all(16),
        hintText: '',
      ),
      textAlign: TextAlign.start,
      textAlignVertical: TextAlignVertical.top,
      cursorColor: Colors.black,
      cursorWidth: 1.0,
    );
  }
}
