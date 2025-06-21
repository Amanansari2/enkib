import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../data/provider/auth_provider.dart';

final String baseUrl = 'https://www.suganta.com/api';

Future<Map<String, dynamic>> registerUser(Map<String, dynamic> userData) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData;
    } else if (response.statusCode == 422) {
      final responseData = jsonDecode(response.body);
      String errorMessage = 'Validation error occurred';

      if (responseData.containsKey('message')) {
        errorMessage = responseData['message'];
      } else if (responseData.containsKey('errors') &&
          responseData['errors'].containsKey('email')) {
        errorMessage = responseData['errors']['email'].join(', ');
      }

      throw {'message': errorMessage, 'status': response.statusCode};
    } else {
      throw {
        'message': 'An unexpected error occurred.',
        'status': response.statusCode,
      };
    }
  } catch (e) {
    if (e is Map<String, dynamic>) {
      throw e;
    } else {
      throw {
        'message': 'An unexpected error occurred during registration.',
        'status': 500,
      };
    }
  }
}

Future<Map<String, dynamic>> loginUser(String email, String password) async {
  final uri = Uri.parse('$baseUrl/login');
  final headers = <String, String>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  final body = json.encode({'email': email, 'password': password});

  final response = await http.post(uri, headers: headers, body: body);

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    final error = json.decode(response.body);
    throw Exception(error['message'] ?? 'Failed to login');
  }
}

Future<Map<String, dynamic>> forgetPassword(String email) async {
  final uri = Uri.parse('$baseUrl/forget-password');
  final headers = <String, String>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  final body = json.encode({'email': email});

  final response = await http.post(uri, headers: headers, body: body);

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else if (response.statusCode == 403) {
    var errorData = jsonDecode(response.body);
    String errorMessage =
        errorData['message'] ?? "You can't add/edit anything on the demo site";
    return {'status': 403, 'message': errorMessage};
  } else if (response.statusCode == 401) {
    return {
      'status': 401,
      'message': "Unauthorized access. Please log in again.",
    };
  } else {
    final error = json.decode(response.body);
    return {
      'status': response.statusCode,
      'message': error['message'] ?? 'Something went wrong',
    };
  }
}

Future<Map<String, dynamic>> resendEmail(String token) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/resend-email');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 403) {
      var errorData = jsonDecode(response.body);
      String errorMessage =
          errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {'status': 403, 'message': errorMessage};
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to resend email');
    }
  } catch (e) {
    throw 'Failed to resend email: $e';
  }
}

Future<Map<String, dynamic>> logout(String token) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/logout');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.post(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to resend email');
    }
  } catch (e) {
    throw 'Failed to resend email: $e';
  }
}

Future<Map<String, dynamic>> updatePassword(
  Map<String, dynamic> userData,
  String token,
  int id,
) async {
  final uri = Uri.parse('$baseUrl/update-password/$id');
  final headers = <String, String>{
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  final response = await http.post(
    uri,
    headers: headers,
    body: json.encode(userData),
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else if (response.statusCode == 403) {
    var errorData = jsonDecode(response.body);
    String errorMessage =
        errorData['message'] ?? "You can't add/edit anything on the demo site";
    return {'status': 403, 'message': errorMessage};
  } else if (response.statusCode == 401) {
    return {
      'status': 401,
      'message': "Unauthorized access. Please log in again.",
    };
  } else {
    throw Exception('Failed to update password');
  }
}

Future<Map<String, dynamic>> findTutors({
  int page = 1,
  int perPage = 5,
  String? sortBy,
  String? keyword,
  double? maxPrice,
  int? country,
  int? groupId,
  String? sessionType,
  List<int>? subjectIds,
  List<int>? languageIds,
}) async {
  try {
    final Map<String, dynamic> queryParams = {
      'page': page.toString(),
      'per_page': perPage.toString(),
      'sort_by': sortBy,
      'keyword': keyword,
      'max_price': maxPrice?.toString(),
      'country': country?.toString(),
      'group_id': groupId?.toString(),
      'session_type': sessionType,
      'subject_id': subjectIds != null ? subjectIds.join(',') : null,
      'language_id': languageIds != null ? languageIds.join(',') : null,
    };

    queryParams.removeWhere((key, value) => value == null);

    final Uri uri = Uri.parse(
      '$baseUrl/find-tutors',
    ).replace(queryParameters: queryParams);

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get tutors');
    }
  } catch (e) {
    throw 'Failed to get tutors: $e';
  }
}

Future<Map<String, dynamic>> getTutors(String? token, String slug) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/tutor/$slug');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get tutors');
    }
  } catch (e) {
    throw 'Failed to get tutors $e';
  }
}

Future<Map<String, dynamic>> getTutorsEducation(String? token, int id) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/tutor-education/$id');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get education');
    }
  } catch (e) {
    throw 'Failed to get education $e';
  }
}

Future<Map<String, dynamic>> getTutorsExperience(String? token, int id) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/tutor-experience/$id');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get experience');
    }
  } catch (e) {
    throw 'Failed to get experience $e';
  }
}

Future<Map<String, dynamic>> getTutorsCertification(
  String? token,
  int id,
) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/tutor-certification/$id');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get certification');
    }
  } catch (e) {
    throw 'Failed to get certification $e';
  }
}

Future<Map<String, dynamic>> addEducation(
  String token,
  Map<String, dynamic> data,
) async {
  final Uri uri = Uri.parse('$baseUrl/tutor-education');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  try {
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(data),
    );

    final decodedResponse = json.decode(response.body);

    if (response.statusCode == 200) {
      return decodedResponse;
    } else if (response.statusCode == 403) {
      var errorData = jsonDecode(response.body);
      String errorMessage =
          errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {'status': 403, 'message': errorMessage};
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      return {
        'status': response.statusCode,
        'message': decodedResponse['message'] ?? 'Failed to add education',
        'errors': decodedResponse['errors'],
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'Failed to add education'};
  }
}

Future<Map<String, dynamic>> getCountries(String? token) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/countries');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get countries');
    }
  } catch (e) {
    throw 'Failed to get countries $e';
  }
}

Future<Map<String, dynamic>> getLanguages(String? token) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/languages');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get languages');
    }
  } catch (e) {
    throw 'Failed to get languages $e';
  }
}

Future<Map<String, dynamic>> getSubjects(String? token) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/subjects');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get subjects');
    }
  } catch (e) {
    throw 'Failed to get subjects $e';
  }
}

Future<Map<String, dynamic>> getSubjectsGroup(String? token) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/subject-groups');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get subjects group');
    }
  } catch (e) {
    throw 'Failed to get subjects group $e';
  }
}

Future<Map<String, dynamic>> getCountryStates(
  String? token,
  int countryId,
) async {
  try {
    final Uri uri = Uri.parse(
      '$baseUrl/country-states',
    ).replace(queryParameters: {'country_id': countryId.toString()});
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get country states');
    }
  } catch (e) {
    throw 'Failed to get country states $e';
  }
}

Future<Map<String, dynamic>> deleteEducation(String token, int id) async {
  final url = Uri.parse('$baseUrl/tutor-education/$id');

  try {
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 403) {
      var errorData = jsonDecode(response.body);
      String errorMessage =
          errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {'status': 403, 'message': errorMessage};
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      return {
        'status': response.statusCode,
        'message': 'Failed to delete education: ${response.reasonPhrase}',
      };
    }
  } catch (error) {
    return {'status': 500, 'message': 'Error occurred: $error'};
  }
}

Future<Map<String, dynamic>> savedTutors(String token) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/favourite-tutors');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get saved tutors');
    }
  } catch (e) {
    throw 'Failed to get saved tutors $e';
  }
}

