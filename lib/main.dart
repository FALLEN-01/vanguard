import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        scaffoldBackgroundColor: const Color(0xFFF3F3F3),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
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
  bool _isBold = false;
  bool _isItalic = false;
  final String _currentHeading = 'Normal';
  int _characterCount = 0;
  int _lineNumber = 1;
  int _columnNumber = 1;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateStats);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateStats);
    _controller.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: Column(
        children: [
          // Custom Title Bar with Mica effect
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              border: const Border(
                bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                // Notepad icon
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(2),
                      bottomLeft: Radius.circular(2),
                      bottomRight: Radius.circular(2),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(left: 2),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(1),
                        bottomLeft: Radius.circular(1),
                      ),
                    ),
                    width: 3,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Untitled - ScramPad',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                // Title bar controls
                _buildTitleBarButton(Icons.palette, Colors.red),
                _buildTitleBarButton(Icons.account_circle, Colors.orange),
                _buildTitleBarButton(Icons.settings, Colors.grey),
                _buildTitleBarButton(Icons.minimize, Colors.grey),
                _buildTitleBarButton(Icons.crop_square, Colors.grey),
                _buildTitleBarButton(Icons.close, Colors.grey),
              ],
            ),
          ),

          // Tab Bar
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
                    horizontal: 8,
                    vertical: 4,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Untitled',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.close, size: 12, color: Colors.grey),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.add, size: 14, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                const SizedBox(width: 16),
                _buildDropdown(_currentHeading, ['Normal', 'H1', 'H2', 'H3']),
                const SizedBox(width: 8),
                _buildDropdown('•', ['•', '1.', '→']),
                const SizedBox(width: 16),
                _buildFormatButton(Icons.format_bold, _isBold, () {
                  setState(() => _isBold = !_isBold);
                }),
                _buildFormatButton(Icons.format_italic, _isItalic, () {
                  setState(() => _isItalic = !_isItalic);
                }),
                _buildFormatButton(Icons.link, false, () {}),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Aa',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
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
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Segoe UI',
                  color: Colors.black,
                  height: 1.4,
                  fontWeight: _isBold ? FontWeight.w600 : FontWeight.w400,
                  fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
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
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
                const SizedBox(width: 16),
                Text(
                  '$_characterCount characters',
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
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
    );
  }

  Widget _buildTitleBarButton(IconData icon, Color color) {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(right: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          child: Icon(icon, size: 14, color: color.withValues(alpha: 0.8)),
        ),
      ),
    );
  }

  Widget _buildMenuButton(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey.shade600),
        ],
      ),
    );
  }

  Widget _buildFormatButton(IconData icon, bool isActive, VoidCallback onTap) {
    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.blue.withValues(alpha: 0.1)
            : Colors.transparent,
        border: Border.all(
          color: isActive
              ? Colors.blue.withValues(alpha: 0.3)
              : Colors.grey.shade300,
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
            size: 16,
            color: isActive ? Colors.blue : Colors.black54,
          ),
        ),
      ),
    );
  }
}
