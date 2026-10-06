import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../resume/presentation/resume_editor_screen.dart';

class CustomTemplateBuilderScreen extends ConsumerStatefulWidget {
  const CustomTemplateBuilderScreen({super.key});

  @override
  ConsumerState<CustomTemplateBuilderScreen> createState() =>
      _CustomTemplateBuilderScreenState();
}

class _CustomTemplateBuilderScreenState
    extends ConsumerState<CustomTemplateBuilderScreen> {
  // Template customization options
  String _selectedLayout = 'two_column';
  Color _primaryColor = Colors.blue;
  Color _accentColor = Colors.blueAccent;
  String _fontFamily = 'Outfit';
  double _headerSize = 24.0;
  double _bodySize = 11.0;
  bool _showProfilePicture = false;
  bool _showColoredHeader = true;
  bool _showSkillBars = false;
  String _skillsLayout = 'list';

  final List<Map<String, dynamic>> _layouts = [
    {
      'id': 'single_column',
      'name': 'Single Column',
      'description': 'Traditional single-column layout',
      'icon': Icons.view_agenda_rounded,
    },
    {
      'id': 'two_column',
      'name': 'Two Column',
      'description': 'Modern sidebar layout',
      'icon': Icons.view_column_rounded,
    },
    {
      'id': 'creative',
      'name': 'Creative Header',
      'description': 'Eye-catching header design',
      'icon': Icons.auto_awesome_rounded,
    },
  ];

  final List<Color> _colorOptions = [
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
    Colors.brown,
    Colors.grey,
  ];

  final List<String> _fontOptions = [
    'Outfit',
    'Roboto',
    'Open Sans',
    'Lato',
    'Montserrat',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'Custom Template Builder',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          FilledButton.icon(
            onPressed: _createCustomTemplate,
            icon: const Icon(Icons.create_rounded),
            label: const Text('Create Resume'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Left Panel - Customization Options
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Layout Style'),
                    _buildLayoutSelector(),

                    const SizedBox(height: 32),
                    _buildSectionTitle('Color Scheme'),
                    _buildColorSelector(),

                    const SizedBox(height: 32),
                    _buildSectionTitle('Typography'),
                    _buildTypographySelector(),

                    const SizedBox(height: 32),
                    _buildSectionTitle('Design Options'),
                    _buildDesignOptions(),

                    const SizedBox(height: 32),
                    _buildSectionTitle('Skills Display'),
                    _buildSkillsOptions(),
                  ],
                ),
              ),
            ),
          ),

          // Right Panel - Live Preview
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Preview',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _buildPreview(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildLayoutSelector() {
    return Column(
      children: [
        const SizedBox(height: 16),
        ..._layouts.map((layout) {
          final isSelected = _selectedLayout == layout['id'];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedLayout = layout['id'] ?? 'two_column';
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _primaryColor.withValues(alpha: 0.1)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? _primaryColor : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      layout['icon'],
                      color: isSelected ? _primaryColor : Colors.grey[600],
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            layout['name'],
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? _primaryColor
                                  : Colors.black87,
                            ),
                          ),
                          Text(
                            layout['description'],
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: _primaryColor,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Primary Color',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _colorOptions.map((color) {
            final isSelected = _primaryColor == color;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _primaryColor = color;
                  _accentColor = color.withValues(alpha: 0.7);
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.black87 : Colors.grey[300]!,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Primary Color',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accent Color',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: _accentColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypographySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
        value: _fontFamily,
          decoration: const InputDecoration(
            labelText: 'Font Family',
            border: OutlineInputBorder(),
          ),
          items: _fontOptions.map((font) {
            return DropdownMenuItem(value: font, child: Text(font));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _fontFamily = value;
              });
            }
          },
        ),
        const SizedBox(height: 20),
        Text(
          'Header Size: ${_headerSize.toInt()}pt',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: _headerSize,
          min: 18,
          max: 32,
          divisions: 14,
          activeColor: _primaryColor,
          onChanged: (value) {
            setState(() {
              _headerSize = value;
            });
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Body Size: ${_bodySize.toInt()}pt',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: _bodySize,
          min: 9,
          max: 14,
          divisions: 5,
          activeColor: _primaryColor,
          onChanged: (value) {
            setState(() {
              _bodySize = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDesignOptions() {
    return Column(
      children: [
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Show Profile Picture'),
          subtitle: const Text('Add a circular profile photo'),
          value: _showProfilePicture,
          activeColor: _primaryColor,
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _primaryColor;
            }
            return null;
          }),
          onChanged: (value) {
            setState(() {
              _showProfilePicture = value;
            });
          },
        ),
        SwitchListTile(
          title: const Text('Colored Header'),
          subtitle: const Text('Use primary color for header background'),
          value: _showColoredHeader,
          activeColor: _primaryColor,
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _primaryColor;
            }
            return null;
          }),
          onChanged: (value) {
            setState(() {
              _showColoredHeader = value;
            });
          },
        ),
        SwitchListTile(
          title: const Text('Skill Progress Bars'),
          subtitle: const Text('Show skills with visual progress bars'),
          value: _showSkillBars,
          activeColor: _primaryColor,
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _primaryColor;
            }
            return null;
          }),
          onChanged: (value) {
            setState(() {
              _showSkillBars = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSkillsOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _skillsLayout,
          decoration: const InputDecoration(
            labelText: 'Skills Layout',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'list', child: Text('Simple List')),
            DropdownMenuItem(value: 'grid', child: Text('Grid Layout')),
            DropdownMenuItem(value: 'tags', child: Text('Tag Style')),
            DropdownMenuItem(value: 'columns', child: Text('Two Columns')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _skillsLayout = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _showColoredHeader ? _primaryColor : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (_showProfilePicture) ...[
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: _showColoredHeader
                        ? Colors.white
                        : _primaryColor,
                    child: Icon(
                      Icons.person_rounded,
                      color: _showColoredHeader ? _primaryColor : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Name',
                        style: _getTextStyle(
                          fontSize: _headerSize,
                          fontWeight: FontWeight.bold,
                          color: _showColoredHeader
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      Text(
                        'Your Professional Headline',
                        style: _getTextStyle(
                          fontSize: _bodySize + 2,
                          color: _showColoredHeader
                              ? Colors.white.withValues(alpha: 0.9)
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Content Preview
          Expanded(
            child: _selectedLayout == 'two_column'
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column
                      Expanded(
                        flex: 1,
                        child: _buildPreviewSection(
                          'Skills',
                          _buildSkillsPreview(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Right Column
                      Expanded(
                        flex: 2,
                        child: _buildPreviewSection(
                          'Experience',
                          _buildExperiencePreview(),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPreviewSection(
                        'Experience',
                        _buildExperiencePreview(),
                      ),
                      const SizedBox(height: 12),
                      _buildPreviewSection('Skills', _buildSkillsPreview()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: _getTextStyle(
            fontSize: _bodySize + 2,
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        Container(
          height: 2,
          width: 30,
          color: _primaryColor,
          margin: const EdgeInsets.only(top: 4, bottom: 8),
        ),
        content,
      ],
    );
  }

  Widget _buildSkillsPreview() {
    final skills = ['Skill 1', 'Skill 2', 'Skill 3', 'Skill 4', 'Skill 5'];

    // Safety check to ensure skills array is not empty
    if (skills.isEmpty) {
      return const Text('No skills to display');
    }

    if (_skillsLayout == 'tags') {
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: skills.map((skill) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              skill,
              style: _getTextStyle(
                fontSize: _bodySize - 1,
                color: _primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      );
    } else if (_showSkillBars) {
      return Column(
        children: skills.map((skill) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill,
                  style: _getTextStyle(
                    fontSize: _bodySize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: 0.8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: skills.map((skill) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('• $skill', style: _getTextStyle(fontSize: _bodySize)),
          );
        }).toList(),
      );
    }
  }

  Widget _buildExperiencePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Job Title',
          style: _getTextStyle(
            fontSize: _bodySize + 1,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Company Name • Start – End',
          style: _getTextStyle(fontSize: _bodySize, color: _accentColor),
        ),
        const SizedBox(height: 4),
        Text(
          'A brief description of your responsibilities and achievements in this role.',
          style: _getTextStyle(fontSize: _bodySize - 1, height: 1.4),
        ),
      ],
    );
  }

  TextStyle _getTextStyle({
    required double fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    try {
      // Ensure font family is valid
      final fontFamily = _fontFamily.isNotEmpty ? _fontFamily : 'Outfit';
      return GoogleFonts.getFont(fontFamily).copyWith(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
      );
    } catch (e) {
      // Fallback to default font if Google Font fails
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
      );
    }
  }

  void _createCustomTemplate() {
    // Map the selected layout to an existing template ID
    // 'two_column' and 'creative' map to 'modern'; 'single_column' maps to 'classic'
    final templateId = _selectedLayout == 'single_column'
        ? 'classic'
        : 'modern';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResumeEditorScreen(templateId: templateId),
      ),
    );
  }
}