Future<Map<String, dynamic>> addDeleteFavouriteTutors(
  String token,
  int tutorId,
  AuthProvider authProvider,
) async {
  final url = Uri.parse('$baseUrl/favourite-tutors/$tutorId');

  try {
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      authProvider.toggleFavoriteStatus(tutorId);
      return jsonDecode(response.body);
    } else if (response.statusCode == 403) {
      var errorData = jsonDecode(response.body);
      String errorMessage =
          errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {'status': 403, 'message': errorMessage};
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      return {
        'status': response.statusCode,
        'message': 'Failed to update favorite status: ${response.reasonPhrase}',
      };
    }
  } catch (error) {
    return {'status': 500, 'message': 'Error occurred: $error'};
  }
}

Future<Map<String, dynamic>> updateEducation(
  String token,
  int id,
  Map<String, dynamic> educationData,
) async {
  final url = Uri.parse('$baseUrl/tutor-education/$id');
  try {
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(educationData),
    );

    final decodedResponse = json.decode(response.body);

    if (response.statusCode == 200) {
      return decodedResponse;
    } else if (response.statusCode == 403) {
      var errorData = jsonDecode(response.body);
      String errorMessage =
          errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {'status': 403, 'message': errorMessage};
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      return {
        'status': response.statusCode,
        'message': decodedResponse['message'] ?? 'Failed to update education',
        'errors': decodedResponse['errors'],
      };
    }
  } catch (error) {
    return {'status': 500, 'message': 'Error occurred: $error'};
  }
}

Future<Map<String, dynamic>> addExperience(
  String token,
  Map<String, dynamic> data,
) async {
  final Uri uri = Uri.parse('$baseUrl/tutor-experience');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  try {
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(data),
    );

    final decodedResponse = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return decodedResponse;
    } else if (response.statusCode == 403) {
      var errorData = jsonDecode(response.body);
      String errorMessage =
          errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {'status': 403, 'message': errorMessage};
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = decodedResponse;
      return {
        'status': response.statusCode,
        'message': error['message'] ?? 'Failed to add experience',
        'errors': error['errors'] ?? {},
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'Failed to add experience'};
  }
}

Future<Map<String, dynamic>> deleteExperience(String token, int id) async {
  final url = Uri.parse('$baseUrl/tutor-experience/$id');

  try {
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 403) {
      var errorData = jsonDecode(response.body);
      String errorMessage =
          errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {'status': 403, 'message': errorMessage};
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      return {
        'status': response.statusCode,
        'message': 'Failed to delete experience: ${response.reasonPhrase}',
      };
    }
  } catch (error) {
    return {'status': 500, 'message': 'Error occurred: $error'};
  }
}

Future<Map<String, dynamic>> updateExperience(
  String token,
  int id,
  Map<String, dynamic> experienceData,
) async {
  final url = Uri.parse('$baseUrl/tutor-experience/$id');

  try {
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(experienceData),
    );

    final decodedResponse = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return decodedResponse;
    } else if (response.statusCode == 403) {
      var errorData = jsonDecode(response.body);
      String errorMessage =
          errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {'status': 403, 'message': errorMessage};
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = decodedResponse;
      return {
        'status': response.statusCode,
        'message': error['message'] ?? 'Failed to update experience',
        'errors': error['errors'] ?? {},
      };
    }
  } catch (error) {
    return {'status': 500, 'message': 'Error occurred: $error'};
  }
}

Future<Map<String, dynamic>> addCertification(
  String token,
  Map<String, dynamic> data,
) async {
  final Uri uri = Uri.parse('$baseUrl/tutor-certification');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  try {
    var request =
        http.MultipartRequest('POST', uri)
          ..headers.addAll(headers)
          ..fields['title'] = data['title']
          ..fields['institute_name'] = data['institute_name']
          ..fields['issue_date'] = data['issue_date']
          ..fields['expiry_date'] = data['expiry_date']
          ..fields['description'] = data['description'];

    if (data['image'] != null && data['image']!.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          data['image']!,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    final decodedResponse = jsonDecode(responseBody);

    if (response.statusCode == 200) {
      return decodedResponse;
    } else if (response.statusCode == 403) {
      var errorData = decodedResponse;
      String errorMessage =
          errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {'status': 403, 'message': errorMessage};
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = decodedResponse;
      return {
        'status': response.statusCode,
        'message': error['message'] ?? 'Failed to add certification',
        'errors': error['errors'] ?? {},
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'Failed to add certification'};
  }
}

Future<Map<String, dynamic>> deleteCertification(String token, int id) async {
  final url = Uri.parse('$baseUrl/tutor-certification/$id');

  try {
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 403) {
      var errorData = jsonDecode(response.body);
      String errorMessage =
          errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {'status': 403, 'message': errorMessage};
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      return {
        'status': response.statusCode,
        'message': 'Failed to delete certification: ${response.reasonPhrase}',
      };
    }
  } catch (error) {
    return {'status': 500, 'message': 'Error occurred: $error'};
  }
}

Future<Map<String, dynamic>> updateCertification(
  String token,
  int id,
  Map<String, dynamic> certificationData,
) async {
  final Uri uri = Uri.parse('$baseUrl/tutor-certification/$id');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  try {
    var request =
        http.MultipartRequest('POST', uri)
          ..headers.addAll(headers)
          ..fields['title'] = certificationData['title']
          ..fields['institute_name'] = certificationData['institute_name']
          ..fields['issue_date'] = certificationData['issue_date']
          ..fields['expiry_date'] = certificationData['expiry_date']
          ..fields['description'] = certificationData['description'];

    if (certificationData['image'] != null &&
        certificationData['image']!.isNotEmpty) {
      final imagePath = certificationData['image']!;

      if (Uri.parse(imagePath).isAbsolute) {
        final encodedImagePath = Uri.encodeFull(imagePath);

        final response = await http.get(Uri.parse(encodedImagePath));
        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          final fileName = imagePath.split('/').last;

          final contentType = _getContentTypeFromExtension(fileName);

          request.files.add(
            http.MultipartFile.fromBytes(
              'image',
              bytes,
              filename: fileName,
              contentType: contentType,
            ),
          );
        } else {
          return {
            'status': 500,
            'message': 'Failed to download image from URL.',
          };
        }
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imagePath,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return json.decode(responseBody);
    } else if (response.statusCode == 403) {
      var errorData = jsonDecode(responseBody);
      String errorMessage =
          errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {'status': 403, 'message': errorMessage};
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(responseBody);
      return {
        'status': response.statusCode,
        'message': error['message'] ?? 'Failed to update certification',
      };
    }
  } catch (error) {
    return {'status': 500, 'message': 'Error occurred: $error'};
  }
}

MediaType _getContentTypeFromExtension(String fileName) {
  if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
    return MediaType('image', 'jpeg');
  } else if (fileName.endsWith('.png')) {
    return MediaType('image', 'png');
  } else if (fileName.endsWith('.gif')) {
    return MediaType('image', 'gif');
  } else {
    return MediaType('image', 'jpeg');
  }
}

Future<Map<String, dynamic>> getProfile(String token, int id) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/profile-settings/$id');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get profile settings');
    }
  } catch (e) {
    throw 'Failed to get profile settings $e';
  }
}

Future<Map<String, dynamic>> getMyEarnings(String token, int id) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/my-earning/$id');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get earning');
    }
  } catch (e) {
    throw 'Failed to get earning $e';
  }
}

Future<Map<String, dynamic>> getPayouts(
  String token,
  int id, {
  int page = 1,
}) async {
  try {
    final Map<String, dynamic> queryParams = {'page': page.toString()};

    final Uri uri = Uri.parse(
      '$baseUrl/tutor-payouts/$id',
    ).replace(queryParameters: queryParams);
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get payouts');
    }
  } catch (e) {
    throw 'Failed to get payouts $e';
  }
}

Future<Map<String, dynamic>> getPayoutStatus(String token) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/payout-status');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get earning');
    }
  } catch (e) {
    throw 'Failed to get earning $e';
  }
}

