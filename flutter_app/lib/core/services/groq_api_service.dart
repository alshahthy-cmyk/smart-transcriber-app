import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class GroqApiService {
  final Dio _dio;
  
  GroqApiService({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = 'https://api.groq.com/openai/v1';
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(minutes: 3);
  }

  Future<bool> _hasInternet() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  Future<String> transcribeAudio({
    required File audioFile,
    required String apiKey,
    bool isDemoMode = false,
    Function(double)? onProgress,
  }) async {
    
    // Demo Mode Logic
    if (isDemoMode) {
       for (int i = 0; i <= 100; i += 10) {
         if (onProgress != null) onProgress(i / 100);
         await Future.delayed(const Duration(milliseconds: 300));
       }
       return 'هذا نص تجريبي تم توليده لأنك تستخدم الوضع التجريبي. للحصول على تفريغ كامل ودقيق لملفاتك الحقيقية، يرجى الحصول على مفتاح Groq API من الإعدادات.';
    }

    const int maxRetries = 4; // A11 & S3: Increased to 4 with exponential backoff
    int currentTry = 0;
    
    while (currentTry < maxRetries) {
      try {
        if (!(await _hasInternet())) {
          throw Exception('لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة وإعادة المحاولة.');
        }

        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            audioFile.path,
            filename: audioFile.path.split('/').last,
          ),
          'model': 'whisper-large-v3',
          'language': 'ar', // Force Arabic
          'response_format': 'json',
          'temperature': 0.0,
        });

        final response = await _dio.post(
          '/audio/transcriptions',
          data: formData,
          options: Options(
            headers: {
              'Authorization': 'Bearer $apiKey',
            },
          ),
          onSendProgress: (sent, total) {
            if (onProgress != null && total > 0) {
               onProgress(sent / total);
            }
          },
        );

        if (response.statusCode == 200 && response.data != null) {
          return response.data['text']?.toString() ?? '';
        } else {
          throw Exception('فشل التفريغ بسبب خطأ غير معروف (${response.statusCode})');
        }
      } on DioException catch (e) {
        currentTry++;
        
        // S3: Exponential backoff logic with Cooldown
        final retryDelay = pow(2, currentTry).toInt() + 1; // 3s, 5s, 9s, 17s
        
        if (e.response?.statusCode == 429) {
          // Rate limit handling
          if (currentTry >= maxRetries) {
            throw Exception('تم تجاوز الحد المسموح به للطلبات. يرجى الانتظار قليلاً ثم المحاولة مرة أخرى.');
          }
          await Future.delayed(Duration(seconds: retryDelay));
        } else if (_isNetworkError(e)) {
           // Network instability, retry
           if (currentTry >= maxRetries) throw Exception(_handleDioError(e));
           await Future.delayed(Duration(seconds: retryDelay));
        } else {
           // Bad request or authorization failure, don't retry
           throw Exception(_handleDioError(e));
        }
      } catch (e) {
        currentTry++;
        if (currentTry >= maxRetries) {
          throw Exception(e.toString());
        }
        await Future.delayed(Duration(seconds: pow(2, currentTry).toInt()));
      }
    }
    throw Exception('فشل الاتصال بعد $maxRetries محاولات. تأكد من جودة اتصالك.');
  }

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout || 
           e.type == DioExceptionType.sendTimeout || 
           e.type == DioExceptionType.receiveTimeout || 
           e.type == DioExceptionType.connectionError ||
           e.type == DioExceptionType.unknown;
  }

  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return 'انقطع الاتصال بالخادم. تأكد من استقرار شبكة الإنترنت وضعف التغطية.';
      case DioExceptionType.badResponse:
        final msg = e.response?.data?['error']?['message'] ?? e.response?.statusMessage;
        if (e.response?.statusCode == 401) {
           return 'مفتاح API غير صالح. يرجى التحقق من إعدادات المفتاح وتحديثه.';
        }
        if (e.response?.statusCode == 413) {
           return 'حجم الملف كبير جداً وتجاوز قدرة التقسيم التلقائي.';
        }
        return 'خطأ من الخادم (${e.response?.statusCode}): $msg';
      default:
        return 'حدث خطأ غير متوقع في الشبكة: ${e.message}';
    }
  }
}
