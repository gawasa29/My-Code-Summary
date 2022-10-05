import 'package:chat_example/model/User.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/FirebaseHelper.dart';
import 'home_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  // 入力されたメールアドレス
  String email = "";
  // 入力されたパスワード
  String password = "";
  // 登録・ログインに関する情報を表示
  String infoText = "";
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userModelProvider);
    //値更新用のuserクラス
    final user = ref.watch(userModelProvider.notifier);
    return Scaffold(
        appBar: AppBar(),
        body: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 40.0, left: 40.0, top: 100),
              child: TextFormField(
                decoration: const InputDecoration(labelText: "メールアドレス"),
                onChanged: (String val) {
                  email = val;
                },
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(right: 40.0, left: 40.0, bottom: 50),
              child: TextFormField(
                decoration: const InputDecoration(labelText: "パスワード"),
                // パスワードが見えないようにする
                obscureText: true,
                onChanged: (String val) {
                  password = val;
                },
              ),
            ),
            Text(
              infoText,
              style: const TextStyle(color: Colors.red),
            ),
            ElevatedButton(
              child: const Text('登録'),
              onPressed: () async {
                try {
                  // メール/パスワードでユーザー登録
                  await FirebaseAuth.instance.createUserWithEmailAndPassword(
                    email: email,
                    password: password,
                  );
                  currentUser.userID = FirebaseAuth.instance.currentUser!.uid;
                  //入力した値をfirestoreに追加
                  await FireStoreUtils.firebaseCreateNewUser(currentUser);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                } catch (e) {
                  print(e);
                  setState(() {
                    infoText = "登録に失敗しました";
                  });
                }
              },
            ),
            ElevatedButton(
              child: const Text('ログイン'),
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: email, password: password);
                  //これでfirestoreから持ってきた値をUserクラスに代入する
                  user.state = (await FireStoreUtils.getCurrentUser(
                      FirebaseAuth.instance.currentUser!.uid))!;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                } on FirebaseAuthException catch (e) {
                  print(e);
                  setState(() {
                    infoText = "ログインに失敗しました";
                  });
                }
              },
            ),
          ],
        ));
  }
}
