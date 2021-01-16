import 'dart:io';
import 'package:dio/dio.dart';
import 'package:tTemplateWithBlocPattern/utils/Constants.dart';

class AppInterceptors extends Interceptor{
  
  static RequestOptions requestBackup;

  @override
  Future<dynamic> onRequest(RequestOptions options) async {
      options.baseUrl = API_URL;
  
      return options;
  }

  @override
  Future<dynamic> onError(DioError dioError) async {

    if(dioError.error is SocketException){
      throw HttpException("No have connect");
    }
     else if (dioError.response.statusCode == 500){
       throw HttpException("Unexpected error");
    }
  
    return dioError;
  }

  @override
  Future<dynamic> onResponse(Response options) async {
    return options;
  }
}