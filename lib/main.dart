import 'package:flutter/material.dart';
import 'package:crm/providers/app_provider.dart';
import 'package:crm/providers/category_provider.dart';
import 'package:crm/providers/core_provider.dart';
import 'package:provider/provider.dart';
import 'package:crm/util/consts.dart';

// import './src/bloc/ApplicationBloc.dart';
// import './src/bloc/BlocProvider.dart';
import 'package:crm/screens/splash.dart';

void main() => runApp(
  MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => CoreProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
      ],
      child: MyApp(),
    ),
);

class MyApp extends StatelessWidget {
  // final ApplicationBloc bloc = ApplicationBloc();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (BuildContext context, AppProvider appProvider, Widget child) {
        return MaterialApp(
          key: appProvider.key,
          debugShowCheckedModeBanner: false,
          navigatorKey: appProvider.navigatorKey,
          title: Constants.appName,
          theme: appProvider.theme,
          darkTheme: Constants.darkTheme,
          home: Splash(),
        );
      },
    );
  }
}
