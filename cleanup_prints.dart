#!/usr/bin/env dart

import 'dart:io';

/// Script para remover automáticamente todos los prints del código
/// Mantiene solo los prints en archivos de test
void main() async {
  print('🧹 Iniciando limpieza de prints...');
  
  final directory = Directory('.');
  final files = await _findDartFiles(directory);
  
  int totalPrintsRemoved = 0;
  int filesModified = 0;
  
  for (final file in files) {
    // Skip test files and validation scripts
    if (_shouldSkipFile(file.path)) {
      continue;
    }
    
    final printsRemoved = await _cleanPrintsFromFile(file);
    if (printsRemoved > 0) {
      totalPrintsRemoved += printsRemoved;
      filesModified++;
      print('✅ ${file.path}: $printsRemoved prints removidos');
    }
  }
  
  print('\n🎉 Limpieza completada:');
  print('📁 Archivos modificados: $filesModified');
  print('🗑️  Total prints removidos: $totalPrintsRemoved');
}

Future<List<File>> _findDartFiles(Directory dir) async {
  final files = <File>[];
  
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      files.add(entity);
    }
  }
  
  return files;
}

bool _shouldSkipFile(String path) {
  // Skip test files and validation scripts
  return path.contains('/test/') ||
         path.contains('test_') ||
         path.contains('validacion_') ||
         path.contains('verificacion_') ||
         path.contains('cleanup_') ||
         path.contains('prueba_');
}

Future<int> _cleanPrintsFromFile(File file) async {
  try {
    final content = await file.readAsString();
    final lines = content.split('\n');
    final cleanedLines = <String>[];
    int printsRemoved = 0;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();
      
      // Check if this is a print statement
      if (_isPrintStatement(trimmed)) {
        printsRemoved++;
        // Skip this line (remove the print)
        continue;
      }
      
      cleanedLines.add(line);
    }
    
    if (printsRemoved > 0) {
      final cleanedContent = cleanedLines.join('\n');
      await file.writeAsString(cleanedContent);
    }
    
    return printsRemoved;
  } catch (e) {
    print('❌ Error procesando ${file.path}: $e');
    return 0;
  }
}

bool _isPrintStatement(String line) {
  // Remove leading/trailing whitespace and check for print statements
  line = line.trim();
  
  // Common print patterns
  return line.startsWith('print(') ||
         line.startsWith('print ') ||
         (line.contains('print(') && line.endsWith(');')) ||
         (line.contains('print(') && line.endsWith(')'));
}
