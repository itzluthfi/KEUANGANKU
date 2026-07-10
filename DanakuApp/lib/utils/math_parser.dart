import 'package:intl/intl.dart';

/// Evaluates a simple mathematical expression containing numbers, dots, and operators (+, -, x, /).
/// Handles standard operator precedence (multiplication and division before addition and subtraction).
double? evaluateExpression(String expr) {
  // Clean expression: replace 'x' with '*' and remove any spaces
  String cleanExpr = expr.replaceAll('x', '*').replaceAll(' ', '');
  
  // If there are no operators, try parsing directly
  if (!cleanExpr.contains(RegExp(r'[\+\-\*/]'))) {
    return double.tryParse(cleanExpr);
  }
  
  try {
    int pos = -1;
    int ch = -1;
    
    void nextChar() {
      ch = (++pos < cleanExpr.length) ? cleanExpr.codeUnitAt(pos) : -1;
    }
    
    bool eat(int charToEat) {
      while (ch == 32) { // space
        nextChar();
      }
      if (ch == charToEat) {
        nextChar();
        return true;
      }
      return false;
    }
    
    double parseFactor() {
      if (eat(43)) return parseFactor(); // unary plus '+'
      if (eat(45)) return -parseFactor(); // unary minus '-'
      
      int startPos = pos;
      if ((ch >= 48 && ch <= 57) || ch == 46) { // digits or dot '.'
        while ((ch >= 48 && ch <= 57) || ch == 46) {
          nextChar();
        }
        String numStr = cleanExpr.substring(startPos, pos);
        return double.parse(numStr);
      }
      throw Exception("Unexpected character: " + String.fromCharCode(ch));
    }
    
    double parseTerm() {
      double x = parseFactor();
      for (;;) {
        if (eat(42)) {
          x *= parseFactor(); // multiplication '*'
        } else if (eat(47)) {
          double divisor = parseFactor();
          if (divisor == 0) throw Exception("Division by zero");
          x /= divisor; // division '/'
        } else {
          return x;
        }
      }
    }
    
    double parseExpression() {
      double x = parseTerm();
      for (;;) {
        if (eat(43)) {
          x += parseTerm(); // addition '+'
        } else if (eat(45)) {
          x -= parseTerm(); // subtraction '-'
        } else {
          return x;
        }
      }
    }
    
    nextChar();
    double result = parseExpression();
    if (pos < cleanExpr.length) {
      throw Exception("Unexpected remainder: " + cleanExpr.substring(pos));
    }
    return result;
  } catch (e) {
    return null;
  }
}

/// Formats a mathematical expression dynamically for user display.
/// Group numbers with thousands separator (.) and decimal separator (,) for Indonesian locale.
String formatLiveExpression(String expr) {
  if (expr.trim().isEmpty) return "0";
  
  // RegExp matching integer or decimal numbers
  final RegExp numberReg = RegExp(r'\d+\.?\d*');
  
  String formatted = expr.replaceAllMapped(numberReg, (match) {
    String numStr = match.group(0)!;
    List<String> parts = numStr.split('.');
    String integerPart = parts[0];
    
    // Group thousands
    String formattedInt = "";
    int len = integerPart.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        formattedInt += ".";
      }
      formattedInt += integerPart[i];
    }
    
    if (parts.length > 1) {
      return formattedInt + "," + parts[1]; // Use comma for decimals in ID locale
    } else if (numStr.endsWith('.')) {
      return formattedInt + ",";
    }
    return formattedInt;
  });
  
  // Format operator spacing for beauty
  formatted = formatted
      .replaceAll('+', ' + ')
      .replaceAll('-', ' - ')
      .replaceAll('x', ' x ')
      .replaceAll('/', ' / ')
      .replaceAll(RegExp(r'\s+'), ' '); // clean duplicate spaces
  
  return formatted.trim();
}
