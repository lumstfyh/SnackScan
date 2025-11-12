import 'package:flutter/material.dart';
import 'notification_helper.dart';

class AppLifecycleObserver extends WidgetsBindingObserver {
  DateTime? _pausedTime;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    print('📱 App Lifecycle State: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        // App kembali ke foreground
        _onAppResumed();
        break;
      case AppLifecycleState.inactive:
        // App dalam transisi (misal saat lock screen muncul)
        print('🔄 App inactive');
        break;
      case AppLifecycleState.paused:
        // App di background atau ditutup
        _onAppPaused();
        break;
      case AppLifecycleState.detached:
        // App akan dihentikan
        print('⛔ App detached');
        break;
      case AppLifecycleState.hidden:
        // App tersembunyi
        print('👻 App hidden');
        break;
    }
  }

  void _onAppResumed() {
    print('✅ App resumed');

    if (_pausedTime != null) {
      final duration = DateTime.now().difference(_pausedTime!);
      print('⏱️ App was paused for: ${duration.inSeconds} seconds');

      // Kalau user balik sebelum 1 menit, batalkan notifikasi
      if (duration.inSeconds < 60) {
        NotificationHelper().cancelEnjoySnackNotification();
        print('❌ Notifikasi dibatalkan karena user kembali sebelum 1 menit');
      }

      _pausedTime = null;
    }
  }

  void _onAppPaused() {
    _pausedTime = DateTime.now();
    print('⏸️ App paused at: $_pausedTime');

    // Jadwalkan notifikasi "Selamat Menikmati" 1 menit dari sekarang
    NotificationHelper().scheduleRandomEnjoySnackNotification();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
