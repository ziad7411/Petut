import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petut/screens/payment_method_screen.dart';
import 'package:petut/screens/select_location_screen.dart';
import 'package:petut/widgets/custom_button.dart';
import 'package:petut/widgets/custom_text_field.dart';

enum DeliveryMethod { standard, express, postal }

class DeliveryScreen extends StatefulWidget {
  final double subtotal;

  const DeliveryScreen({super.key, required this.subtotal});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _addressController = TextEditingController();

  String? governorate;
  String? city;
  String? street;

  DeliveryMethod? selectedMethod;
  DateTime? selectedDateTime;

  double deliveryTax = 0.0;

  double get total => widget.subtotal + deliveryTax;

  void _calculateDeliveryFee() {
    setState(() {
      switch (selectedMethod) {
        case DeliveryMethod.standard:
          deliveryTax = 0;
          break;
        case DeliveryMethod.express:
          deliveryTax = 50;
          break;
        case DeliveryMethod.postal:
          deliveryTax = 20;
          break;
        default:
          deliveryTax = 0;
      }
    });
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDate:
          selectedDateTime ?? DateTime.now().add(const Duration(days: 1)),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDateTime ?? DateTime.now()),
    );

    if (pickedTime == null) return;

    setState(() {
      selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    if (governorate == null || city == null || street == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select full address details')),
      );
      return;
    }

    if (selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery method')),
      );
      return;
    }

    if (selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select delivery date and time')),
      );
      return;
    }

    final fullAddress =
        "$governorate $city $street ${_addressController.text.trim()}";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PaymentMethodScreen(
              name: _nameController.text.trim(),
              phone: _phoneController.text.trim(),
              address: fullAddress,
              governorate: governorate!,
              city: city!,
              street: street!,
              subtotal: widget.subtotal,
              deliveryFee: deliveryTax,
              total: total,
              deliveryTime: selectedDateTime!,
              postalCode: _postalCodeController.text.trim(),
              deliveryMethod: selectedMethod!,
            ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _postalCodeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text("Delivery Information", style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),

              CustomTextField(
                hintText: 'Full Name',
                controller: _nameController,
                validator:
                    (v) =>
                        v == null || v.trim().isEmpty
                            ? 'Enter your name'
                            : null,
              ),
              CustomTextField(
                hintText: 'Phone Number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator:
                    (v) =>
                        v == null || v.length < 8
                            ? 'Enter valid phone number'
                            : null,
              ),
              CustomTextField(
                hintText: 'Postal Code',
                controller: _postalCodeController,
                keyboardType: TextInputType.number,
                validator:
                    (v) => v == null || v.isEmpty ? 'Enter postal code' : null,
              ),
              const SizedBox(height: 10),

              // Location Picker
              InkWell(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SelectLocationScreen(),
                    ),
                  );

                  if (result != null && result is Map<String, dynamic>) {
                    if (result['governorate'] != null &&
                        result['city'] != null &&
                        result['street'] != null) {
                      setState(() {
                        governorate = result['governorate'];
                        city = result['city'];
                        street = result['street'];
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Address info incomplete'),
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Address not selected')),
                    );
                  }
                },

                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.surface,
                  ),
                  child: Text(
                    governorate != null
                        ? "$governorate - $city - $street"
                        : "Select Address from Map",
                    style: TextStyle(
                      color:
                          governorate != null
                              ? theme.textTheme.bodyLarge?.color
                              : theme.hintColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              CustomTextField(
                hintText: 'Street Details / House No.',
                controller: _addressController,
                validator:
                    (v) =>
                        v == null || v.isEmpty
                            ? 'Enter additional street info'
                            : null,
              ),

              const SizedBox(height: 20),

              Text("Delivery Method", style: theme.textTheme.titleMedium),
              ...DeliveryMethod.values.map((method) {
                final label =
                    method == DeliveryMethod.standard
                        ? "Standard (5–7 days) - Free"
                        : method == DeliveryMethod.express
                        ? "Express (1–2 days) - 50 EGP"
                        : "Postal Office - 20 EGP";

                return RadioListTile<DeliveryMethod>(
                  title: Text(label),
                  value: method,
                  groupValue: selectedMethod,
                  onChanged: (val) {
                    setState(() {
                      selectedMethod = val;
                      _calculateDeliveryFee();
                    });
                  },
                );
              }),

              const SizedBox(height: 20),

              Text(
                "Preferred Delivery Time",
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDateTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.surface,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedDateTime != null
                            ? DateFormat(
                              'yyyy-MM-dd hh:mm a',
                            ).format(selectedDateTime!)
                            : "Select delivery date & time",
                        style: TextStyle(
                          color:
                              selectedDateTime != null
                                  ? theme.textTheme.bodyLarge?.color
                                  : theme.hintColor,
                        ),
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text("Subtotal: ${widget.subtotal.toStringAsFixed(2)} EGP"),
              Text("Delivery: ${deliveryTax.toStringAsFixed(2)} EGP"),
              Text(
                "Total: ${total.toStringAsFixed(2)} EGP",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),
              CustomButton(text: "Confirm Order", onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
