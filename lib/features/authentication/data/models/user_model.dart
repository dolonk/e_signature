import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({required super.id, required super.email, super.displayName});

  factory UserModel.fromFirebaseUser(firebase_auth.User user) {
    return UserModel(id: user.uid, email: user.email ?? '', displayName: user.displayName);
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(id: json['id'], email: json['email'], displayName: json['displayName']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'displayName': displayName};
  }
}
