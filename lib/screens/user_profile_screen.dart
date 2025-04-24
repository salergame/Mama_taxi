import 'package:flutter/material.dart';
import 'package:mama_taxi/services/firebase_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userData = await _firebaseService.getUserData();
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Ошибка загрузки данных пользователя: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await _firebaseService.signOut();
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      print('Ошибка при выходе: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              width: 320,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.only(topRight: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(30, 8),
                    blurRadius: 10,
                    color: Colors.black.withOpacity(0.1),
                  ),
                  BoxShadow(
                    offset: const Offset(0, 20),
                    blurRadius: 25,
                    color: Colors.black.withOpacity(0.1),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  _buildProfileHeader(),
                  _buildChildrenSection(),
                  _buildNavigation(),
                  _buildSignOutButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      height: 169,
      width: 320,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 24),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: _userData?['photoUrl'] != null
                          ? NetworkImage(_userData!['photoUrl'])
                          : const AssetImage('assets/images/default_avatar.png')
                              as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userData?['name'] ?? 'Анна Смирнова',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, size: 18, color: Colors.black),
                        const SizedBox(width: 4),
                        Text(
                          _userData?['rating']?.toString() ?? '4.92',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 16),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/edit_profile');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF53CFC4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(272, 40),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.edit, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Редактировать профиль',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenSection() {
    return Container(
      height: 165,
      width: 320,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 24, top: 18),
            child: Text(
              'Мои дети',
              style: TextStyle(
                fontFamily: 'Rubik',
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 288,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(left: 8, top: 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: const DecorationImage(
                            image: AssetImage('assets/images/child_avatar.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                          'Петя, 8 лет',
                          style: TextStyle(
                            fontFamily: 'Rubik',
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/add_child');
                    },
                    icon: const Icon(
                      Icons.add,
                      color: Color(0xFF2563EB),
                      size: 14,
                    ),
                    label: const Text(
                      'Добавить ребенка',
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 16,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation() {
    return Container(
      width: 320,
      height: 424,
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          _buildNavItem(
            title: 'Мои поездки',
            icon: Icons.directions_car,
            isActive: true,
            onTap: () => Navigator.pushNamed(context, '/trips'),
          ),
          _buildNavItem(
            title: 'Программа лояльности',
            icon: Icons.loyalty,
            onTap: () => Navigator.pushNamed(context, '/loyalty'),
            trailing: Container(
              width: 70,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    '120',
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 12,
                      color: Color(0xFF047857),
                    ),
                  ),
                  Text(
                    'баллов',
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 12,
                      color: Color(0xFF047857),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildNavItem(
            title: 'Настройки',
            icon: Icons.settings,
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          _buildNavItem(
            title: 'Поддержка и помощь',
            icon: Icons.help,
            onTap: () => Navigator.pushNamed(context, '/support'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String title,
    required IconData icon,
    bool isActive = false,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 288,
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFEFF6FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(width: 12),
              Icon(
                icon,
                size: 18,
                color: isActive ? const Color(0xFF1D4ED8) : Colors.black,
              ),
              SizedBox(width: 18),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 16,
                  color: isActive ? const Color(0xFF1D4ED8) : Colors.black,
                ),
              ),
              if (trailing != null) const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return Container(
      width: 320,
      height: 81,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      child: TextButton(
        onPressed: _signOut,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.logout, color: Color(0xFFDC2626), size: 16),
            SizedBox(width: 16),
            Text(
              'Выход из аккаунта',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                color: Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
