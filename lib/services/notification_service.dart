import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart'; // Для kIsWeb

import '../models/task.dart';

// Провайдер для NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  // Инициализация при создании провайдера
  service.initialize(); 
  return service;
});

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Инициализация плагина
  Future<void> initialize() async {
    if (_initialized) return;
    print('Initializing Notification Service...');

    // Настройка для Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Стандартная иконка

    // Настройка для iOS/macOS
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
           // Запрос разрешений при инициализации (можно и отдельно)
           requestAlertPermission: true,
           requestBadgePermission: true,
           requestSoundPermission: true,
           onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
        );

    // Настройка для Linux (если поддерживается)
     const LinuxInitializationSettings initializationSettingsLinux = 
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin, // Используем те же настройки для macOS
        linux: initializationSettingsLinux,
    );

    // Инициализация Timezone базы данных
    tz.initializeTimeZones();
    // Установка локальной временной зоны (важно для планирования)
    // TODO: Определять зону динамически?
    tz.setLocalLocation(tz.getLocation('Europe/Moscow')); 

    try {
      await _flutterLocalNotificationsPlugin.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
          onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
       );
       print('Notification Service Initialized.');
       _initialized = true;
       // Запрашиваем разрешения после инициализации (особенно для Android)
       await requestPermissions();
    } catch (e) {
       print('Error initializing Notification Service: $e');
    }
  }

  // Запрос разрешений (особенно актуально для Android 13+)
  Future<bool> requestPermissions() async {
     if (kIsWeb) return false; // Уведомления не поддерживаются на Web этим плагином

     if (Platform.isAndroid) {
         final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
         final bool? granted = await androidImplementation?.requestNotificationsPermission();
          print('Android notification permission granted: $granted');
         return granted ?? false;
     } else if (Platform.isIOS || Platform.isMacOS) {
        // Разрешения запрашиваются при инициализации для Darwin
        // Можно запросить снова, если нужно
         final bool? granted = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
          print('iOS/macOS notification permission granted: $granted');
        return granted ?? false;
     } else if (Platform.isLinux) {
        final LinuxFlutterLocalNotificationsPlugin? linuxImplementation = 
            _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                LinuxFlutterLocalNotificationsPlugin>();
        final bool? granted = await linuxImplementation?.requestPermission();
        print('Linux notification permission granted: $granted');
        return granted ?? false;
     }
     return false; // Для других платформ
  }

  // Обработчик нажатия на уведомление (когда приложение было в foreground/background)
  void _onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (notificationResponse.payload != null) {
      debugPrint('notification payload: $payload');
    }
    // TODO: Реализовать навигацию к задаче по payload (taskId)
    // Например, используя Riverpod и GoRouter
  }
  
  // Обработчик нажатия на уведомление (когда приложение было закрыто)
  // Должна быть static или top-level функция
  @pragma('vm:entry-point')
  static void notificationTapBackground(NotificationResponse notificationResponse) {
     // TODO: Обработать нажатие в фоне (сложнее)
     print('Notification tapped in background: ${notificationResponse.payload}');
  }

  // Обработчик для старых версий iOS
  void _onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) async {
    // Показать диалог или обновить UI
     debugPrint('onDidReceiveLocalNotification payload: $payload');
  }

  // Планирование уведомления для задачи
  Future<void> scheduleNotification(Task task, DateTime notificationTime, String title, String body) async {
    if (!_initialized) {
       print('Notification service not initialized, skipping schedule.');
       return;
    }
    if (notificationTime.isBefore(DateTime.now())) {
       print('Cannot schedule notification in the past for task ${task.id}');
       return;
    }

    // Генерируем уникальный ID для уведомления (можно использовать хэш ID задачи или число)
    // Важно: ID должен быть 32-битным знаковым integer для Android
    final notificationId = task.id.hashCode % 2147483647;

    const AndroidNotificationDetails androidNotificationDetails = 
        AndroidNotificationDetails(
           'task_reminders', // ID канала
           'Напоминания о задачах', // Имя канала
           channelDescription: 'Уведомления о сроках выполнения задач', 
           importance: Importance.max, 
           priority: Priority.high, 
           ticker: 'ticker');
           
    const DarwinNotificationDetails darwinNotificationDetails = 
        DarwinNotificationDetails(badgeNumber: 1);
        
    const LinuxNotificationDetails linuxNotificationDetails = LinuxNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
       android: androidNotificationDetails,
       iOS: darwinNotificationDetails,
       macOS: darwinNotificationDetails,
       linux: linuxNotificationDetails,
    );
    
    try {
       await _flutterLocalNotificationsPlugin.zonedSchedule(
         notificationId, 
         title, 
         body, 
         tz.TZDateTime.from(notificationTime, tz.local), // Используем локальное время TZDateTime
         notificationDetails, 
         androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
         uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
         payload: task.id // Передаем ID задачи для обработки нажатия
       );
       print('Scheduled notification $notificationId for task ${task.id} at $notificationTime');
    } catch (e) {
       print('Error scheduling notification $notificationId for task ${task.id}: $e');
    }
  }

  // Отмена уведомления для задачи
  Future<void> cancelNotification(Task task) async {
     if (!_initialized) return;
     final notificationId = task.id.hashCode % 2147483647;
     try {
        await _flutterLocalNotificationsPlugin.cancel(notificationId);
        print('Cancelled notification $notificationId for task ${task.id}');
     } catch (e) {
        print('Error cancelling notification $notificationId for task ${task.id}: $e');
     }
  }

   // Отмена всех уведомлений
  Future<void> cancelAllNotifications() async {
     if (!_initialized) return;
     try {
        await _flutterLocalNotificationsPlugin.cancelAll();
        print('Cancelled all notifications');
     } catch (e) {
        print('Error cancelling all notifications: $e');
     }
  }
} 