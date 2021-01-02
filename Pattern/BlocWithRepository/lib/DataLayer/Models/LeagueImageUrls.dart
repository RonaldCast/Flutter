class LeagueImageUrls {
  String dark;
  String light;

  LeagueImageUrls({this.dark, this.light});

  LeagueImageUrls.fromJson(Map<String, dynamic> json) {
    dark = json['dark'];
    light = json['light'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['dark'] = this.dark;
    data['light'] = this.light;
    return data;
  }
}