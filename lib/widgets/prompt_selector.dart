import 'package:flutter/material.dart';

class PromptSelector extends StatelessWidget {
  final List<Map<String, dynamic>> templates;
  final String selectedTemplateId;
  final ValueChanged<String> onChanged;

  const PromptSelector({
    super.key,
    required this.templates,
    required this.selectedTemplateId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedTemplateId,
      decoration: const InputDecoration(
        labelText: 'Template',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.article),
      ),
      items: templates.map((template) {
        return DropdownMenuItem<String>(
          value: template['id'] as String,
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  template['description'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (template['rules'] != null)
                  Text(
                    _buildRulesText(template['rules']),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }

  String _buildRulesText(Map<String, dynamic> rules) {
    final parts = <String>[];
    if (rules['max_chars'] != null) {
      parts.add('max ${rules['max_chars']} chars');
    }
    if (rules['parts'] != null) {
      parts.add('${rules['parts']} parti');
    }
    if (rules['hashtags_max'] != null) {
      parts.add('${rules['hashtags_max']} hashtag');
    }
    return parts.join(' • ');
  }
}
