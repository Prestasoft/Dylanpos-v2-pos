import 'dart:io';

void main() {
  final file = File('lib/Screen/Reports/report_screen.dart');
  final content = file.readAsStringSync();
  
  // Buscar secciones vacías problemáticas
  final emptyPatterns = [
    'ResponsiveGridCol(\n                                    ),',
    'child: Padding(\n                                      ),',
    'Container(\n                                        ),',
    'child: Container(\n                                        ),',
  ];
  
  print('🔍 Buscando secciones vacías en report_screen.dart...\n');
  
  for (String pattern in emptyPatterns) {
    if (content.contains(pattern)) {
      print('❌ ENCONTRADO: Sección vacía con patrón:');
      print(pattern);
      print('');
    }
  }
  
  // Buscar ResponsiveGridCol sin child
  final lines = content.split('\n');
  for (int i = 0; i < lines.length - 2; i++) {
    if (lines[i].trim().startsWith('ResponsiveGridCol(') && 
        lines[i+1].trim() == '),') {
      print('❌ ENCONTRADO: ResponsiveGridCol vacío en línea ${i+1}');
      print('${lines[i]}');
      print('${lines[i+1]}');
      print('');
    }
  }
  
  print('✅ Análisis completado.');
}