Future<Map<String, dynamic>> payoutMethod(
  String token,
  Map<String, dynamic> data,
) async {
  final Uri uri = Uri.parse('$baseUrl/payout-method');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  try {
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 403) {
      var errorData = jsonDecode(response.body);
      String errorMessage =
          errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {'status': 403, 'message': errorMessage};
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      return {
        'status': response.statusCode,
        'message': error['message'] ?? 'Failed to add payout method',
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'Failed to add payout method'};
  }
}

Future<Map<String, dynamic>> deletePayoutMethod(
  String token,
  String method,
) async {
  final Uri url = Uri.parse('$baseUrl/payout-method');
  final Map<String, String> headers = {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  try {
    final response = await http.delete(
      url,
      headers: headers,
      body: jsonEncode({'current_method': method}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 403) {
      var errorData = jsonDecode(response.body);
      String errorMessage =
          errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {'status': 403, 'message': errorMessage};
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      return {
        'status': response.statusCode,
        'message': 'Failed to delete payout method: ${response.reasonPhrase}',
      };
    }
  } catch (error) {
    return {'status': 500, 'message': 'Error occurred: $error'};
  }
}

Future<Map<String, dynamic>> userWithdrawal(
  String token,
  Map<String, dynamic> data,
) async {
  final Uri uri = Uri.parse('$baseUrl/user-withdrawal');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  try {
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 403) {
      var errorData = jsonDecode(response.body);
      String errorMessage =
          errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {'status': 403, 'message': errorMessage};
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      return {
        'status': response.statusCode,
        'message': error['message'] ?? 'Failed to add withdrawal',
        'errors': error['errors'] ?? {},
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'Failed to add withdrawal', 'errors': {}};
  }
}

Future<Map<String, dynamic>> getBookings(
  String token,
  String startDate,
  String endDate,
) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/upcoming-bookings').replace(
      queryParameters: {
        'show_by': 'daily',
        'start_date': startDate,
        'end_date': endDate,
        'type': '',
      },
    );

    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      throw Exception('Failed to load bookings');
    }
  } catch (e) {
    throw 'Error fetching bookings: $e';
  }
}

Future<Map<String, dynamic>> getInvoices(String token, {int page = 1}) async {
  try {
    final Map<String, dynamic> queryParams = {'page': page.toString()};

    final Uri uri = Uri.parse(
      '$baseUrl/invoices',
    ).replace(queryParameters: queryParams);
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get invoices');
    }
  } catch (e) {
    throw 'Failed to get invoices $e';
  }
}

Future<Map<String, dynamic>> getIdentityVerification(
  String token,
  int id,
) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/identity-verification/$id');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(
        error['message'] ?? 'Failed to get identity verification',
      );
    }
  } catch (e) {
    throw 'Failed to get identity verification $e';
  }
}

Future<Map<String, dynamic>> identityVerification(
  String token,
  Map<String, dynamic> data,
  File? image,
  File? identificationCard,
  File? transcript,
) async {
  final Uri uri = Uri.parse('$baseUrl/identity-verification');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  try {
    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll(headers);

    data.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
    });

    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }

    if (identificationCard != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'identificationCard',
          identificationCard.path,
        ),
      );
    }

    if (transcript != null) {
      request.files.add(
        await http.MultipartFile.fromPath('transcript', transcript.path),
      );
    }

    final response = await request.send();
    final responseData = await http.Response.fromStream(response);
    final decodedResponse = json.decode(responseData.body);

    if (response.statusCode == 200) {
      return decodedResponse;
    } else if (response.statusCode == 403) {
      var errorData = decodedResponse;
      String errorMessage =
          errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {'status': 403, 'message': errorMessage};
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      return {
        'status': response.statusCode,
        'message': decodedResponse['message'] ?? 'Failed to verify identity',
        'errors': decodedResponse['errors'] ?? {},
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'Failed to submit identity verification'};
  }
}

Future<Map<String, dynamic>> getTutorAvailableSlots(
  String token,
  String userId,
) async {
  final Uri uri = Uri.parse(
    '$baseUrl/tutor-available-slots',
  ).replace(queryParameters: {'user_id': userId});
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  try {
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch available slots');
    }
  } catch (e) {
    throw 'Error fetching available slots: $e';
  }
}

Future<Map<String, dynamic>> getStudentReviews(
  String? token,
  int id, {
  int page = 1,
  int? perPage,
}) async {
  try {
    final Uri uri = Uri.parse(
      '$baseUrl/student-reviews/$id?page=$page&perPage=$perPage',
    );

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get student reviews');
    }
  } catch (e) {
    throw 'Failed to get student reviews $e';
  }
}

Future<Map<String, dynamic>> getBillingDetail(String token, int id) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/billing-detail/$id');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get billing detail');
    }
  } catch (e) {
    throw 'Failed to get identity billing detail $e';
  }
}

Future<Map<String, dynamic>> addBillingDetail(
  String token,
  Map<String, dynamic> data,
) async {
  final Uri uri = Uri.parse('$baseUrl/billing-detail');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  try {
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(data),
    );

    final decodedResponse = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return decodedResponse;
    } else if (response.statusCode == 403) {
      var errorData = jsonDecode(response.body);
      String errorMessage =
          errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {'status': 403, 'message': errorMessage};
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = decodedResponse;
      return {
        'status': response.statusCode,
        'message': error['message'] ?? 'Failed to add billing detail:',
        'errors': error['errors'] ?? {},
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'Failed to add billing detail:'};
  }
}

Future<Map<String, dynamic>> updateBillingDetails(
  String token,
  int id,
  Map<String, dynamic> updateBillingData,
) async {
  final url = Uri.parse('$baseUrl/billing-detail/$id');

  try {
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(updateBillingData),
    );

    final decodedResponse = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return decodedResponse;
    } else if (response.statusCode == 403) {
      var errorData = jsonDecode(response.body);
      String errorMessage =
          errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {'status': 403, 'message': errorMessage};
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      return {
        'status': response.statusCode,
        'errors': decodedResponse['errors'] ?? {},
      };
    }
  } catch (error) {
    return {'status': 500, 'message': 'Error occurred: $error'};
  }
}

Future<Map<String, dynamic>> bookSessionCart(
  String token,
  Map<String, dynamic> data,
  String id,
) async {
  final Uri uri = Uri.parse(
    '$baseUrl/booking-cart',
  ).replace(queryParameters: {'id': id});
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  try {
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(data),
    );

    final decodedResponse = json.decode(response.body);

    if (response.statusCode == 200) {
      return decodedResponse;
    } else if (response.statusCode == 403) {
      var errorData = jsonDecode(response.body);
      String errorMessage =
          errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {'status': 403, 'message': errorMessage};
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      return {
        'status': response.statusCode,
        'message': decodedResponse['message'] ?? 'Failed to book session',
        'errors': decodedResponse['errors'],
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'Failed to book session'};
  }
}

Future<Map<String, dynamic>> getBookingCart(String token) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/booking-cart');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? '');
    }
  } catch (e) {
    throw 'Failed to get booking cart $e';
  }
}

Future<Map<String, dynamic>> deleteBookingCart(String token, int id) async {
  final url = Uri.parse('$baseUrl/booking-cart/$id');

  try {
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 403) {
      var errorData = jsonDecode(response.body);
      String errorMessage =
          errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {'status': 403, 'message': errorMessage};
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      return {
        'status': response.statusCode,
        'message': 'Failed to delete booking cart: ${response.reasonPhrase}',
      };
    }
  } catch (error) {
    return {'status': 500, 'message': 'Error occurred: $error'};
  }
}

Future<Map<String, dynamic>> postCheckOut(
  String token,
  Map<String, dynamic> data,
) async {
  final Uri uri = Uri.parse('$baseUrl/checkout');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  try {
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(data),
    );

    final decodedResponse = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return decodedResponse;
    } else if (response.statusCode == 403) {
      var errorData = jsonDecode(response.body);
      String errorMessage =
          errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {'status': 403, 'message': errorMessage};
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = decodedResponse;
      return {
        'status': response.statusCode,
        'message': error['message'] ?? 'Failed to add billing detail:',
        'errors': error['errors'] ?? {},
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'Failed to add billing detail:'};
  }
}

