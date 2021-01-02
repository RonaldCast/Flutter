import './Players.dart';

class ApiResult {
  int page;
  int totalPages;
  int totalResults;
  String type;
  int count;
  List<Players> items;

  ApiResult(
      {this.page,
        this.totalPages,
        this.totalResults,
        this.type,
        this.count,
        this.items});

  ApiResult.fromJson(Map<String, dynamic> json) {
    page = json['page'];
    totalPages = json['totalPages'];
    totalResults = json['totalResults'];
    type = json['type'];
    count = json['count'];
    if (json['items'] != null) {
      items = new List<Players>();
      json['items'].forEach((v) {
        items.add(new Players.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['page'] = this.page;
    data['totalPages'] = this.totalPages;
    data['totalResults'] = this.totalResults;
    data['type'] = this.type;
    data['count'] = this.count;
    if (this.items != null) {
      data['items'] = this.items.map((v) => v.toJson()).toList();
    }
    return data;
  }
}