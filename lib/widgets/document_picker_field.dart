import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// A required-document upload control used during Partner/Driver sign-up
/// (ID, Commercial Registration, Residential ID, Driver's Licence).
///
/// This demo only remembers the picked file's **name** — nothing is
/// uploaded anywhere, and no bytes are kept. A real onboarding flow would
/// upload the file to secure storage and route it into a manual or
/// automated KYC/document-verification review; that review is what should
/// flip an account's [VerificationStatus] from `pending` to `verified`, not
/// the mere act of picking a file the way this widget does.
class DocumentPickerField extends FormField<String> {
  // Can't use super-parameter shorthand for key/onSaved/validator here: this
  // constructor already has an explicit `: super(...)` call (needed to pass
  // `builder`), and Dart forbids mixing the two in one constructor.
  // ignore: use_super_parameters
  DocumentPickerField({
    Key? key,
    required String label,
    required IconData icon,
    FormFieldSetter<String>? onSaved,
    FormFieldValidator<String>? validator,
  }) : super(
          key: key,
          onSaved: onSaved,
          validator: validator,
          builder: (state) {
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _pickFile(state),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: label,
                  prefixIcon: Icon(icon),
                  errorText: state.errorText,
                  suffixIcon: Icon(
                    state.value == null ? Icons.upload_file_outlined : Icons.check_circle,
                    color: state.value == null ? null : Colors.green,
                  ),
                ),
                child: Text(
                  state.value ?? 'Tap to upload (PDF, JPG, or PNG)',
                  overflow: TextOverflow.ellipsis,
                  style: state.value == null ? TextStyle(color: Theme.of(state.context).hintColor) : null,
                ),
              ),
            );
          },
        );

  static Future<void> _pickFile(FormFieldState<String> state) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.isNotEmpty) {
      state.didChange(result.files.single.name);
    }
  }
}
