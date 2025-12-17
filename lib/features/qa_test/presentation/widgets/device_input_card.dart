import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/qa_bloc.dart';
import '../bloc/qa_event.dart';

class DeviceInputCard extends StatefulWidget {
  final bool isLoading;

  const DeviceInputCard({super.key, this.isLoading = false});

  @override
  State<DeviceInputCard> createState() => _DeviceInputCardState();
}

class _DeviceInputCardState extends State<DeviceInputCard>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _startTest() {
    final count = int.tryParse(_controller.text);
    if (count != null && count > 0) {
      context.read<QaBloc>().add(StartScanningEvent(count));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(32),
              decoration: AppDecorations.cardDecoration(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildIcon(),
                  const SizedBox(height: 20),
                  _buildTitle(),
                  const SizedBox(height: 10),
                  _buildSubtitle(),
                  const SizedBox(height: 24),
                  _buildInputField(),
                  const SizedBox(height: 20),
                  _buildStartButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.blueWithOpacity(0.2),
            AppColors.blueWithOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: AppColors.blueWithOpacity(0.3),
          width: 2,
        ),
      ),
      child: const Icon(
        Icons.bluetooth_searching,
        size: 40,
        color: AppColors.blue,
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Device Configuration',
      style: TextStyle(
        color: AppColors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Enter the number of GMSync devices to test',
      style: TextStyle(
        color: AppColors.whiteWithOpacity(0.6),
        fontSize: 13,
        letterSpacing: 0.3,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildInputField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.blueWithOpacity(0.3),
          width: 2,
        ),
      ),
      child: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        decoration: InputDecoration(
          hintText: 'Enter device count',
          hintStyle: TextStyle(
            color: AppColors.whiteWithOpacity(0.3),
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
        onSubmitted: (_) => _startTest(),
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: widget.isLoading ? null : _startTest,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          disabledBackgroundColor: AppColors.blueWithOpacity(0.3),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: widget.isLoading
            ? const SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
          ),
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow, size: 22),
            SizedBox(width: 8),
            Text(
              'Start Test',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}