import 'package:flutter/material.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({Key? key}) : super(key: key);

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        title: Row(
          children: const [
            Icon(Icons.verified_user_outlined, size: 18),
            SizedBox(width: 16),
            Text(
              'Документы и верификация',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=44'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Предупреждение о верификации
            _buildVerificationWarning(),

            // Секция загрузки документов
            _buildDocumentUploadSection(),

            // Секция процесса верификации
            _buildVerificationProcessSection(),

            // Секция безопасности данных
            _buildDataSecuritySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationWarning() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.black,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Верификация не пройдена',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Загрузите необходимые документы',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentUploadSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Загрузка документов',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),

          // Паспорт
          _buildDocumentUploadItem(
            title: 'Паспорт',
            icon: Icons.assignment_ind_outlined,
            status: 'Требуется',
          ),

          const SizedBox(height: 16),

          // Водительское удостоверение
          _buildDocumentUploadItem(
            title: 'Водительское удостоверение',
            icon: Icons.drive_eta_outlined,
            status: 'Требуется',
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadItem({
    required String title,
    required IconData icon,
    required String status,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              Text(
                status,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton.icon(
              onPressed: () {
                // Логика загрузки документа
              },
              icon: const Icon(Icons.upload_file, size: 14),
              label: const Text('Загрузить'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEFF6FF),
                foregroundColor: const Color(0xFF1D4ED8),
                elevation: 0,
                textStyle: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationProcessSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Процесс верификации',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildVerificationStep(
                  title: 'Загрузка документов',
                  status: 'В процессе',
                  isActive: true,
                  step: 1,
                ),
                const SizedBox(height: 16),
                _buildVerificationStep(
                  title: 'Проверка данных',
                  status: 'Ожидание',
                  isActive: false,
                  step: 2,
                ),
                const SizedBox(height: 16),
                _buildVerificationStep(
                  title: 'Подтверждение',
                  status: 'Ожидание',
                  isActive: false,
                  step: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStep({
    required String title,
    required String status,
    required bool isActive,
    required int step,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.black : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataSecuritySection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 16,
              color: Colors.black,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Ваши данные надежно защищены и',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'используются только для верификации.',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
