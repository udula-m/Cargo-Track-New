import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/thingspeak_data.dart';
import '../providers/iot_data_provider.dart';
import '../services/thingspeak_service.dart';
import '../config/thingspeak_config.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _channelIdController = TextEditingController();
  final _readApiKeyController = TextEditingController();
  final _writeApiKeyController = TextEditingController();
  final _directUrlController = TextEditingController();
  
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isChannelVerified = false;
  bool _useDirectUrl = false;
  ThingSpeakChannel? _channelInfo;

  @override
  void initState() {
    super.initState();
    
    _channelIdController.text = ThingSpeakConfig.defaultChannelId;
    _readApiKeyController.text = ThingSpeakConfig.defaultReadApiKey;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _channelIdController.dispose();
    _readApiKeyController.dispose();
    _writeApiKeyController.dispose();
    _directUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add ThingSpeak Device'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
              
            
            SwitchListTile(
              title: const Text('Use Direct API URL'),
              subtitle: const Text('Switch to use a full ThingSpeak API URL'),
              value: _useDirectUrl,
              onChanged: (value) {
                setState(() {
                  _useDirectUrl = value;
                  _isChannelVerified = false;
                  _channelInfo = null;
                });
              },
            ),
            
            const Divider(),
            
            if (!_useDirectUrl) ...[
              
              TextFormField(
                controller: _channelIdController,
                decoration: const InputDecoration(
                  labelText: 'Channel ID *',
                  hintText: 'Enter ThingSpeak Channel ID',
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Channel ID';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Channel ID must be a number';
                  }
                  return null;
                },
                enabled: !_isChannelVerified,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _readApiKeyController,
                decoration: const InputDecoration(
                  labelText: 'Read API Key *',
                  hintText: 'Enter read API key',
                  prefixIcon: Icon(Icons.vpn_key),
                ),
                validator: (value) {
                  
                  return null;
                },
                enabled: !_isChannelVerified,
              ),
            ] else 
              
              TextFormField(
                controller: _directUrlController,
                decoration: const InputDecoration(
                  labelText: 'Direct API URL *',
                  hintText: 'Enter full ThingSpeak API URL',
                  prefixIcon: Icon(Icons.link),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter API URL';
                  }
                  if (!Uri.parse(value).isAbsolute) {
                    return 'Please enter a valid URL';
                  }
                  return null;
                },
                enabled: !_isChannelVerified,
              ),
            
            const SizedBox(height: 16),
            
            
            if (!_isChannelVerified)
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _verifyChannel,
                icon: _isLoading 
                  ? Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.all(2.0),
                      child: const CircularProgressIndicator(
                        strokeWidth: 3,
                      ),
                    )
                  : const Icon(Icons.check_circle),
                label: Text(_isLoading ? 'Verifying...' : 'Verify Channel'),
              ),
              
            if (_isChannelVerified) ...[
              const Divider(height: 32),
              
             
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Channel Verified',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Channel Name: ${_channelInfo!.name}'),
                      if (_channelInfo!.description.isNotEmpty)
                        Text('Description: ${_channelInfo!.description}'),
                      const SizedBox(height: 8),
                      Text('Fields: ${_channelInfo!.fieldLabels.length}'),
                    ],
                  ),
                ),
              ),
              
             
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Device Name *',
                  hintText: 'Give this device a name',
                  prefixIcon: const Icon(Icons.device_hub),
                  helperText: _nameController.text.isEmpty ? 'Default: ${_channelInfo!.name}' : null,
                ),
                validator: (value) {
                  
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
             
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Add a description (optional)',
                  prefixIcon: const Icon(Icons.description),
                  helperText: _descriptionController.text.isEmpty && _channelInfo!.description.isNotEmpty 
                    ? 'Default: ${_channelInfo!.description}' : null,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              
              
              TextFormField(
                controller: _writeApiKeyController,
                decoration: const InputDecoration(
                  labelText: 'Write API Key (Optional)',
                  hintText: 'For data updates (if needed)',
                  prefixIcon: Icon(Icons.edit),
                ),
              ),
              const SizedBox(height: 24),
              
              ElevatedButton.icon(
                onPressed: _addDevice,
                icon: const Icon(Icons.add),
                label: const Text('Add Device'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              
              TextButton(
                onPressed: () {
                  setState(() {
                    _isChannelVerified = false;
                    _channelInfo = null;
                  });
                },
                child: const Text('Change Channel Info'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _verifyChannel() async {
    if (_useDirectUrl) {
      
      if (_directUrlController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter a direct API URL';
        });
        return;
      }

      final directUrl = _directUrlController.text.trim();
      
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final ThingSpeakService service = ThingSpeakService();
        debugPrint('Verifying channel from direct URL: $directUrl');
        
        final channelInfo = await service.getChannelInfo('0', '', directUrl: directUrl);
        
        debugPrint('Channel verified successfully: ${channelInfo.name}');
        
        setState(() {
          _isLoading = false;
          _isChannelVerified = true;
          _channelInfo = channelInfo;
          
          
          if (_nameController.text.isEmpty) {
            _nameController.text = channelInfo.name;
          }
          
          
          if (_descriptionController.text.isEmpty && channelInfo.description.isNotEmpty) {
            _descriptionController.text = channelInfo.description;
          }
        });
      } catch (e) {
        debugPrint('Error verifying channel: $e');
        
        
        String errorMessage = 'Error verifying channel';
        
        if (e.toString().contains('API Error')) {
         
          errorMessage = e.toString().replaceAll('Exception: ', '');
        } else if (e.toString().contains('Bad Request')) {
          errorMessage = 'Channel verification failed. Please check your API URL.';
        } else if (e.toString().contains('Channel not found')) {
          errorMessage = 'Channel not found. Please check your API URL.';
        } else if (e.toString().contains('Access denied')) {
          errorMessage = 'Access denied. Please check your API URL.';
        } else if (e.toString().contains('No internet connection')) {
          errorMessage = 'No internet connection. Please check your network.';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Connection timeout. ThingSpeak server is not responding.';
        }
        
        setState(() {
          _isLoading = false;
          _errorMessage = errorMessage;
        });
      }
    } else {
      
      if (_channelIdController.text.isEmpty || _readApiKeyController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter both Channel ID and Read API Key';
        });
        return;
      }

     
      final channelId = _channelIdController.text.trim();
      if (int.tryParse(channelId) == null) {
        setState(() {
          _errorMessage = 'Channel ID must be a number';
        });
        return;
      }

      
      final apiKey = _readApiKeyController.text.trim();
      
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final ThingSpeakService service = ThingSpeakService();
        
        debugPrint('Verifying channel: $channelId with API key: $apiKey');
        
        final channelInfo = await service.getChannelInfo(channelId, apiKey);
        
        debugPrint('Channel verified successfully: ${channelInfo.name}');
        
        setState(() {
          _isLoading = false;
          _isChannelVerified = true;
          _channelInfo = channelInfo;
          
          
          if (_nameController.text.isEmpty) {
            _nameController.text = channelInfo.name;
          }
          
          
          if (_descriptionController.text.isEmpty && channelInfo.description.isNotEmpty) {
            _descriptionController.text = channelInfo.description;
          }
        });
      } catch (e) {
        debugPrint('Error verifying channel: $e');
        
       
        String errorMessage = 'Error verifying channel';
        
        if (e.toString().contains('API Error')) {
          
          errorMessage = e.toString().replaceAll('Exception: ', '');
        } else if (e.toString().contains('Bad Request')) {
          errorMessage = 'Channel verification failed. Please check your Channel ID and Read API Key.';
        } else if (e.toString().contains('Channel not found')) {
          errorMessage = 'Channel not found. Please check your Channel ID.';
        } else if (e.toString().contains('Access denied')) {
          errorMessage = 'Access denied. Please check your Read API Key.';
        } else if (e.toString().contains('No internet connection')) {
          errorMessage = 'No internet connection. Please check your network.';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Connection timeout. ThingSpeak server is not responding.';
        }
        
        setState(() {
          _isLoading = false;
          _errorMessage = errorMessage;
        });
      }
    }
  }

  void _addDevice() {
    if (!_isChannelVerified || _channelInfo == null) {
      setState(() {
        _errorMessage = 'Please verify the channel first';
      });
      return;
    }
    
    final String name = _nameController.text.isNotEmpty 
        ? _nameController.text 
        : _channelInfo!.name;
    
    final String description = _descriptionController.text.isNotEmpty
        ? _descriptionController.text
        : _channelInfo?.description ?? '';
    
    try {
      final ThingSpeakDevice newDevice = ThingSpeakDevice(
        channelId: _useDirectUrl ? '0' : _channelIdController.text,
        readApiKey: _useDirectUrl ? '' : _readApiKeyController.text,
        writeApiKey: _writeApiKeyController.text,
        name: name,
        description: description,
        directUrl: _useDirectUrl ? _directUrlController.text : null,
      );
      
      Provider.of<IoTDataProvider>(context, listen: false).addDevice(newDevice);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name added successfully')),
      );
      
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error adding device: $e';
      });
    }
  }
}
