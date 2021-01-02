class Club {
  ImageUrls imageUrls;
  String abbrName;
  int id;
  Null imgUrl;
  String name;

  Club({this.imageUrls, this.abbrName, this.id, this.imgUrl, this.name});

  Club.fromJson(Map<String, dynamic> json) {
    imageUrls = json['imageUrls'] != null
        ? new ImageUrls.fromJson(json['imageUrls'])
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

class ImageUrls {
  Dark dark;
  Light light;

  ImageUrls({this.dark, this.light});

  ImageUrls.fromJson(Map<String, dynamic> json) {
    dark = json['dark'] != null ? new Dark.fromJson(json['dark']) : null;
    light = json['light'] != null ? new Light.fromJson(json['light']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.dark != null) {
      data['dark'] = this.dark.toJson();
    }
    if (this.light != null) {
      data['light'] = this.light.toJson();
    }
    return data;
  }
}

class Dark {
  String small;
  String medium;
  String large;

  Dark({this.small, this.medium, this.large});

  Dark.fromJson(Map<String, dynamic> json) {
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

class Light {
  String small;
  String medium;
  String large;

  Light({this.small, this.medium, this.large});

  Light.fromJson(Map<String, dynamic> json) {
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