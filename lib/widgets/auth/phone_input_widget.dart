import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'country_picker_widget.dart';

class PhoneInputWidget extends StatefulWidget {
  final String? initialValue;
  final Country? initialCountry;
  final ValueChanged<String>? onPhoneChanged;
  final ValueChanged<Country>? onCountryChanged;
  final ValueChanged<PhoneInputData>? onChanged;
  final String? errorText;
  final String? placeholder;
  final bool enabled;
  final bool required;
  final String? label;
  final bool autoValidate;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;

  const PhoneInputWidget({
    super.key,
    this.initialValue,
    this.initialCountry,
    this.onPhoneChanged,
    this.onCountryChanged,
    this.onChanged,
    this.errorText,
    this.placeholder,
    this.enabled = true,
    this.required = false,
    this.label,
    this.autoValidate = false,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<PhoneInputWidget> createState() => _PhoneInputWidgetState();
}

class _PhoneInputWidgetState extends State<PhoneInputWidget> {
  late TextEditingController _phoneController;
  Country? _selectedCountry;
  String? _validationError;

  // Default to US if no country is specified
  static const Country _defaultCountry = Country(
    name: 'United States',
    code: 'US',
    dialCode: '+1',
    flag: '🇺🇸',
  );

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialValue);
    _selectedCountry = widget.initialCountry ?? _defaultCountry;
    _phoneController.addListener(_onPhoneTextChanged);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onPhoneTextChanged() {
    final phoneNumber = _phoneController.text;

    if (widget.autoValidate) {
      _validatePhoneNumber(phoneNumber);
    }

    final data = PhoneInputData(
      phoneNumber: phoneNumber,
      country: _selectedCountry!,
      fullPhoneNumber: _selectedCountry!.dialCode + phoneNumber,
    );

    widget.onPhoneChanged?.call(phoneNumber);
    widget.onChanged?.call(data);
  }

  void _onCountryChanged(Country country) {
    setState(() {
      _selectedCountry = country;
    });

    widget.onCountryChanged?.call(country);

    final data = PhoneInputData(
      phoneNumber: _phoneController.text,
      country: country,
      fullPhoneNumber: country.dialCode + _phoneController.text,
    );

    widget.onChanged?.call(data);
  }

  String? _validatePhoneNumber(String phoneNumber) {
    if (widget.required && phoneNumber.isEmpty) {
      _validationError = 'Phone number is required';
      return _validationError;
    }

    if (phoneNumber.isEmpty) {
      _validationError = null;
      return null;
    }

    // Basic validation rules based on country
    String? error = _validateByCountry(phoneNumber, _selectedCountry!);

    setState(() {
      _validationError = error;
    });

    return error;
  }

  String? _validateByCountry(String phoneNumber, Country country) {
    // Remove any non-digit characters for validation
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    switch (country.code) {
      case 'US':
      case 'CA':
        if (cleanNumber.length != 10) {
          return 'Phone number must be 10 digits';
        }
        if (cleanNumber.startsWith('0') || cleanNumber.startsWith('1')) {
          return 'Phone number cannot start with 0 or 1';
        }
        break;
      case 'GB':
        if (cleanNumber.length < 10 || cleanNumber.length > 11) {
          return 'Phone number must be 10-11 digits';
        }
        break;
      case 'IN':
        if (cleanNumber.length != 10) {
          return 'Phone number must be 10 digits';
        }
        if (!cleanNumber.startsWith(RegExp(r'[6-9]'))) {
          return 'Phone number must start with 6, 7, 8, or 9';
        }
        break;
      case 'AU':
        if (cleanNumber.length != 9) {
          return 'Phone number must be 9 digits';
        }
        break;
      case 'DE':
        if (cleanNumber.length < 10 || cleanNumber.length > 12) {
          return 'Phone number must be 10-12 digits';
        }
        break;
      case 'FR':
        if (cleanNumber.length != 10) {
          return 'Phone number must be 10 digits';
        }
        break;
      case 'JP':
        if (cleanNumber.length < 10 || cleanNumber.length > 11) {
          return 'Phone number must be 10-11 digits';
        }
        break;
      case 'CN':
        if (cleanNumber.length != 11) {
          return 'Phone number must be 11 digits';
        }
        break;
      default:
        // Generic validation for other countries
        if (cleanNumber.length < 7 || cleanNumber.length > 15) {
          return 'Phone number must be 7-15 digits';
        }
    }

    return null;
  }

  String _formatPhoneNumber(String phoneNumber, Country country) {
    // Remove any non-digit characters
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanNumber.isEmpty) return '';

    // Format based on country
    switch (country.code) {
      case 'US':
      case 'CA':
        return _formatNANP(cleanNumber);
      case 'GB':
        return _formatUK(cleanNumber);
      case 'IN':
        return _formatIndia(cleanNumber);
      default:
        return cleanNumber;
    }
  }

  String _formatNANP(String number) {
    // North American Numbering Plan (US, Canada)
    if (number.length <= 3) return number;
    if (number.length <= 6) {
      return '(${number.substring(0, 3)}) ${number.substring(3)}';
    }
    return '(${number.substring(0, 3)}) ${number.substring(3, 6)}-${number.substring(6)}';
  }

