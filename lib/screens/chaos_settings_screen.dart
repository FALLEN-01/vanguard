import 'package:flutter/material.dart';

class ChaosSettingsScreen extends StatefulWidget {
  final bool isChaosEnabled;
  final Function(bool) onChaosToggle;

  const ChaosSettingsScreen({
    super.key,
    required this.isChaosEnabled,
    required this.onChaosToggle,
  });

  @override
  State<ChaosSettingsScreen> createState() => _ChaosSettingsScreenState();
}

class _ChaosSettingsScreenState extends State<ChaosSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chaos Mode Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Chaos Mode',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ALWAYS ON',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Chaotic text editor behaviors are permanently active and will randomly interfere with your typing experience.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade600,
                      height: 1.4,
                    ),
                  ),
                  // Always show chaos descriptions since it's permanently active
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Chaos Behaviors:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ..._buildChaosDescriptions(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // General Settings Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Editor Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSettingTile(
                    'Font Size',
                    '14px',
                    Icons.text_fields,
                    onTap: () {},
                  ),
                  _buildSettingTile(
                    'Theme',
                    'Light',
                    Icons.palette_outlined,
                    onTap: () {},
                  ),
                  _buildSettingTile(
                    'Auto Save',
                    'Every 30 seconds',
                    Icons.save_outlined,
                    onTap: () {},
                  ),
                  _buildSettingTile(
                    'Chaos Interval',
                    '8-15 seconds',
                    Icons.timer_outlined,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Warning Footer - Always show since chaos is permanent
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chaos mode is permanently active. Your text will be randomly modified while typing every 8-15 seconds.',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildChaosDescriptions() {
    final descriptions = [
      '• Random cursor displacement while typing',
      '• Spontaneous deletion of characters or words',
      '• Letter and word position swapping',
      '• Unexpected punctuation insertion',
      '• Random line indentation on save',
      '• Chaos interval: 8-15 seconds (increased)',
    ];

    return descriptions
        .map(
          (desc) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              desc,
              style: TextStyle(fontSize: 10, color: Colors.red.shade700),
            ),
          ),
        )
        .toList();
  }

  Widget _buildSettingTile(
    String title,
    String value,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade500),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ),
            Text(
              value,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
