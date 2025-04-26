import 'dart:html' as html;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class InvoiceRedirectPage extends StatefulWidget {
  const InvoiceRedirectPage({super.key});

  @override
  _InvoiceRedirectPageState createState() => _InvoiceRedirectPageState();
}

class _InvoiceRedirectPageState extends State<InvoiceRedirectPage> {
  @override
  void initState() {
    super.initState();
    _redirectToInvoice();
  }

  Future<void> _redirectToInvoice() async {
    // Get the current URL
    Uri uri = Uri.base;

    // Check if the URL matches the /invoices/invoiceNumber pattern
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'invoices') {
      String invoiceNumber = uri.pathSegments[3];
      String userId = uri.pathSegments[1];
      String type = uri.pathSegments[2];
      try {
        // Generate the Firebase Storage path based on the invoice number
        String path = '$userId/$type/invoice-$invoiceNumber.pdf';

        // Get the download URL from Firebase Storage
        FirebaseStorage storage = FirebaseStorage.instance;
        String downloadUrl = await storage.ref(path).getDownloadURL();

        // Redirect the user to the download URL
        html.window.location.href = downloadUrl;
      } catch (e) {
        print('Error fetching download link: $e');
        // Optionally, redirect to an error page or show an alert
      }
    } else {
      // If the URL is invalid, you could redirect to a 404 page or home
      html.window.location.href = '/404';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Optionally, return a loader or empty container while redirecting
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