Future<Map<String, dynamic>> getEarningDetails(String token) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/earning-detail');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get earning details');
    }
  } catch (e) {
    throw 'Failed to get earning details $e';
  }
}

Future<Map<String, dynamic>> getForumCategories(
  String? token, {
  String sortBy = 'asc',
}) async {
  try {
    final Uri uri = Uri.parse(
      '$baseUrl/forumwise/categories',
    ).replace(queryParameters: {'sortby': sortBy});

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch forum categories');
    }
  } catch (e) {
    throw 'Error fetching forum categories: $e';
  }
}

Future<Map<String, dynamic>> getForums(
  String? token, {
  String sortBy = 'asc',
  String title = '',
}) async {
  try {
    final Uri uri = Uri.parse(
      '$baseUrl/forumwise/forums',
    ).replace(queryParameters: {'sortby': sortBy, 'title': title});

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch forums');
    }
  } catch (e) {
    throw 'Error fetching forums: $e';
  }
}

Future<Map<String, dynamic>> getPopularTopics(String? token) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/forumwise/popular-topics-media');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch popular topics');
    }
  } catch (e) {
    throw 'Error fetching popular topics: $e';
  }
}

Future<Map<String, dynamic>> getTopUsers(String? token) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/forumwise/top-user-media');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch users');
    }
  } catch (e) {
    throw 'Error fetching popular users: $e';
  }
}

Future<Map<String, dynamic>> getTopics(
  String? token, {
  String sortBy = 'asc',
  String? filterType = 'my',
  String? title,
  String? slug,
}) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/forumwise/topics').replace(
      queryParameters: {
        'sortby': sortBy,
        'filterType': filterType,
        'title': title,
        'slug': slug,
      },
    );

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch topics');
    }
  } catch (e) {
    throw 'Error fetching topics: $e';
  }
}

Future<Map<String, dynamic>> createTopic({
  required String token,
  required String title,
  required String description,
  required List<String> tags,
  required bool status,
  required bool type,
  required String forumId,
  File? image,
}) async {
  final Uri uri = Uri.parse('$baseUrl/forumwise/create-topic');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  try {
    var request =
        http.MultipartRequest('POST', uri)
          ..headers.addAll(headers)
          ..fields['title'] = title
          ..fields['description'] = description
          ..fields['status'] = status ? '1' : '0'
          ..fields['type'] = type ? '1' : '0'
          ..fields['forum_id'] = forumId;

    for (var i = 0; i < tags.length; i++) {
      request.fields['tags[$i]'] = tags[i];
    }

    if (image != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          image.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    final response = await request.send();
    final responseBody = await http.Response.fromStream(response);
    final decodedResponse = json.decode(responseBody.body);

    if (response.statusCode == 200) {
      return decodedResponse;
    } else if (response.statusCode == 403) {
      var errorData = jsonDecode(decodedResponse);
      String errorMessage =
          errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {'status': 403, 'message': errorMessage};
    } else {
      return {
        'status': response.statusCode,
        'message': decodedResponse['message'] ?? 'Failed to create topic',
        'errors': decodedResponse['errors'] ?? {},
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'Failed to create topic'};
  }
}

Future<Map<String, dynamic>> getTopicContributors(
  String? token,
  String slug,
) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/forumwise/topic-contributors/$slug');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch contributors');
    }
  } catch (e) {
    throw 'Error fetching contributors: $e';
  }
}

Future<Map<String, dynamic>> getTopicDetails(String token, String slug) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/forumwise/topic/$slug');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch topic');
    }
  } catch (e) {
    throw 'Error fetching topic: $e';
  }
}

Future<Map<String, dynamic>> getRelatedTopics(
  String? token,
  String slug,
) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/forumwise/related-topics/$slug');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch related topics');
    }
  } catch (e) {
    throw 'Error fetching related topics: $e';
  }
}

Future<Map<String, dynamic>> getComments(String? token, int? id) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/forumwise/comments/$id');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch comments');
    }
  } catch (e) {
    throw 'Error fetching comments: $e';
  }
}

Future<Map<String, dynamic>> replyComment({
  required String? token,
  required String description,
  required String topicId,
}) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/forumwise/reply');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({'description': description, 'topic_id': topicId});

    final response = await http.post(uri, headers: headers, body: body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else if (response.statusCode == 403) {
      var errorData = jsonDecode(response.body);
      String errorMessage =
          errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {'status': 403, 'message': errorMessage};
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to submit reply');
    }
  } catch (e) {
    throw 'Error submitting reply: $e';
  }
}

Future<Map<String, dynamic>> voteTopic({
  required String? token,
  required String type,
  required String topicId,
}) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/forumwise/vote');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({'type': 'vote', 'topic_id': topicId});

    final response = await http.post(uri, headers: headers, body: body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else if (response.statusCode == 403) {
      var errorData = jsonDecode(response.body);
      String errorMessage =
          errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {'status': 403, 'message': errorMessage};
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to submit reply');
    }
  } catch (e) {
    throw 'Error submitting reply: $e';
  }
}

Future<Map<String, dynamic>> socialLogin(String authCode) async {
  final uri = Uri.parse('$baseUrl/social-login');
  final headers = <String, String>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  final body = json.encode({'provider': 'google', 'auth_code': authCode});

  final response = await http.post(uri, headers: headers, body: body);

  final Map<String, dynamic> responseData = json.decode(response.body);

  if (response.statusCode == 200) {
    return responseData;
  } else if (response.statusCode == 403) {
    return {
      'status': 403,
      'message':
          responseData['message'] ??
          "You can't add/edit anything on the demo site",
    };
  } else {
    return responseData;
  }
}

Future<Map<String, dynamic>> socialProfile(
  String email,
  String firstName,
  String lastName,
  String phoneNumber,
  String userRole,
  String termsCondition,
) async {
  final uri = Uri.parse('$baseUrl/social-profile');
  final headers = <String, String>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  final body = json.encode({
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
    'phone_number': phoneNumber,
    'user_role': userRole,
    'terms': termsCondition,
  });

  final response = await http.post(uri, headers: headers, body: body);

  final Map<String, dynamic> responseData = json.decode(response.body);

  if (response.statusCode == 200) {
    return responseData;
  } else if (response.statusCode == 403) {
    return {
      'status': 403,
      'message':
          responseData['message'] ??
          "You can't add/edit anything on the demo site",
    };
  } else if (response.statusCode == 422) {
    return {
      'status': 422,
      'message': responseData['message'] ?? 'Validation error',
      'errors': responseData['errors'] ?? {},
    };
  } else {
    return responseData;
  }
}

