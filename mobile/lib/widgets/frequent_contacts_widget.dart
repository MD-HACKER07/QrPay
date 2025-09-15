import 'package:flutter/material.dart';
import '../services/upi_account_service.dart';

class FrequentContactsWidget extends StatefulWidget {
  final Function(String) onContactSelected;

  const FrequentContactsWidget({
    Key? key,
    required this.onContactSelected,
  }) : super(key: key);

  @override
  State<FrequentContactsWidget> createState() => _FrequentContactsWidgetState();
}

class _FrequentContactsWidgetState extends State<FrequentContactsWidget> {
  List<String> _frequentUpiIds = [];
  Map<String, UpiAccountDetails> _contactDetails = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFrequentContacts();
  }

  Future<void> _loadFrequentContacts() async {
    try {
      final frequentIds = await UpiAccountService.getFrequentUpiIds(limit: 5);
      
      // Load details for each frequent UPI ID
      final Map<String, UpiAccountDetails> details = {};
      for (final upiId in frequentIds) {
        final accountDetails = await UpiAccountService.getAccountDetails(upiId);
        if (accountDetails != null) {
          details[upiId] = accountDetails;
        }
      }

      if (mounted) {
        setState(() {
          _frequentUpiIds = frequentIds.where((id) => details.containsKey(id)).toList();
          _contactDetails = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Container(
        height: 80,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_frequentUpiIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Frequent Contacts',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _frequentUpiIds.length,
            itemBuilder: (context, index) {
              final upiId = _frequentUpiIds[index];
              final details = _contactDetails[upiId]!;

              return Container(
                width: 70,
                margin: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () => widget.onContactSelected(upiId),
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.blue.shade100,
                        backgroundImage: details.profileImage != null
                            ? NetworkImage(details.profileImage!)
                            : null,
                        child: details.profileImage == null
                            ? Text(
                                details.displayName[0].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        details.displayName.split(' ')[0], // First name only
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
