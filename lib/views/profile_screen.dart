import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _darkModeEnabled = false;
  bool _biometricEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.red,
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              _showEditProfileDialog();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.shade100,
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Header
              _buildProfileHeader(),
              SizedBox(height: 30),

              // Quick Stats
              _buildQuickStats(),
              SizedBox(height: 30),

              // Personal Information Section
              _buildPersonalInfoSection(),
              SizedBox(height: 30),

              // Payment & Cards Section
              _buildPaymentSection(),
              SizedBox(height: 30),

              // Subscriptions Section
              _buildSubscriptionsSection(),
              SizedBox(height: 30),

              // Account Actions
              _buildAccountActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(1, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Picture
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red, width: 3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.asset(
                'assets/profileImage.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.grey[600],
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 16),

          // User Name
          Text(
            'Junior Smith',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),

          // User Email
          Text(
            'junior.smith@email.com',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 12),

          // Member Since
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green, width: 1),
            ),
            child: Text(
              'Member since January 2024',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Rides',
            '127',
            FontAwesomeIcons.bus,
            Colors.blue,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Total Spent',
            'R 1,250',
            FontAwesomeIcons.moneyBill,
            Colors.green,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Saved Routes',
            '8',
            FontAwesomeIcons.heart,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: Offset(1, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          FaIcon(
            icon,
            color: color,
            size: 24,
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 16),
        _buildSettingsTile(
          'Full Name',
          'Junior Smith',
          FontAwesomeIcons.user,
          Colors.blue,
          onTap: () => _showEditNameDialog(),
        ),
        _buildSettingsTile(
          'Email Address',
          'junior.smith@email.com',
          FontAwesomeIcons.envelope,
          Colors.green,
          onTap: () => _showEditEmailDialog(),
        ),
        _buildSettingsTile(
          'Phone Number',
          '+27 82 123 4567',
          FontAwesomeIcons.phone,
          Colors.orange,
          onTap: () => _showEditPhoneDialog(),
        ),
        _buildSettingsTile(
          'Date of Birth',
          '15 March 1995',
          FontAwesomeIcons.calendar,
          Colors.purple,
          onTap: () => _showEditBirthDateDialog(),
        ),
        _buildSettingsTile(
          'Emergency Contact',
          'Add emergency contact',
          FontAwesomeIcons.heart,
          Colors.red,
          onTap: () => _showEmergencyContactDialog(),
        ),
        _buildSettingsTile(
          'Address',
          '123 Main Street, Johannesburg',
          FontAwesomeIcons.home,
          Colors.indigo,
          onTap: () => _showEditAddressDialog(),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment & Cards',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 16),
        _buildSettingsTile(
          'Linked Cards',
          'Manage your payment methods',
          FontAwesomeIcons.creditCard,
          Colors.blue,
          onTap: () => _showLinkedCards(),
        ),
        _buildSettingsTile(
          'Payment History',
          'View all transactions',
          FontAwesomeIcons.history,
          Colors.green,
          onTap: () => _showPaymentHistory(),
        ),
        _buildSettingsTile(
          'Auto Top-up',
          'Set up automatic balance top-up',
          FontAwesomeIcons.robot,
          Colors.orange,
          onTap: () => _showAutoTopUpSettings(),
        ),
        _buildSettingsTile(
          'Billing Address',
          'Update billing information',
          FontAwesomeIcons.addressCard,
          Colors.purple,
          onTap: () => _showBillingAddress(),
        ),
      ],
    );
  }

  Widget _buildSubscriptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subscriptions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 16),
        _buildSettingsTile(
          'Premium Plan',
          'Monthly subscription - R 99.99',
          FontAwesomeIcons.crown,
          Colors.amber,
          trailing: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green, width: 1),
            ),
            child: Text(
              'Active',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          onTap: () => _showSubscriptionDetails(),
        ),
        _buildSettingsTile(
          'Family Plan',
          'Add family members',
          FontAwesomeIcons.users,
          Colors.pink,
          onTap: () => _showFamilyPlan(),
        ),
        _buildSettingsTile(
          'Student Discount',
          'Verify student status',
          FontAwesomeIcons.graduationCap,
          Colors.indigo,
          onTap: () => _showStudentVerification(),
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Support & Help',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 16),
        _buildSettingsTile(
          'Help Center',
          'Get help and support',
          FontAwesomeIcons.questionCircle,
          Colors.blue,
          onTap: () => _showHelpCenter(),
        ),
        _buildSettingsTile(
          'Contact Support',
          'Chat with our support team',
          FontAwesomeIcons.headset,
          Colors.green,
          onTap: () => _showContactSupport(),
        ),
        _buildSettingsTile(
          'Report an Issue',
          'Report bugs or problems',
          FontAwesomeIcons.bug,
          Colors.red,
          onTap: () => _showReportIssue(),
        ),
        _buildSettingsTile(
          'Feedback',
          'Share your feedback',
          FontAwesomeIcons.comment,
          Colors.orange,
          onTap: () => _showFeedback(),
        ),
        _buildSettingsTile(
          'About OneBus',
          'App version 1.0.0',
          FontAwesomeIcons.infoCircle,
          Colors.grey,
          onTap: () => _showAboutApp(),
        ),
      ],
    );
  }

  Widget _buildAccountActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 16),
        _buildSettingsTile(
          'Change Password',
          'Update your password',
          FontAwesomeIcons.lock,
          Colors.blue,
          onTap: () => _showChangePassword(),
        ),
        _buildSettingsTile(
          'Two-Factor Authentication',
          'Add extra security',
          FontAwesomeIcons.key,
          Colors.green,
          onTap: () => _showTwoFactorAuth(),
        ),
        _buildSettingsTile(
          'Export Data',
          'Download your data',
          FontAwesomeIcons.download,
          Colors.purple,
          onTap: () => _showExportData(),
        ),
        _buildSettingsTile(
          'Delete Account',
          'Permanently delete account',
          FontAwesomeIcons.trash,
          Colors.red,
          onTap: () => _showDeleteAccount(),
        ),
        SizedBox(height: 20),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.white,
            border: Border.all(color: Colors.red, width: 3),
          ),
          child: ListTile(
            leading: FaIcon(
              FontAwesomeIcons.signOutAlt,
              color: Colors.red,
              size: 24,
            ),
            title: Center(
              child: Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
            onTap: () => _showSignOutDialog(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
        border: Border.all(color: Colors.red, width: 3),
      ),
      child: ListTile(
        leading: FaIcon(
          icon,
          color: color,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing: trailing ??
            Icon(
              Icons.arrow_forward,
              color: Colors.green,
            ),
        onTap: onTap,
      ),
    );
  }

  // Dialog Methods
  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Edit Profile',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSuccessDialog('Profile updated successfully!');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Save',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLinkedCards() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Linked Cards',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCardItem('Visa ending in 1234', 'Expires 12/25'),
              _buildCardItem('Mastercard ending in 5678', 'Expires 08/24'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showAddCardDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Add New Card',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCardItem(String title, String subtitle) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          FaIcon(
            FontAwesomeIcons.creditCard,
            color: Colors.blue,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              // Handle delete card
            },
          ),
        ],
      ),
    );
  }

  void _showAddCardDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Add New Card',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Expiry Date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSuccessDialog('Card added successfully!');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Add Card',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Sign Out',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Are you sure you want to sign out?',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to login screen
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Sign Out',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
              SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'OK',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Placeholder methods for other dialogs
  void _showLanguageDialog() {
    _showSuccessDialog('Language settings updated!');
  }

  void _showPrivacyPolicy() {
    _showSuccessDialog('Privacy policy opened!');
  }

  void _showPaymentHistory() {
    _showSuccessDialog('Payment history opened!');
  }

  void _showAutoTopUpSettings() {
    _showSuccessDialog('Auto top-up settings opened!');
  }

  void _showBillingAddress() {
    _showSuccessDialog('Billing address updated!');
  }

  void _showSubscriptionDetails() {
    _showSuccessDialog('Subscription details opened!');
  }

  void _showFamilyPlan() {
    _showSuccessDialog('Family plan settings opened!');
  }

  void _showStudentVerification() {
    _showSuccessDialog('Student verification opened!');
  }

  void _showHelpCenter() {
    _showSuccessDialog('Help center opened!');
  }

  void _showContactSupport() {
    _showSuccessDialog('Contact support opened!');
  }

  void _showReportIssue() {
    _showSuccessDialog('Report issue opened!');
  }

  void _showFeedback() {
    _showSuccessDialog('Feedback form opened!');
  }

  void _showAboutApp() {
    _showSuccessDialog('About OneBus opened!');
  }

  void _showChangePassword() {
    _showSuccessDialog('Password change form opened!');
  }

  void _showTwoFactorAuth() {
    _showSuccessDialog('Two-factor authentication opened!');
  }

  void _showExportData() {
    _showSuccessDialog('Data export started!');
  }

  void _showDeleteAccount() {
    _showSuccessDialog('Delete account confirmation opened!');
  }

  // Personal Information Dialog Methods
  void _showEditNameDialog() {
    _showSuccessDialog('Name updated successfully!');
  }

  void _showEditEmailDialog() {
    _showSuccessDialog('Email updated successfully!');
  }

  void _showEditPhoneDialog() {
    _showSuccessDialog('Phone number updated successfully!');
  }

  void _showEditBirthDateDialog() {
    _showSuccessDialog('Birth date updated successfully!');
  }

  void _showEmergencyContactDialog() {
    _showSuccessDialog('Emergency contact added successfully!');
  }

  void _showEditAddressDialog() {
    _showSuccessDialog('Address updated successfully!');
  }
}
