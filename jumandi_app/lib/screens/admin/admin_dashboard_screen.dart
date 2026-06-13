import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/jumandi_button.dart';
import '../../widgets/common/jumandi_text_field.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _creating = false;
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDeliveryAgents();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) context.go('/login');
  }

  Future<void> _createAgent() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all fields. Password must be at least 6 characters.')),
      );
      return;
    }

    setState(() => _creating = true);
    final provider = context.read<AdminProvider>();
    final agent = await provider.createDeliveryAgent(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _creating = false);

    if (agent != null) {
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _passwordController.clear();
      setState(() => _showForm = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delivery agent ${agent.email} created')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Could not create agent')),
      );
    }
  }

  Future<void> _deleteAgent(UserModel agent) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Delete ${agent.name}?', style: AppTextStyles.headingSmall),
        content: Text(
          'This removes their login. They cannot be deleted if they have active orders.',
          style: AppTextStyles.caption,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.logoOrange)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await context.read<AdminProvider>().deleteDeliveryAgent(agent.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Agent deleted' : context.read<AdminProvider>().error ?? 'Delete failed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        title: Text('Admin', style: AppTextStyles.headingSmall),
        actions: [
          IconButton(
            onPressed: provider.loadDeliveryAgents,
            icon: const Icon(Icons.refresh, color: AppColors.brandYellow),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: AppColors.white),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.loadDeliveryAgents,
        color: AppColors.brandYellow,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Welcome, ${auth.user?.name ?? 'Admin'}', style: AppTextStyles.heading.copyWith(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              'Create delivery login details here, then share email and password with your drivers.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text('Delivery agents (${provider.deliveryAgents.length})',
                      style: AppTextStyles.headingSmall),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _showForm = !_showForm),
                  icon: Icon(_showForm ? Icons.close : Icons.person_add, color: AppColors.brandYellow),
                  label: Text(
                    _showForm ? 'Close' : 'Add agent',
                    style: AppTextStyles.button.copyWith(color: AppColors.brandYellow),
                  ),
                ),
              ],
            ),
            if (_showForm) ...[
              const SizedBox(height: 12),
              _buildCreateForm(),
            ],
            const SizedBox(height: 16),
            if (provider.loading)
              const Center(child: CircularProgressIndicator(color: AppColors.brandYellow))
            else if (provider.deliveryAgents.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: Text(
                  'No delivery agents yet. Tap "Add agent" to create login details for a driver.',
                  style: AppTextStyles.body,
                ),
              )
            else
              ...provider.deliveryAgents.map(_agentCard),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.brandYellow.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          JumandiTextField(
            label: 'FULL NAME',
            controller: _nameController,
            hint: 'Driver name',
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: 14),
          JumandiTextField(
            label: 'EMAIL (LOGIN)',
            controller: _emailController,
            hint: 'driver@jumandi.com',
            prefixIcon: Icons.alternate_email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          JumandiTextField(
            label: 'PHONE',
            controller: _phoneController,
            hint: '+234...',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          JumandiTextField(
            label: 'PASSWORD',
            controller: _passwordController,
            hint: 'Min 6 characters',
            prefixIcon: Icons.lock_outline,
            obscureText: true,
          ),
          const SizedBox(height: 18),
          JumandiPrimaryButton(
            label: 'CREATE DELIVERY LOGIN',
            icon: Icons.check,
            loading: _creating,
            onPressed: _createAgent,
          ),
        ],
      ),
    );
  }

  Widget _agentCard(UserModel agent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(agent.name, style: AppTextStyles.headingSmall.copyWith(fontSize: 16)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: agent.isAvailable
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.logoOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  agent.isAvailable ? 'Available' : 'Offline',
                  style: AppTextStyles.caption.copyWith(
                    color: agent.isAvailable ? AppColors.success : AppColors.logoOrange,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(agent.email, style: AppTextStyles.body),
          Text(agent.phone, style: AppTextStyles.caption),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Share these login details with the driver',
                  style: AppTextStyles.caption.copyWith(fontSize: 10),
                ),
              ),
              IconButton(
                onPressed: () => _deleteAgent(agent),
                icon: const Icon(Icons.delete_outline, color: AppColors.logoOrange),
                tooltip: 'Delete agent',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
