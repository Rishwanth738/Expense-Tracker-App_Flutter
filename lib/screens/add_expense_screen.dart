import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../widgets/add_category_dialog.dart';
import '../widgets/add_tag_dialog.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? initialExpense;

  const AddExpenseScreen({Key? key, this.initialExpense}) : super(key: key);

  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  late TextEditingController _amountController;
  late TextEditingController _payeeController;
  late TextEditingController _noteController;
  String? _selectedCategoryId;
  String? _selectedTagId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
        text: widget.initialExpense?.amount.toString() ?? '');
    _payeeController =
        TextEditingController(text: widget.initialExpense?.payee ?? '');
    _noteController =
        TextEditingController(text: widget.initialExpense?.note ?? '');
    _selectedDate = widget.initialExpense?.date ?? DateTime.now();
    _selectedCategoryId = widget.initialExpense?.categoryId;
    _selectedTagId = widget.initialExpense?.tag;
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.initialExpense == null ? 'Add Expense' : 'Edit Expense'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildTextField(_amountController, 'Amount',
                TextInputType.numberWithOptions(decimal: true)),
            SizedBox(height: 8),
            buildTextField(_payeeController, 'Payee', TextInputType.text),
            SizedBox(height: 8),
            buildTextField(_noteController, 'Note', TextInputType.text),
            SizedBox(height: 8),
            buildDateField(_selectedDate),
            SizedBox(height: 16),
            buildCategoryDropdown(expenseProvider),
            SizedBox(height: 16),
            buildTagDropdown(expenseProvider),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _saveExpense,
          child: Text('Save Expense', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
  // Helper methods for building the form elements go here (omitted for brevity)

  void _saveExpense() {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill in all required fields!')));
      return;
    }

    final expense = Expense(
      id: widget.initialExpense?.id ??
          DateTime.now().toString(), // Assuming you generate IDs like this
      amount: double.parse(_amountController.text),
      categoryId: _selectedCategoryId!,
      payee: _payeeController.text,
      note: _noteController.text,
      date: _selectedDate,
      tag: _selectedTagId!,
    );

    // Calling the provider to add or update the expense
    Provider.of<ExpenseProvider>(context, listen: false)
        .addOrUpdateExpense(expense);
    Navigator.pop(context);
  }

  // Helper method to build a text field
  Widget buildTextField(
      TextEditingController controller, String label, TextInputType type) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: type,
      style: TextStyle(fontSize: 16),
    );
  }

// Helper method to build the date picker field
  Widget buildDateField(DateTime selectedDate) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: ListTile(
        title: Text(
          "Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}",
          style: TextStyle(color: Colors.grey[800]),
        ),
        trailing: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: selectedDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: Theme.of(context).colorScheme.primary,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null && picked != selectedDate) {
            setState(() {
              _selectedDate = picked;
            });
          }
        },
      ),
    );
  }

// Helper method to build the category dropdown
  Widget buildCategoryDropdown(ExpenseProvider provider) {
    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      onChanged: (newValue) {
        if (newValue == 'New') {
          showDialog(
            context: context,
            builder: (context) => AddCategoryDialog(onAdd: (newCategory) {
              setState(() {
                _selectedCategoryId =
                    newCategory.id; // Automatically select the new category
                provider.addCategory(
                    newCategory); // Add to provider, assuming this method exists
              });
            }),
          );
        } else {
          setState(() => _selectedCategoryId = newValue);
        }
      },
      items: provider.categories.map<DropdownMenuItem<String>>((category) {
        return DropdownMenuItem<String>(
          value: category.id,
          child: Text(category.name),
        );
      }).toList()
        ..add(DropdownMenuItem(
          value: "New",
          child: Text("Add New Category"),
        )),
      decoration: InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
      ),
    );
  }

// Helper method to build the tag dropdown
  Widget buildTagDropdown(ExpenseProvider provider) {
    return DropdownButtonFormField<String>(
      value: _selectedTagId,
      onChanged: (newValue) {
        if (newValue == 'New') {
          showDialog(
            context: context,
            builder: (context) => AddTagDialog(onAdd: (newTag) {
              provider.addTag(newTag); // Assuming you have an `addTag` method.
              setState(
                  () => _selectedTagId = newTag.id); // Update selected tag ID
            }),
          );
        } else {
          setState(() => _selectedTagId = newValue);
        }
      },
      items: provider.tags.map<DropdownMenuItem<String>>((tag) {
        return DropdownMenuItem<String>(
          value: tag.id,
          child: Text(tag.name),
        );
      }).toList()
        ..add(DropdownMenuItem(
          value: "New",
          child: Text("Add New Tag"),
        )),
      decoration: InputDecoration(
        labelText: 'Tag',
        border: OutlineInputBorder(),
      ),
    );
  }
}