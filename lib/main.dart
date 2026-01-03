import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/constants/colors.dart';
import 'core/services/auth_service.dart';
import 'providers/finance_provider.dart';
import 'core/routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set status bar color to transparent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  final authService = AuthService();
  final appRouter = AppRouter(authService);

  runApp(MyApp(authService: authService, appRouter: appRouter));
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final AppRouter appRouter;

  const MyApp({super.key, required this.authService, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider(create: (_) => FinanceProvider()..loadData()),
      ],
      child: MaterialApp.router(
        title: 'Flux Finance',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          primaryColor: AppColors.accentGreen,
          textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme)
              .apply(
                bodyColor: AppColors.textPrimary,
                displayColor: AppColors.textPrimary,
              ),
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accentGreen,
            secondary: AppColors.accentRed,
            surface: AppColors.background,
          ),
          useMaterial3: true,
        ),
        routerConfig: appRouter.router,
      ),
    );
  }
}
