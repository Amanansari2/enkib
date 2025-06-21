import 'dart:convert';
import 'dart:io';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

final String baseUrl = 'https://enkib.com/api';

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
    

    print("Request Body ---->> ${jsonEncode(userData)}");

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print("ResponseData ----->>> $responseData");
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

      throw {
        'message': errorMessage,
        'status': response.statusCode,
      };
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

  final body = json.encode({
    'email': email,
    'password': password,
  });

  final response = await http.post(
    uri,
    headers: headers,
    body: body,
  );

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

  final body = json.encode({
    'email': email,
  });

  final response = await http.post(
    uri,
    headers: headers,
    body: body,
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else if (response.statusCode == 403) {
    var errorData = jsonDecode(response.body);
    String errorMessage =
        errorData['message'] ?? "You can't add/edit anything on the demo site";
    return {
      'status': 403,
      'message': errorMessage,
    };
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

    print("Email Uri------>>>$uri");

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    print("Headers ----->>>>> $headers");

    final response = await http.get(
      uri,
      headers: headers,
    );

    var response2 = jsonDecode(response.body);
    print("Response ----->>> $response2");

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 403) {
      var errorData = jsonDecode(response.body);
      print(" Error ---->>>> $errorData");
      String errorMessage = errorData['message'] ??
          "You can't add/edit anything on the demo site";
      print("Error message---->>>> $errorMessage");
      return {
        'status': 403,
        'message': errorMessage,
      };
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again."
      };
    } else {
      final error = json.decode(response.body);
      print("Final Error ---->>> $error");
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

    final response = await http.post(
      uri,
      headers: headers,
    );

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
    Map<String, dynamic> userData, String token, int id) async {
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
    return {
      'status': 403,
      'message': errorMessage,
    };
  } else if (response.statusCode == 401) {
    return {
      'status': 401,
      'message': "Unauthorized access. Please log in again."
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

    final Uri uri =
        Uri.parse('$baseUrl/find-tutors').replace(queryParameters: queryParams);

    print("Url ---->>> $uri");
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final response = await http.get(uri, headers: headers);
    // final response1 = json.decode(response.body);

    if (response.statusCode == 200) {
       // print("Response ---->> $response1");
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      print("Error response ---->> $error");
      throw Exception(error['message'] ?? 'Failed to get tutors');
    }
  } catch (e) {
    throw 'Failed to get tutors: $e';
  }
}

Future<Map<String, dynamic>> getTutors(String? token, String slug) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/tutor/$slug');
    print("URL ----->>>> $uri");
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
      print("Response ----->>> $decodedBody");
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again."
      };
    } else {
      final error = json.decode(response.body);
      print("Error ----->>> $error");
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
        'message': "Unauthorized access. Please log in again."
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
        'message': "Unauthorized access. Please log in again."
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
    String? token, int id) async {
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
        'message': "Unauthorized access. Please log in again."
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
    String token, Map<String, dynamic> data) async {
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
      String errorMessage = errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {
        'status': 403,
        'message': errorMessage,
      };
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again."
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
    String? token, int countryId) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/country-states').replace(
      queryParameters: {
        'country_id': countryId.toString(),
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
      String errorMessage = errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {
        'status': 403,
        'message': errorMessage,
      };
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again."
      };
    } else {
      return {
        'status': response.statusCode,
        'message': 'Failed to delete education: ${response.reasonPhrase}',
      };
    }
  } catch (error) {
    return {
      'status': 500,
      'message': 'Error occurred: $error',
    };
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
    String token, int tutorId, AuthProvider authProvider) async {
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
      String errorMessage = errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {
        'status': 403,
        'message': errorMessage,
      };
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again."
      };
    } else {
      return {
        'status': response.statusCode,
        'message': 'Failed to update favorite status: ${response.reasonPhrase}',
      };
    }
  } catch (error) {
    return {
      'status': 500,
      'message': 'Error occurred: $error',
    };
  }
}

