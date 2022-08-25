class User {
  String name = "anonymous";
  String state = "";
  bool wiki = false;

  User() {

  }

  User.fromJson(Map<String, dynamic> json) {
    name = (json['name'] != null) ? json['name'] : "anonymous";
    state = (json['state'] != null) ? json['state'].toString() : "";
    wiki = (json['wiki'] != null) ? true : false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name.toString();
    data['state'] = state.toString();
    data['wiki'] = wiki.toString();
    return data;
  }

  bool isAnon() {
    if (name=="anonymous") {
      return true;
    }
    return false;
  }
  bool isValid() {
    if (name == "" || name=="anonymous") {
      return false;
    }
    return true;
  }
  void resetUser() {
    name = "anonymous";
    wiki = false;
  }
}

