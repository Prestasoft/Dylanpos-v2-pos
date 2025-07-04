#!/usr/bin/env dart

import 'dart:io';

/// Script para corregir automáticamente algunos warnings comunes
void main() async {
  print('🔧 Iniciando corrección automática de warnings...');
  
  final directory = Directory('lib');
  final files = await _findDartFiles(directory);
  
  int totalWarningsFixed = 0;
  int filesModified = 0;
  
  for (final file in files) {
    final warningsFixed = await _fixWarningsInFile(file);
    if (warningsFixed > 0) {
      totalWarningsFixed += warningsFixed;
      filesModified++;
      print('✅ ${file.path}: $warningsFixed warnings corregidos');
    }
  }
  
  print('\n🎉 Corrección completada:');
  print('📁 Archivos modificados: $filesModified');
  print('🔧 Total warnings corregidos: $totalWarningsFixed');
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

Future<int> _fixWarningsInFile(File file) async {
  try {
    final content = await file.readAsString();
    String fixedContent = content;
    int warningsFixed = 0;
    
    // 1. Fix unnecessary string interpolations
    final unnecessaryInterpolations = RegExp(r'\$\{([^}]+)\}(?![^}]*\})');
    if (unnecessaryInterpolations.hasMatch(fixedContent)) {
      fixedContent = fixedContent.replaceAllMapped(unnecessaryInterpolations, (match) {
        final inner = match.group(1);
        // Only replace if it's a simple variable (no operations)
        if (inner != null && !inner.contains(' ') && !inner.contains('+') && !inner.contains('.')) {
          warningsFixed++;
          return '\$$inner';
        }
        return match.group(0)!;
      });
    }
    
    // 2. Fix unnecessary use of toList in spreads
    final unnecessaryToList = RegExp(r'\.\.\.([^.]+)\.toList\(\)');
    if (unnecessaryToList.hasMatch(fixedContent)) {
      fixedContent = fixedContent.replaceAllMapped(unnecessaryToList, (match) {
        warningsFixed++;
        return '...${match.group(1)}';
      });
    }
    
    // 3. Add const to constructors where appropriate (simple cases)
    final constConstructor = RegExp(r'(\w+)\(\s*\{([^}]*)\}\s*\);', multiLine: true);
    if (constConstructor.hasMatch(fixedContent)) {
      fixedContent = fixedContent.replaceAllMapped(constConstructor, (match) {
        final constructor = match.group(0)!;
        // Only add const if it doesn't already have it and seems like a simple widget
        if (!constructor.contains('const ') && 
            !constructor.contains('new ') &&
            constructor.contains('child:') || constructor.contains('children:')) {
          warningsFixed++;
          return 'const ${match.group(0)}';
        }
        return match.group(0)!;
      });
    }
    
    // 4. Replace withOpacity with withValues (simple cases)
    final withOpacityPattern = RegExp(r'\.withOpacity\(([^)]+)\)');
    if (withOpacityPattern.hasMatch(fixedContent)) {
      fixedContent = fixedContent.replaceAllMapped(withOpacityPattern, (match) {
        final opacity = match.group(1);
        if (opacity != null && opacity.trim().isNotEmpty) {
          warningsFixed++;
          return '.withValues(alpha: $opacity)';
        }
        return match.group(0)!;
      });
    }
    
    // 5. Fix duplicate imports (simple cases)
    final lines = fixedContent.split('\n');
    final imports = <String>{};
    final cleanedLines = <String>[];
    
    for (final line in lines) {
      if (line.trim().startsWith('import ')) {
        if (imports.contains(line.trim())) {
          warningsFixed++;
          continue; // Skip duplicate import
        }
        imports.add(line.trim());
      }
      cleanedLines.add(line);
    }
    
    if (warningsFixed > 0) {
      fixedContent = cleanedLines.join('\n');
      await file.writeAsString(fixedContent);
    }
    
    return warningsFixed;
  } catch (e) {
    print('❌ Error procesando ${file.path}: $e');
    return 0;
  }
}
