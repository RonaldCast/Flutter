
import 'package:dio/dio.dart';
import './appInterceptors.dart';
import 'package:tTemplateWithBlocPattern/DataLayer/Providers/appInterceptors.dart';


class SingletonDio{

  static final SingletonDio _singletonDio = SingletonDio._internal();
  static Dio _dio;

  factory SingletonDio(){
    _dio = Dio();
    _dio.interceptors.add(AppInterceptors());
    return _singletonDio;
  }

   Dio getDio(){
    return _dio;
  }

   SingletonDio._internal();
}