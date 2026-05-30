class CurrencyRate{
  final String code;
  final String name;
  final double rate;
  final int nominal;


  CurrencyRate({
    required this.code,
    required this.name,
    required this.rate,
    required this.nominal,
  });


  double get ratePerUnit => rate / nominal;

  double fromRub(double rubAmount){
    return rubAmount / ratePerUnit;
  }

  double toRub(double currencyAmount){
    return currencyAmount * ratePerUnit;
  }

}