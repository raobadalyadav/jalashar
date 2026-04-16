import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/user_role.dart';
import '../../core/data/extra_repositories.dart';
import '../../core/theme/app_theme.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});
  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  final _pageCtrl = PageController();
  int _step = 0;

  // Step 1 — role
  UserRole _role = UserRole.client;

  // Step 2 — details
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Step 3 — photo
  File? _photo;
  bool _loading = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_step == 1 && !(_formKey.currentState?.validate() ?? false)) return;
    if (_step < 2) {
      setState(() => _step++);
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  void _goBack() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.previousPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) setState(() => _photo = File(file.path));
  }

  Future<void> _finish() async {
    setState(() => _loading = true);
    try {
      String? avatarUrl;
      if (_photo != null) {
        avatarUrl = await ref.read(storageRepoProvider).uploadAvatar(_photo!);
      }
      await ref.read(authControllerProvider).completeProfile(
            name: _nameCtrl.text.trim(),
            role: _role,
            phone: _phoneCtrl.text.trim(),
            city: _cityCtrl.text.trim(),
            avatarUrl: avatarUrl,
          );
      ref.invalidate(currentUserProvider);
      if (mounted) context.go('/splash');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button + progress
                  Row(children: [
                    if (_step > 0)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        onPressed: _goBack,
                        padding: EdgeInsets.zero,
                      )
                    else
                      const SizedBox(width: 40),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_step + 1) / 3,
                          minHeight: 6,
                          backgroundColor: AppColors.violetMid.withValues(alpha: 0.25),
                          valueColor: const AlwaysStoppedAnimation(AppColors.violet),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${_step + 1}/3',
                        style: const TextStyle(color: AppColors.slate, fontSize: 13)),
                  ]),
                  const SizedBox(height: 24),
                  Text(
                    _stepTitle(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ).animate(key: ValueKey(_step)).fadeIn().slideY(begin: 0.1),
                  const SizedBox(height: 6),
                  Text(
                    _stepSubtitle(),
                    style: const TextStyle(color: AppColors.slate, fontSize: 14, height: 1.4),
                  ).animate(key: ValueKey('s$_step')).fadeIn(delay: 100.ms),
                ],
              ),
            ),

            // ── Content ─────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _RoleStep(
                    selected: _role,
                    onSelect: (r) => setState(() => _role = r),
                  ),
                  _DetailsStep(
                    formKey: _formKey,
                    nameCtrl: _nameCtrl,
                    phoneCtrl: _phoneCtrl,
                    cityCtrl: _cityCtrl,
                    role: _role,
                  ),
                  _PhotoStep(
                    photo: _photo,
                    name: _nameCtrl.text,
                    onPick: _pickPhoto,
                    onSkip: _finish,
                    loading: _loading,
                  ),
                ],
              ),
            ),

            // ── Bottom button ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _loading ? null : _goNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.violet,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _step == 2 ? 'Finish Setup' : 'Continue',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _stepTitle() => switch (_step) {
        0 => 'How will you use Jalaram?',
        1 => 'Tell us about yourself',
        _ => 'Add a profile photo',
      };

  String _stepSubtitle() => switch (_step) {
        0 => 'Choose your role — you can update this anytime in settings.',
        1 => 'This helps vendors and clients recognise you.',
        _ => 'A photo builds trust. You can skip and add it later.',
      };
}

// ── Step 1: Role ───────────────────────────────────────────────────────────────

