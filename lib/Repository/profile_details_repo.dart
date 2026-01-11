import '../currency.dart';
import '../model/personal_information_model.dart';
import '../services/api_service.dart';

/// Repositorio de perfil/información personal - Usa PostgreSQL API
class ProfileRepo {
  final ApiService _apiService = ApiService();

  /// Obtener detalles del perfil desde PostgreSQL
  Future<PersonalInformationModel> getDetails() async {
    PersonalInformationModel personalInfo = PersonalInformationModel(
      companyName: 'Loading...',
      businessCategory: 'Loading...',
      countryName: 'Loading...',
      language: 'Loading...',
      phoneNumber: 'Loading...',
      pictureUrl: 'https://cdn.pixabay.com/photo/2017/06/13/12/53/profile-2398782_960_720.png',
      shopOpeningBalance: 0,
      dueInvoiceCounter: 1,
      purchaseInvoiceCounter: 1,
      saleInvoiceCounter: 1,
      remainingShopBalance: 0,
      currency: '\$',
      currentLocale: 'en',
      gst: '',
    );

    try {
      final response = await _apiService.get('profile');

      if (response.success && response.data != null) {
        final data = response.data['profile'] ?? response.data;
        if (data != null) {
          return PersonalInformationModel.fromJson(data as Map<String, dynamic>);
        }
      }

      currency = personalInfo.currency;
      return personalInfo;
    } catch (e) {
      currency = personalInfo.currency;
      return personalInfo;
    }
  }

  /// Verificar si el perfil está configurado
  Future<bool> isProfileSetupDone() async {
    try {
      final response = await _apiService.get('profile');

      if (response.success && response.data != null) {
        final data = response.data['profile'] ?? response.data;
        return data != null;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Actualizar perfil
  Future<bool> updateProfile(PersonalInformationModel profile) async {
    try {
      final profileData = Map<String, dynamic>.from(profile.toJson());
      final response = await _apiService.put('profile', profileData);
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// Crear perfil inicial
  Future<bool> createProfile(PersonalInformationModel profile) async {
    try {
      final profileData = Map<String, dynamic>.from(profile.toJson());
      final response = await _apiService.post('profile', profileData);
      return response.success;
    } catch (e) {
      return false;
    }
  }
}
