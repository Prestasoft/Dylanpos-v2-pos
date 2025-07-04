// Test para validar la detección de planes PRE-QUINCE FIESTA
// Este archivo es solo para testing manual y puede eliminarse después

void main() {
  print('Testing PRE-QUINCE FIESTA plan detection...\n');
  
  // Lista de nombres de planes para probar
  List<String> testPlanNames = [
    'Plan A PRE-QUINCE Y FIESTA',
    'pre-quince y fiesta básico',
    'PLAN B Pre-Quinceañera y Fiesta',
    'pré-quince y fiesta premium',
    'PRE-QUINCE FIESTA DELUXE',
    'Plan Regular de Quinceañera',
    'NORMAL PACKAGE',
    'Pre Quince & Fiesta Special',
    'PLAN PRE-QUINCE Y FIESTA VIP',
    'otro plan normal'
  ];
  
  for (String planName in testPlanNames) {
    bool isPreQuinceFiesta = _isPreQuinceFiestaPlan(planName);
    print('Plan: "$planName" -> ${isPreQuinceFiesta ? "✅ PRE-QUINCE FIESTA" : "❌ Normal"}');
  }
}

bool _isPreQuinceFiestaPlan(String planName) {
  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^plan\s+[a-z]\s+'), '')
        .trim();
  }
  
  String normalized = _normalize(planName);
  return normalized.contains('pre-quince y fiesta') || 
         normalized.contains('pre-quince fiesta') ||
         normalized.contains('pre quince y fiesta') ||
         normalized.contains('pre quince fiesta') ||
         normalized.contains('quinceanera y fiesta');
}
