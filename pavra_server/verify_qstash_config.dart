/// 验证 QStash 配置脚本
///
/// 快速检查 QStash 是否正确配置并可以访问回调 URL
///
/// 使用方法：
/// ```bash
/// cd pavra_server
/// dart run verify_qstash_config.dart
/// ```

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

// 简单的 .env 文件解析器
Map<String, String> loadEnvFile(String path) {
  final env = <String, String>{};
  try {
    final file = File(path);
    if (!file.existsSync()) return env;

    final lines = file.readAsLinesSync();
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      final parts = trimmed.split('=');
      if (parts.length >= 2) {
        final key = parts[0].trim();
        final value = parts.sublist(1).join('=').trim();
        env[key] = value;
      }
    }
  } catch (e) {
    print('⚠️  Could not load .env file: $e');
  }
  return env;
}

void main() async {
  print('🔍 QStash Configuration Verification\n');
  print('=' * 70);

  // 1. 读取环境变量（优先从 .env 文件，然后从系统环境）
  final envFile = loadEnvFile('../assets/.env');

  if (envFile.isNotEmpty) {
    print('\n✅ Loaded .env from ../assets/.env');
  } else {
    print('\n⚠️  No .env file found, using system environment variables');
  }

  final publicHost =
      Platform.environment['PUBLIC_HOST'] ??
      envFile['PUBLIC_HOST'] ??
      'localhost:8080';
  final apiPort =
      Platform.environment['API_PORT'] ?? envFile['API_PORT'] ?? '443';
  final qstashToken =
      Platform.environment['QSTASH_TOKEN'] ?? envFile['QSTASH_TOKEN'];
  final qstashUrl =
      Platform.environment['QSTASH_URL'] ??
      envFile['QSTASH_URL'] ??
      'https://qstash.upstash.io';

  print('\n📋 Configuration:');
  print('   PUBLIC_HOST: $publicHost');
  print('   API_PORT: $apiPort');
  print(
    '   QSTASH_TOKEN: ${qstashToken != null ? "${qstashToken.substring(0, 10)}..." : "NOT SET"}',
  );
  print('   QSTASH_URL: $qstashUrl');

  // 2. 构建回调 URL
  final useHttps = apiPort == '443' || apiPort == '8443';
  final protocol = useHttps ? 'https' : 'http';
  final callbackUrl =
      '$protocol://$publicHost/qstashWebhook/processScheduledNotification';

  print('\n🔗 Callback URL:');
  print('   $callbackUrl');

  // 3. 检查 QStash token
  if (qstashToken == null || qstashToken.isEmpty) {
    print('\n❌ ERROR: QSTASH_TOKEN not configured!');
    print(
      '   Please set QSTASH_TOKEN in your ../assets/.env file or Railway environment.',
    );
    print('\n💡 Your .env file should contain:');
    print(
      '   QSTASH_TOKEN=eyJVc2VySUQiOiI1NGZjMjEyZS0zMDY0LTQ3MDItYmY2MS01YWIyZTcyNjU2YTMiLCJQYXNzd29yZCI6ImM5M2MyMzdjZmVmMzQzZjE4ZTkxYTE2MGM1ZjQxZjgwIn0=',
    );
    exit(1);
  }

  // 4. 测试 QStash API 连接
  print('\n🔌 Testing QStash API connection...');
  try {
    final response = await http.get(
      Uri.parse('$qstashUrl/v2/messages'),
      headers: {'Authorization': 'Bearer $qstashToken'},
    );

    if (response.statusCode == 200) {
      print('✅ QStash API connection successful!');
      final messages = jsonDecode(response.body) as List;
      print('   Found ${messages.length} scheduled messages');

      if (messages.isNotEmpty) {
        print('\n📬 Recent messages:');
        for (var i = 0; i < messages.length && i < 5; i++) {
          final msg = messages[i];
          print('   ${i + 1}. ID: ${msg['messageId']}');
          print('      Status: ${msg['state']}');
          print('      URL: ${msg['url']}');
          print('      Created: ${msg['createdAt']}');
        }
      }
    } else {
      print('❌ QStash API error: ${response.statusCode}');
      print('   Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Failed to connect to QStash: $e');
  }

  // 5. 测试回调 URL 可访问性
  print('\n🌐 Testing callback URL accessibility...');
  try {
    final response = await http
        .get(
          Uri.parse(
            callbackUrl.replaceAll(
              '/qstashWebhook/processScheduledNotification',
              '/',
            ),
          ),
        )
        .timeout(Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 404) {
      print('✅ Server is accessible at $publicHost');
    } else {
      print('⚠️  Server returned status: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Cannot access server at $publicHost');
    print('   Error: $e');
    if (publicHost == 'localhost:8080') {
      print(
        '\n💡 This is expected for localhost. Deploy to Railway for production testing.',
      );
    } else {
      print('\n💡 Possible issues:');
      print('   1. Server is not running');
      print('   2. PUBLIC_HOST is incorrect');
      print('   3. Firewall blocking access');
    }
  }

  // 6. 测试调度一条消息（可选）
  print('\n🧪 Test scheduling a message? (y/n)');
  final input = stdin.readLineSync();

  if (input?.toLowerCase() == 'y') {
    print('\n📤 Scheduling test message...');
    print('   Delay: 60 seconds');
    print('   Callback: $callbackUrl');

    try {
      final response = await http.post(
        Uri.parse('$qstashUrl/v2/publish/$callbackUrl'),
        headers: {
          'Authorization': 'Bearer $qstashToken',
          'Content-Type': 'application/json',
          'Upstash-Delay': '60s',
        },
        body: jsonEncode({
          'notificationId': 'test-${DateTime.now().millisecondsSinceEpoch}',
          'test': true,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        print('✅ Test message scheduled successfully!');
        print('   Message ID: ${result['messageId']}');
        print('   Will be delivered in ~60 seconds');
        print('\n💡 Check your server logs and Upstash Console:');
        print('   https://console.upstash.com/qstash/details');
      } else {
        print('❌ Failed to schedule message: ${response.statusCode}');
        print('   Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Error scheduling message: $e');
    }
  }

  print('\n' + '=' * 70);
  print('✅ Verification completed!\n');

  print('📝 Summary:');
  print(
    '   - QStash API: ${qstashToken != null ? "Connected" : "Not configured"}',
  );
  print('   - Callback URL: $callbackUrl');
  print(
    '   - Server: ${publicHost == 'localhost:8080' ? 'Local (deploy to Railway for testing)' : 'Deployed'}',
  );

  if (publicHost == 'localhost:8080') {
    print('\n⚠️  WARNING: Using localhost');
    print(
      '   QStash cannot reach localhost. Deploy to Railway for production testing.',
    );
    print('   Your Railway deployment: pavra-production.up.railway.app');
  }
}