Future<Map<String, dynamic>> updateEducation(
    String token, int id, Map<String, dynamic> educationData) async {
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
      String errorMessage = errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {
        'status': 403,
        'message': errorMessage,
      };
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again."
      };
    } else {
      return {
        'status': response.statusCode,
        'message': decodedResponse['message'] ?? 'Failed to update education',
        'errors': decodedResponse['errors'],
      };
    }
  } catch (error) {
    return {
      'status': 500,
      'message': 'Error occurred: $error',
    };
  }
}

Future<Map<String, dynamic>> addExperience(
    String token, Map<String, dynamic> data) async {
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
      String errorMessage = errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {
        'status': 403,
        'message': errorMessage,
      };
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again."
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
      String errorMessage = errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {
        'status': 403,
        'message': errorMessage,
      };
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again."
      };
    } else {
      return {
        'status': response.statusCode,
        'message': 'Failed to delete experience: ${response.reasonPhrase}',
      };
    }
  } catch (error) {
    return {
      'status': 500,
      'message': 'Error occurred: $error',
    };
  }
}

Future<Map<String, dynamic>> updateExperience(
    String token, int id, Map<String, dynamic> experienceData) async {
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
      String errorMessage = errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {
        'status': 403,
        'message': errorMessage,
      };
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again."
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
    return {
      'status': 500,
      'message': 'Error occurred: $error',
    };
  }
}

Future<Map<String, dynamic>> addCertification(
    String token, Map<String, dynamic> data) async {
  final Uri uri = Uri.parse('$baseUrl/tutor-certification');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  try {
    var request = http.MultipartRequest('POST', uri)
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
      String errorMessage = errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {
        'status': 403,
        'message': errorMessage,
      };
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again."
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
      String errorMessage = errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {
        'status': 403,
        'message': errorMessage,
      };
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again."
      };
    } else {
      return {
        'status': response.statusCode,
        'message': 'Failed to delete certification: ${response.reasonPhrase}',
      };
    }
  } catch (error) {
    return {
      'status': 500,
      'message': 'Error occurred: $error',
    };
  }
}

Future<Map<String, dynamic>> updateCertification(
    String token, int id, Map<String, dynamic> certificationData) async {
  final Uri uri = Uri.parse('$baseUrl/tutor-certification/$id');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  try {
    var request = http.MultipartRequest('POST', uri)
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
      String errorMessage = errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {
        'status': 403,
        'message': errorMessage,
      };
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again."
      };
    } else {
      final error = json.decode(responseBody);
      return {
        'status': response.statusCode,
        'message': error['message'] ?? 'Failed to update certification',
      };
    }
  } catch (error) {
    return {
      'status': 500,
      'message': 'Error occurred: $error',
    };
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
        'message': "Unauthorized access. Please log in again."
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
    print('Request Url -->>> $uri');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    print('Request Headers---->> $headers');


    final response = await http.get(uri, headers: headers);
    print('Response Status Cod---->>: ${response.statusCode}');
    print('Response Body--->> ${response.body}');

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      print('Decoded Response--->>> $decodedBody');
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      print('Error Response-->>>: $error');
      throw Exception(error['message'] ?? 'Failed to get earning');
    }
  } catch (e) {
    throw 'Failed to get earning $e';
  }
}

Future<Map<String, dynamic>> getPayouts(String token, int id) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/tutor-payouts/$id');
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
        'message': "Unauthorized access. Please log in again."
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
        'message': "Unauthorized access. Please log in again."
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
    String token, Map<String, dynamic> data) async {
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
      String errorMessage = errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {
        'status': 403,
        'message': errorMessage,
      };
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again."
      };
    } else {
      final error = json.decode(response.body);
      return {
        'status': response.statusCode,
        'message': error['message'] ?? 'Failed to add payout method'
      };
    }
  } catch (e) {
    return {'status': 500, 'message': 'Failed to add payout method'};
  }
}

Future<Map<String, dynamic>> deletePayoutMethod(
    String token, String method) async {
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
      String errorMessage = errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {
        'status': 403,
        'message': errorMessage,
      };
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again."
      };
    } else {
      return {
        'status': response.statusCode,
        'message': 'Failed to delete payout method: ${response.reasonPhrase}',
      };
    }
  } catch (error) {
    return {
      'status': 500,
      'message': 'Error occurred: $error',
    };
  }
}

