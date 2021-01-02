class Nation {
  NationImageUrls imageUrls;
  String abbrName;
  int id;
  Null imgUrl;
  String name;

  Nation({this.imageUrls, this.abbrName, this.id, this.imgUrl, this.name});

  Nation.fromJson(Map<String, dynamic> json) {
    imageUrls = json['imageUrls'] != null
        ? new NationImageUrls.fromJson(json['imageUrls'])
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

class NationImageUrls {
  String small;
  String medium;
  String large;

  NationImageUrls({this.small, this.medium, this.large});

  NationImageUrls.fromJson(Map<String, dynamic> json) {
    small = json['small'];
    medium = json['medium'];
    large = json['large'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['small'] = this.small;
    data['medium'] = this.medium;
    data['large'] = this.large;
    return data;
  }
}