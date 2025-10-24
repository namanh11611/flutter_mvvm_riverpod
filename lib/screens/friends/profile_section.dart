import 'package:flutter/material.dart';

class ProfileSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController handleController;
  final bool isEditable;
  final VoidCallback onSave;

  const ProfileSection({
    super.key,
    required this.nameController,
    required this.handleController,
    required this.isEditable,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            label: 'Name',
            controller: nameController,
            enabled: isEditable,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Handle',
            controller: handleController,
            enabled: isEditable,
          ),
         
          ],
        
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black, fontSize: 16)),
        const SizedBox(height: 5),
        SizedBox(
          height: 40,
          width: double.infinity,
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              filled: !enabled,
              
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFF3620B3)),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}