import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

// Text span with formatting info
class FormattedTextSpan {
  final String text;
  final bool isBold;
  final bool isItalic;

  FormattedTextSpan({
    required this.text,
    this.isBold = false,
    this.isItalic = false,
  });
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

  // Rich text formatting
  final List<FormattedTextSpan> _textSpans = [];
  bool _isBold = false;
  bool _isItalic = false;
  String _lastText = '';

  final String _currentHeading = 'Normal';
  int _characterCount = 0;
  int _lineNumber = 1;
  int _columnNumber = 1;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateStats);
    _controller.addListener(_handleTextChange);
    // Initialize with one empty span
    _textSpans.add(FormattedTextSpan(text: '', isBold: false, isItalic: false));
  }

  @override
  void dispose() {
    _controller.removeListener(_updateStats);
    _controller.removeListener(_handleTextChange);
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

  void _handleTextChange() {
    final text = _controller.text;
    final selection = _controller.selection;

    // Only handle new text additions
    if (text.length > _lastText.length) {
      final newText = text.substring(_lastText.length);
      _addFormattedText(newText, _isBold, _isItalic);
    } else if (text.length < _lastText.length) {
      // Handle deletions by rebuilding spans
      _rebuildTextSpans(text, selection);
    }

    _lastText = text;
  }

  void _addFormattedText(String newText, bool isBold, bool isItalic) {
    // Add new text with current formatting
    if (_textSpans.isNotEmpty &&
        _textSpans.last.isBold == isBold &&
        _textSpans.last.isItalic == isItalic) {
      // Same formatting as last span, append to it
      final lastSpan = _textSpans.last;
      _textSpans[_textSpans.length - 1] = FormattedTextSpan(
        text: lastSpan.text + newText,
        isBold: lastSpan.isBold,
        isItalic: lastSpan.isItalic,
      );
    } else {
      // Different formatting, create new span
      _textSpans.add(
        FormattedTextSpan(text: newText, isBold: isBold, isItalic: isItalic),
      );
    }
  }

  void _rebuildTextSpans(String text, TextSelection selection) {
    // For deletions, we'll keep it simple and just track the current text
    // In a full implementation, you'd want more sophisticated span management
    if (text.isEmpty) {
      _textSpans.clear();
      _textSpans.add(
        FormattedTextSpan(text: '', isBold: false, isItalic: false),
      );
    }
  }

  void _applyFormatting(bool isBold, bool isItalic) {
    final selection = _controller.selection;

    if (selection.isValid && !selection.isCollapsed) {
      // Apply formatting to selected text
      final selectedText = _controller.text.substring(
        selection.start,
        selection.end,
      );

      // For simplicity, replace all text with formatted version
      // In a full implementation, you'd modify only the selected spans
      _applyFormattingToSelection(selectedText, isBold, isItalic, selection);
    } else {
      // No selection, just toggle formatting for new text
      setState(() {
        if (isBold) _isBold = !_isBold;
        if (isItalic) _isItalic = !_isItalic;
      });
    }
  }

  void _applyFormattingToSelection(
    String selectedText,
    bool makeBold,
    bool makeItalic,
    TextSelection selection,
  ) {
    final text = _controller.text;
    final beforeSelection = text.substring(0, selection.start);
    final afterSelection = text.substring(selection.end);

    // Rebuild text spans with formatted selection
    _textSpans.clear();

    // Add text before selection (keep original formatting)
    if (beforeSelection.isNotEmpty) {
      _textSpans.add(FormattedTextSpan(text: beforeSelection));
    }

    // Add selected text with new formatting
    if (selectedText.isNotEmpty) {
      _textSpans.add(
        FormattedTextSpan(
          text: selectedText,
          isBold: makeBold,
          isItalic: makeItalic,
        ),
      );
    }

    // Add text after selection (keep original formatting)
    if (afterSelection.isNotEmpty) {
      _textSpans.add(FormattedTextSpan(text: afterSelection));
    }

    setState(() {});
  }

  void _selectAll() {
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
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
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          BoldIntent: CallbackAction<BoldIntent>(
            onInvoke: (BoldIntent intent) {
              _applyFormatting(true, false);
              return null;
            },
          ),
          ItalicIntent: CallbackAction<ItalicIntent>(
            onInvoke: (ItalicIntent intent) {
              _applyFormatting(false, true);
              return null;
            },
          ),
          SelectAllIntent: CallbackAction<SelectAllIntent>(
            onInvoke: (SelectAllIntent intent) {
              _selectAll();
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
                            onTap: () {},
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.settings,
                                size: 14,
                                color: Colors.grey.shade400,
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
                      _buildFormatButton(Icons.format_bold, _isBold, () {
                        _applyFormatting(true, false);
                      }),
                      _buildFormatButton(Icons.format_italic, _isItalic, () {
                        _applyFormatting(false, true);
                      }),
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
    // For now, let's use a simpler approach that avoids cursor offset issues
    // We'll use a regular TextField but update the text spans properly
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      maxLines: null,
      expands: true,
      style: const TextStyle(
        fontSize: 14,
        fontFamily: 'Segoe UI',
        color: Colors.black,
        height: 1.4,
        // Base style - formatting is handled through text spans
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
      cursorColor: Colors.black,
      cursorWidth: 1.0,
    );
  }
}
