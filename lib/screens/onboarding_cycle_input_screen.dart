import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/gradient_wrapper.dart';
import '../utils/auth_guard.dart';
import '../services/supabase_cycle_manager.dart';

class OnboardingCycleInputScreen extends StatefulWidget {
  const OnboardingCycleInputScreen({super.key});

  @override
  State<OnboardingCycleInputScreen> createState() => _OnboardingCycleInputScreenState();
}

class _OnboardingCycleInputScreenState extends State<OnboardingCycleInputScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _lastPeriodStart;
  int _cycleLength = 28;
  int _periodLength = 5;

  @override
  Widget build(BuildContext context) {
    return GradientWrapper(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personalize your cycle tracking',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                    ),
                    const SizedBox(height: 30),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Last Period Start Date
                          Text(
                            'Last Period Start Date',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  _lastPeriodStart = pickedDate;
                                });
                              }
                            },
                            child: Text(
                              _lastPeriodStart == null
                                  ? 'Select Date'
                                  : 'Selected: ${_lastPeriodStart!.toLocal().toString().split(' ')[0]}',
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Average Cycle Length
                          Text(
                            'Average Cycle Length (days)',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            decoration: InputDecoration(
                              hintText: 'e.g., 28',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            initialValue: _cycleLength.toString(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your cycle length.';
                              }
                              final length = int.tryParse(value);
                              if (length == null || length < 21 || length > 35) {
                                return 'Enter a valid cycle length (21-35 days).';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _cycleLength = int.parse(value!);
                            },
                          ),
                          const SizedBox(height: 30),

                          // Average Period Length
                          Text(
                            'Average Period Length (days)',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: _periodLength > 2
                                    ? () {
                                        setState(() {
                                          _periodLength--;
                                        });
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: const Color(0xFF333333),
                                  elevation: 0,
                                  side: const BorderSide(color: Color(0xFF333333), width: 1.5),
                                  disabledBackgroundColor: Colors.transparent,
                                ),
                                child: const Text('−'),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    hintText: 'e.g., 5',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  controller: TextEditingController(text: _periodLength.toString()),
                                  onChanged: (value) {
                                    final length = int.tryParse(value);
                                    if (length != null && length >= 2 && length <= 10) {
                                      setState(() {
                                        _periodLength = length;
                                      });
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your period length.';
                                    }
                                    final length = int.tryParse(value);
                                    if (length == null || length < 2 || length > 10) {
                                      return 'Enter a valid period length (2-10 days).';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 15),
                              ElevatedButton(
                                onPressed: _periodLength < 10
                                    ? () {
                                        setState(() {
                                          _periodLength++;
                                        });
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: const Color(0xFF333333),
                                  elevation: 0,
                                  side: const BorderSide(color: Color(0xFF333333), width: 1.5),
                                  disabledBackgroundColor: Colors.transparent,
                                ),
                                child: const Text('+'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/lifestylePreferences');
                    },
                    child: const Text('Skip',
                      style: TextStyle(color: Color(0xFF666666)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate() && _lastPeriodStart != null) {
                          _formKey.currentState!.save();
                          
                          // Check auth
                          if (!AuthGuard.isLoggedIn()) {
                            final authenticated = await AuthGuard.requireAuth(context);
                            if (!authenticated) return;
                          }

                          try {
                            final userId = AuthGuard.getCurrentUserId()!;

                            // Save to local storage
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('lastPeriodStart', _lastPeriodStart!.toIso8601String());
                            await prefs.setInt('cycleLength', _cycleLength);
                            await prefs.setInt('periodLength', _periodLength);

                            // Save to Supabase
                            await SupabaseCycleManager.createCycle(
                              userId: userId,
                              cycleLength: _cycleLength,
                              periodLength: _periodLength,
                              startDate: _lastPeriodStart!,
                            );

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Cycle info saved!'),
                                  backgroundColor: Color(0xFF4CAF50),
                                ),
                              );
                              Navigator.of(context).pushNamed('/lifestylePreferences');
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('❌ Error: $e'),
                                  backgroundColor: Color(0xFFDD4444),
                                ),
                              );
                            }
                          }
                        } else if (_lastPeriodStart == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select a date.')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: const Color(0xFF333333),
                        elevation: 0,
                        side: const BorderSide(color: Color(0xFF333333), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Next',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
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
