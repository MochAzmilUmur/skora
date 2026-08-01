import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../room/presentation/screens/create_exam_room_screen.dart';
import '../room/presentation/screens/exam_room_screen.dart';
import '../room/presentation/screens/qr_scanner_screen.dart';
import '../room/data/models/models.dart';
import '../room/data/models/websocket_message_model.dart';
import '../room/data/repositories/room_repository_impl.dart';
import '../room/data/datasources/room_remote_datasource.dart';
import '../../core/services/auth_storage_service.dart';
import '../../core/services/websocket_service.dart';
import '../../core/widgets/notification_overlay.dart';
import '../auth/data/models/auth/user.dart';
import '../notifications/presentation/screens/notifications_screen.dart';
import '../profile/presentation/screens/profile_screen.dart';
import '../ujian/presentation/screens/exams_screen.dart';
import '../ujian/presentation/screens/results_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  List<RoomModel> _rooms = [];
  List<RoomModel> _filteredRooms = [];
  bool _isLoading = false;
  bool _showActive = true;
  User? _currentUser;
  final _roomRepository = RoomRepositoryImpl(
    remoteDataSource: RoomRemoteDataSourceImpl(),
  );

  @override
  void initState() {
    super.initState();
    _loadUserData().then((_) => _loadRooms());
    _checkSessionTimeout();
    // Listen for real-time role changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WebSocketService>().messageStream.listen((msg) {
        if (!mounted) return;
        if (msg.type == WebSocketMessageType.roleChanged) {
          _loadUserData();
        }
      });
    });
  }

  Future<void> _checkSessionTimeout() async {
    final valid = await AuthStorageService.isTokenValid();
    if (!valid && mounted) {
      await AuthStorageService.clearUser();
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthStorageService.clearUser();
      if (mounted) {
        context.read<WebSocketService>().disconnect();
        Navigator.of(context).pushReplacementNamed('/');
      }
    }
  }

  Future<void> _loadUserData() async {
    final user = await AuthStorageService.getCurrentUser();
    if (mounted && user != null) {
      setState(() => _currentUser = user);
    }
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);

    final userId = _currentUser?.idUsers;
    final result = userId != null
        ? await _roomRepository.getRoomsByUser(userId)
        : await _roomRepository.getRooms();

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load rooms: ${failure.message}'), backgroundColor: Colors.red),
        );
      },
      (rooms) {
        setState(() {
          _rooms = rooms;
          _applyFilter();
          _isLoading = false;
        });
      },
    );
  }

  void _applyFilter() {
    final now = DateTime.now();
    if (_showActive) {
      _filteredRooms = _rooms.where((r) => r.startDate == null || !r.startDate!.isAfter(now)).toList();
    } else {
      _filteredRooms = _rooms.where((r) => r.startDate != null && r.startDate!.isAfter(now)).toList();
    }
  }

  Future<void> _navigateToCreateRoom() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateExamRoomScreen()),
    );
    if (result == true) _loadRooms();
  }

  Future<void> _scanQRCode() async {
    final roomCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );
    if (roomCode != null && mounted) _joinRoomWithCode(roomCode);
  }

  Future<void> _joinRoomWithCode(String roomCode) async {
    final userId = _currentUser?.idUsers;
    if (userId == null) return;

    final result = await _roomRepository.joinRoom(roomCode: roomCode, userId: userId);
    if (!mounted) return;

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join: ${failure.message}'), backgroundColor: Colors.red),
      ),
      (data) {
        final room = RoomModel.fromJson(data['room'] as Map<String, dynamic>);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joined room: ${room.roomName}'), backgroundColor: Colors.green),
        );
        _navigateToRoomDetails(room);
      },
    );
  }

  Future<void> _deleteRoom(RoomModel room) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Room'),
        content: Text('Delete "${room.roomName}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await _roomRepository.deleteRoom(room.idRoom);
    if (!mounted) return;
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${f.message}'), backgroundColor: Colors.red),
      ),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Room deleted'), backgroundColor: Colors.green),
        );
        _loadRooms();
      },
    );
  }

  Future<void> _editRoom(RoomModel room) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateExamRoomScreen(editRoom: room)),
    );
    if (result == true) _loadRooms();
  }

  void _navigateToRoomDetails(RoomModel room) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ExamRoomScreen(room: room)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wsService = context.watch<WebSocketService>();
    return NotificationOverlay(
      wsService: wsService,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        body: SafeArea(
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildHomeTab(),
              const ExamsScreen(),
              const ResultsScreen(),
              ProfileScreen(onLogout: () async {
                await AuthStorageService.clearUser();
                if (mounted) {
                  context.read<WebSocketService>().disconnect();
                  Navigator.of(context).pushReplacementNamed('/');
                }
              }),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 30),
          _buildQuickActions(),
          const SizedBox(height: 30),
          _buildExamsSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final wsService = context.watch<WebSocketService>();
    final unread = wsService.unreadCount;
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey[800],
          child: const Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Welcome back,', style: TextStyle(color: Colors.grey, fontSize: 14)),
              Text(
                _currentUser?.nama ?? 'User',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationsScreen(wsService: wsService),
                ),
              ),
            ),
            if (unread > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
        IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _logout),
      ],
    );
  }

  Widget _buildQuickActions() {
    final isPelajar = _currentUser?.role == 'pelajar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            if (!isPelajar) ...[
              Expanded(
                child: InkWell(
                  onTap: _navigateToCreateRoom,
                  child: _buildActionCard(
                    icon: Icons.add_circle_outline,
                    title: 'Create Room',
                    subtitle: 'Host a new competency\ntest session',
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: InkWell(
                onTap: _scanQRCode,
                child: _buildActionCard(
                  icon: Icons.qr_code_scanner,
                  title: 'Join Room',
                  subtitle: 'Enter code or scan QR to\njoin',
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({required IconData icon, required String title, required String subtitle, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1A2942), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildExamsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Your Exams', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() { _showActive = true; _applyFilter(); }),
              child: Text('Active', style: TextStyle(color: _showActive ? Colors.blue : Colors.grey[600])),
            ),
            TextButton(
              onPressed: () => setState(() { _showActive = false; _applyFilter(); }),
              child: Text('History', style: TextStyle(color: !_showActive ? Colors.blue : Colors.grey[600])),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.blue))
            : _filteredRooms.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredRooms.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) => _buildExamCard(room: _filteredRooms[index]),
                  ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: const Color(0xFF1A2942), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text('No Exams Yet', style: TextStyle(color: Colors.grey[400], fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Create your first exam room to get started', style: TextStyle(color: Colors.grey[600], fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToCreateRoom,
            icon: const Icon(Icons.add),
            label: const Text('Create Room'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard({required RoomModel room}) {
    final now = DateTime.now();
    final isUpcoming = room.startDate != null && room.startDate!.isAfter(now);
    final statusColor = isUpcoming ? Colors.orange : Colors.green;
    final status = isUpcoming ? 'Upcoming' : 'Active';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2942),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_outlined, color: statusColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(room.roomName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(room.user?.nama ?? 'Unknown', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 12)),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                color: const Color(0xFF1E293B),
                onSelected: (value) {
                  if (value == 'edit') _editRoom(room);
                  if (value == 'delete') _deleteRoom(room);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.white, size: 18), SizedBox(width: 8), Text('Edit', style: TextStyle(color: Colors.white))])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.grey[600], size: 16),
              const SizedBox(width: 4),
              Text(
                room.startDate != null
                    ? '${room.startDate!.day}/${room.startDate!.month}/${room.startDate!.year}'
                    : '${room.createdAt.day}/${room.createdAt.month}/${room.createdAt.year}',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              const SizedBox(width: 16),
              Icon(Icons.timer_outlined, color: Colors.grey[600], size: 16),
              const SizedBox(width: 4),
              Text('${room.durasi} mins', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
          if (room.roomCode.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.vpn_key_outlined, color: Colors.grey[600], size: 16),
                const SizedBox(width: 4),
                Text(room.roomCode, style: TextStyle(color: Colors.grey[400], fontSize: 12, letterSpacing: 2)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _navigateToRoomDetails(room),
              style: ElevatedButton.styleFrom(
                backgroundColor: isUpcoming ? Colors.transparent : Colors.blue,
                foregroundColor: isUpcoming ? Colors.blue : Colors.white,
                side: isUpcoming ? const BorderSide(color: Colors.blue) : null,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(isUpcoming ? 'View Details' : 'Enter Room'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2942),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.description_outlined), label: 'Exams'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Results'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
