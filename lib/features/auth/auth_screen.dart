import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_organizer/services/supabase_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// StateProvider для отслеживания состояния загрузки
final _loadingProvider = StateProvider<bool>((ref) => false);

// Экран аутентификации с кастомным UI
class AuthScreen extends ConsumerStatefulWidget { // Делаем StatefulWidget для контроллеров
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Функция для входа
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Сохраняем ScaffoldMessengerState
    final scaffoldMessenger = ScaffoldMessenger.of(context); 
    ref.read(_loadingProvider.notifier).state = true;
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // GoRouter сам обработает перенаправление
    } on AuthException catch (error) {
       // Используем сохраненный scaffoldMessenger
       scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Ошибка входа: ${error.message}'), backgroundColor: Colors.red),
      );
    } catch (error) {
       // Используем сохраненный scaffoldMessenger
       scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Произошла ошибка: $error'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        ref.read(_loadingProvider.notifier).state = false;
      }
    }
  }

  // Функция для регистрации
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Сохраняем ScaffoldMessengerState
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    ref.read(_loadingProvider.notifier).state = true;
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        emailRedirectTo: 'studorg://login-callback',
      );
      // Используем сохраненный scaffoldMessenger
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Проверьте вашу почту (и спам!) для подтверждения регистрации.')),
      );
      // Остаемся на этом экране
    } on AuthException catch (error) {
       // Используем сохраненный scaffoldMessenger
       scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Ошибка регистрации: ${error.message}'), backgroundColor: Colors.red),
      );
    } catch (error) {
       // Используем сохраненный scaffoldMessenger
       scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Произошла ошибка: $error'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        ref.read(_loadingProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(_loadingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Вход / Регистрация')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Student Organizer', 
                         textAlign: TextAlign.center,
                         style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 30),
                    // Поле Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty || !value.contains('@')) {
                          return 'Введите корректный Email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Поле Пароль
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                       validator: (value) {
                        if (value == null || value.isEmpty || value.length < 6) {
                          return 'Пароль должен быть не менее 6 символов';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // Кнопка Войти
                    ElevatedButton(
                      onPressed: isLoading ? null : _signIn,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Войти'),
                    ),
                    const SizedBox(height: 12),
                     // Кнопка Зарегистрироваться
                    OutlinedButton(
                      onPressed: isLoading ? null : _signUp,
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Зарегистрироваться'),
                    ),
                    const SizedBox(height: 16),
                    // Ссылка Забыли пароль?
                    TextButton(
                      onPressed: isLoading ? null : () async { // Делаем async
                         final email = _emailController.text.trim();
                         // Проверяем email перед отправкой запроса
                         if (email.isEmpty || !email.contains('@')) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('Сначала введите ваш Email в поле выше.'), backgroundColor: Colors.orange),
                           );
                           return;
                         }
                         
                         // Сохраняем ScaffoldMessengerState до асинхронной операции
                         final scaffoldMessenger = ScaffoldMessenger.of(context); 
                         ref.read(_loadingProvider.notifier).state = true;
                         try {
                           final supabase = ref.read(supabaseClientProvider);
                           // Сразу вызываем resetPasswordForEmail с email из контроллера
                           await supabase.auth.resetPasswordForEmail(
                             email,
                             redirectTo: 'studorg://login-callback',
                           );
                           scaffoldMessenger.showSnackBar(
                             const SnackBar(content: Text('Инструкции по сбросу пароля отправлены на почту (проверьте спам).')),
                           );
                         } on AuthException catch (error) {
                           scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text('Ошибка: ${error.message}'), backgroundColor: Colors.red),
                           );
                         } catch (error) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text('Произошла ошибка: $error'), backgroundColor: Colors.red),
                           );
                         } finally {
                            // Проверяем mounted перед изменением state
                            if (mounted) { 
                              ref.read(_loadingProvider.notifier).state = false;
                            }
                         }
                      },
                      child: const Text('Забыли пароль?'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 