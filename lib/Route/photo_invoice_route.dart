import 'package:go_router/go_router.dart';
import 'package:salespro_admin/Screen/Photo%20Invoice/photo_invoice_screen.dart';

final photoInvoiceRoute = GoRoute(
  path: 'photo-invoice',
  pageBuilder: (context, state) => const NoTransitionPage<void>(
    child: PhotoInvoiceScreen(),
  ),
);