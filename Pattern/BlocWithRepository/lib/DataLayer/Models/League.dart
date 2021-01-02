import './LeagueImageUrls.dart';

class League {
  LeagueImageUrls imageUrls;
  String abbrName;
  int id;
  Null imgUrl;
  String name;

  League({this.imageUrls, this.abbrName, this.id, this.imgUrl, this.name});

  League.fromJson(Map<String, dynamic> json) {
    imageUrls = json['imageUrls'] != null
        ? new LeagueImageUrls.fromJson(json['imageUrls'])
        : null;
    abbrName = json['abbrName'];
    id = json['id'];
    imgUrl = json['imgUrl'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.imageUrls != null) {
      data['imageUrls'] = this.imageUrls.toJson();
    }
    data['abbrName'] = this.abbrName;
    data['id'] = this.id;
    data['imgUrl'] = this.imgUrl;
    data['name'] = this.name;
    return data;
  }
}
