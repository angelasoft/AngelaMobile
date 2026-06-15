import 'package:flutter/material.dart';

class ForceUpdatePage extends StatelessWidget {
  const ForceUpdatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('업데이트 필요')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '앱을 최신 버전으로 업데이트해 주세요.\n(구현 예정)',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
