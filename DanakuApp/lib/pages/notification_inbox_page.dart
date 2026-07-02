import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../data/database_helper.dart';
import '../services/sync_service.dart';
import '../widgets/custom_snackbar.dart';

class NotificationInboxPage extends StatefulWidget {
  const NotificationInboxPage({super.key});

  @override
  State<NotificationInboxPage> createState() => _NotificationInboxPageState();
}

class _NotificationInboxPageState extends State<NotificationInboxPage> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  bool _isSendingTest = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final token = await DatabaseHelper.instance.getSetting('auth_token');
      if (token == null) {
        setState(() {
          _notifications = [];
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${SyncService.instance.laravelBaseUrl}/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        setState(() {
          _notifications = resData['data']['data'] ?? [];
        });
      } else {
        if (mounted) {
          CustomSnackBar.show(
            context,
            message: "Gagal mengambil data notifikasi dari awan.",
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: "Kesalahan koneksi: $e",
          isError: true,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(int id) async {
    try {
      final token = await DatabaseHelper.instance.getSetting('auth_token');
      if (token == null) return;

      final response = await http.post(
        Uri.parse('${SyncService.instance.laravelBaseUrl}/notifications/$id/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _loadNotifications();
      }
    } catch (e) {
      debugPrint("Error marking as read: $e");
    }
  }

  Future<void> _sendTestNotification() async {
    setState(() => _isSendingTest = true);

    try {
      final token = await DatabaseHelper.instance.getSetting('auth_token');
      if (token == null) {
        if (mounted) {
          CustomSnackBar.show(
            context,
            message: "Silakan login terlebih dahulu untuk mencoba fitur ini.",
            isError: true,
          );
        }
        return;
      }

      final response = await http.post(
        Uri.parse('${SyncService.instance.laravelBaseUrl}/notifications/test'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': 'Uji Coba FCM Danaku 🚀',
          'body': 'Selamat! Notifikasi push cloud dan database log berhasil disimulasikan secara real-time ke akun Anda.',
          'type': 'budget_alert'
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          CustomSnackBar.show(
            context,
            message: "Simulasi push notifikasi sukses dikirim!",
            isSuccess: true,
          );
        }
        _loadNotifications();
      } else {
        if (mounted) {
          CustomSnackBar.show(
            context,
            message: "Gagal memicu simulasi notifikasi.",
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: "Koneksi gagal: $e",
          isError: true,
        );
      }
    } finally {
      setState(() => _isSendingTest = false);
    }
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    _markAsRead(notification['id']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF528F).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFFF528F), size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Detail Notifikasi",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification['title'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Text(
              notification['body'] ?? '',
              style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black54),
            ),
            const Divider(height: 24),
            Text(
              "Waktu: ${DateTime.parse(notification['created_at']).toLocal().toString().split('.')[0]}",
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF528F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF528F),
        elevation: 0,
        title: const Text("Kotak Masuk Notifikasi", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF528F))))
          : _notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final item = _notifications[index];
                    final isRead = item['is_read'] == true || item['is_read'] == 1;

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isRead ? Colors.grey.shade200 : const Color(0xFFFF528F).withOpacity(0.3),
                          width: isRead ? 1 : 1.5,
                        ),
                      ),
                      color: isRead ? Colors.white : const Color(0xFFFFF0F5),
                      child: InkWell(
                        onTap: () => _showNotificationDetails(item),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Unread dot indicator
                              if (!isRead)
                                Container(
                                  margin: const EdgeInsets.only(top: 6, right: 12),
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF528F),
                                    shape: BoxShape.circle,
                                  ),
                                )
                              else
                                const SizedBox(width: 8),
                              
                              // Main content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] ?? '',
                                      style: TextStyle(
                                        fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item['body'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isRead ? Colors.grey.shade600 : Colors.black87,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      DateTime.parse(item['created_at']).toLocal().toString().split('.')[0],
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSendingTest ? null : _sendTestNotification,
        backgroundColor: const Color(0xFFFF528F),
        icon: _isSendingTest
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              )
            : const Icon(Icons.send_rounded, color: Colors.white),
        label: const Text("Simulasi Push", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200, width: 2),
              ),
              child: const Icon(Icons.notifications_off_outlined, color: Colors.grey, size: 50),
            ),
            const SizedBox(height: 24),
            const Text(
              "Kotak Masuk Kosong",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              "Belum ada pemberitahuan atau pesan notifikasi baru di akun Anda saat ini.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