Future<Map<String, dynamic>> addReview({
  required String token,
  required int bookingId,
  required int rating,
  required String comment,
}) async {
  final Uri uri = Uri.parse('$baseUrl/review/$bookingId');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  final body = json.encode({'rating': rating, 'comment': comment});

  try {
    final response = await http.post(uri, headers: headers, body: body);

    final decodedResponse = json.decode(response.body);

    if (response.statusCode == 200) {
      return {
        'status': 200,
        'message': decodedResponse['message'] ?? 'Review added successfully',
        'data': decodedResponse['data'] ?? {},
      };
    } else if (response.statusCode == 403) {
      return {
        'status': 403,
        'message':
            decodedResponse['message'] ??
            "You can't add/edit anything on the demo site",
      };
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else if (response.statusCode == 422) {
      return {
        'status': 422,
        'message': decodedResponse['message'] ?? 'Validation error',
        'errors': decodedResponse['errors'] ?? {},
      };
    } else {
      return {
        'status': response.statusCode,
        'message': decodedResponse['message'] ?? 'Failed to add review',
        'errors': decodedResponse['errors'] ?? {},
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'An unexpected error occurred: $e'};
  }
}

Future<Map<String, dynamic>> completeBooking({
  required String token,
  required int bookingId,
}) async {
  final Uri uri = Uri.parse('$baseUrl/complete-booking/$bookingId');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  try {
    final response = await http.post(uri, headers: headers);

    final decodedResponse = json.decode(response.body);

    if (response.statusCode == 200) {
      return {
        'status': 200,
        'message':
            decodedResponse['message'] ?? 'Booking completed successfully',
        'data': decodedResponse['data'] ?? {},
      };
    } else if (response.statusCode == 403) {
      return {
        'status': 403,
        'message':
            decodedResponse['message'] ??
            "You can't add/edit anything on the demo site",
      };
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else if (response.statusCode == 422) {
      return {
        'status': 422,
        'message': decodedResponse['message'] ?? 'Validation error',
        'errors': decodedResponse['errors'] ?? {},
      };
    } else {
      return {
        'status': response.statusCode,
        'message': decodedResponse['message'] ?? 'Failed to complete booking',
        'errors': decodedResponse['errors'] ?? {},
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'An unexpected error occurred: $e'};
  }
}

Future<Map<String, dynamic>> disputeBooking({
  required String token,
  required int bookingId,
  required String reason,
  required String description,
}) async {
  final Uri uri = Uri.parse('$baseUrl/dispute/$bookingId');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  final body = json.encode({'reason': reason, 'description': description});

  try {
    final response = await http.post(uri, headers: headers, body: body);

    final decodedResponse = json.decode(response.body);

    if (response.statusCode == 200) {
      return {
        'status': 200,
        'message': decodedResponse['message'] ?? 'Dispute added successfully',
        'data': decodedResponse['data'] ?? {},
      };
    } else if (response.statusCode == 403) {
      return {
        'status': 403,
        'message':
            decodedResponse['message'] ??
            "You can't add/edit anything on the demo site",
      };
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else if (response.statusCode == 422) {
      return {
        'status': 422,
        'message': decodedResponse['message'] ?? 'Validation error',
        'errors': decodedResponse['errors'] ?? {},
      };
    } else {
      return {
        'status': response.statusCode,
        'message': decodedResponse['message'] ?? 'Failed to add dispute',
        'errors': decodedResponse['errors'] ?? {},
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'An unexpected error occurred: $e'};
  }
}

Future<Map<String, dynamic>> getDisputeListing(
  String token, {
  int page = 1,
}) async {
  try {
    final Uri uri = Uri.parse(
      '$baseUrl/dispute-listing',
    ).replace(queryParameters: {'page': page.toString()});

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch disputes');
    }
  } catch (e) {
    throw 'Error fetching disputes: $e';
  }
}

Future<Map<String, dynamic>> getDisputeDetail(
  String token,
  int disputeId,
) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/dispute-detail/$disputeId');

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch dispute detail');
    }
  } catch (e) {
    throw 'Error fetching disputes: $e';
  }
}

Future<Map<String, dynamic>> getDisputeDiscussion(
  String token,
  int disputeId,
) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/dispute-discussion/$disputeId');

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch dispute detail');
    }
  } catch (e) {
    throw 'Error fetching disputes: $e';
  }
}

Future<Map<String, dynamic>> disputeReply({
  required String token,
  required int disputeId,
  required String message,
}) async {
  final Uri uri = Uri.parse('$baseUrl/dispute-reply/$disputeId');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'multipart/form-data',
  };

  try {
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(headers);
    request.fields['message'] = message;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final decodedResponse = json.decode(response.body);

    if (response.statusCode == 200) {
      return {
        'status': 200,
        'message': decodedResponse['message'] ?? 'Reply successfully submitted',
        'data': decodedResponse['data'] ?? {},
      };
    } else if (response.statusCode == 403) {
      return {
        'status': 403,
        'message':
            decodedResponse['message'] ??
            "You can't add/edit anything on the demo site",
      };
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else if (response.statusCode == 422) {
      return {
        'status': 422,
        'message': decodedResponse['message'] ?? 'Validation error',
        'errors': decodedResponse['errors'] ?? {},
      };
    } else {
      return {
        'status': response.statusCode,
        'message': decodedResponse['message'] ?? 'Failed to send message',
        'errors': decodedResponse['errors'] ?? {},
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'An unexpected error occurred: $e'};
  }
}

Future<Map<String, dynamic>> getAllNotifications(
  String? token, {
  int page = 1,
}) async {
  try {
    final Uri uri = Uri.parse(
      '$baseUrl/notifications',
    ).replace(queryParameters: {'page': page.toString()});

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get notifications');
    }
  } catch (e) {
    throw 'Error fetching notifications: $e';
  }
}

Future<Map<String, dynamic>> markReadNotification({
  required String? token,
  required String notificationId,
}) async {
  final Uri uri = Uri.parse('$baseUrl/notifications/$notificationId/read');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  try {
    final response = await http.post(uri, headers: headers);

    final decodedResponse = json.decode(response.body);

    if (response.statusCode == 200) {
      return {
        'status': 200,
        'message': decodedResponse['message'] ?? 'Notification marked as read',
        'data': decodedResponse['data'] ?? {},
      };
    } else if (response.statusCode == 403) {
      return {
        'status': 403,
        'message':
            decodedResponse['message'] ??
            "You can't add/edit anything on the demo site",
      };
    } else if (response.statusCode == 400) {
      return {
        'status': 400,
        'message': decodedResponse['message'] ?? "Notification already read",
      };
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      return {
        'status': response.statusCode,
        'message':
            decodedResponse['message'] ?? 'Failed to mark as read notification',
        'errors': decodedResponse['errors'] ?? {},
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'An unexpected error occurred: $e'};
  }
}

Future<Map<String, dynamic>> readAllNotifications({
  required String? token,
}) async {
  final Uri uri = Uri.parse('$baseUrl/notifications/read-all');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  try {
    final response = await http.post(uri, headers: headers);

    final decodedResponse = json.decode(response.body);

    if (response.statusCode == 200) {
      return {
        'status': 200,
        'message':
            decodedResponse['message'] ??
            'All notifications are marked as read',
        'data': decodedResponse['data'] ?? {},
      };
    } else if (response.statusCode == 403) {
      return {
        'status': 403,
        'message':
            decodedResponse['message'] ??
            "You can't add/edit anything on the demo site",
      };
    } else if (response.statusCode == 400) {
      return {
        'status': 400,
        'message':
            decodedResponse['message'] ?? "All notifications already read",
      };
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      return {
        'status': response.statusCode,
        'message':
            decodedResponse['message'] ?? 'Failed to mark read notifications',
        'errors': decodedResponse['errors'] ?? {},
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'An unexpected error occurred: $e'};
  }
}

Future<Map<String, dynamic>> getAllCourses(
  String? token, {
  int page = 1,
  String? keyword,
  String? sort,
  List<int>? categoryIds,
  List<int>? languageIds,
  String? minPrice,
  String? maxPrice,
  String? pricingType,
  List<String>? duration,
  List<int>? avgRatings,
  List<String>? level,
}) async {
  try {
    final Map<String, dynamic> queryParams = {
      'page': page.toString(),
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      if (sort != null && sort.isNotEmpty) 'sort': sort,
      if (minPrice != null && minPrice.isNotEmpty) 'min_price': minPrice,
      if (maxPrice != null && maxPrice.isNotEmpty) 'max_price': maxPrice,
      if (pricingType != null && pricingType.isNotEmpty)
        'pricing_type': pricingType,
    };

    if (categoryIds != null && categoryIds.isNotEmpty) {
      for (var id in categoryIds) {
        queryParams.putIfAbsent('category[]', () => []).add(id.toString());
      }
    }

    if (languageIds != null && languageIds.isNotEmpty) {
      for (var id in languageIds) {
        queryParams.putIfAbsent('languages[]', () => []).add(id.toString());
      }
    }

    if (avgRatings != null && avgRatings.isNotEmpty) {
      for (var rating in avgRatings) {
        queryParams
            .putIfAbsent('avg_rating[]', () => [])
            .add(rating.toString());
      }
    }

    if (level != null && level.isNotEmpty) {
      for (var l in level) {
        queryParams.putIfAbsent('levels[]', () => []).add(l.toLowerCase());
      }
    }

    if (duration != null && duration.isNotEmpty) {
      for (var d in duration) {
        queryParams.putIfAbsent('duration[]', () => []).add(d);
      }
    }

    final Uri uri = Uri.parse(
      '$baseUrl/courses',
    ).replace(queryParameters: queryParams);

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get courses');
    }
  } catch (e) {
    throw Exception('Error fetching courses: $e');
  }
}

Future<Map<String, dynamic>> getCategories(String? token) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/categories');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get categories');
    }
  } catch (e) {
    throw 'Failed to get categories $e';
  }
}