Future<Map<String, dynamic>> userWithdrawal(
    String token, Map<String, dynamic> data) async {
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
      String errorMessage = errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {
        'status': 403,
        'message': errorMessage,
      };
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again."
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
    String token, String startDate, String endDate) async {
  try {

    final Uri uri = Uri.parse('$baseUrl/upcoming-bookings').replace(
      queryParameters: {
        'show_by': 'daily',
        'start_date': startDate,
        'end_date': endDate,
        'type': '',
      },
    );
    print("Response url --->> $uri");

    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    print("Headers -->> $headers");

    final response = await http.get(uri, headers: headers);
    print('Response Body--->>> ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print("Failed Response--->> ${response.body}");
      throw Exception('Failed to load bookings');
    }
  } catch (e) {
      print("Error --->> $e");
    throw 'Error fetching bookings: $e';
  }
}

Future<Map<String, dynamic>> getInvoices(String token) async {
  try {
    final Uri uri = Uri.parse('$baseUrl/invoices');
    print("Response Url ---->> $uri");
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    print("Response headers -->>> $headers");

    final response = await http.get(uri, headers: headers);
    print("Response --->>> $response");

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      print("ResponseData ---->>> $decodedBody");
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again."
      };
    } else {
      final error = json.decode(response.body);
      print("Error ---->> $error");
      throw Exception(error['message'] ?? 'Failed to get invoices');
    }
  } catch (e) {
    throw 'Failed to get invoices $e';
  }
}

Future<Map<String, dynamic>> getIdentityVerification(
    String token, int id) async {
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
    } else {
      final error = json.decode(response.body);
      throw Exception(
          error['message'] ?? 'Failed to get identity verification');
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
    File? transcript) async {

  final Uri uri = Uri.parse('$baseUrl/identity-verification');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
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
      request.files.add(await http.MultipartFile.fromPath('identificationCard', identificationCard.path));
    }

    if (transcript != null) {
      request.files.add(await http.MultipartFile.fromPath('transcript', transcript.path));
      print("Transcript file does not exist: ${transcript.path}");
    }

    final response = await request.send();
    final responseData = await http.Response.fromStream(response);
    final decodedResponse = json.decode(responseData.body);

    print("uri ---->>>> $uri");
    print("Response ---->>>> $decodedResponse");
    print("Response Body-------------->>> ${responseData. body}");



    if (response.statusCode == 200) {
      return decodedResponse;
    } else {
      return {
        'status': response.statusCode,
        'message': decodedResponse['message'] ?? 'Failed to verify identity',
        'errors': decodedResponse['errors'] ?? {},
      };
    }
  } catch (e) {
    return {
      'status': 500,
      'message': 'Failed to submit identity verification',
    };
  }
}


Future<Map<String, dynamic>> deleteIdentityVerification(
    String token, int id) async {
  final url = Uri.parse('$baseUrl/identity-verification/$id');

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
    } else {
      return {
        'status': response.statusCode,
        'message':
        'Failed to delete identity verification: ${response.reasonPhrase}',
      };
    }
  } catch (error) {
    return {
      'status': 500,
      'message': 'Error occurred: $error',
    };
  }
}

Future<Map<String, dynamic>> getTutorAvailableSlots(
    String token, String userId) async {
  final Uri uri = Uri.parse('$baseUrl/tutor-available-slots').replace(
    queryParameters: {
      'user_id': userId,
    },
  );

  print("Url session -->> $uri");
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
print("Headers --->> $headers");
  try {
    final response = await http.get(
      uri,
      headers: headers,
    );

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again."
      };
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch available slots');
    }
  } catch (e) {
    throw 'Error fetching available slots: $e';
  }
}

Future<Map<String, dynamic>> getStudentReviews(String? token, int id,
    {int page = 1, int? perPage }) async {
  try {
    final Uri uri =
        Uri.parse('$baseUrl/student-reviews/$id?page=$page&perPage=$perPage');

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
print("Get billing details url --->> $uri");
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      print("Response data ->>>>> $decodedBody");
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
    String token, Map<String, dynamic> data) async {
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
      String errorMessage = errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {
        'status': 403,
        'message': errorMessage,
      };
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
    String token, int id, Map<String, dynamic> updateBillingData) async {
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
      String errorMessage = errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {
        'status': 403,
        'message': errorMessage,
      };
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
    return {
      'status': 500,
      'message': 'Error occurred: $error',
    };
  }
}

