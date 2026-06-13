import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'config/theme.dart';
import 'providers/app_providers.dart';
import 'routes/app_router.dart';
import 'services/api_service.dart';
import 'services/call_service.dart';
import 'services/websocket_service.dart';
import 'widgets/common/incoming_call_listener.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JumandiApp());
}

class JumandiApp extends StatefulWidget {
  const JumandiApp({super.key});

  @override
  State<JumandiApp> createState() => _JumandiAppState();
}

class _JumandiAppState extends State<JumandiApp> {
  late final ApiService _api;
  late final WebSocketService _ws;
  late final CallService _callService;
  late final AuthProvider _auth;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _api = ApiService();
    _ws = WebSocketService();
    _callService = CallService(_api);
    _auth = AuthProvider(_api);
    _router = createRouter(_auth);
    _auth.init();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: _api),
        Provider<WebSocketService>.value(value: _ws),
        Provider<CallService>.value(value: _callService),
        ChangeNotifierProvider<AuthProvider>.value(value: _auth),
        ChangeNotifierProvider(create: (_) => BookingProvider(_api)),
        ChangeNotifierProvider(create: (_) => AdminProvider(_api)),
      ],
      child: IncomingCallListener(
        child: MaterialApp.router(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          routerConfig: _router,
        ),
      ),
    );
  }
}