Future<Map<String, dynamic>> getLevel(String? token) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/levels');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get levels');
    }
  } catch (e) {
    throw 'Failed to get levels $e';
  }
}

Future<Map<String, dynamic>> getDurationCounts(String? token) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/duration-counts');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get duration counts');
    }
  } catch (e) {
    throw 'Failed to get duration counts $e';
  }
}

Future<Map<String, dynamic>> getRatings(String? token) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/ratings');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get ratings');
    }
  } catch (e) {
    throw 'Failed to get ratings$e';
  }
}

Future<Map<String, dynamic>> getCourseDetails(
  String? token,
  String slug,
) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/course-detail/$slug');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get course details');
    }
  } catch (e) {
    throw 'Failed to get course details $e';
  }
}

Future<Map<String, dynamic>> addDeleteFavouriteCourse(
  String token,
  int courseId,
  AuthProvider authProvider,
) async {
  final url = Uri.parse('$baseUrl/like-course/$courseId');

  try {
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      authProvider.toggleFavoriteCourseStatus(courseId);
      return jsonDecode(response.body);
    } else if (response.statusCode == 403) {
      var errorData = jsonDecode(response.body);
      String errorMessage =
          errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {'status': 403, 'message': errorMessage};
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      return {
        'status': response.statusCode,
        'message': 'Failed to update courses status: ${response.reasonPhrase}',
      };
    }
  } catch (error) {
    return {'status': 500, 'message': 'Error occurred: $error'};
  }
}

Future<Map<String, dynamic>> bookCourseCart(
  String token,
  Map<String, dynamic> data,
  String slug,
) async {
  final Uri uri = Uri.parse(
    '$baseUrl/course-cart',
  ).replace(queryParameters: {'slug': slug});
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  try {
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(data),
    );

    final decodedResponse = json.decode(response.body);

    if (response.statusCode == 200) {
      return decodedResponse;
    } else if (response.statusCode == 403) {
      var errorData = jsonDecode(response.body);
      String errorMessage =
          errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {'status': 403, 'message': errorMessage};
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      return {
        'status': response.statusCode,
        'message': decodedResponse['message'] ?? 'Failed to book course',
        'errors': decodedResponse['errors'],
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'Failed to book course'};
  }
}

Future<Map<String, dynamic>> getEnrolledCourse(
  String token, {
  int page = 1,
  String? keyword,
}) async {
  try {
    final Map<String, dynamic> queryParams = {
      'page': page.toString(),
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
    };

    final Uri uri = Uri.parse(
      '$baseUrl/enrolled-courses',
    ).replace(queryParameters: queryParams);

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get courses');
    }
  } catch (e) {
    throw Exception('Error fetching courses: $e');
  }
}

Future<Map<String, dynamic>> getCourseTakingDetails(
  String? token,
  String slug,
) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/course-taking/$slug');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(
        error['message'] ?? 'Failed to get course taking details',
      );
    }
  } catch (e) {
    throw 'Failed to get course taking details $e';
  }
}

Future<Map<String, dynamic>> updateProgress(
  String token,
  Map<String, dynamic> data,
  String courseId,
  String curriculumId,
) async {
  final Uri uri = Uri.parse('$baseUrl/update-progress');

  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'multipart/form-data',
  };

  var request = http.MultipartRequest('POST', uri);
  request.headers.addAll(headers);
  request.fields['course_id'] = courseId;
  request.fields['curriculum_id'] = curriculumId;

  data.forEach((key, value) {
    request.fields[key] = value.toString();
  });

  try {
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final decodedResponse = json.decode(response.body);

    if (response.statusCode == 200) {
      return decodedResponse;
    } else if (response.statusCode == 403) {
      String errorMessage =
          decodedResponse['message'] ??
          "You can't add/edit anything on the demo site";
      return {'status': 403, 'message': errorMessage};
    } else if (response.statusCode == 400) {
      String errorMessage =
          decodedResponse['message'] ?? "You have already watched this section";
      return {'status': 400, 'message': errorMessage};
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      return {
        'status': response.statusCode,
        'message': decodedResponse['message'] ?? 'Failed to update progress',
        'errors': decodedResponse['errors'],
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'Failed to update progress'};
  }
}

Future<Map<String, dynamic>> bookFreeSession(
  String token,
  Map<String, dynamic> data,
  String slotId,
) async {
  final Uri uri = Uri.parse('$baseUrl/book-free-slot');

  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'multipart/form-data',
  };

  var request = http.MultipartRequest('POST', uri);
  request.headers.addAll(headers);
  request.fields['slot_id'] = slotId;

  data.forEach((key, value) {
    request.fields[key] = value.toString();
  });

  try {
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final decodedResponse = json.decode(response.body);

    if (response.statusCode == 200) {
      return decodedResponse;
    } else if (response.statusCode == 403) {
      String errorMessage =
          decodedResponse['message'] ??
          "You can't add/edit anything on the demo site";
      return {'status': 403, 'message': errorMessage};
    } else if (response.statusCode == 400) {
      String errorMessage =
          decodedResponse['message'] ?? "Can't directly book in a paid slot.";
      return {'status': 400, 'message': errorMessage};
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      return {
        'status': response.statusCode,
        'message': decodedResponse['message'] ?? 'Failed to book session slot',
        'errors': decodedResponse['errors'],
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'Failed to book session slot'};
  }
}

Future<Map<String, dynamic>> enrolledFreeCourse(
  String token,
  Map<String, dynamic> data,
  String slug,
) async {
  final Uri uri = Uri.parse('$baseUrl/enroll-course');

  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'multipart/form-data',
  };

  var request = http.MultipartRequest('POST', uri);
  request.headers.addAll(headers);
  request.fields['slug'] = slug;

  data.forEach((key, value) {
    request.fields[key] = value.toString();
  });

  try {
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final decodedResponse = json.decode(response.body);

    if (response.statusCode == 200) {
      return decodedResponse;
    } else if (response.statusCode == 403) {
      String errorMessage =
          decodedResponse['message'] ??
          "You can't add/edit anything on the demo site";
      return {'status': 403, 'message': errorMessage};
    } else if (response.statusCode == 400) {
      String errorMessage =
          decodedResponse['message'] ??
          "Can't directly enroll in a paid course.";
      return {'status': 400, 'message': errorMessage};
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      return {
        'status': response.statusCode,
        'message': decodedResponse['message'] ?? 'Failed to enroll course',
        'errors': decodedResponse['errors'],
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'Failed to enroll course'};
  }
}

Future<Map<String, dynamic>> getContactList(
  String token, {
  int page = 1,
  String? search,
}) async {
  try {
    final Map<String, dynamic> queryParams = {
      'page': page.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final Uri uri = Uri.parse(
      '$baseUrl/contacts',
    ).replace(queryParameters: queryParams);

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get contacts');
    }
  } catch (e) {
    throw Exception('Error fetching contacts: $e');
  }
}

Future<Map<String, dynamic>> getThreadList(
  String token, {
  int page = 1,
  String? search,
}) async {
  try {
    final Map<String, dynamic> queryParams = {
      'page': page.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final Uri uri = Uri.parse(
      '$baseUrl/threads',
    ).replace(queryParameters: queryParams);

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get threads');
    }
  } catch (e) {
    throw Exception('Error fetching threads: $e');
  }
}

