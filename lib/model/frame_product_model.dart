class FrameProductModel {
  String? productId;
  String productName;
  String productType; // 'marco', 'album', 'lienzo', etc.
  double productPrice;
  int quantity;
  int? stock;
  String? size; // '5x7', '8x10', '11x14', etc.
  String? material; // 'madera', 'metal', 'plástico'
  String? color;
  double? discount;
  
  FrameProductModel({
    this.productId,
    required this.productName,
    required this.productType,
    required this.productPrice,
    this.quantity = 1,
    this.stock,
    this.size,
    this.material,
    this.color,
    this.discount,
  });

  double get subtotal => (productPrice * quantity) - (discount ?? 0);

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'productType': productType,
    'productPrice': productPrice,
    'quantity': quantity,
    'stock': stock,
    'size': size,
    'material': material,
    'color': color,
    'discount': discount,
  };

  factory FrameProductModel.fromJson(Map<String, dynamic> json) => FrameProductModel(
    productId: json['productId'],
    productName: json['productName'],
    productType: json['productType'],
    productPrice: json['productPrice']?.toDouble() ?? 0.0,
    quantity: json['quantity'] ?? 1,
    stock: json['stock'],
    size: json['size'],
    material: json['material'],
    color: json['color'],
    discount: json['discount']?.toDouble(),
  );
  
  Map<String, dynamic> toMap() => toJson();
  
  factory FrameProductModel.fromMap(Map<String, dynamic> map) => FrameProductModel.fromJson(map);
}