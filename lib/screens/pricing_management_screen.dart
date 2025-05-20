import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class PricingManagementScreen extends StatefulWidget {
  const PricingManagementScreen({Key? key}) : super(key: key);

  @override
  State<PricingManagementScreen> createState() => _PricingManagementScreenState();
}

class _PricingManagementScreenState extends State<PricingManagementScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _pricingData = [];
  bool _isLoading = true;
  int _page = 1;
  int _limit = 10;
  int _totalPages = 1;

  // Filter parameters
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  bool _isFilterMode = false;

  @override
  void initState() {
    super.initState();
    _loadPricingData();
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _loadPricingData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getAllFlightPricing(page: _page, limit: _limit);

      if (response['success']) {
        final List pricingData = response['data'];

        setState(() {
          _pricingData = pricingData.cast<Map<String, dynamic>>();
          _totalPages = response['pagination']['totalPages'] ?? 1;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load pricing data');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading pricing data: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _filterPricingData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Validate input
      if (_originController.text.isEmpty && _destinationController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter at least one filter criterion'),
            backgroundColor: AppColors.warningColor,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await _apiService.searchFlightPricing(
        origin: _originController.text.isNotEmpty ? _originController.text : null,
        destination: _destinationController.text.isNotEmpty ? _destinationController.text : null,
      );

      if (response['success']) {
        final List pricingData = response['data'];

        setState(() {
          _pricingData = pricingData.cast<Map<String, dynamic>>();
          _isLoading = false;
          _isFilterMode = true;
        });
      } else {
        throw Exception('No pricing data found for the specified criteria');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search error: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  void _resetFilter() {
    setState(() {
      _originController.clear();
      _destinationController.clear();
      _isFilterMode = false;
      _page = 1;
    });
    _loadPricingData();
  }


  Future<void> _showPricingDialog({Map<String, dynamic>? pricingItem}) async {
    final bool isEditing = pricingItem != null;

    // Safely convert values with proper type handling
    double safeGetDouble(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    final TextEditingController routeController = TextEditingController(
      text: isEditing ? '${pricingItem['origin']} → ${pricingItem['destination']}' : '',
    );

    // Safely handle base price
    final double basePrice = isEditing ? safeGetDouble(pricingItem['base_price'], 0.0) : 0.0;
    final TextEditingController basePriceController = TextEditingController(
      text: isEditing ? basePrice.toString() : '',
    );

    // Safely handle multipliers
    final TextEditingController economyMultiplierController = TextEditingController(
      text: isEditing ? safeGetDouble(pricingItem['economy_multiplier'], 1.0).toString() : '1.0',
    );

    final TextEditingController businessMultiplierController = TextEditingController(
      text: isEditing ? safeGetDouble(pricingItem['business_multiplier'], 2.5).toString() : '2.5',
    );

    final TextEditingController firstMultiplierController = TextEditingController(
      text: isEditing ? safeGetDouble(pricingItem['first_multiplier'], 4.0).toString() : '4.0',
    );

    final TextEditingController womanOnlyMultiplierController = TextEditingController(
      text: isEditing ? safeGetDouble(pricingItem['woman_only_multiplier'], 1.2).toString() : '1.2',
    );

    // For display purposes (sample pricing)
    double displayBasePrice = isEditing ? basePrice : 100.0;
    // For live updates of prices
    double economyPrice = 0.0;
    double businessPrice = 0.0;
    double firstClassPrice = 0.0;
    double womanOnlyPrice = 0.0;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Helper function to update all prices when any value changes
            void updateAllPrices() {
              final double base = double.tryParse(basePriceController.text) ?? 100.0;
              final double economy = double.tryParse(economyMultiplierController.text) ?? 1.0;
              final double business = double.tryParse(businessMultiplierController.text) ?? 2.5;
              final double firstClass = double.tryParse(firstMultiplierController.text) ?? 4.0;
              final double womanOnly = double.tryParse(womanOnlyMultiplierController.text) ?? 1.2;

              setState(() {
                displayBasePrice = base;
                economyPrice = base * economy;
                businessPrice = base * business;
                firstClassPrice = base * firstClass;
                womanOnlyPrice = base * womanOnly;
              });
            }

            // Initialize prices on first load
            if (economyPrice == 0.0) {
              updateAllPrices();
            }

            return AlertDialog(
              title: Text(isEditing ? 'Edit Pricing for Route' : 'Add New Route Pricing'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Route Information
                    if (isEditing) ...[
                      TextField(
                        controller: routeController,
                        decoration: const InputDecoration(
                          labelText: 'Route',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _originController,
                              decoration: const InputDecoration(
                                labelText: 'Origin',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _destinationController,
                              decoration: const InputDecoration(
                                labelText: 'Destination',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Base Price
                    TextField(
                      controller: basePriceController,
                      decoration: const InputDecoration(
                        labelText: 'Base Price',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => updateAllPrices(),
                    ),
                    const SizedBox(height: 16),

                    // Multipliers section header
                    const Text(
                      'Class Multipliers',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Economy Multiplier
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: economyMultiplierController,
                            decoration: const InputDecoration(
                              labelText: 'Economy Multiplier',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.airline_seat_recline_normal),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => updateAllPrices(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '\$${economyPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Business Multiplier
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: businessMultiplierController,
                            decoration: const InputDecoration(
                              labelText: 'Business Multiplier',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.business),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => updateAllPrices(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '\$${businessPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // First Class Multiplier
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: firstMultiplierController,
                            decoration: const InputDecoration(
                              labelText: 'First Class Multiplier',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.airline_seat_flat),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => updateAllPrices(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '\$${firstClassPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Woman Only Multiplier
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: womanOnlyMultiplierController,
                            decoration: const InputDecoration(
                              labelText: 'Woman Only Multiplier',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.woman),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => updateAllPrices(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '\$${womanOnlyPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    // Validate inputs
                    if (basePriceController.text.isEmpty ||
                        economyMultiplierController.text.isEmpty ||
                        businessMultiplierController.text.isEmpty ||
                        firstMultiplierController.text.isEmpty ||
                        womanOnlyMultiplierController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all required fields'),
                          backgroundColor: AppColors.warningColor,
                        ),
                      );
                      return;
                    }

                    // Validate base price
                    final basePrice = double.tryParse(basePriceController.text);
                    if (basePrice == null || basePrice <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Base price must be a positive number'),
                          backgroundColor: AppColors.warningColor,
                        ),
                      );
                      return;
                    }

                    // Validate multipliers
                    final economyMultiplier = double.tryParse(economyMultiplierController.text);
                    final businessMultiplier = double.tryParse(businessMultiplierController.text);
                    final firstMultiplier = double.tryParse(firstMultiplierController.text);
                    final womanOnlyMultiplier = double.tryParse(womanOnlyMultiplierController.text);

                    if (economyMultiplier == null || businessMultiplier == null ||
                        firstMultiplier == null || womanOnlyMultiplier == null ||
                        economyMultiplier <= 0 || businessMultiplier <= 0 ||
                        firstMultiplier <= 0 || womanOnlyMultiplier <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All multipliers must be positive numbers'),
                          backgroundColor: AppColors.warningColor,
                        ),
                      );
                      return;
                    }

                    try {
                      // Prepare pricing data
                      final Map<String, dynamic> pricingData = {
                        'base_price': basePrice,
                        'economy_multiplier': economyMultiplier,
                        'business_multiplier': businessMultiplier,
                        'first_multiplier': firstMultiplier,
                        'woman_only_multiplier': womanOnlyMultiplier,
                      };

                      Navigator.of(context).pop();
                      EasyLoading.show(status: isEditing ? 'Updating pricing...' : 'Creating pricing...');

                      if (isEditing) {
                        await _apiService.updateFlightPricing(
                            pricingItem!['pricing_id'],
                            pricingData
                        );
                      } else {
                        // Add route information for new pricing
                        pricingData['origin'] = _originController.text;
                        pricingData['destination'] = _destinationController.text;
                        await _apiService.createFlightPricing(pricingData);
                      }

                      EasyLoading.dismiss();
                      _loadPricingData();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEditing ? 'Pricing updated successfully' : 'Pricing created successfully'),
                          backgroundColor: AppColors.successColor,
                        ),
                      );
                    } catch (e) {
                      EasyLoading.dismiss();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: AppColors.errorColor,
                        ),
                      );
                    }
                  },
                  child: Text(isEditing ? 'Update' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deletePricing(Map<String, dynamic> pricingItem) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: AppColors.errorColor),
              SizedBox(width: 8),
              Text('Confirm Delete'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete pricing for route "${pricingItem['origin']} → ${pricingItem['destination']}"?\n\n'
                'This will reset all tickets on this route to use default pricing.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      try {
        EasyLoading.show(status: 'Deleting pricing...');
        await _apiService.deleteFlightPricing(pricingItem['pricing_id']);
        EasyLoading.dismiss();

        _loadPricingData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pricing deleted successfully'),
            backgroundColor: AppColors.successColor,
          ),
        );
      } catch (e) {
        EasyLoading.dismiss();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting pricing: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Panel
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter Pricing by Route',
                      style: AppTextStyles.title,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _originController,
                            decoration: const InputDecoration(
                              labelText: 'Origin',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _destinationController,
                            decoration: const InputDecoration(
                              labelText: 'Destination',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _filterPricingData,
                          icon: const Icon(Icons.search),
                          label: const Text('Filter'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_isFilterMode)
                          OutlinedButton.icon(
                            onPressed: _resetFilter,
                            icon: const Icon(Icons.clear),
                            label: const Text('Reset'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Pricing Table
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Flight Pricing',
                            style: AppTextStyles.title,
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showPricingDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add New Pricing'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _pricingData.isEmpty
                            ? const Center(child: Text('No pricing data found'))
                            : DataTable2(
                          columns: const [
                            DataColumn2(
                              label: Text('ID'),
                              size: ColumnSize.S,
                            ),
                            DataColumn2(
                              label: Text('Route'),
                              size: ColumnSize.L,
                            ),
                            DataColumn2(
                              label: Text('Base Price'),
                              size: ColumnSize.M,
                              numeric: true,
                            ),
                            DataColumn2(
                              label: Text('Economy'),
                              size: ColumnSize.S,
                              numeric: true,
                            ),
                            DataColumn2(
                              label: Text('Business'),
                              size: ColumnSize.S,
                              numeric: true,
                            ),
                            DataColumn2(
                              label: Text('First Class'),
                              size: ColumnSize.S,
                              numeric: true,
                            ),
                            DataColumn2(
                              label: Text('Woman Only'),
                              size: ColumnSize.S,
                              numeric: true,
                            ),
                            DataColumn2(
                              label: Text('Actions'),
                              size: ColumnSize.M,
                            ),
                          ],
                          rows: _pricingData.map((pricing) {
                            // Add proper type conversion for all numeric values
                            final basePrice = pricing['base_price'] is int
                                ? (pricing['base_price'] as int).toDouble()
                                : pricing['base_price'] is String
                                ? double.tryParse(pricing['base_price']) ?? 0.0
                                : pricing['base_price'] as double;

                            final economyMultiplier = pricing['economy_multiplier'] is int
                                ? (pricing['economy_multiplier'] as int).toDouble()
                                : pricing['economy_multiplier'] is String
                                ? double.tryParse(pricing['economy_multiplier']) ?? 1.0
                                : pricing['economy_multiplier'] as double? ?? 1.0;

                            final businessMultiplier = pricing['business_multiplier'] is int
                                ? (pricing['business_multiplier'] as int).toDouble()
                                : pricing['business_multiplier'] is String
                                ? double.tryParse(pricing['business_multiplier']) ?? 2.5
                                : pricing['business_multiplier'] as double? ?? 2.5;

                            final firstMultiplier = pricing['first_multiplier'] is int
                                ? (pricing['first_multiplier'] as int).toDouble()
                                : pricing['first_multiplier'] is String
                                ? double.tryParse(pricing['first_multiplier']) ?? 4.0
                                : pricing['first_multiplier'] as double? ?? 4.0;

                            final womanOnlyMultiplier = pricing['woman_only_multiplier'] is int
                                ? (pricing['woman_only_multiplier'] as int).toDouble()
                                : pricing['woman_only_multiplier'] is String
                                ? double.tryParse(pricing['woman_only_multiplier']) ?? 1.2
                                : pricing['woman_only_multiplier'] as double? ?? 1.2;

                            return DataRow(
                              cells: [
                                DataCell(Text('#${pricing['pricing_id']}')),
                                DataCell(Text('${pricing['origin']} → ${pricing['destination']}')),
                                DataCell(Text('\$${basePrice.toStringAsFixed(2)}')),
                                DataCell(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('$economyMultiplier×'),
                                      Text('\$${(basePrice * economyMultiplier).toStringAsFixed(2)}'),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('$businessMultiplier×'),
                                      Text('\$${(basePrice * businessMultiplier).toStringAsFixed(2)}'),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('$firstMultiplier×'),
                                      Text('\$${(basePrice * firstMultiplier).toStringAsFixed(2)}'),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('$womanOnlyMultiplier×'),
                                      Text('\$${(basePrice * womanOnlyMultiplier).toStringAsFixed(2)}'),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: AppColors.infoColor),
                                        tooltip: 'Edit Pricing',
                                        onPressed: () => _showPricingDialog(pricingItem: pricing),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: AppColors.errorColor),
                                        tooltip: 'Delete Pricing',
                                        onPressed: () => _deletePricing(pricing),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),

                      // Pagination
                      if (!_isFilterMode && !_isLoading && _pricingData.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('Page $_page of $_totalPages'),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: _page > 1
                                    ? () {
                                  setState(() {
                                    _page--;
                                  });
                                  _loadPricingData();
                                }
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: _page < _totalPages
                                    ? () {
                                  setState(() {
                                    _page++;
                                  });
                                  _loadPricingData();
                                }
                                    : null,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}