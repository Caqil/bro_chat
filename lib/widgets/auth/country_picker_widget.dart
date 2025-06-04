import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class Country {
  final String name;
  final String code;
  final String dialCode;
  final String flag;

  const Country({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
  });
}

class CountryPickerWidget extends StatefulWidget {
  final Country? selectedCountry;
  final ValueChanged<Country> onCountrySelected;
  final String? placeholder;
  final bool enabled;
  final String? errorText;

  const CountryPickerWidget({
    super.key,
    this.selectedCountry,
    required this.onCountrySelected,
    this.placeholder = 'Select country',
    this.enabled = true,
    this.errorText,
  });

  @override
  State<CountryPickerWidget> createState() => _CountryPickerWidgetState();
}

class _CountryPickerWidgetState extends State<CountryPickerWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<Country> _filteredCountries = [];
  bool _isDropdownOpen = false;

  // Popular countries list - you can expand this
  static const List<Country> _countries = [
    Country(name: 'United States', code: 'US', dialCode: '+1', flag: '🇺🇸'),
    Country(name: 'United Kingdom', code: 'GB', dialCode: '+44', flag: '🇬🇧'),
    Country(name: 'Canada', code: 'CA', dialCode: '+1', flag: '🇨🇦'),
    Country(name: 'Australia', code: 'AU', dialCode: '+61', flag: '🇦🇺'),
    Country(name: 'Germany', code: 'DE', dialCode: '+49', flag: '🇩🇪'),
    Country(name: 'France', code: 'FR', dialCode: '+33', flag: '🇫🇷'),
    Country(name: 'Italy', code: 'IT', dialCode: '+39', flag: '🇮🇹'),
    Country(name: 'Spain', code: 'ES', dialCode: '+34', flag: '🇪🇸'),
    Country(name: 'Japan', code: 'JP', dialCode: '+81', flag: '🇯🇵'),
    Country(name: 'South Korea', code: 'KR', dialCode: '+82', flag: '🇰🇷'),
    Country(name: 'China', code: 'CN', dialCode: '+86', flag: '🇨🇳'),
    Country(name: 'India', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
    Country(name: 'Indonesia', code: 'ID', dialCode: '+62', flag: '🇮🇩'),
    Country(name: 'Brazil', code: 'BR', dialCode: '+55', flag: '🇧🇷'),
    Country(name: 'Mexico', code: 'MX', dialCode: '+52', flag: '🇲🇽'),
    Country(name: 'Russia', code: 'RU', dialCode: '+7', flag: '🇷🇺'),
    Country(name: 'Turkey', code: 'TR', dialCode: '+90', flag: '🇹🇷'),
    Country(name: 'Saudi Arabia', code: 'SA', dialCode: '+966', flag: '🇸🇦'),
    Country(
      name: 'United Arab Emirates',
      code: 'AE',
      dialCode: '+971',
      flag: '🇦🇪',
    ),
    Country(name: 'Nigeria', code: 'NG', dialCode: '+234', flag: '🇳🇬'),
    Country(name: 'South Africa', code: 'ZA', dialCode: '+27', flag: '🇿🇦'),
    Country(name: 'Egypt', code: 'EG', dialCode: '+20', flag: '🇪🇬'),
    Country(name: 'Thailand', code: 'TH', dialCode: '+66', flag: '🇹🇭'),
    Country(name: 'Vietnam', code: 'VN', dialCode: '+84', flag: '🇻🇳'),
    Country(name: 'Philippines', code: 'PH', dialCode: '+63', flag: '🇵🇭'),
    Country(name: 'Singapore', code: 'SG', dialCode: '+65', flag: '🇸🇬'),
    Country(name: 'Malaysia', code: 'MY', dialCode: '+60', flag: '🇲🇾'),
    Country(name: 'Argentina', code: 'AR', dialCode: '+54', flag: '🇦🇷'),
    Country(name: 'Chile', code: 'CL', dialCode: '+56', flag: '🇨🇱'),
    Country(name: 'Colombia', code: 'CO', dialCode: '+57', flag: '🇨🇴'),
    Country(name: 'Peru', code: 'PE', dialCode: '+51', flag: '🇵🇪'),
    Country(name: 'Netherlands', code: 'NL', dialCode: '+31', flag: '🇳🇱'),
    Country(name: 'Belgium', code: 'BE', dialCode: '+32', flag: '🇧🇪'),
    Country(name: 'Switzerland', code: 'CH', dialCode: '+41', flag: '🇨🇭'),
    Country(name: 'Austria', code: 'AT', dialCode: '+43', flag: '🇦🇹'),
    Country(name: 'Sweden', code: 'SE', dialCode: '+46', flag: '🇸🇪'),
    Country(name: 'Norway', code: 'NO', dialCode: '+47', flag: '🇳🇴'),
    Country(name: 'Denmark', code: 'DK', dialCode: '+45', flag: '🇩🇰'),
    Country(name: 'Finland', code: 'FI', dialCode: '+358', flag: '🇫🇮'),
    Country(name: 'Poland', code: 'PL', dialCode: '+48', flag: '🇵🇱'),
    Country(name: 'Czech Republic', code: 'CZ', dialCode: '+420', flag: '🇨🇿'),
    Country(name: 'Hungary', code: 'HU', dialCode: '+36', flag: '🇭🇺'),
    Country(name: 'Portugal', code: 'PT', dialCode: '+351', flag: '🇵🇹'),
    Country(name: 'Greece', code: 'GR', dialCode: '+30', flag: '🇬🇷'),
    Country(name: 'Israel', code: 'IL', dialCode: '+972', flag: '🇮🇱'),
    Country(name: 'New Zealand', code: 'NZ', dialCode: '+64', flag: '🇳🇿'),
  ];

  @override
  void initState() {
    super.initState();
    _filteredCountries = _countries;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries(String query) {
    if (query.isEmpty) {
      _filteredCountries = _countries;
    } else {
      _filteredCountries = _countries
          .where(
            (country) =>
                country.name.toLowerCase().contains(query.toLowerCase()) ||
                country.dialCode.contains(query) ||
                country.code.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
    setState(() {});
  }

  void _openCountryPicker() {
    if (!widget.enabled) return;

    showDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Select Country'),
        actions: [
          ShadButton.outline(
            onPressed: () {
              Navigator.of(context).pop();
              _searchController.clear();
              _filteredCountries = _countries;
            },
            child: const Text('Cancel'),
          ),
        ],
        child: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: Column(
            children: [
              // Search field
              ShadInput(
                controller: _searchController,
                placeholder: const Text('Search countries...'),
                trailing: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Icon(Icons.search, size: 16, color: Colors.grey),
                ),
                onChanged: _filterCountries,
              ),
              const SizedBox(height: 16),

              // Countries list
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredCountries.length,
                  itemBuilder: (context, index) {
                    final country = _filteredCountries[index];
                    final isSelected =
                        widget.selectedCountry?.code == country.code;

                    return ShadButton.raw(
                      onPressed: () {
                        widget.onCountrySelected(country);
                        Navigator.of(context).pop();
                        _searchController.clear();
                        _filteredCountries = _countries;
                      },
                      variant: isSelected
                          ? ShadButtonVariant.secondary
                          : ShadButtonVariant.ghost,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Text(
                              country.flag,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    country.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${country.code} ${country.dialCode}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.green,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShadButton.outline(
          onPressed: widget.enabled ? _openCountryPicker : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                if (widget.selectedCountry != null) ...[
                  Text(
                    widget.selectedCountry!.flag,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.selectedCountry!.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          widget.selectedCountry!.dialCode,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: Text(
                      widget.placeholder ?? 'Select country',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),

        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

// Helper widget for compact country display (for forms)
class CompactCountrySelector extends StatelessWidget {
  final Country? selectedCountry;
  final ValueChanged<Country> onCountrySelected;
  final bool enabled;

  const CompactCountrySelector({
    super.key,
    this.selectedCountry,
    required this.onCountrySelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ShadButton.outline(
      onPressed: enabled ? () => _showCompactPicker(context) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedCountry != null) ...[
            Text(selectedCountry!.flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              selectedCountry!.dialCode,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ] else ...[
            const Icon(Icons.flag, size: 16),
            const SizedBox(width: 4),
            const Text('+1'),
          ],
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 16),
        ],
      ),
    );
  }

  void _showCompactPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CountryPickerWidget(
        selectedCountry: selectedCountry,
        onCountrySelected: (country) {
          onCountrySelected(country);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