Future<Map<String, dynamic>> getMessages(
  String token, {
  int page = 1,
  String? threadId,
  String? threadType,
}) async {
  try {
    final Map<String, dynamic> queryParams = {
      'page': page.toString(),
      'threadId': threadId,
      'threadType': threadType,
    };

    final Uri uri = Uri.parse(
      '$baseUrl/messages',
    ).replace(queryParameters: queryParams);

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get messages');
    }
  } catch (e) {
    throw Exception('Error fetching messages: $e');
  }
}

Future<Map<String, dynamic>> sendMessage({
  required String token,
  required String threadId,
  required String body,
  required String messageType,
  required bool isSender,
}) async {
  final Uri uri = Uri.parse('$baseUrl/messages');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  final bodyData = json.encode({
    'threadId': threadId,
    'body': body,
    'messageType': messageType,
    'isSender': isSender,
  });

  try {
    final response = await http.post(uri, headers: headers, body: bodyData);

    final decodedResponse = json.decode(response.body);

    if (response.statusCode == 200) {
      return {
        'status': response.statusCode,
        'message': decodedResponse['message'] ?? 'Message sent successfully',
        'data': decodedResponse['data'] ?? {},
      };
    } else if (response.statusCode == 403) {
      return {
        'status': 403,
        'message':
            decodedResponse['message'] ??
            "You can't add/edit anything on the demo site",
      };
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      return {
        'status': response.statusCode,
        'message': decodedResponse['message'] ?? 'Failed to send message',
        'errors': decodedResponse['errors'] ?? {},
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'An unexpected error occurred: $e'};
  }
}

Future<Map<String, dynamic>> startChat({
  required String token,
  required String userId,
}) async {
  final Uri uri = Uri.parse('$baseUrl/start-chat/$userId');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  try {
    final response = await http.post(uri, headers: headers);

    final decodedResponse = json.decode(response.body);

    if (response.statusCode == 200 && decodedResponse['type'] == 'success') {
      return {
        'status': 200,
        'message': decodedResponse['message'] ?? '',
        'data': decodedResponse['data'],
      };
    } else if (response.statusCode == 403) {
      return {
        'status': 403,
        'message':
            decodedResponse['message'] ??
            "You can't add/edit anything on the demo site",
      };
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else if (response.statusCode == 422) {
      return {
        'status': 422,
        'message': decodedResponse['message'] ?? 'Validation error',
        'errors': decodedResponse['errors'] ?? {},
      };
    } else {
      return {
        'status': response.statusCode,
        'message': decodedResponse['message'] ?? 'Failed to chat',
        'errors': decodedResponse['errors'] ?? {},
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'An unexpected error occurred: $e'};
  }
}

Future<Map<String, dynamic>> deleteMessage({
  required String token,
  required String messageId,
  required String threadId,
}) async {
  final Uri uri = Uri.parse('$baseUrl/messages/$messageId');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  final body = json.encode({'thread_id': threadId});

  try {
    final response = await http.delete(uri, headers: headers, body: body);

    final decodedResponse = json.decode(response.body);

    if (response.statusCode == 200) {
      return {
        'status': 200,
        'message': decodedResponse['message'] ?? 'Message deleted successfully',
        'data': decodedResponse['data'] ?? {},
      };
    } else if (response.statusCode == 403) {
      return {
        'status': 403,
        'message':
            decodedResponse['message'] ??
            "You can't delete anything on the demo site",
      };
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      return {
        'status': response.statusCode,
        'message': decodedResponse['message'] ?? 'Failed to delete message',
        'errors': decodedResponse['errors'] ?? {},
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'An unexpected error occurred: $e'};
  }
}

Future<Map<String, dynamic>> uploadImage({
  required String token,
  required String threadId,
  required File imageFile,
}) async {
  final Uri uri = Uri.parse('$baseUrl/messages');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  try {
    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll(headers);

    request.fields['threadId'] = threadId;
    request.fields['body'] = '';
    request.fields['messageType'] = 'image';
    request.fields['isSender'] = 'true';
    request.fields['timeStamp'] =
        DateTime.now().millisecondsSinceEpoch.toString();

    request.files.add(
      await http.MultipartFile.fromPath(
        'media[]',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final response = await request.send();
    final responseBody = await http.Response.fromStream(response);

    final decodedResponse =
        responseBody.body.isNotEmpty ? responseBody.body : "{}";

    if (response.statusCode == 200) {
      return {
        'status': 200,
        'message': 'Image uploaded successfully',
        'data': decodedResponse,
      };
    } else if (response.statusCode == 403) {
      return {
        'status': 403,
        'message': "You can't add/edit anything on the demo site",
      };
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      return {
        'status': response.statusCode,
        'message': 'Failed to upload image',
        'errors': decodedResponse,
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'An unexpected error occurred: $e'};
  }
}

Future<Map<String, dynamic>> uploadVideo({
  required String token,
  required String threadId,
  required File videoFile,
}) async {
  final Uri uri = Uri.parse('$baseUrl/messages');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  try {
    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll(headers);

    request.fields['threadId'] = threadId;
    request.fields['body'] = '';
    request.fields['messageType'] = 'video';
    request.fields['isSender'] = 'true';
    request.fields['timeStamp'] =
        DateTime.now().millisecondsSinceEpoch.toString();

    request.files.add(
      await http.MultipartFile.fromPath(
        'media[]',
        videoFile.path,
        contentType: MediaType('mp4', 'mkv'),
      ),
    );

    final response = await request.send();
    final responseBody = await http.Response.fromStream(response);

    final decodedResponse =
        responseBody.body.isNotEmpty ? responseBody.body : "{}";

    if (response.statusCode == 200) {
      return {
        'status': 200,
        'message': 'Video uploaded successfully',
        'data': decodedResponse,
      };
    } else if (response.statusCode == 403) {
      return {
        'status': 403,
        'message': "You can't add/edit anything on the demo site",
      };
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      return {
        'status': response.statusCode,
        'message': 'Failed to upload video',
        'errors': decodedResponse,
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'An unexpected error occurred: $e'};
  }
}

Future<Map<String, dynamic>> uploadDocument({
  required String token,
  required String threadId,
  required File documentFile,
}) async {
  final Uri uri = Uri.parse('$baseUrl/messages');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  try {
    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll(headers);

    request.fields['threadId'] = threadId;
    request.fields['body'] = '';
    request.fields['messageType'] = 'document';
    request.fields['isSender'] = 'true';
    request.fields['timeStamp'] =
        DateTime.now().millisecondsSinceEpoch.toString();

    request.files.add(
      await http.MultipartFile.fromPath(
        'media[]',
        documentFile.path,
        contentType: MediaType('pdf', 'docx'),
      ),
    );

    final response = await request.send();
    final responseBody = await http.Response.fromStream(response);

    final decodedResponse =
        responseBody.body.isNotEmpty ? responseBody.body : "{}";

    if (response.statusCode == 200) {
      return {
        'status': 200,
        'message': 'Document uploaded successfully',
        'data': decodedResponse,
      };
    } else if (response.statusCode == 403) {
      return {
        'status': 403,
        'message': "You can't add/edit anything on the demo site",
      };
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      return {
        'status': response.statusCode,
        'message': 'Failed to upload document',
        'errors': decodedResponse,
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'An unexpected error occurred: $e'};
  }
}

Future<Map<String, dynamic>> updateFriendStatus(
  String token,
  String userId,
  String friendStatus,
) async {
  final Uri uri = Uri.parse('$baseUrl/friends/update');
  final headers = <String, String>{
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  final body = json.encode({'userId': userId, 'friendStatus': friendStatus});

  try {
    final response = await http.put(uri, headers: headers, body: body);

    final decodedResponse = json.decode(response.body);

    if (response.statusCode == 200) {
      return decodedResponse;
    } else if (response.statusCode == 403) {
      return {
        'status': 403,
        'message':
            decodedResponse['message'] ??
            "You can't add/edit anything on the demo site",
      };
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      return {
        'status': response.statusCode,
        'message':
            decodedResponse['message'] ?? 'Failed to update friend status',
        'errors': decodedResponse['errors'] ?? {},
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'An unexpected error occurred: $e'};
  }
}

Future<Map<String, dynamic>> getAssignmentsListing(
  String token, {
  int? page = 1,
  String? keyword,
  String? studentStatus,
  int? perPage,
}) async {
  try {
    final Map<String, dynamic> queryParams = {
      'page': page?.toString(),
      if (perPage != null) 'perPage': perPage.toString(),
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      if (studentStatus != null && studentStatus.isNotEmpty)
        'studentStatus': studentStatus.toString(),
    };

    final Uri uri = Uri.parse(
      '$baseUrl/assignments',
    ).replace(queryParameters: queryParams);

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get assignments');
    }
  } catch (e) {
    throw Exception('Error fetching assignments: $e');
  }
}

Future<Map<String, dynamic>> getAssignmentDetail(
  String? token,
  String? assignmnentId,
) async {
  try {
    final Uri uri = Uri.parse(
      '$baseUrl/assignment',
    ).replace(queryParameters: {'id': assignmnentId});
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get assignment details');
    }
  } catch (e) {
    throw 'Failed to get assignment details $e';
  }
}

Future<Map<String, dynamic>> getTutorAssignmentsListing(
  String token, {
  int? page = 1,
  String? keyword,
  String? status,
}) async {
  try {
    final Map<String, dynamic> queryParams = {
      'perPage': page?.toString(),
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      if (status != null && status.isNotEmpty) 'status': status,
    };

    final Uri uri = Uri.parse(
      '$baseUrl/assignments-list',
    ).replace(queryParameters: queryParams);

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get assignments');
    }
  } catch (e) {
    throw Exception('Error fetching assignments: $e');
  }
}

Future<Map<String, dynamic>> getSessions(String? token, String? id) async {
  try {
    final Uri uri = Uri.parse(
      '$baseUrl/session-list',
    ).replace(queryParameters: {'id': id});
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get session');
    }
  } catch (e) {
    throw 'Failed to get session $e';
  }
}

Future<Map<String, dynamic>> getCourseList(String? token) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/courses-list');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get course list');
    }
  } catch (e) {
    throw 'Failed to get course list $e';
  }
}

Future<Map<String, dynamic>> createAssignment({
  required String token,
  required Map<String, dynamic> data,
  List<http.MultipartFile>? files,
}) async {
  final Uri uri = Uri.parse('$baseUrl/assignment');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  try {
    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll(headers);

    data.forEach((key, value) {
      if (value != null) {
        if (value is List) {
          for (var i = 0; i < value.length; i++) {
            request.fields['${key}[$i]'] = value[i].toString();
          }
        } else {
          request.fields[key] = value.toString();
        }
      }
    });

    if (files != null && files.isNotEmpty) {
      request.files.addAll(files);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final decodedResponse = json.decode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return decodedResponse;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else if (response.statusCode == 403) {
      var errorData = jsonDecode(response.body);
      String errorMessage =
          errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {'status': 403, 'message': errorMessage};
    } else {
      return {
        'status': response.statusCode,
        'message': decodedResponse['message'] ?? 'Failed to create assignment',
        'errors': decodedResponse['errors'] ?? {},
      };
    }
  } catch (e) {
    return {
      'status': 500,
      'message': 'Failed to create assignment',
      'error': e.toString(),
    };
  }
}

Future<Map<String, dynamic>> getTutorAssignmentDetail(
  String? token,
  String? id,
) async {
  try {
    final Uri uri = Uri.parse(
      '$baseUrl/assignment-detail',
    ).replace(queryParameters: {'id': id});
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get detail');
    }
  } catch (e) {
    throw 'Failed to get detail $e';
  }
}

Future<Map<String, dynamic>> getSubmittedAssignmentsDetail(
  String token, {
  String? keyword,
  String? status,
  String? id,
}) async {
  try {
    final Map<String, dynamic> queryParams = {
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      if (status != null && status.isNotEmpty) 'status': status.toString(),
      if (id != null && id.isNotEmpty) 'id': id,
    };

    final Uri uri = Uri.parse(
      '$baseUrl/submission-assignments-list',
    ).replace(queryParameters: queryParams);

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get assignments');
    }
  } catch (e) {
    throw Exception('Error fetching assignments: $e');
  }
}

Future<Map<String, dynamic>> getReviewAssignmentDetail(
  String token, {
  String? id,
}) async {
  try {
    final Map<String, dynamic> queryParams = {
      if (id != null && id.isNotEmpty) 'id': id,
    };

    final Uri uri = Uri.parse(
      '$baseUrl/submission-assignment-detail',
    ).replace(queryParameters: queryParams);

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get assignment detail');
    }
  } catch (e) {
    throw Exception('Error fetching assignment detail: $e');
  }
}

Future<Map<String, dynamic>> submitAssignmentResult(
  String token, {
  String? id,
  int? marks_awarded,
}) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/submit-result');

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final body = json.encode({'id': id, 'marks_awarded': marks_awarded});

    final response = await http.post(uri, headers: headers, body: body);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else if (response.statusCode == 403) {
      return {
        'status': 403,
        'message': "You can't add/edit anything on the demo site",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to submit assignment result');
    }
  } catch (e) {
    throw Exception('Error submitting assignment result: $e');
  }
}

