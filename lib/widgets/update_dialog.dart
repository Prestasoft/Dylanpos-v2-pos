import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../services/version_check_service.dart';

// Definir colores localmente
const Color kMainColor = Color(0xFF7C4DFF);
const Color kTitleColor = Color(0xFF2B2B2B);
const Color kGreyTextColor = Color(0xFF717171);

class UpdateDialog extends StatelessWidget {
  final VersionInfo versionInfo;
  
  const UpdateDialog({
    super.key,
    required this.versionInfo,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !versionInfo.forceUpdate,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                spreadRadius: 5,
                blurRadius: 20,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono de actualización
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: kMainColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_update,
                    size: 40,
                    color: kMainColor,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Título
                Text(
                  '¡Nueva actualización disponible!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: kTitleColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                
                // Versión
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: kMainColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    'Versión ${versionInfo.version}',
                    style: const TextStyle(
                      color: kMainColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Descripción
                if (versionInfo.description.isNotEmpty) ...[
                  Text(
                    versionInfo.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: kGreyTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                ],
                
                // Fecha de lanzamiento
                Text(
                  'Fecha de lanzamiento: ${versionInfo.releaseDate}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: kGreyTextColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 30),
                
                // Botones
                Row(
                  children: [
                    if (!versionInfo.forceUpdate) ...[
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text(
                            'Más tarde',
                            style: TextStyle(
                              color: kGreyTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleUpdate(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kMainColor,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Actualizar ahora',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (versionInfo.forceUpdate) ...[
                  const SizedBox(height: 15),
                  Text(
                    'Esta actualización es obligatoria para continuar usando la aplicación',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleUpdate(BuildContext context) async {
    try {
      EasyLoading.show(
        status: 'Actualizando...\nLimpiando caché y cerrando sesión',
        dismissOnTap: false,
      );
      
      // Pequeña demora para mostrar el mensaje
      await Future.delayed(const Duration(seconds: 2));
      
      // Realizar actualización
      await VersionCheckService().performUpdate();
      
      EasyLoading.dismiss();
    } catch (e) {
      EasyLoading.showError('Error al actualizar: $e');
    }
  }
}

/// Mostrar diálogo de actualización
Future<void> showUpdateDialog(BuildContext context, VersionInfo versionInfo) async {
  return showDialog(
    context: context,
    barrierDismissible: !versionInfo.forceUpdate,
    builder: (context) => UpdateDialog(versionInfo: versionInfo),
  );
}