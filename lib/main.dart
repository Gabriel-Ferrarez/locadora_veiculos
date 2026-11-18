import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './repository/locacao_repository.dart';
import './repository/locacao_repository_offline_first.dart';
import './screens/dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Estratégia de persistência usada pelo app. Para comparar, dá para trocar
  // por LocacaoRepositoryLocal() (só SQLite) ou LocacaoRepositoryRemoto()
  // (só API) sem mexer em nenhuma tela.
  final LocacaoRepository repository = LocacaoRepositoryOfflineFirst();

  runApp(LocadoraApp(repository: repository));
}

class LocadoraApp extends StatelessWidget {
  final LocacaoRepository repository;

  const LocadoraApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    Intl.defaultLocale = "pt_BR";
    return MaterialApp(
      title: 'Locadora de Veículos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,

        // Paleta gerada a partir do azul índigo, cor base da locadora
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),

        primaryColor: Colors.indigo.shade900,

        appBarTheme: AppBarTheme(
          backgroundColor: Colors.indigo.shade900,
          foregroundColor: Colors.white,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade700,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.amber.shade700,
          foregroundColor: Colors.black,
        ),

        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),

      home: Dashboard(repository: repository),
    );
  }
}
