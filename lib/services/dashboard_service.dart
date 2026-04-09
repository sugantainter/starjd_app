import 'dart:io';
import 'package:dio/dio.dart';
import 'auth_service.dart';

class CreatorDashboardService {
  static Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final c = await AuthService.client;
      final response = await c.get('/api/creator/dashboard');
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to load dashboard'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getPackages() async {
    try {
      final c = await AuthService.client;
      final response = await c.get('/api/creator/packages');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getPackageCategories() async {
    try {
      final c = await AuthService.client;
      final response = await c.get('/api/creator/packages/categories');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> savePackage(Map<String, dynamic> data, {int? id}) async {
    try {
      final c = await AuthService.client;
      final response = id == null 
        ? await c.post('/api/creator/packages', data: data)
        : await c.put('/api/creator/packages/$id', data: data);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deletePackage(int id) async {
    try {
      final c = await AuthService.client;
      await c.delete('/api/creator/packages/$id');
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getImagePosts() async {
    try {
      final c = await AuthService.client;
      final response = await c.get('/api/creator/image-posts');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> uploadImagePost(File file, String caption) async {
    try {
      final c = await AuthService.client;
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(file.path, filename: fileName),
        'caption': caption,
      });
      final response = await c.post('/api/creator/image-posts', data: formData);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getSocialAccounts() async {
    try {
      final c = await AuthService.client;
      final response = await c.get('/api/creator/social-accounts');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> syncSocialAccount(Map<String, dynamic> data) async {
    try {
      final c = await AuthService.client;
      final response = await c.post('/api/creator/social-accounts/sync', data: data);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> disconnectSocialAccount(String platform) async {
    try {
      final c = await AuthService.client;
      await c.delete('/api/creator/social-accounts/$platform');
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> refreshSocialAccountStats(String platform) async {
    try {
      final c = await AuthService.client;
      final response = await c.post('/api/creator/social-accounts/$platform/refresh');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}

class BrandDashboardService {
  static Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final c = await AuthService.client;
      final response = await c.get('/api/brand/dashboard');
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to load dashboard'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getCampaigns() async {
    try {
      final c = await AuthService.client;
      final response = await c.get('/api/brand/campaigns');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getCampaignDetail(int id) async {
    try {
      final c = await AuthService.client;
      final response = await c.get('/api/brand/campaigns/$id');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> saveCampaign(Map<String, dynamic> data, {int? id}) async {
    try {
      final c = await AuthService.client;
      final response = id == null 
        ? await c.post('/api/brand/campaigns', data: data)
        : await c.put('/api/brand/campaigns/$id', data: data);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateApplicationStatus(int applicationId, String status) async {
    try {
      final c = await AuthService.client;
      final response = await c.patch('/api/brand/campaign-applications/$applicationId', data: {
        'status': status,
      });
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}

class StudioOwnerDashboardService {
  static Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final c = await AuthService.client;
      final response = await c.get('/api/studio-owner/dashboard');
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to load dashboard'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getStudios() async {
    try {
      final c = await AuthService.client;
      final response = await c.get('/api/studio-owner/studios');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getStudioDetail(int id) async {
    try {
      final c = await AuthService.client;
      final response = await c.get('/api/studio-owner/studios/$id');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> saveStudio(Map<String, dynamic> data, {int? id, List<File>? images}) async {
    try {
      final c = await AuthService.client;
      
      FormData formData = FormData.fromMap(data);
      
      if (images != null && images.isNotEmpty) {
        for (var i = 0; i < images.length; i++) {
          formData.files.add(MapEntry(
            'images[]',
            await MultipartFile.fromFile(images[i].path, filename: images[i].path.split('/').last),
          ));
        }
      }

      final response = id == null 
        ? await c.post('/api/studio-owner/studios', data: formData)
        : await c.post('/api/studio-owner/studios/$id?_method=PUT', data: formData); // Using POST with _method=PUT for multipart support
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to save studio'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteStudio(int id) async {
    try {
      final c = await AuthService.client;
      await c.delete('/api/studio-owner/studios/$id');
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getBookings() async {
    try {
      final c = await AuthService.client;
      final response = await c.get('/api/studio-owner/bookings');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getAvailability(int studioId) async {
    try {
      final c = await AuthService.client;
      final response = await c.get('/api/studio-owner/studios/$studioId/availability');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> saveAvailability(int studioId, Map<String, dynamic> data) async {
    try {
      final c = await AuthService.client;
      final response = await c.post('/api/studio-owner/studios/$studioId/availability', data: data);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteAvailabilitySlot(int slotId) async {
    try {
      final c = await AuthService.client;
      await c.delete('/api/studio-owner/availability-slots/$slotId');
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
