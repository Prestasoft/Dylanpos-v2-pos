import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/model/customer_model.dart';
import 'package:salespro_admin/model/frame_product_model.dart';
import 'package:salespro_admin/model/photo_service_model.dart';
import 'package:salespro_admin/Repository/photo_products_services_repository.dart';
import 'package:salespro_admin/Provider/profile_provider.dart';

// Estado de la factura actual
class PhotoInvoiceState {
  final CustomerModel? selectedCustomer;
  final List<FrameProductModel> products;
  final List<PhotoServiceModel> services;
  final double discountAmount;
  final double taxRate;
  final String notes;
  final String paymentMethod;
  final String? selectedBank;
  final double paidAmount;
  final bool isLoading;
  final String? error;

  PhotoInvoiceState({
    this.selectedCustomer,
    this.products = const [],
    this.services = const [],
    this.discountAmount = 0,
    this.taxRate = 0,
    this.notes = '',
    this.paymentMethod = 'Cash',
    this.selectedBank,
    this.paidAmount = 0,
    this.isLoading = false,
    this.error,
  });

  double get productSubtotal => products.fold(0, (sum, item) => sum + item.subtotal);
  double get serviceSubtotal => services.fold(0, (sum, item) => sum + item.subtotal);
  double get subtotal => productSubtotal + serviceSubtotal;
  double get taxAmount => (subtotal - discountAmount) * (taxRate / 100);
  double get totalAmount => subtotal - discountAmount + taxAmount;
  double get dueAmount => totalAmount - paidAmount;

