// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false) ? locale.languageCode : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }




  /// `Service Packages`
  String get servicePackages {
    return Intl.message(
      'Service Packages',
      name: 'servicePackages',
      desc: '',
      args: [],
    );
  }

  /// `Add Service Package`
  String get addServicePackage {
    return Intl.message(
      'Agregar paquete de servicios',
      name: 'addServicePackage',
      desc: '',
      args: [],
    );
  }

  /// `No service packages found`
  String get noServicePackagesFound {
    return Intl.message(
      'No se han encontrado paquetes de servicio',
      name: 'noServicePackagesFound',
      desc: '',
      args: [],
    );
  }

  /// `Package Name`
  String get packageName {
    return Intl.message(
      'Nombre del paquete',
      name: 'packageName',
      desc: '',
      args: [],
    );
  }


  // dresf
  /// No Images Available
  String get noImagesAvailable {
    return Intl.message(
      'No hay imágenes disponibles', // 👈 El texto que quieres mostrar
      name: 'noImagesAvailable',
      desc: 'Mensaje mostrado cuando no hay imágenes para un vestido',
      args: [],
    );
  }
  String get addDress {
    return Intl.message(
      'Agregar vestido', // 👈 El texto que quieres mostrar
      name: 'addDress',
      desc: 'Botón o título para agregar un nuevo vestido',
      args: [],
    );
  }
  String get branch {
    return Intl.message(
      'Sucursal', // 👈 El texto que quieres mostrar
      name: 'branch',
      desc: 'Nombre o título que representa una sucursal o tienda',
      args: [],
    );
  }
  String get available {
    return Intl.message(
      'Disponible',
      name: 'available',
      desc: 'Estado de disponibilidad de un vestido',
      args: [],
    );
  }

  String get viewImages {
    return Intl.message(
      'Ver Imágenes',
      name: 'viewImages',
      desc: 'Botón o acción para ver las imágenes de un vestido',
      args: [],
    );
  }

  String get noDressesFound {
    return Intl.message(
      'No se encontraron vestidos',
      name: 'noDressesFound',
      desc: 'Mensaje mostrado cuando no hay vestidos disponibles en la búsqueda',
      args: [],
    );
  }

  String get images {
    return Intl.message(
      'Imágenes',
      name: 'images',
      desc: 'Título o etiqueta para el apartado de imágenes',
      args: [],
    );
  }

  String get addImages {
    return Intl.message(
      'Agregar Imágenes',
      name: 'addImages',
      desc: 'Botón o acción para agregar nuevas imágenes',
      args: [],
    );
  }

  String get imagesFor {
    return Intl.message(
      'Imágenes de',
      name: 'imagesFor',
      desc: 'Texto que precede al nombre de un vestido para mostrar sus imágenes',
      args: [],
    );
  }

  String get areYouSureDeleteDress {
    return Intl.message(
      '¿Estás seguro de eliminar este vestido?',
      name: 'areYouSureDeleteDress',
      desc: 'Mensaje de confirmación antes de eliminar un vestido',
      args: [],
    );
  }

  String get dress {
    return Intl.message(
      'Vestido',
      name: 'dress',
      desc: 'Nombre singular para un vestido',
      args: [],
    );
  }

  String get errorDeletingDress {
    return Intl.message(
      'Error al eliminar el vestido',
      name: 'errorDeletingDress',
      desc: 'Mensaje mostrado cuando ocurre un error al intentar eliminar un vestido',
      args: [],
    );
  }

  String get deleted {
    return Intl.message(
      'Eliminado',
      name: 'deleted',
      desc: 'Mensaje breve indicando que algo fue eliminado exitosamente',
      args: [],
    );
  }

  String get updating {
    return Intl.message(
      'Actualizando...',
      name: 'updating',
      desc: 'Mensaje mostrado mientras se actualiza información',
      args: [],
    );
  }

  String get toggleDressAvailabilityProvider {
    return Intl.message(
      'Cambiar disponibilidad del vestido',
      name: 'toggleDressAvailabilityProvider',
      desc: 'Acción para activar o desactivar la disponibilidad de un vestido',
      args: [],
    );
  }

  String get dressAvailability {
    return Intl.message(
      'Disponibilidad del vestido',
      name: 'dressAvailability',
      desc: 'Título o descripción sobre la disponibilidad del vestido',
      args: [],
    );
  }

  String get enabled {
    return Intl.message(
      'Habilitado',
      name: 'enabled',
      desc: 'Estado que indica que algo está disponible o activo',
      args: [],
    );
  }

  String get disabled {
    return Intl.message(
      'Deshabilitado',
      name: 'disabled',
      desc: 'Estado que indica que algo no está disponible o está inactivo',
      args: [],
    );
  }

  String get errorUpdatingAvailability {
    return Intl.message(
      'Error al actualizar la disponibilidad',
      name: 'errorUpdatingAvailability',
      desc: 'Mensaje mostrado cuando ocurre un error al cambiar la disponibilidad',
      args: [],
    );
  }

  String get errorAddingDress {
    return Intl.message(
      'Error al agregar el vestido',
      name: 'errorAddingDress',
      desc: 'Mensaje mostrado cuando ocurre un error al intentar agregar un vestido',
      args: [],
    );
  }

  String get dressAdded {
    return Intl.message(
      'Vestido agregado',
      name: 'dressAdded',
      desc: 'Mensaje mostrado cuando un vestido se agrega exitosamente',
      args: [],
    );
  }

  String get adding {
    return Intl.message(
      'Agregando...',
      name: 'adding',
      desc: 'Mensaje mostrado mientras se está agregando información',
      args: [],
    );
  }

  String get pleaseSelectAtLeastOneImage {
    return Intl.message(
      'Por favor, selecciona al menos una imagen',
      name: 'pleaseSelectAtLeastOneImage',
      desc: 'Mensaje mostrado cuando el usuario no ha seleccionado ninguna imagen',
      args: [],
    );
  }

  String get branchRequired {
    return Intl.message(
      'Sucursal requerida',
      name: 'branchRequired',
      desc: 'Mensaje mostrado cuando no se ha seleccionado una sucursal',
      args: [],
    );
  }

  String get selectBranch {
    return Intl.message(
      'Seleccionar Sucursal',
      name: 'selectBranch',
      desc: 'Etiqueta o botón para seleccionar una sucursal',
      args: [],
    );
  }

  String get enterSubcategory {
    return Intl.message(
      'Ingresar Subcategoría',
      name: 'enterSubcategory',
      desc: 'Etiqueta o instrucción para ingresar una subcategoría',
      args: [],
    );
  }

  String get nameRequired {
    return Intl.message(
      'Nombre requerido',
      name: 'nameRequired',
      desc: 'Mensaje mostrado cuando el campo de nombre está vacío',
      args: [],
    );
  }

  String get enterDressName {
    return Intl.message(
      'Ingresar nombre del vestido',
      name: 'enterDressName',
      desc: 'Etiqueta o instrucción para ingresar el nombre de un vestido',
      args: [],
    );
  }

  String get errorUpdatingDress {
    return Intl.message(
      'Error al actualizar el vestido',
      name: 'errorUpdatingDress',
      desc: 'Mensaje mostrado cuando ocurre un error al actualizar la información de un vestido',
      args: [],
    );
  }

  String get dressUpdated {
    return Intl.message(
      'Vestido actualizado',
      name: 'dressUpdated',
      desc: 'Mensaje mostrado cuando un vestido se actualiza exitosamente',
      args: [],
    );
  }

  String get updateDressProvider {
    return Intl.message(
      'Actualizar vestido',
      name: 'updateDressProvider',
      desc: 'Nombre de la acción o método para actualizar un vestido',
      args: [],
    );
  }







  String get dresses {
    return Intl.message(
      'Vestidos', // 👈 El texto que quieres mostrar
      name: 'dresses',
      desc: 'Título o nombre de la sección de vestidos',
      args: [],
    );
  }
  /// `Category`
  String get category {
    return Intl.message(
      'Categoría',
      name: 'category',
      desc: '',
      args: [],
    );
  }




























  /// `Subcategory`
  String get subcategory {
    return Intl.message(
      'subcategoría',
      name: 'subcategory',
      desc: '',
      args: [],
    );
  }

  /// `Description`
  String get description {
    return Intl.message(
      'Descripción',
      name: 'description',
      desc: '',
      args: [],
    );
  }

  /// `Price`
  String get price {
    return Intl.message(
      'Precio',
      name: 'price',
      desc: '',
      args: [],
    );
  }

  /// `Duration`
  String get duration {
    return Intl.message(
      'Duración',
      name: 'duration',
      desc: '',
      args: [],
    );
  }

  /// `Unit`
  String get unit {
    return Intl.message(
      'Unidad',
      name: 'unit',
      desc: '',
      args: [],
    );
  }

  /// `hours`
  String get hours {
    return Intl.message(
      'horas',
      name: 'hours',
      desc: '',
      args: [],
    );
  }

  /// `days`
  String get days {
    return Intl.message(
      'Días',
      name: 'days',
      desc: '',
      args: [],
    );
  }

  /// `Edit Category`
  String get editCategory {
    return Intl.message(
      'Editar categoría',
      name: 'editCategory',
      desc: '',
      args: [],
    );
  }

  /// `Pos Saas Login panel`
  String get PosSaasLoginPanel {
    return Intl.message(
      'Panel de inicio de sesión de Pos Saas',
      name: 'PosSaasLoginPanel',
      desc: '',
      args: [],
    );
  }

  /// `Pos Saas SingUp Panel`
  String get posSaasSingUpPanel {
    return Intl.message(
      'Panel de Registro Pos Saas',
      name: 'posSaasSingUpPanel',
      desc: '',
      args: [],
    );
  }

  /// `Add New User`
  String get addNewUser {
    return Intl.message('Add New User', name: 'addNewUser', desc: '', args: []);
  }

  /// `User Role`
  String get userRole {
    return Intl.message('User Role', name: 'userRole', desc: '', args: []);
  }

  /// `Add New`
  String get addNew {
    return Intl.message('Add New', name: 'addNew', desc: '', args: []);
  }

  /// `Inventory Sales`
  String get inventorySales {
    return Intl.message(
      'Reservar Venta',
      name: 'inventorySales',
      desc: '',
      args: [],
    );
  }

  /// `Orders`
  String get orders {
    return Intl.message('Orders', name: 'orders', desc: '', args: []);
  }

  /// `Revenue`
  String get revenue {
    return Intl.message('Revenue', name: 'revenue', desc: '', args: []);
  }

  /// `User Name`
  String get userName {
    return Intl.message('User Name', name: 'userName', desc: '', args: []);
  }

  /// `No User Found`
  String get noUserFound {
    return Intl.message(
      'No User Found',
      name: 'noUserFound',
      desc: '',
      args: [],
    );
  }

  /// `All`
  String get all {
    return Intl.message('All', name: 'all', desc: '', args: []);
  }

  /// `Profile Edit`
  String get profileEdit {
    return Intl.message(
      'Profile Edit',
      name: 'profileEdit',
      desc: '',
      args: [],
    );
  }

  /// `Practise`
  String get practies {
    return Intl.message('Practise', name: 'practies', desc: '', args: []);
  }

  /// `Sales List`
  String get salesList {
    return Intl.message('Sales List', name: 'salesList', desc: '', args: []);
  }

  /// `Enter Password`
  String get enterPassword {
    return Intl.message(
      'Enter Password',
      name: 'enterPassword',
      desc: '',
      args: [],
    );
  }

  /// `No User Role Found`
  String get noUserRoleFound {
    return Intl.message(
      'No User Role Found',
      name: 'noUserRoleFound',
      desc: '',
      args: [],
    );
  }

  /// `Add User Role`
  String get addUserRole {
    return Intl.message(
      'Add User Role',
      name: 'addUserRole',
      desc: '',
      args: [],
    );
  }

  /// `User Title`
  String get UserTitle {
    return Intl.message('User Title', name: 'UserTitle', desc: '', args: []);
  }

  /// `Enter user title`
  String get enterUserTitle {
    return Intl.message(
      'Enter user title',
      name: 'enterUserTitle',
      desc: '',
      args: [],
    );
  }

  /// `User Title`
  String get userTitle {
    return Intl.message('User Title', name: 'userTitle', desc: '', args: []);
  }

  /// `Added Successful`
  String get addSuccessful {
    return Intl.message(
      'Added Successful',
      name: 'addSuccessful',
      desc: '',
      args: [],
    );
  }

  /// `You have to RE-LOGIN on your account.`
  String get youHaveToRelogin {
    return Intl.message(
      'You have to RE-LOGIN on your account.',
      name: 'youHaveToRelogin',
      desc: '',
      args: [],
    );
  }

  /// `Ok`
  String get ok {
    return Intl.message('Ok', name: 'ok', desc: '', args: []);
  }

  /// `Pay Cash`
  String get payCash {
    return Intl.message('Pay Cash', name: 'payCash', desc: '', args: []);
  }

  /// `Free Lifetime Update`
  String get freeLifeTimeUpdate {
    return Intl.message(
      'Free Lifetime Update',
      name: 'freeLifeTimeUpdate',
      desc: '',
      args: [],
    );
  }

  /// `Android & iOS App Support`
  String get androidIOSAppSupport {
    return Intl.message(
      'Android & iOS App Support',
      name: 'androidIOSAppSupport',
      desc: '',
      args: [],
    );
  }

  /// `Premium Customer Support`
  String get premiumCustomerSupport {
    return Intl.message(
      'Premium Customer Support',
      name: 'premiumCustomerSupport',
      desc: '',
      args: [],
    );
  }

  /// `Custom Invoice Branding`
  String get customInvoiceBranding {
    return Intl.message(
      'Custom Invoice Branding',
      name: 'customInvoiceBranding',
      desc: '',
      args: [],
    );
  }

  /// `Unlimited Usage`
  String get unlimitedUsage {
    return Intl.message(
      'Unlimited Usage',
      name: 'unlimitedUsage',
      desc: '',
      args: [],
    );
  }

  /// `Free Data Backup`
  String get freeDataBackup {
    return Intl.message(
      'Free Data Backup',
      name: 'freeDataBackup',
      desc: '',
      args: [],
    );
  }

  /// `Stay at the forefront of technological advancements without any extra costs. Our Pos Saas POS Unlimited Upgrade ensures that you always have the latest tools and features at your fingertips, guaranteeing your business remains cutting-edge.`
  String get stayAtTheForFront {
    return Intl.message(
      'Stay at the forefront of technological advancements without any extra costs. Our Pos Saas POS Unlimited Upgrade ensures that you always have the latest tools and features at your fingertips, guaranteeing your business remains cutting-edge.',
      name: 'stayAtTheForFront',
      desc: '',
      args: [],
    );
  }

  /// ` We understand the importance of seamless operations. That's why our round-the-clock support is available to assist you, whether it's a quick query or a comprehensive concern. Connect with us anytime, anywhere via call or WhatsApp to experience unrivaled customer service.`
  String get weUnderStand {
    return Intl.message(
      ' We understand the importance of seamless operations. That\'s why our round-the-clock support is available to assist you, whether it\'s a quick query or a comprehensive concern. Connect with us anytime, anywhere via call or WhatsApp to experience unrivaled customer service.',
      name: 'weUnderStand',
      desc: '',
      args: [],
    );
  }

  /// `Unlock the full potential of Pos Saas POS with personalized training sessions led by our expert team. From the basics to advanced techniques, we ensure you're well-versed in utilizing every facet of the system to optimize your business processes.`
  String get unlockTheFull {
    return Intl.message(
      'Unlock the full potential of Pos Saas POS with personalized training sessions led by our expert team. From the basics to advanced techniques, we ensure you\'re well-versed in utilizing every facet of the system to optimize your business processes.',
      name: 'unlockTheFull',
      desc: '',
      args: [],
    );
  }

  /// `Make a lasting impression on your customers with branded invoices. Our Unlimited Upgrade offers the unique advantage of customizing your invoices, adding a professional touch that reinforces your brand identity and fosters customer loyalty.`
  String get makeALastingImpression {
    return Intl.message(
      'Make a lasting impression on your customers with branded invoices. Our Unlimited Upgrade offers the unique advantage of customizing your invoices, adding a professional touch that reinforces your brand identity and fosters customer loyalty.',
      name: 'makeALastingImpression',
      desc: '',
      args: [],
    );
  }

  /// `The name says it all. With Pos Saas POS Unlimited, there's no cap on your usage. Whether you're processing a handful of transactions or experiencing a rush of customers, you can operate with confidence, knowing you're not constrained by limits`
  String get theNameSysIt {
    return Intl.message(
      'The name says it all. With Pos Saas POS Unlimited, there\'s no cap on your usage. Whether you\'re processing a handful of transactions or experiencing a rush of customers, you can operate with confidence, knowing you\'re not constrained by limits',
      name: 'theNameSysIt',
      desc: '',
      args: [],
    );
  }

  /// `Safeguard your business data effortlessly. Our Pos Saas POS Unlimited Upgrade includes free data backup, ensuring your valuable information is protected against any unforeseen events. Focus on what truly matters - your business growth.`
  String get safegurardYourBusinessDate {
    return Intl.message(
      'Safeguard your business data effortlessly. Our Pos Saas POS Unlimited Upgrade includes free data backup, ensuring your valuable information is protected against any unforeseen events. Focus on what truly matters - your business growth.',
      name: 'safegurardYourBusinessDate',
      desc: '',
      args: [],
    );
  }

  /// `Buy`
  String get buy {
    return Intl.message('Buy', name: 'buy', desc: '', args: []);
  }

  /// `Bank Information`
  String get bankInformation {
    return Intl.message(
      'Bank Information',
      name: 'bankInformation',
      desc: '',
      args: [],
    );
  }

  /// `Bank Name`
  String get bankName {
    return Intl.message('Bank Name', name: 'bankName', desc: '', args: []);
  }

  /// `Branch Name`
  String get branchName {
    return Intl.message('Branch Name', name: 'branchName', desc: '', args: []);
  }

  /// `Account Name`
  String get accountName {
    return Intl.message(
      'Account Name',
      name: 'accountName',
      desc: '',
      args: [],
    );
  }

  /// `Account Number`
  String get accountNumber {
    return Intl.message(
      'Account Number',
      name: 'accountNumber',
      desc: '',
      args: [],
    );
  }

  /// `Bank Account Currency`
  String get bankAccountingCurrecny {
    return Intl.message(
      'Bank Account Currency',
      name: 'bankAccountingCurrecny',
      desc: '',
      args: [],
    );
  }

  /// `SWIFT Code`
  String get swiftCode {
    return Intl.message('SWIFT Code', name: 'swiftCode', desc: '', args: []);
  }

  /// `Enter Transaction Id`
  String get enterTransactionId {
    return Intl.message(
      'Enter Transaction Id',
      name: 'enterTransactionId',
      desc: '',
      args: [],
    );
  }

  /// `Upload Document`
  String get uploadDocument {
    return Intl.message(
      'Upload Document',
      name: 'uploadDocument',
      desc: '',
      args: [],
    );
  }

  /// `Upload File`
  String get uploadFile {
    return Intl.message('Upload File', name: 'uploadFile', desc: '', args: []);
  }

  /// `About App`
  String get aboutApp {
    return Intl.message('About App', name: 'aboutApp', desc: '', args: []);
  }

  /// `Terms of use`
  String get termsOfUse {
    return Intl.message('Terms of use', name: 'termsOfUse', desc: '', args: []);
  }

  /// `Privacy Policy`
  String get privacyPolicy {
    return Intl.message(
      'Privacy Policy',
      name: 'privacyPolicy',
      desc: '',
      args: [],
    );
  }

  /// `User Role Name`
  String get userRoleName {
    return Intl.message(
      'User Role Name',
      name: 'userRoleName',
      desc: '',
      args: [],
    );
  }

  /// `Enter User Role Name`
  String get enterUserRoleName {
    return Intl.message(
      'Enter User Role Name',
      name: 'enterUserRoleName',
      desc: '',
      args: [],
    );
  }

  /// `Your Package`
  String get yourPackage {
    return Intl.message(
      'Your Package',
      name: 'yourPackage',
      desc: '',
      args: [],
    );
  }

  /// `Free Plan`
  String get freePlan {
    return Intl.message('Free Plan', name: 'freePlan', desc: '', args: []);
  }

  /// `You are using`
  String get yourAreUsing {
    return Intl.message(
      'You are using',
      name: 'yourAreUsing',
      desc: '',
      args: [],
    );
  }

  /// `Free Package`
  String get freePackage {
    return Intl.message(
      'Free Package',
      name: 'freePackage',
      desc: '',
      args: [],
    );
  }

  /// `Premium Plan`
  String get premiumPlan {
    return Intl.message(
      'Premium Plan',
      name: 'premiumPlan',
      desc: '',
      args: [],
    );
  }

  /// `Package Feature`
  String get packageFeature {
    return Intl.message(
      'Package Feature',
      name: 'packageFeature',
      desc: '',
      args: [],
    );
  }

  /// `Remaining: `
  String get remaining {
    return Intl.message('Remaining: ', name: 'remaining', desc: '', args: []);
  }

  /// `Unlimited`
  String get unlimited {
    return Intl.message('Unlimited', name: 'unlimited', desc: '', args: []);
  }

  /// `For Unlimited Uses`
  String get forUnlimitedUses {
    return Intl.message(
      'For Unlimited Uses',
      name: 'forUnlimitedUses',
      desc: '',
      args: [],
    );
  }

  /// `Update Now`
  String get updateNow {
    return Intl.message('Update Now', name: 'updateNow', desc: '', args: []);
  }

  /// `Purchase Premium Plan`
  String get purchasePremiumPlan {
    return Intl.message(
      'Purchase Premium Plan',
      name: 'purchasePremiumPlan',
      desc: '',
      args: [],
    );
  }

  /// `Stay at the forefront of technological advancements without any extra costs. Our Pos Sass POS Unlimited Upgrade ensures that you always have the latest tools and features at your fingertips, guaranteeing your business remains cutting-edge.`
  String get stayAtTheForeFrontOfTechnological {
    return Intl.message(
      'Stay at the forefront of technological advancements without any extra costs. Our Pos Sass POS Unlimited Upgrade ensures that you always have the latest tools and features at your fingertips, guaranteeing your business remains cutting-edge.',
      name: 'stayAtTheForeFrontOfTechnological',
      desc: '',
      args: [],
    );
  }

  /// `Buy Premium Plan`
  String get buyPremiumPlan {
    return Intl.message(
      'Buy Premium Plan',
      name: 'buyPremiumPlan',
      desc: '',
      args: [],
    );
  }

  /// `Mobile App\n+\nDesktop`
  String get mobilePlusDesktop {
    return Intl.message(
      'Mobile App\n+\nDesktop',
      name: 'mobilePlusDesktop',
      desc: '',
      args: [],
    );
  }

  /// `Transaction Id`
  String get transactionId {
    return Intl.message(
      'Transaction Id',
      name: 'transactionId',
      desc: '',
      args: [],
    );
  }

  /// `Product Stock`
  String get productStock {
    return Intl.message(
      'Product Stock',
      name: 'productStock',
      desc: '',
      args: [],
    );
  }

  /// `Please enter product stock`
  String get pleaseEnterProductStock {
    return Intl.message(
      'Please enter product stock',
      name: 'pleaseEnterProductStock',
      desc: '',
      args: [],
    );
  }

  /// `Increase Stock`
  String get increaseStock {
    return Intl.message(
      'Increase Stock',
      name: 'increaseStock',
      desc: '',
      args: [],
    );
  }

  /// `Are you want to delete this product`
  String get areYouWantToDeleteThisProduct {
    return Intl.message(
      'Are you want to delete this product',
      name: 'areYouWantToDeleteThisProduct',
      desc: '',
      args: [],
    );
  }

  /// `No Connection`
  String get noConnection {
    return Intl.message(
      'No Connection',
      name: 'noConnection',
      desc: '',
      args: [],
    );
  }

  /// `Please Check Your Internet Connectivity`
  String get pleaseCheckYourInternetConnectivity {
    return Intl.message(
      'Please Check Your Internet Connectivity',
      name: 'pleaseCheckYourInternetConnectivity',
      desc: '',
      args: [],
    );
  }

  /// `Try Again`
  String get tryAgain {
    return Intl.message('Try Again', name: 'tryAgain', desc: '', args: []);
  }

  /// `Currency`
  String get currency {
    return Intl.message('Currency', name: 'currency', desc: '', args: []);
  }

  /// `Business Category`
  String get businessCategory {
    return Intl.message(
      'Business Category',
      name: 'businessCategory',
      desc: '',
      args: [],
    );
  }

  /// `Company Name`
  String get companyName {
    return Intl.message(
      'Company Name',
      name: 'companyName',
      desc: '',
      args: [],
    );
  }

  /// `Enter Your Company Name`
  String get enterYourCompanyName {
    return Intl.message(
      'Enter Your Company Name',
      name: 'enterYourCompanyName',
      desc: '',
      args: [],
    );
  }

  /// `Phone Number`
  String get phoneNumber {
    return Intl.message(
      'Phone Number',
      name: 'phoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Enter your phone number`
  String get enterYourPhoneNumber {
    return Intl.message(
      'Enter your phone number',
      name: 'enterYourPhoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Shop Opening Balance`
  String get shopOpeningBalance {
    return Intl.message(
      'Shop Opening Balance',
      name: 'shopOpeningBalance',
      desc: '',
      args: [],
    );
  }

  /// `Enter your amount`
  String get enterYOurAmount {
    return Intl.message(
      'Enter your amount',
      name: 'enterYOurAmount',
      desc: '',
      args: [],
    );
  }

  /// `Continue`
  String get continu {
    return Intl.message('Continue', name: 'continu', desc: '', args: []);
  }

  /// `Reset Your Password`
  String get resetYourPassword {
    return Intl.message(
      'Reset Your Password',
      name: 'resetYourPassword',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get email {
    return Intl.message('Email', name: 'email', desc: '', args: []);
  }

  /// `Enter your email address`
  String get enterYourEmailAddress {
    return Intl.message(
      'Enter your email address',
      name: 'enterYourEmailAddress',
      desc: '',
      args: [],
    );
  }

  /// `Please download our mobile app and subscribe to a package to use the desktop version`
  String get pleaseDownloadOurMobileApp {
    return Intl.message(
      'Please download our mobile app and subscribe to a package to use the desktop version',
      name: 'pleaseDownloadOurMobileApp',
      desc: '',
      args: [],
    );
  }

  /// `Pos Saas Login Panel`
  String get mobiPosLoginPanel {
    return Intl.message(
      'Pos Saas Login Panel',
      name: 'mobiPosLoginPanel',
      desc: '',
      args: [],
    );
  }

  /// `Enter Your Password`
  String get enterYourPassword {
    return Intl.message(
      'Enter Your Password',
      name: 'enterYourPassword',
      desc: '',
      args: [],
    );
  }

  /// `Login`
  String get login {
    return Intl.message('Login', name: 'login', desc: '', args: []);
  }

  /// `Password`
  String get password {
    return Intl.message('Password', name: 'password', desc: '', args: []);
  }

  /// `Forgot Password?`
  String get forgotPassword {
    return Intl.message(
      'Forgot Password?',
      name: 'forgotPassword',
      desc: '',
      args: [],
    );
  }

  /// `Register`
  String get registration {
    return Intl.message('Register', name: 'registration', desc: '', args: []);
  }

  /// `Edit your profile`
  String get editYourProfile {
    return Intl.message(
      'Edit your profile',
      name: 'editYourProfile',
      desc: '',
      args: [],
    );
  }

  /// `Upload an image`
  String get uploadAImage {
    return Intl.message(
      'Upload an image',
      name: 'uploadAImage',
      desc: '',
      args: [],
    );
  }

  /// ` or drag & drop PNG, JPG`
  String get orDragAndDropPng {
    return Intl.message(
      ' or drag & drop PNG, JPG',
      name: 'orDragAndDropPng',
      desc: '',
      args: [],
    );
  }

  /// `Company Name`
  String get comapnyName {
    return Intl.message(
      'Company Name',
      name: 'comapnyName',
      desc: '',
      args: [],
    );
  }

  /// `Enter your Company Name`
  String get enterYourCompanyNames {
    return Intl.message(
      'Enter your Company Name',
      name: 'enterYourCompanyNames',
      desc: '',
      args: [],
    );
  }

  /// `Address`
  String get address {
    return Intl.message('Address', name: 'address', desc: '', args: []);
  }

  /// `Enter Your Address`
  String get enterYourAddress {
    return Intl.message(
      'Enter Your Address',
      name: 'enterYourAddress',
      desc: '',
      args: [],
    );
  }

  /// `Pos Saas Signup Panel`
  String get mobiPosSignUpPane {
    return Intl.message(
      'Pos Saas Signup Panel',
      name: 'mobiPosSignUpPane',
      desc: '',
      args: [],
    );
  }

  /// `Confirm password`
  String get confirmPassword {
    return Intl.message(
      'Confirm password',
      name: 'confirmPassword',
      desc: '',
      args: [],
    );
  }

  /// `Enter your password again`
  String get enterYourPasswordAgain {
    return Intl.message(
      'Enter your password again',
      name: 'enterYourPasswordAgain',
      desc: '',
      args: [],
    );
  }

  /// `Already have an account's?`
  String get alreadyHaveAnAccounts {
    return Intl.message(
      'Already have an account\'s?',
      name: 'alreadyHaveAnAccounts',
      desc: '',
      args: [],
    );
  }

  /// `Chose a plan`
  String get choseAplan {
    return Intl.message('Chose a plan', name: 'choseAplan', desc: '', args: []);
  }

  /// `All Basic Features`
  String get allBasicFeatures {
    return Intl.message(
      'All Basic Features',
      name: 'allBasicFeatures',
      desc: '',
      args: [],
    );
  }

  /// `Unlimited Invoices`
  String get unlimitedInvoice {
    return Intl.message(
      'Unlimited Invoices',
      name: 'unlimitedInvoice',
      desc: '',
      args: [],
    );
  }

  /// `Get Started`
  String get getStarted {
    return Intl.message('Get Started', name: 'getStarted', desc: '', args: []);
  }

  /// `Current plan`
  String get currentPlan {
    return Intl.message(
      'Current plan',
      name: 'currentPlan',
      desc: '',
      args: [],
    );
  }

  /// `Select your language`
  String get selectYourLanguage {
    return Intl.message(
      'Select your language',
      name: 'selectYourLanguage',
      desc: '',
      args: [],
    );
  }

  /// `Shop Name`
  String get shopName {
    return Intl.message('Shop Name', name: 'shopName', desc: '', args: []);
  }

  /// `Enter Your Shop Name`
  String get enterYourShopName {
    return Intl.message(
      'Enter Your Shop Name',
      name: 'enterYourShopName',
      desc: '',
      args: [],
    );
  }

  /// `Phone Verification`
  String get phoneVerification {
    return Intl.message(
      'Phone Verification',
      name: 'phoneVerification',
      desc: '',
      args: [],
    );
  }

  /// `We need to register your phone before getting started!`
  String get weNeedToRegisterYourPhone {
    return Intl.message(
      'We need to register your phone before getting started!',
      name: 'weNeedToRegisterYourPhone',
      desc: '',
      args: [],
    );
  }

  /// `Verify Phone Number`
  String get verifyPhoneNumber {
    return Intl.message(
      'Verify Phone Number',
      name: 'verifyPhoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Customer Name`
  String get customerName {
    return Intl.message(
      'Customer Name',
      name: 'customerName',
      desc: '',
      args: [],
    );
  }

  /// `Enter Customer Name`
  String get enterCustomerName {
    return Intl.message(
      'Enter Customer Name',
      name: 'enterCustomerName',
      desc: '',
      args: [],
    );
  }

  /// `Opening Balance`
  String get openingBalance {
    return Intl.message(
      'Opening Balance',
      name: 'openingBalance',
      desc: '',
      args: [],
    );
  }

  /// `Enter Opening Balance`
  String get enterOpeningBalance {
    return Intl.message(
      'Enter Opening Balance',
      name: 'enterOpeningBalance',
      desc: '',
      args: [],
    );
  }

  /// `Type`
  String get type {
    return Intl.message('Type', name: 'type', desc: '', args: []);
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `Save & Publish`
  String get saveAndPublish {
    return Intl.message(
      'Save & Publish',
      name: 'saveAndPublish',
      desc: '',
      args: [],
    );
  }

  /// `Customer List`
  String get customerList {
    return Intl.message(
      'Customer List',
      name: 'customerList',
      desc: '',
      args: [],
    );
  }

  /// `Search by Name or Phone...`
  String get searchByNameOrPhone {
    return Intl.message(
      'Search by Name or Phone...',
      name: 'searchByNameOrPhone',
      desc: '',
      args: [],
    );
  }

  /// `Add Customer`
  String get addCustomer {
    return Intl.message(
      'Add Customer',
      name: 'addCustomer',
      desc: '',
      args: [],
    );
  }

  /// `Party Name`
  String get partyName {
    return Intl.message('Party Name', name: 'partyName', desc: '', args: []);
  }

  /// `Party Type`
  String get partyType {
    return Intl.message('Party Type', name: 'partyType', desc: '', args: []);
  }

  /// `Phone`
  String get phone {
    return Intl.message('Phone', name: 'phone', desc: '', args: []);
  }

  /// `Due`
  String get due {
    return Intl.message('Due', name: 'due', desc: '', args: []);
  }

  /// `Edit`
  String get edit {
    return Intl.message('Edit', name: 'edit', desc: '', args: []);
  }

  /// `Delete`
  String get delete {
    return Intl.message('Delete', name: 'delete', desc: '', args: []);
  }

  /// `Are you want to delete this Customer?`
  String get areYouWantToDeleteThisCustomer {
    return Intl.message(
      'Are you want to delete this Customer?',
      name: 'areYouWantToDeleteThisCustomer',
      desc: '',
      args: [],
    );
  }

  /// `This customer have previous due`
  String get thisCustomerHavepreviousDue {
    return Intl.message(
      'This customer have previous due',
      name: 'thisCustomerHavepreviousDue',
      desc: '',
      args: [],
    );
  }

  /// `No Customer Found`
  String get noCustomerFound {
    return Intl.message(
      'No Customer Found',
      name: 'noCustomerFound',
      desc: '',
      args: [],
    );
  }

  /// `Total Due`
  String get totalDue {
    return Intl.message('Total Due', name: 'totalDue', desc: '', args: []);
  }

  /// `Customers`
  String get customers {
    return Intl.message('Customers', name: 'customers', desc: '', args: []);
  }

  /// `Suppliers`
  String get supplier {
    return Intl.message('Suppliers', name: 'supplier', desc: '', args: []);
  }

  /// `Collect Due >`
  String get collectDue {
    return Intl.message(
      'Collect Due >',
      name: 'collectDue',
      desc: '',
      args: [],
    );
  }

  /// `No Due Transaction Found`
  String get noDueTransantionFound {
    return Intl.message(
      'No Due Transaction Found',
      name: 'noDueTransantionFound',
      desc: '',
      args: [],
    );
  }

  /// `Create Payment`
  String get createPayment {
    return Intl.message(
      'Create Payment',
      name: 'createPayment',
      desc: '',
      args: [],
    );
  }

  /// `Grand Total`
  String get grandTotal {
    return Intl.message('Grand Total', name: 'grandTotal', desc: '', args: []);
  }

  /// `Paying Amount`
  String get payingAmount {
    return Intl.message(
      'Paying Amount',
      name: 'payingAmount',
      desc: '',
      args: [],
    );
  }

  /// `Enter paid amounts`
  String get enterPaidAmount {
    return Intl.message(
      'Enter paid amounts',
      name: 'enterPaidAmount',
      desc: '',
      args: [],
    );
  }

  /// `Change Amount`
  String get changeAmount {
    return Intl.message(
      'Change Amount',
      name: 'changeAmount',
      desc: '',
      args: [],
    );
  }

  /// `Due Amount`
  String get dueAmount {
    return Intl.message('Due Amount', name: 'dueAmount', desc: '', args: []);
  }

  /// `Payment Type`
  String get paymentType {
    return Intl.message(
      'Payment Type',
      name: 'paymentType',
      desc: '',
      args: [],
    );
  }

  /// `Submit`
  String get submit {
    return Intl.message('Submit', name: 'submit', desc: '', args: []);
  }

  /// `Enter Expense Category`
  String get enterExpanseCategory {
    return Intl.message(
      'Enter Expense Category',
      name: 'enterExpanseCategory',
      desc: '',
      args: [],
    );
  }

  /// `Please enter valid data`
  String get pleaseEnterValidData {
    return Intl.message(
      'Please enter valid data',
      name: 'pleaseEnterValidData',
      desc: '',
      args: [],
    );
  }

  /// `Category Name`
  String get categoryName {
    return Intl.message(
      'Category Name',
      name: 'categoryName',
      desc: '',
      args: [],
    );
  }

  /// `Enter Category Name`
  String get entercategoryName {
    return Intl.message(
      'Enter Category Name',
      name: 'entercategoryName',
      desc: '',
      args: [],
    );
  }


  /// `Add description....`
  String get addDescription {
    return Intl.message(
      'Add description....',
      name: 'addDescription',
      desc: '',
      args: [],
    );
  }

  /// `Expense CategoryList`
  String get expensecategoryList {
    return Intl.message(
      'Expense CategoryList',
      name: 'expensecategoryList',
      desc: '',
      args: [],
    );
  }

  /// `Search by invoice....`
  String get searchByInvoice {
    return Intl.message(
      'Search by invoice....',
      name: 'searchByInvoice',
      desc: '',
      args: [],
    );
  }

  /// `Add Category`
  String get addCategory {
    return Intl.message(
      'Add Category',
      name: 'addCategory',
      desc: '',
      args: [],
    );
  }

  /// `Action`
  String get action {
    return Intl.message('Action', name: 'action', desc: '', args: []);
  }

  /// `No Expense Category Found`
  String get noExpenseCategoryFound {
    return Intl.message(
      'No Expense Category Found',
      name: 'noExpenseCategoryFound',
      desc: '',
      args: [],
    );
  }

  /// `Expense Details`
  String get expenseDetails {
    return Intl.message(
      'Expense Details',
      name: 'expenseDetails',
      desc: '',
      args: [],
    );
  }

  /// `Date`
  String get date {
    return Intl.message('Date', name: 'date', desc: '', args: []);
  }

  /// `Name`
  String get name {
    return Intl.message('Name', name: 'name', desc: '', args: []);
  }



  /// `Reference No.`
  String get referenceNo {
    return Intl.message(
      'Reference No.',
      name: 'referenceNo',
      desc: '',
      args: [],
    );
  }

  /// `Amount`
  String get amount {
    return Intl.message('Amount', name: 'amount', desc: '', args: []);
  }

  /// `Note`
  String get note {
    return Intl.message('Note', name: 'note', desc: '', args: []);
  }

  /// `Name*`
  String get nam {
    return Intl.message('Name*', name: 'nam', desc: '', args: []);
  }

  /// `Income`
  String get income {
    return Intl.message('Income', name: 'income', desc: '', args: []);
  }

  /// `Add/Update Expense List`
  String get addUpdateExpenseList {
    return Intl.message(
      'Add/Update Expense List',
      name: 'addUpdateExpenseList',
      desc: '',
      args: [],
    );
  }

  /// `Expense Date`
  String get expenseDate {
    return Intl.message(
      'Expense Date',
      name: 'expenseDate',
      desc: '',
      args: [],
    );
  }

  /// `Enter Expense Date`
  String get enterExpenseDate {
    return Intl.message(
      'Enter Expense Date',
      name: 'enterExpenseDate',
      desc: '',
      args: [],
    );
  }

  /// `Expense For`
  String get expenseFor {
    return Intl.message('Expense For', name: 'expenseFor', desc: '', args: []);
  }

  /// `Enter Name`
  String get enterName {
    return Intl.message('Enter Name', name: 'enterName', desc: '', args: []);
  }

  /// `Reference Number`
  String get referenceNumber {
    return Intl.message(
      'Reference Number',
      name: 'referenceNumber',
      desc: '',
      args: [],
    );
  }

  /// `Enter Reference Number`
  String get enterReferenceNumber {
    return Intl.message(
      'Enter Reference Number',
      name: 'enterReferenceNumber',
      desc: '',
      args: [],
    );
  }

  /// `Enter Note`
  String get enterNote {
    return Intl.message('Enter Note', name: 'enterNote', desc: '', args: []);
  }

  /// `Between`
  String get between {
    return Intl.message('Between', name: 'between', desc: '', args: []);
  }

  /// `To`
  String get to {
    return Intl.message('To', name: 'to', desc: '', args: []);
  }

  /// `Total Expense`
  String get totalExpense {
    return Intl.message(
      'Total Expense',
      name: 'totalExpense',
      desc: '',
      args: [],
    );
  }

  /// `Total Sales`
  String get totalSales {
    return Intl.message('Total Sales', name: 'totalSales', desc: '', args: []);
  }

  /// `Purchase`
  String get purchase {
    return Intl.message('Purchase', name: 'purchase', desc: '', args: []);
  }

  /// `New Customers`
  String get newCustomers {
    return Intl.message(
      'New Customers',
      name: 'newCustomers',
      desc: '',
      args: [],
    );
  }

  /// `Daily Sales`
  String get dailySales {
    return Intl.message('Daily Sales', name: 'dailySales', desc: '', args: []);
  }

  /// `Daily Collection`
  String get dailyCollection {
    return Intl.message(
      'Daily Collection',
      name: 'dailyCollection',
      desc: '',
      args: [],
    );
  }

  /// `Instant Privacy`
  String get instantPrivacy {
    return Intl.message(
      'Instant Privacy',
      name: 'instantPrivacy',
      desc: '',
      args: [],
    );
  }

  /// `Stock Inventory`
  String get stockInventory {
    return Intl.message(
      'Stock Inventory',
      name: 'stockInventory',
      desc: '',
      args: [],
    );
  }

  /// `Stock Value`
  String get stockValue {
    return Intl.message('Stock Value', name: 'stockValue', desc: '', args: []);
  }

  /// `Low Stocks`
  String get lowStocks {
    return Intl.message('Low Stocks', name: 'lowStocks', desc: '', args: []);
  }

  /// `Other`
  String get other {
    return Intl.message('Other', name: 'other', desc: '', args: []);
  }

  /// `Other Income`
  String get otherIncome {
    return Intl.message(
      'Other Income',
      name: 'otherIncome',
      desc: '',
      args: [],
    );
  }

  /// `Pos Saas`
  String get MOBIPOS {
    return Intl.message('Pos Saas', name: 'MOBIPOS', desc: '', args: []);
  }

  /// `New Customers`
  String get newCusotmers {
    return Intl.message(
      'New Customers',
      name: 'newCusotmers',
      desc: '',
      args: [],
    );
  }

  /// `Enter Income Category`
  String get enterIncomeCategory {
    return Intl.message(
      'Enter Income Category',
      name: 'enterIncomeCategory',
      desc: '',
      args: [],
    );
  }

  /// `Please enter valid data`
  String get pleaseentervaliddata {
    return Intl.message(
      'Please enter valid data',
      name: 'pleaseentervaliddata',
      desc: '',
      args: [],
    );
  }

  /// `Save & Publish`
  String get saveAndPublished {
    return Intl.message(
      'Save & Publish',
      name: 'saveAndPublished',
      desc: '',
      args: [],
    );
  }

  /// `Income Category List`
  String get incomeCategoryList {
    return Intl.message(
      'Income Category List',
      name: 'incomeCategoryList',
      desc: '',
      args: [],
    );
  }

  /// `No Income Category Found`
  String get noIncomeCategoryFound {
    return Intl.message(
      'No Income Category Found',
      name: 'noIncomeCategoryFound',
      desc: '',
      args: [],
    );
  }

  /// `Income Details`
  String get incomeDetails {
    return Intl.message(
      'Income Details',
      name: 'incomeDetails',
      desc: '',
      args: [],
    );
  }

  /// `Payment Type`
  String get paymentTypes {
    return Intl.message(
      'Payment Type',
      name: 'paymentTypes',
      desc: '',
      args: [],
    );
  }

  /// `Total Income`
  String get totalIncome {
    return Intl.message(
      'Total Income',
      name: 'totalIncome',
      desc: '',
      args: [],
    );
  }

  /// `Income List`
  String get incomeList {
    return Intl.message('Income List', name: 'incomeList', desc: '', args: []);
  }

  /// `income Category`
  String get incomeCategory {
    return Intl.message(
      'income Category',
      name: 'incomeCategory',
      desc: '',
      args: [],
    );
  }

  /// `New Income`
  String get newIncome {
    return Intl.message('New Income', name: 'newIncome', desc: '', args: []);
  }

  /// `Created By`
  String get createdBy {
    return Intl.message('Created By', name: 'createdBy', desc: '', args: []);
  }

  /// `View`
  String get view {
    return Intl.message('View', name: 'view', desc: '', args: []);
  }

  /// `No Income Found`
  String get noIncomeFound {
    return Intl.message(
      'No Income Found',
      name: 'noIncomeFound',
      desc: '',
      args: [],
    );
  }

  /// `Add/Update Income List`
  String get addUpdateIncomeList {
    return Intl.message(
      'Add/Update Income List',
      name: 'addUpdateIncomeList',
      desc: '',
      args: [],
    );
  }

  /// `Income Date`
  String get incomeDate {
    return Intl.message('Income Date', name: 'incomeDate', desc: '', args: []);
  }

  /// `Enter Income Date`
  String get enterIncomeDate {
    return Intl.message(
      'Enter Income Date',
      name: 'enterIncomeDate',
      desc: '',
      args: [],
    );
  }

  /// `Income For`
  String get incomeFor {
    return Intl.message('Income For', name: 'incomeFor', desc: '', args: []);
  }

  /// `Enter Name`
  String get enterNames {
    return Intl.message('Enter Name', name: 'enterNames', desc: '', args: []);
  }

  /// `Enter Amount`
  String get enterAmount {
    return Intl.message(
      'Enter Amount',
      name: 'enterAmount',
      desc: '',
      args: [],
    );
  }

  /// `Print Invoice`
  String get printInvoice {
    return Intl.message(
      'Print Invoice',
      name: 'printInvoice',
      desc: '',
      args: [],
    );
  }

  /// `Money Receipt`
  String get moneyReciept {
    return Intl.message(
      'Money Receipt',
      name: 'moneyReciept',
      desc: '',
      args: [],
    );
  }

  /// `Bill to:`
  String get billTo {
    return Intl.message('Bill to:', name: 'billTo', desc: '', args: []);
  }

  /// `Invoice No.`
  String get invoiceNo {
    return Intl.message('Invoice No.', name: 'invoiceNo', desc: '', args: []);
  }

  /// `Total Dues`
  String get totalDues {
    return Intl.message('Total Dues', name: 'totalDues', desc: '', args: []);
  }

  /// `Paid amount`
  String get paidAmount {
    return Intl.message('Paid amount', name: 'paidAmount', desc: '', args: []);
  }

  /// `Remaining Due`
  String get remainingDue {
    return Intl.message(
      'Remaining Due',
      name: 'remainingDue',
      desc: '',
      args: [],
    );
  }

  /// `Delivery Charge`
  String get deliveryCharge {
    return Intl.message(
      'Delivery Charge',
      name: 'deliveryCharge',
      desc: '',
      args: [],
    );
  }

  /// `INVOICE`
  String get INVOICE {
    return Intl.message('INVOICE', name: 'INVOICE', desc: '', args: []);
  }

  /// `Product`
  String get product {
    return Intl.message('Product', name: 'product', desc: '', args: []);
  }

  /// `Quantity`
  String get quantity {
    return Intl.message('Quantity', name: 'quantity', desc: '', args: []);
  }

  /// `Unit Price`
  String get unitPrice {
    return Intl.message('Unit Price', name: 'unitPrice', desc: '', args: []);
  }

  /// `Total Price`
  String get totalPrice {
    return Intl.message('Total Price', name: 'totalPrice', desc: '', args: []);
  }

  /// `Sub Total`
  String get subTotal {
    return Intl.message('Sub Total', name: 'subTotal', desc: '', args: []);
  }

  /// `Total Vat`
  String get totalVat {
    return Intl.message('Total Vat', name: 'totalVat', desc: '', args: []);
  }

  /// `Total Discount`
  String get totalDiscount {
    return Intl.message(
      'Total Discount',
      name: 'totalDiscount',
      desc: '',
      args: [],
    );
  }

  /// `Payable`
  String get payable {
    return Intl.message('Payable', name: 'payable', desc: '', args: []);
  }

  /// `Paid`
  String get paid {
    return Intl.message('Paid', name: 'paid', desc: '', args: []);
  }

  /// `Service Charge`
  String get serviceCharge {
    return Intl.message(
      'Service Charge',
      name: 'serviceCharge',
      desc: '',
      args: [],
    );
  }

  /// `Total Sale`
  String get totalSale {
    return Intl.message('Total Sale', name: 'totalSale', desc: '', args: []);
  }

  /// `Total Purchase`
  String get totalPurchase {
    return Intl.message(
      'Total Purchase',
      name: 'totalPurchase',
      desc: '',
      args: [],
    );
  }

  /// `Received Amount`
  String get recivedAmount {
    return Intl.message(
      'Received Amount',
      name: 'recivedAmount',
      desc: '',
      args: [],
    );
  }

  /// `Customer Due`
  String get customerDue {
    return Intl.message(
      'Customer Due',
      name: 'customerDue',
      desc: '',
      args: [],
    );
  }

  /// `Supplier Due`
  String get supplierDue {
    return Intl.message(
      'Supplier Due',
      name: 'supplierDue',
      desc: '',
      args: [],
    );
  }

  /// `Select Parties`
  String get selectParties {
    return Intl.message(
      'Select Parties',
      name: 'selectParties',
      desc: '',
      args: [],
    );
  }

  /// `Details >`
  String get details {
    return Intl.message('Details >', name: 'details', desc: '', args: []);
  }

  /// `Show >`
  String get show {
    return Intl.message('Show >', name: 'show', desc: '', args: []);
  }

  /// `No Transaction Found`
  String get noTransactionFound {
    return Intl.message(
      'No Transaction Found',
      name: 'noTransactionFound',
      desc: '',
      args: [],
    );
  }

  /// `Ledger Details`
  String get ledgeDetails {
    return Intl.message(
      'Ledger Details',
      name: 'ledgeDetails',
      desc: '',
      args: [],
    );
  }

  /// `Status`
  String get status {
    return Intl.message('Status', name: 'status', desc: '', args: []);
  }

  /// `ItemName`
  String get itemName {
    return Intl.message('ItemName', name: 'itemName', desc: '', args: []);
  }

  /// `Purchase Price`
  String get purchasePrice {
    return Intl.message(
      'Purchase Price',
      name: 'purchasePrice',
      desc: '',
      args: [],
    );
  }

  /// `Sale Price`
  String get salePrice {
    return Intl.message('Sale Price', name: 'salePrice', desc: '', args: []);
  }

  /// `Profit`
  String get profit {
    return Intl.message('Profit', name: 'profit', desc: '', args: []);
  }

  /// `Loss`
  String get loss {
    return Intl.message('Loss', name: 'loss', desc: '', args: []);
  }

  /// `total`
  String get total {
    return Intl.message('total', name: 'total', desc: '', args: []);
  }

  /// `Total Profit`
  String get totalProfit {
    return Intl.message(
      'Total Profit',
      name: 'totalProfit',
      desc: '',
      args: [],
    );
  }

  /// `Total Loss`
  String get totalLoss {
    return Intl.message('Total Loss', name: 'totalLoss', desc: '', args: []);
  }

  /// `Unpaid`
  String get unPaid {
    return Intl.message('Unpaid', name: 'unPaid', desc: '', args: []);
  }

  /// `Loss/Profit`
  String get lossOrProfit {
    return Intl.message(
      'Loss/Profit',
      name: 'lossOrProfit',
      desc: '',
      args: [],
    );
  }

  /// `Sale Amount`
  String get saleAmount {
    return Intl.message('Sale Amount', name: 'saleAmount', desc: '', args: []);
  }

  /// `Profit(+)`
  String get profitPlus {
    return Intl.message('Profit(+)', name: 'profitPlus', desc: '', args: []);
  }

  /// `Profit(-)`
  String get profitMinus {
    return Intl.message('Profit(-)', name: 'profitMinus', desc: '', args: []);
  }

  /// `Your Payment is canceled`
  String get yourPaymentIsCancelled {
    return Intl.message(
      'Your Payment is canceled',
      name: 'yourPaymentIsCancelled',
      desc: '',
      args: [],
    );
  }

  /// `Your Payment is successfully`
  String get yourPaymentIsSuccessfully {
    return Intl.message(
      'Your Payment is successfully',
      name: 'yourPaymentIsSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Hold`
  String get hold {
    return Intl.message('Hold', name: 'hold', desc: '', args: []);
  }

  /// `Hold Number`
  String get holdNumber {
    return Intl.message('Hold Number', name: 'holdNumber', desc: '', args: []);
  }

  /// `Select Serial Number`
  String get selectSerialNumber {
    return Intl.message(
      'Select Serial Number',
      name: 'selectSerialNumber',
      desc: '',
      args: [],
    );
  }

  /// `Serial Number`
  String get serialNumber {
    return Intl.message(
      'Serial Number',
      name: 'serialNumber',
      desc: '',
      args: [],
    );
  }

  /// `Search Serial Number`
  String get searchSerialNumber {
    return Intl.message(
      'Search Serial Number',
      name: 'searchSerialNumber',
      desc: '',
      args: [],
    );
  }

  /// `No Serial Number Found`
  String get noSerialNumberFound {
    return Intl.message(
      'No Serial Number Found',
      name: 'noSerialNumberFound',
      desc: '',
      args: [],
    );
  }

  /// `Name or Code or Category`
  String get nameCodeOrCateogry {
    return Intl.message(
      'Name or Code or Category',
      name: 'nameCodeOrCateogry',
      desc: '',
      args: [],
    );
  }

  /// `Vat/GST`
  String get vatOrgst {
    return Intl.message('Vat/GST', name: 'vatOrgst', desc: '', args: []);
  }

  /// `Discount`
  String get discount {
    return Intl.message('Discount', name: 'discount', desc: '', args: []);
  }

  /// `Are you want to create this Quotation?`
  String get areYouWantToCreateThisQuation {
    return Intl.message(
      'Are you want to create this Quotation?',
      name: 'areYouWantToCreateThisQuation',
      desc: '',
      args: [],
    );
  }

  /// `Update your plan first\nSale Limit is over.`
  String get updateYourPlanFirst {
    return Intl.message(
      'Update your plan first\\nSale Limit is over.',
      name: 'updateYourPlanFirst',
      desc: '',
      args: [],
    );
  }

  /// `Quotation`
  String get quotation {
    return Intl.message('Quotation', name: 'quotation', desc: '', args: []);
  }

  /// `Add Product`
  String get addProduct {
    return Intl.message('Add Product', name: 'addProduct', desc: '', args: []);
  }

  /// `Total Product`
  String get totalProduct {
    return Intl.message(
      'Total Product',
      name: 'totalProduct',
      desc: '',
      args: [],
    );
  }

  /// `Shipping/Service`
  String get shpingOrServices {
    return Intl.message(
      'Shipping/Service',
      name: 'shpingOrServices',
      desc: '',
      args: [],
    );
  }

  /// `Add Item Category`
  String get addItemCategory {
    return Intl.message(
      'Add Item Category',
      name: 'addItemCategory',
      desc: '',
      args: [],
    );
  }

  /// `Select Variations:`
  String get selectVariations {
    return Intl.message(
      'Select Variations:',
      name: 'selectVariations',
      desc: '',
      args: [],
    );
  }

  /// `Size`
  String get size {
    return Intl.message('Size', name: 'size', desc: '', args: []);
  }

  /// `Color`
  String get color {
    return Intl.message('Color', name: 'color', desc: '', args: []);
  }

  /// `Weight`
  String get wight {
    return Intl.message('Weight', name: 'wight', desc: '', args: []);
  }

  /// `Capacity`
  String get capacity {
    return Intl.message('Capacity', name: 'capacity', desc: '', args: []);
  }

  /// `Warranty`
  String get warranty {
    return Intl.message('Warranty', name: 'warranty', desc: '', args: []);
  }

  /// `Add Brand`
  String get addBrand {
    return Intl.message('Add Brand', name: 'addBrand', desc: '', args: []);
  }

  /// `Brand Name`
  String get brandName {
    return Intl.message('Brand Name', name: 'brandName', desc: '', args: []);
  }

  /// `Enter Brand Name`
  String get enterBrandName {
    return Intl.message(
      'Enter Brand Name',
      name: 'enterBrandName',
      desc: '',
      args: [],
    );
  }

  /// `Add Unit`
  String get addUnit {
    return Intl.message('Add Unit', name: 'addUnit', desc: '', args: []);
  }

  /// `Unit Name`
  String get unitName {
    return Intl.message('Unit Name', name: 'unitName', desc: '', args: []);
  }

  /// `Enter Unit Name`
  String get enterUnitName {
    return Intl.message(
      'Enter Unit Name',
      name: 'enterUnitName',
      desc: '',
      args: [],
    );
  }

  /// `Product Name*`
  String get productNam {
    return Intl.message(
      'Product Name*',
      name: 'productNam',
      desc: '',
      args: [],
    );
  }

  /// `Enter Product Name`
  String get enterProductName {
    return Intl.message(
      'Enter Product Name',
      name: 'enterProductName',
      desc: '',
      args: [],
    );
  }

  /// `ProductType`
  String get productType {
    return Intl.message('ProductType', name: 'productType', desc: '', args: []);
  }

  /// `Enter Product Type`
  String get enterProductType {
    return Intl.message(
      'Enter Product Type',
      name: 'enterProductType',
      desc: '',
      args: [],
    );
  }

  /// `Product Warranty`
  String get productWaranty {
    return Intl.message(
      'Product Warranty',
      name: 'productWaranty',
      desc: '',
      args: [],
    );
  }

  /// `Enter Warranty`
  String get enterWarranty {
    return Intl.message(
      'Enter Warranty',
      name: 'enterWarranty',
      desc: '',
      args: [],
    );
  }

  /// `Warranty`
  String get warrantys {
    return Intl.message('Warranty', name: 'warrantys', desc: '', args: []);
  }

  /// `Select Warranty ATime`
  String get selectWarrantyTime {
    return Intl.message(
      'Select Warranty ATime',
      name: 'selectWarrantyTime',
      desc: '',
      args: [],
    );
  }

  /// `Brand`
  String get brand {
    return Intl.message('Brand', name: 'brand', desc: '', args: []);
  }

  /// `Select Product Brand`
  String get selectProductBrand {
    return Intl.message(
      'Select Product Brand',
      name: 'selectProductBrand',
      desc: '',
      args: [],
    );
  }

  /// `Product Code*`
  String get productCod {
    return Intl.message(
      'Product Code*',
      name: 'productCod',
      desc: '',
      args: [],
    );
  }

  /// `Enter Product Code`
  String get enterProductCode {
    return Intl.message(
      'Enter Product Code',
      name: 'enterProductCode',
      desc: '',
      args: [],
    );
  }

  /// `Enter Product Quantity`
  String get enterProductQuantity {
    return Intl.message(
      'Enter Product Quantity',
      name: 'enterProductQuantity',
      desc: '',
      args: [],
    );
  }

  /// `Quantity*`
  String get Quantity {
    return Intl.message('Quantity*', name: 'Quantity', desc: '', args: []);
  }

  /// `Product Unit`
  String get productUnit {
    return Intl.message(
      'Product Unit',
      name: 'productUnit',
      desc: '',
      args: [],
    );
  }

  /// `Enter Purchase Price`
  String get enterPurchasePrice {
    return Intl.message(
      'Enter Purchase Price',
      name: 'enterPurchasePrice',
      desc: '',
      args: [],
    );
  }

  /// `Sale Price*`
  String get salePrices {
    return Intl.message('Sale Price*', name: 'salePrices', desc: '', args: []);
  }

  /// `Dealer Price`
  String get dealerPrice {
    return Intl.message(
      'Dealer Price',
      name: 'dealerPrice',
      desc: '',
      args: [],
    );
  }

  /// `Enter Dealer Price`
  String get enterDealePrice {
    return Intl.message(
      'Enter Dealer Price',
      name: 'enterDealePrice',
      desc: '',
      args: [],
    );
  }

  /// `WholeSale Price`
  String get wholeSaleprice {
    return Intl.message(
      'WholeSale Price',
      name: 'wholeSaleprice',
      desc: '',
      args: [],
    );
  }

  /// `Enter Price`
  String get enterPrice {
    return Intl.message('Enter Price', name: 'enterPrice', desc: '', args: []);
  }

  /// `Manufacturer`
  String get manufacturer {
    return Intl.message(
      'Manufacturer',
      name: 'manufacturer',
      desc: '',
      args: [],
    );
  }

  /// `Enter Manufacturer Name`
  String get enterManufacturerName {
    return Intl.message(
      'Enter Manufacturer Name',
      name: 'enterManufacturerName',
      desc: '',
      args: [],
    );
  }

  /// `Serial Number`
  String get serialNumbers {
    return Intl.message(
      'Serial Number',
      name: 'serialNumbers',
      desc: '',
      args: [],
    );
  }

  /// `Enter Serial Number`
  String get enterSerialNumber {
    return Intl.message(
      'Enter Serial Number',
      name: 'enterSerialNumber',
      desc: '',
      args: [],
    );
  }

  /// `No Serial Number Found`
  String get nosSerialNumberFound {
    return Intl.message(
      'No Serial Number Found',
      name: 'nosSerialNumberFound',
      desc: '',
      args: [],
    );
  }

  /// `Product List`
  String get productList {
    return Intl.message(
      'Product List',
      name: 'productList',
      desc: '',
      args: [],
    );
  }

  /// `Search By Name`
  String get searchByName {
    return Intl.message(
      'Search By Name',
      name: 'searchByName',
      desc: '',
      args: [],
    );
  }

  /// `Retailer`
  String get retailer {
    return Intl.message('Retailer', name: 'retailer', desc: '', args: []);
  }

  /// `Dealer`
  String get dealer {
    return Intl.message('Dealer', name: 'dealer', desc: '', args: []);
  }

  /// `Wholesale`
  String get wholesale {
    return Intl.message('Wholesale', name: 'wholesale', desc: '', args: []);
  }

  /// `Expense`
  String get expense {
    return Intl.message('Expense', name: 'expense', desc: '', args: []);
  }

  /// `Total Payable`
  String get totalPayable {
    return Intl.message(
      'Total Payable',
      name: 'totalPayable',
      desc: '',
      args: [],
    );
  }

  /// `Total Amount`
  String get totalAmount {
    return Intl.message(
      'Total Amount',
      name: 'totalAmount',
      desc: '',
      args: [],
    );
  }

  /// `Search by invoice or name`
  String get searchByInvoiceOrName {
    return Intl.message(
      'Search by invoice or name',
      name: 'searchByInvoiceOrName',
      desc: '',
      args: [],
    );
  }

  /// `Invoice`
  String get invoice {
    return Intl.message('Invoice', name: 'invoice', desc: '', args: []);
  }

  /// `Loss(-)`
  String get lossminus {
    return Intl.message('Loss(-)', name: 'lossminus', desc: '', args: []);
  }

  /// `Your Payment is canceled`
  String get yourPaymentIscancelled {
    return Intl.message(
      'Your Payment is canceled',
      name: 'yourPaymentIscancelled',
      desc: '',
      args: [],
    );
  }

  /// `Previous Due:`
  String get previousDue {
    return Intl.message(
      'Previous Due:',
      name: 'previousDue',
      desc: '',
      args: [],
    );
  }

  /// `Calculator:`
  String get calculator {
    return Intl.message('Calculator:', name: 'calculator', desc: '', args: []);
  }

  /// `DashBoard`
  String get dashBoard {
    return Intl.message('DashBoard', name: 'dashBoard', desc: '', args: []);
  }

  /// `Price`

  /// `Create`
  String get create {
    return Intl.message('Create', name: 'create', desc: '', args: []);
  }

  /// `Payment`
  String get payment {
    return Intl.message('Payment', name: 'payment', desc: '', args: []);
  }

  /// `Enter Paying Amount`
  String get enterPayingAmount {
    return Intl.message(
      'Enter Paying Amount',
      name: 'enterPayingAmount',
      desc: '',
      args: [],
    );
  }

  /// `Enter Category Name`
  String get enterCategoryName {
    return Intl.message(
      'Enter Category Name',
      name: 'enterCategoryName',
      desc: '',
      args: [],
    );
  }

  /// `Product Size`
  String get productSize {
    return Intl.message(
      'Product Size',
      name: 'productSize',
      desc: '',
      args: [],
    );
  }

  /// `Enter Product Size`
  String get enterProductSize {
    return Intl.message(
      'Enter Product Size',
      name: 'enterProductSize',
      desc: '',
      args: [],
    );
  }

  /// `Product Color`
  String get productColor {
    return Intl.message(
      'Product Color',
      name: 'productColor',
      desc: '',
      args: [],
    );
  }

  /// `Enter Product Color`
  String get enterProductColor {
    return Intl.message(
      'Enter Product Color',
      name: 'enterProductColor',
      desc: '',
      args: [],
    );
  }

  /// `Product weight`
  String get productWeight {
    return Intl.message(
      'Product weight',
      name: 'productWeight',
      desc: '',
      args: [],
    );
  }

  /// `Enter Product Weight`
  String get enterProductWeight {
    return Intl.message(
      'Enter Product Weight',
      name: 'enterProductWeight',
      desc: '',
      args: [],
    );
  }

  /// `Product Capacity`
  String get productcapacity {
    return Intl.message(
      'Product Capacity',
      name: 'productcapacity',
      desc: '',
      args: [],
    );
  }

  /// `Enter Product Capacity`
  String get enterProductCapacity {
    return Intl.message(
      'Enter Product Capacity',
      name: 'enterProductCapacity',
      desc: '',
      args: [],
    );
  }

  /// `Enter Sale Price`
  String get enterSalePrice {
    return Intl.message(
      'Enter Sale Price',
      name: 'enterSalePrice',
      desc: '',
      args: [],
    );
  }

  /// `Add`
  String get add {
    return Intl.message('Add', name: 'add', desc: '', args: []);
  }

  /// `Product Category`
  String get productCategory {
    return Intl.message(
      'Product Category',
      name: 'productCategory',
      desc: '',
      args: [],
    );
  }

  /// `Enter Product Unit`
  String get enterProductUnit {
    return Intl.message(
      'Enter Product Unit',
      name: 'enterProductUnit',
      desc: '',
      args: [],
    );
  }

  /// `Product Name`
  String get productName {
    return Intl.message(
      'Product Name',
      name: 'productName',
      desc: '',
      args: [],
    );
  }

  /// `No Product Found`
  String get noProductFound {
    return Intl.message(
      'No Product Found',
      name: 'noProductFound',
      desc: '',
      args: [],
    );
  }

  /// `Adding Serial Number?`
  String get addingSerialNumber {
    return Intl.message(
      'Adding Serial Number?',
      name: 'addingSerialNumber',
      desc: '',
      args: [],
    );
  }


  /// `Edit/Add Serial:`
  String get editOrAddSerial {
    return Intl.message(
      'Edit/Add Serial:',
      name: 'editOrAddSerial',
      desc: '',
      args: [],
    );
  }

  /// `Enter Wholesale Price`
  String get enterWholeSalePrice {
    return Intl.message(
      'Enter Wholesale Price',
      name: 'enterWholeSalePrice',
      desc: '',
      args: [],
    );
  }

  /// `Invoice:`
  String get invoiceCo {
    return Intl.message('Invoice:', name: 'invoiceCo', desc: '', args: []);
  }

  /// `Categories`
  String get categories {
    return Intl.message('Categories', name: 'categories', desc: '', args: []);
  }

  /// `Purchase List`
  String get purchaseList {
    return Intl.message(
      'Purchase List',
      name: 'purchaseList',
      desc: '',
      args: [],
    );
  }

  /// `Print`
  String get print {
    return Intl.message('Print', name: 'print', desc: '', args: []);
  }

  /// `No purchase transaction found`
  String get noPurchaseTransactionFound {
    return Intl.message(
      'No purchase transaction found',
      name: 'noPurchaseTransactionFound',
      desc: '',
      args: [],
    );
  }

  /// `Quotation List`
  String get quotationList {
    return Intl.message(
      'Quotation List',
      name: 'quotationList',
      desc: '',
      args: [],
    );
  }

  /// `Are you want to delete this Quotation?`
  String get areYouWantToDeleteThisQuotion {
    return Intl.message(
      'Are you want to delete this Quotation?',
      name: 'areYouWantToDeleteThisQuotion',
      desc: '',
      args: [],
    );
  }

  /// `Convert To Sale`
  String get convertToSale {
    return Intl.message(
      'Convert To Sale',
      name: 'convertToSale',
      desc: '',
      args: [],
    );
  }

  /// `No Quotation Found`
  String get noQuotionFound {
    return Intl.message(
      'No Quotation Found',
      name: 'noQuotionFound',
      desc: '',
      args: [],
    );
  }

  /// `Stock Report`
  String get stockReport {
    return Intl.message(
      'Stock Report',
      name: 'stockReport',
      desc: '',
      args: [],
    );
  }

  /// `PRODUCT NAME`
  String get PRODUCTNAME {
    return Intl.message(
      'PRODUCT NAME',
      name: 'PRODUCTNAME',
      desc: '',
      args: [],
    );
  }

  /// `CATEGORY`
  String get CATEGORY {
    return Intl.message('CATEGORY', name: 'CATEGORY', desc: '', args: []);
  }

  /// `PRICE`
  String get PRICE {
    return Intl.message('PRICE', name: 'PRICE', desc: '', args: []);
  }

  /// `QTY`
  String get QTY {
    return Intl.message('QTY', name: 'QTY', desc: '', args: []);
  }

  /// `STATUS`
  String get STATUS {
    return Intl.message('STATUS', name: 'STATUS', desc: '', args: []);
  }

  /// `TOTAL VALUE`
  String get TOTALVALUE {
    return Intl.message('TOTAL VALUE', name: 'TOTALVALUE', desc: '', args: []);
  }

  /// `NO Report Found`
  String get noReportFound {
    return Intl.message(
      'NO Report Found',
      name: 'noReportFound',
      desc: '',
      args: [],
    );
  }

  /// `Remaining Balance`
  String get remainingBalance {
    return Intl.message(
      'Remaining Balance',
      name: 'remainingBalance',
      desc: '',
      args: [],
    );
  }

  /// `Total Payment In`
  String get totalpaymentIn {
    return Intl.message(
      'Total Payment In',
      name: 'totalpaymentIn',
      desc: '',
      args: [],
    );
  }

  /// `Total Payment Out`
  String get totalPaymentOut {
    return Intl.message(
      'Total Payment Out',
      name: 'totalPaymentOut',
      desc: '',
      args: [],
    );
  }

  /// `Daily Transaction`
  String get dailyTransaction {
    return Intl.message(
      'Daily Transaction',
      name: 'dailyTransaction',
      desc: '',
      args: [],
    );
  }

  /// `Payment In`
  String get paymentIn {
    return Intl.message('Payment In', name: 'paymentIn', desc: '', args: []);
  }

  /// `Payment Out`
  String get paymentOut {
    return Intl.message('Payment Out', name: 'paymentOut', desc: '', args: []);
  }

  /// `Balance`
  String get balance {
    return Intl.message('Balance', name: 'balance', desc: '', args: []);
  }

  /// `Total Paid`
  String get totalPaid {
    return Intl.message('Total Paid', name: 'totalPaid', desc: '', args: []);
  }

  /// `Due Transaction`
  String get dueTransaction {
    return Intl.message(
      'Due Transaction',
      name: 'dueTransaction',
      desc: '',
      args: [],
    );
  }

  /// `Download PDF`
  String get downloadPDF {
    return Intl.message(
      'Download PDF',
      name: 'downloadPDF',
      desc: '',
      args: [],
    );
  }

  /// `Customer Type`
  String get customerType {
    return Intl.message(
      'Customer Type',
      name: 'customerType',
      desc: '',
      args: [],
    );
  }

  /// `Please Add Customer`
  String get pleaseAddCustomer {
    return Intl.message(
      'Please Add Customer',
      name: 'pleaseAddCustomer',
      desc: '',
      args: [],
    );
  }

  /// `Purchase Transaction`
  String get purchaseTransaction {
    return Intl.message(
      'Purchase Transaction',
      name: 'purchaseTransaction',
      desc: '',
      args: [],
    );
  }

  /// `Print PDF`
  String get printPdf {
    return Intl.message('Print PDF', name: 'printPdf', desc: '', args: []);
  }

  /// `Sale Transactions (Quotation Sale History)`
  String get saleTransactionQuatationHistory {
    return Intl.message(
      'Sale Transactions (Quotation Sale History)',
      name: 'saleTransactionQuatationHistory',
      desc: '',
      args: [],
    );
  }

  /// `ADD SALE`
  String get ADDSALE {
    return Intl.message('ADD SALE', name: 'ADDSALE', desc: '', args: []);
  }

  /// `Search.......`
  String get search {
    return Intl.message('Search.......', name: 'search', desc: '', args: []);
  }

  /// `Transaction Report`
  String get transactionReport {
    return Intl.message(
      'Transaction Report',
      name: 'transactionReport',
      desc: '',
      args: [],
    );
  }

  /// `Sale Transaction`
  String get saleTransaction {
    return Intl.message(
      'Sale Transaction',
      name: 'saleTransaction',
      desc: '',
      args: [],
       );
  }

  /// `Total Returns`
  String get totalReturns {
    return Intl.message(
      'Total Returns',
      name: 'totalReturns',
      desc: '',
      args: [],
    );
  }

  /// `Total Return Amount`
  String get totalReturnAmount {
    return Intl.message(
      'Total Return Amount',
      name: 'totalReturnAmount',
      desc: '',
      args: [],
    );
  }

  /// `Sale Return`
  String get saleReturn {
    return Intl.message('Sale Return', name: 'saleReturn', desc: '', args: []);
  }

  /// `No Sale Transaction Found`
  String get noSaleTransaactionFound {
    return Intl.message(
      'No Sale Transaction Found',
      name: 'noSaleTransaactionFound',
      desc: '',
      args: [],
    );
  }

  /// `Sale List`
  String get saleList {
    return Intl.message('Sale List', name: 'saleList', desc: '', args: []);
  }

  /// `Reports`
  String get reports {
    return Intl.message('Reports', name: 'reports', desc: '', args: []);
  }

  /// `Are you want to return this sale?`
  String get areYouWantToReturnThisSale {
    return Intl.message(
      'Are you want to return this sale?',
      name: 'areYouWantToReturnThisSale',
      desc: '',
      args: [],
    );
  }

  /// `No`
  String get no {
    return Intl.message('No', name: 'no', desc: '', args: []);
  }

  /// `Yes Return`
  String get yesReturn {
    return Intl.message('Yes Return', name: 'yesReturn', desc: '', args: []);
  }

  /// `Setting`
  String get setting {
    return Intl.message('Setting', name: 'setting', desc: '', args: []);
  }

  /// `Upload An Invoice Logo`
  String get uploadAnInvoiceLogo {
    return Intl.message(
      'Upload An Invoice Logo',
      name: 'uploadAnInvoiceLogo',
      desc: '',
      args: [],
    );
  }

  /// `Show Logo in Invoice?`
  String get showLogoInInvoice {
    return Intl.message(
      'Show Logo in Invoice?',
      name: 'showLogoInInvoice',
      desc: '',
      args: [],
    );
  }

  /// `Logo position in invoice?`
  String get logoPositionInInvoice {
    return Intl.message(
      'Logo position in invoice?',
      name: 'logoPositionInInvoice',
      desc: '',
      args: [],
    );
  }

  /// `Left`
  String get left {
    return Intl.message('Left', name: 'left', desc: '', args: []);
  }

  /// `Right`
  String get right {
    return Intl.message('Right', name: 'right', desc: '', args: []);
  }

  /// `Company Address`
  String get companyAddress {
    return Intl.message(
      'Company Address',
      name: 'companyAddress',
      desc: '',
      args: [],
    );
  }

  /// `Enter Your Company Address`
  String get enterYourCompanyAddress {
    return Intl.message(
      'Enter Your Company Address',
      name: 'enterYourCompanyAddress',
      desc: '',
      args: [],
    );
  }

  /// `Company phone number`
  String get companyPhoneNumber {
    return Intl.message(
      'Company phone number',
      name: 'companyPhoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Company email address`
  String get companyEmailAddress {
    return Intl.message(
      'Company email address',
      name: 'companyEmailAddress',
      desc: '',
      args: [],
    );
  }

  /// `Enter company phone number`
  String get enterCompanyPhoneNumber {
    return Intl.message(
      'Enter company phone number',
      name: 'enterCompanyPhoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Enter company email address`
  String get enterCompanyEmailAddress {
    return Intl.message(
      'Enter company email address',
      name: 'enterCompanyEmailAddress',
      desc: '',
      args: [],
    );
  }

  /// `Company Website Url`
  String get companyWebsiteUrl {
    return Intl.message(
      'Company Website Url',
      name: 'companyWebsiteUrl',
      desc: '',
      args: [],
    );
  }

  /// `Enter company website url`
  String get enterCompanyWebsiteUrl {
    return Intl.message(
      'Enter company website url',
      name: 'enterCompanyWebsiteUrl',
      desc: '',
      args: [],
    );
  }

  /// `Company Description`
  String get companyDescription {
    return Intl.message(
      'Company Description',
      name: 'companyDescription',
      desc: '',
      args: [],
    );
  }

  /// `Enter Company Description`
  String get enterCompanyDesciption {
    return Intl.message(
      'Enter Company Description',
      name: 'enterCompanyDesciption',
      desc: '',
      args: [],
    );
  }

  /// `Save Changes`
  String get saveChanges {
    return Intl.message(
      'Save Changes',
      name: 'saveChanges',
      desc: '',
      args: [],
    );
  }

  /// `KYC Verification`
  String get kycVerification {
    return Intl.message(
      'KYC Verification',
      name: 'kycVerification',
      desc: '',
      args: [],
    );
  }

  /// `Identity Verify`
  String get identityVerify {
    return Intl.message(
      'Identity Verify',
      name: 'identityVerify',
      desc: '',
      args: [],
    );
  }

  /// `You need to identity verify before buying messages`
  String get yourNeedToIdentityVerify {
    return Intl.message(
      'You need to identity verify before buying messages',
      name: 'yourNeedToIdentityVerify',
      desc: '',
      args: [],
    );
  }

  /// `Government Id`
  String get govermentId {
    return Intl.message(
      'Government Id',
      name: 'govermentId',
      desc: '',
      args: [],
    );
  }

  /// `Take a driver's license, national identity card or passport photo`
  String get takeADriveLisense {
    return Intl.message(
      'Take a driver\'s license, national identity card or passport photo',
      name: 'takeADriveLisense',
      desc: '',
      args: [],
    );
  }

  /// `Add Documents`
  String get addDucument {
    return Intl.message(
      'Add Documents',
      name: 'addDucument',
      desc: '',
      args: [],
    );
  }

  /// `You need to identity verify before buying messages`
  String get youNeedToIdentityVerifySms {
    return Intl.message(
      'You need to identity verify before buying messages',
      name: 'youNeedToIdentityVerifySms',
      desc: '',
      args: [],
    );
  }

  /// `Wholesaler`
  String get wholeSeller {
    return Intl.message('Wholesaler', name: 'wholeSeller', desc: '', args: []);
  }

  /// `Enter message Content`
  String get enterSmsContent {
    return Intl.message(
      'Enter message Content',
      name: 'enterSmsContent',
      desc: '',
      args: [],
    );
  }

  /// `Send message`
  String get sendMessage {
    return Intl.message(
      'Send message',
      name: 'sendMessage',
      desc: '',
      args: [],
    );
  }

  /// `Buy sms`
  String get buySms {
    return Intl.message('Buy sms', name: 'buySms', desc: '', args: []);
  }

  /// `Supplier List`
  String get supplierList {
    return Intl.message(
      'Supplier List',
      name: 'supplierList',
      desc: '',
      args: [],
    );
  }

  /// `Add Supplier`
  String get addSupplier {
    return Intl.message(
      'Add Supplier',
      name: 'addSupplier',
      desc: '',
      args: [],
    );
  }

  /// `No Supplier Found`
  String get noSupplierFound {
    return Intl.message(
      'No Supplier Found',
      name: 'noSupplierFound',
      desc: '',
      args: [],
    );
  }

  /// `Check Warranty`
  String get checkWarranty {
    return Intl.message(
      'Check Warranty',
      name: 'checkWarranty',
      desc: '',
      args: [],
    );
  }

  /// `Customer Invoices`
  String get customerInvoices {
    return Intl.message(
      'Customer Invoices',
      name: 'customerInvoices',
      desc: '',
      args: [],
    );
  }

  /// `Supplier Invoice`
  String get supplierInvoice {
    return Intl.message(
      'Supplier Invoice',
      name: 'supplierInvoice',
      desc: '',
      args: [],
    );
  }

  /// `Add Item`
  String get addItem {
    return Intl.message('Add Item', name: 'addItem', desc: '', args: []);
  }

  /// `No Invoice Found`
  String get noInvoiceFound {
    return Intl.message(
      'No Invoice Found',
      name: 'noInvoiceFound',
      desc: '',
      args: [],
    );
  }

  /// `Stock`
  String get stock {
    return Intl.message('Stock', name: 'stock', desc: '', args: []);
  }

  /// `Enter Stock Amount`
  String get enterStockAmount {
    return Intl.message(
      'Enter Stock Amount',
      name: 'enterStockAmount',
      desc: '',
      args: [],
    );
  }

  /// `Discount Price`
  String get discountPrice {
    return Intl.message(
      'Discount Price',
      name: 'discountPrice',
      desc: '',
      args: [],
    );
  }

  /// `Enter Discount Price`
  String get enterDiscountPrice {
    return Intl.message(
      'Enter Discount Price',
      name: 'enterDiscountPrice',
      desc: '',
      args: [],
    );
  }

  /// `Date Time`
  String get dateTime {
    return Intl.message('Date Time', name: 'dateTime', desc: '', args: []);
  }

  /// `Walk in Customer`
  String get walkInCustomer {
    return Intl.message(
      'Walk in Customer',
      name: 'walkInCustomer',
      desc: '',
      args: [],
    );
  }

  /// `Sale Details`
  String get saleDetails {
    return Intl.message(
      'Sale Details',
      name: 'saleDetails',
      desc: '',
      args: [],
    );
  }

  /// `Customer: Walk-in Customer`
  String get customerWalkIncostomer {
    return Intl.message(
      'Customer: Walk-in Customer',
      name: 'customerWalkIncostomer',
      desc: '',
      args: [],
    );
  }

  /// `Item`
  String get item {
    return Intl.message('Item', name: 'item', desc: '', args: []);
  }

  /// `Camera`
  String get camera {
    return Intl.message('Camera', name: 'camera', desc: '', args: []);
  }

  /// `Total Item : 2`
  String get totalItem2 {
    return Intl.message(
      'Total Item : 2',
      name: 'totalItem2',
      desc: '',
      args: [],
    );
  }

  /// `Shipping/Other`
  String get shipingOrOther {
    return Intl.message(
      'Shipping/Other',
      name: 'shipingOrOther',
      desc: '',
      args: [],
    );
  }

  /// `Your Due Sales`
  String get yourDueSales {
    return Intl.message(
      'Your Due Sales',
      name: 'yourDueSales',
      desc: '',
      args: [],
    );
  }

  /// `Your All Sales`
  String get yourAllSales {
    return Intl.message(
      'Your All Sales',
      name: 'yourAllSales',
      desc: '',
      args: [],
    );
  }

  /// `Invoice NO..`
  String get invoiceHint {
    return Intl.message(
      'Invoice NO..',
      name: 'invoiceHint',
      desc: '',
      args: [],
    );
  }

  /// `Customer`
  String get customer {
    return Intl.message('Customer', name: 'customer', desc: '', args: []);
  }

  /// `Due amount will show here if available`
  String get dueAmountWillShowHere {
    return Intl.message(
      'Due amount will show here if available',
      name: 'dueAmountWillShowHere',
      desc: '',
      args: [],
    );
  }

  /// `This customer has no due`
  String get thisCustmerHasNoDue {
    return Intl.message(
      'This customer has no due',
      name: 'thisCustmerHasNoDue',
      desc: '',
      args: [],
    );
  }

  /// `Please Select A Customer`
  String get pleaseSelectACustomer {
    return Intl.message(
      'Please Select A Customer',
      name: 'pleaseSelectACustomer',
      desc: '',
      args: [],
    );
  }

  /// `Please Add A Sale`
  String get pleaseAddASale {
    return Intl.message(
      'Please Add A Sale',
      name: 'pleaseAddASale',
      desc: '',
      args: [],
    );
  }

  /// `Your all sale list`
  String get yourAllSaleList {
    return Intl.message(
      'Your all sale list',
      name: 'yourAllSaleList',
      desc: '',
      args: [],
    );
  }

  /// `Changeable Amount`
  String get changeableAmount {
    return Intl.message(
      'Changeable Amount',
      name: 'changeableAmount',
      desc: '',
      args: [],
    );
  }

  /// `Sales`
  String get sales {
    return Intl.message('Sales', name: 'sales', desc: '', args: []);
  }

  /// `Due List`
  String get dueList {
    return Intl.message('Due List', name: 'dueList', desc: '', args: []);
  }

  /// `Ledger`
  String get ledger {
    return Intl.message('Ledger', name: 'ledger', desc: '', args: []);
  }

  /// `Transaction`
  String get transaction {
    return Intl.message('Transaction', name: 'transaction', desc: '', args: []);
  }

  /// `Subscription`
  String get subciption {
    return Intl.message('Subscription', name: 'subciption', desc: '', args: []);
  }

  /// `Upgrade On Mobile App`
  String get upgradeOnMobileApp {
    return Intl.message(
      'Upgrade On Mobile App',
      name: 'upgradeOnMobileApp',
      desc: '',
      args: [],
    );
  }

  /// `POS Sale`
  String get POSSale {
    return Intl.message('POS Sale', name: 'POSSale', desc: '', args: []);
  }

  /// `Search Anythings...`
  String get searchAnyThing {
    return Intl.message(
      'Search Anythings...',
      name: 'searchAnyThing',
      desc: '',
      args: [],
    );
  }

  /// `Sale`
  String get sale {
    return Intl.message('Sale', name: 'sale', desc: '', args: []);
  }

  /// `Log out`
  String get logOut {
    return Intl.message('Log out', name: 'logOut', desc: '', args: []);
  }

  /// `Cash & Bank`
  String get cashAndBank {
    return Intl.message('Cash & Bank', name: 'cashAndBank', desc: '', args: []);
  }

  /// `Cash In Hand`
  String get cashInHand {
    return Intl.message('Cash In Hand', name: 'cashInHand', desc: '', args: []);
  }

  /// `Bank Accounts`
  String get bankAccounts {
    return Intl.message(
      'Bank Accounts',
      name: 'bankAccounts',
      desc: '',
      args: [],
    );
  }

  /// `Creative Hub`
  String get creativeHub {
    return Intl.message(
      'Creative Hub',
      name: 'creativeHub',
      desc: '',
      args: [],
    );
  }

  /// `Open Cheques`
  String get openCheques {
    return Intl.message(
      'Open Cheques',
      name: 'openCheques',
      desc: '',
      args: [],
    );
  }

  /// `Loan Accounts`
  String get loanAccounts {
    return Intl.message(
      'Loan Accounts',
      name: 'loanAccounts',
      desc: '',
      args: [],
    );
  }

  /// `Share`
  String get share {
    return Intl.message('Share', name: 'share', desc: '', args: []);
  }

  /// `Preview`
  String get preview {
    return Intl.message('Preview', name: 'preview', desc: '', args: []);
  }

  /// `Due Collection`
  String get dueCollection {
    return Intl.message(
      'Due Collection',
      name: 'dueCollection',
      desc: '',
      args: [],
    );
  }

  /// `Customer of the month`
  String get customerOfTheMonth {
    return Intl.message(
      'Customer of the month',
      name: 'customerOfTheMonth',
      desc: '',
      args: [],
    );
  }

  /// `Top Selling Product`
  String get topSellingProduct {
    return Intl.message(
      'Top Selling Product',
      name: 'topSellingProduct',
      desc: '',
      args: [],
    );
  }

  /// `Statistic`
  String get statistic {
    return Intl.message('Statistic', name: 'statistic', desc: '', args: []);
  }

  /// `Stock Value`
  String get stockValues {
    return Intl.message('Stock Value', name: 'stockValues', desc: '', args: []);
  }

  /// `Low Stock`
  String get lowStock {
    return Intl.message('Low Stock', name: 'lowStock', desc: '', args: []);
  }

  /// `Top 5 purchasing product of the month`
  String get fivePurchase {
    return Intl.message(
      'Top 5 purchasing product of the month',
      name: 'fivePurchase',
      desc: '',
      args: [],
    );
  }

  /// `Recent Sales`
  String get recentSale {
    return Intl.message('Recent Sales', name: 'recentSale', desc: '', args: []);
  }

  /// `Total Sales`
  String get tSale {
    return Intl.message('Total Sales', name: 'tSale', desc: '', args: []);
  }

  /// `Sale Amount`
  String get sAmount {
    return Intl.message('Sale Amount', name: 'sAmount', desc: '', args: []);
  }

  /// `Expense`
  String get expenses {
    return Intl.message('Expense', name: 'expenses', desc: '', args: []);
  }

  /// `Income`
  String get inc {
    return Intl.message('Income', name: 'inc', desc: '', args: []);
  }

  /// `Profile`
  String get prof {
    return Intl.message('Profile', name: 'prof', desc: '', args: []);
  }

  /// `Uploading`
  String get uploading {
    return Intl.message('Uploading', name: 'uploading', desc: '', args: []);
  }

  /// `Upload Successful`
  String get uploadSuccessful {
    return Intl.message(
      'Upload Successful',
      name: 'uploadSuccessful',
      desc: '',
      args: [],
    );
  }

  /// `Select Shop Category`
  String get selectShopCategory {
    return Intl.message(
      'Select Shop Category',
      name: 'selectShopCategory',
      desc: '',
      args: [],
    );
  }

  /// `Company Name can\'n be empty`
  String get companyNameCanNotBeEmpty {
    return Intl.message(
      'Company Name can\\\'n be empty',
      name: 'companyNameCanNotBeEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Phone number can\'n be empty`
  String get phoneNumberCanNotBeEmpty {
    return Intl.message(
      'Phone number can\\\'n be empty',
      name: 'phoneNumberCanNotBeEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Enter a valid phone number`
  String get enterAValidPhoneNumber {
    return Intl.message(
      'Enter a valid phone number',
      name: 'enterAValidPhoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Enter your shop address`
  String get enterYourShopAddress {
    return Intl.message(
      'Enter your shop address',
      name: 'enterYourShopAddress',
      desc: '',
      args: [],
    );
  }

  /// `Shop GST`
  String get ShopGST {
    return Intl.message('Shop GST', name: 'ShopGST', desc: '', args: []);
  }

  /// `Enter your shop GST number`
  String get enterYourShopGSTNumber {
    return Intl.message(
      'Enter your shop GST number',
      name: 'enterYourShopGSTNumber',
      desc: '',
      args: [],
    );
  }

  /// `Please select Business Category`
  String get pleaseSelectBusinessCategory {
    return Intl.message(
      'Please select Business Category',
      name: 'pleaseSelectBusinessCategory',
      desc: '',
      args: [],
    );
  }

  /// `Loading`
  String get loading {
    return Intl.message('Loading', name: 'loading', desc: '', args: []);
  }

  /// `Added Successfully`
  String get addedSuccessfully {
    return Intl.message(
      'Added Successfully',
      name: 'addedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Email can\'n be empty`
  String get emailCanNotBeEmpty {
    return Intl.message(
      'Email can\\\'n be empty',
      name: 'emailCanNotBeEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a valid email`
  String get pleaseEnterAValidEmail {
    return Intl.message(
      'Please enter a valid email',
      name: 'pleaseEnterAValidEmail',
      desc: '',
      args: [],
    );
  }

  /// `Sending Reset Email`
  String get sendingResetEmail {
    return Intl.message(
      'Sending Reset Email',
      name: 'sendingResetEmail',
      desc: '',
      args: [],
    );
  }

  /// `Please Check Your Inbox`
  String get pleaseCheckYourInbox {
    return Intl.message(
      'Please Check Your Inbox',
      name: 'pleaseCheckYourInbox',
      desc: '',
      args: [],
    );
  }

  /// `No user found for that email`
  String get noUserFoundForThatEmail {
    return Intl.message(
      'No user found for that email',
      name: 'noUserFoundForThatEmail',
      desc: '',
      args: [],
    );
  }

  /// `Wrong password provided for that user`
  String get wrongPasswordProvidedForThatUser {
    return Intl.message(
      'Wrong password provided for that user',
      name: 'wrongPasswordProvidedForThatUser',
      desc: '',
      args: [],
    );
  }

  /// `Not Active User`
  String get notActiveUser {
    return Intl.message(
      'Not Active User',
      name: 'notActiveUser',
      desc: '',
      args: [],
    );
  }

  /// `Please use the valid purchase code to use the app`
  String get pleaseUseTheValidPurchaseCodeToUseTheApp {
    return Intl.message(
      'Please use the valid purchase code to use the app',
      name: 'pleaseUseTheValidPurchaseCodeToUseTheApp',
      desc: '',
      args: [],
    );
  }

  /// `OK`
  String get oK {
    return Intl.message('OK', name: 'oK', desc: '', args: []);
  }

  /// `Login Panel`
  String get loginPanel {
    return Intl.message('Login Panel', name: 'loginPanel', desc: '', args: []);
  }

  /// `Password can\'t be empty`
  String get passwordCanNotBeEmpty {
    return Intl.message(
      'Password can\\\'t be empty',
      name: 'passwordCanNotBeEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a bigger password`
  String get pleaseEnterABiggerPassword {
    return Intl.message(
      'Please enter a bigger password',
      name: 'pleaseEnterABiggerPassword',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a Company Name`
  String get pleaseEnterACompanyName {
    return Intl.message(
      'Please enter a Company Name',
      name: 'pleaseEnterACompanyName',
      desc: '',
      args: [],
    );
  }

  /// `Please enter Phone Number`
  String get pleaseEnterPhoneNumber {
    return Intl.message(
      'Please enter Phone Number',
      name: 'pleaseEnterPhoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Address can\'n be empty`
  String get addressCanNotBeEmpty {
    return Intl.message(
      'Address can\\\'n be empty',
      name: 'addressCanNotBeEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Please enter Your Address`
  String get pleaseEnterYourAddress {
    return Intl.message(
      'Please enter Your Address',
      name: 'pleaseEnterYourAddress',
      desc: '',
      args: [],
    );
  }

  /// `Opening Balance can\'n be empty`
  String get openingBalanceCanNotBeEmpty {
    return Intl.message(
      'Opening Balance can\\\'n be empty',
      name: 'openingBalanceCanNotBeEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Enter a valid amount`
  String get enterAValidAmount {
    return Intl.message(
      'Enter a valid amount',
      name: 'enterAValidAmount',
      desc: '',
      args: [],
    );
  }

  /// `SignUp Panel`
  String get signUpPanel {
    return Intl.message(
      'SignUp Panel',
      name: 'signUpPanel',
      desc: '',
      args: [],
    );
  }

  /// `Password Not mach`
  String get passwordNotMach {
    return Intl.message(
      'Password Not mach',
      name: 'passwordNotMach',
      desc: '',
      args: [],
    );
  }

  /// `Customer Name Is Required`
  String get customerNameIsRequired {
    return Intl.message(
      'Customer Name Is Required',
      name: 'customerNameIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Phone Number is required`
  String get phoneNumberIsRequired {
    return Intl.message(
      'Phone Number is required',
      name: 'phoneNumberIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Phone Number already exists`
  String get phoneNumberAlreadyExists {
    return Intl.message(
      'Phone Number already exists',
      name: 'phoneNumberAlreadyExists',
      desc: '',
      args: [],
    );
  }

  /// `Please Enter valid phone number`
  String get pleaseEnterValidPhoneNumber {
    return Intl.message(
      'Please Enter valid phone number',
      name: 'pleaseEnterValidPhoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Please Enter valid balance`
  String get pleaseEnterValidBalance {
    return Intl.message(
      'Please Enter valid balance',
      name: 'pleaseEnterValidBalance',
      desc: '',
      args: [],
    );
  }

  /// `Customer GST`
  String get customerGST {
    return Intl.message(
      'Customer GST',
      name: 'customerGST',
      desc: '',
      args: [],
    );
  }

  /// `Enter customer GST number`
  String get enterCustomerGSTNumber {
    return Intl.message(
      'Enter customer GST number',
      name: 'enterCustomerGSTNumber',
      desc: '',
      args: [],
    );
  }

  /// `Receive Whatsapp Updates`
  String get receiveWhatsappUpdates {
    return Intl.message(
      'Receive Whatsapp Updates',
      name: 'receiveWhatsappUpdates',
      desc: '',
      args: [],
    );
  }

  /// `You don't have permission to add customer`
  String get youDonNotHavePermissionToAddCustomer {
    return Intl.message(
      'You don\'t have permission to add customer',
      name: 'youDonNotHavePermissionToAddCustomer',
      desc: '',
      args: [],
    );
  }

  /// `Deleting`
  String get deleting {
    return Intl.message('Deleting', name: 'deleting', desc: '', args: []);
  }

  /// `Done`
  String get done {
    return Intl.message('Done', name: 'done', desc: '', args: []);
  }

  /// `Please enter a phone number`
  String get pleaseEnterAPhoneNumber {
    return Intl.message(
      'Please enter a phone number',
      name: 'pleaseEnterAPhoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Phone number already Used`
  String get phoneNumberAlreadyUsed {
    return Intl.message(
      'Phone number already Used',
      name: 'phoneNumberAlreadyUsed',
      desc: '',
      args: [],
    );
  }

  /// `Due List (Customer)`
  String get dueListCustomer {
    return Intl.message(
      'Due List (Customer)',
      name: 'dueListCustomer',
      desc: '',
      args: [],
    );
  }

  /// `Due List (Supplier)`
  String get dueListSupplier {
    return Intl.message(
      'Due List (Supplier)',
      name: 'dueListSupplier',
      desc: '',
      args: [],
    );
  }

  /// `Update your plan first,\nDue Collection limit is over`
  String get updateYourPlanFirstDueCollectionLimitIsOver {
    return Intl.message(
      'Update your plan first,\\nDue Collection limit is over',
      name: 'updateYourPlanFirstDueCollectionLimitIsOver',
      desc: '',
      args: [],
    );
  }

  /// `Select a Invoice`
  String get selectAInvoice {
    return Intl.message(
      'Select a Invoice',
      name: 'selectAInvoice',
      desc: '',
      args: [],
    );
  }

  /// `Please Enter Amount`
  String get pleaseEnterAmount {
    return Intl.message(
      'Please Enter Amount',
      name: 'pleaseEnterAmount',
      desc: '',
      args: [],
    );
  }

  /// `Category Name Already Exists`
  String get categoryNameAlreadyExists {
    return Intl.message(
      'Category Name Already Exists',
      name: 'categoryNameAlreadyExists',
      desc: '',
      args: [],
    );
  }

  /// `Edit Successfully`
  String get editSuccessfully {
    return Intl.message(
      'Edit Successfully',
      name: 'editSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `SL`
  String get SL {
    return Intl.message('SL', name: 'SL', desc: '', args: []);
  }

  /// `This category Cannot be deleted`
  String get thisCategoryCannotBeDeleted {
    return Intl.message(
      'This category Cannot be deleted',
      name: 'thisCategoryCannotBeDeleted',
      desc: '',
      args: [],
    );
  }

  /// `Please Enter Name`
  String get pleaseEnterName {
    return Intl.message(
      'Please Enter Name',
      name: 'pleaseEnterName',
      desc: '',
      args: [],
    );
  }

  /// `please Inter Amount`
  String get pleaseInterAmount {
    return Intl.message(
      'please Inter Amount',
      name: 'pleaseInterAmount',
      desc: '',
      args: [],
    );
  }

  /// `Cash`
  String get cash {
    return Intl.message('Cash', name: 'cash', desc: '', args: []);
  }

  /// `Bank`
  String get bank {
    return Intl.message('Bank', name: 'bank', desc: '', args: []);
  }

  /// `Card`
  String get card {
    return Intl.message('Card', name: 'card', desc: '', args: []);
  }

  /// `Mobile Payment`
  String get mobilePayment {
    return Intl.message(
      'Mobile Payment',
      name: 'mobilePayment',
      desc: '',
      args: [],
    );
  }

  /// `Snacks`
  String get snacks {
    return Intl.message('Snacks', name: 'snacks', desc: '', args: []);
  }

  /// `This Month`
  String get thisMonth {
    return Intl.message('This Month', name: 'thisMonth', desc: '', args: []);
  }

  /// `Last Month`
  String get lastMonth {
    return Intl.message('Last Month', name: 'lastMonth', desc: '', args: []);
  }

  /// `Last 6 Month`
  String get last6Month {
    return Intl.message('Last 6 Month', name: 'last6Month', desc: '', args: []);
  }

  /// `This Year`
  String get thisYear {
    return Intl.message('This Year', name: 'thisYear', desc: '', args: []);
  }

  /// `Expenses List`
  String get expensesList {
    return Intl.message(
      'Expenses List',
      name: 'expensesList',
      desc: '',
      args: [],
    );
  }

  /// `Expense Category`
  String get expenseCategory {
    return Intl.message(
      'Expense Category',
      name: 'expenseCategory',
      desc: '',
      args: [],
    );
  }

  /// `New Expenses`
  String get newExpenses {
    return Intl.message(
      'New Expenses',
      name: 'newExpenses',
      desc: '',
      args: [],
    );
  }

  /// `No Expense Found`
  String get noExpenseFound {
    return Intl.message(
      'No Expense Found',
      name: 'noExpenseFound',
      desc: '',
      args: [],
    );
  }

  /// `Select expense category`
  String get selectExpenseCategory {
    return Intl.message(
      'Select expense category',
      name: 'selectExpenseCategory',
      desc: '',
      args: [],
    );
  }

  /// `Please select a category`
  String get pleaseSelectACategory {
    return Intl.message(
      'Please select a category',
      name: 'pleaseSelectACategory',
      desc: '',
      args: [],
    );
  }

  /// `April`
  String get april {
    return Intl.message('April', name: 'april', desc: '', args: []);
  }

  /// `March`
  String get march {
    return Intl.message('March', name: 'march', desc: '', args: []);
  }

  /// `February`
  String get february {
    return Intl.message('February', name: 'february', desc: '', args: []);
  }

  /// `January`
  String get january {
    return Intl.message('January', name: 'january', desc: '', args: []);
  }

  /// `May`
  String get may {
    return Intl.message('May', name: 'may', desc: '', args: []);
  }

  /// `June`
  String get june {
    return Intl.message('June', name: 'june', desc: '', args: []);
  }

  /// `July`
  String get july {
    return Intl.message('July', name: 'july', desc: '', args: []);
  }

  /// `Update your plan first\nAdd Customer limit is over`
  String get updateYourPlanFirstAddCustomerLimitIsOver {
    return Intl.message(
      'Update your plan first\\nAdd Customer limit is over',
      name: 'updateYourPlanFirstAddCustomerLimitIsOver',
      desc: '',
      args: [],
    );
  }

  /// `Showing`
  String get showing {
    return Intl.message('Showing', name: 'showing', desc: '', args: []);
  }

  /// `of`
  String get OF {
    return Intl.message('of', name: 'OF', desc: '', args: []);
  }

  /// `View All`
  String get viewAll {
    return Intl.message('View All', name: 'viewAll', desc: '', args: []);
  }

  /// `Unpaid`
  String get unpaid {
    return Intl.message('Unpaid', name: 'unpaid', desc: '', args: []);
  }

  /// `Yearly`
  String get yearly {
    return Intl.message('Yearly', name: 'yearly', desc: '', args: []);
  }

  /// `Stock is more then low limit`
  String get stockIsMoreThenLowLimit {
    return Intl.message(
      'Stock is more then low limit',
      name: 'stockIsMoreThenLowLimit',
      desc: '',
      args: [],
    );
  }

  /// `Add Designation`
  String get addDesignation {
    return Intl.message(
      'Add Designation',
      name: 'addDesignation',
      desc: '',
      args: [],
    );
  }

  /// `Designation`
  String get designation {
    return Intl.message('Designation', name: 'designation', desc: '', args: []);
  }

  /// `Please enter Designation`
  String get pleaseEnterDesignation {
    return Intl.message(
      'Please enter Designation',
      name: 'pleaseEnterDesignation',
      desc: '',
      args: [],
    );
  }

  /// `Enter Designation Name`
  String get enterDesignationName {
    return Intl.message(
      'Enter Designation Name',
      name: 'enterDesignationName',
      desc: '',
      args: [],
    );
  }

  /// `Designation Name Already Exists`
  String get designationNameAlreadyExists {
    return Intl.message(
      'Designation Name Already Exists',
      name: 'designationNameAlreadyExists',
      desc: '',
      args: [],
    );
  }

  /// `Enter Description`
  String get enterDescription {
    return Intl.message(
      'Enter Description',
      name: 'enterDescription',
      desc: '',
      args: [],
    );
  }

  /// `Designation List`
  String get designationList {
    return Intl.message(
      'Designation List',
      name: 'designationList',
      desc: '',
      args: [],
    );
  }

  /// `No Data Found`
  String get noDataFound {
    return Intl.message(
      'No Data Found',
      name: 'noDataFound',
      desc: '',
      args: [],
    );
  }

  /// `Select a category`
  String get selectACategory {
    return Intl.message(
      'Select a category',
      name: 'selectACategory',
      desc: '',
      args: [],
    );
  }

  /// `Select category`
  String get selectCategory {
    return Intl.message(
      'Select category',
      name: 'selectCategory',
      desc: '',
      args: [],
    );
  }

  /// `Mobile Pay`
  String get mobilePay {
    return Intl.message('Mobile Pay', name: 'mobilePay', desc: '', args: []);
  }

  /// `Guest`
  String get guest {
    return Intl.message('Guest', name: 'guest', desc: '', args: []);
  }

  /// `Out of Stock`
  String get outOfStock {
    return Intl.message('Out of Stock', name: 'outOfStock', desc: '', args: []);
  }

  /// `Wholesaler`
  String get wholesaler {
    return Intl.message('Wholesaler', name: 'wholesaler', desc: '', args: []);
  }

  /// `Product Out Of Stock`
  String get productOutOfStock {
    return Intl.message(
      'Product Out Of Stock',
      name: 'productOutOfStock',
      desc: '',
      args: [],
    );
  }

  /// `Party`
  String get party {
    return Intl.message('Party', name: 'party', desc: '', args: []);
  }

  /// `Warehouse`
  String get warehouse {
    return Intl.message('Warehouse', name: 'warehouse', desc: '', args: []);
  }

  /// `Enter a valid Price`
  String get enterAValidPrice {
    return Intl.message(
      'Enter a valid Price',
      name: 'enterAValidPrice',
      desc: '',
      args: [],
    );
  }

  /// `Enter received amount`
  String get enterReceivedAmount {
    return Intl.message(
      'Enter received amount',
      name: 'enterReceivedAmount',
      desc: '',
      args: [],
    );
  }

  /// `Change Return`
  String get changeReturn {
    return Intl.message(
      'Change Return',
      name: 'changeReturn',
      desc: '',
      args: [],
    );
  }

  /// `Enter change return`
  String get enterChangeReturn {
    return Intl.message(
      'Enter change return',
      name: 'enterChangeReturn',
      desc: '',
      args: [],
    );
  }

  /// `Enter due amount`
  String get enterDueAmount {
    return Intl.message(
      'Enter due amount',
      name: 'enterDueAmount',
      desc: '',
      args: [],
    );
  }

  /// `Enter a valid Discount`
  String get enterAValidDiscount {
    return Intl.message(
      'Enter a valid Discount',
      name: 'enterAValidDiscount',
      desc: '',
      args: [],
    );
  }

  /// `Please Add Some Product first`
  String get pleaseAddSomeProductFirst {
    return Intl.message(
      'Please Add Some Product first',
      name: 'pleaseAddSomeProductFirst',
      desc: '',
      args: [],
    );
  }

  /// `Update your plan first\nSale Limit is over`
  String get updateYourPlanFirstSaleLimitIsOver {
    return Intl.message(
      'Update your plan first\\nSale Limit is over',
      name: 'updateYourPlanFirstSaleLimitIsOver',
      desc: '',
      args: [],
    );
  }

  /// `Sale Successfully Done`
  String get saleSuccessfullyDone {
    return Intl.message(
      'Sale Successfully Done',
      name: 'saleSuccessfullyDone',
      desc: '',
      args: [],
    );
  }

  /// `Due is not available For Guest`
  String get dueIsNotAvailableForGuest {
    return Intl.message(
      'Due is not available For Guest',
      name: 'dueIsNotAvailableForGuest',
      desc: '',
      args: [],
    );
  }

  /// `Due Date`
  String get dueDate {
    return Intl.message('Due Date', name: 'dueDate', desc: '', args: []);
  }

  /// `Seller`
  String get seller {
    return Intl.message('Seller', name: 'seller', desc: '', args: []);
  }

  /// `Admin`
  String get admin {
    return Intl.message('Admin', name: 'admin', desc: '', args: []);
  }

  /// `Serial`
  String get serial {
    return Intl.message('Serial', name: 'serial', desc: '', args: []);
  }

  /// `Ledger Details`
  String get ledgerDetails {
    return Intl.message(
      'Ledger Details',
      name: 'ledgerDetails',
      desc: '',
      args: [],
    );
  }

  /// `Received Amount`
  String get receivedAmount {
    return Intl.message(
      'Received Amount',
      name: 'receivedAmount',
      desc: '',
      args: [],
    );
  }

  /// `Customer Name`
  String get customerPhone {
    return Intl.message(
      'Customer Name',
      name: 'customerPhone',
      desc: '',
      args: [],
    );
  }

  /// `Not found`
  String get notFound {
    return Intl.message('Not found', name: 'notFound', desc: '', args: []);
  }

  /// `Search product name or code`
  String get searchProductNameOrCode {
    return Intl.message(
      'Search product name or code',
      name: 'searchProductNameOrCode',
      desc: '',
      args: [],
    );
  }

  /// `Total Item`
  String get totalItem {
    return Intl.message('Total Item', name: 'totalItem', desc: '', args: []);
  }

  /// `Product Barcode`
  String get productBarcode {
    return Intl.message(
      'Product Barcode',
      name: 'productBarcode',
      desc: '',
      args: [],
    );
  }

  /// `Code`
  String get code {
    return Intl.message('Code', name: 'code', desc: '', args: []);
  }

  /// `Components`
  String get components {
    return Intl.message('Components', name: 'components', desc: '', args: []);
  }

  /// `Site Name`
  String get siteName {
    return Intl.message('Site Name', name: 'siteName', desc: '', args: []);
  }

  /// `Product Code`
  String get productCode {
    return Intl.message(
      'Product Code',
      name: 'productCode',
      desc: '',
      args: [],
    );
  }

  /// `Product Price`
  String get productPrice {
    return Intl.message(
      'Product Price',
      name: 'productPrice',
      desc: '',
      args: [],
    );
  }

  /// `Product Name with code`
  String get productNameWithCode {
    return Intl.message(
      'Product Name with code',
      name: 'productNameWithCode',
      desc: '',
      args: [],
    );
  }

  /// `Enter quantity`
  String get enterQuantity {
    return Intl.message(
      'Enter quantity',
      name: 'enterQuantity',
      desc: '',
      args: [],
    );
  }

  /// `Quantity is required`
  String get quantityIsRequired {
    return Intl.message(
      'Quantity is required',
      name: 'quantityIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Enter valid number`
  String get enterValidNumber {
    return Intl.message(
      'Enter valid number',
      name: 'enterValidNumber',
      desc: '',
      args: [],
    );
  }

  /// `Reset`
  String get reset {
    return Intl.message('Reset', name: 'reset', desc: '', args: []);
  }

  /// `Quantity is required`
  String get selectProduct {
    return Intl.message(
      'Quantity is required',
      name: 'selectProduct',
      desc: '',
      args: [],
    );
  }

  /// `Generate`
  String get generate {
    return Intl.message('Generate', name: 'generate', desc: '', args: []);
  }

  /// `Category name is required`
  String get categoryNameIsRequired {
    return Intl.message(
      'Category name is required',
      name: 'categoryNameIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Category name is already exist`
  String get categoryNameIsAlreadyExist {
    return Intl.message(
      'Category name is already exist',
      name: 'categoryNameIsAlreadyExist',
      desc: '',
      args: [],
    );
  }

  /// `Adding Category`
  String get addingCategory {
    return Intl.message(
      'Adding Category',
      name: 'addingCategory',
      desc: '',
      args: [],
    );
  }

  /// `Successfully Added`
  String get successfullyAdded {
    return Intl.message(
      'Successfully Added',
      name: 'successfullyAdded',
      desc: '',
      args: [],
    );
  }

  /// `Error`
  String get error {
    return Intl.message('Error', name: 'error', desc: '', args: []);
  }

  /// `Brand name is required`
  String get brandNameIsRequired {
    return Intl.message(
      'Brand name is required',
      name: 'brandNameIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Brand name is already exist`
  String get brandNameIsAlreadyExist {
    return Intl.message(
      'Brand name is already exist',
      name: 'brandNameIsAlreadyExist',
      desc: '',
      args: [],
    );
  }

  /// `Adding Brand`
  String get addingBrand {
    return Intl.message(
      'Adding Brand',
      name: 'addingBrand',
      desc: '',
      args: [],
    );
  }

  /// `Unit name is required`
  String get unitNameIsRequired {
    return Intl.message(
      'Unit name is required',
      name: 'unitNameIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Unit name is already exist`
  String get unitNameIsAlreadyExist {
    return Intl.message(
      'Unit name is already exist',
      name: 'unitNameIsAlreadyExist',
      desc: '',
      args: [],
    );
  }

  /// `Adding Units`
  String get addingUnits {
    return Intl.message(
      'Adding Units',
      name: 'addingUnits',
      desc: '',
      args: [],
    );
  }

  /// `Select Tax`
  String get selectTax {
    return Intl.message('Select Tax', name: 'selectTax', desc: '', args: []);
  }

  /// `Select Tax type`
  String get selectTaxType {
    return Intl.message(
      'Select Tax type',
      name: 'selectTaxType',
      desc: '',
      args: [],
    );
  }

  /// `Inclusive`
  String get inclusive {
    return Intl.message('Inclusive', name: 'inclusive', desc: '', args: []);
  }

  /// `Exclusive`
  String get exclusive {
    return Intl.message('Exclusive', name: 'exclusive', desc: '', args: []);
  }

  /// `Product name is required`
  String get productNameIsRequired {
    return Intl.message(
      'Product name is required',
      name: 'productNameIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Product Name already exists in this warehouse`
  String get productNameAlreadyExistsInThisWarehouse {
    return Intl.message(
      'Product Name already exists in this warehouse',
      name: 'productNameAlreadyExistsInThisWarehouse',
      desc: '',
      args: [],
    );
  }

  /// `Enter Quantity in number`
  String get enterQuantityInNumber {
    return Intl.message(
      'Enter Quantity in number',
      name: 'enterQuantityInNumber',
      desc: '',
      args: [],
    );
  }

  /// `Product Code already exist`
  String get productCodeAlreadyExist {
    return Intl.message(
      'Product Code already exist',
      name: 'productCodeAlreadyExist',
      desc: '',
      args: [],
    );
  }

  /// `Product Quantity is required`
  String get productQuantityIsRequired {
    return Intl.message(
      'Product Quantity is required',
      name: 'productQuantityIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Manufacture Date`
  String get manufactureDate {
    return Intl.message(
      'Manufacture Date',
      name: 'manufactureDate',
      desc: '',
      args: [],
    );
  }

  /// `Enter Date`
  String get enterDate {
    return Intl.message('Enter Date', name: 'enterDate', desc: '', args: []);
  }

  /// `Expire Date`
  String get expireDate {
    return Intl.message('Expire Date', name: 'expireDate', desc: '', args: []);
  }

  /// `Low Stock Alert`
  String get lowStockAlert {
    return Intl.message(
      'Low Stock Alert',
      name: 'lowStockAlert',
      desc: '',
      args: [],
    );
  }

  /// `Enter Low Stock Alert Quantity`
  String get enterLowStockAlertQuantity {
    return Intl.message(
      'Enter Low Stock Alert Quantity',
      name: 'enterLowStockAlertQuantity',
      desc: '',
      args: [],
    );
  }

  /// `Serial number already added`
  String get serialNumberAlreadyAdded {
    return Intl.message(
      'Serial number already added',
      name: 'serialNumberAlreadyAdded',
      desc: '',
      args: [],
    );
  }

  /// `Applicable Tax`
  String get applicableTax {
    return Intl.message(
      'Applicable Tax',
      name: 'applicableTax',
      desc: '',
      args: [],
    );
  }

  /// `Tax Type`
  String get taxType {
    return Intl.message('Tax Type', name: 'taxType', desc: '', args: []);
  }

  /// `Margin`
  String get margin {
    return Intl.message('Margin', name: 'margin', desc: '', args: []);
  }

  /// `Inc. tax`
  String get incTax {
    return Intl.message('Inc. tax', name: 'incTax', desc: '', args: []);
  }

  /// `Exc. tax`
  String get excTax {
    return Intl.message('Exc. tax', name: 'excTax', desc: '', args: []);
  }

  /// `Product Purchase Price is required`
  String get productPurchasePriceIsRequired {
    return Intl.message(
      'Product Purchase Price is required',
      name: 'productPurchasePriceIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Enter price in number`
  String get enterPriceInNumber {
    return Intl.message(
      'Enter price in number',
      name: 'enterPriceInNumber',
      desc: '',
      args: [],
    );
  }

  /// `Product Sale Price is required`
  String get productSalePriceIsRequired {
    return Intl.message(
      'Product Sale Price is required',
      name: 'productSalePriceIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Fill all required field`
  String get fillAllRequiredField {
    return Intl.message(
      'Fill all required field',
      name: 'fillAllRequiredField',
      desc: '',
      args: [],
    );
  }

  /// `Upload Done`
  String get uploadDone {
    return Intl.message('Upload Done', name: 'uploadDone', desc: '', args: []);
  }

  /// `Bulk Product Upload`
  String get bulkProductUpload {
    return Intl.message(
      'Bulk Product Upload',
      name: 'bulkProductUpload',
      desc: '',
      args: [],
    );
  }

  /// `Download Excel Format`
  String get downloadExcelFormat {
    return Intl.message(
      'Download Excel Format',
      name: 'downloadExcelFormat',
      desc: '',
      args: [],
    );
  }

  /// `Upload an Excel`
  String get uploadAnExcel {
    return Intl.message(
      'Upload an Excel',
      name: 'uploadAnExcel',
      desc: '',
      args: [],
    );
  }

  /// `or drag & drop .xlsx`
  String get orDragdropXlsx {
    return Intl.message(
      'or drag & drop .xlsx',
      name: 'orDragdropXlsx',
      desc: '',
      args: [],
    );
  }

  /// `An Excel file picked`
  String get AnExcelFilePicked {
    return Intl.message(
      'An Excel file picked',
      name: 'AnExcelFilePicked',
      desc: '',
      args: [],
    );
  }

  /// `Remove`
  String get remove {
    return Intl.message('Remove', name: 'remove', desc: '', args: []);
  }

  /// `Upload`
  String get upload {
    return Intl.message('Upload', name: 'upload', desc: '', args: []);
  }

  /// `Product Name already exist`
  String get productNameAlreadyExist {
    return Intl.message(
      'Product Name already exist',
      name: 'productNameAlreadyExist',
      desc: '',
      args: [],
    );
  }

  /// `Expired List`
  String get expiredList {
    return Intl.message(
      'Expired List',
      name: 'expiredList',
      desc: '',
      args: [],
    );
  }

  /// `Please enter Stock`
  String get pleaseEnterStock {
    return Intl.message(
      'Please enter Stock',
      name: 'pleaseEnterStock',
      desc: '',
      args: [],
    );
  }

  /// `Enter Stock in number`
  String get enterStockInNumber {
    return Intl.message(
      'Enter Stock in number',
      name: 'enterStockInNumber',
      desc: '',
      args: [],
    );
  }

  /// `Please enter Purchase Price`
  String get pleaseEnterPurchasePrice {
    return Intl.message(
      'Please enter Purchase Price',
      name: 'pleaseEnterPurchasePrice',
      desc: '',
      args: [],
    );
  }

  /// `Please enter Sale Price`
  String get pleaseEnterSalePrice {
    return Intl.message(
      'Please enter Sale Price',
      name: 'pleaseEnterSalePrice',
      desc: '',
      args: [],
    );
  }

  /// `Result`
  String get result {
    return Intl.message('Result', name: 'result', desc: '', args: []);
  }

  /// `Bulk Upload`
  String get bulkUpload {
    return Intl.message('Bulk Upload', name: 'bulkUpload', desc: '', args: []);
  }

  /// `Barcode Generate`
  String get barcodeGenerate {
    return Intl.message(
      'Barcode Generate',
      name: 'barcodeGenerate',
      desc: '',
      args: [],
    );
  }

  /// `Expired`
  String get expired {
    return Intl.message('Expired', name: 'expired', desc: '', args: []);
  }

  /// `Will Expire at`
  String get willExpireAt {
    return Intl.message(
      'Will Expire at',
      name: 'willExpireAt',
      desc: '',
      args: [],
    );
  }

  /// `of`
  String get Of {
    return Intl.message('of', name: 'Of', desc: '', args: []);
  }

  /// `entries`
  String get entries {
    return Intl.message('entries', name: 'entries', desc: '', args: []);
  }

  /// `Previous`
  String get previous {
    return Intl.message('Previous', name: 'previous', desc: '', args: []);
  }

  /// `Next`
  String get next {
    return Intl.message('Next', name: 'next', desc: '', args: []);
  }

  /// `Image`
  String get image {
    return Intl.message('Image', name: 'image', desc: '', args: []);
  }

  /// `Already Added`
  String get alreadyAdded {
    return Intl.message(
      'Already Added',
      name: 'alreadyAdded',
      desc: '',
      args: [],
    );
  }

  /// `Update your plan first \nPurchase Limit is over`
  String get updateYourPlanFirstPurchaseLimitIsOver {
    return Intl.message(
      'Update your plan first \nPurchase Limit is over',
      name: 'updateYourPlanFirstPurchaseLimitIsOver',
      desc: '',
      args: [],
    );
  }

  /// `Field to pick image`
  String get fieldToPickImage {
    return Intl.message(
      'Field to pick image',
      name: 'fieldToPickImage',
      desc: '',
      args: [],
    );
  }

  /// `Welcome`
  String get welcome {
    return Intl.message('Welcome', name: 'welcome', desc: '', args: []);
  }

  /// `items`
  String get items {
    return Intl.message('items', name: 'items', desc: '', args: []);
  }

  /// `Are you sure to delete this Purchase`
  String get areYouSureToDeleteThisPurchase {
    return Intl.message(
      'Are you sure to delete this Purchase',
      name: 'areYouSureToDeleteThisPurchase',
      desc: '',
      args: [],
    );
  }

  /// `The sale will be deleted and all the data will be deleted about this Purchase .Are you sure to delete this`
  String get theSaleWillBeDeletedAndAllTheDataWillBeDeletedAboutThisPurchaseAreYouSureToDeleteThis {
    return Intl.message(
      'The sale will be deleted and all the data will be deleted about this Purchase .Are you sure to delete this',
      name: 'theSaleWillBeDeletedAndAllTheDataWillBeDeletedAboutThisPurchaseAreYouSureToDeleteThis',
      desc: '',
      args: [],
    );
  }

  /// `Yes, Delete Forever`
  String get yesDeleteForever {
    return Intl.message(
      'Yes, Delete Forever',
      name: 'yesDeleteForever',
      desc: '',
      args: [],
    );
  }

  /// `Purchase Return`
  String get purchaseReturn {
    return Intl.message(
      'Purchase Return',
      name: 'purchaseReturn',
      desc: '',
      args: [],
    );
  }

  /// `Due is not for Guest Customer`
  String get dueIsNotForGuestCustomer {
    return Intl.message(
      'Due is not for Guest Customer',
      name: 'dueIsNotForGuestCustomer',
      desc: '',
      args: [],
    );
  }

  /// `Add product first`
  String get addProductFirst {
    return Intl.message(
      'Add product first',
      name: 'addProductFirst',
      desc: '',
      args: [],
    );
  }

  /// `Successfully Done`
  String get successfullyDone {
    return Intl.message(
      'Successfully Done',
      name: 'successfullyDone',
      desc: '',
      args: [],
    );
  }

  /// `Sale Quantity`
  String get saleQuantity {
    return Intl.message(
      'Sale Quantity',
      name: 'saleQuantity',
      desc: '',
      args: [],
    );
  }

  /// `Return Quantity`
  String get returnQuantity {
    return Intl.message(
      'Return Quantity',
      name: 'returnQuantity',
      desc: '',
      args: [],
    );
  }

  /// `Select a product for return`
  String get selectAProductForReturn {
    return Intl.message(
      'Select a product for return',
      name: 'selectAProductForReturn',
      desc: '',
      args: [],
    );
  }

  /// `Conform Return`
  String get conformReturn {
    return Intl.message(
      'Conform Return',
      name: 'conformReturn',
      desc: '',
      args: [],
    );
  }

  /// `Low`
  String get low {
    return Intl.message('Low', name: 'low', desc: '', args: []);
  }

  /// `High`
  String get high {
    return Intl.message('High', name: 'high', desc: '', args: []);
  }

  /// `Sales Return`
  String get salesReturn {
    return Intl.message(
      'Sales Return',
      name: 'salesReturn',
      desc: '',
      args: [],
    );
  }

  /// `Current Stock`
  String get currentStock {
    return Intl.message(
      'Current Stock',
      name: 'currentStock',
      desc: '',
      args: [],
    );
  }

  /// `Quotation Sale History`
  String get quotationSaleHistory {
    return Intl.message(
      'Quotation Sale History',
      name: 'quotationSaleHistory',
      desc: '',
      args: [],
    );
  }

  /// `Loss/Profit report`
  String get lossProfitReport {
    return Intl.message(
      'Loss/Profit report',
      name: 'lossProfitReport',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure to delete this sale`
  String get areYouSureToDeleteThisSale {
    return Intl.message(
      'Are you sure to delete this sale',
      name: 'areYouSureToDeleteThisSale',
      desc: '',
      args: [],
    );
  }

  /// `The sale will be deleted and all the data will be deleted about this sale.Are you sure to delete this`
  String get theSaleWillBeDeletedAndAllTheDataWillBeDeletedAboutThisSaleAreYouSureToDeleteThis {
    return Intl.message(
      'The sale will be deleted and all the data will be deleted about this sale.Are you sure to delete this',
      name: 'theSaleWillBeDeletedAndAllTheDataWillBeDeletedAboutThisSaleAreYouSureToDeleteThis',
      desc: '',
      args: [],
    );
  }

  /// `Please Enter Transaction Number`
  String get pleaseEnterTransactionNumber {
    return Intl.message(
      'Please Enter Transaction Number',
      name: 'pleaseEnterTransactionNumber',
      desc: '',
      args: [],
    );
  }

  /// `Request has been send`
  String get requestHasBeenSend {
    return Intl.message(
      'Request has been send',
      name: 'requestHasBeenSend',
      desc: '',
      args: [],
    );
  }

  /// `You Are Not A Valid User`
  String get youAreNotAValidUser {
    return Intl.message(
      'You Are Not A Valid User',
      name: 'youAreNotAValidUser',
      desc: '',
      args: [],
    );
  }



  /// `Whatsapp marketing enabled`
  String get whatsappMarketingEnabled {
    return Intl.message(
      'Whatsapp marketing enabled',
      name: 'whatsappMarketingEnabled',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get save {
    return Intl.message('Save', name: 'save', desc: '', args: []);
  }

  /// `Day`
  String get day {
    return Intl.message('Day', name: 'day', desc: '', args: []);
  }

  /// `Plan`
  String get plan {
    return Intl.message('Plan', name: 'plan', desc: '', args: []);
  }

  /// `This customer have previous due`
  String get thisCustomerHavePreviousDue {
    return Intl.message(
      'This customer have previous due',
      name: 'thisCustomerHavePreviousDue',
      desc: '',
      args: [],
    );
  }

  /// `Please Select a Plan`
  String get pleaseSelectAPlan {
    return Intl.message(
      'Please Select a Plan',
      name: 'pleaseSelectAPlan',
      desc: '',
      args: [],
    );
  }

  /// `Add New Tax`
  String get addNewTax {
    return Intl.message('Add New Tax', name: 'addNewTax', desc: '', args: []);
  }

  /// `Tax rate`
  String get taxRate {
    return Intl.message('Tax rate', name: 'taxRate', desc: '', args: []);
  }

  /// `Enter Tax rate`
  String get enterTaxRate {
    return Intl.message(
      'Enter Tax rate',
      name: 'enterTaxRate',
      desc: '',
      args: [],
    );
  }

  /// `Already Exists`
  String get alreadyExists {
    return Intl.message(
      'Already Exists',
      name: 'alreadyExists',
      desc: '',
      args: [],
    );
  }

  /// `Edit Tax`
  String get editTax {
    return Intl.message('Edit Tax', name: 'editTax', desc: '', args: []);
  }

  /// `Name  Already Exists`
  String get nameAlreadyExists {
    return Intl.message(
      'Name  Already Exists',
      name: 'nameAlreadyExists',
      desc: '',
      args: [],
    );
  }

  /// `Name can\'t be empty`
  String get nameCantBeEmpty {
    return Intl.message(
      'Name can\\\'t be empty',
      name: 'nameCantBeEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Update`
  String get update {
    return Intl.message('Update', name: 'update', desc: '', args: []);
  }

  /// `Sub Taxes`
  String get subTaxes {
    return Intl.message('Sub Taxes', name: 'subTaxes', desc: '', args: []);
  }

  /// `No Sub Tax selected`
  String get noSubTaxSelected {
    return Intl.message(
      'No Sub Tax selected',
      name: 'noSubTaxSelected',
      desc: '',
      args: [],
    );
  }

  /// `Add New Tax with single/multiple Tax type`
  String get addNewTaxWithSingleMultipleTaxType {
    return Intl.message(
      'Add New Tax with single/multiple Tax type',
      name: 'addNewTaxWithSingleMultipleTaxType',
      desc: '',
      args: [],
    );
  }

  /// `Tax rates- Manage your Tax rates`
  String get taxRatesManageYourTaxRates {
    return Intl.message(
      'Tax rates- Manage your Tax rates',
      name: 'taxRatesManageYourTaxRates',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure want to delete this Tax`
  String get areYouSureWantToDeleteThisTax {
    return Intl.message(
      'Are you sure want to delete this Tax',
      name: 'areYouSureWantToDeleteThisTax',
      desc: '',
      args: [],
    );
  }

  /// `Tax Group`
  String get taxGroup {
    return Intl.message('Tax Group', name: 'taxGroup', desc: '', args: []);
  }

  /// `Combination of multiple taxes`
  String get combinationOfMultipleTaxes {
    return Intl.message(
      'Combination of multiple taxes',
      name: 'combinationOfMultipleTaxes',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure want to delete this Tax Group`
  String get areYouSureWantToDeleteThisTaxGroup {
    return Intl.message(
      'Are you sure want to delete this Tax Group',
      name: 'areYouSureWantToDeleteThisTaxGroup',
      desc: '',
      args: [],
    );
  }

  /// `No Group Found`
  String get noGroupFound {
    return Intl.message(
      'No Group Found',
      name: 'noGroupFound',
      desc: '',
      args: [],
    );
  }

  /// `Password and confirm password does not match`
  String get passwordAndConfirmPasswordDoesNotMatch {
    return Intl.message(
      'Password and confirm password does not match',
      name: 'passwordAndConfirmPasswordDoesNotMatch',
      desc: '',
      args: [],
    );
  }

  /// `User title can\'n be empty`
  String get userTitleCanBeEmpty {
    return Intl.message(
      'User title can\\\'n be empty',
      name: 'userTitleCanBeEmpty',
      desc: '',
      args: [],
    );
  }

  /// `You Have To Give Permission`
  String get youHaveToGivePermission {
    return Intl.message(
      'You Have To Give Permission',
      name: 'youHaveToGivePermission',
      desc: '',
      args: [],
    );
  }

  /// `Registering`
  String get registering {
    return Intl.message('Registering', name: 'registering', desc: '', args: []);
  }

  /// `wrong-password`
  String get wrongPassword {
    return Intl.message(
      'wrong-password',
      name: 'wrongPassword',
      desc: '',
      args: [],
    );
  }

  /// `Failed with Error`
  String get failedWithError {
    return Intl.message(
      'Failed with Error',
      name: 'failedWithError',
      desc: '',
      args: [],
    );
  }

  /// `The password provided is too weak`
  String get thePasswordProvidedIsTooWeak {
    return Intl.message(
      'The password provided is too weak',
      name: 'thePasswordProvidedIsTooWeak',
      desc: '',
      args: [],
    );
  }

  /// `The account already exists for that email`
  String get theAccountAlreadyExistsForThatEmail {
    return Intl.message(
      'The account already exists for that email',
      name: 'theAccountAlreadyExistsForThatEmail',
      desc: '',
      args: [],
    );
  }

  /// `Package Name Required`
  String get packageNameRequired {
    return Intl.message(
      'Package Name Required',
      name: 'packageNameRequired',
      desc: '',
      args: [],
    );
  }

  /// `Category Required`
  String get categoryRequired {
    return Intl.message(
      'Category Required',
      name: 'categoryRequired',
      desc: '',
      args: [],
    );
  }

  /// `Subcategory Hint`
  String get subcategoryHint {
    return Intl.message(
      'Sugerencia de subcategoría',
      name: 'subcategoryHint',
      desc: '',
      args: [],
    );
  }

  /// `Price Required`
  String get priceRequired {
    return Intl.message(
      'Price Required',
      name: 'priceRequired',
      desc: '',
      args: [],
    );
  }

  /// `Invalid Number`
  String get invalidNumber {
    return Intl.message(
      'Invalid Number',
      name: 'invalidNumber',
      desc: '',
      args: [],
    );
  }

  /// `Duration Required`
  String get durationRequired {
    return Intl.message(
      'Duration Required',
      name: 'durationRequired',
      desc: '',
      args: [],
    );
  }

  /// `Invalid Integer`
  String get invalidInteger {
    return Intl.message(
      'Invalid Integer',
      name: 'invalidInteger',
      desc: '',
      args: [],
    );
  }

  /// `Adding Package`
  String get addingPackage {
    return Intl.message(
      'Adding Package',
      name: 'addingPackage',
      desc: '',
      args: [],
    );
  }

  /// `Failed to Add Package`
  String get failedToAddPackage {
    return Intl.message(
      'Failed to Add Package',
      name: 'failedToAddPackage',
      desc: '',
      args: [],
    );
  }

  /// `Package Added Successfully`
  String get packageAddedSuccess {
    return Intl.message(
      'Package Added Successfully',
      name: 'packageAddedSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Edit Package`
  String get editPackage {
    return Intl.message(
      'Edit Package',
      name: 'editPackage',
      desc: '',
      args: [],
    );
  }
  /// `User Role Details`
  String get userRoleDetails {
    return Intl.message(
      'User Role Details',
      name: 'userRoleDetails',
      desc: '',
      args: [],
    );
  }

  /// `Please Enter Password`
  String get pleaseEnterPassword {
    return Intl.message(
      'Please Enter Password',
      name: 'pleaseEnterPassword',
      desc: '',
      args: [],
    );
  }

  /// `Select Practise`
  String get selectPractise {
    return Intl.message(
      'Select Practise',
      name: 'selectPractise',
      desc: '',
      args: [],
    );
  }

  /// `Loss/Profit`
  String get lossProfit {
    return Intl.message('Loss/Profit', name: 'lossProfit', desc: '', args: []);
  }

  /// `Enter email address`
  String get enterEmailAddress {
    return Intl.message(
      'Enter email address',
      name: 'enterEmailAddress',
      desc: '',
      args: [],
    );
  }

  /// `Enter Your User Title`
  String get enterYourUserTitle {
    return Intl.message(
      'Enter Your User Title',
      name: 'enterYourUserTitle',
      desc: '',
      args: [],
    );
  }

  /// `Enter User Role`
  String get enterUserRole {
    return Intl.message(
      'Enter User Role',
      name: 'enterUserRole',
      desc: '',
      args: [],
    );
  }

  /// `An Email has been sent\nCheck your inbox`
  String get anEmailHasBeenSentCheckYourInbox {
    return Intl.message(
      'An Email has been sent\\nCheck your inbox',
      name: 'anEmailHasBeenSentCheckYourInbox',
      desc: '',
      args: [],
    );
  }

  /// `Forget password`
  String get forgetPassword {
    return Intl.message(
      'Forget password',
      name: 'forgetPassword',
      desc: '',
      args: [],
    );
  }

  /// `Successfully deleted`
  String get successfullyDeleted {
    return Intl.message(
      'Successfully deleted',
      name: 'successfullyDeleted',
      desc: '',
      args: [],
    );
  }

  /// `Delete Successful`
  String get deleteSuccessful {
    return Intl.message(
      'Delete Successful',
      name: 'deleteSuccessful',
      desc: '',
      args: [],
    );
  }

  /// `You have to RE-LOGIN on your account`
  String get youHaveToRELOGINOnYourAccount {
    return Intl.message(
      'You have to RE-LOGIN on your account',
      name: 'youHaveToRELOGINOnYourAccount',
      desc: '',
      args: [],
    );
  }

  /// `Ok`
  String get Ok {
    return Intl.message('Ok', name: 'Ok', desc: '', args: []);
  }

  /// `Successfully Updated`
  String get successfullyUpdated {
    return Intl.message(
      'Successfully Updated',
      name: 'successfullyUpdated',
      desc: '',
      args: [],
    );
  }

  /// `Warehouse  Already Exists`
  String get warehouseAlreadyExists {
    return Intl.message(
      'Warehouse  Already Exists',
      name: 'warehouseAlreadyExists',
      desc: '',
      args: [],
    );
  }

  /// `Warehouse List`
  String get warehouseList {
    return Intl.message(
      'Warehouse List',
      name: 'warehouseList',
      desc: '',
      args: [],
    );
  }

  /// `Search with name`
  String get searchWithName {
    return Intl.message(
      'Search with name',
      name: 'searchWithName',
      desc: '',
      args: [],
    );
  }

  /// `Add WareHouse`
  String get addWareHouse {
    return Intl.message(
      'Add WareHouse',
      name: 'addWareHouse',
      desc: '',
      args: [],
    );
  }

  /// `Add New WareHouse`
  String get addNewWareHouse {
    return Intl.message(
      'Add New WareHouse',
      name: 'addNewWareHouse',
      desc: '',
      args: [],
    );
  }

  /// `Warehouse Name`
  String get warehouseName {
    return Intl.message(
      'Warehouse Name',
      name: 'warehouseName',
      desc: '',
      args: [],
    );
  }

  /// `Enter address`
  String get enterAddress {
    return Intl.message(
      'Enter address',
      name: 'enterAddress',
      desc: '',
      args: [],
    );
  }

  /// `Enter Warehouse Name`
  String get enterWarehouseName {
    return Intl.message(
      'Enter Warehouse Name',
      name: 'enterWarehouseName',
      desc: '',
      args: [],
    );
  }

  /// `Total value`
  String get totalValue {
    return Intl.message('Total value', name: 'totalValue', desc: '', args: []);
  }

  /// `Stock Quantity`
  String get stockQuantity {
    return Intl.message(
      'Stock Quantity',
      name: 'stockQuantity',
      desc: '',
      args: [],
    );
  }

  /// `InHouse can\'t be edit`
  String get inHouseCantBeEdit {
    return Intl.message(
      'InHouse can\\\'t be edit',
      name: 'inHouseCantBeEdit',
      desc: '',
      args: [],
    );
  }

  /// `InHouse can\'t be delete`
  String get inHouseCantBeDelete {
    return Intl.message(
      'InHouse can\\\'t be delete',
      name: 'inHouseCantBeDelete',
      desc: '',
      args: [],
    );
  }

  /// `Search with product name`
  String get searchWithProductName {
    return Intl.message(
      'Search with product name',
      name: 'searchWithProductName',
      desc: '',
      args: [],
    );
  }

  /// `Whatsapp Marketing SMS Template`
  String get whatsappMarketingSMSTemplate {
    return Intl.message(
      'Whatsapp Marketing SMS Template',
      name: 'whatsappMarketingSMSTemplate',
      desc: '',
      args: [],
    );
  }

  /// `Sales Template`
  String get salesTemplate {
    return Intl.message(
      'Sales Template',
      name: 'salesTemplate',
      desc: '',
      args: [],
    );
  }

  /// `Enter Sales Template`
  String get enterSalesTemplate {
    return Intl.message(
      'Enter Sales Template',
      name: 'enterSalesTemplate',
      desc: '',
      args: [],
    );
  }

  /// `Shortcodes`
  String get shortcodes {
    return Intl.message('Shortcodes', name: 'shortcodes', desc: '', args: []);
  }

  /// `Sales Return Template`
  String get salesReturnTemplate {
    return Intl.message(
      'Sales Return Template',
      name: 'salesReturnTemplate',
      desc: '',
      args: [],
    );
  }

  /// `Enter Sales Return Template`
  String get enterSalesReturnTemplate {
    return Intl.message(
      'Enter Sales Return Template',
      name: 'enterSalesReturnTemplate',
      desc: '',
      args: [],
    );
  }

  /// `Quotation Template`
  String get quotationTemplate {
    return Intl.message(
      'Quotation Template',
      name: 'quotationTemplate',
      desc: '',
      args: [],
    );
  }

  /// `Enter Quotation Template`
  String get enterQuotationTemplate {
    return Intl.message(
      'Enter Quotation Template',
      name: 'enterQuotationTemplate',
      desc: '',
      args: [],
    );
  }

  /// `Purchase Template`
  String get purchaseTemplate {
    return Intl.message(
      'Purchase Template',
      name: 'purchaseTemplate',
      desc: '',
      args: [],
    );
  }

  /// `Enter Purchase Template`
  String get enterPurchaseTemplate {
    return Intl.message(
      'Enter Purchase Template',
      name: 'enterPurchaseTemplate',
      desc: '',
      args: [],
    );
  }

  /// `Purchase Return Template`
  String get purchaseReturnTemplate {
    return Intl.message(
      'Purchase Return Template',
      name: 'purchaseReturnTemplate',
      desc: '',
      args: [],
    );
  }

  /// `Enter Purchase Return Template`
  String get enterPurchaseReturnTemplate {
    return Intl.message(
      'Enter Purchase Return Template',
      name: 'enterPurchaseReturnTemplate',
      desc: '',
      args: [],
    );
  }

  /// `Due Template`
  String get dueTemplate {
    return Intl.message(
      'Due Template',
      name: 'dueTemplate',
      desc: '',
      args: [],
    );
  }

  /// `Enter Due Template`
  String get enterDueTemplate {
    return Intl.message(
      'Enter Due Template',
      name: 'enterDueTemplate',
      desc: '',
      args: [],
    );
  }

  /// `Bulk Template`
  String get bulkTemplate {
    return Intl.message(
      'Bulk Template',
      name: 'bulkTemplate',
      desc: '',
      args: [],
    );
  }

  /// `Enter Bulk SMS Template`
  String get enterBulkSMSTemplate {
    return Intl.message(
      'Enter Bulk SMS Template',
      name: 'enterBulkSMSTemplate',
      desc: '',
      args: [],
    );
  }

  /// `Updating Template`
  String get updatingTemplate {
    return Intl.message(
      'Updating Template',
      name: 'updatingTemplate',
      desc: '',
      args: [],
    );
  }

  /// `Update Template`
  String get updateTemplate {
    return Intl.message(
      'Update Template',
      name: 'updateTemplate',
      desc: '',
      args: [],
    );
  }

  /// `Whatsapp Marketing is not enabled in your current subscription plan`
  String get whatsappMarketingIsNotEnabledInYourCurrentSubscriptionPlan {
    return Intl.message(
      'Whatsapp Marketing is not enabled in your current subscription plan',
      name: 'whatsappMarketingIsNotEnabledInYourCurrentSubscriptionPlan',
      desc: '',
      args: [],
    );
  }

  /// `Please Add A Product name`
  String get pleaseAddAProductName {
    return Intl.message(
      'Please Add A Product name',
      name: 'pleaseAddAProductName',
      desc: '',
      args: [],
    );
  }

  /// `Please Add A Product code`
  String get pleaseAddAProductCode {
    return Intl.message(
      'Please Add A Product code',
      name: 'pleaseAddAProductCode',
      desc: '',
      args: [],
    );
  }

  /// `Updating Package`
  String get updatingPackage {
    return Intl.message(
      'Updating Package',
      name: 'updatingPackage',
      desc: '',
      args: [],
    );
  }

  /// `Failed to Update Package`
  String get failedToUpdatePackage {
    return Intl.message(
      'Failed to Update Package',
      name: 'failedToUpdatePackage',
      desc: '',
      args: [],
    );
  }

  /// `Package Updated Successfully`
  String get packageUpdatedSuccess {
    return Intl.message(
      'Package Updated Successfully',
      name: 'packageUpdatedSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Confirm Delete`
  String get confirmDelete {
    return Intl.message(
      'Confirm Delete',
      name: 'confirmDelete',
      desc: '',
      args: [],
    );
  }

  /// `Delete Package Confirmation`
  String get deletePackageConfirmation {
    return Intl.message(
      'Delete Package Confirmation',
      name: 'deletePackageConfirmation',
      desc: '',
      args: [],
    );
  }

  /// `Package Deleted Successfully`
  String get packageDeletedSuccess {
    return Intl.message(
      'Package Deleted Successfully',
      name: 'packageDeletedSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Failed to Delete Package`
  String get failedToDeletePackage {
    return Intl.message(
      'Failed to Delete Package',
      name: 'failedToDeletePackage',
      desc: '',
      args: [],
    );
  }
  /// `Please Select a product Category`
  String get pleaseSelectAProductCategory {
    return Intl.message(
      'Please Select a product Category',
      name: 'pleaseSelectAProductCategory',
      desc: '',
      args: [],
    );
  }

  /// `Please Select a brand`
  String get pleaseSelectABrand {
    return Intl.message(
      'Please Select a brand',
      name: 'pleaseSelectABrand',
      desc: '',
      args: [],
    );
  }

  /// `Enter stock number`
  String get enterStockNumber {
    return Intl.message(
      'Enter stock number',
      name: 'enterStockNumber',
      desc: '',
      args: [],
    );
  }

  /// `Select unit type`
  String get selectUnitType {
    return Intl.message(
      'Select unit type',
      name: 'selectUnitType',
      desc: '',
      args: [],
    );
  }

  /// `Please add sale price`
  String get pleaseAddSalePrice {
    return Intl.message(
      'Please add sale price',
      name: 'pleaseAddSalePrice',
      desc: '',
      args: [],
    );
  }

  /// `Please add purchase price`
  String get pleaseAddPurchasePrice {
    return Intl.message(
      'Please add purchase price',
      name: 'pleaseAddPurchasePrice',
      desc: '',
      args: [],
    );
  }

  /// `Successfull`
  String get successfull {
    return Intl.message('Successfull', name: 'successfull', desc: '', args: []);
  }

    String get selectComponent {
    return Intl.message('Select a category to add', name: 'selectcomponent', desc: '', args: []);
  }

      String get addComponent {
    return Intl.message('Add component', name: 'addcomponent', desc: '', args: []);
  }
}



class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'es'),
      Locale.fromSubtags(languageCode: 'en'),
      
      /*Locale.fromSubtags(languageCode: 'af'),
      Locale.fromSubtags(languageCode: 'ar'),
      Locale.fromSubtags(languageCode: 'as'),
      Locale.fromSubtags(languageCode: 'az'),
      Locale.fromSubtags(languageCode: 'be'),
      Locale.fromSubtags(languageCode: 'bn'),
      Locale.fromSubtags(languageCode: 'bs'),
      Locale.fromSubtags(languageCode: 'ca'),
      Locale.fromSubtags(languageCode: 'cs'),
      Locale.fromSubtags(languageCode: 'cy'),
      Locale.fromSubtags(languageCode: 'da'),
      Locale.fromSubtags(languageCode: 'de'),
      Locale.fromSubtags(languageCode: 'el'),
      Locale.fromSubtags(languageCode: 'et'),
      Locale.fromSubtags(languageCode: 'eu'),
      Locale.fromSubtags(languageCode: 'fa'),
      Locale.fromSubtags(languageCode: 'fi'),
      Locale.fromSubtags(languageCode: 'fr'),
      Locale.fromSubtags(languageCode: 'gl'),
      Locale.fromSubtags(languageCode: 'gu'),
      Locale.fromSubtags(languageCode: 'he'),
      Locale.fromSubtags(languageCode: 'hi'),
      Locale.fromSubtags(languageCode: 'hr'),
      Locale.fromSubtags(languageCode: 'hu'),
      Locale.fromSubtags(languageCode: 'hy'),
      Locale.fromSubtags(languageCode: 'id'),
      Locale.fromSubtags(languageCode: 'is'),
      Locale.fromSubtags(languageCode: 'it'),
      Locale.fromSubtags(languageCode: 'ja'),
      Locale.fromSubtags(languageCode: 'kk'),
      Locale.fromSubtags(languageCode: 'km'),
      Locale.fromSubtags(languageCode: 'kn'),
      Locale.fromSubtags(languageCode: 'ko'),
      Locale.fromSubtags(languageCode: 'ky'),
      Locale.fromSubtags(languageCode: 'lo'),
      Locale.fromSubtags(languageCode: 'lt'),
      Locale.fromSubtags(languageCode: 'lv'),
      Locale.fromSubtags(languageCode: 'mk'),
      Locale.fromSubtags(languageCode: 'ml'),
      Locale.fromSubtags(languageCode: 'mr'),
      Locale.fromSubtags(languageCode: 'ms'),
      Locale.fromSubtags(languageCode: 'my'),
      Locale.fromSubtags(languageCode: 'ne'),
      Locale.fromSubtags(languageCode: 'nl'),
      Locale.fromSubtags(languageCode: 'no'),
      Locale.fromSubtags(languageCode: 'pa'),
      Locale.fromSubtags(languageCode: 'pl'),
      Locale.fromSubtags(languageCode: 'ps'),
      Locale.fromSubtags(languageCode: 'pt'),
      Locale.fromSubtags(languageCode: 'ro'),
      Locale.fromSubtags(languageCode: 'ru'),
      Locale.fromSubtags(languageCode: 'si'),
      Locale.fromSubtags(languageCode: 'sk'),
      Locale.fromSubtags(languageCode: 'sq'),
      Locale.fromSubtags(languageCode: 'sr'),
      Locale.fromSubtags(languageCode: 'sv'),
      Locale.fromSubtags(languageCode: 'sw'),
      Locale.fromSubtags(languageCode: 'ta'),
      Locale.fromSubtags(languageCode: 'th'),
      Locale.fromSubtags(languageCode: 'tr'),
      Locale.fromSubtags(languageCode: 'uk'),
      Locale.fromSubtags(languageCode: 'ur'),
      Locale.fromSubtags(languageCode: 'vi'),
      Locale.fromSubtags(languageCode: 'zh'),*/
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }


}
