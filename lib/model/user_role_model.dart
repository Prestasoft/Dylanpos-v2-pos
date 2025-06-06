class UserRoleModel {
  String? email;
  String? userTitle;
  String? databaseId;
  String? userRoleName;
  List<Permission> permissions;
  bool? saleView;
  bool? saleEdit;
  bool? saleDelete;
  bool? partiesView;
  bool? partiesEdit;
  bool? partiesDelete;
  bool? purchaseView;
  bool? purchaseEdit;
  bool? purchaseDelete;
  bool? productView;
  bool? productEdit;
  bool? productDelete;
  bool? profileEditView;
  bool? profileEditEdit;
  bool? profileEditDelete;
  bool? addExpenseView;
  bool? addExpenseEdit;
  bool? addExpenseDelete;
  bool? lossProfitView;
  bool? lossProfitEdit;
  bool? lossProfitDelete;
  bool? dueListView;
  bool? dueListEdit;
  bool? dueListDelete;
  bool? stockView;
  bool? stockEdit;
  bool? stockDelete;
  bool? reportsView;
  bool? reportsEdit;
  bool? reportsDelete;
  bool? salesListView;
  bool? salesListEdit;
  bool? salesListDelete;
  bool? purchaseListView;
  bool? purchaseListEdit;
  bool? purchaseListDelete;
  bool? hrmView;
  bool? hrmEdit;
  bool? hrmDelete;

  String? userKey;

  UserRoleModel(
      {this.email,
      this.userTitle,
      this.databaseId,
      this.userRoleName,
      required this.permissions,
      this.saleView,
      this.saleEdit,
      this.saleDelete,
      this.partiesView,
      this.partiesEdit,
      this.partiesDelete,
      this.purchaseView,
      this.purchaseEdit,
      this.purchaseDelete,
      this.productView,
      this.productEdit,
      this.productDelete,
      this.profileEditView,
      this.profileEditEdit,
      this.profileEditDelete,
      this.addExpenseView,
      this.addExpenseEdit,
      this.addExpenseDelete,
      this.lossProfitView,
      this.lossProfitEdit,
      this.lossProfitDelete,
      this.dueListView,
      this.dueListEdit,
      this.dueListDelete,
      this.stockView,
      this.stockEdit,
      this.stockDelete,
      this.reportsView,
      this.reportsEdit,
      this.reportsDelete,
      this.salesListView,
      this.salesListEdit,
      this.salesListDelete,
      this.purchaseListView,
      this.purchaseListEdit,
      this.purchaseListDelete,
      this.hrmView,
      this.hrmEdit,
      this.hrmDelete,
      this.userKey});

  /// Buscar permiso por tipo de menú o submenú
  Permission? getPermission(String type) {
    return permissions.firstWhere(
      (p) => p.type == type,
      orElse: () => Permission(type: type),
    );
  }

  /// Métodos helper
  bool canView(String type) => getPermission(type)?.view ?? false;
  bool canEdit(String type) => getPermission(type)?.edit ?? false;
  bool canDelete(String type) => getPermission(type)?.delete ?? false;

  factory UserRoleModel.fromJson(Map<String, dynamic> json) => UserRoleModel(
        email: json["email"] ?? '',
        userTitle: json["userTitle"] ?? '',
        databaseId: json["databaseId"] ?? '',
        userRoleName: json["userRoleName"] ?? '',
        permissions: json["permissions"] == null
            ? []
            : List<Permission>.from(
                json["permissions"].map((x) => Permission.fromJson(x))),
        saleView: json["saleView"] ?? false,
        saleEdit: json["saleEdit"] ?? false,
        saleDelete: json["saleDelete"] ?? false,
        partiesView: json["partiesView"] ?? false,
        partiesEdit: json["partiesEdit"] ?? false,
        partiesDelete: json["partiesDelete"] ?? false,
        purchaseView: json["purchaseView"] ?? false,
        purchaseEdit: json["purchaseEdit"] ?? false,
        purchaseDelete: json["purchaseDelete"] ?? false,
        productView: json["productView"] ?? false,
        productEdit: json["productEdit"] ?? false,
        productDelete: json["productDelete"] ?? false,
        profileEditView: json["profileEditView"] ?? false,
        profileEditEdit: json["profileEditEdit"] ?? false,
        profileEditDelete: json["profileEditDelete"] ?? false,
        addExpenseView: json["addExpenseView"] ?? false,
        addExpenseEdit: json["addExpenseEdit"] ?? false,
        addExpenseDelete: json["addExpenseDelete"] ?? false,
        lossProfitView: json["lossProfitView"] ?? false,
        lossProfitEdit: json["lossProfitEdit"] ?? false,
        lossProfitDelete: json["lossProfitDelete"] ?? false,
        dueListView: json["dueListView"] ?? false,
        dueListEdit: json["dueListEdit"] ?? false,
        dueListDelete: json["dueListDelete"] ?? false,
        stockView: json["stockView"] ?? false,
        stockEdit: json["stockEdit"] ?? false,
        stockDelete: json["stockDelete"] ?? false,
        reportsView: json["reportsView"] ?? false,
        reportsEdit: json["reportsEdit"] ?? false,
        reportsDelete: json["reportsDelete"] ?? false,
        salesListView: json["salesListView"] ?? false,
        salesListEdit: json["salesListEdit"] ?? false,
        salesListDelete: json["salesListDelete"] ?? false,
        purchaseListView: json["purchaseListView"] ?? false,
        purchaseListEdit: json["purchaseListEdit"] ?? false,
        purchaseListDelete: json["purchaseListDelete"] ?? false,
        hrmView: json["hrmView"] ?? false,
        hrmEdit: json["hrmEdit"] ?? false,
        hrmDelete: json["hrmDelete"] ?? false,
      );

  Map<String, dynamic> toJson() => {
        "email": email,
        "userTitle": userTitle,
        "databaseId": databaseId,
        "userRoleName": userRoleName,
        "permissions": List<dynamic>.from(permissions.map((x) => x.toJson())),
        "saleView": saleView,
        "saleEdit": saleEdit,
        "saleDelete": saleDelete,
        "partiesView": partiesView,
        "partiesEdit": partiesEdit,
        "partiesDelete": partiesDelete,
        "purchaseView": purchaseView,
        "purchaseEdit": purchaseEdit,
        "purchaseDelete": purchaseDelete,
        "productView": productView,
        "productEdit": productEdit,
        "productDelete": productDelete,
        "profileEditView": profileEditView,
        "profileEditEdit": profileEditEdit,
        "profileEditDelete": profileEditDelete,
        "addExpenseView": addExpenseView,
        "addExpenseEdit": addExpenseEdit,
        "addExpenseDelete": addExpenseDelete,
        "lossProfitView": lossProfitView,
        "lossProfitEdit": lossProfitEdit,
        "lossProfitDelete": lossProfitDelete,
        "dueListView": dueListView,
        "dueListEdit": dueListEdit,
        "dueListDelete": dueListDelete,
        "stockView": stockView,
        "stockEdit": stockEdit,
        "stockDelete": stockDelete,
        "reportsView": reportsView,
        "reportsEdit": reportsEdit,
        "reportsDelete": reportsDelete,
        "salesListView": salesListView,
        "salesListEdit": salesListEdit,
        "salesListDelete": salesListDelete,
        "purchaseListView": purchaseListView,
        "purchaseListEdit": purchaseListEdit,
        "purchaseListDelete": purchaseListDelete,
        "hrmView": hrmView,
        "hrmEdit": hrmEdit,
        "hrmDelete": hrmDelete,
      };
}

class Permission {
  String type;
  String? title;
  bool view;
  bool edit;
  bool delete;

  Permission({
    required this.type,
    this.title,
    this.view = false,
    this.edit = false,
    this.delete = false,
  });

  factory Permission.fromJson(Map<String, dynamic> json) => Permission(
        type: json["type"],
        title: json["title"],
        view: json["view"],
        edit: json["edit"],
        delete: json["delete"],
      );

  Map<String, dynamic> toJson() => {
        "type": type,
        "title": title,
        "view": view,
        "edit": edit,
        "delete": delete,
      };
}

class UserPermission {
  final String type; // ejemplo: "dashboard", "servicios", etc.
  final bool canView;
  final bool canEdit;
  final bool canDelete;

  UserPermission({
    required this.type,
    this.canView = false,
    this.canEdit = false,
    this.canDelete = false,
  });
}