Future<Map<String, dynamic>> submitAssignment({
  required String token,
  required String assignmentId,
  String? submissionText,
  List<File>? attachments,
}) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/submit-assignment');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll(headers);

    request.fields['assignment_id'] = assignmentId.toString();
    if (submissionText != null) {
      request.fields['submission_text'] = submissionText;
    }
    if (attachments != null && attachments.isNotEmpty) {
      for (var file in attachments) {
        request.files.add(
          await http.MultipartFile.fromPath('attachments[]', file.path),
        );
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else if (response.statusCode == 403) {
      return {
        'status': 403,
        'message': "You can't add/edit anything on the demo site",
      };
    } else if (response.statusCode == 422) {
      return {
        'status': 422,
        'message': "Validation errors",
        'errors': json.decode(response.body),
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to submit assignment');
    }
  } catch (e) {
    return {'status': 500, 'message': e.toString()};
  }
}

Future<Map<String, dynamic>> publishAssignment(
  String token, {
  String? id,
}) async {
  try {
    final Uri uri = Uri.parse(
      '$baseUrl/publish-assignment',
    ).replace(queryParameters: id != null ? {'id': id} : null);
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.post(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else if (response.statusCode == 403) {
      return {
        'status': 403,
        'message': "You can't add/edit anything on the demo site",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to publish assignment');
    }
  } catch (e) {
    throw Exception('Error publishing assignment: $e');
  }
}

Future<Map<String, dynamic>> deleteAssignment(
  String token, {
  String? id,
}) async {
  try {
    final Uri uri = Uri.parse(
      '$baseUrl/assignment',
    ).replace(queryParameters: id != null ? {'id': id} : null);
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.delete(uri, headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else if (response.statusCode == 403) {
      return {
        'status': 403,
        'message': "You can't add/edit anything on the demo site",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to delete assignment');
    }
  } catch (e) {
    throw Exception('Error deleting assignment: $e');
  }
}

Future<Map<String, dynamic>> archiveAssignment(
  String token, {
  String? id,
}) async {
  try {
    final Uri uri = Uri.parse(
      '$baseUrl/archive-assignment',
    ).replace(queryParameters: id != null ? {'id': id} : null);
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.post(uri, headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else if (response.statusCode == 403) {
      return {
        'status': 403,
        'message': "You can't add/edit anything on the demo site",
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to archive assignment');
    }
  } catch (e) {
    throw Exception('Error archiving assignment: $e');
  }
}
