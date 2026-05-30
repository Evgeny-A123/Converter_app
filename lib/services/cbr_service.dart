import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/currency.dart'; 

class CbrService {
  Future<List<CurrencyRate>> fetchAllRates() async {
    try {
      final response = await http.get(Uri.parse('https://www.cbr.ru/scripts/XML_daily.asp'));
      
      if (response.statusCode != 200) {
        throw Exception('Ошибка HTTP: ${response.statusCode}');
      }
      
      final document = XmlDocument.parse(response.body);
      final elements = document.findAllElements('Valute');
      
      List<CurrencyRate> rates = [];
      
      for (var element in elements) {
        try {
          String code = element.findElements('CharCode').first.text;
          String name = element.findElements('Name').first.text;
          int nominal = int.parse(element.findElements('Nominal').first.text);
          String valueStr = element.findElements('Value').first.text;
          double rate = double.parse(valueStr.replaceAll(',', '.'));
          
          rates.add(CurrencyRate(
            code: code,
            name: name,
            rate: rate,
            nominal: nominal,
          ));
        } catch (e) {
          print('Ошибка парсинга валюты: $e');
        }
      }
      
      return rates;
    } catch (e) {
      print('Ошибка загрузки: $e');
      throw Exception('Не удалось загрузить курсы');
    }
  }
  
  Future<double> convert({
    required String fromCurrency,
    required String toCurrency,
    required double amount,
  }) async {
    if (fromCurrency == toCurrency) return amount;
    
    final rates = await fetchAllRates();
    
    double fromRate = 1;
    int fromNominal = 1;
    
    for (var rate in rates) {
      if (rate.code == fromCurrency) {
        fromRate = rate.rate;
        fromNominal = rate.nominal;
        break;
      }
    }
    
    double toRate = 1;
    int toNominal = 1;
    
    for (var rate in rates) {
      if (rate.code == toCurrency) {
        toRate = rate.rate;
        toNominal = rate.nominal;
        break;
      }
    }
    
    if (fromCurrency == 'RUB') {
      fromRate = 1;
      fromNominal = 1;
    }
    
    if (toCurrency == 'RUB') {
      toRate = 1;
      toNominal = 1;
    }
    
    double rubAmount = amount * (fromRate / fromNominal);
    double result = rubAmount / (toRate / toNominal);
    
    return result;
  }
  
  Future<DateTime> getRateDate() async {
    try {
      final response = await http.get(Uri.parse('https://www.cbr.ru/scripts/XML_daily.asp'));
      final document = XmlDocument.parse(response.body);
      String dateStr = document.rootElement.getAttribute('Date') ?? '';
      
      List<String> parts = dateStr.split('.');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (e) {
      print('Ошибка получения даты: $e');
    }
    
    return DateTime.now();
  }
}