class _RoleStep extends StatelessWidget {
  const _RoleStep({required this.selected, required this.onSelect});
  final UserRole selected;
  final ValueChanged<UserRole> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          _RoleCard(
            title: 'I\'m planning an event',
            subtitle: 'Find, compare, and book vendors for weddings, birthdays, corporate events and more.',
            icon: Icons.celebration_rounded,
            color: AppColors.violet,
            badge: 'Client',
            selected: selected == UserRole.client,
            onTap: () => onSelect(UserRole.client),
          ),
          const SizedBox(height: 16),
          _RoleCard(
            title: 'I\'m a vendor / artist',
            subtitle: 'Showcase your work, receive booking requests, and grow your business.',
            icon: Icons.storefront_rounded,
            color: AppColors.saffron,
            badge: 'Vendor',
            selected: selected == UserRole.vendor,
            onTap: () => onSelect(UserRole.vendor),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.violet.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.violetMid.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.violet, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Jalaram is 100% free — no commission, no platform fees. Vendors and clients settle directly.',
                  style: TextStyle(fontSize: 12, color: AppColors.violet.withValues(alpha: 0.85), height: 1.4),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.badge,
    required this.selected,
    required this.onTap,
  });
  final String title, subtitle, badge;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color : AppColors.violetMid.withValues(alpha: 0.3),
            width: selected ? 2.5 : 1,
          ),
          color: selected ? color.withValues(alpha: 0.08) : context.softSurface,
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: selected ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(badge, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: AppColors.slate, fontSize: 12, height: 1.4)),
            ]),
          ),
          if (selected)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Icon(Icons.check_circle_rounded, color: color, size: 22),
            ),
        ]),
      ),
    );
  }
}

// ── Step 2: Details ───────────────────────────────────────────────────────────

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.formKey,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.cityCtrl,
    required this.role,
  });
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl, phoneCtrl, cityCtrl;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Form(
        key: formKey,
        child: Column(children: [
          _Field(
            controller: nameCtrl,
            label: role == UserRole.vendor ? 'Business / Artist Name *' : 'Full Name *',
            hint: role == UserRole.vendor ? 'e.g. Rahul Photography' : 'e.g. Priya Sharma',
            icon: Icons.person_outline_rounded,
            capitalization: TextCapitalization.words,
            validator: (v) {
              if (v == null || v.trim().length < 2) return 'Please enter at least 2 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _Field(
            controller: phoneCtrl,
            label: 'Phone Number',
            hint: '10-digit mobile number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              if (v.trim().length != 10) return 'Enter a valid 10-digit number';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _Field(
            controller: cityCtrl,
            label: 'City',
            hint: 'e.g. Mumbai, Jaipur, Delhi',
            icon: Icons.location_city_rounded,
            capitalization: TextCapitalization.words,
          ),
          if (role == UserRole.vendor) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.saffron.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.saffron.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.tips_and_updates_rounded, color: AppColors.saffron, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'After setup, complete your vendor profile with portfolio photos, packages, and availability to start receiving bookings.',
                    style: TextStyle(fontSize: 12, color: AppColors.saffron.withValues(alpha: 0.9), height: 1.4),
                  ),
                ),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.capitalization = TextCapitalization.none,
    this.validator,
  });
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization capitalization;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: capitalization,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppColors.slate),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.violetMid.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.violet, width: 2),
        ),
      ),
    );
  }
}

// ── Step 3: Photo ─────────────────────────────────────────────────────────────

class _PhotoStep extends StatelessWidget {
  const _PhotoStep({
    required this.photo,
    required this.name,
    required this.onPick,
    required this.onSkip,
    required this.loading,
  });
  final File? photo;
  final String name;
  final VoidCallback onPick, onSkip;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        children: [
          GestureDetector(
            onTap: onPick,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: photo == null ? const LinearGradient(colors: [AppColors.violetDeep, AppColors.violet]) : null,
                    image: photo != null
                        ? DecorationImage(image: FileImage(photo!), fit: BoxFit.cover)
                        : null,
                    boxShadow: [
                      BoxShadow(color: AppColors.violet.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: photo == null
                      ? Center(
                          child: Text(
                            initials.isEmpty ? '?' : initials,
                            style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800),
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: AppColors.violet,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            photo == null ? 'Tap to add a photo' : 'Looking great!',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            photo == null
                ? 'Choose from your gallery'
                : 'Tap the photo to change it',
            style: const TextStyle(color: AppColors.slate, fontSize: 13),
          ),
          const Spacer(),
          if (!loading)
            TextButton(
              onPressed: onSkip,
              child: const Text('Skip for now', style: TextStyle(color: AppColors.slate)),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
