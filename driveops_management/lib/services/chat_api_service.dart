import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:driveops_management/config/api_config.dart';
import 'package:driveops_management/services/auth_service.dart';
import 'package:driveops_management/shared/models/conversation.dart';
import 'package:driveops_management/shared/models/conversation_summary.dart';
import 'package:driveops_management/shared/models/chat_message.dart';

final chatApiServiceProvider = Provider<ChatApiService>((ref) {
  final authService = AuthService();
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.realtimeBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(_ChatAuthInterceptor(authService, dio));

  return ChatApiService(dio);
});

class _ChatAuthInterceptor extends Interceptor {
  final AuthService _authService;
  final Dio _dio;

  _ChatAuthInterceptor(this._authService, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _authService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) async {
    if (error.response?.statusCode == 401) {
      final refreshed = await _authService.refreshToken();
      if (refreshed != null) {
        try {
          final retryResponse = await _retryRequest(error.requestOptions, refreshed.accessToken);
          return handler.resolve(retryResponse);
        } catch (retryError) {
          return handler.next(error);
        }
      }
    }
    return handler.next(error);
  }

  Future<Response> _retryRequest(RequestOptions requestOptions, String token) async {
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $token',
      },
    );
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}

class ChatApiService {
  final Dio _dio;

  ChatApiService(this._dio);

  Future<List<ConversationSummary>> getMyConversations() async {
    final response = await _dio.get('/api/chat/conversations');
    final list = response.data as List<dynamic>;
    return list.map((e) => ConversationSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Conversation> getConversation(String id) async {
    final response = await _dio.get('/api/chat/conversations/$id');
    return Conversation.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PagedMessages> getMessages(String conversationId, {int page = 1, int pageSize = 50}) async {
    final response = await _dio.get(
      '/api/chat/conversations/$conversationId/messages',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return PagedMessages.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Conversation> createDirectConversation(String otherUserId) async {
    final response = await _dio.post(
      '/api/chat/conversations',
      data: {'otherUserId': otherUserId},
    );
    return Conversation.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Conversation> joinConversation(String conversationId) async {
    final response = await _dio.post('/api/chat/conversations/$conversationId/join');
    return Conversation.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ConversationSummary>> getActiveTripConversations() async {
    final response = await _dio.get('/api/chat/trip-conversations');
    final list = response.data as List<dynamic>;
    return list.map((e) => ConversationSummary.fromJson(e as Map<String, dynamic>)).toList();
  }
}