Future<Map<String, dynamic>> bookSessionCart(
    String token, Map<String, dynamic> data, String id) async {
  final Uri uri = Uri.parse('$baseUrl/booking-cart').replace(
    queryParameters: {
      'id': id,
    },
  );
  print("booking seesion url --->> $uri");
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
print("headers -->> $headers");
  try {
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(data),
    );

    final decodedResponse = json.decode(response.body);

    print("Response decoded ---->>>> $decodedResponse");


    if (response.statusCode == 200) {
      return decodedResponse;
    } else if (response.statusCode == 403) {

      var errorData = jsonDecode(response.body);

      print("Error -->>> $errorData");
      String errorMessage = errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {
        'status': 403,
        'message': errorMessage,
      };
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
    print('Exceptions ---->>> $e');
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
    print("Url -->>> $uri");
    print("Response data session ---->> $response");

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return decodedBody;
    } else {
      final error = json.decode(response.body);
      print("Error --->> $error");
      throw Exception(error['message'] ?? 'Failed to get booking cart');
    }
  } catch (e) {
    print('Exceptions --->>> $e');
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
      String errorMessage = errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {
        'status': 403,
        'message': errorMessage,
      };
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
    return {
      'status': 500,
      'message': 'Error occurred: $error',
    };
  }
}

Future<Map<String, dynamic>> postCheckOut(
    String token, Map<String, dynamic> data) async {
  final Uri uri = Uri.parse('$baseUrl/checkout');
  print("Url ---->> $uri");
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  print("Headers ---->> $headers");

  try {
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(data),
    );


    final decodedResponse = jsonDecode(response.body);
   print("Decode response --->>> $decodedResponse");
    if (response.statusCode == 200) {
      return decodedResponse;
    } else if (response.statusCode == 403) {
      var errorData = jsonDecode(response.body);
      print("Error ---->> $errorData");
      String errorMessage = errorData['message'] ??
          "You can't add/edit anything on the demo site";
      return {
        'status': 403,
        'message': errorMessage,
      };
    } else if (response.statusCode == 401) {
      return {
        'status': 401,
        'message': "Unauthorized access. Please log in again.",
      };
    } else {
      final error = decodedResponse;
      print("Error ---->> $error");
      return {
        'status': response.statusCode,
        'message': error['message'] ?? 'Failed to add billing detail:',
        'errors': error['errors'] ?? {},
      };
    }
  } catch (e) {
    print("Errorr 2 ---->> $e");
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

Future <Map<String, dynamic>> getTermsConditions() async {
  final Uri uri= Uri.parse('$baseUrl/pagebuilder/terms-condition');
  final headers = <String, String>{
    'Accept' : 'application/json',
    'Content-Type' : 'application/json'
  };
  try{
    final response = await http.get(uri, headers: headers);
    if(response.statusCode ==200){
      final decodedBody = json.decode(response.body);
      return decodedBody;
    }
    else {
      final error = json.decode(response.body);
      throw Exception(error['message']?? "Failed to load Terms & Conditions");
    }
  } catch(e){
     throw 'failed to load terms & Conditions : $e';
  }
}

Future <Map<String,dynamic>> getPrivacyPolicy () async {
  final Uri uri = Uri.parse('$baseUrl/pagebuilder/privacy-policy');
  final headers = <String, String>{
    'accept' : 'application/json',
    'Content-Type' : 'application/json',
  };

  try{
    final response = await http.get(uri, headers: headers);
    if(response.statusCode == 200){
      final decodedBody = json.decode(response.body);
      return decodedBody;
    }
    else {
      final error = json.decode(response.body);
      throw Exception(error['message']?? 'Failed to load Privacy Policy');
    }
  }catch(e){
    throw 'Failed to load Privacy Policy : $e';
  }
}


//// 11 digit phone number , profile setting update