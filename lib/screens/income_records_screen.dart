import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/income_record.dart';
import '../services/storage_service.dart';

class IncomeRecordsScreen extends StatefulWidget {
  final StorageService storageService;
  final Function(List<IncomeRecord>) onRecordsUpdated;

  const IncomeRecordsScreen({
    Key? key,
    required this.storageService,
    required this.onRecordsUpdated,
  }) : super(key: key);

  @override
  _IncomeRecordsScreenState createState() => _IncomeRecordsScreenState();
}

class _IncomeRecordsScreenState extends State<IncomeRecordsScreen> {
  List<IncomeRecord> incomeRecords = [];
  final _formKey = GlobalKey<FormState>();
  final cropNameController = TextEditingController();
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  String selectedSection = 'Section A';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIncomeRecords();
  }

  Future<void> _loadIncomeRecords() async {
    setState(() {
      isLoading = true;
    });

    final records = await widget.storageService.loadIncomeRecords();

    setState(() {
      incomeRecords = records;
      isLoading = false;
    });
  }

  double parseAmountString(String amount) {
    return double.parse(amount.replaceAll(',', ''));
  }

  Future<void> _addIncomeRecord() async {
    if (_formKey.currentState!.validate()) {
      final newRecord = IncomeRecord(
        cropName: cropNameController.text,
        section: selectedSection,
        amount: parseAmountString(amountController.text),
        date: DateTime.now(),
        description: descriptionController.text.isEmpty ? null : descriptionController.text,
      );

      setState(() {
        incomeRecords.add(newRecord);
      });

      await widget.storageService.saveIncomeRecords(incomeRecords);
      widget.onRecordsUpdated(incomeRecords);

      cropNameController.clear();
      amountController.clear();
      descriptionController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Income record added successfully')),
      );
    }
  }

  void _removeIncomeRecord(int index) async {
    setState(() {
      incomeRecords.removeAt(index);
    });

    await widget.storageService.saveIncomeRecords(incomeRecords);
    widget.onRecordsUpdated(incomeRecords);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Income record removed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Income Records'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: cropNameController,
                    decoration: InputDecoration(labelText: 'Crop Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a crop name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedSection,
                    decoration: InputDecoration(labelText: 'Section'),
                    items: ['Section A', 'Section B', 'Section C']
                        .map((section) => DropdownMenuItem(
                      value: section,
                      child: Text(section),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSection = value!;
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount (₱)',
                      hintText: 'Example: 1,000 or 1000',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^[0-9,]*$')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      try {
                        parseAmountString(value);
                        return null;
                      } catch (e) {
                        return 'Please enter a valid number';
                      }
                    },
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Enter additional details',
                    ),
                    maxLines: 2,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addIncomeRecord,
                    child: Text('Add Income Record'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: incomeRecords.isEmpty
                  ? Center(child: Text('No income records added yet'))
                  : ListView.builder(
                itemCount: incomeRecords.length,
                itemBuilder: (context, index) {
                  final record = incomeRecords[index];
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        record.cropName,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${record.section}'),
                          if (record.description != null)
                            Text(
                              record.description!,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₱${record.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                              Text(
                                '${record.date.day}/${record.date.month}/${record.date.year}',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          SizedBox(width: 12),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red[600]),
                            tooltip: 'Remove',
                            onPressed: () => _removeIncomeRecord(index),
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
    );
  }

  @override
  void dispose() {
    cropNameController.dispose();
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
