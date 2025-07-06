import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _darkModeEnabled = false;
  bool _biometricEnabled = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _autoRefreshEnabled = true;
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'R (ZAR)';

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
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
              // App Preferences Section
              _buildSection(
                'App Preferences',
                [
                  _buildSettingsTile(
                    'Notifications',
                    'Manage notification preferences',
                    FontAwesomeIcons.bell,
                    Colors.orange,
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                  ),
                  _buildSettingsTile(
                    'Sound',
                    'Enable app sounds',
                    FontAwesomeIcons.volumeUp,
                    Colors.blue,
                    trailing: Switch(
                      value: _soundEnabled,
                      onChanged: (value) {
                        setState(() {
                          _soundEnabled = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                  ),
                  _buildSettingsTile(
                    'Vibration',
                    'Enable vibration feedback',
                    FontAwesomeIcons.mobile,
                    Colors.purple,
                    trailing: Switch(
                      value: _vibrationEnabled,
                      onChanged: (value) {
                        setState(() {
                          _vibrationEnabled = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                  ),
                  _buildSettingsTile(
                    'Dark Mode',
                    'Switch to dark theme',
                    FontAwesomeIcons.moon,
                    Colors.indigo,
                    trailing: Switch(
                      value: _darkModeEnabled,
                      onChanged: (value) {
                        setState(() {
                          _darkModeEnabled = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),

              // Location & Privacy Section
              _buildSection(
                'Location & Privacy',
                [
                  _buildSettingsTile(
                    'Location Services',
                    'Enable location tracking',
                    FontAwesomeIcons.locationArrow,
                    Colors.blue,
                    trailing: Switch(
                      value: _locationEnabled,
                      onChanged: (value) {
                        setState(() {
                          _locationEnabled = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                  ),
                  _buildSettingsTile(
                    'Biometric Login',
                    'Use fingerprint or face ID',
                    FontAwesomeIcons.fingerprint,
                    Colors.teal,
                    trailing: Switch(
                      value: _biometricEnabled,
                      onChanged: (value) {
                        setState(() {
                          _biometricEnabled = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                  ),
                  _buildSettingsTile(
                    'Privacy Policy',
                    'Read our privacy policy',
                    FontAwesomeIcons.shieldAlt,
                    Colors.grey,
                    onTap: () => _showPrivacyPolicy(),
                  ),
                  _buildSettingsTile(
                    'Terms of Service',
                    'Read our terms of service',
                    FontAwesomeIcons.fileContract,
                    Colors.grey,
                    onTap: () => _showTermsOfService(),
                  ),
                ],
              ),
              SizedBox(height: 30),

              // Display & Language Section
              _buildSection(
                'Display & Language',
                [
                  _buildSettingsTile(
                    'Language',
                    _selectedLanguage,
                    FontAwesomeIcons.language,
                    Colors.indigo,
                    onTap: () => _showLanguageDialog(),
                  ),
                  _buildSettingsTile(
                    'Currency',
                    _selectedCurrency,
                    FontAwesomeIcons.moneyBill,
                    Colors.green,
                    onTap: () => _showCurrencyDialog(),
                  ),
                  _buildSettingsTile(
                    'Auto Refresh',
                    'Auto refresh bus locations',
                    FontAwesomeIcons.sync,
                    Colors.orange,
                    trailing: Switch(
                      value: _autoRefreshEnabled,
                      onChanged: (value) {
                        setState(() {
                          _autoRefreshEnabled = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                  ),
                  _buildSettingsTile(
                    'Map Style',
                    'Choose map appearance',
                    FontAwesomeIcons.map,
                    Colors.red,
                    onTap: () => _showMapStyleDialog(),
                  ),
                ],
              ),
              SizedBox(height: 30),

              // Data & Storage Section
              _buildSection(
                'Data & Storage',
                [
                  _buildSettingsTile(
                    'Clear Cache',
                    'Free up storage space',
                    FontAwesomeIcons.trash,
                    Colors.red,
                    onTap: () => _showClearCacheDialog(),
                  ),
                  _buildSettingsTile(
                    'Export Data',
                    'Download your data',
                    FontAwesomeIcons.download,
                    Colors.purple,
                    onTap: () => _showExportData(),
                  ),
                  _buildSettingsTile(
                    'Data Usage',
                    'Manage data consumption',
                    FontAwesomeIcons.chartBar,
                    Colors.blue,
                    onTap: () => _showDataUsage(),
                  ),
                  _buildSettingsTile(
                    'Offline Mode',
                    'Use app without internet',
                    FontAwesomeIcons.wifi,
                    Colors.grey,
                    onTap: () => _showOfflineMode(),
                  ),
                ],
              ),
              SizedBox(height: 30),

              // Support & Help Section
              _buildSection(
                'Support & Help',
                [
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
                ],
              ),
              SizedBox(height: 30),

              // About Section
              _buildSection(
                'About',
                [
                  _buildSettingsTile(
                    'About OneBus',
                    'App version 1.0.0',
                    FontAwesomeIcons.infoCircle,
                    Colors.grey,
                    onTap: () => _showAboutApp(),
                  ),
                  _buildSettingsTile(
                    'What\'s New',
                    'Latest updates and features',
                    FontAwesomeIcons.star,
                    Colors.amber,
                    onTap: () => _showWhatsNew(),
                  ),
                  _buildSettingsTile(
                    'Rate App',
                    'Rate us on app store',
                    FontAwesomeIcons.thumbsUp,
                    Colors.green,
                    onTap: () => _showRateApp(),
                  ),
                  _buildSettingsTile(
                    'Share App',
                    'Share with friends',
                    FontAwesomeIcons.share,
                    Colors.blue,
                    onTap: () => _showShareApp(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 16),
        ...children,
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
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Select Language',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption('English', 'English'),
              _buildLanguageOption('Afrikaans', 'Afrikaans'),
              _buildLanguageOption('Zulu', 'isiZulu'),
              _buildLanguageOption('Xhosa', 'isiXhosa'),
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
                _showSuccessDialog('Language updated successfully!');
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

  Widget _buildLanguageOption(String language, String displayName) {
    return ListTile(
      title: Text(displayName),
      leading: Radio<String>(
        value: language,
        groupValue: _selectedLanguage,
        onChanged: (value) {
          setState(() {
            _selectedLanguage = value!;
          });
        },
        activeColor: Colors.red,
      ),
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Select Currency',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCurrencyOption('R (ZAR)', 'South African Rand'),
              _buildCurrencyOption('\$ (USD)', 'US Dollar'),
              _buildCurrencyOption('€ (EUR)', 'Euro'),
              _buildCurrencyOption('£ (GBP)', 'British Pound'),
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
                _showSuccessDialog('Currency updated successfully!');
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

  Widget _buildCurrencyOption(String currency, String description) {
    return ListTile(
      title: Text(currency),
      subtitle: Text(description),
      leading: Radio<String>(
        value: currency,
        groupValue: _selectedCurrency,
        onChanged: (value) {
          setState(() {
            _selectedCurrency = value!;
          });
        },
        activeColor: Colors.red,
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Clear Cache',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'This will free up 45.2 MB of storage space. Are you sure you want to continue?',
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
                _showSuccessDialog('Cache cleared successfully!');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Clear',
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
  void _showPrivacyPolicy() {
    _showSuccessDialog('Privacy policy opened!');
  }

  void _showTermsOfService() {
    _showSuccessDialog('Terms of service opened!');
  }

  void _showMapStyleDialog() {
    _showSuccessDialog('Map style settings opened!');
  }

  void _showExportData() {
    _showSuccessDialog('Data export started!');
  }

  void _showDataUsage() {
    _showSuccessDialog('Data usage statistics opened!');
  }

  void _showOfflineMode() {
    _showSuccessDialog('Offline mode settings opened!');
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

  void _showWhatsNew() {
    _showSuccessDialog('What\'s new opened!');
  }

  void _showRateApp() {
    _showSuccessDialog('Rate app opened!');
  }

  void _showShareApp() {
    _showSuccessDialog('Share app opened!');
  }
}