  PhotoInvoiceState copyWith({
    CustomerModel? selectedCustomer,
    List<FrameProductModel>? products,
    List<PhotoServiceModel>? services,
    double? discountAmount,
    double? taxRate,
    String? notes,
    String? paymentMethod,
    String? selectedBank,
    double? paidAmount,
    bool? isLoading,
    String? error,
  }) {
    return PhotoInvoiceState(
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
      products: products ?? this.products,
      services: services ?? this.services,
      discountAmount: discountAmount ?? this.discountAmount,
      taxRate: taxRate ?? this.taxRate,
      notes: notes ?? this.notes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      selectedBank: selectedBank ?? this.selectedBank,
      paidAmount: paidAmount ?? this.paidAmount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier para manejar el estado de la factura
class PhotoInvoiceNotifier extends StateNotifier<PhotoInvoiceState> {
  PhotoInvoiceNotifier() : super(PhotoInvoiceState());

  void setCustomer(CustomerModel customer) {
    state = state.copyWith(selectedCustomer: customer);
  }

  void addProduct(FrameProductModel product) {
    final existingIndex = state.products.indexWhere((p) => p.productId == product.productId);
    
    if (existingIndex != -1) {
      final updatedProducts = [...state.products];
      updatedProducts[existingIndex] = FrameProductModel(
        productId: product.productId,
        productName: product.productName,
        productType: product.productType,
        productPrice: product.productPrice,
        quantity: updatedProducts[existingIndex].quantity + product.quantity,
        size: product.size,
        material: product.material,
        color: product.color,
        discount: product.discount,
      );
      state = state.copyWith(products: updatedProducts);
    } else {
      state = state.copyWith(products: [...state.products, product]);
    }
  }

  void removeProduct(int index) {
    final updatedProducts = [...state.products];
    updatedProducts.removeAt(index);
    state = state.copyWith(products: updatedProducts);
  }

  void updateProductQuantity(int index, int quantity) {
    if (quantity <= 0) {
      removeProduct(index);
      return;
    }
    
    final updatedProducts = [...state.products];
    final product = updatedProducts[index];
    updatedProducts[index] = FrameProductModel(
      productId: product.productId,
      productName: product.productName,
      productType: product.productType,
      productPrice: product.productPrice,
      quantity: quantity,
      size: product.size,
      material: product.material,
      color: product.color,
      discount: product.discount,
    );
    state = state.copyWith(products: updatedProducts);
  }

  void addService(PhotoServiceModel service) {
    final existingIndex = state.services.indexWhere((s) => s.serviceId == service.serviceId);
    
    if (existingIndex != -1) {
      final updatedServices = [...state.services];
      updatedServices[existingIndex] = PhotoServiceModel(
        serviceId: service.serviceId,
        serviceName: service.serviceName,
        serviceType: service.serviceType,
        servicePrice: service.servicePrice,
        quantity: updatedServices[existingIndex].quantity + service.quantity,
        size: service.size,
        description: service.description,
        discount: service.discount,
      );
      state = state.copyWith(services: updatedServices);
    } else {
      state = state.copyWith(services: [...state.services, service]);
    }
  }

  void removeService(int index) {
    final updatedServices = [...state.services];
    updatedServices.removeAt(index);
    state = state.copyWith(services: updatedServices);
  }

  void updateServiceQuantity(int index, int quantity) {
    if (quantity <= 0) {
      removeService(index);
      return;
    }
    
    final updatedServices = [...state.services];
    final service = updatedServices[index];
    updatedServices[index] = PhotoServiceModel(
      serviceId: service.serviceId,
      serviceName: service.serviceName,
      serviceType: service.serviceType,
      servicePrice: service.servicePrice,
      quantity: quantity,
      size: service.size,
      description: service.description,
      discount: service.discount,
    );
    state = state.copyWith(services: updatedServices);
  }

  void setDiscountAmount(double amount) {
    state = state.copyWith(discountAmount: amount);
  }

  void setTaxRate(double rate) {
    state = state.copyWith(taxRate: rate);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method, selectedBank: null);
  }
  
  void setSelectedBank(String? bank) {
    state = state.copyWith(selectedBank: bank);
  }

  void setPaidAmount(double amount) {
    state = state.copyWith(paidAmount: amount);
  }

  void clearInvoice() {
    state = PhotoInvoiceState();
  }

  Future<String> generateInvoiceNumber() async {
    // Generar número de factura único basado en timestamp
    final now = DateTime.now();
    return 'PHOTO-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';
  }
}

// Provider para el notifier
final photoInvoiceProvider = StateNotifierProvider<PhotoInvoiceNotifier, PhotoInvoiceState>((ref) {
  return PhotoInvoiceNotifier();
});

// Listas de productos y servicios predefinidos (para migración inicial)
final availableFrameProductsProvider = Provider<List<FrameProductModel>>((ref) {
  return [
    FrameProductModel(
      productId: 'frame001',
      productName: 'Marco de Madera Clásico',
      productType: 'marco',
      productPrice: 25.00,
      size: '8x10',
      material: 'madera',
      color: 'Marrón',
    ),
    FrameProductModel(
      productId: 'frame002',
      productName: 'Marco Metálico Moderno',
      productType: 'marco',
      productPrice: 35.00,
      size: '11x14',
      material: 'metal',
      color: 'Plateado',
    ),
    FrameProductModel(
      productId: 'frame003',
      productName: 'Marco Vintage',
      productType: 'marco',
      productPrice: 45.00,
      size: '16x20',
      material: 'madera',
      color: 'Blanco Antiguo',
    ),
    FrameProductModel(
      productId: 'album001',
      productName: 'Álbum de Fotos Premium',
      productType: 'album',
      productPrice: 60.00,
      size: '12x12',
      material: 'cuero',
      color: 'Negro',
    ),
    FrameProductModel(
      productId: 'canvas001',
      productName: 'Lienzo Canvas',
      productType: 'lienzo',
      productPrice: 80.00,
      size: '20x24',
      material: 'tela',
      color: 'Natural',
    ),
  ];
});

final availablePhotoServicesProvider = Provider<List<PhotoServiceModel>>((ref) {
  return [
    PhotoServiceModel(
      serviceId: 'print001',
      serviceName: 'Impresión Estándar',
      serviceType: 'impresion',
      servicePrice: 0.50,
      size: '4x6',
    ),
    PhotoServiceModel(
      serviceId: 'print002',
      serviceName: 'Impresión Grande',
      serviceType: 'impresion',
      servicePrice: 2.00,
      size: '8x10',
    ),
    PhotoServiceModel(
      serviceId: 'print003',
      serviceName: 'Impresión Extra Grande',
      serviceType: 'impresion',
      servicePrice: 5.00,
      size: '11x14',
    ),
    PhotoServiceModel(
      serviceId: 'reveal001',
      serviceName: 'Revelado de Rollo 35mm',
      serviceType: 'revelado',
      servicePrice: 15.00,
      description: 'Incluye digitalización',
    ),
    PhotoServiceModel(
      serviceId: 'digital001',
      serviceName: 'Digitalización de Fotos',
      serviceType: 'digitalizacion',
      servicePrice: 1.00,
      description: 'Por foto',
    ),
    PhotoServiceModel(
      serviceId: 'restore001',
      serviceName: 'Restauración Digital',
      serviceType: 'restauracion',
      servicePrice: 25.00,
      description: 'Restauración de fotos antiguas',
    ),
  ];
});

// Provider para obtener productos desde Firebase
final photoProductsStreamProvider = StreamProvider<List<FrameProductModel>>((ref) async* {
  try {
    final personalInfo = await ref.watch(profileDetailsProvider.future);
    if (personalInfo.phoneNumber.isEmpty) {
      throw Exception('Usuario no autenticado');
    }
    
    final repository = PhotoProductsServicesRepository(userId: personalInfo.phoneNumber);
    yield* repository.getProducts();
  } catch (e) {
    // Error obteniendo productos
    yield [];
  }
});

// Provider para obtener servicios desde Firebase
final photoServicesStreamProvider = StreamProvider<List<PhotoServiceModel>>((ref) async* {
  try {
    final personalInfo = await ref.watch(profileDetailsProvider.future);
    if (personalInfo.phoneNumber.isEmpty) {
      throw Exception('Usuario no autenticado');
    }
    
    final repository = PhotoProductsServicesRepository(userId: personalInfo.phoneNumber);
    yield* repository.getServices();
  } catch (e) {
    // Error obteniendo servicios
    yield [];
  }
});