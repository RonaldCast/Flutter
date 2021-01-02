class Headshot {
  String imgUrl;
  bool isDynamicPortrait;

  Headshot({this.imgUrl, this.isDynamicPortrait});

  Headshot.fromJson(Map<String, dynamic> json) {
    imgUrl = json['imgUrl'];
    isDynamicPortrait = json['isDynamicPortrait'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['imgUrl'] = this.imgUrl;
    data['isDynamicPortrait'] = this.isDynamicPortrait;
    return data;
  }
}