  String _formatUK(String number) {
    if (number.length <= 4) return number;
    if (number.length <= 7) {
      return '${number.substring(0, 4)} ${number.substring(4)}';
    }
    return '${number.substring(0, 4)} ${number.substring(4, 7)} ${number.substring(7)}';
  }

  String _formatIndia(String number) {
    if (number.length <= 5) return number;
    return '${number.substring(0, 5)}-${number.substring(5)}';
  }

  PhoneInputData? get value {
    if (_selectedCountry == null) return null;

    return PhoneInputData(
      phoneNumber: _phoneController.text,
      country: _selectedCountry!,
      fullPhoneNumber: _selectedCountry!.dialCode + _phoneController.text,
    );
  }

  String? validate() {
    return _validatePhoneNumber(_phoneController.text);
  }

  void clear() {
    _phoneController.clear();
    setState(() {
      _validationError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveError = widget.errorText ?? _validationError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
        ],

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Country selector
            CompactCountrySelector(
              selectedCountry: _selectedCountry,
              onCountrySelected: _onCountryChanged,
              enabled: widget.enabled,
            ),

            const SizedBox(width: 12),

            // Phone number input
            Expanded(
              child: ShadInput(
                controller: _phoneController,
                focusNode: widget.focusNode,
                enabled: widget.enabled,
                placeholder: Text(widget.placeholder ?? 'Phone number'),
                keyboardType: TextInputType.phone,
                textInputAction: widget.textInputAction ?? TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15),
                  _PhoneNumberFormatter(_selectedCountry!),
                ],
                onSubmitted: widget.onSubmitted != null
                    ? (_) => widget.onSubmitted!()
                    : null,
                decoration: ShadDecoration(),
              ),
            ),
          ],
        ),

        if (effectiveError != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  effectiveError,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ],
          ),
        ],

        // Show full phone number preview
        if (_phoneController.text.isNotEmpty && _selectedCountry != null) ...[
          const SizedBox(height: 4),
          Text(
            'Full number: ${_selectedCountry!.dialCode} ${_phoneController.text}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ],
    );
  }
}

// Data class to hold phone input information
class PhoneInputData {
  final String phoneNumber;
  final Country country;
  final String fullPhoneNumber;

  const PhoneInputData({
    required this.phoneNumber,
    required this.country,
    required this.fullPhoneNumber,
  });

  @override
  String toString() {
    return 'PhoneInputData(phoneNumber: $phoneNumber, country: ${country.name}, fullPhoneNumber: $fullPhoneNumber)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PhoneInputData &&
        other.phoneNumber == phoneNumber &&
        other.country.code == country.code &&
        other.fullPhoneNumber == fullPhoneNumber;
  }

  @override
  int get hashCode {
    return phoneNumber.hashCode ^
        country.code.hashCode ^
        fullPhoneNumber.hashCode;
  }
}

// Custom formatter for phone numbers
class _PhoneNumberFormatter extends TextInputFormatter {
  final Country country;

  _PhoneNumberFormatter(this.country);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Only allow digits
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Don't format if deleting
    if (newValue.text.length < oldValue.text.length) {
      return newValue.copyWith(text: digitsOnly);
    }

    String formatted = _formatNumber(digitsOnly);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatNumber(String number) {
    switch (country.code) {
      case 'US':
      case 'CA':
        return _formatNANP(number);
      case 'GB':
        return _formatUK(number);
      case 'IN':
        return _formatIndia(number);
      default:
        return number;
    }
  }

  String _formatNANP(String number) {
    if (number.length <= 3) return number;
    if (number.length <= 6) {
      return '(${number.substring(0, 3)}) ${number.substring(3)}';
    }
    return '(${number.substring(0, 3)}) ${number.substring(3, 6)}-${number.substring(6)}';
  }

  String _formatUK(String number) {
    if (number.length <= 4) return number;
    if (number.length <= 7) {
      return '${number.substring(0, 4)} ${number.substring(4)}';
    }
    return '${number.substring(0, 4)} ${number.substring(4, 7)} ${number.substring(7)}';
  }

  String _formatIndia(String number) {
    if (number.length <= 5) return number;
    return '${number.substring(0, 5)}-${number.substring(5)}';
  }
}

// Form field wrapper for integration with Form widgets
class PhoneInputFormField extends FormField<PhoneInputData> {
  PhoneInputFormField({
    super.key,
    PhoneInputData? initialValue,
    FormFieldSetter<PhoneInputData>? onSaved,
    FormFieldValidator<PhoneInputData>? validator,
    bool autovalidate = false,
    bool enabled = true,
    String? label,
    String? placeholder,
    bool required = false,
  }) : super(
         initialValue: initialValue,
         onSaved: onSaved,
         validator: validator,
         enabled: enabled,
         autovalidateMode: autovalidate
             ? AutovalidateMode.onUserInteraction
             : AutovalidateMode.disabled,
         builder: (FormFieldState<PhoneInputData> state) {
           return PhoneInputWidget(
             initialValue: initialValue?.phoneNumber,
             initialCountry: initialValue?.country,
             onChanged: (data) {
               state.didChange(data);
             },
             errorText: state.errorText,
             enabled: enabled,
             label: label,
             placeholder: placeholder,
             required: required,
             autoValidate: autovalidate,
           );
         },
       );
}
