class HomeReport {
  String? name;
  String? amount;

  HomeReport(this.name, this.amount);
}

class TopSellReport {
  String? name;
  String? amount;
  String? category;
  String? stock;
  String? productImage;

  TopSellReport(this.name, this.amount, this.category, this.stock, this.productImage);
}

class TopPurchaseReport {
  String? name;
  String? amount;
  String? category;
  String? image;
  String? stock;

  TopPurchaseReport(this.name, this.amount, this.category, this.image, this.stock);
}

class TopCustomer {
  String? name;
  String? amount;
  String? phone;
  String? image;

  TopCustomer(this.name, this.amount, this.phone, this.image);
}
