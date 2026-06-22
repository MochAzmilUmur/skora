import 'package:flutter/material.dart';
import '../room/presentation/screens/create_exam_room_screen.dart';
import '../room/presentation/screens/exam_room_screen.dart';
import '../room/presentation/screens/qr_scanner_screen.dart';
import '../room/data/models/models.dart';
import '../room/data/repositories/room_repository_impl.dart';
import '../room/data/datasources/room_remote_datasource.dart';
import '../../core/services/auth_storage_service.dart';
import '../auth/data/models/auth/user.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  List<RoomModel> _rooms = [];
  bool _isLoading = false;
  User? _currentUser;
  final _roomRepository = RoomRepositoryImpl(
    remoteDataSource: RoomRemoteDataSourceImpl(),
  );

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadRooms();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload user data when dependencies change
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await AuthStorageService.getCurrentUser();
    debugPrint('📱 Loading user data: ${user?.nama} (ID: ${user?.idUsers})');
    
    if (mounted && user != null) {
      setState(() => _currentUser = user);
      debugPrint('✅ User updated: ${_currentUser?.nama}');
    } else {
      debugPrint('⚠️ No user found in storage');
    }
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);
    
    final result = await _roomRepository.getRooms();
    
    if (!mounted) return;
    
    result.fold(
      (failure) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load rooms: ${failure.message}'),
            backgroundColor: Colors.red,
          ),
        );
      },
      (rooms) {
        setState(() {
          _rooms = rooms;
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _navigateToCreateRoom() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateExamRoomScreen(),
      ),
    );
    
    if (result == true) {
      _loadRooms();
    }
  }

  Future<void> _scanQRCode() async {
    final roomCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
      ),
    );

    if (roomCode != null && mounted) {
      _joinRoomWithCode(roomCode);
    }
  }

  void _joinRoomWithCode(String roomCode) {
    // TODO: Implement join room API call
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Joining room: $roomCode'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _navigateToRoomDetails(RoomModel room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExamRoomScreen(room: room),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: SingleChildScrollView(
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
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
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
              const Text(
                'Welcome back,',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              Text(
                _currentUser?.nama ?? 'User',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
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

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2942),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
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
            const Text(
              'Your Exams',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: const Text('Active', style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () {},
              child: Text('History', style: TextStyle(color: Colors.grey[600])),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              )
            : _rooms.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _rooms.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final room = _rooms[index];
                      return _buildExamCard(room: room);
                    },
                  ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2942),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No Exams Yet',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first exam room to get started',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToCreateRoom,
            icon: const Icon(Icons.add),
            label: const Text('Create Room'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard({required RoomModel room}) {
    final now = DateTime.now();
    final isUpcoming = room.createdAt.isAfter(now);
    final statusColor = isUpcoming ? Colors.orange : Colors.green;
    final status = isUpcoming ? 'Upcoming' : 'Active';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2942),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: statusColor, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school_outlined,
                color: statusColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.roomName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      room.user?.nama ?? 'Unknown',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
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
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.grey[600], size: 16),
              const SizedBox(width: 4),
              Text(
                '${room.createdAt.day}/${room.createdAt.month}/${room.createdAt.year}',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              const SizedBox(width: 16),
              Icon(Icons.timer_outlined, color: Colors.grey[600], size: 16),
              const SizedBox(width: 4),
              Text(
                '${room.durasi} mins',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
          ),
        ],
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
