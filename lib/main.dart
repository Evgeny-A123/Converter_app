import 'package:flutter/material.dart';
import 'services/cbr_service.dart';
import 'models/currency.dart';

void main() => runApp(CurrencyConverterApp());

class CurrencyConverterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Конвертер валют',
    theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
    home: ConverterScreen(),
    debugShowCheckedModeBanner: false,
  );
}

class ConverterScreen extends StatefulWidget {
  @override
  _ConverterScreenState createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final CbrService _service = CbrService();
  
  String _from = 'USD';
  String _to = 'RUB';
  String _amount = '1';
  String _result = '';
  bool _loading = true;
  String _error = '';
  List<CurrencyRate> _rates = [];
  DateTime? _date;
  
  List<String> get _currencies => _rates.map((e) => e.code).toList();
  
  @override
  void initState() {
    super.initState();
    _load();
  }
  
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _rates = await _service.fetchAllRates();
      _date = await _service.getRateDate();
      _rates.add(CurrencyRate(code: 'RUB', name: 'RUB', rate: 1, nominal: 1));
      _loading = false;
      await _convert();
    } catch (e) {
      _error = e.toString();
      _loading = false;
    }
    setState(() {});
  }
  
  Future<void> _convert() async {
    if (_amount.isEmpty || _rates.isEmpty) return;
    double? amount = double.tryParse(_amount);
    if (amount == null) return;
    try {
      double converted = await _service.convert(fromCurrency: _from, toCurrency: _to, amount: amount);
      setState(() => _result = converted.toStringAsFixed(2));
    } catch (e) {
      setState(() => _result = 'Ошибка');
    }
  }
  
  void _swap() {
    final temp = _from;
    _from = _to;
    _to = temp;
    _convert();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Загрузка...'),
            ],
          ),
        ),
      );
    }
    
    if (_error.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(_error),
              SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: Text('Повторить')),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            if (_date != null)
              Text('Курс на ${_date!.day}.${_date!.month}.${_date!.year}',
                   style: TextStyle(color: Colors.grey)),
            SizedBox(height: 20),
            
            // Поле ввода суммы
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Сумма',
                border: OutlineInputBorder(),
                suffixText: _from,
              ),
              onChanged: (value) {
                _amount = value;
                _convert();
              },
            ),
            SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(child: _buildDropdown(_from, 'Из', (v) => setState(() => _from = v!))),
                IconButton(onPressed: _swap, icon: Icon(Icons.swap_horiz)),
                Expanded(child: _buildDropdown(_to, 'В', (v) => setState(() => _to = v!))),
              ],
            ),
            SizedBox(height: 30),
            
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text('$_amount $_from ='),
                  SizedBox(height: 10),
                  Text(_result, style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                  Text(_to),
                  SizedBox(height: 10),
                  _buildRateInfo(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDropdown(String value, String label, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
      items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: onChanged,
    );
  }
  
  Widget _buildRateInfo() {
    CurrencyRate fromRate = _rates.firstWhere((r) => r.code == _from, orElse: () => CurrencyRate(code: _from, name: '', rate: 0, nominal: 1));
    CurrencyRate toRate = _rates.firstWhere((r) => r.code == _to, orElse: () => CurrencyRate(code: _to, name: '', rate: 0, nominal: 1));
    
    if (fromRate.rate == 0 || toRate.rate == 0) return SizedBox();
    
    double rubPerFrom = fromRate.rate / fromRate.nominal;
    double rubPerTo = toRate.rate / toRate.nominal;
    double cross = rubPerFrom / rubPerTo;
    
    return Text('1 $_from = ${cross.toStringAsFixed(4)} $_to', style: TextStyle(fontSize: 12));
  }
}

